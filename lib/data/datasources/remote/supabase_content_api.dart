import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/content_models.dart';
import '../../models/core_models.dart';
import '../../../core/config/supabase_env.dart';
import '../../../core/utils/supabase_time.dart';
import 'content_api.dart';

class SupabaseContentApi implements ContentApi {
  SupabaseContentApi(this._fallback);

  final ContentApi _fallback;

  bool get _ready => SupabaseEnv.initialized;

  SupabaseClient get _client => Supabase.instance.client;

  LocalizedText _cols(Map<String, dynamic> json, String key) {
    final sorani = '${json['${key}_sorani'] ?? ''}';
    var badini = '${json['${key}_badini'] ?? ''}';
    if (badini.isEmpty) badini = sorani;
    if (sorani.isEmpty && badini.isEmpty) return LocalizedText.empty;
    return LocalizedText(sorani: sorani.isEmpty ? badini : sorani, badini: badini);
  }

  List<String> _ids(dynamic value) {
    if (value is List) {
      return value.map((item) => '$item').where((item) => item.isNotEmpty).toList();
    }
    return const [];
  }

  List<LocalizedText> _colList(Map<String, dynamic> json, String key) {
    final sorani = _ids(json['${key}_sorani']);
    final badini = _ids(json['${key}_badini']);
    final length = sorani.length > badini.length ? sorani.length : badini.length;
    return [
      for (var i = 0; i < length; i++)
        LocalizedText(
          sorani: i < sorani.length ? sorani[i] : '',
          badini: i < badini.length ? badini[i] : (i < sorani.length ? sorani[i] : ''),
        ),
    ];
  }

  Future<T> _orFallback<T>(Future<T> Function() load, Future<T> Function() fallback) async {
    if (!_ready) return fallback();
    try {
      return await load();
    } catch (_) {
      return fallback();
    }
  }

