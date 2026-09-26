import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/catalog_chrome.dart';
import '../../../../data/providers.dart';
import '../../data/models/library_book.dart';
import '../books_providers.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  String _query = '';
  String _categoryId = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final progress = ref.watch(readingProgressMapProvider);
    final booksAsync = ref.watch(libraryBooksProvider);
    final categoriesAsync = ref.watch(libraryCategoriesProvider);

    return CatalogPageScaffold(
      title: strings.booksTitle,
      searchHint: strings.searchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      child: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(libraryBooksProvider),
        ),
        data: (books) {
          final categories = categoriesAsync.valueOrNull ?? const <BookCategory>[];
          final filtered = books.where((book) {
            final matchesCategory = _categoryId.isEmpty || book.categoryId == _categoryId;
            final hay = '${book.title.resolve(language)} ${book.author.resolve(language)} ${book.description.resolve(language)}';
            return matchesCategory && hay.contains(_query);
          }).toList();
          final featured = filtered.where((book) => book.featured).toList();
          final recentIds = progress.values.toList()
            ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
          final recent = [
            for (final item in recentIds)
              for (final book in books)
                if (book.id == item.bookId) book,
          ];
          final newest = [...filtered]
            ..sort((a, b) => (b.publishedAt ?? b.createdAt ?? DateTime(2000))
                .compareTo(a.publishedAt ?? a.createdAt ?? DateTime(2000)));

          if (books.isEmpty) {
            return StatusPanel(title: strings.emptyTitle, body: strings.libraryEmptyBody);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              if (categories.isNotEmpty) ...[
                CategoryChips(
                  items: [strings.all, ...categories.map((c) => c.title.resolve(language))],
                  selected: _categoryId.isEmpty
                      ? strings.all
                      : categories
                          .firstWhere(
                            (c) => c.id == _categoryId,
                            orElse: () => categories.first,
                          )
                          .title
                          .resolve(language),
                  onSelected: (label) {
                    setState(() {
                      if (label == strings.all) {
                        _categoryId = '';
                      } else {
                        _categoryId = categories
                            .firstWhere((c) => c.title.resolve(language) == label)
                            .id;
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 14),
              ],
              if (featured.isNotEmpty) ...[
                _SectionTitle(strings.featuredBooks),
                const SizedBox(height: 10),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final book = featured[index];
                      return SizedBox(
                        width: 140,
                        child: BookCoverCard(
                          book: book,
                          progress: progress[book.id],
                          language: language,
                          onTap: () => context.push('/books/${book.id}'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (recent.isNotEmpty) ...[
                _SectionTitle(strings.recentlyOpened),
                const SizedBox(height: 10),
                ...recent.take(4).map(
                  (book) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookListCard(
                      book: book,
                      progress: progress[book.id],
                      language: language,
                      pageLabel: strings.pagesCount,
                      onTap: () => context.push('/books/${book.id}'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _SectionTitle(strings.newBooks),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                StatusPanel(title: strings.emptyTitle, body: strings.emptyBody)
              else
                ...newest.map(
                  (book) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookListCard(
                      book: book,
                      progress: progress[book.id],
                      language: language,
                      pageLabel: strings.pagesCount,
                      onTap: () => context.push('/books/${book.id}'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTypography.uiFamily,
        color: AppColors.navy,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class BookCoverCard extends StatelessWidget {
  const BookCoverCard({
    super.key,
    required this.book,
    required this.language,
    required this.onTap,
    this.progress,
  });

  final LibraryBook book;
  final AppLanguage language;
  final BookReadingProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: BookCover(url: book.coverImageUrl, title: book.title.resolve(language))),
          const SizedBox(height: 8),
          Text(
            book.title.resolve(language),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.contentStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              height: 1.3,
            ),
          ),
          if (progress != null)
            Text(
              '${progress!.currentPage}',
              style: const TextStyle(color: AppColors.goldMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class BookListCard extends StatelessWidget {
  const BookListCard({
    super.key,
    required this.book,
    required this.language,
    required this.pageLabel,
    required this.onTap,
    this.progress,
  });

  final LibraryBook book;
  final AppLanguage language;
  final String pageLabel;
  final BookReadingProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pages = book.pageCount > 0 ? book.pageCount : null;
    final ratio = progress == null || pages == null || pages == 0
        ? 0.0
        : (progress!.currentPage / pages).clamp(0.0, 1.0);
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 96,
                child: BookCover(url: book.coverImageUrl, title: book.title.resolve(language)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title.resolve(language),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.contentStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author.resolve(language),
                      style: AppTypography.contentStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (pages != null) pageLabel.replaceFirst('{n}', '$pages'),
                        book.language,
                      ].where((e) => e.trim().isNotEmpty).join(' · '),
                      style: AppTypography.contentStyle(
                        fontSize: 12,
                        color: AppColors.navy,
                      ),
                    ),
                    if (ratio > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 5,
                          backgroundColor: AppColors.lightBlue,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.title, this.url});

  final String? url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.medallion,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
        ),
        child: url == null || url!.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.goldSoft, fontFamily: AppTypography.uiFamily, fontSize: 12),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, _, _) => Center(
                  child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.goldSoft)),
                ),
              ),
      ),
    );
  }
}
