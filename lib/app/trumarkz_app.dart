import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/services/push_notification_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/notifications/application/notification_notifier.dart';
import 'theme_scope.dart';

class TrumarkzAppLoadingShell extends StatelessWidget {
  const TrumarkzAppLoadingShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruMarkZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SizedBox.shrink(),
    );
  }
}

class TruMarkZApp extends ConsumerStatefulWidget {
  const TruMarkZApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  ConsumerState<TruMarkZApp> createState() => _TruMarkZAppState();
}

class _TruMarkZAppState extends ConsumerState<TruMarkZApp> {
  StreamSubscription<PushNotificationEvent>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    _pushSubscription = ref
        .read(pushNotificationServiceProvider)
        .events
        .listen(_handlePushEvent);
  }

  void _handlePushEvent(PushNotificationEvent event) {
    // The data payload is only a navigation/refetch hint. The API remains the
    // source of truth for all notification and batch details.
    ref.read(notificationNotifierProvider.notifier).refresh(showLoader: false);
    if (event.opened) {
      AppRouter.router.go(AppRouter.notificationsPath);
      return;
    }
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeController,
      builder: (BuildContext context, _) {
        return ThemeScope(
          controller: widget.themeController,
          child: MaterialApp.router(
            title: 'TruMarkZ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            // Dark theme currently causes low-contrast UI across many screens
            // that use fixed light background colors. Keep visuals readable by
            // using the light theme for both modes.
            darkTheme: AppTheme.light,
            themeMode: widget.themeController.themeMode,
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
