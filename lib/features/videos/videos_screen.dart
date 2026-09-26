import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/video_source.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/content_models.dart';
import '../../data/providers.dart';
import 'video_player_pane.dart';

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});
  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    return CatalogPageScaffold(
      title: strings.videosTitle,
      searchHint: strings.searchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      child: ref.watch(videosProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(videosProvider),
        ),
        data: (rawItems) {
          final seen = <String>{};
          final items = [
            for (final item in rawItems)
              if (seen.add(item.id)) item,
          ];
          final filtered = items.where((item) {
            final text = '${item.title.resolve(language)} ${item.description.resolve(language)}';
            return text.contains(_query);
          }).toList();
          final featured = filtered.where((item) => item.featured).toList();
          final featuredIds = {for (final item in featured) item.id};
          final rest = filtered.where((item) => !featuredIds.contains(item.id)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              if (featured.isNotEmpty) ...[
                Text(
                  strings.featured,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                ...featured.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _VideoCard(item: item),
                  ),
                ),
                if (rest.isNotEmpty) ...[
                  Text(
                    strings.recent,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.navy),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              if (filtered.isEmpty) StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
              ...rest.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _VideoCard(item: item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VideoCard extends ConsumerWidget {
  const _VideoCard({required this.item});
  final VideoItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final thumb = VideoSource.thumbnailUrl(item.videoUrl, fallback: item.thumbnailUrl);
    final description = ScriptAwareText.kurdishOnly(item.description.resolve(language));
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/videos/${item.id}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 148,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: AppColors.navy),
                      if (thumb != null)
                        Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      const Center(
                        child: Icon(Icons.play_circle_fill_rounded, color: AppColors.goldSoft, size: 48),
                      ),
                      if (item.durationLabel.isNotEmpty)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.deepNavy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.durationLabel,
                              style: const TextStyle(color: AppColors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Text(
                  item.title.resolve(language),
                  style: AppTypography.contentStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    height: 1.45,
                  ),
                ),
              ),
              if (description.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.contentStyle(
                      fontSize: 13,
                      color: AppColors.navy,
                      height: 1.65,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoDetailScreen extends ConsumerWidget {
  const VideoDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    return ref.watch(videosProvider).when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF2F4F7),
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: StatusPanel(title: strings.errorTitle, body: strings.errorBody),
      ),
      data: (items) {
        final item = items.cast<VideoItem?>().firstWhere((entry) => entry?.id == id, orElse: () => null);
        if (item == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F4F7),
            body: StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
          );
        }
        final playUrl = VideoSource.youtubeId(item.videoUrl) != null || VideoSource.isDirectVideo(item.videoUrl)
            ? item.videoUrl
            : (VideoSource.youtubeId(item.thumbnailUrl) != null || VideoSource.isDirectVideo(item.thumbnailUrl)
                ? item.thumbnailUrl
                : item.videoUrl);
        return CatalogPageScaffold(
          title: item.title.resolve(language),
          meta: item.durationLabel.isNotEmpty ? item.durationLabel : null,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: RounahiVideoPlayer(
                    key: ValueKey(playUrl ?? item.id),
                    url: playUrl,
                    thumbnailUrl: item.thumbnailUrl,
                    watchOnYoutubeLabel: strings.watchOnYoutube,
                    unavailableLabel: strings.videoUnavailable,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ScriptAwareText(
                        item.description.resolve(language),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.75),
                      ),
                    ),
                    if (item.relatedIds.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(
                        strings.related,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 10),
                      ...item.relatedIds.map((relatedId) {
                        final related = items.cast<VideoItem?>().firstWhere(
                          (entry) => entry?.id == relatedId,
                          orElse: () => null,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CatalogListCard(
                            title: related?.title.resolve(language) ?? relatedId,
                            leading: const CatalogIconBadge(icon: Icons.play_circle_outline_rounded),
                            onTap: () => context.push('/videos/$relatedId'),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
