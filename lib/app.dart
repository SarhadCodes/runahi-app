import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'services/notification_service.dart';

class RounahiApp extends ConsumerStatefulWidget {
  const RounahiApp({super.key});

  @override
  ConsumerState<RounahiApp> createState() => _RounahiAppState();
}

class _RounahiAppState extends ConsumerState<RounahiApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.pendingRoute.addListener(_openPendingRoute);
  }

  @override
  void dispose() {
    NotificationService.pendingRoute.removeListener(_openPendingRoute);
    super.dispose();
  }

  void _openPendingRoute() {
    final route = NotificationService.pendingRoute.value;
    if (route == null || route.isEmpty) return;
    NotificationService.pendingRoute.value = null;
    ref.read(appRouterProvider).go(route);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(contentRealtimeProvider);
    final settings = ref.watch(settingsProvider);
    final strings = ref.watch(stringsProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = switch (settings.themeMode) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    return MaterialApp.router(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'rounahi_app',
      routerConfig: router,
      theme: AppTheme.light(fontScale: settings.fontScale),
      darkTheme: AppTheme.dark(fontScale: settings.fontScale),
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.fontScale.clamp(0.9, 1.6)),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
