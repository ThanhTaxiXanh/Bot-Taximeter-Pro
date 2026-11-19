import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../map_tracking/data/gps_tracker.dart';
import 'speed_limit_engine.dart';
import 'speed_rules.dart';

typedef OverpassRequest = Future<Map<String, dynamic>> Function(
    Uri endpoint, String query);

/// OSM chỉ là gợi ý; không xác nhận biển báo hợp pháp.
class RoadObservation {
  const RoadObservation(this.carriageway, this.postedKmh, this.roadType);
  final Carriageway carriageway;
  final int? postedKmh;
  final String roadType;
}

class RoadContextProvider {
  RoadContextProvider({OverpassRequest? request, DateTime Function()? clock})
      : _request = request ?? _httpRequest,
        _clock = clock ?? DateTime.now;
  final OverpassRequest _request;
  final DateTime Function() _clock;
  final Map<String, RoadObservation?> _cache = {};
  DateTime? _lastCall;

  static String? verifiedEndpoint(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty || uri.hasFragment) return null;
    return uri.toString();
  }

  static String cell(double lat, double lon) {
    final x = (lat * 111000 / 200).floor();
    final y = (lon * 111000 * math.cos(lat * math.pi / 180) / 200).floor();
    return '$x:$y';
  }

  Future<RoadObservation?> lookup(
      String endpoint, double latitude, double longitude) async {
    final url = verifiedEndpoint(endpoint);
    if (url == null || !latitude.isFinite || !longitude.isFinite ||
        latitude.abs() > 90 || longitude.abs() > 180) {
      throw ArgumentError('Máy chủ HTTPS hoặc tọa độ không hợp lệ');
    }
    final key = url + ':' + cell(latitude, longitude);
    if (_cache.containsKey(key)) return _cache[key];
    final now = _clock();
    if (_lastCall != null &&
        now.difference(_lastCall!) < const Duration(seconds: 10)) {
      throw StateError('Chờ 10 giây giữa hai lần tra cứu OSM');
    }
    _lastCall = now;
    final query = '[out:json][timeout:8];way(around:50,' +
        latitude.toStringAsFixed(6) + ',' + longitude.toStringAsFixed(6) +
        ')[highway];out center 12;';
    final road = parse(await _request(Uri.parse(url), query));
    if (_cache.length >= 64) _cache.remove(_cache.keys.first);
    _cache[key] = road;
    return road;
  }

  static RoadObservation? parse(Map<String, dynamic> data) {
    final elements = data['elements'];
    if (elements is! List) return null;
    for (final item in elements) {
      if (item is! Map || item['type'] != 'way') continue;
      final tags = item['tags'];
      if (tags is! Map || tags['highway'] is! String) continue;
      final highway = tags['highway'] as String;
      const allowed = <String>{
        'motorway', 'trunk', 'primary', 'secondary', 'tertiary',
        'residential', 'unclassified', 'living_street', 'service',
      };
      if (!allowed.contains(highway)) continue;
      final oneway = tags['oneway']?.toString() ?? '';
      final lanes = int.tryParse(tags['lanes']?.toString() ?? '');
      Carriageway way = Carriageway.unknown;
      if (oneway == 'yes' && lanes != null && lanes >= 2) {
        way = Carriageway.dividedOrMultilaneOneWay;
      } else if (oneway == 'no' || (oneway == 'yes' && lanes == 1)) {
        way = Carriageway.twoWayOrSingleLaneOneWay;
      }
      final speed = tags['maxspeed']?.toString() ?? '';
      final parsed = RegExp(r'^[0-9]{1,3}$').hasMatch(speed)
          ? int.tryParse(speed) : null;
      final max = parsed != null && parsed >= 5 && parsed <= 120
          ? parsed : null;
      return RoadObservation(way, max, highway);
    }
    return null;
  }

  static Future<Map<String, dynamic>> _httpRequest(
      Uri endpoint, String query) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.postUrl(endpoint)
          .timeout(const Duration(seconds: 6));
      req.headers.contentType = ContentType(
          'application', 'x-www-form-urlencoded', charset: 'utf-8');
      req.headers.set(HttpHeaders.userAgentHeader, 'BOT-TaxiMeterPro/1.0');
      req.write('data=' + Uri.encodeQueryComponent(query));
      final response = await req.close()
          .timeout(const Duration(seconds: 9));
      if (response.statusCode != 200) {
        throw StateError('OSM trả mã ' + response.statusCode.toString());
      }
      final raw = await response.transform(utf8.decoder).join()
          .timeout(const Duration(seconds: 9));
      if (raw.length > 250000) throw StateError('Dữ liệu OSM quá lớn');
      return jsonDecode(raw) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}

