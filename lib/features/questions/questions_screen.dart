import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/body_with_quran_words.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/content_models.dart';
import '../../data/providers.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({super.key});

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  String _query = '';
  String _categoryId = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final config = ref.watch(configProvider).valueOrNull;

    return CatalogPageScaffold(
      title: strings.questionsTitle,
      searchHint: strings.searchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      child: ref.watch(questionsProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(questionsProvider),
        ),
        data: (items) {
          final categoryLabels = <String>{
            for (final item in items)
              if (item.category.resolve(language).trim().isNotEmpty) item.category.resolve(language),
          }.toList();
          final chipLabels = [strings.all, ...categoryLabels];
          final selectedLabel = _categoryId.isEmpty
              ? strings.all
              : categoryLabels.contains(_categoryId)
                  ? _categoryId
                  : strings.all;

          final filtered = items.where((item) {
            final category = item.category.resolve(language);
            final matchesCategory = selectedLabel == strings.all || category == selectedLabel;
            final hay =
                '${item.question.resolve(language)} ${item.answer.resolve(language)} $category';
            return matchesCategory && (_query.isEmpty || hay.contains(_query));
          }).toList();

          return Column(
            children: [
              if (chipLabels.length > 1) ...[
                const SizedBox(height: 10),
                CategoryChips(
                  items: chipLabels,
                  selected: selectedLabel,
                  onSelected: (value) => setState(() {
                    _categoryId = value == strings.all ? '' : value;
                  }),
                ),
              ],
              Expanded(
                child: filtered.isEmpty
                    ? StatusPanel(title: strings.emptyTitle, body: strings.emptyBody)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: filtered.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _AskQuietly(
                                title: strings.haveQuestion,
                                body: strings.contactViaWhatsApp,
                                buttonLabel: strings.contactWhatsApp,
                                onPressed: () async {
                                  final ok = config != null &&
                                      await const WhatsAppLauncher().open(config, language);
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(strings.whatsAppUnavailable)),
                                    );
                                  }
                                },
                              ),
                            );
                          }
                          final item = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QuestionRow(
                              question: item.question.resolve(language),
                              category: item.category.resolve(language),
                              index: index + 1,
                              onTap: () => context.push('/questions/${item.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.question,
    required this.category,
    required this.index,
    required this.onTap,
  });

  final String question;
  final String category;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.goldMuted,
                    borderRadius: BorderRadiusDirectional.horizontal(
                      start: const Radius.circular(16),
                    ).resolve(Directionality.of(context)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category.trim().isNotEmpty)
                          Text(
                            category,
                            style: const TextStyle(
                              fontFamily: AppTypography.uiFamily,
                              color: AppColors.goldMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        if (category.trim().isNotEmpty) const SizedBox(height: 6),
                        Text(
                          question,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: AppTypography.uiFamily,
                            color: AppColors.navy,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFamily,
                        color: AppColors.navy.withValues(alpha: 0.28),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AskQuietly extends StatelessWidget {
  const _AskQuietly({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldSoft.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.uiFamily,
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.uiFamily,
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const WhatsAppLogo(size: 22),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: AppTypography.uiFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final scale = ref.watch(settingsProvider).fontScale;

    return ref.watch(questionsProvider).when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF7F1E6),
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: const Color(0xFFF7F1E6),
        body: StatusPanel(title: strings.errorTitle, body: strings.errorBody),
      ),
      data: (items) {
        final item = items.cast<QuestionItem?>().firstWhere((entry) => entry?.id == id, orElse: () => null);
        if (item == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F1E6),
            body: StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
          );
        }

        final question = item.question.resolve(language);
        final answer = item.answer.resolve(language);
        final answerLabel = strings.answerLabel;
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
          title: strings.questionsTitle,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
            children: [
              Text(
                question,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTypography.uiFamily,
                  color: AppColors.navy,
                  fontSize: 22 * scale.clamp(0.9, 1.35),
                  fontWeight: FontWeight.w700,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 56,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.goldMuted.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                answerLabel,
                style: const TextStyle(
                  fontFamily: AppTypography.uiFamily,
                  color: AppColors.goldMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              if (answer.trim().isNotEmpty)
                BodyWithQuranWords(
                  answer,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFamily,
                    color: AppColors.navy,
                    fontSize: 16.5 * scale.clamp(0.9, 1.35),
                    fontWeight: FontWeight.w500,
                    height: 1.95,
                  ),
                ),
              if (hasVideo) ...[
                const SizedBox(height: 28),
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
