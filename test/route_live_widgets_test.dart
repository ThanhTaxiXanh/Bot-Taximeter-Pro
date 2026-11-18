import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_taximeter_pro/features/map_tracking/data/osrm_route_service.dart';
import 'package:bot_taximeter_pro/features/map_tracking/data/place_search_service.dart';
import 'package:bot_taximeter_pro/features/map_tracking/presentation/route_live_panel.dart';
import 'package:bot_taximeter_pro/features/map_tracking/presentation/search_live_panel.dart';
import 'package:bot_taximeter_pro/features/map_tracking/presentation/mock_travel_data.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Tra cứu thật do người dùng bấm, chọn tọa độ', (tester) async {
    LocatedPlace? chosen;
    final service = NominatimPlaceService(
      baseUrl: 'https://geocode.example.test',
      request: (_) async => <Object>[
        <String, Object>{
          'display_name': 'Hồ Gươm, Hà Nội, Việt Nam',
          'lat': '21.028', 'lon': '105.852',
        },
      ],
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: SearchLivePanel(
        query: 'Hồ Gươm',
        service: service,
        onPick: (place, start) => chosen = place,
      )),
    )));
    expect(chosen, isNull);
    await tester.tap(find.text('Tìm thật'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Hồ Gươm, Hà Nội, Việt Nam'), findsOneWidget);
    await tester.tap(find.text('Chọn điểm đến'));
    expect(chosen?.longitude, closeTo(105.852, .0001));
  });

  testWidgets('Tuyến thật trong widget test vẫn dùng Canvas', (tester) async {
    final router = OsrmRouteService(
      baseUrl: 'https://routing.example.test',
      request: (_) async => <String, dynamic>{
        'code': 'Ok',
        'routes': <Object>[
          <String, dynamic>{
            'distance': 4000, 'duration': 600,
            'geometry': <String, Object>{
              'coordinates': <Object>[
                <num>[105.8, 21.0], <num>[105.82, 21.02],
              ],
            },
            'legs': <Object>[
              <String, Object>{
                'steps': <Object>[
                  <String, Object>{
                    'name': 'Lê Lợi', 'distance': 100,
                    'maneuver': <String, String>{
                      'type': 'turn', 'modifier': 'right',
                    },
                  },
                ],
              },
            ],
          },
        ],
      },
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: RouteLivePanel(
        startName: 'Điểm A', endName: 'Điểm B', stopName: '',
        includeStop: false, is3D: false, traffic: false,
        startLatitude: '21.0', startLongitude: '105.8',
        endLatitude: '21.02', endLongitude: '105.82',
        router: router, on3D: () {}, on2D: () {}, onTraffic: () {},
      )),
    )));
    await tester.tap(find.text('Tính tuyến thật'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('Rẽ phải'), findsOneWidget);
    expect(find.textContaining('Khoảng cước:'), findsOneWidget);
    expect(find.byType(MockRouteMap), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
  });
}
