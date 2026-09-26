import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock/mock_catalog.dart';
import '../../data/models/core_models.dart';
import '../../data/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initial});
  final String? initial;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial ?? '');
  final _debouncer = Debouncer();
  List<SearchHit> _hits = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initial ?? '').isNotEmpty) {
      _run(widget.initial!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _run(String query) async {
    setState(() => _loading = true);
    final hits = await ref.read(contentRepositoryProvider).search(query);
    if (mounted) {
      setState(() {
        _hits = hits;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final recent = ref.watch(searchHistoryRepositoryProvider).recent();
    final grouped = groupBy(_hits, (SearchHit hit) => hit.kind);
    return SectionScaffold(
      title: strings.navSearch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RounahiSearchField(
            controller: _controller,
            hint: strings.searchGlobalHint,
            autofocus: true,
            onChanged: (value) => _debouncer.run(() => _run(value)),
          ),
          const SizedBox(height: 16),
          if (_controller.text.isEmpty) ...[
            PremiumCard(
              onTap: () => context.push('/quran'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.headphones_rounded, color: AppColors.navy),
                title: Text(strings.quranListenTitle),
                subtitle: Text(strings.quranListenCardBody),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
            PremiumCard(
              onTap: () => context.push('/qibla'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.explore_rounded, color: AppColors.navy),
                title: Text(strings.qiblaTitle),
                subtitle: Text(strings.qiblaSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(strings.recentSearches, style: Theme.of(context).textTheme.titleMedium)),
                if (recent.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await ref.read(searchHistoryRepositoryProvider).clear();
                      setState(() {});
                    },
                    child: Text(strings.clear),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: recent
                  .map(
                    (item) => ActionChip(
                      label: Text(item),
                      onPressed: () {
                        _controller.text = item;
                        _run(item);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(strings.suggestedSearches, style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: MockCatalog.suggestedSearches
                  .map(
                    (item) => ActionChip(
                      label: Text(item),
                      onPressed: () {
                        _controller.text = item;
                        _run(item);
                      },
                    ),
                  )
                  .toList(),
            ),
          ] else if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppColors.navy)),
            )
          else if (_hits.isEmpty)
            StatusPanel(title: strings.noResults, body: strings.emptyBody)
          else ...[
            Text('${strings.resultsFor} «${_controller.text}»', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...grouped.entries.map((entry) {
              final label = switch (entry.key) {
                ContentKind.verse => strings.groupVerses,
                ContentKind.word => strings.groupWords,
                ContentKind.topic => strings.groupTopics,
                ContentKind.video => strings.groupVideos,
                ContentKind.question => strings.groupQuestions,
                ContentKind.book => strings.groupBooks,
                ContentKind.research => strings.groupResearch,
                ContentKind.announcement => strings.navNotifications,
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(label, style: Theme.of(context).textTheme.titleLarge),
                  ...entry.value.map(
                    (hit) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: hit.kind == ContentKind.verse || hit.kind == ContentKind.word
                          ? ScriptAwareText(
                              hit.title.resolve(language),
                              style: Theme.of(context).textTheme.titleMedium,
                              arabicSize: 20,
                            )
                          : Text(hit.title.resolve(language)),
                      subtitle: Text(hit.subtitle.resolve(language), maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => context.push('/${hit.kind.pathSegment}/${hit.id}'),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}
