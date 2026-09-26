import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/content_models.dart';
import '../../data/providers.dart';

class WordsScreen extends ConsumerStatefulWidget {
  const WordsScreen({super.key});
  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  String _query = '';
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    return CatalogPageScaffold(
      title: strings.wordsTitle,
      searchHint: strings.wordSearchHint,
      onQueryChanged: (value) => _debouncer.run(() => setState(() => _query = value)),
      child: ref.watch(wordsProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(wordsProvider),
        ),
        data: (items) {
          final q = _query.trim();
          final filtered = q.isEmpty
              ? items
              : items.where((word) {
                  return word.arabic.contains(q) ||
                      word.normalized.contains(q) ||
                      word.root.contains(q) ||
                      word.meaning.resolve(language).contains(q);
                }).toList();
          if (filtered.isEmpty) {
            return StatusPanel(title: strings.noResults, body: strings.emptyBody);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final word = filtered[index];
              return CatalogListCard(
                title: word.arabic,
                titleWidget: QuranText(word.arabic, size: 26, textAlign: TextAlign.start),
                footer: '${strings.meaning}: ${word.meaning.resolve(language)}',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${word.occurrences}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () => context.push('/words/${word.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    return ref.watch(wordsProvider).when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF2F4F7),
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: StatusPanel(title: strings.errorTitle, body: strings.errorBody),
      ),
      data: (items) {
        final word = items.cast<QuranWord?>().firstWhere((entry) => entry?.id == id, orElse: () => null);
        if (word == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F4F7),
            body: StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
          );
        }
        return CatalogPageScaffold(
          title: word.arabic,
          useQuranTitle: true,
          meta: word.root.isNotEmpty ? word.root : null,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                  child: QuranText(word.arabic, size: 34),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.meaning,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word.meaning.resolve(language),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.75),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${strings.occurrences}: ${word.occurrences}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
              ),
              if (word.surahs.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  strings.surah,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                ...word.surahs.map(
                  (surah) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CatalogListCard(title: surah.resolve(language)),
                  ),
                ),
              ],
              if (word.exampleVerseIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  strings.relatedVerses,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                ...word.exampleVerseIds.map(
                  (verseId) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CatalogListCard(
                      title: verseId,
                      leading: const CatalogIconBadge(icon: Icons.menu_book_outlined),
                      onTap: () => context.push('/verses/$verseId'),
                    ),
                  ),
                ),
              ],
              if (word.relatedWordIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  strings.related,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                ...word.relatedWordIds.map(
                  (wordId) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CatalogListCard(
                      title: wordId,
                      leading: const CatalogIconBadge(icon: Icons.translate_rounded),
                      onTap: () => context.push('/words/$wordId'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
