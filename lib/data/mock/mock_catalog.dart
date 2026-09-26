import '../models/content_models.dart';
import '../models/core_models.dart';

LocalizedText L(String sorani, [String? badini]) =>
    LocalizedText(sorani: sorani, badini: badini ?? sorani);

/// Sample catalog used until the remote API is connected.
/// Religious text is limited to well-known Quran verses and structural
/// educational notes. Scholarly rulings are not invented here.
class MockCatalog {
  MockCatalog._();

  static final DateTime _stamp = DateTime.utc(2026, 3, 1);

  static AppConfig get config => AppConfig(
    whatsAppNumber: '',
    whatsAppPrefill: L(
      'سڵاو، پرسیارێکم هەیە سەبارەت بە رووناهى.',
      'سلاڤ، پسیارەکە هەیە لدور رووناهى.',
    ),
    contentVersion: '1',
    privacyUrl: 'https://rounahi.app/privacy',
    termsUrl: 'https://rounahi.app/terms',
    supportEmail: '',
    aboutBody: L(
      'رووناهى پلاتفۆڕمێکی کوردییە بۆ خوێندنەوە، توێژینەوە و تێگەیشتنی قورئان. مەبەست لە ناوەکە ڕووناهییە: ڕوونکردنەوەی واتای ئایەت و وشە و بابەت بە زمانێکی ئارام و متمانەپێکراو.',
      'رووناهى پلاتفۆرمایەکا کوردییە بۆ خاندن، ڤەکولین و تێگەهشتنا قورئانێ. مەبەست ژ ناڤی ڕووناهییە: ڕوونکرنا رامانا ئایەت و پەیڤ و بابەتان ب زمانەکێ ئارام.',
    ),
    missionBody: L(
      'ئامانجی رووناهى ئەوەیە خوێنەری کورد بتوانێت قورئان بخوێنێتەوە، واتای ئایەت و وشەکان تێبگات، توێژینەوە و ڤیدیۆ ببینێت، و پرسیارەکانی بە شێوەیەکی ڕێکخراو بدۆزێتەوە. ناوەڕۆکی ئایینی لە سەرچاوەی پشتڕاستکراوەوە دێت.',
      'ئارمانجا رووناهى ئەوەیە خواندەڤانێ کورد بشێت قورئانێ بخوێنیت، رامانا ئایەت و پەیڤان تێبگەهیت، ڤەکولین و ڤیدیویان ببینیت، و پسیارێن خۆ ب شێوەیەکێ ڕێکخستی بدۆزیت.',
    ),
    teamBody: L(
      'رووناهى پڕۆژەیەکی فێرکارییە. تیم لەسەر ناوەڕۆکی کوردی، وەرگێڕان، و شێوازی پێشکەشکردنی قورئان کاردەکات. ناوەڕۆک لە پانێلی بەڕێوەبردنەوە نوێ دەکرێتەوە بێ ئەوەی وەشانێکی نوێی ئەپ پێویست بێت.',
      'رووناهى پڕۆژەیەکێ فێرکارییە. تیم لسەر ناڤەڕۆکا کوردی، وەرگێڕان، و شێوازێ پێشکەشکرنا قورئانێ کارتکەت. ناڤەڕۆک ژ پانێلا بەڕێڤەبرنێ دهێتە نووکرن.',
    ),
  );

  static DailyContent get daily => DailyContent(
    verseId: '20-114',
    arabic: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
    translation: L(
      'و بڵێ: پەروەردگارم، زانستم زیاد بکە.',
      'و بێژە: پەروەردگارێ من، زانینا من زێدە بکە.',
    ),
    topicId: 'topic-ilm',
    topicTitle: L('زانست و فێربوون', 'زانست و فێربوون'),
    wordId: 'word-ilm',
    message: L(
      'ڕۆژێک بە داواکردنی زانست دەست پێدەکات.',
      'ڕۆژەک ب داخوازیا زانستێ دەستپێدکەت.',
    ),
  );

