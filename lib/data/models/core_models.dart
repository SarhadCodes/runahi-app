import 'package:equatable/equatable.dart';

import '../../core/localization/app_language.dart';

class LocalizedText extends Equatable {
  const LocalizedText({required this.sorani, required this.badini});

  final String sorani;
  final String badini;

  String resolve(AppLanguage language) {
    return language == AppLanguage.badini ? badini : sorani;
  }

  Map<String, dynamic> toJson() => {'sorani': sorani, 'badini': badini};

  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      sorani: json['sorani'] as String? ?? '',
      badini: json['badini'] as String? ?? json['sorani'] as String? ?? '',
    );
  }

  static const empty = LocalizedText(sorani: '', badini: '');

  @override
  List<Object?> get props => [sorani, badini];
}

enum ContentKind {
  book,
  research,
  verse,
  word,
  video,
  question,
  topic,
  announcement;

  String get pathSegment => switch (this) {
    ContentKind.book => 'books',
    ContentKind.research => 'research',
    ContentKind.verse => 'verses',
    ContentKind.word => 'words',
    ContentKind.video => 'videos',
    ContentKind.question => 'questions',
    ContentKind.topic => 'topics',
    ContentKind.announcement => 'notifications',
  };
}

class AppConfig extends Equatable {
  const AppConfig({
    required this.whatsAppNumber,
    required this.whatsAppPrefill,
    required this.contentVersion,
    required this.privacyUrl,
    required this.termsUrl,
    required this.supportEmail,
    required this.aboutBody,
    required this.missionBody,
    required this.teamBody,
  });

  final String whatsAppNumber;
  final LocalizedText whatsAppPrefill;
  final String contentVersion;
  final String privacyUrl;
  final String termsUrl;
  final String supportEmail;
  final LocalizedText aboutBody;
  final LocalizedText missionBody;
  final LocalizedText teamBody;

  bool get hasWhatsApp => whatsAppNumber.trim().isNotEmpty;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      whatsAppNumber: json['whatsAppNumber'] as String? ?? '',
      whatsAppPrefill: json['whatsAppPrefill'] is Map<String, dynamic>
          ? LocalizedText.fromJson(json['whatsAppPrefill'] as Map<String, dynamic>)
          : LocalizedText(
              sorani: json['whatsAppPrefillSorani'] as String? ??
                  'سڵاو، پرسیارێکم هەیە سەبارەت بە رووناهى.',
              badini: json['whatsAppPrefillBadini'] as String? ??
                  'سلاڤ، پسیارەکە هەیە لدور رووناهى.',
            ),
      contentVersion: json['contentVersion'] as String? ?? '1',
      privacyUrl: json['privacyUrl'] as String? ?? '',
      termsUrl: json['termsUrl'] as String? ?? '',
      supportEmail: json['supportEmail'] as String? ?? '',
      aboutBody: json['aboutBody'] is Map<String, dynamic>
          ? LocalizedText.fromJson(json['aboutBody'] as Map<String, dynamic>)
          : LocalizedText.empty,
      missionBody: json['missionBody'] is Map<String, dynamic>
          ? LocalizedText.fromJson(json['missionBody'] as Map<String, dynamic>)
          : LocalizedText.empty,
      teamBody: json['teamBody'] is Map<String, dynamic>
          ? LocalizedText.fromJson(json['teamBody'] as Map<String, dynamic>)
          : LocalizedText.empty,
    );
  }

  @override
  List<Object?> get props => [whatsAppNumber, contentVersion];
}

class DailyContent extends Equatable {
  const DailyContent({
    required this.verseId,
    required this.arabic,
    required this.translation,
    required this.topicId,
    required this.topicTitle,
    required this.wordId,
    required this.message,
  });

  final String verseId;
  final String arabic;
  final LocalizedText translation;
  final String topicId;
  final LocalizedText topicTitle;
  final String wordId;
  final LocalizedText message;

