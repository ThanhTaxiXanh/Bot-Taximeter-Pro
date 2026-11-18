import 'package:flutter_test/flutter_test.dart';

import 'package:bot_taximeter_pro/features/map_tracking/data/place_search_service.dart';
import 'package:bot_taximeter_pro/features/map_tracking/data/osrm_route_service.dart';
import 'package:bot_taximeter_pro/features/fare_meter/fare_calculator.dart';

void main() {
  test('Nominatim công cộng và URL không an toàn bị từ chối', () async {
    final public = NominatimPlaceService(
        baseUrl: 'https://nominatim.openstreetmap.org');
    expect(public.configured, isFalse);
    expect(NominatimPlaceService(baseUrl: 'http://example.test')
        .configured, isFalse);
    await expectLater(public.search('Hà Nội'), throwsStateError);
  });

  test('Nominatim tìm thủ công, giới hạn và cache kết quả', () async {
    var requests = 0;
    Uri? received;
    final service = NominatimPlaceService(
      baseUrl: 'https://geocode.example.test/api',
      request: (uri) async {
        requests++;
        received = uri;
        return <Object>[
          <String, Object>{
            'display_name': 'Hà Nội, Việt Nam',
            'lat': '21.0278', 'lon': '105.8342',
          },
          <String, Object>{
            'display_name': 'Tọa độ lỗi', 'lat': '1000', 'lon': '105',
          },
        ];
      },
    );
    final places = await service.search('Hà Nội');
    expect(places, hasLength(1));
    expect(places.first.latitude, closeTo(21.0278, .00001));
    expect(received!.queryParameters['q'], 'Hà Nội');
    expect(received!.queryParameters['limit'], '5');
    expect(received!.queryParameters['countrycodes'], 'vn');
    expect((await service.search('hà nội')).length, 1);
    expect(requests, 1);
    await expectLater(service.search('HN'), throwsArgumentError);
  });

  test('OSRM parse GeoJSON, chỉ dẫn rẽ, cache và cước ước tính', () async {
    var requests = 0;
    final service = OsrmRouteService(
      baseUrl: 'https://routing.example.test',
      request: (uri) async {
        requests++;
        expect(uri.path, contains('/route/v1/driving/'));
        expect(uri.queryParameters['steps'], 'true');
        expect(uri.queryParameters['geometries'], 'geojson');
        return <String, dynamic>{
          'code': 'Ok',
          'routes': <Object>[
            <String, dynamic>{
              'distance': 3800.0, 'duration': 600.0,
              'geometry': <String, Object>{
                'coordinates': <Object>[
                  <num>[105.8, 21.0], <num>[105.82, 21.02],
                ],
              },
              'legs': <Object>[
                <String, Object>{
                  'steps': <Object>[
                    <String, Object>{
                      'name': 'Lê Lợi', 'distance': 300.0,
                      'maneuver': <String, String>{
                        'type': 'turn', 'modifier': 'right',
                      },
                    },
                  ],
                },
              ],
            },
          ],
        };
      },
    );
    final points = <RoutePoint>[
      const RoutePoint(21.0, 105.8),
      const RoutePoint(21.02, 105.82),
    ];
    final routes = await service.route(points);
    expect(routes, hasLength(1));
    expect(routes.first.points.first.latitude, 21.0);
    expect(routes.first.turns.first.instruction, 'Rẽ phải · Lê Lợi');
    expect(routes.first.durationSeconds, 600);
    final fare = const FareCalculator(FareConfig()).estimate(
        routes.first.distanceMeters / 1000);
    expect(fare.$1, greaterThanOrEqualTo(30000));
    expect(fare.$2, greaterThan(fare.$1));
    await service.route(points);
    expect(requests, 1);
  });

  test('OSRM không nhận dữ liệu lỗi hoặc route không kết nối', () async {
    expect(OsrmRouteService(baseUrl: 'https://router.project-osrm.org')
        .configured, isFalse);
    expect(() => OsrmRouteService.parseRoutes({
      'code': 'NoRoute', 'routes': [],
    }), throwsFormatException);
    expect(() => OsrmRouteService.parseRoutes({
      'code': 'Ok', 'routes': [
        {'distance': -1, 'duration': 10, 'geometry': {
          'coordinates': [[105.8, 21.0], [105.81, 21.01]],
        }},
      ],
    }), throwsFormatException);
    final service = OsrmRouteService(
      baseUrl: 'https://routing.example.test',
      request: (_) async => {'code': 'Ok', 'routes': []},
    );
    await expectLater(service.route([const RoutePoint(95, 105),
      const RoutePoint(21, 105)]), throwsArgumentError);
  });
}
