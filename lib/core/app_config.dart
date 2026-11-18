/// Cấu hình tập trung của ứng dụng.
abstract final class AppConfig {
  static const String appNameLine1 = 'BOT';
  static const String appNameLine2 = 'TAXIMETER PRO';
  // Android applicationId thực tế do lệnh flutter create trong CI sinh ra.
  static const String packageName = 'vn.bottaximeter.bot_taximeter_pro';
  static const String applicationId = packageName;
}

/// Bật bằng --dart-define=CI=true khi chạy kiểm thử trên GitHub Actions.
/// GPS, mạng và bản đồ thật phải tôn trọng cờ này ở các bước sau.
const bool kCI = bool.fromEnvironment('CI');
