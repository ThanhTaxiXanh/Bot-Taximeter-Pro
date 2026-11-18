import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';
import '../../../shared/route_preview_painter.dart';
import 'history_mock_data.dart';

/// Biểu đồ 7 cột dùng fl_chart, mọi số liệu đều là mẫu.
class HistoryRevenueChart extends StatelessWidget {
  const HistoryRevenueChart({super.key});

  Widget _bottomTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= mockDailyLabels.length ||
        value != index.toDouble()) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
      meta: meta, space: 7,
      child: Text(
        mockDailyLabels[index], textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.white, fontSize: 10),
      ),
    );
  }

  Widget _leftTitle(double value, TitleMeta meta) {
    if (value < 0 || value > 1600000 || value % 400000 != 0) {
      return const SizedBox.shrink();
    }
    final label = switch (value.toInt()) {
      0 => '0',
      400000 => '400k',
      800000 => '800k',
      1200000 => '1,2 tr',
      _ => '1,6 tr',
    };
    return SideTitleWidget(
      meta: meta, space: 5,
      child: Text(label, style: const TextStyle(
        color: AppColors.muted, fontSize: 10,
      )),
    );
  }

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(children: <Widget>[
          const Icon(Icons.bar_chart, color: AppColors.white, size: 24),
          const SizedBox(width: 7),
          const Expanded(child: Text('Doanh thu 7 ngày gần nhất',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          const SizedBox(width: 5),
          const Text('Tổng: ', style: TextStyle(
            fontSize: 11, color: AppColors.muted,
          )),
          const Text('8.436.000 đ', style: TextStyle(
            color: AppColors.cyan, fontSize: 13,
            fontWeight: FontWeight.w800,
          )),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: BarChart(
            BarChartData(
              minY: 0, maxY: 1800000,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                horizontalInterval: 400000,
                getDrawingHorizontalLine: (value) => FlLine(
                  strokeWidth: 1,
                  color: AppColors.border.withValues(alpha: 0.28),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40,
                  interval: 400000, getTitlesWidget: _leftTitle,
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 37,
                  interval: 1, getTitlesWidget: _bottomTitle,
                )),
              ),
              barGroups: <BarChartGroupData>[
                for (var i = 0; i < mockDailyRevenue.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: mockDailyRevenue[i].toDouble(),
                        width: 23,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: i == mockDailyRevenue.length - 1
                              ? const <Color>[
                                  AppColors.cyan, Color(0xFF00647C),
                                ]
                              : const <Color>[
                                  Color(0xFF2AC2D9), Color(0xFF08627E),
                                ],
                        ),
                        label: BarChartRodLabel(
                          text: mockDailyValueLabels[i],
                          offset: const Offset(0, -6),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
        const SizedBox(height: 6),
        const Text('DỮ LIỆU MẪU · 20–26/01 (ảnh thiết kế)',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 10)),
      ],
    ),
  );
}

/// Thẻ cuốc xe với bản đồ mini, điểm đón/trả và hai thao tác.
class HistoryTripCard extends StatelessWidget {
  const HistoryTripCard({
    super.key, required this.trip, required this.selected,
    required this.onTap, required this.onDetails, required this.onExport,
  });

  final MockHistoryTrip trip;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDetails;
  final VoidCallback onExport;

  Widget _location(IconData icon, Color color, String text) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Expanded(child: Text(text, maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.white))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => GlassCard(
    selected: selected,
    padding: const EdgeInsets.all(11),
    onTap: onTap,
    child: Column(children: <Widget>[
      Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100, height: 133,
            child: RoutePreview(height: 133),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                const Icon(Icons.local_taxi, color: AppColors.white, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(
                  '${trip.dayOffset == 0 ? 'Hôm nay' : 'Ngày mẫu'}, ${trip.time}',
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.white, fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ]),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success),
                ),
                child: const Text('✓ Hoàn thành', style: TextStyle(
                  fontSize: 10, color: AppColors.success,
                )),
              ),
              _location(Icons.circle, AppColors.success,
                  'Đón: ${trip.pickup}'),
              _location(Icons.circle, AppColors.danger,
                  'Trả: ${trip.dropoff}'),
              const SizedBox(height: 6),
              Text('Thanh toán: ${trip.payment}',
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.muted, fontSize: 11,
                  )),
              Text(trip.fare, style: const TextStyle(
                color: AppColors.cyan, fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
            ],
          )),
        ],
      ),
      if (selected) ...<Widget>[
        const SizedBox(height: 11),
        Row(children: <Widget>[
          Expanded(child: NeonButton(
            label: 'Xem chi tiết',
            icon: Icons.visibility_outlined,
            primary: false, onPressed: onDetails,
          )),
          const SizedBox(width: 7),
          Expanded(child: NeonButton(
            label: 'Xuất hóa đơn',
            icon: Icons.receipt_long,
            onPressed: onExport,
          )),
        ]),
      ],
    ]),
  );
}