  static final List<VerseExplanation> verses = [
    VerseExplanation(
      id: '1-1',
      surahNumber: 1,
      ayahNumber: 1,
      surahNameArabic: 'الفاتحة',
      surahName: L('فاتیحە', 'فاتیحە'),
      arabic: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      translation: L(
        'بە ناوی خودای بەخشندە و میهرەبان.',
        'ب ناڤێ خودایێ دڵۆڤان و میهرەبان.',
      ),
    ),
    VerseExplanation(
      id: '20-114',
      surahNumber: 20,
      ayahNumber: 114,
      surahNameArabic: 'طه',
      surahName: L('تاها', 'تاها'),
      arabic: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
      translation: L(
        'و بڵێ: پەروەردگارم، زانستم زیاد بکە.',
        'و بێژە: پەروەردگارێ من، زانینا من زێدە بکە.',
      ),
    ),
    VerseExplanation(
      id: '2-152',
      surahNumber: 2,
      ayahNumber: 152,
      surahNameArabic: 'البقرة',
      surahName: L('بەقەرە', 'بەقەرە'),
      arabic: 'فَاذْكُرُونِي أَذْكُرْكُمْ',
      translation: L(
        'جا بمبیربێننەوە، باشتان بیر دەهێنمەوە.',
        'جا بمبیربێنن، باشتان بیرهێنم.',
      ),
    ),
  ];

  static final List<QuranWord> words = [
    QuranWord(
      id: 'word-rahma',
      arabic: 'رَحْمَة',
      normalized: 'رحمة',
      root: 'ر-ح-م',
      meaning: L('بەزەیی / میهرەبانی', 'دلۆڤانی / میهرەبانی'),
      occurrences: 114,
      surahs: [L('فاتیحە'), L('بەقەرە'), L('ئەنعام')],
      exampleVerseIds: ['1-1'],
      relatedWordIds: ['word-ilm'],
    ),
    QuranWord(
      id: 'word-ilm',
      arabic: 'عِلْم',
      normalized: 'علم',
      root: 'ع-ل-م',
      meaning: L('زانست / زانیاری', 'زانست / زانین'),
      occurrences: 105,
      surahs: [L('تاها'), L('عەلەق'), L('بەقەرە')],
      exampleVerseIds: ['20-114', '96-1'],
      relatedWordIds: ['word-rahma'],
    ),
    QuranWord(
      id: 'word-sabr',
      arabic: 'صَبْر',
      normalized: 'صبر',
      root: 'ص-ب-ر',
      meaning: L('خۆگری / سەبر', 'خۆگری / سەبر'),
      occurrences: 103,
      surahs: [L('بەقەرە'), L('عەسر')],
      exampleVerseIds: ['2-153'],
      relatedWordIds: ['word-salah'],
    ),
    QuranWord(
      id: 'word-salah',
      arabic: 'صَلَاة',
      normalized: 'صلاة',
      root: 'ص-ل-و',
      meaning: L('نوێژ', 'نوێژ'),
      occurrences: 99,
      surahs: [L('بەقەرە'), L('موئمینوون')],
      exampleVerseIds: ['2-153'],
      relatedWordIds: ['word-sabr'],
    ),
    QuranWord(
      id: 'word-nur',
      arabic: 'نُور',
      normalized: 'نور',
      root: 'ن-و-ر',
      meaning: L('ڕووناکی / ڕووناهی', 'ڕووناهی'),
      occurrences: 43,
      surahs: [L('نوور'), L('بەقەرە')],
      exampleVerseIds: ['20-114'],
      relatedWordIds: ['word-ilm'],
    ),
    QuranWord(
      id: 'word-iman',
      arabic: 'إِيمَان',
      normalized: 'ايمان',
      root: 'ء-م-ن',
      meaning: L('باوەڕ / ئیمان', 'باوەڕ / ئیمان'),
      occurrences: 45,
      surahs: [L('بەقەرە'), L('ئیمان')],
      exampleVerseIds: ['2-153'],
      relatedWordIds: ['word-sabr'],
    ),
  ];

  static final List<BookItem> books = [];

