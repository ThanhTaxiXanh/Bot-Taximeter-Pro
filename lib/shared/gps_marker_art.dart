import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mũi tên GPS kèm tên đường bên DƯỚI, luôn bám cùng tọa độ marker.
/// Dữ liệu tên đường lấy từ GPS/Nominatim đã xác minh, không tự suy đoán.
abstract final class GpsMarkerArt {
  static const String unknownRoad = 'Chưa xác định tên đường';

  static String roadLabel(String? name) {
    final clean = (name ?? '')
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return unknownRoad;
    final runes = clean.runes.toList();
    if (runes.length <= 44) return clean;
    return String.fromCharCodes(runes.take(43)) + '…';
  }

  /// Bitmap 2x để chữ sắc nét; icon giữ phương thẳng đứng kể cả bản đồ 3D.
  static Future<BitmapDescriptor> draw(String road) async {
    const width = 480, height = 166;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const cyan = Color(0xFF00E6F5);
    const navy = Color(0xFF07253E);
    const blue = Color(0xFF1D71F2);

    // Vòng sáng quanh mũi tên; tâm marker ở gần (240, 58).
    canvas.drawCircle(const Offset(240, 52), 42,
        Paint()..color = cyan.withValues(alpha: .22)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16));
    canvas.drawCircle(const Offset(240, 52), 38,
        Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(240, 52), 32,
        Paint()..color = blue);
    final arrow = Path()
      ..moveTo(240, 21)
      ..lineTo(268, 73)
      ..lineTo(240, 62)
      ..lineTo(212, 73)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.white);

    // Nhãn pill đặt ngay dưới mũi tên, giữ ngang khi xoay camera.
    final pill = RRect.fromRectAndRadius(
        const Rect.fromLTWH(15, 98, 450, 58),
        const Radius.circular(29));
    canvas.drawRRect(pill, Paint()
      ..color = cyan.withValues(alpha: .24)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10));
    canvas.drawRRect(pill, Paint()..color = navy);
    canvas.drawRRect(pill, Paint()
      ..style = PaintingStyle.stroke ..strokeWidth = 2.5 ..color = cyan);

    // Chấm vị trí ở mé trái của nhãn.
    canvas.drawCircle(const Offset(49, 127), 11,
        Paint()..color = cyan);
    canvas.drawCircle(const Offset(49, 127), 4,
        Paint()..color = navy);
    final painter = TextPainter(
      text: TextSpan(text: roadLabel(road), style: const TextStyle(
          color: Colors.white, fontSize: 27, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 372);
    painter.paint(canvas, Offset(73, 127 - painter.height / 2));
    painter.dispose();

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw StateError('Không vẽ được nhãn GPS');
      return BitmapDescriptor.bytes(png.buffer.asUint8List(),
          imagePixelRatio: 2);
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}
