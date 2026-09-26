import '../../core/localization/app_language.dart';
import '../datasources/local/local_store.dart';
import '../datasources/remote/content_api.dart';
import '../models/content_models.dart';
import '../models/core_models.dart';

class ContentRepository {
  ContentRepository({required ContentApi api, required LocalStore local})
    : _api = api,
      _local = local;

  final ContentApi _api;
  final LocalStore _local;

  Future<AppConfig> config() => _api.fetchConfig();
  Future<DailyContent> daily() => _api.fetchDaily();
  Future<List<VerseExplanation>> verses() => _api.fetchVerses();
  Future<List<VerseExplanation>> versesForSurah(int surahNumber) => _api.fetchVersesForSurah(surahNumber);
  Future<VerseExplanation?> verse(String id) => _api.fetchVerse(id);
  Future<List<QuranWord>> words() => _api.fetchWords();
  Future<QuranWord?> word(String id) => _api.fetchWord(id);
  Future<List<BookItem>> books() => _api.fetchBooks();
  Future<BookItem?> book(String id) => _api.fetchBook(id);
  Future<List<ResearchItem>> research() => _api.fetchResearch();
  Future<ResearchItem?> researchItem(String id) => _api.fetchResearchItem(id);
  Future<List<VideoItem>> videos() => _api.fetchVideos();
  Future<VideoItem?> video(String id) => _api.fetchVideo(id);
  Future<List<QuestionItem>> questions() => _api.fetchQuestions();
  Future<QuestionItem?> question(String id) => _api.fetchQuestion(id);
  Future<List<TopicItem>> topics() => _api.fetchTopics();
  Future<TopicItem?> topic(String id) => _api.fetchTopic(id);

  Future<List<SearchHit>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    await _local.addRecentSearch(trimmed);
    return _api.search(trimmed);
  }

  Future<List<ContentUpdate>> updates({DateTime? since}) {
    return _api.fetchUpdates(since: since);
  }
}

class BookmarkRepository {
  BookmarkRepository(this._local);
  final LocalStore _local;

  Set<String> all() => _local.bookmarks();
  bool isBookmarked(String key) => _local.isBookmarked(key);
  Future<void> toggle(String key) => _local.toggleBookmark(key);
}

class SettingsRepository {
  SettingsRepository(this._local);
  final LocalStore _local;

  UserSettings load() {
    return UserSettings(
      language: _local.language(),
      themeMode: _local.themeMode(),
      fontScale: _local.fontScale(),
      quranFontScale: _local.quranFontScale(),
      notifications: _local.notificationPrefs(),
    );
  }

  Future<void> saveLanguage(AppLanguage language) => _local.setLanguage(language);
  Future<void> saveTheme(String mode) => _local.setThemeMode(mode);
  Future<void> saveFontScale(double value) => _local.setFontScale(value);
  Future<void> saveQuranFontScale(double value) => _local.setQuranFontScale(value);
  Future<void> saveNotifications(NotificationPrefs prefs) => _local.setNotificationPrefs(prefs);
}

class ProgressRepository {
  ProgressRepository(this._local);
  final LocalStore _local;

  int chapterFor(String bookId) => _local.readingProgress()[bookId] ?? 0;
  Future<void> setChapter(String bookId, int index) => _local.setReadingProgress(bookId, index);
  double videoFor(String videoId) => _local.videoProgress()[videoId] ?? 0;
  Future<void> setVideo(String videoId, double value) => _local.setVideoProgress(videoId, value);
  String? continueBookId() {
    final progress = _local.readingProgress();
    if (progress.isEmpty) return null;
    return progress.keys.last;
  }

  String? continueVideoId() {
    final progress = _local.videoProgress();
    if (progress.isEmpty) return null;
    return progress.keys.last;
  }
}

class SearchHistoryRepository {
  SearchHistoryRepository(this._local);
  final LocalStore _local;
  List<String> recent() => _local.recentSearches();
  Future<void> clear() => _local.clearRecentSearches();
}

class NotificationInboxRepository {
  NotificationInboxRepository(this._local);
  final LocalStore _local;

  List<AppNotification> all() => _local.inbox();

  Future<void> add(AppNotification item) async {
    final items = _local.inbox();
    if (items.any((existing) => existing.id == item.id)) return;
    items.insert(0, item);
    await _local.saveInbox(items);
  }

  Future<void> markRead(String id) async {
    final items = _local.inbox().map((item) {
      return item.id == id ? item.copyWith(read: true) : item;
    }).toList();
    await _local.saveInbox(items);
  }
}
