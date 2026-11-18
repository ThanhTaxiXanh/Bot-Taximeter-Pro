import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import 'history_mock_data.dart';
import 'history_widgets.dart';

/// Màn Lịch sử & Doanh thu mô phỏng, không truy vấn SQLite hay doanh thu thật.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _selectedPeriod = 0;
  bool _showAll = false;
  String _highlightedTrip = mockHistoryTrips[0].id;

  MockRevenuePeriod get _period => mockPeriods[_selectedPeriod];
  List<MockHistoryTrip> get _filteredTrips => mockHistoryTrips.where((trip) {
    final days = switch (_selectedPeriod) { 0 => 0, 1 => 6, _ => 29 };
    return trip.dayOffset <= days;
  }).toList();
  List<MockHistoryTrip> get _visibleTrips =>
      _showAll ? _filteredTrips : _filteredTrips.take(3).toList();

  void _selectPeriod(int index) => setState(() {
    _selectedPeriod = index;
    _showAll = false;
    _highlightedTrip = _filteredTrips.first.id;
  });

  void _openDetails(MockHistoryTrip trip) =>
      context.push(AppRouter.receipt, extra: trip.receiptSnapshot);

  void _exportNotice() =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Xuất hóa đơn chưa được triển khai; đây là dữ liệu mẫu.',
        )),
      );

  Widget _heading() => const Row(
    children: <Widget>[
      Icon(Icons.history, color: AppColors.cyan, size: 30),
      SizedBox(width: 10),
      Expanded(child: Text(
        'Lịch sử cuốc xe & Doanh thu',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      )),
    ],
  );

  Widget _periodTabs() => Row(children: <Widget>[
    for (var index = 0; index < mockPeriods.length; index++) ...<Widget>[
      if (index > 0) const SizedBox(width: 6),
      Expanded(child: NeonButton(
        label: mockPeriods[index].label,
        icon: Icons.calendar_today_outlined,
        primary: _selectedPeriod == index,
        onPressed: () => _selectPeriod(index),
      )),
    ],
  ]);

  Widget _summaryCards() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    // Thẻ có 3 dòng và biến động: thêm chiều cao, tránh overflow CI #10.
    childAspectRatio: 1.0,
    crossAxisSpacing: 9,
    mainAxisSpacing: 9,
    children: <Widget>[
      StatCard(
        label: _selectedPeriod == 0
            ? 'Doanh thu hôm nay' : 'Doanh thu ${_period.label}',
        value: _period.revenue,
        icon: Icons.savings_outlined,
        highlight: true,
        change: _period.revenueDelta,
      ),
      StatCard(
        label: 'Số cuốc',
        value: _period.trips,
        icon: Icons.local_taxi_outlined,
        change: _period.tripDelta,
      ),
      StatCard(
        label: 'Quãng đường',
        value: _period.distance,
        icon: Icons.route,
        change: _period.distanceDelta,
      ),
      StatCard(
        label: 'Giờ hoạt động',
        value: _period.hours,
        icon: Icons.access_time,
        change: _period.hoursDelta,
      ),
    ],
  );

  Widget _recentHeader() => Row(children: <Widget>[
    const Icon(Icons.format_list_bulleted, color: AppColors.white),
    const SizedBox(width: 6),
    const Expanded(child: Text(
      'Các cuốc xe gần đây',
      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    )),
    TextButton(
      onPressed: () => setState(() => _showAll = !_showAll),
      child: Text(_showAll ? 'Thu gọn' : 'Xem tất cả'),
    ),
  ]);

  Widget _recentTrips() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _recentHeader(),
      const SizedBox(height: 3),
      for (final trip in _visibleTrips) ...<Widget>[
        HistoryTripCard(
          key: ValueKey<String>(trip.id),
          trip: trip,
          selected: trip.id == _highlightedTrip,
          onTap: () {
            if (trip.id == _highlightedTrip) return;
            _openDetails(trip);
          },
          onDetails: () => _openDetails(trip),
          onExport: _exportNotice,
        ),
        const SizedBox(height: 9),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => AppShell(
    showBack: true,
    onBack: () => context.canPop()
        ? context.pop() : context.go(AppRouter.home),
    helpText: 'Xem lịch sử cuốc xe, theo dõi doanh thu, '
        'lọc dữ liệu theo ngày, xem nhanh tuyến đường.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _heading(),
        const SizedBox(height: 13),
        _periodTabs(),
        const SizedBox(height: 16),
        _summaryCards(),
        const SizedBox(height: 15),
        const HistoryRevenueChart(),
        const SizedBox(height: 17),
        _recentTrips(),
        const SizedBox(height: 5),
        const Text('DỮ LIỆU MẪU · Chưa lưu cuốc xe thật',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    ),
  );
}
