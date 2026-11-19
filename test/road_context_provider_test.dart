import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_taximeter_pro/features/speed_limit/road_context_provider.dart';
import 'package:bot_taximeter_pro/features/speed_limit/road_speed_panel.dart';
import 'package:bot_taximeter_pro/features/speed_limit/speed_limit_engine.dart';
import 'package:bot_taximeter_pro/features/speed_limit/speed_rules.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Overpass chỉ chấp nhận HTTPS do tài xế cấu hình', () {
    expect(RoadContextProvider.verifiedEndpoint('http://example.com'), isNull);
    expect(RoadContextProvider.verifiedEndpoint(''), isNull);
    expect(RoadContextProvider.verifiedEndpoint('https://user@host.vn'),
        isNull);
    expect(RoadContextProvider.verifiedEndpoint(
        'https://example.com/api/interpreter'),
        'https://example.com/api/interpreter');
  });

  test('OSM maxspeed là tham khảo, kiểm tra số và phân loại đường', () {
    final road = RoadContextProvider.parse(<String, dynamic>{
      'elements': <Object>[
        <String, Object>{
          'type': 'way',
          'tags': <String, String>{
            'highway': 'primary', 'oneway': 'yes',
            'lanes': '2', 'maxspeed': '60',
          },
        },
      ],
    });
    expect(road, isNotNull);
    expect(road!.carriageway, Carriageway.dividedOrMultilaneOneWay);
    expect(road.postedKmh, 60);
    expect(RoadContextProvider.parse(<String, dynamic>{
      'elements': <Object>[<String, Object>{
        'type': 'way',
        'tags': <String, String>{
          'highway': 'secondary', 'maxspeed': 'walk',
        },
      }],
    })!.postedKmh, isNull);
  });

  test('Cache OSM theo ô 200m; giới hạn 10 giây khi đổi ô', () async {
    var calls = 0;
    var now = DateTime.utc(2026, 11, 19, 8);
    final provider = RoadContextProvider(clock: () => now,
      request: (uri, query) async {
        calls++;
        expect(uri.scheme, 'https');
        expect(query, contains('[highway]'));
        return <String, dynamic>{'elements': <Object>[]};
      },
    );
    const endpoint = 'https://example.com/api/interpreter';
    await provider.lookup(endpoint, 21.27, 106.19);
    await provider.lookup(endpoint, 21.27, 106.19);
    expect(calls, 1);
    await expectLater(provider.lookup(endpoint, 21.28, 106.20),
        throwsStateError);
    now = now.add(const Duration(seconds: 10));
    await provider.lookup(endpoint, 21.28, 106.20);
    expect(calls, 2);
  });

  test('Ngữ cảnh OSM không có xác minh: không báo pháp lý', () async {
    final controller = RoadSpeedController(trackGps: false);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.configure(
      selectedArea: AreaType.populated,
      selectedWay: Carriageway.unknown,
      limit: null, persistent: false, url: '',
    );
    controller.observation = const RoadObservation(
        Carriageway.dividedOrMultilaneOneWay, null, 'primary');
    expect(controller.result.source, SpeedLimitSource.ruleGuess);
    expect(controller.result.displayLabel, '~60');
    expect(controller.result.canAlert, isFalse);
    controller.observation = const RoadObservation(
        Carriageway.dividedOrMultilaneOneWay, 50, 'primary');
    expect(controller.result.source, SpeedLimitSource.posted);
    expect(controller.result.displayLabel, '~50');
    expect(controller.result.canAlert, isFalse);
  });

  test('Chỉ cảnh báo GPS đủ tin cậy sau 3s; xung cách >=15s',
      () async {
    final controller = RoadSpeedController(trackGps: false);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.configure(
      selectedArea: AreaType.unknown, selectedWay: Carriageway.unknown,
      limit: 60, persistent: true, url: '',
    );
    final start = DateTime.utc(2026, 11, 19, 8);
    void reading(int sec, {double speed = 80, double accuracy = 4}) {
      final time = start.add(Duration(seconds: sec));
      controller.sample(speed, accuracy, time, time);
    }
    reading(0);
    expect(controller.warning, isFalse);
    reading(1);
    expect(controller.warning, isFalse);
    reading(3);
    expect(controller.warning, isTrue);
    expect(controller.newPulse, isTrue);
    reading(4);
    expect(controller.newPulse, isFalse);
    reading(18);
    expect(controller.warning, isFalse,
        reason: 'Đứt GPS quá 4s phải bắt đầu lại');
    reading(19);
    reading(21);
    expect(controller.warning, isTrue);
    expect(controller.newPulse, isTrue);
    reading(22, accuracy: 28);
    expect(controller.warning, isFalse);
  });

  testWidgets('Biển mặc định --, nhập thủ công chỉ khi chủ động lưu',
      (tester) async {
    tester.view.physicalSize = const Size(440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = RoadSpeedController(trackGps: false);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(
        child: RoadSpeedPanel(controller: controller),
      )),
    ));
    await tester.pump();
    expect(find.text('--'), findsOneWidget);
    await tester.tap(find.byKey(const Key('legal_speed_open')));
    await tester.pump();
    expect(find.textContaining('nguồn cần xác minh'), findsOneWidget);
    final chip = find.widgetWithText(ActionChip, '80');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
    await tester.tap(find.text('Giữ đến khi tôi đổi'));
    await tester.pump();
    final save = find.byKey(const Key('save_speed_context'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(controller.manualKmh, 80);
    expect(controller.result.source, SpeedLimitSource.manual);
    expect(find.text('80'), findsWidgets);
  });
}
