import 'dart:convert';
import 'dart:io';

import 'road_name_provider.dart';

typedef PlaceRequest = Future<Object?> Function(Uri uri);

class LocatedPlace {
  const LocatedPlace(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude;
  final double longitude;

  static LocatedPlace? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['display_name'];
    final lat = double.tryParse((raw['lat'] ?? '').toString());
    final lon = double.tryParse((raw['lon'] ?? '').toString());
    if (name is! String || name.trim().isEmpty ||
        lat == null || lon == null || !lat.isFinite || !lon.isFinite ||
        lat.abs() > 90 || lon.abs() > 180) return null;
    return LocatedPlace(name, lat, lon);
  }
}

/// Chỉ dùng Nominatim self-hosted/nhà cung cấp đã cho phép.
/// Không nhúng nominatim.openstreetmap.org vào sản phẩm taxi.
class NominatimPlaceService {
  NominatimPlaceService({
    this.baseUrl = geocodingBaseUrl,
    PlaceRequest? request,
    DateTime Function()? clock,
  }) : _request = request, _clock = clock ?? DateTime.now;

  static final instance = NominatimPlaceService();
  String baseUrl;
  final PlaceRequest? _request;
  final DateTime Function() _clock;
  final Map<String, (DateTime, List<LocatedPlace>)> _cache = {};
  DateTime? _lastRequest;
  bool _inFlight = false;

  /// Cho phép đổi máy chủ ngay trong Cài đặt, xóa cache cũ theo host.
  void setBaseUrl(String value) {
    final next = value.trim();
    if (next == baseUrl) return;
    baseUrl = next;
    _cache.clear();
    _lastRequest = null;
  }

  bool get configured {
    final uri = Uri.tryParse(baseUrl.trim());
    return uri != null && uri.scheme == 'https' &&
        uri.host.isNotEmpty && uri.host != 'nominatim.openstreetmap.org';
  }

  Future<List<LocatedPlace>> search(String query) async {
    final q = query.trim();
    if (!configured) throw StateError('Chưa cấu hình máy chủ Nominatim được phép');
    if (q.length < 3 || q.length > 160) {
      throw ArgumentError('Hãy nhập địa chỉ từ 3 đến 160 ký tự');
    }
    final key = q.toLowerCase();
    final now = _clock();
    final cached = _cache[key];
    if (cached != null && now.difference(cached.$1) <
        const Duration(hours: 24)) return cached.$2;
    if (_inFlight) throw StateError('Đang tra cứu, vui lòng thử lại');
    _inFlight = true;
    try {
      if (_lastRequest != null) {
        final elapsed = now.difference(_lastRequest!);
        const gap = Duration(milliseconds: 1200);
        if (elapsed < gap) await Future<void>.delayed(gap - elapsed);
      }
      _lastRequest = _clock();
      final base = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');
      final uri = Uri.parse(base + '/search').replace(queryParameters: {
        'q': q, 'format': 'jsonv2', 'limit': '5',
        'countrycodes': 'vn', 'addressdetails': '0',
      });
      final result = await (_request?.call(uri) ?? _fetch(uri));
      if (result is! List) throw const FormatException('Phản hồi địa chỉ sai');
      final places = result.map(LocatedPlace.fromJson)
          .whereType<LocatedPlace>().take(5).toList(growable: false);
      if (_cache.length >= 64) _cache.remove(_cache.keys.first);
      _cache[key] = (_clock(), places);
      return places;
    } finally {
      _inFlight = false;
    }
  }

  Future<Object?> _fetch(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader,
          'BotTaxiMeterPro/0.1 (+https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro)');
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'vi');
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Nominatim HTTP ' + response.statusCode.toString());
      }
      final body = await utf8.decoder.bind(response).join()
          .timeout(const Duration(seconds: 8));
      if (body.length > 1000000) throw const FormatException('Phản hồi quá lớn');
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }
}
