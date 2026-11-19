import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_taximeter_pro/features/history/data/completed_trip_store.dart';
import 'package:bot_taximeter_pro/features/receipt/data/receipt_pdf_service.dart';
import 'package:bot_taximeter_pro/features/receipt/data/vietqr_transfer_payload.dart';
import 'package:bot_taximeter_pro/features/trip/trip_controller.dart';

/// Luồng liên tính năng: cước -> bản ghi -> biên lai -> QR (không gửi tiền).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Cước chờ đúng mốc 500, BOT sau làm tròn, biên lai và QR nhất quán',
      () async {
    var now = DateTime(2026, 11, 19, 10);
    var trackerMeters = 0.0;
    final active = MemoryTripStore();
    final completed = MemoryCompletedTripStore();
    final trip = TripController(
      store: active, completedStore: completed, runTimer: false,
      clock: () => now, distanceSource: () => trackerMeters,
    );
    try {
      await trip.begin();
      trackerMeters = 100;
      now = now.add(const Duration(seconds: 10));
      trip.tick();
      trackerMeters = 1600;
      now = now.add(const Duration(seconds: 20));
      trip.tick();
      expect(trip.distanceMeters, 1500);

      trip.pause();
      now = now.add(const Duration(seconds: 360));
      trip.tick();
      trip.resume();
      trip.addToll(5000);
      final stored = await trip.complete();
      expect(stored, isNotNull);
      expect(stored!.waitingSeconds, 360);
      expect(stored.waitFeeVnd, 500);
      expect(stored.fareVnd, 35000); // 30.500 làm tròn xuống + BOT.
      expect(trip.fare.total, 35000);
      expect(active.current, isNull);
      expect((await completed.all()).length, 1);

      final receipt = stored.receiptSnapshot;
      expect(receipt['isRecorded'], 'true');
      expect(receipt['amountVnd'], '35000');
      final pdfData = ReceiptPdfData.fromSnapshot(receipt);
      expect(pdfData.total, '35.000 đ');
      expect(pdfData.id, stored.id);

      final qr = VietQrTransferPayload.encode(
        bankBin: '970436', account: '123456789',
        amountVnd: int.parse(receipt['amountVnd']!),
        note: VietQrTransferPayload.noteForTrip(stored.id),
      );
      expect(VietQrTransferPayload.checksumValid(qr), isTrue);
      expect(qr, contains('5303704')); // Tiền tệ VND.
      expect(qr, contains('540535000')); // 35.000 đ; không sửa số tiền.
      await trip.complete();
      expect((await completed.all()).length, 1);
    } finally {
      trip.dispose();
    }
  });
}
