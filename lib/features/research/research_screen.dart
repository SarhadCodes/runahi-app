import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/content_models.dart';
import '../../data/providers.dart';

class ResearchScreen extends ConsumerStatefulWidget {
  const ResearchScreen({super.key});
  @override
  ConsumerState<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends ConsumerState<ResearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    return CatalogPageScaffold(
      title: strings.researchTitle,
      searchHint: strings.searchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      child: ref.watch(researchProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(researchProvider),
        ),
        data: (items) {
          final filtered = items.where((item) {
            final text = '${item.title.resolve(language)} ${item.description.resolve(language)}';
            return text.contains(_query);
          }).toList();
          if (filtered.isEmpty) {
            return StatusPanel(title: strings.emptyTitle, body: strings.emptyBody);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return CatalogListCard(
                title: item.title.resolve(language),
                subtitle: item.description.resolve(language),
                footer: [
                  item.author.resolve(language),
                  if (item.readingMinutes > 0) '${item.readingMinutes} ${strings.minutes}',
                ].where((part) => part.trim().isNotEmpty).join(' · '),
                leading: const CatalogIconBadge(icon: Icons.article_outlined),
                onTap: () => context.push('/research/${item.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class ResearchDetailScreen extends ConsumerWidget {
  const ResearchDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    return ref.watch(researchProvider).when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF2F4F7),
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: StatusPanel(title: strings.errorTitle, body: strings.errorBody),
      ),
      data: (items) {
        final item = items.cast<ResearchItem?>().firstWhere((entry) => entry?.id == id, orElse: () => null);
        if (item == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F4F7),
            body: StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
          );
        }
        final key = 'research:${item.id}';
        final body = item.body.resolve(language);
        final arabic = ScriptAwareText.arabicOnly(body);
        final kurdish = ScriptAwareText.kurdishOnly(body);
        return CatalogPageScaffold(
          title: item.title.resolve(language),
          meta: [
            item.author.resolve(language),
            if (item.dateLabel != null) item.dateLabel!.resolve(language),
          ].where((part) => part.trim().isNotEmpty).join(' · '),
          headerActions: [
            CatalogHeaderIconButton(
              icon: bookmarks.contains(key) ? Icons.bookmark : Icons.bookmark_border,
              onTap: () => ref.read(bookmarksProvider.notifier).toggle(key),
            ),
            const SizedBox(width: 4),
          ],
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              if (item.description.resolve(language).trim().isNotEmpty)
                CatalogListCard(
                  title: item.description.resolve(language),
                  titleWidget: Text(
                    item.description.resolve(language),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.navy,
                      height: 1.7,
                    ),
                  ),
                ),
              if (arabic.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final block in arabic.split('\n\n'))
                  if (block.trim().isNotEmpty) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                        child: QuranText(block.trim(), size: 22),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
              ],
              if (kurdish.isNotEmpty) ...[
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
                        strings.explanation,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        kurdish,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.85),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
              if (item.relatedIds.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  strings.related,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                ...item.relatedIds.map(
                  (relatedId) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CatalogListCard(
                      title: relatedId,
                      leading: const CatalogIconBadge(icon: Icons.article_outlined),
                      onTap: () => context.push('/research/$relatedId'),
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
