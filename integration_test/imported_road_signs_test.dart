import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:bot_taximeter_pro/features/map_tracking/data/imported_road_signs.dart';

/// Kiểm thử SQLite Android trên tệp tạm; không đụng dữ liệu chuyến đi.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CSV vào SQLite, ghim phủ viewport và phục hồi offline',
      (tester) async {
    final root = await getDatabasesPath();
    final dbPath = '$root/ci_imported_signs_step28.db';
    final csv = File('$root/ci_imported_signs_step28.csv');
    await deleteDatabase(dbPath);
    final store = ImportedRoadSigns.forTesting(dbPath);
    ImportedRoadSigns? reopened;
    try {
      final sink = csv.openWrite();
      sink.writeln(ImportedRoadSigns.trafficHeader);
      var id = 0;
      // 8 x 4 ô, mỗi ô 40 biển: kiểm tra giới hạn và phân bố ghim.
      for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 4; col++) {
          for (var i = 0; i < 40; i++) {
            final lat = 20.0 + row * .1 + .001 + i * .0001;
            final lon = 105.0 + col * .1 + .001 + i * .0001;
            sink.writeln('$id,' + lon.toStringAsFixed(6) + ',' +
                lat.toStringAsFixed(6) + ',1,255,60,0,0,0');
            id++;
          }
        }
      }
      await sink.flush();
      await sink.close();
      expect(await store.importCsv(XFile(csv.path)), 1280);
      expect(store.count, 1280);
      final bounds = LatLngBounds(
        southwest: const LatLng(20.0, 105.0),
        northeast: const LatLng(20.8, 105.4),
      );
      final markers = await store.markersInBounds(bounds);
      expect(markers.length, 32);
      final cells = markers.map((m) {
        final p = m.position;
        return (p.latitude - 20.0).toStringAsFixed(2) + ':' +
            (p.longitude - 105.0).toStringAsFixed(2);
      }).toSet();
      expect(cells.length, 32);
      expect(markers.every((m) => m.infoWindow.title != null &&
          m.infoWindow.title!.contains('DỮ LIỆU THU THẬP')), isTrue);
      expect(await store.markersInBounds(LatLngBounds(
        southwest: const LatLng(10, 100),
        northeast: const LatLng(11, 101),
      )), isEmpty);

      // Header sai không được xóa 1.280 biển đang có.
      await csv.writeAsString('id,lat,lon\n1,20.0,105.0\n');
      await expectLater(store.importCsv(XFile(csv.path)),
          throwsA(isA<FormatException>()));
      expect(store.count, 1280);

      // Đóng/mở SQLite lại vẫn còn dữ liệu offline.
      await store.closeForTesting();
      reopened = ImportedRoadSigns.forTesting(dbPath);
      await reopened.loadCount();
      expect(reopened.count, 1280);
      expect((await reopened.markersInBounds(bounds)).length, 32);

      // Nhập tệp tốc độ thay thế tập cũ, không cộng dồn.
      await csv.writeAsString(
          ImportedRoadSigns.speedHeader + '\n42,105.01,20.01,80,255,1\n');
      expect(await reopened.importCsv(XFile(csv.path)), 1);
      expect(reopened.count, 1);
      final one = await reopened.markersInBounds(bounds);
      expect(one.length, 1);
      expect(one.single.infoWindow.title, contains('80 km/h'));
    } finally {
      await store.closeForTesting();
      if (reopened != null) await reopened.closeForTesting();
      if (await csv.exists()) await csv.delete();
      await deleteDatabase(dbPath);
    }
  });
}
