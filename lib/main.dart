import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_config.dart';
import 'core/router/app_router.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF06152B),
      ),
      routerConfig: _router,
    );
  }
}
