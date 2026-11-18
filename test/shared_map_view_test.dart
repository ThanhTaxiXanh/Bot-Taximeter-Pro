import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bot_taximeter_pro/shared/shared_map_view.dart';
import 'package:bot_taximeter_pro/features/map_tracking/presentation/home_map_mock.dart';
import 'package:bot_taximeter_pro/features/map_tracking/presentation/mock_travel_data.dart';

void main() {
  testWidgets('SharedMapView trong widget test chỉ tạo bản đồ Canvas',
      (tester) async {
    tester.view.physicalSize = const Size(430, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(SharedMapView.useMock, isTrue);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 250,
          child: SharedMapView(
            is3D: true, isDark: true,
            trafficEnabled: false, followVehicle: true,
          ),
        ),
      ),
    ));
    expect(find.byType(HomeMockMap), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Route dùng Canvas khi test, chọn được tuyến mẫu',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SizedBox(
        height: 210,
        child: SharedMapView(
          is3D: false, isDark: false,
          trafficEnabled: true, followVehicle: false,
          showRoute: true, routeIndex: 2,
        ),
      )),
    ));
    expect(find.byType(MockRouteMap), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gọi recenter khi test không mở bản đồ thật',
      (tester) async {
    final key = GlobalKey<SharedMapViewState>();
    var following = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(
        height: 210,
        child: SharedMapView(
          key: key,
          is3D: true, isDark: false,
          trafficEnabled: false, followVehicle: false,
          onFollowChanged: (value) => following = value,
        ),
      )),
    ));
    key.currentState!.recenter();
    await tester.pump();
    expect(following, isTrue);
    expect(find.byType(GoogleMap), findsNothing);
  });
}
