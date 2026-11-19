import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bot_taximeter_pro/features/history/data/completed_trip_store.dart';
import 'package:bot_taximeter_pro/features/trip/trip_controller.dart';

/// Chạy SQLite native trên Android 13, không dùng GPS/API và không đổi smoke cũ.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Lưu cuốc vào SQLite thật và xóa snapshot khi thành công',
      (tester) async {
    final snapshot = SqliteTripStore();
    final completed = SqliteCompletedTripStore();
    await snapshot.clear();

    final started = DateTime.now();
    final controller = TripController(
      store: snapshot, completedStore: completed,
      clock: () => started, distanceSource: () => 0,
      runTimer: false,
    );
    await controller.begin();
    await controller.flush();
    expect((await snapshot.read())?['state'], 'inTrip');

    final record = await controller.complete();
    expect(record?.fareVnd, 30000);
    expect(await snapshot.read(), isNull);

    final all = await completed.all();
    expect(all.where((trip) => trip.id == record?.id).length, 1);
    controller.dispose();
  });
}
