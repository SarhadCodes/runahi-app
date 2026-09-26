import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_env.dart';
import '../core/localization/app_language.dart';
import '../core/localization/app_strings.dart';
import '../services/content_sync_coordinator.dart';
import 'datasources/local/local_store.dart';
import 'datasources/remote/content_api.dart';
import 'datasources/remote/imanikurd_content_api.dart';
import 'datasources/remote/supabase_content_api.dart';
import 'models/content_models.dart';
import 'models/core_models.dart';
import 'repositories/repositories.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in bootstrap.');
});

final localStoreProvider = Provider<LocalStore>((ref) {
  return LocalStore(ref.watch(sharedPreferencesProvider));
});

final contentApiProvider = Provider<ContentApi>((ref) {
  return SupabaseContentApi(ImaniKurdContentApi());
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(api: ref.watch(contentApiProvider), local: ref.watch(localStoreProvider));
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(localStoreProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(localStoreProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(localStoreProvider));
});

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((ref) {
  return SearchHistoryRepository(ref.watch(localStoreProvider));
});

final inboxRepositoryProvider = Provider<NotificationInboxRepository>((ref) {
  return NotificationInboxRepository(ref.watch(localStoreProvider));
});

class InboxNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => ref.read(inboxRepositoryProvider).all();

  void reload() {
    state = [...ref.read(inboxRepositoryProvider).all()];
  }

  Future<void> markRead(AppNotification item) async {
    final repo = ref.read(inboxRepositoryProvider);
    await repo.add(item.copyWith(read: true));
    await repo.markRead(item.id);
    reload();
  }

  int get unreadCount => state.where((item) => !item.read).length;
}

final inboxProvider = NotifierProvider<InboxNotifier, List<AppNotification>>(InboxNotifier.new);

class ContentSyncService {
  ContentSyncService(this._ref);
  final Ref _ref;

  Future<void> pull() async {
    await ContentSyncCoordinator.runOnce(
      store: _ref.read(localStoreProvider),
      api: _ref.read(contentApiProvider),
    );
    _ref.read(inboxProvider.notifier).reload();
    _ref.invalidate(contentUpdatesProvider);
    _ref.invalidate(booksProvider);
    _ref.invalidate(videosProvider);
    _ref.invalidate(researchProvider);
    _ref.invalidate(questionsProvider);
    _ref.invalidate(topicsProvider);
    _ref.invalidate(wordsProvider);
    _ref.invalidate(dailyProvider);
  }
}

final contentUpdatesProvider = FutureProvider<List<ContentUpdate>>((ref) {
  return ref.watch(contentRepositoryProvider).updates();
});

final notificationFeedProvider = Provider<AsyncValue<List<AppNotification>>>((ref) {
  final strings = ref.watch(stringsProvider);
  final inbox = ref.watch(inboxProvider);
  final readIds = {for (final item in inbox.where((item) => item.read)) item.id};
  final remote = ref.watch(contentUpdatesProvider);
  return remote.when(
    data: (updates) {
      if (updates.isEmpty) return AsyncValue.data(inbox);
      return AsyncValue.data([
        for (final update in updates)
          AppNotification(
            id: update.id,
            kind: update.kind,
            title: LocalizedText(
              sorani: strings.newContentLabel(update.kind.name),
              badini: strings.newContentLabel(update.kind.name),
            ),
            body: update.title,
            createdAt: update.createdAt,
            deepLink: update.deepLink ?? '/${update.kind.pathSegment}',
            read: readIds.contains(update.id),
          ),
      ]);
    },
    loading: () => inbox.isEmpty ? const AsyncValue.loading() : AsyncValue.data(inbox),
    error: (error, stack) => inbox.isEmpty ? AsyncValue.error(error, stack) : AsyncValue.data(inbox),
  );
});

final contentSyncProvider = Provider<ContentSyncService>((ref) {
  return ContentSyncService(ref);
});

final contentRealtimeProvider = Provider<void>((ref) {
  final poll = Timer.periodic(const Duration(seconds: 45), (_) {
    ref.read(contentSyncProvider).pull();
  });
  ref.onDispose(poll.cancel);
  if (!SupabaseEnv.initialized) return;
  final channel = Supabase.instance.client.channel('content-updates')
    ..onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'content_updates',
      callback: (_) {
        ref.read(contentSyncProvider).pull();
      },
    )
    ..subscribe();
  ref.onDispose(() {
    Supabase.instance.client.removeChannel(channel);
  });
});

class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() => ref.read(settingsRepositoryProvider).load();

  Future<void> setLanguage(AppLanguage language) async {
    await ref.read(settingsRepositoryProvider).saveLanguage(language);
    state = state.copyWith(language: language);
  }

  Future<void> setTheme(String mode) async {
    await ref.read(settingsRepositoryProvider).saveTheme(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setFontScale(double value) async {
    await ref.read(settingsRepositoryProvider).saveFontScale(value);
    state = state.copyWith(fontScale: value);
  }

  Future<void> setQuranFontScale(double value) async {
    await ref.read(settingsRepositoryProvider).saveQuranFontScale(value);
    state = state.copyWith(quranFontScale: value);
  }

  Future<void> setNotifications(NotificationPrefs prefs) async {
    await ref.read(settingsRepositoryProvider).saveNotifications(prefs);
    state = state.copyWith(notifications: prefs);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);

final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings.of(ref.watch(settingsProvider).language);
});

final languageProvider = Provider<AppLanguage>((ref) {
  return ref.watch(settingsProvider).language;
});

class BookmarkNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.read(bookmarkRepositoryProvider).all();

  Future<void> toggle(String key) async {
    await ref.read(bookmarkRepositoryProvider).toggle(key);
    state = {...ref.read(bookmarkRepositoryProvider).all()};
  }
}

final bookmarksProvider = NotifierProvider<BookmarkNotifier, Set<String>>(BookmarkNotifier.new);

final configProvider = FutureProvider<AppConfig>((ref) {
  return ref.watch(contentRepositoryProvider).config();
});

final dailyProvider = FutureProvider<DailyContent>((ref) {
  return ref.watch(contentRepositoryProvider).daily();
});

final booksProvider = FutureProvider<List<BookItem>>((ref) {
  return ref.watch(contentRepositoryProvider).books();
});

final researchProvider = FutureProvider<List<ResearchItem>>((ref) {
  return ref.watch(contentRepositoryProvider).research();
});

final versesProvider = FutureProvider<List<VerseExplanation>>((ref) {
  return ref.watch(contentRepositoryProvider).verses();
});

final surahVersesProvider = FutureProvider.family<List<VerseExplanation>, int>((ref, surahNumber) {
  return ref.watch(contentRepositoryProvider).versesForSurah(surahNumber);
});

final verseProvider = FutureProvider.family<VerseExplanation?, String>((ref, id) {
  return ref.watch(contentRepositoryProvider).verse(id);
});

final wordsProvider = FutureProvider<List<QuranWord>>((ref) {
  return ref.watch(contentRepositoryProvider).words();
});

final videosProvider = FutureProvider<List<VideoItem>>((ref) {
  return ref.watch(contentRepositoryProvider).videos();
});

final questionsProvider = FutureProvider<List<QuestionItem>>((ref) {
  return ref.watch(contentRepositoryProvider).questions();
});

final topicsProvider = FutureProvider<List<TopicItem>>((ref) {
  return ref.watch(contentRepositoryProvider).topics();
});
