import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/quran_cloud_api.dart';
import '../../data/models/quran_listen_models.dart';

final quranCloudApiProvider = Provider<QuranCloudApi>((ref) => QuranCloudApi());

final quranSurahsProvider = FutureProvider<List<QuranSurahInfo>>((ref) {
  return ref.watch(quranCloudApiProvider).fetchSurahs();
});

final quranSurahAudioProvider = FutureProvider.family<QuranSurahAudio, (int, String)>((
  ref,
  key,
) {
  return ref.watch(quranCloudApiProvider).fetchSurah(number: key.$1, reciterId: key.$2);
});
