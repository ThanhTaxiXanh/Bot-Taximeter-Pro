import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Chỉ biên lai từ chuyến đã được lưu. Không coi đây là hóa đơn/đã thanh toán.
class ReceiptPdfData {
  ReceiptPdfData.fromSnapshot(Map<String, String> snapshot)
      : id = snapshot['id']?.trim() ?? '',
        started = snapshot['started']?.trim() ?? '',
        finished = snapshot['finished']?.trim() ?? '',
        distance = snapshot['distance']?.trim() ?? '',
        duration = snapshot['duration']?.trim() ?? '',
        waiting = snapshot['waiting']?.trim() ?? '',
        waitFee = snapshot['waitFee']?.trim() ?? '',
        toll = snapshot['toll']?.trim() ?? '',
        total = snapshot['fare']?.trim() ?? '' {
    if (snapshot['isRecorded'] != 'true' ||
        id.isEmpty || started.isEmpty || finished.isEmpty ||
        distance.isEmpty || total.isEmpty) {
      throw StateError('Chỉ xuất PDF cho chuyến đã lưu có đủ thông tin.');
    }
  }

  final String id, started, finished, distance, duration;
  final String waiting, waitFee, toll, total;

  String get filename {
    final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'BOT-TaxiMeterPro-${safeId.substring(0, safeId.length > 55 ? 55 : safeId.length)}.pdf';
  }
}

/// Tạo một trang A4 từ ảnh Canvas Flutter để chữ tiếng Việt có dấu
/// được render offline, không tải font từ mạng và không cần lưu tệp tạm.
class ReceiptPdfService {
  const ReceiptPdfService();

  Future<Uint8List> generate(ReceiptPdfData data) async {
    const width = 900.0, height = 1273.0;
    const left = 72.0, right = 828.0;
    const navy = Color(0xFF071C34);
    const cyan = Color(0xFF00BFCF);
    const ink = Color(0xFF173047);
    const subtle = Color(0xFF5C6E7B);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    void rect(Rect area, Color color) {
      canvas.drawRect(area, paint..color = color);
    }

    void draw(String value, double x, double y, {
      double size = 27, double maxWidth = 720, Color color = ink,
      FontWeight weight = FontWeight.normal, int maxLines = 2,
    }) {
      final paragraph = TextPainter(
        text: TextSpan(text: value, style: TextStyle(
          color: color, fontSize: size, fontWeight: weight, height: 1.15)),
        textDirection: TextDirection.ltr,
        maxLines: maxLines, ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      paragraph.paint(canvas, Offset(x, y));
      paragraph.dispose();
    }

    rect(const Rect.fromLTWH(0, 0, width, height), Colors.white);
    rect(const Rect.fromLTWH(0, 0, width, 246), navy);
    rect(const Rect.fromLTWH(0, 0, width, 10), cyan);
    draw('BỘT TAXIMETER PRO', left, 56,
        size: 47, maxWidth: 760, color: cyan, weight: FontWeight.bold);
    draw('BIÊN LAI CƯỚC GPS THAM KHẢO', left, 132,
        size: 30, color: Colors.white, weight: FontWeight.bold);
    draw('KHÔNG PHẢI HÓA ĐƠN · CHƯA KIỂM ĐỊNH', left, 188,
        size: 22, color: const Color(0xFFFFC8AA));
    draw('Mã chuyến', left, 289, color: subtle);
    draw(data.id, 292, 289, maxWidth: 530, weight: FontWeight.bold);
    rect(Rect.fromLTWH(left, 352, right - left, 2),
        const Color(0xFFDAE3EA));

    var y = 382.0;
    void line(String label, String value) {
      draw(label, left, y, size: 25, color: subtle, maxWidth: 205);
      draw(value.isEmpty ? 'Chưa ghi nhận' : value, 292, y,
          size: 27, maxWidth: 530, maxLines: 2);
      y += 83;
    }

    line('Bắt đầu', data.started);
    line('Kết thúc', data.finished);
    line('Quãng đường', data.distance);
    line('Thời gian', data.duration);
    line('Thời gian chờ', data.waiting);
    line('Phí chờ', data.waitFee);
    line('Phí BOT', data.toll);
    rect(Rect.fromLTWH(left, 990, right - left, 116),
        const Color(0xFFE6F8FC));
    draw('TỔNG CƯỚC', left + 21, 1023,
        size: 29, color: ink, weight: FontWeight.bold);
    draw(data.total, 410, 1013, size: 41, maxWidth: 395,
        color: const Color(0xFF007D96), weight: FontWeight.bold);
    draw('Tổng tiền trên là cước ước tính bằng GPS.', left, 1141,
        size: 22, color: subtle);
    draw('Không xác nhận khách đã trả tiền hoặc đã chuyển khoản.',
        left, 1180, size: 21, color: subtle);

    final picture = recorder.endRecording();
    try {
      final rendered = await picture.toImage(width.toInt(), height.toInt());
      try {
        final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) throw StateError('Không thể tạo ảnh biên lai');
        final image = pw.MemoryImage(png.buffer.asUint8List());
        final document = pw.Document(compress: true);
        document.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
        ));
        return await document.save();
      } finally {
        rendered.dispose();
      }
    } finally {
      picture.dispose();
    }
  }
}
