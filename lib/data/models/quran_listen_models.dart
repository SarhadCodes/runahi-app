class QuranReciter {
  const QuranReciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.cdnId,
  });

  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String cdnId;

  static const List<QuranReciter> catalog = [
    QuranReciter(id: 'ar.alafasy', nameArabic: 'مشاري راشد العفاسي', nameEnglish: 'Mishari Alafasy', cdnId: 'ar.alafasy'),
    QuranReciter(id: 'ar.husary', nameArabic: 'محمود خليل الحصري', nameEnglish: 'Mahmoud Khalil Al-Husary', cdnId: 'ar.husary'),
    QuranReciter(id: 'ar.minshawi', nameArabic: 'محمد صديق المنشاوي', nameEnglish: 'Mohamed Siddiq El-Minshawi', cdnId: 'ar.minshawi'),
    QuranReciter(id: 'ar.abdulbasitmurattal', nameArabic: 'عبد الباسط عبد الصمد', nameEnglish: 'Abdul Basit Murattal', cdnId: 'ar.abdulbasitmurattal'),
    QuranReciter(id: 'ar.mahermuaiqly', nameArabic: 'ماهر المعيقلي', nameEnglish: 'Maher Al Muaiqly', cdnId: 'ar.mahermuaiqly'),
    QuranReciter(id: 'ar.hudhaify', nameArabic: 'علي بن عبد الرحمن الحذيفي', nameEnglish: 'Ali Al-Hudhaify', cdnId: 'ar.hudhaify'),
  ];

  static QuranReciter byId(String id) {
    return catalog.firstWhere((item) => item.id == id, orElse: () => catalog.first);
  }

  String audioUrl({required int globalNumber, required int surahNumber}) {
    return 'https://cdn.islamic.network/quran/audio/128/$cdnId/$globalNumber.mp3';
  }
}

class QuranSurahInfo {
  const QuranSurahInfo({
    required this.number,
    required this.nameArabic,
    required this.englishName,
    required this.ayahCount,
    required this.meccan,
  });

  final int number;
  final String nameArabic;
  final String englishName;
  final int ayahCount;
  final bool meccan;
}

class QuranAyahAudio {
  const QuranAyahAudio({
    required this.globalNumber,
    required this.numberInSurah,
    required this.text,
    required this.audioUrl,
  });

  final int globalNumber;
  final int numberInSurah;
  final String text;
  final String audioUrl;
}

class QuranSurahAudio {
  const QuranSurahAudio({
    required this.info,
    required this.reciter,
    required this.ayahs,
  });

  final QuranSurahInfo info;
  final QuranReciter reciter;
  final List<QuranAyahAudio> ayahs;
}
