import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imanikurd/imanikurd.dart' as iman;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rounahi/app.dart';
import 'package:rounahi/core/widgets/app_widgets.dart';
import 'package:rounahi/data/imanikurd_bootstrap.dart';
import 'package:rounahi/data/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  configureImaniKurd();

  test('web JSON numbers are coerced to ints for Imani Kurd', () {
    final decoded = decodeImaniJson('{"number":1.0,"ayahs":[{"ayah":7.0}]}') as Map<String, dynamic>;
    expect(decoded['number'], isA<int>());
    expect(decoded['number'], 1);
    expect((decoded['ayahs'] as List).first['ayah'], 7);
  });

  test('Imani Kurd loads Fatiha and Runahi tafsir', () async {
    final surah = await iman.getSurah(1);
    expect(surah, isNotNull);
    expect(surah!.numberOfAyahs, 7);
    final tafsir = await iman.getTafsirForAyah('runahi', 1, 1);
    expect(tafsir, isNotNull);
    expect(tafsir!, isNotEmpty);
  });

  testWidgets('Rounahi app boots to splash brand', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const RounahiApp(),
      ),
    );
    expect(find.byType(RounahiLogo), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    expect(find.byType(RounahiLogo), findsWidgets);
  });
}
