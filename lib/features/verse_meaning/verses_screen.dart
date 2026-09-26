import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/body_with_quran_words.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/quran_listen_models.dart';
import '../../data/providers.dart';
import '../quran_listen/quran_providers.dart';

class VersesScreen extends ConsumerStatefulWidget {
  const VersesScreen({super.key});
  @override
  ConsumerState<VersesScreen> createState() => _VersesScreenState();
}

class _VersesScreenState extends ConsumerState<VersesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    return CatalogPageScaffold(
      title: strings.versesTitle,
      searchHint: strings.searchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      child: ref.watch(quranSurahsProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(quranSurahsProvider),
        ),
        data: (items) {
          final filtered = items.where((surah) {
            final haystack = '${surah.number} ${surah.nameArabic} ${surah.englishName}';
            return haystack.contains(_query);
          }).toList();
          if (filtered.isEmpty) {
            return StatusPanel(title: strings.emptyTitle, body: strings.emptyBody);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final surah = filtered[index];
              return CatalogListCard(
                title: surah.nameArabic,
                titleWidget: QuranText(surah.nameArabic, size: 24, textAlign: TextAlign.start),
                footer: strings.quranAyahCount(surah.ayahCount),
                leading: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    arabicDigits(surah.number),
                    style: const TextStyle(color: AppColors.goldSoft, fontWeight: FontWeight.w700),
                  ),
                ),
                onTap: () => context.push('/verses/${surah.number}'),
              );
            },
          );
        },
      ),
    );
  }
}

class SurahTafsirScreen extends ConsumerStatefulWidget {
  const SurahTafsirScreen({super.key, required this.surahNumber});
  final int surahNumber;

  @override
  ConsumerState<SurahTafsirScreen> createState() => _SurahTafsirScreenState();
}

