import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String uiFamily = 'Rudaw';
  static const String displayFamily = 'Amiri';
  static const String quranFamily = 'AmiriQuran';
  static const String latinFamily = 'Roboto';

  /// Rudaw is Kurdish-first; keep Latin + Arabic coverage without Google Fonts CDN.
  static const List<String> uiFallbacks = ['Roboto', 'NotoNaskhArabic', 'Amiri', 'Noto Sans Arabic'];

  /// On Flutter web, Rudaw often ships empty Latin slots that block fallback.
  /// Prefer Roboto (real Latin) with Rudaw/Naskh for Kurdish/Arabic.
  static String get effectiveUiFamily => kIsWeb ? latinFamily : uiFamily;

  static List<String> get effectiveUiFallbacks =>
      kIsWeb ? const ['Rudaw', 'NotoNaskhArabic', 'Amiri', 'Noto Sans Arabic'] : uiFallbacks;

  /// CMS titles/names — Roboto for Latin, then Rudaw/Naskh for Kurdish/Arabic.
  static const List<String> mixedFallbacks = ['Rudaw', 'NotoNaskhArabic', 'Amiri', 'Noto Sans Arabic'];

  static TextStyle uiStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double height = 1.7,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: effectiveUiFamily,
      fontFamilyFallback: effectiveUiFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Book/video/CMS titles — Latin + Kurdish must both paint on Flutter web.
  static TextStyle contentStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double height = 1.7,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: latinFamily,
      fontFamilyFallback: mixedFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme({double scale = 1}) {
    TextStyle ui({
      double size = 16,
      FontWeight weight = FontWeight.w400,
      Color color = AppColors.textPrimary,
      double height = 1.7,
      double letterSpacing = 0,
    }) {
      return uiStyle(
        fontSize: size * scale,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    return TextTheme(
      displayLarge: ui(size: 40, weight: FontWeight.w700, height: 1.4),
      displayMedium: ui(size: 34, weight: FontWeight.w700, height: 1.35),
      headlineLarge: ui(size: 28, weight: FontWeight.w700, height: 1.45),
      headlineMedium: ui(size: 22, weight: FontWeight.w700, height: 1.45),
      titleLarge: ui(size: 20, weight: FontWeight.w700),
      titleMedium: ui(size: 17, weight: FontWeight.w600),
      titleSmall: ui(size: 15, weight: FontWeight.w600),
      bodyLarge: ui(size: 16),
      bodyMedium: ui(size: 15, color: AppColors.textSecondary),
      bodySmall: ui(size: 13, color: AppColors.textSecondary, height: 1.65),
      labelLarge: ui(size: 14, weight: FontWeight.w600),
      labelMedium: ui(size: 12, weight: FontWeight.w600, color: AppColors.textSecondary),
    );
  }

  static TextStyle quran({double size = 28, double scale = 1, Color color = AppColors.navy}) {
    return TextStyle(
      fontFamily: quranFamily,
      fontFamilyFallback: const ['Amiri', 'NotoNaskhArabic'],
      fontSize: size * scale,
      fontWeight: FontWeight.w400,
      color: color,
      height: 2.05,
      letterSpacing: 0.2,
    );
  }

  static TextStyle arabicBody({double size = 20, double scale = 1, Color color = AppColors.navy}) {
    return TextStyle(
      fontFamily: quranFamily,
      fontFamilyFallback: const ['Amiri', 'NotoNaskhArabic'],
      fontSize: size * scale,
      fontWeight: FontWeight.w400,
      color: color,
      height: 2.0,
      letterSpacing: 0.15,
    );
  }
}

/// Pure Arabic Quran/Hadith text — never uses Rudaw or UI text scale.
class QuranText extends StatelessWidget {
  const QuranText(
    this.data, {
    super.key,
    this.size = 28,
    this.scale = 1,
    this.color = AppColors.navy,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final double size;
  final double scale;
  final Color color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Text(
        data,
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
        maxLines: maxLines,
        overflow: overflow,
        style: AppTypography.quran(size: size, scale: scale, color: color),
      ),
    );
  }
}

/// Mixed Kurdish/Arabic body text. Arabic scripture (tashkeel) uses AmiriQuran;
/// Kurdish and UI copy stay on Rudaw.
class ScriptAwareText extends StatelessWidget {
  const ScriptAwareText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.arabicSize = 20,
    this.arabicScale = 1,
    this.arabicColor = AppColors.navy,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double arabicSize;
  final double arabicScale;
  final Color arabicColor;

  static final RegExp _arabicLetter = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  static final RegExp _tashkeel = RegExp(r'[\u064B-\u065F\u0670ﷺ]');
  static final RegExp _kurdishMarker = RegExp(r'[ەڕڤڵۆێ]');
  static final RegExp _token = RegExp(r'\S+|\s+');

  /// Splits [text] into UI vs Arabic-scripture segments (word-based).
  static List<({String text, bool arabic})> segments(String text) {
    if (text.isEmpty) return const [];
    final out = <({String text, bool arabic})>[];
    for (final match in _token.allMatches(text)) {
      final chunk = match.group(0)!;
      final trimmed = chunk.trim();
      final arabic = trimmed.isNotEmpty &&
          _arabicLetter.hasMatch(trimmed) &&
          _tashkeel.hasMatch(trimmed);
      if (out.isNotEmpty && out.last.arabic == arabic) {
        out[out.length - 1] = (text: '${out.last.text}$chunk', arabic: arabic);
      } else {
        out.add((text: chunk, arabic: arabic));
      }
    }
    return _coalesceArabicFillers(out);
  }

  /// Keeps classical Arabic fillers (e.g. صلى الله عليه وسلم) with scripture,
  /// but leaves Kurdish (ە ڕ ێ …) on the UI side.
  static List<({String text, bool arabic})> _coalesceArabicFillers(
    List<({String text, bool arabic})> parts,
  ) {
    if (parts.isEmpty) return parts;
    final flags = [for (final part in parts) part.arabic];

    bool canPromote(int i) {
      final trimmed = parts[i].text.trim();
      if (trimmed.isEmpty) return false;
      if (_kurdishMarker.hasMatch(trimmed)) return false;
      return _arabicLetter.hasMatch(trimmed);
    }

    var changed = true;
    while (changed) {
      changed = false;
      for (var i = 0; i < parts.length; i++) {
        if (flags[i] || !canPromote(i)) continue;
        final prevArabic = i > 0 && flags[i - 1];
        final nextArabic = i + 1 < parts.length && flags[i + 1];
        if (prevArabic || nextArabic) {
          flags[i] = true;
          changed = true;
        }
      }
    }

    final merged = <({String text, bool arabic})>[];
    for (var i = 0; i < parts.length; i++) {
      final part = (text: parts[i].text, arabic: flags[i]);
      if (merged.isNotEmpty && merged.last.arabic == part.arabic) {
        merged[merged.length - 1] = (text: '${merged.last.text}${part.text}', arabic: part.arabic);
      } else {
        merged.add(part);
      }
    }
    return merged;
  }

  /// Merged blocks for layout (Arabic in a card, Kurdish outside).
  static List<({String text, bool arabic})> blocks(String text) {
    return [
      for (final part in segments(text))
        if (part.text.trim().isNotEmpty) (text: part.text.trim(), arabic: part.arabic),
    ];
  }

  static String kurdishOnly(String text) {
    final parts = blocks(text).where((part) => !part.arabic).map((part) => part.text.trim());
    return parts.where((part) => part.isNotEmpty).join('\n\n');
  }

  static String arabicOnly(String text) {
    final parts = blocks(text).where((part) => part.arabic).map((part) => part.text.trim());
    return parts.where((part) => part.isNotEmpty).join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final parts = segments(data);
    final hasArabic = parts.any((part) => part.arabic);
    if (!hasArabic) {
      return Text(data, style: base, textAlign: textAlign, textDirection: TextDirection.rtl);
    }

    final arabicStyle = AppTypography.arabicBody(
      size: arabicSize,
      scale: arabicScale,
      color: arabicColor,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Text.rich(
        TextSpan(
          children: [
            for (final part in parts)
              TextSpan(
                text: part.text,
                style: part.arabic
                    ? arabicStyle
                    : base.copyWith(
                        fontFamily: AppTypography.uiFamily,
                        fontFamilyFallback: const ['NotoNaskhArabic'],
                      ),
              ),
          ],
        ),
        textAlign: textAlign ?? TextAlign.start,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

/// Arabic scripture in its own card; Kurdish text always outside — never mixed.
class ScriptSplitBody extends StatelessWidget {
  const ScriptSplitBody(
    this.data, {
    super.key,
    this.style,
    this.arabicSize = 22,
    this.arabicScale = 1,
    this.arabicColor = AppColors.navy,
    this.hideEmbeddedArabic = false,
  });

  final String data;
  final TextStyle? style;
  final double arabicSize;
  final double arabicScale;
  final Color arabicColor;

  /// When true, only Kurdish is shown (use when Quran is already displayed above).
  final bool hideEmbeddedArabic;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.85) ??
        const TextStyle(height: 1.85);
    final parts = ScriptAwareText.blocks(data);
    if (parts.isEmpty) return const SizedBox.shrink();

    final arabicParts = [for (final part in parts) if (part.arabic) part.text];
    final kurdishParts = [for (final part in parts) if (!part.arabic) part.text];

    if (hideEmbeddedArabic || arabicParts.isEmpty) {
      final kurdish = kurdishParts.join('\n\n').trim();
      if (kurdish.isEmpty) return const SizedBox.shrink();
      return Text(
        kurdish,
        style: base.copyWith(
          fontFamily: AppTypography.uiFamily,
          fontFamilyFallback: const ['NotoNaskhArabic'],
        ),
        textDirection: TextDirection.rtl,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final arabic in arabicParts) ...[
          _ScriptureCard(
            text: arabic,
            size: arabicSize,
            scale: arabicScale,
            color: arabicColor,
          ),
          const SizedBox(height: 16),
        ],
        if (kurdishParts.isNotEmpty)
          Text(
            kurdishParts.join('\n\n').trim(),
            style: base.copyWith(
              fontFamily: AppTypography.uiFamily,
              fontFamilyFallback: const ['NotoNaskhArabic'],
            ),
            textDirection: TextDirection.rtl,
          ),
      ],
    );
  }
}

class _ScriptureCard extends StatelessWidget {
  const _ScriptureCard({
    required this.text,
    required this.size,
    required this.scale,
    required this.color,
  });

  final String text;
  final double size;
  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: Text(
            text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTypography.arabicBody(size: size, scale: scale, color: color),
          ),
        ),
      ),
    );
  }
}

class ContentSection extends StatelessWidget {
  const ContentSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
