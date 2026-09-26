import '../../models/content_models.dart';
import '../../models/core_models.dart';

/// Remote contract. The mock implementation is swapped for Dio later
/// without changing repositories or UI.
abstract class ContentApi {
  Future<AppConfig> fetchConfig();
  Future<DailyContent> fetchDaily();
  Future<List<VerseExplanation>> fetchVerses();
  Future<List<VerseExplanation>> fetchVersesForSurah(int surahNumber);
  Future<VerseExplanation?> fetchVerse(String id);
  Future<List<QuranWord>> fetchWords();
  Future<QuranWord?> fetchWord(String id);
  Future<List<BookItem>> fetchBooks();
  Future<BookItem?> fetchBook(String id);
  Future<List<ResearchItem>> fetchResearch();
  Future<ResearchItem?> fetchResearchItem(String id);
  Future<List<VideoItem>> fetchVideos();
  Future<VideoItem?> fetchVideo(String id);
  Future<List<QuestionItem>> fetchQuestions();
  Future<QuestionItem?> fetchQuestion(String id);
  Future<List<TopicItem>> fetchTopics();
  Future<TopicItem?> fetchTopic(String id);
  Future<List<ContentUpdate>> fetchUpdates({DateTime? since});
  Future<List<SearchHit>> search(String query);
}
