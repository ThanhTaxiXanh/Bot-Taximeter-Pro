import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import '../../../shared/shared_map_view.dart';
import '../../fare_meter/fare_calculator.dart';
import '../../map_tracking/data/gps_tracker.dart';
import '../../map_tracking/presentation/gps_permission_prompt.dart';
import '../../map_tracking/presentation/home_widgets.dart';
import '../trip_controller.dart';
import 'trip_map_panel.dart';

class TripPage extends StatefulWidget {
  const TripPage({super.key});
  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  final _controller = TripController.instance;
  final _mapKey = GlobalKey<SharedMapViewState>();
  bool _busy = true, _is3D = true, _traffic = true, _follow = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_controller.pending != null) {
      final restore = await showDialog<bool>(
        context: context, barrierDismissible: false,
        builder: (dialog) => AlertDialog(
          title: const Text('Khôi phục chuyến đang chạy?'),
          content: const Text('Chỉ khôi phục số liệu đã lưu. '
              'Không tự tính tiền cho lúc ứng dụng đã đóng.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialog).pop(false),
                child: const Text('Bỏ chuyến cũ')),
            FilledButton(onPressed: () => Navigator.of(dialog).pop(true),
                child: const Text('Khôi phục')),
          ],
        ),
      );
      if (!mounted) return;
      if (restore == true) {
        try { await _controller.restore(); }
        catch (_) { await _controller.discardPending(); }
      } else { await _controller.discardPending(); }
    }
    if (!_controller.isActive) await _controller.begin();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!GpsTracker.useMock && !GpsTracker.instance.tripActive) {
      final ok = await confirmGpsStart(context, trip: true);
      if (!mounted) return;
      if (!ok) _notice('Chưa có GPS, cước chỉ để tham khảo');
      GpsTracker.instance.setTripPaused(
          _controller.state == TripState.waiting);
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _toll() async {
    var input = '';
    final result = await showModalBottomSheet<int>(
      context: context, showDragHandle: true,
      builder: (sheet) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const Text('Phụ phí BOT (cộng thủ công)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          TextField(onChanged: (value) => input = value,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền (đ)')),
          Wrap(spacing: 6, children: <Widget>[
            for (final value in <int>[5000, 10000, 20000])
              ActionChip(label: Text(formatVnd(value)),
                onPressed: () => Navigator.of(sheet).pop(value)),
          ]),
          FilledButton(
            onPressed: () => Navigator.of(sheet).pop(
                int.tryParse(input.trim())),
            child: const Text('Cộng BOT')),
        ]),
      )),
    );
    if (!mounted || result == null) return;
    if (result < 0 || result > 10000000) {
      _notice('Phụ phí BOT không hợp lệ');
    } else { _controller.addToll(result); }
  }

  String _clock(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  Future<void> _finish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Kết thúc chuyến đi?'),
        content: const Text('Kết thúc chuyến và xem biên lai '
            'GPS tham khảo, chưa phải đồng hồ kiểm định.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialog).pop(false),
              child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true),
              child: const Text('Xác nhận')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    final amount = _controller.fare;
    final meters = _controller.distanceMeters;
    final elapsed = _controller.elapsedSeconds;
    final waiting = _controller.waitingSeconds;
    await _controller.complete();
    await GpsTracker.instance.stop();
    if (!mounted) return;
    context.go(AppRouter.receipt, extra: <String, String>{
      'fare': formatVnd(amount.total),
      'distance': formatKm(meters / 1000),
      'duration': _clock(elapsed), 'waiting': _clock(waiting),
      'waitFee': '${amount.waitFee.toStringAsFixed(0)} đ (trước làm tròn)',
      'toll': formatVnd(amount.toll),
    });
  }

  Future<void> _sos() => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('SOS (bản mẫu)'),
      content: const Text('SOS chưa gọi điện hoặc gửi vị trí.'),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Đã hiểu')),
      ],
    ),
  );

  Widget _map() => TripMapPanel(
    mapKey: _mapKey, is3D: _is3D, traffic: _traffic, follow: _follow,
    on3D: () => setState(() => _is3D = true),
    on2D: () => setState(() => _is3D = false),
    onTraffic: () => setState(() => _traffic = !_traffic),
    onFollowChanged: (v) => setState(() => _follow = v),
    onLimitTap: () => _notice('Biển giới hạn vẫn là dữ liệu mẫu'),
  );

  Widget _chips() => Row(children: <Widget>[
    Expanded(child: HomeStatusChip(
      label: GpsTracker.useMock ? 'GPS tốt' : GpsTracker.instance.message,
      icon: Icons.check_circle,
      active: GpsTracker.useMock || GpsTracker.instance.hasGoodFix,
      onTap: () => _notice(GpsTracker.instance.message),
    )),
    const SizedBox(width: 5),
    Expanded(flex: 2, child: HomeStatusChip(
      label: _is3D ? 'Google Maps 3D' : 'Google Maps 2D',
      icon: Icons.view_in_ar,
      onTap: () => _notice('Chọn 2D/3D trên bản đồ'),
    )),
    const SizedBox(width: 5),
    Expanded(child: HomeStatusChip(
      label: 'Follow xe', icon: Icons.local_taxi, active: _follow,
      onTap: () => setState(() => _follow = !_follow),
    )),
  ]);

  Widget _stats() => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2, childAspectRatio: 1.3,
    crossAxisSpacing: 7, mainAxisSpacing: 7,
    children: <Widget>[
      StatCard(label: 'Tổng cước', value: formatVnd(_controller.fare.total),
          icon: Icons.account_balance_wallet, highlight: true),
      StatCard(label: 'Quãng đường',
          value: formatKm(_controller.distanceMeters / 1000),
          icon: Icons.route),
      StatCard(label: 'Thời gian chuyến', icon: Icons.timer_outlined,
          value: _clock(_controller.elapsedSeconds)),
      StatCard(label: 'Thời gian chờ', icon: Icons.hourglass_empty,
          value: _clock(_controller.waitingSeconds)),
    ],
  );

  Widget _buttons() => Row(children: <Widget>[
    Expanded(flex: 5, child: NeonButton(
      label: _controller.state == TripState.waiting ? 'Tiếp tục' : 'Tạm dừng',
      icon: _controller.state == TripState.waiting
          ? Icons.play_arrow : Icons.pause,
      primary: false, onPressed: _busy ? null : () {
        if (_controller.state == TripState.waiting) {
          _controller.resume();
        } else { _controller.pause(); }
        GpsTracker.instance.setTripPaused(
            _controller.state == TripState.waiting);
      },
    )),
    const SizedBox(width: 7),
    Expanded(flex: 6, child: NeonButton(
      label: 'Kết thúc', icon: Icons.stop,
      onPressed: _busy ? null : _finish,
    )),
    const SizedBox(width: 7),
    Expanded(flex: 3, child: OutlinedButton(
      onPressed: _sos, child: const Text('SOS',
          style: TextStyle(color: AppColors.danger)),
    )),
  ]);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[
      _controller, GpsTracker.instance,
    ]),
    builder: (context, _) => AppShell(
      scrollable: false,
      helpText: 'Cước tham khảo theo GPS, tính bằng Fare Engine.',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: <Widget>[
          Expanded(child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('CƯỚC GPS THAM KHẢO · CHƯA KIỂM ĐỊNH',
                style: TextStyle(color: AppColors.muted, fontSize: 11)),
              const SizedBox(height: 7), _chips(),
              const SizedBox(height: 7),
              const GlassCard(
                padding: EdgeInsets.all(10),
                child: Row(children: <Widget>[
                  Icon(Icons.arrow_upward, color: AppColors.cyan),
                  SizedBox(width: 9),
                  Expanded(child: Text('Tiếp tục đi thẳng · 800 m (mẫu)')),
                ]),
              ),
              const SizedBox(height: 7), _map(),
              const SizedBox(height: 8), _stats(),
              TextButton.icon(
                onPressed: _busy ? null : _toll,
                icon: const Icon(Icons.toll),
                label: Text('Phụ phí BOT: ${formatVnd(_controller.tollFee)}'),
              ),
              if (!GpsTracker.useMock)
                TextButton.icon(onPressed: () => showBatteryHelp(context),
                  icon: const Icon(Icons.battery_saver),
                  label: const Text('Cài đặt pin Xiaomi / Redmi')),
              const Text('Tuyến, biển tốc độ và chỉ dẫn rẽ vẫn là mẫu.',
                style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ))),
          const SizedBox(height: 6), _buttons(),
        ]),
      ),
    ),
  );
}
