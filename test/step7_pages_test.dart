import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_taximeter_pro/core/router/app_router.dart';

Future<void> _open(WidgetTester tester, String path,
    {Map<String, String>? extra}) async {
  tester.view.physicalSize = const Size(430, 940);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = AppRouter.createRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(
    theme: ThemeData.dark(),
    routerConfig: router,
  ));
  router.go(path, extra: extra);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Biên lai nhận tiền cuốc mẫu và QR DEMO có thể ẩn',
      (tester) async {
    await _open(tester, AppRouter.receipt, extra: <String, String>{
      'fare': '112.000 đ',
      'id': 'TTX-250126-0147',
    });
    expect(find.text('Biên lai chuyến đi'), findsOneWidget);
    expect(find.text('112.000 đ'), findsOneWidget);
    expect(find.textContaining('KHÔNG PHẢI HÓA ĐƠN'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('KHÔNG THANH TOÁN'), findsOneWidget);

    final cash = find.text('Tiền Mặt');
    await tester.ensureVisible(cash);
    await tester.pump();
    await tester.tap(cash);
    await tester.pump();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Phương thức thanh toán'), findsOneWidget);
    final export = find.text('Xuất PDF');
    await tester.ensureVisible(export);
    await tester.pump();
    await tester.tap(export);
    await tester.pump();
    expect(find.textContaining('Chỉ xuất PDF cho chuyến đã lưu'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cài đặt đổi 2D và lưu trên thiết bị bằng shared_preferences',
      (tester) async {
    await _open(tester, AppRouter.settings);
    expect(find.text('Lưu cài đặt'), findsOneWidget);
    expect(find.text('Bản đồ & Camera'), findsOneWidget);
    expect(find.text('Biểu phí & Phí chờ'), findsOneWidget);

    await tester.tap(find.text('2D'));
    await tester.pump();
    expect(find.text('Xem trước (Góc 60° - 2D)'), findsOneWidget);

    final save = find.text('Lưu cài đặt');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 450));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('map_3d'), false);
    expect(prefs.getDouble('map_tilt'), 60.0);
    expect(tester.takeException(), isNull);
  });
}
