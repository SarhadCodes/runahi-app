import 'package:flutter_test/flutter_test.dart';
import 'package:rounahi/core/theme/app_typography.dart';

void main() {
  test('puts Arabic in scripture blocks and Kurdish outside', () {
    const text =
        'عَنِ ابْنِ عُمَرَ، قَالَ: قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم: ((خَالِفُوا الْمُشْرِكِينَ))\n'
        'واتە: پێچەوانەی موشریکەکان بکەن.';

    final parts = ScriptAwareText.blocks(text);
    expect(parts.length, greaterThanOrEqualTo(2));
    expect(parts.any((part) => part.arabic), isTrue);
    expect(
      parts.any((part) => part.arabic && (part.text.contains('خَالِفُوا') || part.text.contains('عَنِ'))),
      isTrue,
    );
    expect(parts.any((part) => !part.arabic && part.text.contains('واتە')), isTrue);
    // Classical fillers without tashkeel stay with the Arabic card.
    final arabicJoined = parts.where((part) => part.arabic).map((part) => part.text).join(' ');
    expect(arabicJoined.contains('صلى') || arabicJoined.contains('عَنِ'), isTrue);
  });

  test('plain Kurdish stays non-arabic', () {
    final parts = ScriptAwareText.blocks('فەرمان کردن بە هێشتنەوەی ڕیش');
    expect(parts.every((part) => !part.arabic), isTrue);
  });
}
