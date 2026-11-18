import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_taximeter_pro/features/road_safety/speed_alert_controller.dart';
import 'package:bot_taximeter_pro/features/road_safety/speed_alert_widgets.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Cảnh báo tốc độ mặc định tắt và lưu ngưỡng thủ công',
      (tester) async {
    final controller = SpeedAlertController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(430, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: Column(children: <Widget>[
        SpeedAlertSettings(controller: controller),
        SpeedAlertBanner(controller: controller),
      ])),
    )));
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.enabled, false);
    expect(find.textContaining('GPS chưa đủ tin cậy'), findsNothing);
    await tester.tap(find.text('Bật cảnh báo ngưỡng cá nhân'));
    await tester.pump();
    final choice = find.text('80 km/h');
    await tester.ensureVisible(choice);
    await tester.pump();
    await tester.tap(choice);
    await tester.ensureVisible(find.text('Lưu cảnh báo tốc độ'));
    await tester.pump();
    await tester.tap(find.text('Lưu cảnh báo tốc độ'));
    await tester.pump(const Duration(milliseconds: 150));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(speedAlertEnabledKey), isTrue);
    expect(prefs.getInt(speedAlertLimitKey), 80);
    expect(find.textContaining('GPS chưa đủ tin cậy'), findsOneWidget);
    expect(find.textContaining('không phải giới hạn pháp lý'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Khôi phục cấu hình cảnh báo trên máy, không cần GPS/API', () async {
    SharedPreferences.setMockInitialValues({
      speedAlertEnabledKey: true,
      speedAlertLimitKey: 70,
    });
    final controller = SpeedAlertController();
    await controller.loadAndStart();
    expect(controller.enabled, isTrue);
    expect(controller.thresholdKmh, 70);
    expect(controller.reading.newAlert, isFalse);
    await controller.configure(enabled: false, limitKmh: 60);
    expect(controller.enabled, isFalse);
    controller.dispose();
  });
}
