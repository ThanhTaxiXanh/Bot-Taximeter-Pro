import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Ảnh tuyến đường thu nhỏ offline, không khởi tạo GoogleMap.
class RoutePreview extends StatelessWidget {
  const RoutePreview({
    super.key,
    this.points = const <Offset>[
      Offset(0.15, 0.85),
      Offset(0.24, 0.65),
      Offset(0.47, 0.60),
      Offset(0.55, 0.38),
      Offset(0.83, 0.17),
    ],
    this.height = 110,
  });
  final List<Offset> points;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: double.infinity, height: height,
      child: CustomPaint(
        painter: RoutePreviewPainter(points: points),
      ),
    ),
  );
}

class RoutePreviewPainter extends CustomPainter {
  const RoutePreviewPainter({required this.points});

  /// Các điểm đã chuẩn hóa trong khoảng 0..1.
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AppColors.backgroundEnd, AppColors.backgroundStart,
        ],
      ).createShader(bounds),
    );
    final road = Paint()
      ..color = const Color(0xFF39516B)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 4; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x + 28, size.height), road);
    }
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y),
          Offset(size.width, y - 10), road);
    }
    if (points.length < 2) return;
    final path = Path()..moveTo(
        points.first.dx * size.width,
        points.first.dy * size.height,
    );
    for (final p in points.skip(1)) {
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }
    canvas.drawPath(path, Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.22)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke);
    canvas.drawPath(path, Paint()
      ..color = AppColors.cyan
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke);
    final start = Offset(
        points.first.dx * size.width,
        points.first.dy * size.height);
    final end = Offset(
        points.last.dx * size.width,
        points.last.dy * size.height);
    canvas.drawCircle(start, 8, Paint()..color = AppColors.success);
    canvas.drawCircle(start, 3, Paint()..color = AppColors.white);
    canvas.drawCircle(end, 8, Paint()..color = AppColors.danger);
    canvas.drawCircle(end, 3, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant RoutePreviewPainter oldDelegate) =>
      oldDelegate.points != points;
}
