import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_taximeter_pro/core/router/app_router.dart';
import 'package:bot_taximeter_pro/features/history/presentation/history_page.dart';

Future<void> openHistory(WidgetTester tester) async {
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
  router.go(AppRouter.history);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('Lịch sử có biểu đồ và ba bộ lọc doanh thu mẫu',
      (tester) async {
    await openHistory(tester);
    expect(find.byType(HistoryPage), findsOneWidget);
    expect(find.text('Lịch sử cuốc xe & Doanh thu'), findsOneWidget);
    expect(find.text('Các cuốc xe gần đây'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('1.284.000 đ'), findsOneWidget);

    await tester.tap(find.text('7 ngày'));
    await tester.pump();
    expect(find.text('8.436.000 đ'), findsWidgets);

    await tester.tap(find.text('30 ngày'));
    await tester.pump();
    expect(find.text('31.420.000 đ'), findsOneWidget);

    await tester.tap(find.text('Hôm nay'));
    await tester.pump();
    expect(find.text('1.284.000 đ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Xem chi tiết cuốc mẫu mở biên lai', (tester) async {
    await openHistory(tester);
    final details = find.text('Xem chi tiết');
    await tester.ensureVisible(details);
    await tester.pump();
    await tester.tap(details);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Biên lai chuyến đi'), findsOneWidget);
    expect(find.text('112.000 đ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