/// Cùng cấu hình cho Home/Trip; không can thiệp cảnh báo cá nhân.
class RoadSpeedController extends ChangeNotifier {
  RoadSpeedController({RoadContextProvider? provider,
      DateTime Function()? clock, bool trackGps = true})
      : _provider = provider ?? RoadContextProvider(),
        _clock = clock ?? DateTime.now {
    if (trackGps) GpsTracker.instance.addListener(_onGps);
  }
  static final instance = RoadSpeedController();
  final RoadContextProvider _provider;
  final DateTime Function() _clock;
  final SpeedLimitEngine _engine = const SpeedLimitEngine();
  Future<void>? _loading;

  AreaType area = AreaType.unknown;
  Carriageway carriageway = Carriageway.unknown;
  VehicleClass vehicle = VehicleClass.lightPassengerOrTruck;
  int? manualKmh;
  bool untilChanged = false;
  double? anchorLat, anchorLon;
  RoadObservation? observation;
  double? observationLat, observationLon;
  String overpassUrl = '';
  bool warning = false, newPulse = false;
  DateTime? _overSince, _lastPulse, _lastSample;

  SpeedLimitResult get result => _engine.resolve(RoadContext(
    vehicleClass: vehicle, areaType: area,
    carriageway: carriageway == Carriageway.unknown
        ? (observation?.carriageway ?? Carriageway.unknown) : carriageway,
    areaInferred: carriageway == Carriageway.unknown &&
        observation != null &&
        observation!.carriageway != Carriageway.unknown,
    manualLimitKmh: manualKmh,
    postedLimitKmh: observation?.postedKmh,
    postedConfirmed: false,
  ));

  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      overpassUrl = p.getString('road_overpass_url') ?? '';
      vehicle = (p.getString('vehicle_type') ?? 'Ô tô con') == 'Ô tô con'
          ? VehicleClass.lightPassengerOrTruck : VehicleClass.unknown;
      area = AreaType.values.firstWhere(
        (e) => e.name == p.getString('road_speed_area'),
        orElse: () => AreaType.unknown);
      carriageway = Carriageway.values.firstWhere(
        (e) => e.name == p.getString('road_speed_way'),
        orElse: () => Carriageway.unknown);
      manualKmh = p.getInt('road_speed_manual');
      untilChanged = p.getBool('road_speed_until_changed') ?? false;
      anchorLat = p.getDouble('road_speed_lat');
      anchorLon = p.getDouble('road_speed_lon');
      _onGps();
    } catch (_) { /* Không có cài đặt: giữ trạng thái an toàn. */ }
    notifyListeners();
  }

  Future<void> configure({required AreaType selectedArea,
      required Carriageway selectedWay, required int? limit,
      required bool persistent, required String url}) async {
    if (limit != null && (limit < 5 || limit > 120)) {
      throw ArgumentError('Biển phải từ 5 đến 120 km/h');
    }
    final normalized = url.trim();
    if (normalized.isNotEmpty &&
        RoadContextProvider.verifiedEndpoint(normalized) == null) {
      throw ArgumentError('Máy chủ Overpass phải dùng HTTPS');
    }
    if (limit != null && !persistent && GpsTracker.instance.fix == null) {
      throw StateError('Cần GPS để ghi đè cho đoạn đường này');
    }
    final p = await SharedPreferences.getInstance();
    area = selectedArea; carriageway = selectedWay;
    manualKmh = limit; untilChanged = persistent;
    anchorLat = limit != null && !persistent
        ? GpsTracker.instance.fix!.point.latitude : null;
    anchorLon = limit != null && !persistent
        ? GpsTracker.instance.fix!.point.longitude : null;
    overpassUrl = normalized;
    await p.setString('road_speed_area', area.name);
    await p.setString('road_speed_way', carriageway.name);
    await p.setString('road_overpass_url', overpassUrl);
    if (limit == null) { await p.remove('road_speed_manual'); }
    else { await p.setInt('road_speed_manual', limit); }
    await p.setBool('road_speed_until_changed', untilChanged);
    if (anchorLat == null) { await p.remove('road_speed_lat'); }
    else { await p.setDouble('road_speed_lat', anchorLat!); }
    if (anchorLon == null) { await p.remove('road_speed_lon'); }
    else { await p.setDouble('road_speed_lon', anchorLon!); }
    _resetAlert(); notifyListeners();
  }

  Future<void> lookupRoad() async {
    if (GpsTracker.useMock) throw StateError('Không gọi mạng khi CI');
    final fix = GpsTracker.instance.fix;
    if (fix == null || fix.point.accuracyMeters > 15) {
      throw StateError('Cần GPS tốt trước khi tra cứu');
    }
    if (overpassUrl.isEmpty) throw StateError('Chưa có máy chủ Overpass');
    observation = await _provider.lookup(overpassUrl,
        fix.point.latitude, fix.point.longitude);
    observationLat = fix.point.latitude;
    observationLon = fix.point.longitude;
    _resetAlert(); notifyListeners();
  }

  void _onGps() {
    final fix = GpsTracker.instance.fix;
    if (fix == null) { _resetAlert(); notifyListeners(); return; }
    if (manualKmh != null && !untilChanged &&
        anchorLat != null && anchorLon != null &&
        _meters(anchorLat!, anchorLon!, fix.point.latitude,
            fix.point.longitude) > 200) {
      manualKmh = null; anchorLat = null; anchorLon = null;
      SharedPreferences.getInstance().then((p) async {
        await p.remove('road_speed_manual');
        await p.remove('road_speed_lat');
        await p.remove('road_speed_lon');
      });
    }
    if (observation != null && observationLat != null &&
        observationLon != null &&
        _meters(observationLat!, observationLon!, fix.point.latitude,
            fix.point.longitude) > 200) {
      observation = null;
    }
    sample(fix.speedKmh, fix.point.accuracyMeters, fix.point.timestamp,
        _clock());
  }

  static double _meters(double a, double b, double c, double d) {
    final dx = (a - c) * 111000;
    final dy = (b - d) * 111000 * math.cos(c * math.pi / 180);
    return math.sqrt(dx * dx + dy * dy);
  }

  void _resetAlert() {
    warning = false; newPulse = false;
    _overSince = null; _lastSample = null;
  }

  /// GPS kém/cũ, mất ngữ cảnh hoặc vượt <3 giây: không cảnh báo.
  void sample(double? speed, double? accuracy, DateTime? fixTime,
      DateTime now) {
    final legal = result;
    if (!legal.canAlert || speed == null || !speed.isFinite || speed < 0 ||
        accuracy == null || accuracy > 15 || fixTime == null ||
        now.isBefore(fixTime) ||
        now.difference(fixTime) > const Duration(seconds: 5) ||
        (_lastSample != null && !now.isAfter(_lastSample!))) {
      _resetAlert(); notifyListeners(); return;
    }
    if (_lastSample != null &&
        now.difference(_lastSample!) > const Duration(seconds: 4)) {
      _overSince = null; warning = false;
    }
    _lastSample = now;
    final band = _engine.assess(speed, legal);
    if (band == OverspeedBand.unavailable || band == OverspeedBand.none) {
      _overSince = null; warning = false; newPulse = false;
    } else {
      _overSince ??= now;
      warning = now.difference(_overSince!) >= const Duration(seconds: 3);
      newPulse = warning && (_lastPulse == null ||
          now.difference(_lastPulse!) >= const Duration(seconds: 15));
      if (newPulse) _lastPulse = now;
    }
    notifyListeners();
  }
}
