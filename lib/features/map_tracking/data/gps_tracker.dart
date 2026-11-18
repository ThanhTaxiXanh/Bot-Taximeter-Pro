import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/app_config.dart';
import 'gps_filter.dart';
import 'road_name_provider.dart';

/// Vị trí thiết bị thật; không tự khởi chạy và không dùng trong CI/test.
class GpsTracker extends ChangeNotifier {
  GpsTracker._();
  static final GpsTracker instance = GpsTracker._();

  final GpsFilter _filter = GpsFilter();
  final GeocodingProvider _geocoder = NominatimGeocodingProvider();
  StreamSubscription<Position>? _subscription;
  GpsFix? _fix;
  String _message = 'GPS chưa bật';
  String? _roadName;
  GpsPoint? _roadPoint;
  double? _accuracy;
  bool _running = false;
  bool _starting = false;
  bool _trip = false;
  bool _paused = false;

  static bool get useMock =>
      kCI || (!kIsWeb && Platform.environment['FLUTTER_TEST'] == 'true');

  GpsFix? get fix => _fix;
  String? get roadName => _roadName;
  double? get accuracyMeters => _accuracy;
  String get message => useMock ? 'GPS tốt' : _message;
  bool get isTracking => _running;
  bool get isStarting => _starting;
  bool get tripActive => _trip;
  bool get hasGoodFix => _fix != null &&
      _accuracy != null && _accuracy! <= 15;
  double get distanceMeters => _filter.totalMeters;

  Future<bool> start({bool trip = false}) async {
    if (useMock) return false; // Không xin quyền hay mở dịch vụ nền khi test.
    if (_starting) return false;
    if (_running && _trip == trip) return true;
    if (_running && _trip && !trip) return true;
    _starting = true;
    _message = 'Đang kiểm tra GPS…';
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _message = 'Hãy bật dịch vụ vị trí trên điện thoại';
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _message = permission == LocationPermission.deniedForever
            ? 'GPS bị từ chối. Mở cài đặt ứng dụng để cấp quyền.'
            : 'Chưa có quyền GPS';
        return false;
      }

      // Android 13+: xin thông báo SAU quyền vị trí, không dùng để chặn GPS.
      if (trip && Platform.isAndroid) {
        try {
          await Permission.notification.request();
        } catch (_) {
          // Thông báo có thể bị chặn: vẫn thử foreground service.
        }
      }
      await _subscription?.cancel();
      if (trip && !_trip) _filter.reset();
      _trip = trip;
      _paused = false;
      final settings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 1),
              maxUpdateAge: const Duration(seconds: 5),
              foregroundNotificationConfig: trip
                  ? const ForegroundNotificationConfig(
                      notificationTitle: 'BOT TAXIMETER PRO',
                      notificationText: 'Đang chạy chuyến',
                      notificationChannelName: 'Theo dõi chuyến taxi',
                      enableWakeLock: true, setOngoing: true,
                    )
                  : null,
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high, distanceFilter: 0,
            );
      _subscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(_onPosition, onError: (Object error) {
        _fix = null;
        _accuracy = null;
        _message = 'Mất tín hiệu vị trí: kiểm tra quyền/GPS';
        notifyListeners();
      });
      _running = true;
      _message = 'Đang chờ tín hiệu GPS…';
      if (trip) {
        try { await WakelockPlus.enable(); } catch (_) {}
      }
      return true;
    } catch (_) {
      _message = 'Không thể khởi động GPS. Kiểm tra quyền ứng dụng.';
      _running = false;
      return false;
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  void _onPosition(Position position) {
    if (position.isMocked) {
      _fix = null;
      _message = 'Hệ thống đang cung cấp vị trí giả lập';
      notifyListeners();
      return;
    }
    _accuracy = position.accuracy;
    final point = GpsPoint(
      latitude: position.latitude, longitude: position.longitude,
      accuracyMeters: position.accuracy,
      speedMetersPerSecond: position.hasSpeed ? position.speed : -1,
      headingDegrees: position.heading,
      timestamp: position.timestamp,
    );
    final candidate = _filter.add(
      point, recordDistance: !_trip || !_paused,
    );
    if (candidate == null) {
      _fix = null; // không hiển thị marker từ tọa độ cũ.
      _roadName = null;
      _roadPoint = null;
      _message = 'GPS yếu / điểm nhiễu (>25m hoặc bước nhảy)';
    } else {
      _fix = candidate;
      if (_roadPoint != null &&
          haversineMeters(
            _roadPoint!.latitude, _roadPoint!.longitude,
            candidate.point.latitude, candidate.point.longitude,
          ) > 75) {
        _roadName = null;
        _roadPoint = null;
      }
      _message = position.accuracy <= 15 ? 'GPS tốt' : 'GPS yếu';
    }
    notifyListeners();
  }

  void setTripPaused(bool value) {
    _paused = value;
    notifyListeners();
  }

  /// Chỉ gọi từ nút cập nhật tên đường, không reverse-geocode từng điểm GPS.
  Future<void> refreshRoadName() async {
    if (useMock || _fix == null) return;
    final point = _fix!.point;
    final result = await _geocoder.reverse(point.latitude, point.longitude);
    if (result != null) {
      _roadName = result;
      _roadPoint = point;
      notifyListeners();
    }
  }

  Future<void> openLocationSettings() async {
    if (useMock) return;
    try { await Geolocator.openLocationSettings(); } catch (_) {}
  }

  /// Điện thoại Xiaomi: người dùng tự chọn Pin → Không hạn chế trong Cài đặt.
  Future<void> openBatterySettings() async {
    if (useMock) return;
    try { await Geolocator.openAppSettings(); } catch (_) {}
  }

  Future<void> stop() async {
    if (useMock) return;
    _running = false;
    _trip = false;
    _paused = false;
    final previous = _subscription;
    _subscription = null;
    await previous?.cancel();
    try { await WakelockPlus.disable(); } catch (_) {}
    _fix = null;
    _accuracy = null;
    _roadName = null;
    _roadPoint = null;
    _message = 'GPS đã dừng';
    notifyListeners();
  }
}
