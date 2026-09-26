import 'package:dio/dio.dart';
import 'package:imanikurd/imanikurd.dart' as iman;

import '../../models/quran_listen_models.dart';

class QuranCloudApi {
  QuranCloudApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _surahEndpoint = 'https://api.alquran.cloud/v1/surah';

  int _asInt(dynamic value) => (value as num).toInt();

  Future<List<int>> _globalStartsFrom(List<QuranSurahInfo> surahs) {
    final starts = List<int>.filled(115, 1);
    var running = 1;
    for (final surah in surahs) {
      starts[surah.number] = running;
      running += surah.ayahCount;
    }
    return Future.value(starts);
  }

  Future<List<QuranSurahInfo>> fetchSurahs() async {
    try {
      return await _fetchSurahsFromImani();
    } catch (_) {
      return _fetchSurahsFromCloud();
    }
  }

  Future<List<QuranSurahInfo>> _fetchSurahsFromImani() async {
    final surahs = await iman.getSurahs();
    if (surahs.isEmpty) {
      throw StateError('imanikurd returned no surahs');
    }
    return [
      for (final surah in surahs)
        QuranSurahInfo(
          number: surah.number,
          nameArabic: surah.name,
          englishName: surah.kurdishName ?? surah.englishName,
          ayahCount: surah.numberOfAyahs,
          meccan: surah.revelationType.toLowerCase().contains('mecc'),
        ),
    ];
  }

  Future<List<QuranSurahInfo>> _fetchSurahsFromCloud() async {
    final response = await _dio.get<Map<String, dynamic>>(_surahEndpoint);
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return [
      for (final item in data)
        QuranSurahInfo(
          number: _asInt(item['number']),
          nameArabic: item['name'] as String? ?? '',
          englishName: item['englishName'] as String? ?? '',
          ayahCount: _asInt(item['numberOfAyahs']),
          meccan: (item['revelationType'] as String? ?? '').toLowerCase().contains('mecc'),
        ),
    ];
  }

  Future<QuranSurahAudio> fetchSurah({
    required int number,
    required String reciterId,
  }) async {
    try {
      return await _fetchSurahFromImani(number: number, reciterId: reciterId);
    } catch (_) {
      return _fetchSurahFromCloud(number: number, reciterId: reciterId);
    }
  }

  Future<QuranSurahAudio> _fetchSurahFromImani({
    required int number,
    required String reciterId,
  }) async {
    final reciter = QuranReciter.byId(reciterId);
    final surah = await iman.getSurah(number);
    final ayahs = await iman.getSurahAyahs(number);
    if (ayahs.isEmpty) {
      throw StateError('imanikurd returned no ayahs for surah $number');
    }
    final catalog = await fetchSurahs();
    final starts = await _globalStartsFrom(catalog);
    return QuranSurahAudio(
      info: QuranSurahInfo(
        number: number,
        nameArabic: surah?.name ?? '',
        englishName: surah?.kurdishName ?? surah?.englishName ?? '',
        ayahCount: surah?.numberOfAyahs ?? ayahs.length,
        meccan: (surah?.revelationType ?? '').toLowerCase().contains('mecc'),
      ),
      reciter: reciter,
      ayahs: [
        for (final ayah in ayahs)
          QuranAyahAudio(
            globalNumber: starts[ayah.surah] + ayah.ayah - 1,
            numberInSurah: ayah.ayah,
            text: ayah.text.replaceAll('\uFEFF', ''),
            audioUrl: reciter.audioUrl(
              globalNumber: starts[ayah.surah] + ayah.ayah - 1,
              surahNumber: number,
            ),
          ),
      ],
    );
  }

  Future<QuranSurahAudio> _fetchSurahFromCloud({
    required int number,
    required String reciterId,
  }) async {
    final reciter = QuranReciter.byId(reciterId);
    final response = await _dio.get<Map<String, dynamic>>('$_surahEndpoint/$number');
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('AlQuran Cloud returned no surah $number');
    }
    final ayahs = data['ayahs'] as List<dynamic>? ?? const [];
    final catalog = await fetchSurahs();
    final starts = await _globalStartsFrom(catalog);
    return QuranSurahAudio(
      info: QuranSurahInfo(
        number: number,
        nameArabic: data['name'] as String? ?? '',
        englishName: data['englishName'] as String? ?? '',
        ayahCount: _asInt(data['numberOfAyahs'] ?? ayahs.length),
        meccan: (data['revelationType'] as String? ?? '').toLowerCase().contains('mecc'),
      ),
      reciter: reciter,
      ayahs: [
        for (final ayah in ayahs)
          QuranAyahAudio(
            globalNumber: _asInt(ayah['number']),
            numberInSurah: _asInt(ayah['numberInSurah']),
            text: (ayah['text'] as String? ?? '').replaceAll('\uFEFF', ''),
            audioUrl: reciter.audioUrl(
              globalNumber: starts[number] + _asInt(ayah['numberInSurah']) - 1,
              surahNumber: number,
            ),
          ),
      ],
    );
  }
}
