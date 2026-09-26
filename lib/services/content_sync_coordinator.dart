import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/config/supabase_env.dart';
import '../core/constants/app_constants.dart';
import '../data/datasources/local/local_store.dart';
import '../data/datasources/remote/content_api.dart';
import '../data/datasources/remote/imanikurd_content_api.dart';
import '../data/datasources/remote/supabase_content_api.dart';
import '../data/imanikurd_bootstrap.dart';
import '../data/repositories/repositories.dart';
import 'notification_service.dart';
import 'widget_sync_service.dart';

bool get _supportsBackgroundTasks {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

@pragma('vm:entry-point')
void rounahiBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    configureImaniKurd();
    await SupabaseEnv.initialize();
    final prefs = await SharedPreferences.getInstance();
    await ContentSyncCoordinator.runOnce(store: LocalStore(prefs));
    return true;
  });
}

class ContentSyncCoordinator {
  static Future<int> runOnce({required LocalStore store, ContentApi? api}) async {
    try {
      await store.reload();
      await SupabaseEnv.initialize();
      final contentApi = api ?? SupabaseContentApi(ImaniKurdContentApi());
      final repo = ContentRepository(api: contentApi, local: store);
      final updates = await repo.updates();
      final language = store.language();
      if (updates.isNotEmpty) {
        final notifications = NotificationService(
          store: store,
          inbox: NotificationInboxRepository(store),
        );
        try {
          await notifications.initialize();
        } catch (_) {}
        await notifications.processUpdates(
          updates: updates,
          language: language,
          prefs: store.notificationPrefs(),
        );
      }
      try {
        final daily = await repo.daily();
        await WidgetSyncService().syncDaily(daily: daily, language: language);
      } catch (_) {}
      await store.setLastContentCheck(DateTime.now().toUtc());
      final config = await repo.config();
      await store.setLastContentVersion(config.contentVersion);
      return updates.length;
    } catch (error, stack) {
      debugPrint('ContentSyncCoordinator.runOnce failed: $error\n$stack');
      return 0;
    }
  }

  static Future<void> register() async {
    if (!_supportsBackgroundTasks) return;
    await Workmanager().initialize(rounahiBackgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      AppConstants.workmanagerTask,
      AppConstants.workmanagerTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }
}
