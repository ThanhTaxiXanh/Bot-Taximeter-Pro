import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../map_tracking/data/gps_tracker.dart';
import 'speed_alert_engine.dart';

const speedAlertEnabledKey = 'speed_alert_enabled';
const speedAlertLimitKey = 'speed_alert_manual_limit_kmh';

/// Chỉ nhận GPS đã qua GpsFilter, không đọc dữ liệu biển báo chưa xác minh.
class SpeedAlertController extends ChangeNotifier {
  SpeedAlertController({GpsTracker? tracker})
      : _tracker = tracker ?? GpsTracker.instance;

  static final instance = SpeedAlertController();
  final GpsTracker _tracker;
  final SpeedAlertEngine _engine = SpeedAlertEngine();

  bool _loaded = false;
  bool _listening = false;
  bool _enabled = false;
  int _thresholdKmh = 60;
  SpeedAlertReading _reading = const SpeedAlertReading(
    status: SpeedAlertStatus.disabled, thresholdKmh: 60,
  );

  bool get enabled => _enabled;
  bool get loaded => _loaded;
  int get thresholdKmh => _thresholdKmh;
  SpeedAlertReading get reading => _reading;

  Future<void> loadAndStart() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final threshold = prefs.getInt(speedAlertLimitKey) ?? 60;
      _thresholdKmh = threshold >= 30 && threshold <= 130 ? threshold : 60;
      _enabled = prefs.getBool(speedAlertEnabledKey) ?? false;
    } catch (_) {
      _enabled = false;
      _thresholdKmh = 60;
    }
    if (!GpsTracker.useMock && !_listening) {
      _tracker.addListener(_onGps);
      _listening = true;
    }
    _engine.reset();
    _onGps();
  }

  Future<void> configure({required bool enabled, required int limitKmh}) async {
    if (limitKmh < 30 || limitKmh > 130) {
      throw ArgumentError.value(limitKmh, 'limitKmh');
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt(speedAlertLimitKey, limitKmh) ||
        !await prefs.setBool(speedAlertEnabledKey, enabled)) {
      throw StateError('Không lưu được cài đặt cảnh báo tốc độ');
    }
    _thresholdKmh = limitKmh;
    _enabled = enabled;
    _engine.reset();
    if (!GpsTracker.useMock && !_listening) {
      _tracker.addListener(_onGps);
      _listening = true;
    }
    _loaded = true;
    _onGps();
  }

  void _onGps() {
    final fix = GpsTracker.useMock ? null : _tracker.fix;
    final next = _engine.evaluate(
      enabled: _enabled,
      thresholdKmh: _thresholdKmh,
      speedKmh: fix?.speedKmh,
      accuracyMeters: fix?.point.accuracyMeters,
      fixTime: fix?.point.timestamp,
      now: DateTime.now(),
    );
    final changed = next.status != _reading.status ||
        next.thresholdKmh != _reading.thresholdKmh ||
        next.newAlert != _reading.newAlert ||
        next.speedKmh != _reading.speedKmh;
    _reading = next;
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    if (_listening) {
      _tracker.removeListener(_onGps);
      _listening = false;
    }
    super.dispose();
  }
}
