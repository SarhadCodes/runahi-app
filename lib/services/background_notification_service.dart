import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/supabase_env.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_language.dart';
import '../core/localization/app_strings.dart';
import '../data/datasources/local/local_store.dart';
import '../data/imanikurd_bootstrap.dart';
import 'content_sync_coordinator.dart';

const _channelId = 'rounahi_background_sync';
const _notificationId = 7701;

Future<AppStrings> _localizedStrings() async {
  final prefs = await SharedPreferences.getInstance();
  final language = AppLanguage.fromCode(prefs.getString(StorageKeys.language));
  return AppStrings.of(language);
}

class BackgroundNotificationService {
  static Future<void> start() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    final strings = await _localizedStrings();
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            strings.bgSyncChannelName,
            description: strings.bgSyncChannelDescription,
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
            showBadge: false,
          ),
        );

    final service = FlutterBackgroundService();
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onBackgroundStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundStart,
        autoStart: true,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: strings.appName,
        initialNotificationContent: strings.bgSyncActiveContent,
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
    );
    if (!await service.isRunning()) {
      await service.startService();
    }
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  configureImaniKurd();
  await SupabaseEnv.initialize();
  final prefs = await SharedPreferences.getInstance();
  await ContentSyncCoordinator.runOnce(store: LocalStore(prefs));
  return true;
}

@pragma('vm:entry-point')
void onBackgroundStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  configureImaniKurd();
  await SupabaseEnv.initialize();

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
    final strings = await _localizedStrings();
    await service.setForegroundNotificationInfo(
      title: strings.appName,
      content: strings.bgSyncActiveContent,
    );
  }

  service.on('stop').listen((_) {
    service.stopSelf();
  });

  Future<void> pull() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await ContentSyncCoordinator.runOnce(store: LocalStore(prefs));
    } catch (error, stack) {
      debugPrint('background sync failed: $error\n$stack');
    }
  }

  await pull();
  Timer.periodic(const Duration(minutes: 15), (_) => pull());
}
