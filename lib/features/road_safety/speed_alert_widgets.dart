import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../settings/presentation/settings_widgets.dart';
import 'speed_alert_controller.dart';
import 'speed_alert_engine.dart';

/// Hiển thị ngưỡng do tài xế tự đặt, không gọi là biển báo hay luật giao thông.
class SpeedAlertBanner extends StatelessWidget {
  const SpeedAlertBanner({super.key, this.controller});
  final SpeedAlertController? controller;

  @override
  Widget build(BuildContext context) {
    final source = controller ?? SpeedAlertController.instance;
    return AnimatedBuilder(
      animation: source,
      builder: (context, _) {
        if (!source.enabled) return const SizedBox.shrink();
        final reading = source.reading;
        final over = reading.status == SpeedAlertStatus.exceeding;
        final state = switch (reading.status) {
          SpeedAlertStatus.disabled => 'Đang tắt',
          SpeedAlertStatus.noReliableGps => 'GPS chưa đủ tin cậy',
          SpeedAlertStatus.withinThreshold => 'Trong ngưỡng cá nhân',
          SpeedAlertStatus.exceeding => 'VƯỢT NGƯỠNG CÁ NHÂN',
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: over ? AppColors.danger : AppColors.border,
            ),
          ),
          child: Row(children: <Widget>[
            Icon(over ? Icons.warning_amber : Icons.speed,
                color: over ? AppColors.danger : AppColors.cyan),
            const SizedBox(width: 8),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(state + ' · ' + source.thresholdKmh.toString() + ' km/h',
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
                const Text('Ngưỡng tài xế tự đặt, không phải giới hạn pháp lý.',
                  style: TextStyle(color: AppColors.muted, fontSize: 10)),
              ],
            )),
          ]),
        );
      },
    );
  }
}

/// Mặc định tắt; người dùng chủ động bật sau khi hiểu giới hạn dữ liệu.
class SpeedAlertSettings extends StatefulWidget {
  const SpeedAlertSettings({super.key, this.controller});
  final SpeedAlertController? controller;

  @override
  State<SpeedAlertSettings> createState() => _SpeedAlertSettingsState();
}

class _SpeedAlertSettingsState extends State<SpeedAlertSettings> {
  late final SpeedAlertController _controller =
      widget.controller ?? SpeedAlertController.instance;
  bool _enabled = false;
  int _limit = 60;
  bool _ready = false;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _controller.loadAndStart();
    if (!mounted) return;
    setState(() {
      _enabled = _controller.enabled;
      _limit = _controller.thresholdKmh;
      _ready = true;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _controller.configure(enabled: _enabled, limitKmh: _limit);
      if (mounted) setState(() => _message = 'Đã lưu cảnh báo trên thiết bị');
    } catch (_) {
      if (mounted) setState(() => _message = 'Không lưu được cảnh báo');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SettingsSection(
    title: 'Cảnh báo tốc độ cá nhân', icon: Icons.speed,
    children: <Widget>[
      const Text(
        'Giới hạn tốc độ trên đường phải theo biển báo/quy định hiện hành. '
        'Ngưỡng bên dưới là do tài xế tự đặt, không được suy đoán từ bản đồ.',
        style: TextStyle(fontSize: 11, color: AppColors.muted),
      ),
      SettingsToggle(
        title: 'Bật cảnh báo ngưỡng cá nhân',
        subtitle: 'Mặc định tắt. Chỉ hoạt động khi GPS chính xác.',
        value: _enabled,
        onChanged: !_ready || _saving ? (_) {} :
            (value) => setState(() => _enabled = value),
      ),
      const SizedBox(height: 7),
      Wrap(spacing: 6, runSpacing: 5, children: <Widget>[
        for (final value in <int>[40, 50, 60, 70, 80, 90, 100, 120])
          ChoiceChip(
            label: Text('$value km/h'),
            selected: _limit == value,
            onSelected: !_ready || _saving ? null :
                (_) => setState(() => _limit = value),
          ),
      ]),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _ready && !_saving ? _save : null,
        icon: const Icon(Icons.save),
        label: const Text('Lưu cảnh báo tốc độ'),
      ),
      if (_message != null) Text(_message!,
          style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
    ],
  );
}
