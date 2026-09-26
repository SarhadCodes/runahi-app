import 'package:equatable/equatable.dart';

import 'core_models.dart';

class VerseExplanation extends Equatable {
  const VerseExplanation({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.translation,
    this.surahNameArabic = '',
    this.surahName = LocalizedText.empty,
  });

  final String id;
  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final LocalizedText translation;

  /// Joined from `surahs` for display — not a column on `verses`.
  final String surahNameArabic;
  final LocalizedText surahName;

  String get ref => '$surahNumber:$ayahNumber';

  @override
  List<Object?> get props => [id, surahNumber, ayahNumber, arabic];
}

class QuranWord extends Equatable {
  const QuranWord({
    required this.id,
    required this.arabic,
    required this.normalized,
    required this.root,
    required this.meaning,
    required this.occurrences,
    required this.surahs,
    required this.exampleVerseIds,
    required this.relatedWordIds,
  });

  final String id;
  final String arabic;
  final String normalized;
  final String root;
  final LocalizedText meaning;
  final int occurrences;
  final List<LocalizedText> surahs;
  final List<String> exampleVerseIds;
  final List<String> relatedWordIds;

  @override
  List<Object?> get props => [id, arabic, root];
}

class BookChapter extends Equatable {
  const BookChapter({
    required this.id,
    required this.title,
    required this.body,
    required this.order,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText body;
  final int order;

  @override
  List<Object?> get props => [id, order];
}

class BookItem extends Equatable {
  const BookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.chapters,
    this.coverColor,
    this.sourceUrl,
    this.updatedAt,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText author;
  final LocalizedText category;
  final LocalizedText description;
  final List<BookChapter> chapters;
  final String? coverColor;
  final String? sourceUrl;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, title];
}

class ResearchItem extends Equatable {
  const ResearchItem({
    required this.id,
    required this.title,
    required this.description,
    required this.body,
    required this.author,
    required this.category,
    required this.readingMinutes,
    required this.relatedIds,
    this.dateLabel,
    this.updatedAt,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final LocalizedText body;
  final LocalizedText author;
  final LocalizedText category;
  final int readingMinutes;
  final List<String> relatedIds;
  final LocalizedText? dateLabel;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id];
}

class VideoItem extends Equatable {
  const VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationLabel,
    required this.thumbnailUrl,
    this.videoUrl,
    this.relatedIds = const [],
    this.featured = false,
    this.updatedAt,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final LocalizedText category;
  final String durationLabel;
  final String thumbnailUrl;
  final String? videoUrl;
  final List<String> relatedIds;
  final bool featured;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id];
}

class QuestionItem extends Equatable {
  const QuestionItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.videoId,
    this.updatedAt,
  });

  final String id;
  final LocalizedText question;
  final LocalizedText answer;
  final LocalizedText category;
  /// Optional related video from the `videos` table.
  final String? videoId;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id];
}

class TopicItem extends Equatable {
  const TopicItem({
    required this.id,
    required this.title,
    required this.introduction,
    required this.body,
    this.videoId,
    this.updatedAt,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText introduction;
  final LocalizedText body;
  /// Optional related video from the `videos` table.
  final String? videoId;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.deepLink,
    this.read = false,
  });

  final String id;
  final ContentKind kind;
  final LocalizedText title;
  final LocalizedText body;
  final DateTime createdAt;
  final String deepLink;
  final bool read;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      createdAt: createdAt,
      deepLink: deepLink,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title.toJson(),
    'body': body.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'deepLink': deepLink,
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      kind: ContentKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => ContentKind.announcement,
      ),
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      body: LocalizedText.fromJson(json['body'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      deepLink: json['deepLink'] as String? ?? '/',
      read: json['read'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, read];
}
