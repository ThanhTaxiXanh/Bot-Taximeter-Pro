import 'dart:convert';
import 'dart:io';

const routingBaseUrl = String.fromEnvironment('ROUTING_BASE_URL');

typedef RouteRequest = Future<Map<String, dynamic>> Function(Uri uri);

class RoutePoint {
  const RoutePoint(this.latitude, this.longitude);
  final double latitude, longitude;

  bool get valid => latitude.isFinite && longitude.isFinite &&
      latitude.abs() <= 90 && longitude.abs() <= 180;
  String get osrm => longitude.toStringAsFixed(6) +
      ',' + latitude.toStringAsFixed(6);
}

class RouteTurn {
  const RouteTurn(this.type, this.modifier, this.road, this.meters);
  final String type, modifier, road;
  final double meters;

  String get instruction {
    final action = switch (type) {
      'depart' => 'Xuất phát',
      'arrive' => 'Đến nơi',
      'turn' => switch (modifier) {
        'left' || 'slight left' || 'sharp left' => 'Rẽ trái',
        'right' || 'slight right' || 'sharp right' => 'Rẽ phải',
        'uturn' => 'Quay đầu',
        _ => 'Đi tiếp',
      },
      'roundabout' || 'rotary' => 'Vào vòng xuyến',
      'merge' => 'Nhập làn',
      'fork' => 'Đi theo nhánh đường',
      'on ramp' || 'off ramp' => 'Vào/ra đường nhánh',
      'new name' || 'continue' => 'Đi tiếp',
      _ => 'Theo tuyến',
    };
    return road.isEmpty ? action : action + ' · ' + road;
  }
}

class PlannedRoute {
  const PlannedRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
    required this.turns,
  });
  final double distanceMeters, durationSeconds;
  final List<RoutePoint> points;
  final List<RouteTurn> turns;
}

/// OSRM qua HTTPS của nhà vận hành; không sử dụng demo server cho taxi.
class OsrmRouteService {
  OsrmRouteService({this.baseUrl = routingBaseUrl, RouteRequest? request,
    DateTime Function()? clock})
      : _request = request, _clock = clock ?? DateTime.now;

  static final instance = OsrmRouteService();
  String baseUrl;
  final RouteRequest? _request;
  final DateTime Function() _clock;
  final Map<String, (DateTime, List<PlannedRoute>)> _cache = {};

  /// Cho phép đổi máy chủ ngay trong Cài đặt, xóa cache cũ theo host.
  void setBaseUrl(String value) {
    final next = value.trim();
    if (next == baseUrl) return;
    baseUrl = next;
    _cache.clear();
    
  }

  bool get configured {
    final url = Uri.tryParse(baseUrl.trim());
    return url != null && url.scheme == 'https' &&
        url.host.isNotEmpty && url.host != 'router.project-osrm.org';
  }

  Future<List<PlannedRoute>> route(List<RoutePoint> waypoints) async {
    if (!configured) throw StateError('Chưa cấu hình máy chủ OSRM được phép');
    if (waypoints.length < 2 || waypoints.length > 3 ||
        waypoints.any((p) => !p.valid)) {
      throw ArgumentError('Cần 2 hoặc 3 tọa độ hợp lệ');
    }
    final path = waypoints.map((p) => p.osrm).join(';');
    final now = _clock();
    final cached = _cache[path];
    if (cached != null && now.difference(cached.$1) <
        const Duration(minutes: 10)) return cached.$2;
    final base = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse(base + '/route/v1/driving/' + path)
        .replace(queryParameters: {
      'steps': 'true', 'alternatives': 'true',
      'geometries': 'geojson', 'overview': 'full',
    });
    final json = await (_request?.call(uri) ?? _fetch(uri));
    final routes = parseRoutes(json);
    if (_cache.length >= 24) _cache.remove(_cache.keys.first);
    _cache[path] = (_clock(), routes);
    return routes;
  }

  static List<PlannedRoute> parseRoutes(Map<String, dynamic> json) {
    if (json['code'] != 'Ok' || json['routes'] is! List) {
      throw const FormatException('OSRM không tìm thấy tuyến');
    }
    final result = <PlannedRoute>[];
    for (final raw in (json['routes'] as List).take(3)) {
      if (raw is! Map || raw['distance'] is! num ||
          raw['duration'] is! num) continue;
      final distance = (raw['distance'] as num).toDouble();
      final duration = (raw['duration'] as num).toDouble();
      final geometry = raw['geometry'];
      if (geometry is! Map || geometry['coordinates'] is! List ||
          !distance.isFinite || !duration.isFinite ||
          distance < 0 || duration < 0) continue;
      final points = <RoutePoint>[];
      for (final pair in geometry['coordinates'] as List) {
        if (pair is List && pair.length >= 2 &&
            pair[0] is num && pair[1] is num) {
          final p = RoutePoint(
              (pair[1] as num).toDouble(), (pair[0] as num).toDouble());
          if (p.valid) points.add(p);
        }
      }
      if (points.length < 2) continue;
      final turns = <RouteTurn>[];
      final legs = raw['legs'];
      if (legs is List) {
        for (final leg in legs) {
          if (leg is! Map || leg['steps'] is! List) continue;
          for (final step in leg['steps'] as List) {
            if (step is! Map) continue;
            final maneuver = step['maneuver'];
            if (maneuver is! Map) continue;
            turns.add(RouteTurn(
              (maneuver['type'] ?? '').toString(),
              (maneuver['modifier'] ?? '').toString(),
              (step['name'] ?? '').toString(),
              step['distance'] is num
                  ? (step['distance'] as num).toDouble() : 0,
            ));
          }
        }
      }
      result.add(PlannedRoute(distanceMeters: distance,
          durationSeconds: duration, points: points, turns: turns));
    }
    if (result.isEmpty) throw const FormatException('OSRM không có tuyến hợp lệ');
    return result;
  }

  Future<Map<String, dynamic>> _fetch(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader,
          'BotTaxiMeterPro/0.1 (+https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro)');
      final response = await req.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('OSRM HTTP ' + response.statusCode.toString());
      }
      final body = await utf8.decoder.bind(response).join()
          .timeout(const Duration(seconds: 10));
      if (body.length > 2000000) throw const FormatException('OSRM quá lớn');
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi OSRM sai định dạng');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}
