import '../../mock/mock_catalog.dart';
import '../../models/content_models.dart';
import '../../models/core_models.dart';
import 'content_api.dart';

class MockContentApi implements ContentApi {
  const MockContentApi();

  Future<T> _delay<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return value;
  }

  @override
  Future<AppConfig> fetchConfig() => _delay(MockCatalog.config);

  @override
  Future<DailyContent> fetchDaily() => _delay(MockCatalog.daily);

  @override
  Future<List<VerseExplanation>> fetchVerses() => _delay(MockCatalog.verses);

  @override
  Future<List<VerseExplanation>> fetchVersesForSurah(int surahNumber) {
    return _delay(MockCatalog.verses.where((item) => item.surahNumber == surahNumber).toList());
  }

  @override
  Future<VerseExplanation?> fetchVerse(String id) {
    return _delay(MockCatalog.verses.cast<VerseExplanation?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    ));
  }

  @override
  Future<List<QuranWord>> fetchWords() => _delay(MockCatalog.words);

  @override
  Future<QuranWord?> fetchWord(String id) {
    return _delay(MockCatalog.words.cast<QuranWord?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    ));
  }

  @override
  Future<List<BookItem>> fetchBooks() => _delay(MockCatalog.books);

  @override
  Future<BookItem?> fetchBook(String id) {
    return _delay(MockCatalog.books.cast<BookItem?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    ));
  }

  @override
  Future<List<ResearchItem>> fetchResearch() => _delay(MockCatalog.research);

  @override
  Future<ResearchItem?> fetchResearchItem(String id) {
    return _delay(MockCatalog.research.cast<ResearchItem?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    ));
  }

  @override
  Future<List<VideoItem>> fetchVideos() => _delay(MockCatalog.videos);

  @override
  Future<VideoItem?> fetchVideo(String id) {
    return _delay(MockCatalog.videos.cast<VideoItem?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    ));
  }

  @override
  Future<List<QuestionItem>> fetchQuestions() => _delay(const []);

  @override
  Future<QuestionItem?> fetchQuestion(String id) => _delay(null);

  @override
  Future<List<TopicItem>> fetchTopics() => _delay(const []);

  @override
  Future<TopicItem?> fetchTopic(String id) => _delay(null);

  @override
  Future<List<ContentUpdate>> fetchUpdates({DateTime? since}) {
    return _delay(MockCatalog.updatesSince(since));
  }

  @override
  Future<List<SearchHit>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final hits = <SearchHit>[];
    bool matches(LocalizedText text) =>
        text.sorani.contains(q) || text.badini.contains(q) || text.sorani.toLowerCase().contains(q.toLowerCase());

    for (final verse in MockCatalog.verses) {
        if (verse.arabic.contains(q) || matches(verse.translation)) {
        hits.add(SearchHit(
          id: verse.id,
          kind: ContentKind.verse,
          title: LocalizedText(sorani: verse.arabic, badini: verse.arabic),
          subtitle: verse.translation,
        ));
      }
    }
    for (final word in MockCatalog.words) {
      if (word.arabic.contains(q) || word.normalized.contains(q) || matches(word.meaning)) {
        hits.add(SearchHit(
          id: word.id,
          kind: ContentKind.word,
          title: LocalizedText(sorani: word.arabic, badini: word.arabic),
          subtitle: word.meaning,
        ));
      }
    }
    for (final book in MockCatalog.books) {
      if (matches(book.title) || matches(book.description)) {
        hits.add(SearchHit(id: book.id, kind: ContentKind.book, title: book.title, subtitle: book.description));
      }
    }
    for (final item in MockCatalog.research) {
      if (matches(item.title) || matches(item.description)) {
        hits.add(SearchHit(id: item.id, kind: ContentKind.research, title: item.title, subtitle: item.description));
      }
    }
    for (final item in MockCatalog.videos) {
      if (matches(item.title) || matches(item.description)) {
        hits.add(SearchHit(id: item.id, kind: ContentKind.video, title: item.title, subtitle: item.description));
      }
    }
    return hits;
  }
}

/// Production remote source. Endpoints stay aligned with [MockContentApi].
class HttpContentApi implements ContentApi {
  HttpContentApi(this._baseUrl);

  final String _baseUrl;

  @override
  Future<AppConfig> fetchConfig() {
    throw UnimplementedError('Wire $_baseUrl/config when the backend is ready.');
  }

  @override
  Future<DailyContent> fetchDaily() {
    throw UnimplementedError('GET $_baseUrl/content/daily');
  }

  @override
  Future<List<VerseExplanation>> fetchVerses() {
    throw UnimplementedError('GET $_baseUrl/verses');
  }

  @override
  Future<List<VerseExplanation>> fetchVersesForSurah(int surahNumber) {
    throw UnimplementedError('GET $_baseUrl/verses?surah=$surahNumber');
  }

  @override
  Future<VerseExplanation?> fetchVerse(String id) {
    throw UnimplementedError('GET $_baseUrl/verses/$id');
  }

  @override
  Future<List<QuranWord>> fetchWords() {
    throw UnimplementedError('GET $_baseUrl/words');
  }

  @override
  Future<QuranWord?> fetchWord(String id) {
    throw UnimplementedError('GET $_baseUrl/words/$id');
  }

  @override
  Future<List<BookItem>> fetchBooks() {
    throw UnimplementedError('GET $_baseUrl/books');
  }

  @override
  Future<BookItem?> fetchBook(String id) {
    throw UnimplementedError('GET $_baseUrl/books/$id');
  }

  @override
  Future<List<ResearchItem>> fetchResearch() {
    throw UnimplementedError('GET $_baseUrl/research');
  }

  @override
  Future<ResearchItem?> fetchResearchItem(String id) {
    throw UnimplementedError('GET $_baseUrl/research/$id');
  }

  @override
  Future<List<VideoItem>> fetchVideos() {
    throw UnimplementedError('GET $_baseUrl/videos');
  }

  @override
  Future<VideoItem?> fetchVideo(String id) {
    throw UnimplementedError('GET $_baseUrl/videos/$id');
  }

  @override
  Future<List<QuestionItem>> fetchQuestions() {
    throw UnimplementedError('GET $_baseUrl/questions');
  }

  @override
  Future<QuestionItem?> fetchQuestion(String id) {
    throw UnimplementedError('GET $_baseUrl/questions/$id');
  }

  @override
  Future<List<TopicItem>> fetchTopics() {
    throw UnimplementedError('GET $_baseUrl/topics');
  }

  @override
  Future<TopicItem?> fetchTopic(String id) {
    throw UnimplementedError('GET $_baseUrl/topics/$id');
  }

  @override
  Future<List<ContentUpdate>> fetchUpdates({DateTime? since}) {
    throw UnimplementedError('GET $_baseUrl/content/updates?since=$since');
  }

  @override
  Future<List<SearchHit>> search(String query) {
    throw UnimplementedError('GET $_baseUrl/search?q=$query');
  }
}