class _SurahTafsirScreenState extends ConsumerState<SurahTafsirScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final surahs = ref.watch(quranSurahsProvider).valueOrNull ?? const <QuranSurahInfo>[];
    QuranSurahInfo? surahInfo;
    for (final item in surahs) {
      if (item.number == widget.surahNumber) {
        surahInfo = item;
        break;
      }
    }

    return ref.watch(surahVersesProvider(widget.surahNumber)).when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF2F4F7),
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(surahVersesProvider(widget.surahNumber)),
        ),
      ),
      data: (items) {
        final nameArabic = surahInfo?.nameArabic ??
            (items.isEmpty ? strings.versesTitle : items.first.surahNameArabic);
        final ayahCount = surahInfo?.ayahCount ?? items.length;
        final filtered = items.where((verse) {
          final kurdish = ScriptAwareText.kurdishOnly(verse.translation.resolve(language));
          return verse.arabic.contains(_query) ||
              kurdish.contains(_query) ||
              '${verse.ayahNumber}'.contains(_query);
        }).toList()
          ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F7),
          body: Column(
            children: [
              CatalogHeroHeader(
                title: nameArabic,
                useQuranTitle: true,
                meta: '${strings.surah} ${arabicDigits(widget.surahNumber)}  ·  ${strings.quranAyahCount(ayahCount)}',
                searchHint: strings.searchHint,
                onQueryChanged: (value) => setState(() => _query = value),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? StatusPanel(title: strings.emptyTitle, body: strings.emptyBody)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final verse = filtered[index];
                          final bookmarkKey = 'verse:${verse.id}';
                          final kurdish = ScriptAwareText.kurdishOnly(verse.translation.resolve(language));
                          final shareText = '${verse.arabic}\n$kurdish';
                          return _VerseDesignCard(
                            ayahNumber: verse.ayahNumber,
                            arabic: verse.arabic,
                            kurdish: kurdish,
                            bookmarked: bookmarks.contains(bookmarkKey),
                            onOpen: () => context.push('/verses/${verse.id}'),
                            onPlay: () => context.push(
                              '/quran/${verse.surahNumber}/play?from=${verse.ayahNumber}&to=${verse.ayahNumber}',
                            ),
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: shareText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(strings.copied)),
                              );
                            },
                            onShare: () => Share.share(shareText),
                            onBookmark: () => ref.read(bookmarksProvider.notifier).toggle(bookmarkKey),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VerseDesignCard extends StatelessWidget {
  const _VerseDesignCard({
    required this.ayahNumber,
    required this.arabic,
    required this.kurdish,
    required this.bookmarked,
    required this.onOpen,
    required this.onPlay,
    required this.onCopy,
    required this.onShare,
    required this.onBookmark,
  });

  final int ayahNumber;
  final String arabic;
  final String kurdish;
  final bool bookmarked;
  final VoidCallback onOpen;
  final VoidCallback onPlay;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: QuranText(arabic, size: 26, textAlign: TextAlign.right),
                    ),
                    const SizedBox(width: 12),
                    _AyahNumberBadge(number: ayahNumber),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    _VerseAction(icon: Icons.play_circle_outline_rounded, onTap: onPlay),
                    _VerseAction(icon: Icons.copy_rounded, onTap: onCopy),
                    _VerseAction(icon: Icons.share_outlined, onTap: onShare),
                    const Spacer(),
                    _VerseAction(
                      icon: bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      onTap: onBookmark,
                    ),
                  ],
                ),
              ),
              if (kurdish.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Text(
                    kurdish,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.navy,
                      height: 1.75,
                      fontFamily: AppTypography.uiFamily,
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

class _AyahNumberBadge extends StatelessWidget {
  const _AyahNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: CustomPaint(
        painter: const _OrnateBadgePainter(),
        child: Center(
          child: Text(
            arabicDigits(number),
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrnateBadgePainter extends CustomPainter {
  const _OrnateBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width / 2 - 1, fill);
    canvas.drawCircle(center, size.width / 2 - 2, gold);
    canvas.drawCircle(center, size.width / 2 - 6, gold);
    canvas.drawCircle(center, size.width / 2 - 9, gold);
    for (var i = 0; i < 8; i++) {
      final angle = (math.pi / 4) * i;
      final outer = Offset(
        center.dx + (size.width / 2 - 4) * math.cos(angle),
        center.dy + (size.height / 2 - 4) * math.sin(angle),
      );
      canvas.drawCircle(outer, 1.4, gold);
    }
    canvas.drawCircle(center, size.width / 2 - 12, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VerseAction extends StatelessWidget {
  const _VerseAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: AppColors.navy, size: 22),
    );
  }
}

class VerseDetailScreen extends ConsumerWidget {
  const VerseDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final scale = ref.watch(settingsProvider).quranFontScale;
    final bookmarks = ref.watch(bookmarksProvider);
    return ref.watch(verseProvider(id)).when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.navy))),
      error: (_, _) => Scaffold(body: StatusPanel(title: strings.errorTitle, body: strings.errorBody)),
      data: (verse) {
        if (verse == null) return Scaffold(body: StatusPanel(title: strings.emptyTitle, body: strings.emptyBody));
        final key = 'verse:${verse.id}';
        final translation = verse.translation.resolve(language).trim();
        final shareText = translation.isEmpty ? verse.arabic : '${verse.arabic}\n$translation';
        return CatalogPageScaffold(
          title: '${strings.surah} ${verse.surahName.resolve(language)}',
          useQuranTitle: false,
          headerActions: [
            CatalogHeaderIconButton(
              icon: Icons.text_decrease,
              onTap: () => ref.read(settingsProvider.notifier).setQuranFontScale((scale - 0.1).clamp(0.8, 1.6)),
            ),
            const SizedBox(width: 4),
            CatalogHeaderIconButton(
              icon: Icons.text_increase,
              onTap: () => ref.read(settingsProvider.notifier).setQuranFontScale((scale + 0.1).clamp(0.8, 1.6)),
            ),
            const SizedBox(width: 4),
            CatalogHeaderIconButton(
              icon: bookmarks.contains(key) ? Icons.bookmark : Icons.bookmark_border,
              onTap: () => ref.read(bookmarksProvider.notifier).toggle(key),
            ),
            const SizedBox(width: 4),
          ],
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.navy.withValues(alpha: 0.14)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                  child: QuranText(verse.arabic, size: 30, scale: scale),
                ),
              ),
              if (translation.isNotEmpty) ...[
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
                        strings.translation,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BodyWithQuranWords(
                        translation,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.85,
                          fontFamily: AppTypography.uiFamily,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareText));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.copied)));
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(strings.copy),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Share.share(shareText),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(strings.share),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/quran/${verse.surahNumber}/play?from=${verse.ayahNumber}&to=${verse.ayahNumber}',
                    ),
                    icon: const Icon(Icons.volume_up_outlined),
                    label: Text(strings.playAudio),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/words'),
                    icon: const Icon(Icons.translate_rounded),
                    label: Text(strings.navWords),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
