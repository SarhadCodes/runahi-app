import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/catalog_chrome.dart';
import '../../../../data/providers.dart';
import '../books_providers.dart';
import 'books_library_screen.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final progress = ref.watch(readingProgressMapProvider)[id];

    return ref.watch(libraryBookProvider(id)).when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF2F4F7),
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: StatusPanel(title: strings.errorTitle, body: strings.errorBody),
      ),
      data: (book) {
        if (book == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F4F7),
            body: StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
          );
        }
        final hasProgress = progress != null && progress.currentPage > 1;
        return CatalogPageScaffold(
          title: book.title.resolve(language),
          meta: book.categoryTitle?.resolve(language),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Center(
                child: SizedBox(
                  width: 180,
                  height: 250,
                  child: BookCover(url: book.coverImageUrl, title: book.title.resolve(language)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                book.title.resolve(language),
                textAlign: TextAlign.center,
                style: AppTypography.contentStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                book.author.resolve(language),
                textAlign: TextAlign.center,
                style: AppTypography.contentStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (book.categoryTitle != null)
                    _MetaChip(book.categoryTitle!.resolve(language)),
                  if (book.pageCount > 0)
                    _MetaChip(strings.pagesCount.replaceFirst('{n}', '${book.pageCount}')),
                  _MetaChip(book.language),
                ],
              ),
              if (hasProgress) ...[
                const SizedBox(height: 14),
                Text(
                  strings.continueFromPage.replaceFirst('{n}', '${progress.currentPage}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFamily,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    book.description.resolve(language),
                    style: AppTypography.contentStyle(
                      fontSize: 15,
                      color: AppColors.navy,
                      height: 1.75,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.push('/books/${book.id}/read'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  hasProgress ? strings.continueReadingBook : strings.startReadingBook,
                  style: const TextStyle(fontFamily: AppTypography.uiFamily, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.uiFamily,
          color: AppColors.navy,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
