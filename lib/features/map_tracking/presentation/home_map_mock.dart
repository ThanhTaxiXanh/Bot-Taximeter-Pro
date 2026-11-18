import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Bản đồ vẽ nội bộ; không lấy ảnh/tile hay truy cập dịch vụ bản đồ.
class HomeMockMap extends StatelessWidget {
  const HomeMockMap({
    super.key,
    required this.is3D,
    required this.isDark,
    required this.traffic,
  });

  final bool is3D;
  final bool isDark;
  final bool traffic;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            painter: HomeMockMapPainter(
              is3D: is3D,
              isDark: isDark,
              traffic: traffic,
            ),
          ),
          Positioned(
            left: 20,
            top: 118,
            child: _PlaceLabel(
              icon: Icons.storefront,
              label: 'ACboutique244',
              color: const Color(0xFF2879D9),
            ),
          ),
          Positioned(
            right: 64,
            top: 85,
            child: const _PlaceLabel(
              icon: Icons.hotel,
              label: 'Khách sạn\nHương Giang',
              color: AppColors.poi,
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.55),
            child: Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: const Color(0xFF1367E9),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 3),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xAA1675FF),
                    blurRadius: 22,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.navigation,
                color: AppColors.white,
                size: 30,
              ),
            ),
          ),
        ],
      );
}

class _PlaceLabel extends StatelessWidget {
  const _PlaceLabel({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 13,
            backgroundColor: color,
            child: Icon(icon, color: AppColors.white, size: 15),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              shadows: const <Shadow>[
                Shadow(color: AppColors.white, blurRadius: 5),
              ],
            ),
          ),
        ],
      );
}

/// Góc nghiêng chỉ là phối cảnh minh họa, chưa phải camera Google Maps.
class HomeMockMapPainter extends CustomPainter {
  const HomeMockMapPainter({
    required this.is3D,
    required this.isDark,
    required this.traffic,
  });

  final bool is3D;
  final bool isDark;
  final bool traffic;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final background = isDark
        ? const <Color>[Color(0xFF172A43), Color(0xFF354D62)]
        : const <Color>[Color(0xFFCDD8E4), Color(0xFFF0F2F5)];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: background,
        ).createShader(Offset.zero & size),
    );

    final mainRoad = Paint()
      ..color = isDark
          ? const Color(0xFF677C91)
          : const Color(0xFFB4C5D6);
    final sideRoad = Paint()
      ..color = isDark
          ? const Color(0xFF50667A)
          : const Color(0xFFD3DBE3);

    // Hai đại lộ dọc và các ngõ ngang, không đại diện địa lý thực.
    canvas.drawPath(
      Path()
        ..moveTo(w * .39, 0)
        ..lineTo(w * .57, 0)
        ..lineTo(w * .65, h)
        ..lineTo(w * .33, h)
        ..close(),
      mainRoad,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * .04, 0)
        ..lineTo(w * .16, 0)
        ..lineTo(w * .08, h)
        ..lineTo(0, h)
        ..close(),
      sideRoad,
    );
    for (var i = 1; i <= 4; i++) {
      final y = h * i / 5;
      canvas.drawRect(Rect.fromLTWH(0, y, w, 8), sideRoad);
    }

    final roof = Paint()
      ..color = isDark
          ? const Color(0xFF8292A3)
          : const Color(0xFFF8F8F6);
    final wall = Paint()
      ..color = isDark
          ? const Color(0xFF536679)
          : const Color(0xFFBBC6D2);
    final stroke = Paint()
      ..color = isDark
          ? const Color(0xFF475A6D)
          : const Color(0xFFCAD2DC)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 6; col++) {
        final x = (col / 6 + .015) * w;
        // Chừa phần trống cho trục đường chính.
        if (x > w * .30 && x < w * .67) continue;
        final y = (row / 6 + .02) * h;
        final width = w * (col.isEven ? .115 : .095);
        final height = h * (row.isEven ? .095 : .075);
        final depth = is3D ? 7.0 + (row % 3) * 3.0 : 0.0;
        if (is3D) {
          canvas.drawPath(
            Path()
              ..moveTo(x + width, y)
              ..lineTo(x + width + depth, y - depth)
              ..lineTo(x + width + depth, y + height - depth)
              ..lineTo(x + width, y + height)
              ..close(),
            wall,
          );
        }
        final rect = Rect.fromLTWH(x, y - depth, width, height);
        canvas.drawRect(rect, roof);
        canvas.drawRect(rect, stroke);
      }
    }

    if (traffic) {
      // Dải màu mô phỏng giao thông, không phải dữ liệu thời gian thực.
      final paint = Paint()
        ..color = AppColors.danger.withValues(alpha: .8)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w * .47, h * .20),
        Offset(w * .49, h * .45),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HomeMockMapPainter oldDelegate) =>
      oldDelegate.is3D != is3D ||
      oldDelegate.isDark != isDark ||
      oldDelegate.traffic != traffic;
}