  static final List<ResearchItem> research = [
    ResearchItem(
      id: 'res-tafsir-method',
      title: L('شێوازی خوێندنەوەی تەفسیر', 'شێوازێ خاندنا تەفسیرێ'),
      description: L(
        'چۆن دەق، وەرگێڕان، و سەرچاوە لە یەک پەڕەدا ڕێکدەخرێن.',
        'چەوا دەق، وەرگێڕان، و ژێدەر د پەرەکێ دا دهێنە ڕێکخستن.',
      ),
      body: L(
        'توێژینەوەیەکی فێرکاری سەبارەت بە پێکهاتەی پەڕەی ئایەت: دەقی عەرەبی، وەرگێڕانی کوردی، ڕوونکردنەوە، و سەرچاوە. مەبەست ڕوونکردنەوەی شێوازە نەک دەرکردنی حوکم.',
        'ڤەکولینەکا فێرکاری لدور پێکهاتەیا پەرێ ئایەتێ: دەقێ عەرەبی، وەرگێڕانا کوردی، ڕوونکرن، و ژێدەر.',
      ),
      author: L('بەشی توێژینەوەی رووناهى', 'پشکا ڤەکولینێ یا رووناهى'),
      category: L('تەفسیر', 'تەفسیر'),
      readingMinutes: 8,
      relatedIds: ['res-history-script'],
      dateLabel: L('ئازار ٢٠٢٦', 'ئادار ٢٠٢٦'),
      updatedAt: _stamp,
    ),
    ResearchItem(
      id: 'res-history-script',
      title: L('دەق و خوێندنەوەی عەرەبی', 'دەق و خاندنا عەرەبی'),
      description: L(
        'گرنگی پاراستنی شەکڵی عەرەبی لە پیشاندانی قورئان.',
        'گرنگا پاراستنا شێوێ عەرەبی د نیشاندانا قورئانێ دا.',
      ),
      body: L(
        'لە رووناهى دەقی عەرەبی بە فۆنتێکی قورئانی پیشان دەدرێت و شەکڵ تێکناچێت. ئەم توێژینەوەیە بنەمای تەکنیکی و فێرکاری ڕوون دەکاتەوە.',
        'ل رووناهى دەقێ عەرەبی ب فۆنتەکێ قورئانی دهێتە نیشاندان و شێو تێکناچیت.',
      ),
      author: L('بەشی توێژینەوەی رووناهى', 'پشکا ڤەکولینێ یا رووناهى'),
      category: L('مێژوو', 'مێژوو'),
      readingMinutes: 6,
      relatedIds: ['res-tafsir-method'],
      dateLabel: L('شوبات ٢٠٢٦', 'شوبات ٢٠٢٦'),
      updatedAt: _stamp,
    ),
    ResearchItem(
      id: 'res-kurdish-read',
      title: L('خوێندنەوەی کوردی بۆ قورئان', 'خاندنا کوردی بۆ قورئانێ'),
      description: L(
        'سۆرانی و بادینی لە یەک پلاتفۆڕمدا.',
        'سۆرانی و بادینی د پلاتفۆرمایەکێ دا.',
      ),
      body: L(
        'رووناهى دوو شێوەزاری کوردی پشتیوانی دەکات. ناوەڕۆک و ناوەڕۆکی ڕووکار جیاوازن و لە سەرچاوەی ناوەڕۆکەوە دێن.',
        'رووناهى دوو شێوەزارێن کوردی پشتیوانی دکەت. ناڤەڕۆک و ڕووکار ژ ژێدەرێ ناڤەڕۆکێ دهێن.',
      ),
      author: L('بەشی توێژینەوەی رووناهى', 'پشکا ڤەکولینێ یا رووناهى'),
      category: L('فێرکاری', 'فێرکاری'),
      readingMinutes: 7,
      relatedIds: ['res-tafsir-method'],
      dateLabel: L('کانوونی دووەم ٢٠٢٦', 'چلە ٢٠٢٦'),
      updatedAt: _stamp,
    ),
  ];

