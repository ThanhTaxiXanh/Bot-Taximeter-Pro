import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import '../../../shared/shared_map_view.dart';

/// Lập tuyến bằng số liệu giả, chưa gọi OSRM hay tính cước thực.
class RoutePage extends StatefulWidget {
  const RoutePage({super.key, this.initialStart, this.initialEnd});
  final String? initialStart;
  final String? initialEnd;

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  late final TextEditingController _start;
  late final TextEditingController _stop;
  late final TextEditingController _end;
  bool _showStop = true;
  bool _is3D = true;
  bool _traffic = false;
  bool _details = false;
  int _selectedRoute = 0;

  static const routes = <String>['Nhanh nhất', 'Ít phí', 'Ít kẹt xe'];
  static const etas = <String>['10 phút', '13 phút', '12 phút'];
  static const distances = <String>['3,8 km', '4,1 km', '4,3 km'];
  static const fares = <String>[
    '≈ 72.000 đ', '≈ 78.000 đ', '≈ 80.000 đ',
  ];

  @override
  void initState() {
    super.initState();
    _start = TextEditingController(
      text: widget.initialStart ?? 'Vị trí hiện tại',
    );
    _stop = TextEditingController(text: 'Vị trí thuê xe');
    _end = TextEditingController(
      text: widget.initialEnd ?? 'KINGLANDS Gaming Center',
    );
  }

  @override
  void dispose() {
    _start.dispose();
    _stop.dispose();
    _end.dispose();
    super.dispose();
  }

  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text)),
  );

  void _swap() => setState(() {
    final startValue = _start.text;
    _start.text = _end.text;
    _end.text = startValue;
  });

  Widget _point(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
    VoidCallback onClear,
  ) => Row(children: <Widget>[
    Icon(icon, color: color, size: 22),
    const SizedBox(width: 8),
    Expanded(child: TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
      ),
    )),
    IconButton(
      onPressed: onClear,
      tooltip: 'Xóa $label',
      icon: const Icon(Icons.close, size: 18),
    ),
  ]);

  Widget _points() => GlassCard(
    child: Column(children: <Widget>[
      _point('Điểm đi', _start, Icons.radio_button_checked,
          AppColors.cyan, () => setState(() => _start.text = 'Vị trí hiện tại')),
      if (_showStop) ...<Widget>[
        const Divider(color: AppColors.border),
        _point('Điểm dừng', _stop, Icons.circle_outlined,
            AppColors.white, () => setState(() => _showStop = false)),
      ],
      const Divider(color: AppColors.border),
      _point('Điểm đến', _end, Icons.location_on, AppColors.poi,
          () => setState(() => _end.clear())),
      const SizedBox(height: 5),
      Wrap(spacing: 12, children: <Widget>[
        TextButton.icon(
          icon: const Icon(Icons.add, size: 19),
          label: const Text('Thêm điểm dừng'),
          onPressed: () => setState(() => _showStop = true),
        ),
        TextButton.icon(
          icon: const Icon(Icons.swap_vert, size: 19),
          label: const Text('Đảo chiều tuyến'),
          onPressed: _swap,
        ),
      ]),
    ]),
  );

  Widget _options() => Wrap(
    spacing: 5, runSpacing: 4,
    children: <Widget>[
      for (var i = 0; i < routes.length; i++)
        ChoiceChip(
          label: Text(routes[i]),
          selected: _selectedRoute == i,
          selectedColor: const Color(0xFF0F819B),
          side: const BorderSide(color: AppColors.border),
          onSelected: (_) => setState(() => _selectedRoute = i),
        ),
    ],
  );

  Widget _map() => SizedBox(
    height: 198,
    child: Stack(children: <Widget>[
      Positioned.fill(child: SharedMapView(
        is3D: _is3D, isDark: false, trafficEnabled: _traffic,
        followVehicle: false, showRoute: true, routeIndex: _selectedRoute,
      )),
      Positioned(
        right: 5, top: 5,
        child: SizedBox(
          width: 60, height: 185,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: MapControlButtons(
              is3D: _is3D, trafficEnabled: _traffic,
              showDayNight: false,
              on3D: () => setState(() => _is3D = true),
              on2D: () => setState(() => _is3D = false),
              onTraffic: () => setState(() => _traffic = !_traffic),
              onRecenter: () => _notice('Đây là bản đồ tuyến mẫu.'),
            ),
          ),
        ),
      ),
    ]),
  );

  Widget _stats() => GridView.count(
    crossAxisCount: 2,
    childAspectRatio: 1.0,
    crossAxisSpacing: 7,
    mainAxisSpacing: 7,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: <Widget>[
      StatCard(label: 'ETA', value: etas[_selectedRoute],
          icon: Icons.schedule),
      StatCard(label: 'Quãng đường', value: distances[_selectedRoute],
          icon: Icons.route),
      StatCard(label: 'Cước ước tính', value: fares[_selectedRoute],
          icon: Icons.payments_outlined),
      const StatCard(label: 'Phí BOT', value: '0 đ',
          icon: Icons.toll),
    ],
  );

  Widget _timeline() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Row(children: <Widget>[
        const Expanded(child: Text('Tổng quan tuyến đường', style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 16,
        ))),
        TextButton(
          onPressed: () => setState(() => _details = !_details),
          child: Text(_details ? 'Thu gọn' : 'Chi tiết'),
        ),
      ]),
      GlassCard(
        child: Column(children: <Widget>[
          _timelineItem(Icons.radio_button_checked, AppColors.cyan,
              'Xuất phát', _start.text),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Divider(color: AppColors.border),
          ),
          if (_showStop)
            _timelineItem(Icons.more_vert, AppColors.white,
                'Điểm dừng', _stop.text),
          _timelineItem(Icons.location_on, AppColors.poi,
              'Điểm đến', _end.text),
          if (_details) ...<Widget>[
            const Divider(color: AppColors.border),
            const Text('Tiếp tục đi thẳng, sau đó rẽ phải (mẫu).',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ]),
      ),
    ],
  );

  Widget _timelineItem(
    IconData icon, Color color, String title, String subtitle,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: <Widget>[
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 9),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12,
          )),
          Text(subtitle.isEmpty ? 'Chưa chọn' : subtitle,
              maxLines: 2, style: const TextStyle(
                color: AppColors.muted, fontSize: 12,
              )),
        ],
      )),
    ]),
  );

  Widget _actions() => Row(children: <Widget>[
    Expanded(flex: 3, child: NeonButton(
      label: 'Bắt đầu dẫn đường', icon: Icons.navigation,
      onPressed: () => context.push(AppRouter.trip),
    )),
    const SizedBox(width: 7),
    Expanded(flex: 2, child: NeonButton(
      label: 'Lưu tuyến', icon: Icons.bookmark_border,
      primary: false,
      onPressed: () => _notice('Chức năng lưu tuyến sẽ có ở bước sau.'),
    )),
  ]);

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Lập tuyến đường',
    showBack: true,
    onBack: () => context.canPop()
        ? context.pop() : context.go(AppRouter.home),
    helpText: 'Lập tuyến, thêm điểm dừng, so sánh phương án, '
        'xem ETA và cước ước tính.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _points(),
        const SizedBox(height: 8),
        _options(),
        const SizedBox(height: 8),
        _map(),
        const SizedBox(height: 8),
        _stats(),
        const SizedBox(height: 8),
        _timeline(),
        const SizedBox(height: 12),
        _actions(),
      ],
    ),
  );
}
