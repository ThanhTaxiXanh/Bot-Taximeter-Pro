/// Cấu hình tập trung của ứng dụng.
abstract final class AppConfig {
  static const String appNameLine1 = 'BOT';
  static const String appNameLine2 = 'TAXIMETER PRO';
  static const String packageName = 'vn.bottaximeter.pro';
  static const String applicationId = 'bot_taximeter_pro';
}

/// Bật bằng --dart-define=CI=true khi chạy kiểm thử trên GitHub Actions.
/// Các dịch vụ vị trí, mạng và bản đồ thật phải kiểm tra cờ này ở bước sau.
const bool kCI = bool.fromEnvironment('CI');
