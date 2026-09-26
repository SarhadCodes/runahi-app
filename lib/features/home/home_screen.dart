import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/providers.dart';
import 'widgets/home_art.dart';
import 'widgets/radial_navigation_hub.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  static const route = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentSyncProvider).pull();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(contentSyncProvider).pull();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final unread = ref.watch(notificationFeedProvider).maybeWhen(
          data: (items) => items.where((item) => !item.read).length,
          orElse: () => ref.watch(inboxProvider).where((item) => !item.read).length,
        );
    final items = [
      RadialNavItem(
        id: 'books',
        label: strings.petalLabel('books'),
        icon: Icons.menu_book_rounded,
        route: '/books',
        dark: true,
      ),
      RadialNavItem(
        id: 'research',
        label: strings.petalLabel('research'),
        icon: Icons.search_rounded,
        route: '/research',
      ),
      RadialNavItem(
        id: 'verses',
        label: strings.petalLabel('verses'),
        icon: Icons.auto_stories_rounded,
        route: '/verses',
        dark: true,
      ),
      RadialNavItem(
        id: 'words',
        label: strings.petalLabel('words'),
        icon: Icons.translate_rounded,
        route: '/words',
      ),
      RadialNavItem(
        id: 'videos',
        label: strings.petalLabel('videos'),
        icon: Icons.play_circle_fill_rounded,
        route: '/videos',
        dark: true,
      ),
      RadialNavItem(
        id: 'questions',
        label: strings.petalLabel('questions'),
        icon: Icons.help_outline_rounded,
        route: '/questions',
      ),
      RadialNavItem(
        id: 'topics',
        label: strings.petalLabel('topics'),
        icon: Icons.view_list_rounded,
        route: '/topics',
        dark: true,
      ),
      RadialNavItem(
        id: 'qibla',
        label: strings.petalLabel('qibla'),
        icon: Icons.explore_rounded,
        route: '/qibla',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: Stack(
        children: [
          const SceneBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxHeight < 80 || constraints.maxWidth < 80) {
                  return const SizedBox.expand();
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: Row(
                        children: [
                          LanguageSwitcher(
                            soraniLabel: AppLanguage.sorani.nativeName,
                            badiniLabel: AppLanguage.badini.nativeName,
                            soraniSelected: language == AppLanguage.sorani,
                            onSorani: () => ref
                                .read(settingsProvider.notifier)
                                .setLanguage(AppLanguage.sorani),
                            onBadini: () => ref
                                .read(settingsProvider.notifier)
                                .setLanguage(AppLanguage.badini),
                            semanticLabel: strings.semanticLanguage,
                          ),
                          const Spacer(),
                          _RoundIconButton(
                            icon: unread > 0
                                ? Icons.notifications_rounded
                                : Icons.notifications_none_rounded,
                            tooltip: strings.semanticNotifications,
                            badge: unread > 0,
                            onTap: () => context.push('/notifications'),
                          ),
                        ],
                      ),
                    ),
                    MihrabHeader(
                      title: strings.appName,
                      subtitle: strings.homeTagline,
                    ),
                    Expanded(
                      child: RadialNavigationHub(
                        items: items,
                        selectedId: _selectedId,
                        onSelected: (item) async {
                          setState(() => _selectedId = item.id);
                          await Future<void>.delayed(
                            const Duration(milliseconds: 180),
                          );
                          if (!context.mounted) return;
                          context.push(item.route);
                          Future<void>.delayed(
                            const Duration(milliseconds: 400),
                            () {
                              if (mounted) setState(() => _selectedId = null);
                            },
                          );
                        },
                        center: _CenterVerse(
                          arabic: strings.quranCenterLabel,
                          icon: Icons.headphones_rounded,
                          onTap: () => context.push('/quran'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                      child: Text(
                        '“ ${strings.homeQuote} ”',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFamily,
                          fontSize: 11,
                          color: AppColors.navy.withValues(alpha: 0.7),
                          height: 1.3,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          HomeCircleButton(
                            icon: Icons.settings_outlined,
                            label: strings.navSettings,
                            onTap: () => context.push('/settings'),
                          ),
                          HomeCircleButton(
                            icon: Icons.live_tv_rounded,
                            label: strings.tvTitle,
                            onTap: () => context.push('/tv'),
                          ),
                          HomeCircleButton(
                            icon: Icons.bookmark_border_rounded,
                            label: strings.navBookmarks,
                            onTap: () => context.push('/bookmarks'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white,
        shape: const CircleBorder(),
        elevation: 1,
        shadowColor: AppColors.navy.withValues(alpha: 0.12),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, color: AppColors.navy),
                ),
                if (badge)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
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

class _CenterVerse extends StatelessWidget {
  const _CenterVerse({
    required this.arabic,
    required this.onTap,
    this.icon = Icons.nightlight_round,
  });

  final String arabic;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.goldSoft, size: 22),
          const SizedBox(height: 6),
          QuranText(arabic, size: 18, color: AppColors.white),
        ],
      ),
    );
  }
}