  static final List<VideoItem> videos = [
    VideoItem(
      id: 'vid-ayah',
      title: L('ڕوونکردنەوەی ئایەتی زانست', 'ڕوونکرنا ئایەتێ زانستێ'),
      description: L(
        'خوێندنەوەیەکی ئارام بۆ ئایەتی «رَبِّ زِدْنِي عِلْمًا».',
        'خاندنەکا ئارام بۆ ئایەتێ «رَبِّ زِدْنِي عِلْمًا».',
      ),
      category: L('ڕوونکردنەوەی ئایەت', 'ڕوونکرنا ئایەتێ'),
      durationLabel: '08:20',
      thumbnailUrl: '',
      featured: true,
      relatedIds: ['vid-tafsir'],
      updatedAt: _stamp,
    ),
    VideoItem(
      id: 'vid-tafsir',
      title: L('چۆن تەفسیر بخوێنینەوە', 'چەوا تەفسیرێ بخوێنین'),
      description: L(
        'ڕێنمایی فێرکاری بۆ جیاکردنەوەی دەق، وەرگێڕان، و ڕوونکردنەوە.',
        'ڕێنماییێن فێرکاری بۆ جوداکرنا دەقی، وەرگێڕانێ، و ڕوونکرنێ.',
      ),
      category: L('تەفسیر', 'تەفسیر'),
      durationLabel: '12:04',
      thumbnailUrl: '',
      relatedIds: ['vid-ayah'],
      updatedAt: _stamp,
    ),
    VideoItem(
      id: 'vid-stories',
      title: L('فێرکارییەکی گشتی', 'فێرکاریەکا گشتی'),
      description: L(
        'دەروازەیەک بۆ زنجیرەی فێرکاری. ڤیدیۆی تەواو لە سەرچاوەی ناوەڕۆکەوە زیاد دەکرێت.',
        'دەرگەهەک بۆ زنجیرەیا فێرکاری. ڤیدیوێ تەمام ژ ژێدەرێ ناڤەڕۆکێ دهێت.',
      ),
      category: L('فێرکاری', 'فێرکاری'),
      durationLabel: '05:40',
      thumbnailUrl: '',
      relatedIds: ['vid-info'],
      updatedAt: _stamp,
    ),
    VideoItem(
      id: 'vid-info',
      title: L('زانیارییە ئیسلامییەکان', 'زانیاریێن ئیسلامی'),
      description: L(
        'پێشەکییەک بۆ بابەتە گشتییەکان بە شێوازی بینراو.',
        'پێشەکییەک بۆ بابەتێن گشتی ب شێوازێ دیتنێ.',
      ),
      category: L('زانیارییە ئیسلامییەکان', 'زانیاریێن ئیسلامی'),
      durationLabel: '09:15',
      thumbnailUrl: '',
      relatedIds: ['vid-stories'],
      updatedAt: _stamp,
    ),
  ];

  static final List<QuestionItem> questions = [
    QuestionItem(
      id: 'qa-quran',
      question: L('رووناهى چۆن ئایەت پیشان دەدات؟', 'رووناهى چەوا ئایەتێ نیشان ددەت؟'),
      answer: L(
        'هەر ئایەتێک دەقی عەرەبی و وەرگێڕانی کوردی لەخۆدەگرێت. وشەی ((رحمة)) نموونەیەکە (بڕوانە وشەکان).',
        'هەر ئایەتەک دەقێ عەرەبی و وەرگێڕانا کوردی وەرگرتیە. پەیڤا ((رحمة)) نموونەیەکە (پەیڤان ببینە).',
      ),
      category: L('قورئان', 'قورئان'),
      videoId: 'vid-ayah',
      updatedAt: _stamp,
    ),
    QuestionItem(
      id: 'qa-lang',
      question: L('جیاوازی سۆرانی و بادینی لە ئەپەکەدا چییە؟', 'جوداهیا سۆرانی و بادینی ل بەرنامێ دا چییە؟'),
      answer: L(
        'هەموو نووسینی ڕووکار و ناوەڕۆک لە هەردوو شێوەزاردا هەیە. گۆڕینی زمان ئاڕاستەی ڕاست-بۆ-چەپ دەهێڵێتەوە و هەڵبژاردنەکە پاشەکەوت دەکرێت.',
        'هەمی نڤیسینێن ڕووکاری و ناڤەڕۆک ب هەردوو شێوەزاران هەنە. گوهۆڕینا زمانی هەلبژارتێ هەلدگریت.',
      ),
      category: L('پرسیارە گشتییەکان', 'پسیارێن گشتی'),
      updatedAt: _stamp,
    ),
    QuestionItem(
      id: 'qa-worship',
      question: L('ئایا رووناهى حوکم دەردەکات؟', 'ئەرێ رووناهى هوکمێ ددەت؟'),
      answer: L(
        'نا. رووناهى پلاتفۆڕمی فێرکاری و زانیارییە. حوکم و فەتوا لە سەرچاوەی زانستی پشتڕاستکراو دێت ئەگەر لە ناوەڕۆکدا هەبێت؛ لێرە حوکم دروست ناکرێت.',
        'نەخێر. رووناهى پلاتفۆرما فێرکاری و زانیارییە. هوکم ژ ژێدەرێ زانستی پشتڕاستکری دهێت؛ ل ڤێرە هوکم ناهێتە چێکرن.',
      ),
      category: L('عەقیدە', 'عەقیدە'),
      updatedAt: _stamp,
    ),
    QuestionItem(
      id: 'qa-daily',
      question: L('چۆن ئایەتی ڕۆژانە بەکاردەهێنرێت؟', 'چەوا ئایەتا ڕۆژانە دهێتە بکارئینان؟'),
      answer: L(
        'لە سەرەتا، ویجێتی سکرینی سەرەکی، و ئاگادارکردنەوەی خۆجێیی. ناوەڕۆک لە کاتێکی دوایین پشکنینەوە نوێ دەکرێتەوە.',
        'ل دەستپێکێ، ویجێتێ ئێکرانێ، و هشیاریێن خۆجێیی. ناڤەڕۆک ژ پشکنینا داوی دهێتە نووکرن.',
      ),
      category: L('ژیانی ڕۆژانە', 'ژیانا ڕۆژانە'),
      updatedAt: _stamp,
    ),
  ];

