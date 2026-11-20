import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bot_taximeter_pro/shared/gps_marker_art.dart';
import 'package:bot_taximeter_pro/shared/shared_map_view.dart';

void main() {
  test('GPS thiếu tên đường phải hiện trạng thái chưa xác định', () {
    expect(GpsMarkerArt.roadLabel(null), GpsMarkerArt.unknownRoad);
    expect(GpsMarkerArt.roadLabel(' \n\t '), GpsMarkerArt.unknownRoad);
    expect(GpsMarkerArt.roadLabel('  Đường Trần Nhân Vũ  '),
        'Đường Trần Nhân Vũ');
  });

  test('Nhãn GPS không mang ký tự điều khiển hoặc dài tràn màn', () {
    expect(GpsMarkerArt.roadLabel('Đường \n Trần \t Nhân Vũ'),
        'Đường Trần Nhân Vũ');
    final long = List<String>.filled(80, 'Đ').join();
    final label = GpsMarkerArt.roadLabel(long);
    expect(label.runes.length, 44);
    expect(label.endsWith('…'), isTrue);
  });

  testWidgets('Tên đường không làm widget test nạp GoogleMap thật',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(height: 270, child: SharedMapView(
          is3D: true, isDark: false, trafficEnabled: true,
          followVehicle: true, roadName: 'Đường Trần Nhân Vũ',
          vehiclePosition: LatLng(21.2741, 106.1946),
        )),
      ),
    ));
    expect(SharedMapView.useMock, isTrue);
    expect(find.byType(SharedMapView), findsOneWidget);
    expect(tester.widget<SharedMapView>(find.byType(SharedMapView))
        .roadName, 'Đường Trần Nhân Vũ');
    expect(find.byType(GoogleMap), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
