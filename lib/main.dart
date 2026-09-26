import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/supabase_env.dart';
import 'data/datasources/local/local_store.dart';
import 'data/imanikurd_bootstrap.dart';
import 'data/providers.dart';
import 'data/repositories/repositories.dart';
import 'services/background_notification_service.dart';
import 'services/content_sync_coordinator.dart';
import 'services/notification_service.dart';
import 'services/widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  if (!kIsWeb) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.rounahi.rounahi.audio',
        androidNotificationChannelName: 'قورئان',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      );
    } catch (_) {}
  }
  configureImaniKurd();
  await SupabaseEnv.initialize();
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  if (!kIsWeb) {
    try {
      await Permission.notification.request();
    } catch (_) {}
    try {
      await BackgroundNotificationService.start();
    } catch (_) {}
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RounahiApp(),
    ),
  );

  unawaited(_bootstrapNative(store, container));
}

Future<void> _bootstrapNative(LocalStore store, ProviderContainer container) async {
  if (kIsWeb) {
    await ContentSyncCoordinator.runOnce(store: store);
    container.read(inboxProvider.notifier).reload();
    container.invalidate(contentUpdatesProvider);
    return;
  }

  final notifications = NotificationService(
    store: store,
    inbox: NotificationInboxRepository(store),
  );
  try {
    await notifications.initialize();
  } catch (_) {}
  try {
    await WidgetSyncService().initialize();
  } catch (_) {}
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  } catch (_) {}
  try {
    await ContentSyncCoordinator.register();
  } catch (_) {}
  await ContentSyncCoordinator.runOnce(store: store);
  container.read(inboxProvider.notifier).reload();
  container.invalidate(contentUpdatesProvider);
  try {
    final daily = await container.read(dailyProvider.future);
    await WidgetSyncService().syncDaily(daily: daily, language: store.language());
  } catch (_) {}
}
