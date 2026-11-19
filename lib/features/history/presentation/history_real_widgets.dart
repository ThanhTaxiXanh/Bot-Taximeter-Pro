import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';
import '../../fare_meter/fare_calculator.dart';
import '../data/completed_trip.dart';

class HistoryRealChart extends StatelessWidget {
  const HistoryRealChart({super.key, required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final peak = values.fold<int>(0, math.max);
    final upper = math.max(1000, (peak * 1.2).ceil()).toDouble();
    return GlassCard(
      padding: const EdgeInsets.all(13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Doanh thu 7 ngày gần nhất',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text('Tổng: ${formatVnd(total)}',
              style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(height: 175, child: BarChart(BarChartData(
            maxY: upper, minY: 0,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(enabled: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 28, interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length ||
                      index.toDouble() != value) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(meta: meta, child: Text(
                    labels[index], style: const TextStyle(
                      color: AppColors.white, fontSize: 10)));
                },
              )),
            ),
            barGroups: <BarChartGroupData>[
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(x: i, barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: values[i].toDouble(), width: 17,
                    color: AppColors.cyan,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4))),
                ]),
            ],
          ), duration: Duration.zero)),
          const SizedBox(height: 5),
          const Text('Chỉ tổng hợp cước GPS tham khảo của chuyến đã lưu.',
            style: TextStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }
}

/// Không đặt điểm đón/trả hoặc phương thức thanh toán khi chưa thu thập.
class HistoryCompletedTripCard extends StatelessWidget {
  const HistoryCompletedTripCard({super.key, required this.trip,
    required this.onDetails});
  final CompletedTrip trip;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(children: <Widget>[
          const Icon(Icons.local_taxi, color: AppColors.cyan),
          const SizedBox(width: 8),
          Expanded(child: Text(formatDateTime(trip.finishedAt),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 18),
        ]),
        const SizedBox(height: 5),
        Text(trip.id, style: const TextStyle(
          fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 8),
        Text(formatVnd(trip.fareVnd),
          style: const TextStyle(color: AppColors.cyan, fontSize: 19,
              fontWeight: FontWeight.bold)),
        Text('${formatKm(trip.distanceMeters / 1000)} · '
             '${trip.duration} · BOT ${formatVnd(trip.tollVnd)}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 8),
        NeonButton(label: 'Xem chi tiết', icon: Icons.receipt_long_outlined,
          primary: false, onPressed: onDetails),
      ],
    ),
  );
}
