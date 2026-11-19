import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Câu chào khách: chỉ hiển thị nội dung, không truy cập GPS hay mạng.
class LedGreetingPage extends StatelessWidget {
  const LedGreetingPage({
    super.key, required this.message, required this.sizeLabel,
  });

  final String message;
  final String sizeLabel;

  static const defaultGreeting = 'Xin chào quý khách!';

  /// Loại ký tự điều khiển, giới hạn 120 ký tự hiển thị, giữ tiếng Việt.
  static String displayMessage(String raw) {
    final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return defaultGreeting;
    return String.fromCharCodes(clean.runes.take(120));
  }

  static double fontSizeFor(String size) => switch (size) {
    'Nhỏ' => 64,
    'Lớn' => 120,
    _ => 88,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundStart,
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.background),
      child: SafeArea(
        child: Stack(children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 52),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: AppColors.navyInk,
                  border: Border.all(color: AppColors.borderActive),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.16),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 660,
                        child: Text(
                          displayMessage(message),
                          key: const Key('led_message'),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: fontSizeFor(sizeLabel),
                            fontWeight: FontWeight.w900,
                            color: AppColors.cyanBright,
                            height: 1.16,
                            shadows: <Shadow>[
                              Shadow(
                                color: AppColors.cyan.withValues(alpha: 0.55),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8, right: 10,
            child: IconButton.filledTonal(
              key: const Key('close_led_greeting'),
              tooltip: 'Đóng màn hình LED',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          const Positioned(
            bottom: 12, left: 16, right: 16,
            child: Text(
              'BOT TAXIMETER PRO · CHÀO MỪNG QUÝ KHÁCH',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}

/// Tạo màn LED tạm thời bên trên Cài đặt, không thêm route GoRouter thứ 8.
class LedGreetingLaunchButton extends StatelessWidget {
  const LedGreetingLaunchButton({
    super.key, required this.controller, required this.sizeLabel,
  });

  final TextEditingController controller;
  final String sizeLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const Text(
        'Xem trước bằng nội dung đang nhập, chưa tự lưu cài đặt. '
        'Chỉ thao tác khi xe đã dừng an toàn.',
        style: TextStyle(color: AppColors.muted, fontSize: 11),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('open_led_greeting'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LedGreetingPage(
              message: controller.text,
              sizeLabel: sizeLabel,
            ),
          ),
        ),
        icon: const Icon(Icons.tv),
        label: const Text('Mở màn hình LED chào khách'),
      ),
    ],
  );
}
