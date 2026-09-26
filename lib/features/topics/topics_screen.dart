import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/body_with_quran_words.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/content_models.dart';
import '../../data/providers.dart';

class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    return CatalogPageScaffold(
      title: strings.topicsTitle,
      searchHint: strings.searchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      child: ref.watch(topicsProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(topicsProvider),
        ),
        data: (items) {
          final filtered = items.where((item) {
            final q = _query.trim();
            if (q.isEmpty) return true;
            return item.title.resolve(language).contains(q) ||
                item.introduction.resolve(language).contains(q) ||
                item.body.resolve(language).contains(q);
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
              final intro = ScriptAwareText.kurdishOnly(item.introduction.resolve(language));
              return CatalogListCard(
                title: item.title.resolve(language),
                subtitle: intro.isEmpty ? null : intro,
                leading: const CatalogIconBadge(icon: Icons.brightness_5_outlined),
                onTap: () => context.push('/topics/${item.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class TopicDetailScreen extends ConsumerWidget {
  const TopicDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    return ref.watch(topicsProvider).when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF2F4F7),
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: StatusPanel(title: strings.errorTitle, body: strings.errorBody),
      ),
      data: (items) {
        final item = items.cast<TopicItem?>().firstWhere((entry) => entry?.id == id, orElse: () => null);
        if (item == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F4F7),
            body: StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
          );
        }
        final intro = item.introduction.resolve(language).trim();
        final body = item.body.resolve(language).trim();
        final videoId = item.videoId?.trim();
        final hasVideo = videoId != null && videoId.isNotEmpty;
        final videoTitle = hasVideo
            ? ref.watch(videosProvider).maybeWhen(
                data: (videos) {
                  for (final video in videos) {
                    if (video.id == videoId) return video.title.resolve(language);
                  }
                  return strings.groupVideos;
                },
                orElse: () => strings.groupVideos,
              )
            : null;
        return CatalogPageScaffold(
          title: item.title.resolve(language),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              if (intro.isNotEmpty) ...[
                Text(
                  strings.introduction,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: ScriptSplitBody(intro),
                  ),
                ),
              ],
              if (body.isNotEmpty) ...[
                if (intro.isNotEmpty) const SizedBox(height: 22),
                Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: BodyWithQuranWords(body),
                  ),
                ),
              ],
              if (hasVideo) ...[
                const SizedBox(height: 22),
                CatalogListCard(
                  title: videoTitle ?? strings.groupVideos,
                  footer: strings.videosTitle,
                  leading: const CatalogIconBadge(icon: Icons.play_circle_outline_rounded),
                  onTap: () => context.push('/videos/$videoId'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
