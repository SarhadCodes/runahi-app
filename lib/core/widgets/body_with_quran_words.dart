import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/content_models.dart';
import '../../data/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// - `((عربي))` = Quran word (markers hidden, styled, tappable when found)
/// - `(text)` = normal parentheses, left visible as written
class BodyWithQuranWords extends ConsumerWidget {
  const BodyWithQuranWords(this.data, {super.key, this.style});

  final String data;
  final TextStyle? style;

  static final _quranMarker = RegExp(r'\(\(([^()\n]+)\)\)');

  QuranWord? _matchWord(List<QuranWord> words, String token) {
    final needle = token.trim();
    if (needle.isEmpty) return null;
    for (final word in words) {
      if (word.arabic == needle || word.normalized == needle || word.root == needle) {
        return word;
      }
    }
    final stripped = needle.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    for (final word in words) {
      final arabic = word.arabic.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
      if (arabic == stripped || word.normalized == stripped) return word;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.85,
              fontFamily: AppTypography.uiFamily,
              fontFamilyFallback: const ['NotoNaskhArabic'],
              color: AppColors.textPrimary,
            ) ??
        const TextStyle(height: 1.85);
    final quranWord = base.copyWith(
      color: AppColors.navy,
      fontFamily: AppTypography.quranFamily,
      fontSize: (base.fontSize ?? 16) + 2,
      height: 1.7,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.gold.withValues(alpha: 0.7),
      decorationThickness: 1.2,
      backgroundColor: null,
    );

    final words = ref.watch(wordsProvider).maybeWhen(data: (items) => items, orElse: () => const <QuranWord>[]);
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _quranMarker.allMatches(data)) {
      if (match.start > start) {
        spans.add(TextSpan(text: data.substring(start, match.start)));
      }
      final token = match.group(1)?.trim() ?? '';
      if (token.isEmpty) {
        start = match.end;
        continue;
      }
      final matched = _matchWord(words, token);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: matched == null ? null : () => context.push('/words/${matched.id}'),
            child: Text(token, style: quranWord, textDirection: TextDirection.rtl),
          ),
        ),
      );
      start = match.end;
    }
    if (start < data.length) {
      spans.add(TextSpan(text: data.substring(start)));
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }
}
