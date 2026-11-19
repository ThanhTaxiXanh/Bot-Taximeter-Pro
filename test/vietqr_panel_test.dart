import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_taximeter_pro/features/receipt/presentation/receipt_transfer_panel.dart';

const trip = <String, String>{
  'isRecorded': 'true', 'id': 'TTX-1763545000000',
  'amountVnd': '72000', 'fare': '72.000 đ',
};

Future<void> mountPanel(WidgetTester tester,
    Map<String, String> snapshot) async {
  tester.view.physicalSize = const Size(430, 940);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(
    body: SingleChildScrollView(child: ReceiptTransferPanel(
      snapshot: snapshot, bank: 'Ngân hàng kiểm thử',
      owner: 'NGUYEN VAN A', account: '0123456789',
    )),
  )));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('Mặc định tắt: chuyến đã lưu không có mã chuyển khoản',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await mountPanel(tester, trip);
    expect(find.byKey(const Key('real_vietqr_qr')), findsNothing);
    expect(find.textContaining('đang tắt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chỉ hiện mã chuyển khoản sau khi bấm',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'vietqr_real_enabled': true,
      'vietqr_bank_bin': '970403',
    });
    await mountPanel(tester, trip);
    expect(find.byKey(const Key('real_vietqr_qr')), findsNothing);
    final button = find.byKey(const Key('show_live_vietqr'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(find.byKey(const Key('real_vietqr_qr')), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    // Nội dung TLV và CRC đã được kiểm tra trong vietqr_transfer_test.dart.
    expect(find.textContaining('KHÔNG kiểm tra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bản mẫu vẫn chỉ là mã DEMO dù bật chuyển khoản',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'vietqr_real_enabled': true, 'vietqr_bank_bin': '970403',
    });
    await mountPanel(tester, const <String, String>{
      'id': 'DEMO', 'fare': '72.000 đ',
    });
    expect(find.byKey(const Key('demo_qr')), findsOneWidget);
    expect(find.byKey(const Key('real_vietqr_qr')), findsNothing);
    expect(find.text('KHÔNG THANH TOÁN'), findsOneWidget);
  });

  testWidgets('Thiếu tiền gốc: không hiện nút tạo mã chuyển khoản',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'vietqr_real_enabled': true, 'vietqr_bank_bin': '970403',
    });
    await mountPanel(tester, const <String, String>{
      'isRecorded': 'true', 'id': 'TTX-TEST', 'fare': '72.000 đ',
    });
    expect(find.byKey(const Key('show_live_vietqr')), findsNothing);
    expect(find.textContaining('không hợp lệ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
