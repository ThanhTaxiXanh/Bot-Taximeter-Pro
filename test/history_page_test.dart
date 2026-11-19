import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_taximeter_pro/core/router/app_router.dart';
import 'package:bot_taximeter_pro/features/history/data/completed_trip.dart';
import 'package:bot_taximeter_pro/features/history/data/completed_trip_store.dart';
import 'package:bot_taximeter_pro/features/history/presentation/history_page.dart';

Future<void> openHistory(WidgetTester tester, CompletedTripStore store) async {
  tester.view.physicalSize = const Size(430, 940);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = AppRouter.createRouter(completedStore: store);
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(
    theme: ThemeData.dark(),
    routerConfig: router,
  ));
  router.go(AppRouter.history);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

CompletedTrip record(String id, DateTime ended, int fare) => CompletedTrip(
  id: id, startedAt: ended.subtract(const Duration(minutes: 10)),
  finishedAt: ended, fareVnd: fare, distanceMeters: 2000,
  elapsedSeconds: 600, waitingSeconds: 0, waitFeeVnd: 0, tollVnd: 0,
);

void main() {
  testWidgets('Chưa có cuốc thật: không hiển thị doanh thu mẫu', (tester) async {
    await openHistory(tester, MemoryCompletedTripStore());
    expect(find.byType(HistoryPage), findsOneWidget);
    expect(find.text('Các cuốc xe gần đây'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('0 đ'), findsOneWidget);
    expect(find.textContaining('Chưa có chuyến đã hoàn thành'),
        findsOneWidget);
    expect(find.text('1.284.000 đ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Doanh thu 1/7/30 ngày chỉ từ cuốc đã lưu', (tester) async {
    final now = DateTime.now();
    final store = MemoryCompletedTripStore();
    await store.save(record('TTX-TODAY', now, 60000));
    await store.save(record('TTX-WEEK',
        now.subtract(const Duration(days: 2)), 40000));
    await store.save(record('TTX-MONTH',
        now.subtract(const Duration(days: 12)), 20000));
    await openHistory(tester, store);

    expect(find.text('60.000 đ'), findsWidgets);
    await tester.tap(find.text('7 ngày'));
    await tester.pump();
    expect(find.text('100.000 đ'), findsOneWidget);
    await tester.tap(find.text('30 ngày'));
    await tester.pump();
    expect(find.text('120.000 đ'), findsOneWidget);
    await tester.tap(find.text('Hôm nay'));
    await tester.pump();
    expect(find.text('60.000 đ'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Xem chi tiết cuốc đã lưu mở biên lai tham khảo', (tester) async {
    final store = MemoryCompletedTripStore();
    await store.save(record('TTX-RECORDED', DateTime.now(), 75000));
    await openHistory(tester, store);
    final details = find.text('Xem chi tiết');
    await tester.ensureVisible(details);
    await tester.pump();
    await tester.tap(details);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Biên lai chuyến đi'), findsOneWidget);
    expect(find.text('75.000 đ'), findsWidgets);
    expect(find.textContaining('CƯỚC GPS THAM KHẢO'), findsOneWidget);
    expect(find.text('Nguyễn Văn Hưng (mẫu)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
