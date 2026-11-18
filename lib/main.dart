import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_config.dart';
import 'features/trip/trip_controller.dart';
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

class _BotTaximeterAppState extends State<BotTaximeterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Trên máy thật, phát hiện snapshot rồi mở màn hỏi khôi phục.
      final found = await TripController.instance.loadPending();
      if (mounted && found) _router.go(AppRouter.trip);
    });
  }

  @override
  void dispose() {
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
