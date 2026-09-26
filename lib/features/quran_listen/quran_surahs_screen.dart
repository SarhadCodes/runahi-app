import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/quran_listen_models.dart';
import '../../data/providers.dart';
import 'quran_providers.dart';

class QuranSurahsScreen extends ConsumerStatefulWidget {
  const QuranSurahsScreen({super.key});

  @override
  ConsumerState<QuranSurahsScreen> createState() => _QuranSurahsScreenState();
}

class _QuranSurahsScreenState extends ConsumerState<QuranSurahsScreen> {
  String _query = '';
  String _reciterId = QuranReciter.catalog.first.id;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final surahs = ref.watch(quranSurahsProvider);
    final reciter = QuranReciter.byId(_reciterId);

    return CatalogPageScaffold(
      title: strings.quranListenTitle,
      searchHint: strings.quranSearchSurah,
      onQueryChanged: (value) => setState(() => _query = value),
      child: surahs.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.quranListenError,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(quranSurahsProvider),
        ),
        data: (items) {
          final filtered = items.where((surah) {
            final haystack = '${surah.number} ${surah.nameArabic} ${surah.englishName}';
            return haystack.toLowerCase().contains(_query.toLowerCase());
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _reciterId,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
                          items: [
                            for (final item in QuranReciter.catalog)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  item.nameArabic,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: AppTypography.uiFamily),
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _reciterId = value);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${strings.quranReciter}: ${reciter.nameArabic}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.navy),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? StatusPanel(title: strings.emptyTitle, body: strings.emptyBody)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final surah = filtered[index];
                          return CatalogListCard(
                            title: surah.nameArabic,
                            titleWidget: QuranText(surah.nameArabic, size: 24, textAlign: TextAlign.start),
                            footer:
                                '${strings.quranAyahCount(surah.ayahCount)} · ${surah.meccan ? strings.quranMeccan : strings.quranMedinan}',
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
                                style: const TextStyle(
                                  color: AppColors.goldSoft,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            trailing: const Icon(Icons.play_circle_fill_rounded, color: AppColors.navy),
                            onTap: () => context.push('/quran/${surah.number}?reciter=$_reciterId'),
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
