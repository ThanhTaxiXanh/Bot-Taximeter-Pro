import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Thẻ kính mờ với viền và bóng phát sáng.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key, required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false, this.danger = false, this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final accent = danger ? AppColors.danger : AppColors.cyan;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerGlass : AppColors.glass,
        borderRadius: radius,
        border: Border.all(
          color: danger ? AppColors.danger.withValues(alpha: 0.6)
              : selected ? AppColors.borderActive : AppColors.border,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: selected ? 0.32 : 0.25),
            blurRadius: selected ? 16 : 12,
          ),
        ],
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: onTap == null ? card
              : InkWell(onTap: onTap, borderRadius: radius, child: card),
        ),
      ),
    );
  }
}

/// Nút chính có gradient cyan, nút phụ là viền cyan.
class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key, required this.label, required this.onPressed,
    this.icon, this.primary = true, this.expanded = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? AppColors.navyInk : AppColors.white;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(19),
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: primary ? AppColors.neonGradient : null,
                color: primary ? null : AppColors.glass,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppColors.cyan, width: 1.5),
                boxShadow: primary ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, color: foreground, size: 21),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label, maxLines: 2, textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground, fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút điều khiển bản đồ; sẽ nối SharedMapView ở Bước 8.
class MapControlButtons extends StatelessWidget {
  const MapControlButtons({
    super.key, required this.is3D, required this.trafficEnabled,
    this.isDark = true, this.showDayNight = true,
    this.on3D, this.on2D, this.onRecenter,
    this.onDayNight, this.onTraffic,
  });
  final bool is3D;
  final bool trafficEnabled;
  final bool isDark;
  final bool showDayNight;
  final VoidCallback? on3D;
  final VoidCallback? on2D;
  final VoidCallback? onRecenter;
  final VoidCallback? onDayNight;
  final VoidCallback? onTraffic;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _MapTile(icon: Icons.view_in_ar_outlined, text: '3D',
          selected: is3D, onTap: on3D),
      const SizedBox(height: 8),
      _MapTile(icon: Icons.map_outlined, text: '2D',
          selected: !is3D, onTap: on2D),
      const SizedBox(height: 8),
      _MapTile(icon: Icons.my_location, text: 'Vị trí', onTap: onRecenter),
      if (showDayNight) ...<Widget>[
        const SizedBox(height: 8),
        _MapTile(
          icon: isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
          text: isDark ? 'Tối' : 'Sáng', onTap: onDayNight,
        ),
      ],
      const SizedBox(height: 8),
      _MapTile(icon: Icons.traffic, text: 'GT',
          selected: trafficEnabled, onTap: onTraffic),
    ],
  );
}

class _MapTile extends StatelessWidget {
  const _MapTile({
    required this.icon, required this.text,
    this.selected = false, this.onTap,
  });
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF194B66) : AppColors.backgroundStart,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? AppColors.cyan : AppColors.border,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 60, height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: selected ? AppColors.cyan : AppColors.white),
            const SizedBox(height: 3),
            Text(text, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: selected ? AppColors.cyan : AppColors.white,
            )),
          ],
        ),
      ),
    ),
  );
}

/// Ô thống kê tái sử dụng cho màn chuyến đi và doanh thu.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key, required this.label, required this.value,
    this.icon, this.change, this.highlight = false,
  });
  final String label;
  final String value;
  final IconData? icon;
  final String? change;
  final bool highlight;

  @override
  Widget build(BuildContext context) => GlassCard(
    selected: highlight,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: AppColors.cyan, size: 20),
            const SizedBox(width: 6),
          ],
          Expanded(child: Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12))),
        ]),
        const SizedBox(height: 9),
        Text(value, style: const TextStyle(
          color: AppColors.cyan, fontSize: 21, fontWeight: FontWeight.w800,
        )),
        if (change != null) ...<Widget>[
          const SizedBox(height: 5),
          Text(change!, style: const TextStyle(
            color: AppColors.success, fontSize: 11,
          )),
        ],
      ],
    ),
  );
}
