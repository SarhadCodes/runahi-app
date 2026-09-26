import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_language.dart';
import '../../models/content_models.dart';
import '../../models/core_models.dart';

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  SharedPreferences get prefs => _prefs;

  Future<void> reload() => _prefs.reload();

  bool onboardingComplete() => _prefs.getBool(StorageKeys.onboardingComplete) ?? false;

  Future<void> setOnboardingComplete([bool value = true]) {
    return _prefs.setBool(StorageKeys.onboardingComplete, value);
  }

  AppLanguage language() => AppLanguage.fromCode(_prefs.getString(StorageKeys.language));

  String qiblaCityKey() => _prefs.getString(StorageKeys.qiblaCity) ?? 'Hawler';

  Future<void> setQiblaCityKey(String key) {
    return _prefs.setString(StorageKeys.qiblaCity, key);
  }

  Future<void> setLanguage(AppLanguage language) {
    return _prefs.setString(StorageKeys.language, language.code);
  }

  String themeMode() => _prefs.getString(StorageKeys.themeMode) ?? 'light';

  Future<void> setThemeMode(String mode) => _prefs.setString(StorageKeys.themeMode, mode);

  double fontScale() => _prefs.getDouble(StorageKeys.fontScale) ?? 1;

  Future<void> setFontScale(double value) => _prefs.setDouble(StorageKeys.fontScale, value);

  double quranFontScale() => _prefs.getDouble(StorageKeys.quranFontScale) ?? 1;

  Future<void> setQuranFontScale(double value) {
    return _prefs.setDouble(StorageKeys.quranFontScale, value);
  }

  NotificationPrefs notificationPrefs() {
    final raw = _prefs.getString(StorageKeys.notificationPrefs);
    if (raw == null) return const NotificationPrefs();
    return NotificationPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setNotificationPrefs(NotificationPrefs prefs) {
    return _prefs.setString(StorageKeys.notificationPrefs, jsonEncode(prefs.toJson()));
  }

  Set<String> bookmarks() {
    return _prefs.getStringList(StorageKeys.bookmarks)?.toSet() ?? <String>{};
  }

  Future<void> toggleBookmark(String key) {
    final items = bookmarks();
    if (items.contains(key)) {
      items.remove(key);
    } else {
      items.add(key);
    }
    return _prefs.setStringList(StorageKeys.bookmarks, items.toList());
  }

  bool isBookmarked(String key) => bookmarks().contains(key);

  Map<String, int> readingProgress() {
    final raw = _prefs.getString(StorageKeys.readingProgress);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );
  }

  Future<void> setReadingProgress(String bookId, int chapterIndex) {
    final data = readingProgress()..[bookId] = chapterIndex;
    return _prefs.setString(StorageKeys.readingProgress, jsonEncode(data));
  }

  Map<String, double> videoProgress() {
    final raw = _prefs.getString(StorageKeys.videoProgress);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  Future<void> setVideoProgress(String videoId, double value) {
    final data = videoProgress()..[videoId] = value;
    return _prefs.setString(StorageKeys.videoProgress, jsonEncode(data));
  }

  List<String> recentSearches() => _prefs.getStringList(StorageKeys.recentSearches) ?? [];

  Future<void> addRecentSearch(String query) {
    final items = recentSearches().where((item) => item != query).toList();
    items.insert(0, query);
    if (items.length > AppConstants.searchHistoryLimit) {
      items.removeRange(AppConstants.searchHistoryLimit, items.length);
    }
    return _prefs.setStringList(StorageKeys.recentSearches, items);
  }

  Future<void> clearRecentSearches() {
    return _prefs.remove(StorageKeys.recentSearches);
  }

  DateTime? lastContentCheck() {
    final raw = _prefs.getString(StorageKeys.lastContentCheck);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastContentCheck(DateTime value) {
    return _prefs.setString(StorageKeys.lastContentCheck, value.toIso8601String());
  }

  String? lastContentVersion() => _prefs.getString(StorageKeys.lastContentVersion);

  Future<void> setLastContentVersion(String value) {
    return _prefs.setString(StorageKeys.lastContentVersion, value);
  }

  Set<String> notifiedIds() {
    return _prefs.getStringList(StorageKeys.notifiedIds)?.toSet() ?? <String>{};
  }

  Future<void> markNotified(String id) {
    final items = notifiedIds()..add(id);
    final trimmed = items.toList();
    if (trimmed.length > AppConstants.notifiedIdRetention) {
      trimmed.removeRange(0, trimmed.length - AppConstants.notifiedIdRetention);
    }
    return _prefs.setStringList(StorageKeys.notifiedIds, trimmed);
  }

  List<AppNotification> inbox() {
    final raw = _prefs.getString('notification_inbox');
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveInbox(List<AppNotification> items) {
    return _prefs.setString(
      'notification_inbox',
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
