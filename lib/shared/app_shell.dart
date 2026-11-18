import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/theme/app_colors.dart';

/// Khung dùng chung: logo, lời chào và thanh chức năng.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key, required this.child, required this.helpText,
    this.title, this.scrollable = true, this.showBack = false,
    this.onBack, this.onMenu, this.onNotification, this.onHelp,
  });
  final Widget child;
  final String helpText;
  final String? title;
  final bool scrollable;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onNotification;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.background),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _header(context),
            _greeting(),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title!,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16), child: child)
                  : child,
            ),
            _helpBar(),
          ],
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 48,
          child: IconButton(
            tooltip: showBack ? 'Quay lại' : 'Menu',
            color: AppColors.white,
            icon: Icon(showBack ? Icons.arrow_back : Icons.menu),
            onPressed: showBack
                ? (onBack ?? () => Navigator.of(context).maybePop())
                : onMenu,
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(children: <Widget>[
                  const Icon(Icons.local_taxi,
                      color: AppColors.cyan, size: 24),
                  const SizedBox(width: 5),
                  Text(
                    '${AppConfig.appNameLine1} ${AppConfig.appNameLine2}',
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ]),
              ),
              const Text('TTX DRIVER PRO',
                  style: TextStyle(fontSize: 9,
                      color: AppColors.muted, letterSpacing: 1.5)),
            ],
          ),
        ),
        SizedBox(
          width: 48,
          child: Stack(
            alignment: Alignment.topRight,
            children: <Widget>[
              IconButton(
                onPressed: onNotification,
                tooltip: 'Thông báo',
                icon: const Icon(Icons.notifications_none,
                    color: AppColors.white),
              ),
              const Positioned(
                right: 9, top: 8,
                child: CircleAvatar(
                    radius: 4, backgroundColor: AppColors.cyan),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _greeting() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: <Widget>[
        Expanded(child: Divider(color: AppColors.border)),
        SizedBox(width: 5),
        Icon(Icons.verified_user_outlined,
            color: AppColors.cyan, size: 20),
        SizedBox(width: 5),
        Flexible(
          flex: 7,
          child: Text(
            'Chúc quý khách thượng lộ bình an',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontSize: 12),
          ),
        ),
        SizedBox(width: 5),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    ),
  );

  Widget _helpBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
    child: Material(
      color: AppColors.glass,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onHelp,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              const Icon(Icons.info_outline, color: AppColors.cyan),
              const SizedBox(width: 9),
              Expanded(
                child: Text.rich(
                  TextSpan(children: <InlineSpan>[
                    const TextSpan(
                      text: 'Chức năng chính: ',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: helpText),
                  ]),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.white),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.white),
            ],
          ),
        ),
      ),
    ),
  );
}