  ResearchItem _research(Map<String, dynamic> json) {
    final dateLabel = _cols(json, 'date_label');
    return ResearchItem(
      id: json['id'] as String,
      title: _cols(json, 'title'),
      description: _cols(json, 'description'),
      body: _cols(json, 'body'),
      author: _cols(json, 'author'),
      category: _cols(json, 'category'),
      readingMinutes: (json['reading_minutes'] as num?)?.toInt() ?? 5,
      relatedIds: _ids(json['related_ids']),
      dateLabel: dateLabel.sorani.isEmpty && dateLabel.badini.isEmpty ? null : dateLabel,
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  VideoItem _video(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'] as String,
      title: _cols(json, 'title'),
      description: _cols(json, 'description'),
      category: _cols(json, 'category'),
      durationLabel: json['duration_label'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      videoUrl: json['video_url'] as String?,
      relatedIds: _ids(json['related_ids']),
      featured: json['featured'] as bool? ?? false,
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  QuestionItem _question(Map<String, dynamic> json) {
    final videoId = '${json['video_id'] ?? ''}'.trim();
    return QuestionItem(
      id: json['id'] as String,
      question: _cols(json, 'question'),
      answer: _cols(json, 'answer'),
      category: _cols(json, 'category'),
      videoId: videoId.isEmpty ? null : videoId,
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  TopicItem _topic(Map<String, dynamic> json) {
    final videoId = '${json['video_id'] ?? ''}'.trim();
    return TopicItem(
      id: json['id'] as String,
      title: _cols(json, 'title'),
      introduction: _cols(json, 'introduction'),
      body: _cols(json, 'body'),
      videoId: videoId.isEmpty ? null : videoId,
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  VerseExplanation _verse(Map<String, dynamic> json) {
    return VerseExplanation(
      id: json['id'] as String,
      surahNumber: (json['surah_number'] as num?)?.toInt() ?? 0,
      ayahNumber: (json['ayah_number'] as num?)?.toInt() ?? 0,
      surahNameArabic: json['name_arabic'] as String? ?? '',
      surahName: _cols(json, 'name'),
      arabic: json['arabic'] as String? ?? '',
      translation: _cols(json, 'translation'),
    );
  }

  QuranWord _word(Map<String, dynamic> json) {
    return QuranWord(
      id: json['id'] as String,
      arabic: json['arabic'] as String? ?? '',
      normalized: json['normalized'] as String? ?? '',
      root: json['root'] as String? ?? '',
      meaning: _cols(json, 'meaning'),
      occurrences: (json['occurrences'] as num?)?.toInt() ?? 1,
      surahs: _colList(json, 'surahs'),
      exampleVerseIds: _ids(json['example_verse_ids']),
      relatedWordIds: _ids(json['related_word_ids']),
    );
  }

  List<T> _items<T>(dynamic rows, T Function(Map<String, dynamic> json) map) {
    if (rows is! Iterable) return const [];
    return [
      for (final raw in rows)
        if (raw is Map)
          map(Map<String, dynamic>.from(raw)),
    ];
  }

  @override
  Future<AppConfig> fetchConfig() {
    return _orFallback(() async {
      final row = await _client.from('app_config').select().eq('id', 'default').maybeSingle();
      if (row == null) return _fallback.fetchConfig();
      return AppConfig(
        whatsAppNumber: row['whatsapp_number'] as String? ?? '',
        whatsAppPrefill: _cols(row, 'whatsapp_prefill'),
        contentVersion: row['content_version'] as String? ?? '1',
        privacyUrl: row['privacy_url'] as String? ?? '',
        termsUrl: row['terms_url'] as String? ?? '',
        supportEmail: row['support_email'] as String? ?? '',
        aboutBody: _cols(row, 'about_body'),
        missionBody: _cols(row, 'mission_body'),
        teamBody: _cols(row, 'team_body'),
      );
    }, _fallback.fetchConfig);
  }

  @override
  Future<DailyContent> fetchDaily() {
    return _orFallback(() async {
      final row = await _client.from('daily_content').select().order('id', ascending: false).limit(1).maybeSingle();
      if (row == null) return _fallback.fetchDaily();
      return DailyContent(
        verseId: row['verse_id'] as String? ?? '',
        arabic: row['arabic'] as String? ?? '',
        translation: _cols(row, 'translation'),
        topicId: row['topic_id'] as String? ?? '',
        topicTitle: _cols(row, 'topic_title'),
        wordId: row['word_id'] as String? ?? '',
        message: _cols(row, 'message'),
      );
    }, _fallback.fetchDaily);
  }

  @override
  Future<List<VerseExplanation>> fetchVerses() async {
    if (!_ready) return const [];
    try {
      final rows = await _client.from('surahs').select().order('number');
      final items = <VerseExplanation>[];
      for (final raw in rows as List<dynamic>) {
        if (raw is! Map<String, dynamic>) continue;
        final number = (raw['number'] as num?)?.toInt() ?? 0;
        final name = _cols(raw, 'name');
        items.add(
          VerseExplanation(
            id: '$number-1',
            surahNumber: number,
            ayahNumber: 1,
            surahNameArabic: raw['name_arabic'] as String? ?? '',
            surahName: name,
            arabic: raw['name_arabic'] as String? ?? '',
            translation: name,
          ),
        );
      }
      return items;
    } catch (e, st) {
      debugPrint('fetchVerses failed: $e\n$st');
      return const [];
    }
  }

  @override
  Future<List<VerseExplanation>> fetchVersesForSurah(int surahNumber) async {
    if (!_ready) return const [];
    try {
      final surah = await _client.from('surahs').select().eq('number', surahNumber).maybeSingle();
      final rows = await _client.from('verses').select().eq('surah_number', surahNumber).order('ayah_number', ascending: true);
      return _items(rows, (row) {
        return _verse({
          ...row,
          'name_arabic': surah?['name_arabic'] as String? ?? '',
          'name_sorani': surah?['name_sorani'],
          'name_badini': surah?['name_badini'],
        });
      });
    } catch (e, st) {
      debugPrint('fetchVersesForSurah failed: $e\n$st');
      return const [];
    }
  }

  @override
  Future<VerseExplanation?> fetchVerse(String id) async {
    if (!_ready) return null;
    try {
      final row = await _client.from('verses').select().eq('id', id).maybeSingle();
      if (row == null) return null;
      final surahNumber = (row['surah_number'] as num?)?.toInt() ?? 0;
      final surah = await _client.from('surahs').select().eq('number', surahNumber).maybeSingle();
      return _verse({
        ...row,
        'name_arabic': surah?['name_arabic'] as String? ?? '',
        'name_sorani': surah?['name_sorani'],
        'name_badini': surah?['name_badini'],
      });
    } catch (e, st) {
      debugPrint('fetchVerse failed: $e\n$st');
      return null;
    }
  }

  @override
  Future<List<QuranWord>> fetchWords() {
    return _orFallback(() async {
      final items = _items(await _client.from('words').select().order('id'), _word);
      if (items.isEmpty) return _fallback.fetchWords();
      return items;
    }, _fallback.fetchWords);
  }

  @override
  Future<QuranWord?> fetchWord(String id) {
    return _orFallback(() async {
      final row = await _client.from('words').select().eq('id', id).maybeSingle();
      if (row == null) return _fallback.fetchWord(id);
      return _word(row);
    }, () => _fallback.fetchWord(id));
  }

  @override
  Future<List<BookItem>> fetchBooks() async => const <BookItem>[];

  @override
  Future<BookItem?> fetchBook(String id) async => null;

  @override
  Future<List<ResearchItem>> fetchResearch() {
    return _orFallback(() async {
      final items = _items(await _client.from('research').select().order('id'), _research);
      if (items.isEmpty) return _fallback.fetchResearch();
      return items;
    }, _fallback.fetchResearch);
  }

  @override
  Future<ResearchItem?> fetchResearchItem(String id) async {
    final items = await fetchResearch();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return _fallback.fetchResearchItem(id);
  }

  @override
  Future<List<VideoItem>> fetchVideos() {
    return _orFallback(() async {
      final items = _items(await _client.from('videos').select().order('id'), _video);
      if (items.isEmpty) return _fallback.fetchVideos();
      return items;
    }, _fallback.fetchVideos);
  }

  @override
  Future<VideoItem?> fetchVideo(String id) async {
    final items = await fetchVideos();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return _fallback.fetchVideo(id);
  }

  @override
  Future<List<QuestionItem>> fetchQuestions() async {
    if (!_ready) return const [];
    try {
      return _items(await _client.from('questions').select().order('id'), _question);
    } catch (e, st) {
      debugPrint('fetchQuestions failed: $e\n$st');
      return const [];
    }
  }

  @override
  Future<QuestionItem?> fetchQuestion(String id) async {
    if (!_ready) return null;
    try {
      final row = await _client.from('questions').select().eq('id', id).maybeSingle();
      if (row is Map<String, dynamic>) return _question(row);
    } catch (e, st) {
      debugPrint('fetchQuestion failed: $e\n$st');
    }
    return null;
  }

  @override
  Future<List<TopicItem>> fetchTopics() async {
    if (!_ready) return const [];
    try {
      return _items(await _client.from('topics').select().order('id'), _topic);
    } catch (e, st) {
      debugPrint('fetchTopics failed: $e\n$st');
      return const [];
    }
  }

  @override
  Future<TopicItem?> fetchTopic(String id) async {
    if (!_ready) return null;
    try {
      final row = await _client.from('topics').select().eq('id', id).maybeSingle();
      if (row is Map<String, dynamic>) return _topic(row);
    } catch (e, st) {
      debugPrint('fetchTopic failed: $e\n$st');
    }
    return null;
  }

  @override
  Future<List<ContentUpdate>> fetchUpdates({DateTime? since}) async {
    if (!_ready) return const [];
    try {
      final items = _items(
        await _client.from('content_updates').select().order('created_at', ascending: false),
        (raw) {
          final kindName = '${raw['kind'] ?? ''}';
          return ContentUpdate(
            id: '${raw['id']}',
            kind: ContentKind.values.firstWhere(
              (kind) => kind.name == kindName,
              orElse: () => ContentKind.announcement,
            ),
            title: _cols(raw, 'title'),
            createdAt: parseSupabaseTime(raw['created_at']),
            deepLink: raw['deep_link'] as String?,
          );
        },
      );
      if (since == null) return items;
      return items.where((item) => item.createdAt.isAfter(since)).toList();
    } catch (error, stack) {
      debugPrint('fetchUpdates failed: $error\n$stack');
      return const [];
    }
  }

  @override
  Future<List<SearchHit>> search(String query) {
    return _orFallback(() async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return const [];
      final pattern = '%$trimmed%';
      final hits = <SearchHit>[];

      Future<void> addHits({
        required String table,
        required ContentKind kind,
        required String titleKey,
        String? subtitleKey,
      }) async {
        final rows = await _client.from(table).select().or(
              '${titleKey}_sorani.ilike."$pattern",${titleKey}_badini.ilike."$pattern"',
            ).limit(12);
        for (final raw in rows as List<dynamic>) {
          if (raw is! Map<String, dynamic>) continue;
          hits.add(
            SearchHit(
              id: raw['id'] as String,
              kind: kind,
              title: _cols(raw, titleKey),
              subtitle: subtitleKey == null ? LocalizedText.empty : _cols(raw, subtitleKey),
            ),
          );
        }
      }

      final verses = await _client.from('verses').select().or(
            'arabic.ilike."$pattern",translation_sorani.ilike."$pattern",translation_badini.ilike."$pattern"',
          ).limit(12);
      for (final raw in verses as List<dynamic>) {
        if (raw is! Map<String, dynamic>) continue;
        hits.add(
          SearchHit(
            id: raw['id'] as String,
            kind: ContentKind.verse,
            title: LocalizedText(sorani: raw['arabic'] as String? ?? '', badini: raw['arabic'] as String? ?? ''),
            subtitle: _cols(raw, 'translation'),
          ),
        );
      }

      await addHits(table: 'words', kind: ContentKind.word, titleKey: 'meaning');
      final wordRows = await _client.from('words').select().ilike('arabic', pattern).limit(8);
      for (final raw in wordRows as List<dynamic>) {
        if (raw is! Map<String, dynamic>) continue;
        hits.add(
          SearchHit(
            id: raw['id'] as String,
            kind: ContentKind.word,
            title: LocalizedText(sorani: raw['arabic'] as String? ?? '', badini: raw['arabic'] as String? ?? ''),
            subtitle: _cols(raw, 'meaning'),
          ),
        );
      }
      await addHits(table: 'research', kind: ContentKind.research, titleKey: 'title', subtitleKey: 'description');
      await addHits(table: 'videos', kind: ContentKind.video, titleKey: 'title', subtitleKey: 'description');
      await addHits(table: 'questions', kind: ContentKind.question, titleKey: 'question', subtitleKey: 'category');
      await addHits(table: 'topics', kind: ContentKind.topic, titleKey: 'title', subtitleKey: 'introduction');
      final topicBodyRows = await _client.from('topics').select().or(
            'body_sorani.ilike."$pattern",body_badini.ilike."$pattern"',
          ).limit(12);
      for (final raw in topicBodyRows as List<dynamic>) {
        if (raw is! Map<String, dynamic>) continue;
        final id = raw['id'] as String;
        if (hits.any((hit) => hit.id == id && hit.kind == ContentKind.topic)) continue;
        hits.add(
          SearchHit(
            id: id,
            kind: ContentKind.topic,
            title: _cols(raw, 'title'),
            subtitle: _cols(raw, 'introduction'),
          ),
        );
      }
      return hits;
    }, () async => const <SearchHit>[]);
  }
}
