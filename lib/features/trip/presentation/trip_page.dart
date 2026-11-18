import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import '../../map_tracking/presentation/home_widgets.dart';
import '../../../shared/shared_map_view.dart';
import '../../map_tracking/data/gps_tracker.dart';
import '../../map_tracking/presentation/gps_permission_prompt.dart';
import 'trip_map_panel.dart';
/// Màn 4 giả lập: không lấy GPS, không tính cước thật, không gửi SOS.
class TripPage extends StatefulWidget {
  const TripPage({super.key});
  @override
  State<TripPage> createState() => _TripPageState();
}
class _TripPageState extends State<TripPage> {
  final _mapKey = GlobalKey<SharedMapViewState>();
  static const int _initialSeconds = 14 * 60 + 26;
  late final Timer _ticker;
  int _trip = _initialSeconds;
  int _waiting = 2 * 60 + 10;
  int _toll = 0;
  bool _paused = false, _is3D = true, _traffic = true, _follow = true;
  @override
  void initState() {
    super.initState();
    if (!GpsTracker.useMock) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final ok = await confirmGpsStart(context, trip: true);
        if (mounted && !ok) _notice('Chưa có GPS, cước vẫn là mẫu');
      });
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_paused) { _waiting++; } else { _trip++; }
      });
    });
  }
  @override
  void dispose() {
    _ticker.cancel();
    if (GpsTracker.instance.tripActive) {
      unawaited(GpsTracker.instance.stop());
    }
    super.dispose();
  }
  // Phép cộng tiền mẫu không phải biểu phí taxi được kiểm định.
  int get _fare => 72000 + ((_trip - _initialSeconds) ~/ 20) * 1000 + _toll;
  String _money(int value) => '${value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.',
  )} đ';
  String _clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
  void _notice(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
  Future<void> _addToll() async {
    final amount = await showModalBottomSheet<int>(
      context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const ListTile(
            title: Text('Phụ phí BOT (mẫu)'),
            subtitle: Text('Chọn số tiền minh họa bằng tay.'),
          ),
          for (final value in <int>[5000, 10000, 20000])
            ListTile(
              leading: const Icon(Icons.toll, color: AppColors.cyan),
              title: Text('+ ${_money(value)}'),
              onTap: () => Navigator.of(sheetContext).pop(value),
            ),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Đóng'),
          ),
        ]),
      ),
    );
    if (mounted && amount != null) setState(() => _toll += amount);
  }
  Future<void> _finish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kết thúc chuyến đi?'),
        content: const Text('Xác nhận kết thúc chuyến mô phỏng và xem biên lai.'),
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
    _ticker.cancel();
    final measured = GpsTracker.instance.fix == null ? 'Chưa đo GPS'
        : '${(GpsTracker.instance.distanceMeters / 1000).toStringAsFixed(2)} km';
    await GpsTracker.instance.stop();
    if (!mounted) return;
    context.go(AppRouter.receipt, extra: <String, String>{
      'fare': _money(_fare), 'distance': measured,
      'duration': _clock(_trip), 'waiting': _clock(_waiting),
      'toll': _money(_toll),
    });
  }
  Future<void> _sos() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('SOS (bản mẫu)'),
      content: const Text('Nút SOS chưa gọi điện hoặc gửi vị trí. '
          'Hãy liên hệ số khẩn cấp phù hợp nếu cần giúp đỡ.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Đã hiểu'),
        ),
      ],
    ),
  );
  Widget _chips() => Row(children: <Widget>[
    Expanded(child: HomeStatusChip(
      label: GpsTracker.useMock ? 'GPS tốt' : GpsTracker.instance.message,
      icon: Icons.check_circle,
      active: GpsTracker.useMock || GpsTracker.instance.hasGoodFix,
      onTap: () async {
        if (GpsTracker.instance.isTracking) {
          _notice(GpsTracker.instance.message);
          return;
        }
        final ok = await confirmGpsStart(context, trip: true);
        if (mounted && !ok) _notice(GpsTracker.instance.message);
      },
    )),
    const SizedBox(width: 6),
    Expanded(flex: 2, child: HomeStatusChip(
      label: _is3D ? 'Google Maps 3D' : 'Google Maps 2D',
      icon: Icons.view_in_ar,
      onTap: () => _notice('Bản đồ 2D/3D chưa dùng Maps thật'),
    )),
    const SizedBox(width: 6),
    Expanded(child: HomeStatusChip(
      label: 'Follow xe', icon: Icons.local_taxi, active: _follow,
      onTap: () => setState(() => _follow = !_follow),
    )),
  ]);
  Widget _directions() => GlassCard(
    selected: true,
    padding: const EdgeInsets.all(11),
    child: Row(children: <Widget>[
      const Icon(Icons.arrow_upward, color: AppColors.white, size: 53),
      Container(width: 1, height: 55, color: AppColors.border,
          margin: const EdgeInsets.symmetric(horizontal: 12)),
      const Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Tiếp tục đi thẳng', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
          )),
          Text('800 m', style: TextStyle(
            color: AppColors.cyan, fontSize: 31,
            fontWeight: FontWeight.w900,
          )),
        ],
      )),
    ]),
  );
  Widget _map() => TripMapPanel(
    mapKey: _mapKey, is3D: _is3D, traffic: _traffic, follow: _follow,
    on3D: () => setState(() => _is3D = true),
    on2D: () => setState(() => _is3D = false),
    onTraffic: () => setState(() => _traffic = !_traffic),
    onFollowChanged: (value) => setState(() => _follow = value),
    onLimitTap: () => _notice('Biển tốc độ chỉ là dữ liệu mẫu'),
  );
  Widget _statistics() => GridView.count(
    crossAxisCount: 2, childAspectRatio: 1.3, shrinkWrap: true,
    crossAxisSpacing: 7, mainAxisSpacing: 7,
    physics: const NeverScrollableScrollPhysics(),
    children: <Widget>[
      StatCard(label: 'Tổng cước', value: _money(_fare),
          icon: Icons.account_balance_wallet, highlight: true),
      StatCard(label: 'Quãng đường', icon: Icons.route,
        value: GpsTracker.instance.fix == null
            ? (GpsTracker.useMock ? '8,4 km' : 'Chưa đo')
            : '${(GpsTracker.instance.distanceMeters / 1000).toStringAsFixed(2)} km'),
      StatCard(label: 'Thời gian chuyến', value: _clock(_trip),
          icon: Icons.timer_outlined),
      StatCard(label: 'Thời gian chờ', value: _clock(_waiting),
          icon: Icons.hourglass_empty),
    ],
  );
  Widget _warning() => const GlassCard(
    danger: true, padding: EdgeInsets.all(11),
    child: Row(children: <Widget>[
      Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 27),
      SizedBox(width: 9),
      Expanded(child: Text('Cảnh báo: Đông xe phía trước\n'
          'Cách 600 m, qua đoạn ~ 3 phút (dữ liệu mẫu)',
          style: TextStyle(color: AppColors.white, fontSize: 12))),
      Icon(Icons.chevron_right, color: AppColors.white),
    ]),
  );
  Widget _controls() => Padding(
    padding: const EdgeInsets.fromLTRB(0, 5, 0, 7),
    child: Row(children: <Widget>[
      Expanded(flex: 5, child: NeonButton(
        label: _paused ? 'Tiếp tục' : 'Tạm dừng',
        icon: _paused ? Icons.play_arrow : Icons.pause,
        primary: false,
        onPressed: () {
          setState(() => _paused = !_paused);
          GpsTracker.instance.setTripPaused(_paused);
        },
      )),
      const SizedBox(width: 7),
      Expanded(flex: 6, child: NeonButton(
        label: 'Kết thúc', icon: Icons.stop, onPressed: _finish,
      )),
      const SizedBox(width: 7),
      Expanded(flex: 3, child: OutlinedButton(
        onPressed: _sos,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.cyan),
        ),
        child: const Text('SOS', style: TextStyle(
          color: AppColors.danger, fontWeight: FontWeight.bold,
        )),
      )),
    ]),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: GpsTracker.instance,
    builder: (context, _) => AppShell(
    scrollable: false,
    helpText: 'Theo dõi chuyến đi, tính cước trực tiếp, '
        'xem tốc độ, theo dõi đường và cảnh báo giao thông.',
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: <Widget>[
        Expanded(child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Đang chạy chuyến · DỮ LIỆU MẪU',
                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
              const SizedBox(height: 6),
              _chips(),
              const SizedBox(height: 7),
              _directions(),
              const SizedBox(height: 7),
              _map(),
              const SizedBox(height: 8),
              _statistics(),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _addToll,
                icon: const Icon(Icons.toll),
                label: Text('Phụ phí BOT: ${_money(_toll)}'),
              ),
              if (!GpsTracker.useMock)
                TextButton.icon(
                  onPressed: () => showBatteryHelp(context),
                  icon: const Icon(Icons.battery_saver),
                  label: const Text('Cài đặt pin Xiaomi / Redmi'),
                ),
              _warning(),
              const SizedBox(height: 10),
            ],
          ),
        )),
        _controls(),
      ]),
    ),
    ),
  );
}
