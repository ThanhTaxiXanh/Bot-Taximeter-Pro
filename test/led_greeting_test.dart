import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_taximeter_pro/features/settings/presentation/led_greeting_page.dart';
import 'package:bot_taximeter_pro/features/settings/presentation/settings_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Lời chào LED loại ký tự điều khiển và giới hạn độ dài', () {
    expect(LedGreetingPage.displayMessage('  \n  '),
        LedGreetingPage.defaultGreeting);
    expect(LedGreetingPage.displayMessage(' Xin \n chào \t quý khách! '),
        'Xin chào quý khách!');
    expect(LedGreetingPage.displayMessage(List<String>.filled(200, 'A').join()).length, 120);
    expect(LedGreetingPage.fontSizeFor('Nhỏ'), 64);
    expect(LedGreetingPage.fontSizeFor('Vừa'), 88);
    expect(LedGreetingPage.fontSizeFor('Lớn'), 120);
  });

  testWidgets('LED từ Cài đặt hiển thị lời chào lưu trên máy và đóng được',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'led_greeting': 'Chào mừng lên Taxi Xanh',
      'font_size': 'Lớn',
    });
    tester.view.physicalSize = const Size(430, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: SettingsPage()),
    );
    await tester.pump(const Duration(milliseconds: 350));
    final open = find.byKey(const Key('open_led_greeting'));
    expect(open, findsOneWidget);
    await tester.ensureVisible(open);
    await tester.pump();
    await tester.tap(open);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(LedGreetingPage), findsOneWidget);
    final text = tester.widget<Text>(find.byKey(const Key('led_message')));
    expect(text.data, 'Chào mừng lên Taxi Xanh');
    expect(text.style!.fontSize, 120);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('close_led_greeting')));
    // Đợi MaterialPageRoute hoàn tất animation pop trước khi đếm widget.
    await tester.pumpAndSettle();
    expect(find.byType(LedGreetingPage), findsNothing);
    expect(find.byType(SettingsPage), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('led_greeting'), 'Chào mừng lên Taxi Xanh');
    expect(prefs.getString('font_size'), 'Lớn');
    expect(tester.takeException(), isNull);
  });

  testWidgets('LED xem trước thay đổi chưa lưu, không tự ghi bộ nhớ',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'led_greeting': 'Lời chào cũ',
    });
    final input = TextEditingController(text: 'Xin kính chào quý khách!');
    addTearDown(input.dispose);
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LedGreetingLaunchButton(
          controller: input, sizeLabel: 'Vừa',
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('open_led_greeting')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Xin kính chào quý khách!'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('led_message')))
        .style!.fontSize, 88);
    expect(tester.takeException(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('led_greeting'), 'Lời chào cũ');
  });
}
