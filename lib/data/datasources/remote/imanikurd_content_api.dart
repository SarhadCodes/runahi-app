import 'package:imanikurd/imanikurd.dart' as iman;

import '../../models/content_models.dart';
import '../../models/core_models.dart';
import 'content_api.dart';
import 'mock_content_api.dart';

LocalizedText _ku(String text) => LocalizedText(sorani: text, badini: text);

class ImaniKurdContentApi implements ContentApi {
  ImaniKurdContentApi({MockContentApi mock = const MockContentApi()}) : _mock = mock;

  final MockContentApi _mock;
  /// ڕێبەر is Central Kurdish (Sorani). ڕوناهی is Badini.
  static const _tafsirSorani = 'rebar';
  static const _tafsirBadini = 'runahi';

  LocalizedText _tafsirText(String sorani, String badini) {
    if (sorani.isEmpty && badini.isEmpty) return LocalizedText.empty;
    if (badini.isEmpty) return LocalizedText(sorani: sorani, badini: sorani);
    if (sorani.isEmpty) return LocalizedText(sorani: badini, badini: badini);
    return LocalizedText(sorani: sorani, badini: badini);
  }

  @override
  Future<AppConfig> fetchConfig() => _mock.fetchConfig();

  @override
  Future<DailyContent> fetchDaily() async {
    final day = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final ayahs = await iman.getFullQuran();
    final ayah = ayahs[day % ayahs.length];
    final surah = await iman.getSurah(ayah.surah);
    final soraniTafsir = await iman.getTafsirForAyah(_tafsirSorani, ayah.surah, ayah.ayah) ?? '';
    final badiniTafsir = await iman.getTafsirForAyah(_tafsirBadini, ayah.surah, ayah.ayah) ?? '';
    final names = await iman.getNamesOfAllah();
    final name = names[day % names.length];
    final hadiths = await iman.getHadiths();
    final hadith = hadiths[day % hadiths.length];
    return DailyContent(
      verseId: '${ayah.surah}-${ayah.ayah}',
      arabic: ayah.text,
      translation: _tafsirText(
        soraniTafsir.isEmpty ? (surah?.kurdishName ?? '') : soraniTafsir,
        badiniTafsir.isEmpty ? (surah?.kurdishName ?? '') : badiniTafsir,
      ),
      topicId: 'dhikr-1',
      topicTitle: _ku(hadith.title),
      wordId: 'name-${name.id}',
      message: _ku(hadith.kurdish),
    );
  }

  @override
  Future<List<VerseExplanation>> fetchVerses() async => const [];

  @override
  Future<List<VerseExplanation>> fetchVersesForSurah(int surahNumber) async => const [];

  @override
  Future<VerseExplanation?> fetchVerse(String id) async => null;

  @override
  Future<List<QuranWord>> fetchWords() async {
    final names = await iman.getNamesOfAllah();
    return [
      for (final name in names)
        QuranWord(
          id: 'name-${name.id}',
          arabic: name.arabic,
          normalized: name.english.toLowerCase(),
          root: name.english,
          meaning: _ku(name.kurdish),
          occurrences: 1,
          surahs: const [],
          exampleVerseIds: const [],
          relatedWordIds: const [],
        ),
    ];
  }

  @override
  Future<QuranWord?> fetchWord(String id) async {
    final words = await fetchWords();
    for (final word in words) {
      if (word.id == id) return word;
    }
    return null;
  }

  @override
  Future<List<BookItem>> fetchBooks() async => const [];

  @override
  Future<BookItem?> fetchBook(String id) async => null;

  @override
  Future<List<ResearchItem>> fetchResearch() async {
    final companions = await iman.getCompanions();
    return [
      for (final item in companions)
        ResearchItem(
          id: 'companion-${item.id}',
          title: _ku(item.name),
          description: _ku(item.arabic ?? item.name),
          body: _ku([
            if (item.arabic != null && item.arabic!.isNotEmpty) item.arabic!,
            item.description ?? item.name,
            ...item.extra.entries
                .where((entry) => entry.value is String && (entry.value as String).trim().isNotEmpty)
                .map((entry) => '${entry.value}'),
          ].join('\n\n')),
          author: _ku('ئیمانی کورد'),
          category: _ku('هاوەڵان'),
          readingMinutes: 4,
          relatedIds: const [],
        ),
    ];
  }

  @override
  Future<ResearchItem?> fetchResearchItem(String id) async {
    final items = await fetchResearch();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<List<VideoItem>> fetchVideos() => _mock.fetchVideos();

  @override
  Future<VideoItem?> fetchVideo(String id) => _mock.fetchVideo(id);

  @override
  Future<List<QuestionItem>> fetchQuestions() async => const [];

  @override
  Future<QuestionItem?> fetchQuestion(String id) async => null;

  @override
  Future<List<TopicItem>> fetchTopics() async => const [];

  @override
  Future<TopicItem?> fetchTopic(String id) async => null;

  @override
  Future<List<ContentUpdate>> fetchUpdates({DateTime? since}) async {
    return const [];
  }

  @override
  Future<List<SearchHit>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final hits = <SearchHit>[];
    final ayahs = await iman.searchQuran(trimmed);
    for (final ayah in ayahs.take(12)) {
      hits.add(
        SearchHit(
          id: '${ayah.surah}-${ayah.ayah}',
          kind: ContentKind.verse,
          title: _ku(ayah.text),
          subtitle: _ku('${ayah.surah}:${ayah.ayah}'),
        ),
      );
    }
    final tafsir = await iman.searchTafsir(_tafsirSorani, trimmed);
    for (final entry in tafsir.take(8)) {
      hits.add(
        SearchHit(
          id: '${entry.s}-${entry.a}',
          kind: ContentKind.verse,
          title: _ku(entry.t),
          subtitle: _ku('${entry.s}:${entry.a}'),
        ),
      );
    }
    final names = await iman.searchNamesOfAllah(trimmed);
    for (final name in names.take(6)) {
      hits.add(
        SearchHit(
          id: 'name-${name.id}',
          kind: ContentKind.word,
          title: _ku(name.arabic),
          subtitle: _ku(name.kurdish),
        ),
      );
    }
    final companions = await iman.searchCompanions(trimmed);
    for (final companion in companions.take(6)) {
      hits.add(
        SearchHit(
          id: 'companion-${companion.id}',
          kind: ContentKind.research,
          title: _ku(companion.name),
          subtitle: _ku(companion.arabic ?? ''),
        ),
      );
    }
    return hits;
  }
}
