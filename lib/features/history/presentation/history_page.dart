import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import '../../fare_meter/fare_calculator.dart';
import '../data/completed_trip.dart';
import '../data/completed_trip_store.dart';
import 'history_real_widgets.dart';

/// Thống kê cước GPS từ chuyến đã lưu, không dùng số liệu doanh thu giả.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.store});
  final CompletedTripStore? store;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final CompletedTripStore _store =
      widget.store ?? CompletedTripStores.instance;
  List<CompletedTrip> _all = const [];
  int _selectedPeriod = 0;
  bool _showAll = false;
  bool _loading = true;
  String? _error;

  static const _tabs = <String>['Hôm nay', '7 ngày', '30 ngày'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final records = await _store.all();
      if (mounted) setState(() {
        _all = records;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Không đọc được lịch sử trên thiết bị.';
      });
    }
  }

  List<CompletedTrip> get _filtered {
    final days = switch (_selectedPeriod) { 0 => 1, 1 => 7, _ => 30 };
    final start = startOfPeriod(DateTime.now(), days);
    return _all.where((trip) => !trip.finishedAt.isBefore(start))
        .toList(growable: false);
  }

  List<int> _dailyRevenue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return <int>[
      for (var i = 0; i < 7; i++)
        _all.where((trip) {
          final day = trip.finishedAt.toLocal();
          final target = today.subtract(Duration(days: 6 - i));
          return day.year == target.year && day.month == target.month &&
              day.day == target.day;
        }).fold<int>(0, (sum, trip) => sum + trip.fareVnd),
    ];
  }

  List<String> _dayLabels() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return <String>[
      for (var i = 0; i < 7; i++)
        '${today.subtract(Duration(days: 6 - i)).day}/'
        '${today.subtract(Duration(days: 6 - i)).month}',
    ];
  }

  void _selectPeriod(int index) => setState(() {
    _selectedPeriod = index;
    _showAll = false;
  });

  Widget _tabsRow() => Row(children: <Widget>[
    for (var i = 0; i < _tabs.length; i++) ...<Widget>[
      if (i > 0) const SizedBox(width: 6),
      Expanded(child: NeonButton(
        label: _tabs[i], icon: Icons.calendar_month,
        primary: i == _selectedPeriod,
        onPressed: () => _selectPeriod(i),
      )),
    ],
  ]);

  Widget _summary() {
    final stats = RevenueStats.fromTrips(_filtered);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, childAspectRatio: 1.0,
      crossAxisSpacing: 9, mainAxisSpacing: 9,
      children: <Widget>[
        StatCard(
          label: _selectedPeriod == 0
              ? 'Doanh thu hôm nay' : 'Doanh thu ${_tabs[_selectedPeriod]}',
          value: formatVnd(stats.totalFare),
          icon: Icons.savings_outlined, highlight: true),
        StatCard(label: 'Số cuốc', value: '${stats.count}',
            icon: Icons.local_taxi_outlined),
        StatCard(label: 'Quãng đường',
            value: formatKm(stats.totalMeters / 1000), icon: Icons.route),
        StatCard(label: 'Giờ hoạt động',
            value: formatDuration(stats.totalSeconds), icon: Icons.access_time),
      ],
    );
  }

  Widget _recent() {
    final filtered = _filtered;
    final shown = _showAll ? filtered : filtered.take(3);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(children: <Widget>[
          const Expanded(child: Text('Các cuốc xe gần đây',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
          TextButton(onPressed: filtered.length <= 3
              ? null : () => setState(() => _showAll = !_showAll),
            child: Text(_showAll ? 'Thu gọn' : 'Xem tất cả')),
        ]),
        if (filtered.isEmpty)
          const GlassCard(child: Text('Chưa có chuyến đã hoàn thành '
              'trong khoảng thời gian này.')),
        for (final trip in shown) ...<Widget>[
          HistoryCompletedTripCard(
            key: ValueKey<String>(trip.id), trip: trip,
            onDetails: () => context.push(
                AppRouter.receipt, extra: trip.receiptSnapshot),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AppShell(
    showBack: true,
    onBack: () => context.canPop()
        ? context.pop() : context.go(AppRouter.home),
    helpText: 'Lịch sử cuốc đã hoàn thành và tổng cước GPS tham khảo.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('Lịch sử cuốc xe & Doanh thu',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('TỔNG CƯỚC GPS THAM KHẢO · KHÔNG XÁC NHẬN ĐÃ THU',
          style: TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 12),
        _tabsRow(),
        const SizedBox(height: 10),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...<Widget>[
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
          TextButton(onPressed: _load, child: const Text('Thử lại')),
        ],
        if (!_loading && _error == null) ...<Widget>[
          _summary(),
          const SizedBox(height: 12),
          HistoryRealChart(values: _dailyRevenue(), labels: _dayLabels()),
          const SizedBox(height: 15),
          _recent(),
        ],
      ],
    ),
  );
}
