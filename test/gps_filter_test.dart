import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/map_tracking/data/gps_filter.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  GpsPoint point(
    double lat, int seconds, {
    double lon = 106.0, double accuracy = 5,
    double speed = 5,
  }) => GpsPoint(
    latitude: lat, longitude: lon, accuracyMeters: accuracy,
    speedMetersPerSecond: speed, headingDegrees: 90,
    timestamp: t0.add(Duration(seconds: seconds)),
  );

  test('Haversine: 1 độ vĩ Bắc-Nam khoảng 111,2 km', () {
    final meters = haversineMeters(21, 106, 22, 106);
    expect(meters, closeTo(111195, 200));
    expect(haversineMeters(21, 106, 21, 106), closeTo(0, .001));
  });

  test('Bỏ GPS yếu trên 25m và tọa độ sai', () {
    final filter = GpsFilter();
    expect(filter.add(point(21, 0, accuracy: 26)), isNull);
    expect(filter.add(point(100, 1)), isNull);
    expect(filter.lastFix, isNull);
    expect(filter.add(point(21, 2)), isNotNull);
  });

  test('Loại bước nhảy phi thực tế trên 200km/h', () {
    final filter = GpsFilter();
    expect(filter.add(point(21, 0)), isNotNull);
    expect(filter.add(point(22, 1)), isNull);
    expect(filter.totalMeters, 0);
  });

  test('Chỉ cộng quãng đường khi di chuyển đủ 5m và 3km/h', () {
    final filter = GpsFilter();
    filter.add(point(21, 0));
    filter.add(point(21.00002, 1, speed: 6));
    expect(filter.totalMeters, 0);
    filter.add(point(21.00010, 3, speed: 6));
    expect(filter.totalMeters, greaterThan(5));
    final before = filter.totalMeters;
    filter.add(point(21.00010, 5, speed: 0));
    filter.add(point(21.00012, 7, speed: 0));
    expect(filter.totalMeters, before);
  });

  test('Tạm dừng không cộng mét và reset về 0', () {
    final filter = GpsFilter();
    filter.add(point(21, 0));
    filter.add(point(21.00010, 5, speed: 6), recordDistance: false);
    expect(filter.totalMeters, 0);
    filter.add(point(21.00020, 10, speed: 6));
    expect(filter.totalMeters, greaterThan(5));
    filter.reset();
    expect(filter.totalMeters, 0);
    expect(filter.lastFix, isNull);
  });

  test('Làm mượt tốc độ thay vì nhảy tức thời', () {
    final filter = GpsFilter();
    filter.add(point(21, 0, speed: 0));
    final f = filter.add(point(21.00001, 1, speed: 10));
    expect(f, isNotNull);
    expect(f!.speedKmh, greaterThan(0));
    expect(f.speedKmh, lessThan(36));
  });
}
