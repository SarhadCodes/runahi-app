import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pages = PageController();
  int _index = 0;
  late AppLanguage _language;
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _language = ref.read(settingsProvider).language;
  }

  @override
  void dispose() {
    _pages.dispose();
    _enter.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setLanguage(_language);
    await ref.read(localStoreProvider).setOnboardingComplete();
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    if (_index >= 3) {
      _finish();
      return;
    }
    _pages.animateToPage(
      _index + 1,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final last = _index == 3;
    final enter = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Atmosphere(),
          AnimatedBuilder(
            animation: _ambient,
            builder: (context, _) {
              final t = _ambient.value;
              return IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.15 + t * 0.2, -0.72 + t * 0.08),
                      radius: 1.05,
                      colors: [
                        AppColors.gold.withValues(alpha: 0.16 + t * 0.05),
                        AppColors.navySoft.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
          CustomPaint(
            painter: IslamicPatternPainter(opacity: 0.07, color: AppColors.goldSoft),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: enter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(enter),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                      child: Row(
                        children: [
                          if (_index != 0) ...[
                            const RounahiLogo(size: 36, borderRadius: 10),
                            const SizedBox(width: 10),
                            Text(
                              strings.appName,
                              style: AppTypography.contentStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldSoft,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (!last)
                            TextButton(
                              onPressed: _finish,
                              child: Text(
                                strings.onboardingSkip,
                                style: AppTypography.uiStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        onPageChanged: (value) => setState(() => _index = value),
                        children: [
                          _StoryPage(
                            title: strings.onboardingWelcomeTitle,
                            body: strings.onboardingWelcomeBody,
                            visual: _BrandVisual(brandName: strings.appName),
                          ),
                          _StoryPage(
                            title: strings.onboardingListenTitle,
                            body: strings.onboardingListenBody,
                            visual: const _ListenVisual(),
                          ),
                          _StoryPage(
                            title: strings.onboardingLearnTitle,
                            body: strings.onboardingLearnBody,
                            visual: const _LearnVisual(),
                          ),
                          _StoryPage(
                            title: strings.onboardingLangTitle,
                            body: strings.onboardingLangBody,
                            visual: _LanguageVisual(
                              selected: _language,
                              soraniHint: strings.onboardingSoraniHint,
                              badiniHint: strings.onboardingBadiniHint,
                              onSelected: (value) async {
                                setState(() => _language = value);
                                await ref.read(settingsProvider.notifier).setLanguage(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
                      child: Column(
                        children: [
                          _ProgressRail(index: _index, count: 4),
                          const SizedBox(height: 20),
                          _PrimaryCta(
                            label: last ? strings.onboardingStart : strings.onboardingNext,
                            onTap: _next,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF122D4A),
            AppColors.navy,
            AppColors.deepNavy,
            Color(0xFF040E18),
          ],
          stops: [0, 0.28, 0.72, 1],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.title,
    required this.body,
    required this.visual,
  });

  final String title;
  final String body;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          Expanded(flex: 6, child: Center(child: visual)),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.contentStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTypography.contentStyle(
                    fontSize: 15,
                    color: AppColors.goldSoft.withValues(alpha: 0.88),
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: i <= index
                    ? AppColors.gold
                    : AppColors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryCta extends StatefulWidget {
  const _PrimaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE6D7AE), AppColors.gold, AppColors.goldMuted],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: AppTypography.uiStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.deepNavy,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandVisual extends StatefulWidget {
  const _BrandVisual({required this.brandName});

  final String brandName;

  @override
  State<_BrandVisual> createState() => _BrandVisualState();
}

class _BrandVisualState extends State<_BrandVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(
          scale: 1 + t * 0.025,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 236,
            height: 236,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 236,
                  height: 236,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 1),
                  ),
                ),
                Container(
                  width: 204,
                  height: 204,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 1.4),
                  ),
                ),
                Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const RounahiLogo(size: 168, borderRadius: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            widget.brandName,
            textAlign: TextAlign.center,
            style: AppTypography.contentStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.goldSoft,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenVisual extends StatefulWidget {
  const _ListenVisual();

  @override
  State<_ListenVisual> createState() => _ListenVisualState();
}

class _ListenVisualState extends State<_ListenVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.medallion,
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: const Icon(Icons.headphones_rounded, color: AppColors.goldSoft, size: 30),
              ),
              const SizedBox(height: 20),
              QuranText('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', size: 22, color: AppColors.goldSoft),
              const SizedBox(height: 10),
              QuranText(
                'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
                size: 17,
                color: AppColors.white.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 18),
              AnimatedBuilder(
                animation: _wave,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Container(
                          width: 3.5,
                          height: 8 +
                              16 *
                                  (0.35 +
                                      0.65 *
                                          (0.5 +
                                              0.5 *
                                                  math.sin(
                                                    (_wave.value * math.pi * 2) + i * 0.7,
                                                  ))),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.4 + (i % 3) * 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnVisual extends StatefulWidget {
  const _LearnVisual();

  @override
  State<_LearnVisual> createState() => _LearnVisualState();
}

class _LearnVisualState extends State<_LearnVisual> with SingleTickerProviderStateMixin {
  static const _items = <IconData>[
    Icons.menu_book_rounded,
    Icons.headphones_rounded,
    Icons.translate_rounded,
    Icons.auto_stories_rounded,
    Icons.play_circle_fill_rounded,
    Icons.explore_rounded,
  ];

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 18000),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) {
          final turn = _spin.value * math.pi * 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
                ),
              ),
              for (var i = 0; i < _items.length; i++)
                Transform.translate(
                  offset: Offset(
                    96 * math.cos(turn + (i / _items.length) * math.pi * 2 - math.pi / 2),
                    96 * math.sin(turn + (i / _items.length) * math.pi * 2 - math.pi / 2),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navySoft.withValues(alpha: 0.9),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(_items[i], color: AppColors.goldSoft, size: 24),
                  ),
                ),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.medallion,
                  border: Border.all(color: AppColors.gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(Icons.brightness_5_rounded, color: AppColors.goldSoft, size: 42),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageVisual extends StatelessWidget {
  const _LanguageVisual({
    required this.selected,
    required this.soraniHint,
    required this.badiniHint,
    required this.onSelected,
  });

  final AppLanguage selected;
  final String soraniHint;
  final String badiniHint;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LangChoice(
            title: AppLanguage.sorani.nativeName,
            hint: soraniHint,
            selected: selected == AppLanguage.sorani,
            onTap: () => onSelected(AppLanguage.sorani),
          ),
          const SizedBox(height: 14),
          _LangChoice(
            title: AppLanguage.badini.nativeName,
            hint: badiniHint,
            selected: selected == AppLanguage.badini,
            onTap: () => onSelected(AppLanguage.badini),
          ),
        ],
      ),
    );
  }
}

class _LangChoice extends StatelessWidget {
  const _LangChoice({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.16)
                : AppColors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.white.withValues(alpha: 0.14),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.gold : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.gold : AppColors.white.withValues(alpha: 0.45),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 14, color: AppColors.deepNavy)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.contentStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: AppTypography.contentStyle(
                        fontSize: 13,
                        color: AppColors.goldSoft.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
