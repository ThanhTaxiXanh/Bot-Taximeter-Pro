import 'package:flutter/material.dart';

import '../data/gps_tracker.dart';

/// Hỏi rõ mục đích trước khi yêu cầu quyền vị trí của Android.
Future<bool> confirmGpsStart(
  BuildContext context, {bool trip = false}
) async {
  if (GpsTracker.useMock) return false;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(trip ? 'Bật GPS cho chuyến đi?' : 'Bật vị trí xe?'),
      content: Text(
        trip
            ? 'Ứng dụng cần vị trí khi dùng và sẽ hiển thị thông báo '
              '"Đang chạy chuyến" để theo dõi GPS khi màn hình tắt. '
              'Không thu cước tự động ở bước này.'
            : 'Cho phép truy cập vị trí khi dùng để hiển thị xe thật. '
              'Tốc độ và độ chính xác phụ thuộc tín hiệu GPS.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Bật GPS'),
        ),
      ],
    ),
  );
  if (accepted != true) return false;
  return GpsTracker.instance.start(trip: trip);
}

/// Không tự xin quyền "bỏ tối ưu pin"; chỉ mở Cài đặt sau khi tài xế chọn.
Future<void> showBatteryHelp(BuildContext context) async {
  if (GpsTracker.useMock) return;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Pin và theo dõi chuyến'),
      content: const Text(
        'Trên Xiaomi/Redmi, vào Cài đặt ứng dụng → Pin '
        '→ Không hạn chế để hệ thống ít ngắt GPS khi tắt màn hình. '
        'Bạn có thể giữ chế độ tối ưu pin nếu không muốn thay đổi.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Mở cài đặt'),
        ),
      ],
    ),
  );
  if (accepted == true) {
    await GpsTracker.instance.openBatterySettings();
  }
}
