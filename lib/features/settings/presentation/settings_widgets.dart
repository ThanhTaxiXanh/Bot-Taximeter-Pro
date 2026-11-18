import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';
import '../../map_tracking/presentation/home_map_mock.dart';

/// Tiêu đề vùng tùy chọn trong thẻ kính chung.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key, required this.title, required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(children: <Widget>[
          Icon(icon, color: AppColors.cyan, size: 22),
          const SizedBox(width: 9),
          Expanded(child: Text(title, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800,
          ))),
        ]),
        const Divider(color: AppColors.border),
        ...children,
      ],
    ),
  );
}

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key, required this.title, required this.value,
    required this.onChanged, this.subtitle, this.icon = Icons.tune,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    secondary: Icon(icon, color: AppColors.cyan, size: 20),
    title: Text(title, style: const TextStyle(
      color: AppColors.white, fontSize: 13,
      fontWeight: FontWeight.w600,
    )),
    subtitle: subtitle == null ? null : Text(subtitle!,
        style: const TextStyle(color: AppColors.muted, fontSize: 11)),
    value: value,
    activeThumbColor: AppColors.cyan,
    onChanged: onChanged,
  );
}

/// Hàng lựa chọn có thể cuộn ngang; không tràn trên điện thoại nhỏ.
class SettingsChoice extends StatelessWidget {
  const SettingsChoice({
    super.key, required this.label, required this.options,
    required this.value, required this.onChanged, this.icon,
  });
  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: AppColors.cyan, size: 19),
            const SizedBox(width: 7),
          ],
          Expanded(child: Text(label, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
          ))),
        ]),
        const SizedBox(height: 7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: <Widget>[
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  label: Text(option),
                  selected: option == value,
                  side: const BorderSide(color: AppColors.border),
                  selectedColor: const Color(0xFF147F91),
                  onSelected: (_) => onChanged(option),
                ),
              ),
          ]),
        ),
      ],
    ),
  );
}

/// Bản đồ xem trước tự vẽ bằng Canvas, không khởi tạo Google Maps.
class SettingsMapPreview extends StatelessWidget {
  const SettingsMapPreview({
    super.key, required this.is3D, required this.isDark,
    required this.traffic, required this.tilt,
    required this.roadNames,
  });
  final bool is3D;
  final bool isDark;
  final bool traffic;
  final double tilt;
  final bool roadNames;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text('Xem trước (Góc ${tilt.round()}° - ${is3D ? '3D' : '2D'})',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white, fontSize: 12,
          )),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(height: 190, child: Stack(children: <Widget>[
          Positioned.fill(child: CustomPaint(
            painter: HomeMockMapPainter(
              is3D: is3D, isDark: isDark, traffic: traffic,
            ),
          )),
          const Align(
            alignment: Alignment(0, .5),
            child: Icon(Icons.navigation, color: Color(0xFF176EEE), size: 42),
          ),
          if (roadNames) const Positioned(
            bottom: 10, left: 20, right: 20,
            child: Text('Đường Trần Nhân Vũ (mẫu)',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800,
                    color: AppColors.navyInk, fontSize: 12)),
          ),
          const Positioned(
            top: 6, left: 6,
            child: Text('BẢN ĐỒ MẪU',
                style: TextStyle(color: AppColors.navyInk, fontSize: 10)),
          ),
        ])),
      ),
    ],
  );
}

/// Trường văn bản trong cài đặt, không lưu cho tới khi nhấn nút Lưu.
class SettingsField extends StatelessWidget {
  const SettingsField({
    super.key, required this.label, required this.controller,
    this.keyboardType, this.hint,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        isDense: true, contentPadding: const EdgeInsets.all(12),
      ),
    ),
  );
}
