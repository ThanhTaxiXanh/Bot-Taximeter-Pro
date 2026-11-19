import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_config.dart';
import 'features/trip/trip_controller.dart';
import 'features/map_tracking/data/routing_server_config.dart';
import 'features/map_tracking/data/gps_tracker.dart';
import 'features/road_safety/speed_alert_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BotTaximeterApp()));
}

class BotTaximeterApp extends StatefulWidget {
  const BotTaximeterApp({super.key});

  @override
  State<BotTaximeterApp> createState() => _BotTaximeterAppState();
}

class _BotTaximeterAppState extends State<BotTaximeterApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = AppRouter.createRouter();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Đọc URL máy chủ đã lưu, không gửi yêu cầu mạng khi khởi động.
      await loadSavedRoutingServers();
      await SpeedAlertController.instance.loadAndStart();
      // Trên máy thật, phát hiện snapshot rồi mở màn hỏi khôi phục.
      final found = await TripController.instance.loadPending();
      if (mounted && found) _router.go(AppRouter.trip);
    });
  }

  /// Tắt GPS Home khi ra nền; không chạm dịch vụ GPS của chuyến đang chạy.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final tracker = GpsTracker.instance;
    if (GpsPowerPolicy.shouldStopPreview(
      appPaused: state == AppLifecycleState.paused,
      tracking: tracker.isTracking,
      starting: tracker.isStarting,
      tripTracking: tracker.tripActive,
      activeTrip: TripController.instance.isActive,
    )) {
      unawaited(tracker.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '${AppConfig.appNameLine1} ${AppConfig.appNameLine2}',
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
