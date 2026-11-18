import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';

/// Chip trạng thái mô phỏng trên bản đồ.
class HomeStatusChip extends StatelessWidget {
  const HomeStatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
        onTap: onTap,
        selected: active,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: active ? AppColors.success : AppColors.white,
                size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Tốc độ/giới hạn đều là số liệu mẫu tới khi GPS và SpeedLimitEngine có thật.
class HomeSpeedPanel extends StatelessWidget {
  const HomeSpeedPanel({
    super.key,
    required this.limitKmh,
    required this.onLimitTap,
  });

  final int limitKmh;
  final VoidCallback onLimitTap;

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('42', style: TextStyle(
                  color: AppColors.white,
                  fontSize: 34, height: 1,
                  fontWeight: FontWeight.w900,
                )),
                Text('km/h', style: TextStyle(
                  fontSize: 12, color: AppColors.white,
                )),
              ],
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 46, color: AppColors.border),
            const SizedBox(width: 8),
            InkWell(
              onTap: onLimitTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 49, height: 49,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.danger, width: 5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$limitKmh',
                  style: const TextStyle(
                    color: AppColors.navyInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Ô điều hướng dùng đúng nhãn tìm kiếm của smoke test.
class HomeQuickAction extends StatelessWidget {
  const HomeQuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        onTap: onTap,
        child: SizedBox(
          height: 57,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: AppColors.white, size: 25),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Hai thẻ thông tin cạnh nhau phía trên các nút chức năng.
class HomeInfoCards extends StatelessWidget {
  const HomeInfoCards({
    super.key,
    required this.onCompany,
    required this.onEstimate,
  });

  final VoidCallback onCompany;
  final VoidCallback onEstimate;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 10),
              selected: true,
              onTap: onCompany,
              child: const Row(
                children: <Widget>[
                  Icon(Icons.local_taxi, color: AppColors.cyan, size: 28),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Taxi Hương Giang',
                      maxLines: 2,
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.white,
                      size: 17),
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              onTap: onEstimate,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Ước tính chuyến đi (mẫu)',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.muted, fontSize: 10,
                      )),
                  SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('≈ 58.000 - 72.000 đ',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
