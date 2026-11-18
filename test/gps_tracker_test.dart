import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/map_tracking/data/gps_tracker.dart';

void main() {
  test('CI/widget test không xin quyền GPS và không mở dịch vụ nền',
      () async {
    expect(GpsTracker.useMock, isTrue);
    final gps = GpsTracker.instance;
    expect(gps.message, 'GPS tốt'); // văn bản mô phỏng cho smoke test cũ
    expect(await gps.start(), isFalse);
    expect(await gps.start(trip: true), isFalse);
    expect(gps.isTracking, isFalse);
    expect(gps.fix, isNull);
    await gps.refreshRoadName(); // không gọi mạng
    await gps.openBatterySettings();
    await gps.openLocationSettings();
    await gps.stop();
    expect(gps.fix, isNull);
  });
}
