import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../core/localization/app_language.dart';
import '../core/localization/app_strings.dart';
import '../data/datasources/local/local_store.dart';
import '../data/models/content_models.dart';
import '../data/models/core_models.dart';
import '../data/repositories/repositories.dart';

class NotificationService {
  NotificationService({
    required LocalStore store,
    required NotificationInboxRepository inbox,
  }) : _store = store,
       _inbox = inbox;

  final LocalStore _store;
  final NotificationInboxRepository _inbox;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static final ValueNotifier<String?> pendingRoute = ValueNotifier<String?>(null);

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          pendingRoute.value = payload;
        }
      },
    );
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final language = _store.language();
    final strings = AppStrings.of(language);
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        'rounahi_new_content',
        strings.notifChannelName,
        description: strings.notifChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> processUpdates({
    required List<ContentUpdate> updates,
    required AppLanguage language,
    required NotificationPrefs prefs,
  }) async {
    final strings = AppStrings.of(language);
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 14));
    for (final update in updates) {
      if (_store.notifiedIds().contains(update.id)) continue;
      final title = strings.newContentLabel(update.kind.name);
      final body = update.title.resolve(language);
      await _inbox.add(
        AppNotification(
          id: update.id,
          kind: update.kind,
          title: LocalizedText(sorani: title, badini: title),
          body: update.title,
          createdAt: update.createdAt,
          deepLink: update.deepLink ?? '/${update.kind.pathSegment}/${update.id}',
        ),
      );
      if (!prefs.allows(update.kind) || !update.createdAt.isAfter(cutoff)) {
        await _store.markNotified(update.id);
        continue;
      }
      try {
        await _plugin.show(
          update.id.hashCode.abs(),
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'rounahi_new_content',
              strings.settingsNewContent,
              channelDescription: strings.notifications,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              styleInformation: BigTextStyleInformation(body),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: update.deepLink ?? '/${update.kind.pathSegment}/${update.id}',
        );
      } catch (error) {
        debugPrint('local notification failed: $error');
      }
      await _store.markNotified(update.id);
    }
  }
}
