import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/core/router/app_router.dart';

Future<void> mountApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 940);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Tìm kiếm chọn điểm đến và truyền sang lập tuyến', (tester) async {
    await mountApp(tester);
    final router = AppRouter.createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      theme: ThemeData.dark(), routerConfig: router,
    ));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('Tìm kiếm'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Kết quả tìm kiếm'), findsOneWidget);
    expect(find.text('Sân bay'), findsWidgets);

    await tester.ensureVisible(find.text('Chọn điểm đến'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('Chọn điểm đến'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Lập tuyến đường'), findsOneWidget);
    final destinations = tester.widgetList<TextField>(find.byType(TextField));
    expect(destinations.last.controller?.text,
        'Sân bay quốc tế Nội Bài (HAN)');
  });

  testWidgets('Lập tuyến đổi phương án và mở chuyến đi', (tester) async {
    await mountApp(tester);
    final router = AppRouter.createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      theme: ThemeData.dark(), routerConfig: router,
    ));
    router.go(AppRouter.route);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Lập tuyến đường'), findsOneWidget);
    expect(find.text('10 phút'), findsOneWidget);

    await tester.tap(find.text('Ít phí'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('13 phút'), findsOneWidget);

    await tester.ensureVisible(find.text('Bắt đầu dẫn đường'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('Bắt đầu dẫn đường'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Tổng cước'), findsOneWidget);
  });
}
