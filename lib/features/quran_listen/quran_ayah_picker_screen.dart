import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/quran_listen_models.dart';
import '../../data/providers.dart';
import 'quran_providers.dart';

class QuranAyahPickerScreen extends ConsumerStatefulWidget {
  const QuranAyahPickerScreen({
    super.key,
    required this.surahNumber,
    this.reciterId = 'ar.alafasy',
  });

  final int surahNumber;
  final String reciterId;

  @override
  ConsumerState<QuranAyahPickerScreen> createState() => _QuranAyahPickerScreenState();
}

class _QuranAyahPickerScreenState extends ConsumerState<QuranAyahPickerScreen> {
  late String _reciterId = QuranReciter.catalog.any((item) => item.id == widget.reciterId)
      ? widget.reciterId
      : QuranReciter.catalog.first.id;
  final Set<int> _selected = {};

  void _play(List<QuranAyahAudio> ayahs) {
    final numbers = (_selected.isEmpty ? ayahs.map((item) => item.numberInSurah) : _selected.toList())
        .toList()
      ..sort();
    if (numbers.isEmpty) return;
    final contiguous = numbers.last - numbers.first + 1 == numbers.length;
    final reciter = Uri.encodeQueryComponent(_reciterId);
    if (contiguous) {
      context.push('/quran/${widget.surahNumber}/play?from=${numbers.first}&to=${numbers.last}&reciter=$reciter');
    } else {
      context.push('/quran/${widget.surahNumber}/play?ayahs=${numbers.join(',')}&reciter=$reciter');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final audio = ref.watch(quranSurahAudioProvider((widget.surahNumber, _reciterId)));

    return CatalogPageScaffold(
      title: strings.quranChooseAyahs,
      child: audio.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (_, _) => StatusPanel(
          title: strings.errorTitle,
          body: strings.quranListenError,
          actionLabel: strings.retry,
          onAction: () => ref.refresh(quranSurahAudioProvider((widget.surahNumber, _reciterId))),
        ),
        data: (surah) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QuranText(surah.info.nameArabic, size: 28),
                          const SizedBox(height: 10),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _reciterId,
                              items: [
                                for (final item in QuranReciter.catalog)
                                  DropdownMenuItem(
                                    value: item.id,
                                    child: QuranText(item.nameArabic, size: 18, textAlign: TextAlign.start),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _reciterId = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: Text(strings.quranPlayAll),
                                onPressed: () {
                                  setState(() {
                                    _selected
                                      ..clear()
                                      ..addAll(surah.ayahs.map((item) => item.numberInSurah));
                                  });
                                },
                              ),
                              ActionChip(
                                label: Text(strings.clear),
                                onPressed: () => setState(() => _selected.clear()),
                              ),
                              ActionChip(
                                label: Text(strings.quranFirstSeven),
                                onPressed: () {
                                  setState(() {
                                    _selected
                                      ..clear()
                                      ..addAll(
                                        List.generate(
                                          surah.ayahs.length.clamp(0, 7),
                                          (index) => index + 1,
                                        ),
                                      );
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: surah.ayahs.length,
                  itemBuilder: (context, index) {
                    final ayah = surah.ayahs[index];
                    final selected = _selected.contains(ayah.numberInSurah);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selected.remove(ayah.numberInSurah);
                              } else {
                                _selected.add(ayah.numberInSurah);
                              }
                            });
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: selected ? AppColors.lightBlue : AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.navy.withValues(alpha: 0.28)
                                    : AppColors.border,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: selected,
                                    activeColor: AppColors.navy,
                                    onChanged: (_) {
                                      setState(() {
                                        if (selected) {
                                          _selected.remove(ayah.numberInSurah);
                                        } else {
                                          _selected.add(ayah.numberInSurah);
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          '${strings.quranAyah} ${ayah.numberInSurah}',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            color: AppColors.navy,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        QuranText(ayah.text, size: 22, textAlign: TextAlign.right),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _play(surah.ayahs),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      _selected.isEmpty ? strings.quranPlayAll : strings.quranPlaySelected(_selected.length),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
