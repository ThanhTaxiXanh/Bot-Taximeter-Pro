import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';

/// Ghi đúng trường gốc CSV; chưa suy ra hiệu lực, hướng, loại xe.
class ImportedRoadSign {
  const ImportedRoadSign(this.id, this.lon, this.lat, this.code,
      this.direction, this.rawValue, this.meta);
  final int id, code, direction;
  final double lon, lat;
  final String rawValue, meta;

  Map<String, Object> get dbRow => <String, Object>{
    'id': id, 'lon': lon, 'lat': lat, 'code': code,
    'direction': direction, 'raw_value': rawValue, 'meta': meta,
  };

  static ImportedRoadSign? parse(String line, {required bool speedOnly}) {
    final f = line.trim().split(',');
    if (f.length != (speedOnly ? 6 : 9)) return null;
    final id = int.tryParse(f[0]);
    final lon = double.tryParse(f[1]);
    final lat = double.tryParse(f[2]);
    final code = int.tryParse(f[speedOnly ? 5 : 3]);
    final dir = int.tryParse(f[4]);
    if (id == null || id < 0 || lon == null || lat == null ||
        !lat.isFinite || !lon.isFinite ||
        lat.abs() > 90 || lon.abs() > 180 ||
        code == null || code < 0 || dir == null ||
        dir < 0 || dir > 255) return null;
    return ImportedRoadSign(id, lon, lat, code, dir,
        f[speedOnly ? 3 : 5], speedOnly ? '' : f[6]);
  }

  factory ImportedRoadSign.fromDb(Map<String, Object?> row) =>
      ImportedRoadSign((row['id'] as num).toInt(),
        (row['lon'] as num).toDouble(), (row['lat'] as num).toDouble(),
        (row['code'] as num).toInt(), (row['direction'] as num).toInt(),
        row['raw_value'] as String, row['meta'] as String);

  String get title {
    final value = int.tryParse(rawValue);
    if (code == 1 && value != null && value >= 5 && value <= 120) {
      return 'Biển tốc độ $value km/h · DỮ LIỆU THU THẬP';
    }
    return 'Biển báo mã $code · DỮ LIỆU THU THẬP';
  }

  String get details => 'ID $id · hướng $direction · '
      'giá trị $rawValue · meta ' + (meta.isEmpty ? '—' : meta);
}

/// SQLite tách biệt, không đụng bot_taximeter.db của lịch sử chuyến.
class ImportedRoadSigns extends ChangeNotifier {
  ImportedRoadSigns._();
  static final ImportedRoadSigns instance = ImportedRoadSigns._();
  Future<Database>? _opening;
  int count = 0;
  bool busy = false;
  String source = '';

  static const trafficHeader = 'sign_id,longitude,latitude,'
      'sign_type_code,direction_raw,value_raw,meta_raw,tile_lat,tile_lon';
  static const speedHeader = 'sign_id,longitude,latitude,'
      'speed_kmh_inferred,direction_raw,sign_type_code';

  static bool? headerKind(String header) {
    final clean = header.trim().replaceFirst('\uFEFF', '');
    if (clean == trafficHeader) return false;
    if (clean == speedHeader) return true;
    return null;
  }

  Future<Database> get _db => _opening ??= _open();
  Future<Database> _open() async {
    final path = (await getDatabasesPath()) + '/imported_traffic_signs.db';
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE signs (id INTEGER PRIMARY KEY, '
          'lat REAL NOT NULL, lon REAL NOT NULL, code INTEGER NOT NULL, '
          'direction INTEGER NOT NULL, raw_value TEXT NOT NULL, '
          'meta TEXT NOT NULL)');
      await db.execute('CREATE INDEX signs_location ON signs(lat, lon)');
    });
  }

  Future<void> loadCount() async {
    if (busy) return;
    final rows = await (await _db).rawQuery('SELECT COUNT(*) AS n FROM signs');
    count = (rows.first['n'] as num).toInt();
    notifyListeners();
  }

  /// Import từ stream với batch; lỗi sẽ rollback, giữ bộ cũ.
  Future<int> importCsv(XFile file) async {
    if (busy) throw StateError('Đang nhập một tệp khác');
    if (await file.length() > 18 * 1024 * 1024) {
      throw const FormatException('CSV vượt 18 MB');
    }
    busy = true;
    notifyListeners();
    try {
      var inserted = 0;
      bool? speedOnly;
      await (await _db).transaction((txn) async {
        var batch = txn.batch();
        await for (final line in file.openRead()
            .transform(utf8.decoder).transform(const LineSplitter())) {
          if (speedOnly == null) {
            speedOnly = headerKind(line);
            if (speedOnly == null) {
              throw const FormatException('Sai tiêu đề CSV biển báo');
            }
            await txn.delete('signs');
            continue;
          }
          final sign = ImportedRoadSign.parse(line, speedOnly: speedOnly!);
          if (sign == null) continue;
          batch.insert('signs', sign.dbRow,
              conflictAlgorithm: ConflictAlgorithm.replace);
          inserted++;
          if (inserted % 600 == 0) {
            await batch.commit(noResult: true);
            batch = txn.batch();
          }
          if (inserted > 200000) {
            throw const FormatException('Quá 200.000 biển báo');
          }
        }
        if (speedOnly == null || inserted == 0) {
          throw const FormatException('CSV không có biển hợp lệ');
        }
        await batch.commit(noResult: true);
      });
      final rows = await (await _db).rawQuery('SELECT COUNT(*) AS n FROM signs');
      count = (rows.first['n'] as num).toInt();
      source = file.name;
      return count;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Chỉ truy vấn vùng nhìn; nhiều nhất 800 ứng viên và 32 marker.
  Future<Set<Marker>> markersInBounds(LatLngBounds bounds) async {
    if (count == 0 || busy) return <Marker>{};
    final south = bounds.southwest.latitude;
    final north = bounds.northeast.latitude;
    final west = bounds.southwest.longitude;
    final east = bounds.northeast.longitude;
    if (north <= south || east <= west) return <Marker>{};
    final midLat = (north + south) / 2, midLon = (east + west) / 2;
    final rows = await (await _db).rawQuery(
      'SELECT id, lat, lon, code, direction, raw_value, meta FROM signs '
      'WHERE lat BETWEEN ? AND ? AND lon BETWEEN ? AND ? '
      'ORDER BY (lat-?)*(lat-?) + (lon-?)*(lon-?) LIMIT 800',
      <Object>[south, north, west, east, midLat, midLat, midLon, midLon],
    );
    final latStep = math.max((north - south) / 7, 0.00025);
    final lonStep = math.max((east - west) / 5, 0.00025);
    final cells = <String>{}, markers = <Marker>{};
    for (final row in rows) {
      final sign = ImportedRoadSign.fromDb(row);
      final cell = ((sign.lat - south) / latStep).floor().toString() +
          ':' + ((sign.lon - west) / lonStep).floor().toString();
      if (!cells.add(cell)) continue;
      markers.add(Marker(
        markerId: MarkerId('collected-' + sign.id.toString()),
        position: LatLng(sign.lat, sign.lon),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: sign.title + ' · CHƯA XÁC NHẬN CHIỀU',
          snippet: sign.details,
        ),
      ));
      if (markers.length >= 32) break;
    }
    return markers;
  }
}
