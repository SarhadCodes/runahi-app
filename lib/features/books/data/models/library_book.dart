import 'package:equatable/equatable.dart';

import '../../../../data/models/core_models.dart';

class BookCategory extends Equatable {
  const BookCategory({
    required this.id,
    required this.title,
    this.sortOrder = 0,
  });

  final String id;
  final LocalizedText title;
  final int sortOrder;

  @override
  List<Object?> get props => [id];
}

class LibraryBook extends Equatable {
  const LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.pdfUrl,
    required this.language,
    required this.pageCount,
    this.coverImageUrl,
    this.categoryId,
    this.categoryTitle,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.featured = false,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText author;
  final LocalizedText description;
  final String pdfUrl;
  final String language;
  final int pageCount;
  final String? coverImageUrl;
  final String? categoryId;
  final LocalizedText? categoryTitle;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool featured;

  bool get hasPdf => pdfUrl.trim().isNotEmpty;

  @override
  List<Object?> get props => [id, pdfUrl, pageCount, updatedAt];
}

class BookReadingProgress extends Equatable {
  const BookReadingProgress({
    required this.bookId,
    required this.currentPage,
    required this.lastOpened,
  });

  final String bookId;
  /// 1-based page index.
  final int currentPage;
  final DateTime lastOpened;

  @override
  List<Object?> get props => [bookId, currentPage, lastOpened];
}

class BookPageBookmark extends Equatable {
  const BookPageBookmark({
    required this.bookId,
    required this.page,
    required this.createdAt,
  });

  final String bookId;
  final int page;
  final DateTime createdAt;

  @override
  List<Object?> get props => [bookId, page];
}

class BookSearchHit extends Equatable {
  const BookSearchHit({
    required this.page,
    required this.preview,
  });

  final int page;
  final String preview;

  @override
  List<Object?> get props => [page, preview];
}

class ReaderPreferences extends Equatable {
  const ReaderPreferences({
    this.pageSound = true,
    this.pageAnimation = true,
    this.animationSpeed = 1,
    this.brightness = 1,
    this.keepAwake = true,
  });

  final bool pageSound;
  final bool pageAnimation;
  final double animationSpeed;
  final double brightness;
  final bool keepAwake;

  ReaderPreferences copyWith({
    bool? pageSound,
    bool? pageAnimation,
    double? animationSpeed,
    double? brightness,
    bool? keepAwake,
  }) {
    return ReaderPreferences(
      pageSound: pageSound ?? this.pageSound,
      pageAnimation: pageAnimation ?? this.pageAnimation,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      brightness: brightness ?? this.brightness,
      keepAwake: keepAwake ?? this.keepAwake,
    );
  }

  @override
  List<Object?> get props => [pageSound, pageAnimation, animationSpeed, brightness, keepAwake];
}
