import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bot_taximeter_pro/core/router/app_router.dart';
import 'package:bot_taximeter_pro/features/trip/presentation/trip_page.dart';
import 'package:bot_taximeter_pro/features/trip/trip_controller.dart';
import 'package:bot_taximeter_pro/shared/glass_widgets.dart';

Future<TripController> openTrip(WidgetTester tester) async {
  final controller = TripController(
    store: MemoryTripStore(), runTimer: false,
  );
  await tester.runAsync(() => controller.begin());
  tester.view.physicalSize = const Size(430, 940);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await controller.complete();
    controller.dispose();
  });
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
    expect(find.text('SOS (bản mẫu)'), findsOneWidget);
    await tester.tap(find.text('Đã hiểu'));
    await tester.pump();
  });
}
