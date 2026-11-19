import 'package:flutter_test/flutter_test.dart';

import 'package:bot_taximeter_pro/features/history/data/completed_trip.dart';
import 'package:bot_taximeter_pro/features/history/data/completed_trip_store.dart';
import 'package:bot_taximeter_pro/features/trip/trip_controller.dart';

CompletedTrip sample(String id, DateTime finished, {int amount = 60000}) =>
    CompletedTrip(
      id: id, startedAt: finished.subtract(const Duration(minutes: 12)),
      finishedAt: finished, fareVnd: amount,
      distanceMeters: 2000, elapsedSeconds: 720, waitingSeconds: 60,
      waitFeeVnd: 0, tollVnd: 5000,
    );

class FailingCompletedStore implements CompletedTripStore {
  final MemoryCompletedTripStore delegate = MemoryCompletedTripStore();
  bool shouldFail = true;

  @override
  Future<void> save(CompletedTrip trip) async {
    if (shouldFail) throw StateError('SQLite lỗi thử nghiệm');
    await delegate.save(trip);
  }
  @override
  Future<List<CompletedTrip>> all() => delegate.all();
}

void main() {
  test('Serial hóa cuốc xe bảo toàn giá trị, không suy đoán đã thu tiền', () {
    final trip = sample('TTX-1', DateTime(2026, 11, 19, 9));
    final decoded = CompletedTrip.fromMap(trip.toMap());
    expect(decoded.id, trip.id);
    expect(decoded.fareVnd, 60000);
    expect(decoded.distanceMeters, 2000);
    expect(decoded.waitingSeconds, 60);
    expect(decoded.receiptSnapshot['isRecorded'], 'true');
    expect(decoded.receiptSnapshot['amountVnd'], '60000');
    expect(decoded.receiptSnapshot['payment'], isNull);
    expect(decoded.receiptSnapshot['pickup'], isNull);
  });

  test('Lưu cùng ID không nhân đôi doanh thu', () async {
    final store = MemoryCompletedTripStore();
    await store.save(sample('one', DateTime(2026, 11, 19), amount: 72000));
    await store.save(sample('one', DateTime(2026, 11, 20), amount: 999999));
    await store.save(sample('two', DateTime(2026, 11, 20), amount: 31000));
    final trips = await store.all();
    expect(trips.length, 2);
    expect(RevenueStats.fromTrips(trips).totalFare, 103000);
    expect(RevenueStats.fromTrips(trips).totalMeters, 4000);
    expect(trips.first.id, 'two');
  });

  test('Bộ lọc khoảng ngày địa phương tính đúng ngày đầu', () {
    final start = startOfPeriod(DateTime(2026, 11, 19, 16), 7);
    expect(start.day, 13);
    expect(start.hour, 0);
    expect(startOfPeriod(DateTime(2026, 11, 19, 9), 1).day, 19);
    expect(formatDuration(3671), '01:01:11');
  });

  test('Không xóa snapshot nếu ghi lịch sử thất bại', () async {
    var now = DateTime(2026, 11, 19, 10);
    final snapshot = MemoryTripStore();
    final completed = FailingCompletedStore();
    final controller = TripController(
      store: snapshot, completedStore: completed,
      runTimer: false, clock: () => now,
      distanceSource: () => 0,
    );
    await controller.begin();
    now = now.add(const Duration(seconds: 8));
    controller.tick();
    await expectLater(controller.complete(), throwsStateError);
    expect(controller.isActive, isTrue);
    expect(snapshot.current, isNotNull);

    completed.shouldFail = false;
    final saved = await controller.complete();
    expect(saved?.fareVnd, 30000);
    expect(controller.state, TripState.completed);
    expect(snapshot.current, isNull);
    expect((await completed.all()).length, 1);
    await controller.complete(); // gọi lặp không tăng số cuốc
    expect((await completed.all()).length, 1);
    controller.dispose();
  });
}
