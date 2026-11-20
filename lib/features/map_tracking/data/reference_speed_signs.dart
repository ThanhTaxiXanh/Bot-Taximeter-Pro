import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Biển tốc độ suy ra CHƯA XÁC MINH, không cung cấp đầu vào cảnh báo/cước.
class ReferenceSpeedSign {
  const ReferenceSpeedSign(this.id, this.lat, this.lon, this.kmh, this.direction);
  final int id, kmh, direction;
  final double lat, lon;
}

abstract final class ReferenceSpeedSigns {
  /// Thử nghiệm 147 biển trong vùng ±0,075 độ quanh bản đồ mẫu Bắc Giang.
  /// Được trích từ speed_limit_signs.csv người dùng cung cấp (20/11/2026).
  /// Chưa rõ giấy phép, ngày cập nhật hoặc ý nghĩa mã hướng.
  static const int pilotCount = 147;
  static const double pilotLat = 21.2741, pilotLon = 106.1946;
  static const int maxMarkers = 16;
  // CSV gzip + base64 với cột id,lat_e6,lon_e6,speed,direction.
  static const String _packed =
    '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'
    '65zfCHh50HnmP+7xL1XhWLzuEgAA';

  static final List<ReferenceSpeedSign> data =
      parse(utf8.decode(gzip.decode(base64.decode(_packed))));

  static List<ReferenceSpeedSign> parse(String csv) {
    final lines = const LineSplitter().convert(csv.trim());
    if (lines.isEmpty ||
        lines.first != 'id,lat_e6,lon_e6,speed,direction') {
      throw const FormatException('Sai cấu trúc bộ dữ liệu biển tốc độ');
    }
    final unique = <int, ReferenceSpeedSign>{};
    for (final line in lines.skip(1)) {
      final fields = line.split(',');
      if (fields.length != 5) continue;
      final values = fields.map(int.tryParse).toList();
      if (values.any((v) => v == null)) continue;
      final id = values[0]!, lat = values[1]! / 1e6;
      final lon = values[2]! / 1e6, speed = values[3]!;
      final direction = values[4]!;
      if (id < 0 || lat < -90 || lat > 90 ||
          lon < -180 || lon > 180 || speed < 5 || speed > 120 ||
          direction < 0 || direction > 255) continue;
      unique.putIfAbsent(id, () =>
          ReferenceSpeedSign(id, lat, lon, speed, direction));
    }
    return List<ReferenceSpeedSign>.unmodifiable(unique.values);
  }

  /// Chọn tối đa 16 biển ở gần GPS; không quét toàn bộ bản đồ hay gọi mạng.
  static List<ReferenceSpeedSign> nearby(double lat, double lon, {
    int radiusMeters = 1600,
    int max = maxMarkers,
    List<ReferenceSpeedSign>? records,
  }) {
    if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180 ||
        radiusMeters <= 0 || max <= 0) return const [];
    final cosLat = math.cos(lat * math.pi / 180);
    final matching = <(double, ReferenceSpeedSign)>[];
    for (final sign in records ?? data) {
      final y = (sign.lat - lat) * 111320;
      final x = (sign.lon - lon) * 111320 * cosLat;
      final distanceSq = x * x + y * y;
      if (distanceSq <= radiusMeters * radiusMeters) {
        matching.add((distanceSq, sign));
      }
    }
    matching.sort((a, b) => a.$1.compareTo(b.$1));
    final cellKeys = <String>{};
    final chosen = <ReferenceSpeedSign>[];
    for (final (_, sign) in matching) {
      final cell = (sign.lat * 2500).floor().toString() + ':' +
          (sign.lon * 2500).floor().toString();
      if (!cellKeys.add(cell)) continue;
      chosen.add(sign);
      if (chosen.length >= math.min(max, maxMarkers)) break;
    }
    return chosen;
  }

  /// Pin màu cam chỉ là ghi nhận chưa kiểm chứng tại hiện trường.
  static Set<Marker> markersNear(double lat, double lon) => <Marker>{
    for (final sign in nearby(lat, lon))
      Marker(
        markerId: MarkerId('sign-ref-' + sign.id.toString()),
        position: LatLng(sign.lat, sign.lon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Suy ra ~' + sign.kmh.toString() + ' km/h · CHƯA XÁC MINH',
          snippet: 'ID ' + sign.id.toString() +
              ' · hướng thô ' + sign.direction.toString() +
              '; không dùng để cảnh báo',
        ),
      ),
  };
}
