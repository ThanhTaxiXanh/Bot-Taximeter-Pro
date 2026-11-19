import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bot_taximeter_pro/core/router/app_router.dart';
import 'package:bot_taximeter_pro/features/trip/presentation/trip_page.dart';
import 'package:bot_taximeter_pro/features/trip/trip_controller.dart';
import 'package:bot_taximeter_pro/shared/glass_widgets.dart';
import 'package:bot_taximeter_pro/features/sos/sos_service.dart';
import 'package:bot_taximeter_pro/features/sos/sos_widgets.dart';

Future<TripController> openTrip(WidgetTester tester) async {
  // Fixture widget: unit test riêng đã kiểm chứng begin()/SQLite.
  // Không khởi chạy async/ticker trong vùng FakeAsync của widget test.
  final controller = TripController(
    store: MemoryTripStore(), runTimer: false,
  )..state = TripState.inTrip;
  tester.view.physicalSize = const Size(430, 940);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(controller.dispose);
  final router = AppRouter.createRouter(tripController: controller);
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(
    theme: ThemeData.dark(),
    routerConfig: router,
  ));
  router.go(AppRouter.trip);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  expect(find.byType(TripPage), findsOneWidget);
  expect(controller.isActive, isTrue);
  expect(tester.widget<NeonButton>(
    find.widgetWithText(NeonButton, 'Kết thúc'),
  ).onPressed, isNotNull);
  return controller;
}

/// Giới hạn tìm đồng hồ trong đúng thẻ, tránh trùng 00:00 giữa hai thẻ.
Finder statValue(String label, String value) => find.descendant(
  of: find.ancestor(
    of: find.text(label), matching: find.byType(StatCard),
  ),
  matching: find.text(value),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Tạm dừng và tiếp tục dùng đồng hồ controller', (tester) async {
    final controller = await openTrip(tester);
    expect(find.text('Tổng cước'), findsOneWidget);
    expect(find.text('Thời gian chờ'), findsOneWidget);
    expect(statValue('Thời gian chuyến', '00:00'), findsOneWidget);
    expect(statValue('Thời gian chờ', '00:00'), findsOneWidget);
    controller.tick(intervalSeconds: 1);
    await tester.pump();
    expect(statValue('Thời gian chuyến', '00:01'), findsOneWidget);

    await tester.tap(find.text('Tạm dừng'));
    await tester.pump();
    expect(find.text('Tiếp tục'), findsOneWidget);
    controller.tick(intervalSeconds: 1);
    await tester.pump();
    expect(statValue('Thời gian chờ', '00:01'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    expect(find.text('Tạm dừng'), findsOneWidget);
  });

  testWidgets('Kết thúc hỏi xác nhận rồi chuyển biên lai mẫu',
      (tester) async {
    await openTrip(tester);
    await tester.tap(find.text('Kết thúc'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Kết thúc chuyến đi?'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Biên lai chuyến đi'), findsOneWidget);
    expect(find.text('30.000 đ'), findsWidgets);
  });

  testWidgets('Nút SOS không gọi điện tự động', (tester) async {
    await openTrip(tester);
    await tester.tap(find.text('SOS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('SOS · Hỗ trợ khẩn cấp'), findsOneWidget);
    expect(find.text('Gọi 113'), findsOneWidget);
    expect(find.text('Chia sẻ vị trí'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pump();
  });

  test('Số SOS hợp lệ và lưu trên thiết bị, mặc định là 113', () async {
    final service = SosService();
    expect(await service.configuredPhone(), SosService.defaultPhone);
    expect(SosService.validPhone('113'), isTrue);
    expect(SosService.validPhone('+84912345678'), isTrue);
    expect(SosService.validPhone('113;999'), isFalse);
    expect(SosService.validPhone(''), isFalse);
    await expectLater(service.savePhone('113;999'), throwsFormatException);
    await service.savePhone('115');
    expect(await service.configuredPhone(), '115');
  });

  test('Vị trí cũ, sai hoặc yếu không tạo tin chia sẻ', () {
    final time = DateTime.utc(2026, 11, 19, 10);
    SosService service(SosLocation fix) => SosService(
      clock: () => time, locationReader: () => fix);
    SosLocation fix(double accuracy, DateTime timestamp) => SosLocation(
      latitude: 21.271234, longitude: 106.197654,
      accuracyMeters: accuracy, timestamp: timestamp);
    final message = service(fix(5, time)).locationMessage();
    expect(message, contains('21.271234, 106.197654'));
    expect(message, contains('maps.google.com/?q=21.271234,106.197654'));
    expect(service(fix(26, time)).locationMessage(), isNull);
    expect(service(fix(5, time.subtract(const Duration(seconds: 16))))
        .locationMessage(), isNull);
    expect(service(fix(5, time.add(const Duration(seconds: 1))))
        .locationMessage(), isNull);
  });

  testWidgets('SOS chỉ mở gọi và chia sẻ khi tài xế xác nhận',
      (tester) async {
    var dials = 0, shares = 0;
    String? sent;
    Uri? dialed;
    final time = DateTime.utc(2026, 11, 19, 10);
    final service = SosService(
      dialer: (uri) async { dials++; dialed = uri; return true; },
      sharer: (message) async { shares++; sent = message; },
      locationReader: () => SosLocation(
        latitude: 21.271234, longitude: 106.197654,
        accuracyMeters: 5, timestamp: time),
      clock: () => time,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(
        builder: (context) => TextButton(
          onPressed: () => SosDialog.show(context, service: service),
          child: const Text('Mở SOS'),
        ),
      )),
    ));
    await tester.tap(find.text('Mở SOS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('SOS · Hỗ trợ khẩn cấp'), findsOneWidget);
    expect(dials, 0);
    expect(shares, 0);

    await tester.tap(find.byKey(const Key('sos_call')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Mở trình gọi điện?'), findsOneWidget);
    expect(dials, 0);
    await tester.tap(find.byKey(const Key('sos_cancel_action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(dials, 0);

    await tester.tap(find.byKey(const Key('sos_call')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('sos_confirm_call')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(dials, 1);
    expect(dialed!.scheme, 'tel');
    expect(dialed!.path, '113');

    await tester.tap(find.byKey(const Key('sos_share')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Chia sẻ vị trí SOS?'), findsOneWidget);
    expect(shares, 0);
    await tester.tap(find.byKey(const Key('sos_confirm_share')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(shares, 1);
    expect(sent, contains('maps.google.com/?q='));
  });
}
