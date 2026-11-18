import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Nominatim tương thích, tự cấu hình địa chỉ qua --dart-define.
/// Mặc định TẮT; không gửi GPS đến máy chủ OSM công cộng khi chưa được phép.
const geocodingBaseUrl = String.fromEnvironment('GEOCODING_BASE_URL');

abstract class GeocodingProvider {
  Future<String?> reverse(double latitude, double longitude);
}

typedef ReverseRequest = Future<Map<String, dynamic>?> Function(
  double latitude, double longitude,
);

/// Chỉ tra cứu theo thao tác người dùng. Không tự quét các ô 50m.
class NominatimGeocodingProvider implements GeocodingProvider {
  NominatimGeocodingProvider({
    this.baseUrl = geocodingBaseUrl,
    ReverseRequest? request,
    DateTime Function()? clock,
  }) : _request = request, _clock = clock ?? DateTime.now;

  final String baseUrl;
  final ReverseRequest? _request;
  final DateTime Function() _clock;
  final Map<String, String> _cache = <String, String>{};
  DateTime? _lastRequest;
  bool _inFlight = false;

  bool get configured => _request != null ||
      (baseUrl.trim().startsWith('https://') &&
       Uri.tryParse(baseUrl)?.host != 'nominatim.openstreetmap.org');
  int get cacheCount => _cache.length;

  String _cell(double lat, double lon) {
    // xấp xỉ ô 50m tại vĩ độ Việt Nam; chỉ là khóa cache.
    final latStep = 50 / 111320;
    final lonStep = latStep / math.cos(lat * math.pi / 180)
        .abs().clamp(.15, 1.0);
    return '${(lat / latStep).round()}:${(lon / lonStep).round()}';
  }

  @override
  Future<String?> reverse(double latitude, double longitude) async {
    if (!configured || !latitude.isFinite || !longitude.isFinite ||
        latitude.abs() > 90 || longitude.abs() > 180) return null;
    final key = _cell(latitude, longitude);
    if (_cache.containsKey(key)) return _cache[key];
    if (_inFlight) return null;
    final now = _clock();
    if (_lastRequest != null &&
        now.difference(_lastRequest!) < const Duration(milliseconds: 1200)) {
      return null; // không tạo hàng đợi bắn dồn.
    }
    _lastRequest = now;
    _inFlight = true;
    try {
      final data = await (_request?.call(latitude, longitude) ??
          _fetch(latitude, longitude));
      final address = data?['address'];
      if (address is! Map) return null;
      final road = <String>[
        'road', 'pedestrian', 'residential', 'living_street',
        'footway', 'highway',
      ].map((key) => address[key])
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .firstOrNull;
      if (road == null) return null;
      if (_cache.length >= 256) _cache.remove(_cache.keys.first);
      _cache[key] = road;
      return road;
    } catch (_) {
      return null;
    } finally {
      _inFlight = false;
    }
  }

  Future<Map<String, dynamic>?> _fetch(double lat, double lon) async {
    final base = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    // URL do tài xế/nhà vận hành cấu hình: chỉ cho phép HTTPS.
    if (!base.startsWith('https://')) return null;
    final url = Uri.parse('$base/reverse').replace(queryParameters: {
      'format': 'jsonv2', 'lat': '$lat', 'lon': '$lon',
      'zoom': '18', 'addressdetails': '1',
    });
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.userAgentHeader,
          'BotTaxiMeterPro/0.1 (+https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro)');
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'vi');
      final response = await request.close()
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await utf8.decoder.bind(response)
          .join().timeout(const Duration(seconds: 6));
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } finally {
      client.close(force: true);
    }
  }
}
