import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/trip/trip_controller.dart';

void main() {
  test('State machine, snapshot 3s, khôi phục và hoàn tất', () async {
    var now = DateTime.utc(2026, 11, 18, 10, 0, 0);
    double gps = 0;
    final store = MemoryTripStore();
    final controller = TripController(
      store: store, clock: () => now,
      distanceSource: () => gps, runTimer: false,
    );
    await controller.begin();
    expect(controller.state, TripState.inTrip);
    expect(controller.fare.total, 30000);

    now = now.add(const Duration(seconds: 1));
    controller.tick(); // neo GPS đầu tiên
    gps = 1200;
    now = now.add(const Duration(seconds: 2));
    controller.tick();
    await controller.flush();
    expect(controller.distanceMeters, 1200);
    expect(controller.elapsedSeconds, 3);
    expect(store.current?['state'], 'inTrip');
    expect(store.current?['elapsed'], 3);

    controller.pause();
    expect(controller.state, TripState.waiting);
    gps = 1300;
    now = now.add(const Duration(seconds: 5));
    controller.tick();
    expect(controller.waitingSeconds, 5);
    expect(controller.distanceMeters, 1200); // khi chờ không cộng GPS.
    await controller.flush();

    final resumed = TripController(
      store: store, clock: () => now,
      distanceSource: () => gps, runTimer: false,
    );
    expect(await resumed.loadPending(), true);
    now = now.add(const Duration(hours: 1)); // máy đóng trước khi mở lại
    await resumed.restore();
    expect(resumed.state, TripState.waiting);
    expect(resumed.distanceMeters, 1200);
    expect(resumed.waitingSeconds, 5);
    resumed.resume();
    expect(resumed.waitingSeconds, 5);
    resumed.addToll(5000);
    await resumed.complete();
    expect(resumed.state, TripState.completed);
    expect(resumed.fare.toll, 5000);
    expect(store.current, isNull);
    expect(await resumed.loadPending(), false);
    controller.dispose();
    resumed.dispose();
  });

  test('Bỏ chuyến cũ xóa snapshot, chuyển trạng thái hợp lệ', () async {
    final store = MemoryTripStore();
    await store.write(<String, dynamic>{
      'version': 1, 'state': 'inTrip', 'elapsed': 1,
    });
    final controller = TripController(store: store, runTimer: false);
    expect(await controller.loadPending(), true);
    await controller.discardPending();
    expect(store.current, isNull);
    await controller.begin();
    controller.resume(); // Không thể resume khi đang InTrip.
    expect(controller.state, TripState.inTrip);
    controller.pause(); controller.pause();
    expect(controller.state, TripState.waiting);
    controller.resume();
    expect(controller.state, TripState.inTrip);
    expect(() => controller.addToll(-1), throwsStateError);
    await controller.complete();
    controller.dispose();
  });

  test('Tự vào Waiting sau 10 giây dưới 3km/h (mặc định tắt)', () async {
    var now = DateTime.utc(2026, 11, 18);
    double speed = 2.0;
    final controller = TripController(
      store: MemoryTripStore(), clock: () => now,
      speedSource: () => speed, distanceSource: () => 0,
      runTimer: false,
    );
    await controller.begin();
    expect(controller.autoWaiting, false);
    controller.autoWaiting = true;
    for (var i = 0; i < 10; i++) {
      now = now.add(const Duration(seconds: 1));
      controller.tick();
    }
    expect(controller.state, TripState.waiting);
    speed = 10;
    now = now.add(const Duration(seconds: 1));
    controller.tick();
    expect(controller.state, TripState.inTrip);
    await controller.complete();
    controller.dispose();
  });
}
