import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import 'home_map_mock.dart';
import 'home_widgets.dart';

/// Màn Home mock, không dùng GPS, Google Maps hay gọi mạng.
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _is3D = true;
  bool _isDark = false;
  bool _traffic = false;
  bool _follow = true;
  int _limitKmh = 60;

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _chooseSpeedLimit() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Giới hạn tốc độ (minh họa)',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Chỉ là số mẫu để thử giao diện. '
                  'Không dùng để quyết định tốc độ khi lái xe.'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  for (final value in <int>[40, 50, 60, 70, 80, 90, 100, 120])
                    ActionChip(
                      label: Text('$value km/h'),
                      onPressed: () => Navigator.of(sheetContext).pop(value),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _limitKmh = result);
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _menuItem(sheetContext, 'Tìm kiếm', Icons.search, AppRouter.search),
            _menuItem(sheetContext, 'Tuyến đường', Icons.route, AppRouter.route),
            _menuItem(sheetContext, 'Doanh thu', Icons.bar_chart, AppRouter.history),
            _menuItem(sheetContext, 'Cài đặt', Icons.settings, AppRouter.settings),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext sheetContext, String label, IconData icon, String route,
  ) => ListTile(
        title: Text(label),
        leading: Icon(icon),
        onTap: () {
          Navigator.of(sheetContext).pop();
          context.push(route);
        },
      );

  Widget _statusChips() => Row(
        children: <Widget>[
          Expanded(
            child: HomeStatusChip(
              label: 'GPS tốt', icon: Icons.check_circle, active: true,
              onTap: () => _message('GPS tốt: dữ liệu minh họa'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: HomeStatusChip(
              label: _is3D ? 'Google Maps 3D' : 'Google Maps 2D',
              icon: Icons.view_in_ar,
              onTap: () => _message('Bản đồ đang được mô phỏng'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: HomeStatusChip(
              label: 'Follow xe', icon: Icons.local_taxi, active: _follow,
              onTap: () => setState(() => _follow = !_follow),
            ),
          ),
        ],
      );

  Widget _map(double height) => SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: HomeMockMap(
                  is3D: _is3D, isDark: _isDark, traffic: _traffic,
                ),
              ),
              Positioned(
                top: 8, left: 8,
                child: HomeSpeedPanel(
                  limitKmh: _limitKmh, onLimitTap: _chooseSpeedLimit,
                ),
              ),
              Positioned(
                top: 7, right: 7,
                child: SizedBox(
                  width: 64, height: height - 14,
                  child: FittedBox(
                    alignment: Alignment.topCenter,
                    fit: BoxFit.scaleDown,
                    child: MapControlButtons(
                      is3D: _is3D,
                      trafficEnabled: _traffic,
                      isDark: _isDark,
                      on3D: () => setState(() => _is3D = true),
                      on2D: () => setState(() => _is3D = false),
                      onTraffic: () => setState(() => _traffic = !_traffic),
                      onDayNight: () => setState(() => _isDark = !_isDark),
                      onRecenter: () {
                        setState(() => _follow = true);
                        _message('Đã về vị trí xe mô phỏng');
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8, left: 36, right: 36,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.location_on, color: AppColors.cyan),
                      SizedBox(width: 5),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Đường Trần Nhân Vũ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.white, fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 10, bottom: 10,
                child: Text('BẢN ĐỒ MẪU', style: TextStyle(
                  color: AppColors.navyInk,
                  fontSize: 8, fontWeight: FontWeight.bold,
                )),
              ),
            ],
          ),
        ),
      );

  Widget _shortcuts() => Row(
        children: <Widget>[
          _quick('Tìm kiếm', Icons.search, AppRouter.search),
          const SizedBox(width: 7),
          _quick('Tuyến đường', Icons.route, AppRouter.route),
          const SizedBox(width: 7),
          _quick('Doanh thu', Icons.bar_chart, AppRouter.history),
          const SizedBox(width: 7),
          _quick('Cài đặt', Icons.settings, AppRouter.settings),
        ],
      );

  Widget _quick(String label, IconData icon, String route) => Expanded(
        child: HomeQuickAction(
          label: label, icon: icon, onTap: () => context.push(route),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final mapHeight = (height * .32).clamp(205.0, 310.0).toDouble();
    return AppShell(
      onMenu: _showMenu,
      onNotification: () => _message('Chưa có thông báo mới'),
      onHelp: () => _message('Đây là màn hình mô phỏng, chưa dùng GPS thật'),
      helpText: 'Theo dõi vị trí, xem tên đường, tốc độ, '
          'chế độ 2D/3D, bắt đầu chuyến.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _statusChips(),
          const SizedBox(height: 8),
          _map(mapHeight),
          const SizedBox(height: 9),
          HomeInfoCards(
            onCompany: () => _message('Taxi Hương Giang: thông tin mẫu'),
            onEstimate: () => context.push(AppRouter.route),
          ),
          const SizedBox(height: 10),
          _shortcuts(),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: NeonButton(
                  label: 'Bắt đầu', icon: Icons.play_arrow,
                  onPressed: () => context.push(AppRouter.trip),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NeonButton(
                  label: 'Lịch sử', icon: Icons.history, primary: false,
                  onPressed: () => context.push(AppRouter.history),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
