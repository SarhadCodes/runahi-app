import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/providers.dart';
import '../books/presentation/books_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final prefs = settings.notifications;
    final notifier = ref.read(settingsProvider.notifier);

    return CatalogPageScaffold(
      title: strings.settingsTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SettingsCard(
            child: Column(
              children: [
                const RounahiLogo(size: 96),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    strings.languageLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _LangChip(
                      label: AppLanguage.sorani.nativeName,
                      selected: settings.language == AppLanguage.sorani,
                      onTap: () => notifier.setLanguage(AppLanguage.sorani),
                    ),
                    const SizedBox(width: 8),
                    _LangChip(
                      label: AppLanguage.badini.nativeName,
                      selected: settings.language == AppLanguage.badini,
                      onTap: () => notifier.setLanguage(AppLanguage.badini),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _SectionLabel(strings.appearance),
          _SettingsCard(
            child: Column(
              children: [
                _FontSlider(
                  label: strings.fontSize,
                  value: settings.fontScale,
                  min: 0.9,
                  max: 1.4,
                  divisions: 5,
                  preview: Text(
                    strings.appName,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFamily,
                      fontSize: 17 * settings.fontScale,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  onChanged: notifier.setFontScale,
                ),
                const SizedBox(height: 8),
                _FontSlider(
                  label: strings.quranFontSize,
                  value: settings.quranFontScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  preview: QuranText(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    size: 20,
                    scale: settings.quranFontScale,
                  ),
                  onChanged: notifier.setQuranFontScale,
                ),
              ],
            ),
          ),
          _SectionLabel(strings.notifications),
          _SettingsCard(
            child: Column(
              children: [
                _GroupCaption(strings.settingsNewContent),
                _ToggleRow(
                  icon: Icons.menu_book_rounded,
                  label: strings.notifNewBooks,
                  value: prefs.books,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(books: value)),
                ),
                _ToggleRow(
                  icon: Icons.search_rounded,
                  label: strings.notifNewResearch,
                  value: prefs.research,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(research: value)),
                ),
                _ToggleRow(
                  icon: Icons.auto_stories_rounded,
                  label: strings.notifNewVerses,
                  value: prefs.verses,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(verses: value)),
                ),
                _ToggleRow(
                  icon: Icons.translate_rounded,
                  label: strings.notifNewWords,
                  value: prefs.words,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(words: value)),
                ),
                _ToggleRow(
                  icon: Icons.play_circle_fill_rounded,
                  label: strings.notifNewVideos,
                  value: prefs.videos,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(videos: value)),
                ),
                _ToggleRow(
                  icon: Icons.help_outline_rounded,
                  label: strings.notifNewQuestions,
                  value: prefs.questions,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(questions: value)),
                ),
                _ToggleRow(
                  icon: Icons.view_list_rounded,
                  label: strings.notifNewTopics,
                  value: prefs.topics,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(topics: value)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _GroupCaption(strings.settingsDailyAlerts),
                _ToggleRow(
                  icon: Icons.wb_sunny_rounded,
                  label: strings.notifDailyAyah,
                  value: prefs.dailyAyah,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(dailyAyah: value)),
                ),
                _ToggleRow(
                  icon: Icons.spa_rounded,
                  label: strings.notifWordOfDay,
                  value: prefs.wordOfDay,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(wordOfDay: value)),
                ),
                _ToggleRow(
                  icon: Icons.auto_awesome_rounded,
                  label: strings.notifTopicOfDay,
                  value: prefs.topicOfDay,
                  onChanged: (value) => notifier.setNotifications(prefs.copyWith(topicOfDay: value)),
                ),
              ],
            ),
          ),
          _SectionLabel(strings.audioSettings),
          _SettingsCard(
            child: Consumer(
              builder: (context, ref, _) {
                final readerPrefs = ref.watch(readerPreferencesProvider);
                return _ToggleRow(
                  icon: Icons.menu_book_rounded,
                  label: strings.pageSound,
                  value: readerPrefs.pageSound,
                  onChanged: (value) => ref
                      .read(readerPreferencesProvider.notifier)
                      .update(readerPrefs.copyWith(pageSound: value)),
                );
              },
            ),
          ),
          _SectionLabel(strings.settingsMore),
          _SettingsCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LinkRow(
                  icon: Icons.headphones_rounded,
                  title: strings.audioSettings,
                  onTap: () => context.push('/quran'),
                ),
                _LinkRow(
                  icon: Icons.explore_rounded,
                  title: strings.qiblaTitle,
                  onTap: () => context.push('/qibla'),
                ),
                _LinkRow(
                  icon: Icons.shield_outlined,
                  title: strings.privacy,
                  onTap: () => context.push('/privacy'),
                ),
                _LinkRow(
                  icon: Icons.info_outline_rounded,
                  title: strings.about,
                  onTap: () => context.push('/about'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '${strings.version} ${AppConstants.version}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.navy.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
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
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.navy : AppColors.lightBlue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.navy.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.uiFamily,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.goldSoft : AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 22, 6, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.uiFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class _GroupCaption extends StatelessWidget {
  const _GroupCaption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTypography.uiFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.navy.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _FontSlider extends StatelessWidget {
  const _FontSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.preview,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Widget preview;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.uiFamily,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}٪',
              style: const TextStyle(
                fontFamily: AppTypography.uiFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.goldMuted,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.navy,
            inactiveTrackColor: AppColors.mist,
            thumbColor: AppColors.gold,
            overlayColor: AppColors.gold.withValues(alpha: 0.16),
            trackHeight: 3.5,
          ),
          child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: preview),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.uiFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.navy,
            activeThumbColor: AppColors.goldSoft,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.goldSoft, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.uiFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.navy.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

