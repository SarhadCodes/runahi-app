import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/library_book.dart';

class ReadingProgressService {
  ReadingProgressService(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'library_reading_progress_v1';

  Map<String, BookReadingProgress> all() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in map.entries)
          if (entry.value is Map<String, dynamic>)
            entry.key: BookReadingProgress(
              bookId: entry.key,
              currentPage: (entry.value['page'] as num?)?.toInt() ?? 1,
              lastOpened: DateTime.tryParse('${entry.value['at'] ?? ''}') ?? DateTime.now(),
            ),
      };
    } catch (_) {
      return {};
    }
  }

  BookReadingProgress? forBook(String bookId) => all()[bookId];

  Future<void> save(String bookId, int page) async {
    final next = Map<String, dynamic>.from(
      all().map(
        (key, value) => MapEntry(key, {
          'page': value.currentPage,
          'at': value.lastOpened.toIso8601String(),
        }),
      ),
    );
    next[bookId] = {
      'page': page.clamp(1, 999999),
      'at': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_key, jsonEncode(next));
  }

  Future<void> reset(String bookId) async {
    final next = Map<String, dynamic>.from(
      all().map(
        (key, value) => MapEntry(key, {
          'page': value.currentPage,
          'at': value.lastOpened.toIso8601String(),
        }),
      ),
    )..remove(bookId);
    await _prefs.setString(_key, jsonEncode(next));
  }

  List<BookReadingProgress> recentlyOpened({int limit = 8}) {
    final items = all().values.toList()
      ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    return items.take(limit).toList();
  }
}

class BookBookmarkService {
  BookBookmarkService(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'library_book_page_bookmarks_v1';

  List<BookPageBookmark> forBook(String bookId) {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic> && item['bookId'] == bookId)
            BookPageBookmark(
              bookId: bookId,
              page: (item['page'] as num).toInt(),
              createdAt: DateTime.tryParse('${item['at'] ?? ''}') ?? DateTime.now(),
            ),
      ]..sort((a, b) => a.page.compareTo(b.page));
    } catch (_) {
      return const [];
    }
  }

  bool isBookmarked(String bookId, int page) {
    return forBook(bookId).any((item) => item.page == page);
  }

  Future<void> toggle(String bookId, int page) async {
    final raw = _prefs.getString(_key);
    final list = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        for (final item in jsonDecode(raw) as List<dynamic>) {
          if (item is Map<String, dynamic>) list.add(Map<String, dynamic>.from(item));
        }
      } catch (_) {}
    }
    final index = list.indexWhere((item) => item['bookId'] == bookId && item['page'] == page);
    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.add({
        'bookId': bookId,
        'page': page,
        'at': DateTime.now().toIso8601String(),
      });
    }
    await _prefs.setString(_key, jsonEncode(list));
  }
}

class ReaderPreferencesService {
  ReaderPreferencesService(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'library_reader_prefs_v1';

  ReaderPreferences load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const ReaderPreferences();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ReaderPreferences(
        pageSound: map['pageSound'] as bool? ?? true,
        pageAnimation: map['pageAnimation'] as bool? ?? true,
        animationSpeed: (map['animationSpeed'] as num?)?.toDouble() ?? 1,
        brightness: (map['brightness'] as num?)?.toDouble() ?? 1,
        keepAwake: map['keepAwake'] as bool? ?? true,
      );
    } catch (_) {
      return const ReaderPreferences();
    }
  }

  Future<void> save(ReaderPreferences prefs) {
    return _prefs.setString(
      _key,
      jsonEncode({
        'pageSound': prefs.pageSound,
        'pageAnimation': prefs.pageAnimation,
        'animationSpeed': prefs.animationSpeed,
        'brightness': prefs.brightness,
        'keepAwake': prefs.keepAwake,
      }),
    );
  }
}
