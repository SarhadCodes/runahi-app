import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/providers.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final keys = ref.watch(bookmarksProvider).toList();
    final filtered = keys.where((key) => key.contains(_query)).toList();

    return CatalogPageScaffold(
      title: strings.navBookmarks,
      searchHint: strings.searchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      child: filtered.isEmpty
          ? StatusPanel(title: strings.emptyTitle, body: strings.emptyBody)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final key = filtered[index];
                final parts = key.split(':');
                final kind = parts.first;
                final id = parts.length > 1 ? parts.sublist(1).join(':') : key;
                final route = switch (kind) {
                  'book' => '/books/$id',
                  'research' => '/research/$id',
                  'verse' => '/verses/$id',
                  _ => '/home',
                };
                final kindLabel = switch (kind) {
                  'book' => strings.booksTitle,
                  'research' => strings.researchTitle,
                  'verse' => strings.versesTitle,
                  _ => kind,
                };
                return CatalogListCard(
                  title: id,
                  footer: kindLabel,
                  leading: const CatalogIconBadge(icon: Icons.bookmark_rounded),
                  trailing: IconButton(
                    onPressed: () => ref.read(bookmarksProvider.notifier).toggle(key),
                    icon: const Icon(Icons.close_rounded, color: AppColors.navy),
                  ),
                  onTap: () => context.push(route),
                );
              },
            ),
    );
  }
}
