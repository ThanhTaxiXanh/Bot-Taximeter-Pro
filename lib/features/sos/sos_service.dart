import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../map_tracking/data/gps_tracker.dart';

typedef SosDialer = Future<bool> Function(Uri uri);
typedef SosSharer = Future<void> Function(String message);
typedef SosLocationReader = SosLocation? Function();

class SosLocation {
  const SosLocation({
    required this.latitude, required this.longitude,
    required this.accuracyMeters, required this.timestamp,
  });
  final double latitude, longitude, accuracyMeters;
  final DateTime timestamp;
}

/// Không có quyền CALL_PHONE: tel: chỉ mở ứng dụng điện thoại.
/// Không tự gọi, gửi SMS, định vị nền hay ghi lịch sử tọa độ.
class SosService {
  SosService({
    SosDialer? dialer, SosSharer? sharer,
    SosLocationReader? locationReader, DateTime Function()? clock,
  }) : _dialer = dialer ?? _openPhoneApp,
       _sharer = sharer ?? _openShareSheet,
       _locationReader = locationReader ?? _readDeviceLocation,
       _clock = clock ?? DateTime.now;

  static const phoneKey = 'sos_phone';
  static const defaultPhone = '113';

  final SosDialer _dialer;
  final SosSharer _sharer;
  final SosLocationReader _locationReader;
  final DateTime Function() _clock;

  static bool validPhone(String phone) =>
      RegExp(r'^(?:[0-9]{2,15}|\+[0-9]{7,15})$')
          .hasMatch(phone.trim());

  Future<String> configuredPhone() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(phoneKey)?.trim() ?? '';
    return validPhone(stored) ? stored : defaultPhone;
  }

  Future<void> savePhone(String value) async {
    final phone = value.trim();
    if (!validPhone(phone)) {
      throw const FormatException(
          'Số SOS chỉ chứa 2–15 chữ số hoặc + và 7–15 chữ số.');
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(phoneKey, phone)) {
      throw StateError('Không lưu được số SOS.');
    }
  }

  Future<bool> openPhoneApp(String value) async {
    final phone = value.trim();
    if (!validPhone(phone)) throw const FormatException('Số SOS không hợp lệ.');
    return _dialer(Uri(scheme: 'tel', path: phone));
  }

  /// Chỉ dùng fix GPS đã lọc, không dùng mock, định vị chưa đủ chính xác,
  /// điểm cũ >15 giây hoặc thời điểm bất thường.
  String? locationMessage() {
    final loc = _locationReader();
    if (loc == null || !loc.latitude.isFinite || !loc.longitude.isFinite ||
        loc.latitude.abs() > 90 || loc.longitude.abs() > 180 ||
        !loc.accuracyMeters.isFinite || loc.accuracyMeters < 0 ||
        loc.accuracyMeters > 25) return null;
    final age = _clock().difference(loc.timestamp);
    if (age.isNegative || age > const Duration(seconds: 15)) return null;
    final lat = loc.latitude.toStringAsFixed(6);
    final lon = loc.longitude.toStringAsFixed(6);
    return 'TÔI CẦN HỖ TRỢ KHẨN CẤP.\n'
        'Vị trí GPS hiện tại: $lat, $lon\n'
        'https://maps.google.com/?q=$lat,$lon\n'
        'Độ chính xác GPS ước tính: ' +
        loc.accuracyMeters.round().toString() +
        ' m.\nVui lòng gọi điện xác nhận trước khi hỗ trợ.';
  }

  Future<void> openPositionShare(String message) => _sharer(message);

  static SosLocation? _readDeviceLocation() {
    if (GpsTracker.useMock) return null;
    final fix = GpsTracker.instance.fix;
    if (fix == null) return null;
    final p = fix.point;
    return SosLocation(
      latitude: p.latitude, longitude: p.longitude,
      accuracyMeters: p.accuracyMeters, timestamp: p.timestamp,
    );
  }

  static Future<bool> _openPhoneApp(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<void> _openShareSheet(String message) async {
    // Chỉ mở bảng chia sẻ; không có xác nhận đã gửi tới ai.
    await SharePlus.instance.share(ShareParams(text: message));
  }
}
