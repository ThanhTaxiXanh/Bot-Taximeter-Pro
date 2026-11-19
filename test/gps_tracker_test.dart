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

  test('Chế độ Home lấy GPS thưa; chuyến đi giữ 1 giây và 0 mét', () {
    expect(GpsPowerPolicy.interval(trip: false),
        const Duration(seconds: 5));
    expect(GpsPowerPolicy.distanceFilter(trip: false), 10);
    expect(GpsPowerPolicy.maxUpdateAge(trip: false),
        const Duration(seconds: 10));
    expect(GpsPowerPolicy.interval(trip: true),
        const Duration(seconds: 1));
    expect(GpsPowerPolicy.distanceFilter(trip: true), 0);
    expect(GpsPowerPolicy.maxUpdateAge(trip: true),
        const Duration(seconds: 5));
  });

  test('Chỉ dừng GPS xem trước khi app vào nền và không có chuyến', () {
    bool stop({
      bool paused = true, bool tracking = true,
      bool starting = false, bool tripTracking = false,
      bool activeTrip = false,
    }) => GpsPowerPolicy.shouldStopPreview(
      appPaused: paused, tracking: tracking, starting: starting,
      tripTracking: tripTracking, activeTrip: activeTrip,
    );
    expect(stop(), isTrue);
    expect(stop(paused: false), isFalse);
    expect(stop(tracking: false), isFalse);
    expect(stop(starting: true), isFalse);
    expect(stop(tripTracking: true), isFalse);
    expect(stop(activeTrip: true), isFalse);
  });
}
