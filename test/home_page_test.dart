import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/core/router/app_router.dart';

void main() {
  testWidgets('Home có đủ nút và chuyển chế độ bản đồ mô phỏng',
      (tester) async {
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
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('GPS tốt'), findsOneWidget);
    expect(find.text('Google Maps 3D'), findsOneWidget);
    expect(find.text('Follow xe'), findsOneWidget);
    for (final label in <String>[
      'Tìm kiếm', 'Tuyến đường', 'Doanh thu', 'Cài đặt',
      'Bắt đầu', 'Lịch sử',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('2D'));
    await tester.pump();
    expect(find.text('Google Maps 2D'), findsOneWidget);

    await tester.tap(find.text('3D'));
    await tester.pump();
    expect(find.text('Google Maps 3D'), findsOneWidget);
  });

  testWidgets('Biển tốc độ mẫu cho phép chọn số minh họa',
      (tester) async {
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
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('60'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Giới hạn tốc độ (minh họa)'), findsOneWidget);

    await tester.tap(find.text('80 km/h'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('80'), findsOneWidget);
  });

  testWidgets('Tìm kiếm ở Home mở đúng tuyến màn hình',
      (tester) async {
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
    await tester.pump(const Duration(milliseconds: 150));

    await tester.ensureVisible(find.text('Tìm kiếm'));
    await tester.pump();
    await tester.tap(find.text('Tìm kiếm'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Kết quả tìm kiếm'), findsOneWidget);
  });
}
