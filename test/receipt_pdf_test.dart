import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/receipt/data/receipt_pdf_service.dart';

const recorded = <String, String>{
  'isRecorded': 'true',
  'id': 'TTX-1763545000000',
  'started': '09:00 - 19/11/2026',
  'finished': '09:20 - 19/11/2026',
  'fare': '72.000 đ',
  'distance': '4,8 km',
  'duration': '20:00',
  'waiting': '02:00',
  'waitFee': '0 đ',
  'toll': '5.000 đ',
};

void main() {
  test('Không xuất khi dữ liệu mẫu/chưa lưu, tên tệp được làm sạch', () {
    expect(() => ReceiptPdfData.fromSnapshot(const <String, String>{
      'id': 'TTX-TEST', 'fare': '72.000 đ',
    }), throwsStateError);
    final safe = ReceiptPdfData.fromSnapshot({
      ...recorded, 'id': 'TTX/2026?fake',
    });
    expect(safe.filename, 'BOT-TaxiMeterPro-TTX_2026_fake.pdf');
    expect(safe.filename.contains('/'), isFalse);
  });

  testWidgets('Tạo PDF A4 offline từ biên lai thực, có header PDF',
      (tester) async {
    final data = ReceiptPdfData.fromSnapshot(recorded);
    Uint8List? bytes;
    await tester.runAsync(() async {
      bytes = await const ReceiptPdfService().generate(data);
    });
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(4000));
    expect(ascii.decode(bytes!.sublist(0, 5)), '%PDF-');
    expect(ascii.decode(bytes!.sublist(bytes!.length - 10),
        allowInvalid: true), contains('%%EOF'));
    expect(tester.takeException(), isNull);
  });
}
