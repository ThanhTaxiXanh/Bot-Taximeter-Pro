import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../../features/map_tracking/presentation/home_page.dart';
import '../../features/map_tracking/presentation/search_page.dart';
import '../../features/map_tracking/presentation/route_page.dart';

/// Bảy tuyến màn hình cơ bản. Giao diện hoàn chỉnh được bổ sung từ bước 2.
abstract final class AppRouter {
  static const String home = '/';
  static const String search = '/search';
  static const String route = '/route';
  static const String trip = '/trip';
  static const String history = '/history';
  static const String receipt = '/receipt';
  static const String settings = '/settings';

  static GoRouter createRouter() => GoRouter(
        initialLocation: home,
        routes: <RouteBase>[
          GoRoute(path: home, builder: (_, _) => const HomePage()),
          GoRoute(path: search, builder: (_, _) => const SearchPage()),
          GoRoute(
            path: route,
            builder: (_, state) {
              final extra = state.extra;
              final points = extra is Map<String, String> ? extra : null;
              return RoutePage(
                initialStart: points?['start'],
                initialEnd: points?['end'],
              );
            },
          ),
          GoRoute(path: trip, builder: (_, _) => const _TripPage()),
          GoRoute(path: history, builder: (_, _) => const _HistoryPage()),
          GoRoute(path: receipt, builder: (_, _) => const _ReceiptPage()),
          GoRoute(path: settings, builder: (_, _) => const _SettingsPage()),
        ],
      );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${AppConfig.appNameLine1} ${AppConfig.appNameLine2}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          Text('TTX DRIVER PRO', style: TextStyle(fontSize: 10)),
        ],
      );
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: GoRouter.of(context).canPop()
              ? BackButton(onPressed: () => context.pop())
              : null,
          title: const _Brand(),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Chúc quý khách thượng lộ bình an',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (title != null) ...<Widget>[
                  Text(title!, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                ],
                ...children,
              ],
            ),
          ),
        ),
      );
}

class _NavButton extends StatelessWidget {
  const _NavButton(this.label, this.path, {this.primary = false});

  final String label;
  final String path;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final onPressed = () => context.push(path);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: primary
          ? FilledButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class _TripPage extends StatefulWidget {
  const _TripPage();

  @override
  State<_TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<_TripPage> {
  bool _paused = false;

  Future<void> _finish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kết thúc chuyến đi?'),
        content: const Text('Xác nhận kết thúc và mở biên lai.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    context.go(AppRouter.receipt);
  }

  @override
  Widget build(BuildContext context) => _PageShell(
        title: 'Đang chạy chuyến',
        children: <Widget>[
          const Text('Tổng cước'),
          const Text('30.000 đ'),
          const Text('Thời gian chờ'),
          const Text('00:00'),
          FilledButton(
            onPressed: () => setState(() => _paused = !_paused),
            child: Text(_paused ? 'Tiếp tục' : 'Tạm dừng'),
          ),
          OutlinedButton(onPressed: _finish, child: const Text('Kết thúc')),
        ],
      );
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) => const _PageShell(
        title: 'Lịch sử cuốc xe & Doanh thu',
        children: <Widget>[
          Text('Các cuốc xe gần đây'),
          Text('Chưa có chuyến đi được lưu.'),
          _NavButton('Xem chi tiết', AppRouter.receipt),
        ],
      );
}

class _ReceiptPage extends StatelessWidget {
  const _ReceiptPage();

  @override
  Widget build(BuildContext context) => const _PageShell(
        title: 'Chi tiết chuyến đi',
        children: <Widget>[
          Text('Biên lai chuyến đi'),
          Text('Tổng cước'),
          Text('30.000 đ (dữ liệu mẫu)'),
          _NavButton('Về trang chủ', AppRouter.home),
        ],
      );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) => _PageShell(
        title: 'Cài đặt',
        children: <Widget>[
          const Text('Bản đồ & Camera'),
          const Text('Biểu phí & Phí chờ'),
          const Text('Ứng dụng chỉ mang tính hỗ trợ, '
              'không phải đồng hồ taxi được kiểm định.'),
          FilledButton(onPressed: () {}, child: const Text('Lưu cài đặt')),
        ],
      );
}