  static final List<TopicItem> topics = [
    TopicItem(
      id: 'topic-iman',
      title: L('ئیمان', 'ئیمان'),
      introduction: L(
        'دەروازەیەک بۆ بابەتی باوەڕ.',
        'دەرگەهەک بۆ بابەتێ باوەڕێ.',
      ),
      body: L(
        'ئیمان لە رووناهى وەک بابەتێکی فێرکاری ڕێکخراوە. وشەی ((رحمة)) لە قورئاندا زۆر دێت (بڕوانە وشەکان).',
        'ئیمان ل رووناهى وەک بابەتەکێ فێرکاری هاتییە ڕێکخستن. پەیڤا ((رحمة)) ل قورئانێ گەلەک دهێت (پەیڤان ببینە).',
      ),
      videoId: 'vid-info',
      updatedAt: _stamp,
    ),
    TopicItem(
      id: 'topic-quran',
      title: L('قورئان', 'قورئان'),
      introduction: L(
        'دەروازەی سەرەکی بۆ ئایەت و وشە.',
        'دەرگەهێ سەرەکی بۆ ئایەت و پەیڤ.',
      ),
      body: L(
        'لە سەرەتاوە ئایەتی ڕۆژ هەڵبژێرە، یان وشەیەک وەک ((صبر)) بخوێنەوە.',
        'ژ دەستپێکێ ئایەتا ڕۆژێ هەلبژێرە، یان پەیڤەکێ وەک ((صبر)) بخوێنە.',
      ),
      updatedAt: _stamp,
    ),
  ];

  static List<ContentUpdate> updatesSince(DateTime? since) {
    final items = <ContentUpdate>[
      ContentUpdate(
        id: 'res-tafsir-method',
        kind: ContentKind.research,
        title: L('توێژینەوەیەکی نوێ بەردەستە.', 'ڤەکولینەکا نوو بەردەستە.'),
        createdAt: _stamp,
        deepLink: '/research/res-tafsir-method',
      ),
      ContentUpdate(
        id: '20-114',
        kind: ContentKind.verse,
        title: L('ڕوونکردنەوەی ئایەتێکی نوێ زیادکرا.', 'ڕوونکرنا ئایەتەکێ نوو هاتە زێدەکرن.'),
        createdAt: _stamp,
        deepLink: '/verses/20-114',
      ),
      ContentUpdate(
        id: 'vid-ayah',
        kind: ContentKind.video,
        title: L('ڤیدیۆیەکی نوێ بەردەستە.', 'ڤیدیویەکێ نوو بەردەستە.'),
        createdAt: _stamp,
        deepLink: '/videos/vid-ayah',
      ),
      ContentUpdate(
        id: 'qa-quran',
        kind: ContentKind.question,
        title: L('پرسیار و وەڵامێکی نوێ زیادکرا.', 'پسیار و بەرسڤەکا نوو هاتە زێدەکرن.'),
        createdAt: _stamp,
        deepLink: '/questions/qa-quran',
      ),
      ContentUpdate(
        id: 'topic-ilm',
        kind: ContentKind.topic,
        title: L('بابەتێکی نوێ لە رووناهى زیادکرا.', 'بابەتەکێ نوو ل رووناهى هاتە زێدەکرن.'),
        createdAt: _stamp,
        deepLink: '/topics/topic-ilm',
      ),
    ];
    if (since == null) return items;
    return items.where((item) => item.createdAt.isAfter(since)).toList();
  }

  static List<String> get suggestedSearches => const ['سەبر', 'رحمة', 'زانست', 'ئیمان', 'نوێژ'];
}
