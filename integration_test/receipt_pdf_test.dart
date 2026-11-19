import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bot_taximeter_pro/features/receipt/data/receipt_pdf_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PDF biên lai dùng chữ tiếng Việt, tạo offline trên Android',
      (tester) async {
    final data = ReceiptPdfData.fromSnapshot(const <String, String>{
      'isRecorded': 'true',
      'id': 'TTX-TEST-ANDROID',
      'started': '09:00 - 19/11/2026',
      'finished': '09:20 - 19/11/2026',
      'fare': '72.000 đ', 'distance': '4,8 km',
      'duration': '20:00', 'waiting': '02:00',
      'waitFee': '0 đ', 'toll': '5.000 đ',
    });
    final pdf = await const ReceiptPdfService().generate(data);
    expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
    expect(pdf.length, greaterThan(4000));
  });
}
