import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_taximeter_pro/features/map_tracking/data/place_search_service.dart';
import 'package:bot_taximeter_pro/features/map_tracking/data/osrm_route_service.dart';
import 'package:bot_taximeter_pro/features/map_tracking/data/routing_server_config.dart';
import 'package:bot_taximeter_pro/features/settings/presentation/routing_server_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    NominatimPlaceService.instance.setBaseUrl('');
    OsrmRouteService.instance.setBaseUrl('');
  });

  tearDown(() {
    NominatimPlaceService.instance.setBaseUrl('');
    OsrmRouteService.instance.setBaseUrl('');
  });

  testWidgets('Lưu và đọc URL HTTPS đã được phép trên điện thoại',
      (tester) async {
    tester.view.physicalSize = const Size(430, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: RoutingServerSettings(),
      )),
    ));
    await tester.pump(const Duration(milliseconds: 350));

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'https://geo.example.test');
    await tester.enterText(fields.at(1), 'https://route.example.test');
    await tester.ensureVisible(find.text('Lưu máy chủ tuyến'));
    await tester.pump();
    await tester.tap(find.text('Lưu máy chủ tuyến'));
    await tester.pump(const Duration(milliseconds: 350));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(geocodingServerKey),
        'https://geo.example.test');
    expect(prefs.getString(osrmServerKey), 'https://route.example.test');
    expect(NominatimPlaceService.instance.configured, isTrue);
    expect(OsrmRouteService.instance.configured, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Từ chối máy chủ công cộng bị cấm', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: RoutingServerSettings(),
      )),
    ));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField).first,
        'https://nominatim.openstreetmap.org');
    await tester.tap(find.text('Lưu máy chủ tuyến'));
    await tester.pump();
    expect(find.textContaining('Chỉ dùng URL HTTPS hợp lệ'),
        findsOneWidget);
    expect(NominatimPlaceService.instance.configured, isFalse);
    expect(tester.takeException(), isNull);
  });
}