  @override
  List<Object?> get props => [verseId, topicId, wordId];
}

class ContentUpdate extends Equatable {
  const ContentUpdate({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    this.deepLink,
  });

  final String id;
  final ContentKind kind;
  final LocalizedText title;
  final DateTime createdAt;
  final String? deepLink;

  @override
  List<Object?> get props => [id, kind];
}

class SearchHit extends Equatable {
  const SearchHit({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final ContentKind kind;
  final LocalizedText title;
  final LocalizedText subtitle;

  @override
  List<Object?> get props => [id, kind];
}

class NotificationPrefs extends Equatable {
  const NotificationPrefs({
    this.books = true,
    this.research = true,
    this.verses = true,
    this.words = true,
    this.videos = true,
    this.questions = true,
    this.topics = true,
    this.dailyAyah = true,
    this.wordOfDay = true,
    this.topicOfDay = true,
  });

  final bool books;
  final bool research;
  final bool verses;
  final bool words;
  final bool videos;
  final bool questions;
  final bool topics;
  final bool dailyAyah;
  final bool wordOfDay;
  final bool topicOfDay;

  bool allows(ContentKind kind) {
    return switch (kind) {
      ContentKind.book => books,
      ContentKind.research => research,
      ContentKind.verse => verses,
      ContentKind.word => words,
      ContentKind.video => videos,
      ContentKind.question => questions,
      ContentKind.topic => topics,
      ContentKind.announcement => true,
    };
  }

  NotificationPrefs copyWith({
    bool? books,
    bool? research,
    bool? verses,
    bool? words,
    bool? videos,
    bool? questions,
    bool? topics,
    bool? dailyAyah,
    bool? wordOfDay,
    bool? topicOfDay,
  }) {
    return NotificationPrefs(
      books: books ?? this.books,
      research: research ?? this.research,
      verses: verses ?? this.verses,
      words: words ?? this.words,
      videos: videos ?? this.videos,
      questions: questions ?? this.questions,
      topics: topics ?? this.topics,
      dailyAyah: dailyAyah ?? this.dailyAyah,
      wordOfDay: wordOfDay ?? this.wordOfDay,
      topicOfDay: topicOfDay ?? this.topicOfDay,
    );
  }

  Map<String, dynamic> toJson() => {
    'books': books,
    'research': research,
    'verses': verses,
    'words': words,
    'videos': videos,
    'questions': questions,
    'topics': topics,
    'dailyAyah': dailyAyah,
    'wordOfDay': wordOfDay,
    'topicOfDay': topicOfDay,
  };

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      books: json['books'] as bool? ?? true,
      research: json['research'] as bool? ?? true,
      verses: json['verses'] as bool? ?? true,
      words: json['words'] as bool? ?? true,
      videos: json['videos'] as bool? ?? true,
      questions: json['questions'] as bool? ?? true,
      topics: json['topics'] as bool? ?? true,
      dailyAyah: json['dailyAyah'] as bool? ?? true,
      wordOfDay: json['wordOfDay'] as bool? ?? true,
      topicOfDay: json['topicOfDay'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    books,
    research,
    verses,
    words,
    videos,
    questions,
    topics,
    dailyAyah,
    wordOfDay,
    topicOfDay,
  ];
}

class UserSettings extends Equatable {
  const UserSettings({
    this.language = AppLanguage.sorani,
    this.themeMode = 'light',
    this.fontScale = 1,
    this.quranFontScale = 1,
    this.notifications = const NotificationPrefs(),
  });

  final AppLanguage language;
  final String themeMode;
  final double fontScale;
  final double quranFontScale;
  final NotificationPrefs notifications;

  UserSettings copyWith({
    AppLanguage? language,
    String? themeMode,
    double? fontScale,
    double? quranFontScale,
    NotificationPrefs? notifications,
  }) {
    return UserSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      quranFontScale: quranFontScale ?? this.quranFontScale,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [language, themeMode, fontScale, quranFontScale, notifications];
}
