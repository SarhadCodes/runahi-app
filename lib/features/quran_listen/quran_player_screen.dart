import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/models/quran_listen_models.dart';
import '../../data/providers.dart';
import 'quran_providers.dart';

class QuranPlayerScreen extends ConsumerStatefulWidget {
  const QuranPlayerScreen({
    super.key,
    required this.surahNumber,
    required this.reciterId,
    this.fromAyah = 1,
    this.toAyah,
    this.ayahNumbers = const [],
  });

  final int surahNumber;
  final String reciterId;
  final int fromAyah;
  final int? toAyah;
  final List<int> ayahNumbers;

  @override
  ConsumerState<QuranPlayerScreen> createState() => _QuranPlayerScreenState();
}

class _QuranPlayerScreenState extends ConsumerState<QuranPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  int _index = 0;
  bool _ready = false;
  bool _loadingTrack = false;
  bool _ignoreComplete = false;
  String? _error;
  List<QuranAyahAudio> _playlist = const [];
  QuranSurahAudio? _surah;
  String _reciterName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    unawaited(_shutdownPlayer());
    super.dispose();
  }

  Future<void> _shutdownPlayer() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _player.dispose();
    } catch (_) {}
  }

  Future<void> _prepare() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      final surah = await ref.read(
        quranSurahAudioProvider((widget.surahNumber, widget.reciterId)).future,
      );
      final selected = widget.ayahNumbers.isNotEmpty
          ? widget.ayahNumbers
          : [
              for (var n = widget.fromAyah; n <= (widget.toAyah ?? surah.ayahs.length); n++) n,
            ];
      final playlist = surah.ayahs.where((ayah) => selected.contains(ayah.numberInSurah)).toList();
      if (playlist.isEmpty) {
        setState(() => _error = 'empty');
        return;
      }

      _reciterName = QuranReciter.byId(widget.reciterId).nameArabic;
      _stateSub?.cancel();
      _stateSub = _player.playerStateStream.listen((state) {
        if (!mounted || _ignoreComplete || _loadingTrack) return;
        if (state.processingState == ProcessingState.completed) {
          if (_index + 1 < _playlist.length) {
            unawaited(_playIndex(_index + 1));
          }
        }
        setState(() {});
      });
      _player.playbackEventStream.listen((_) {}, onError: (_, _) {});

      setState(() {
        _surah = surah;
        _playlist = playlist;
        _ready = true;
      });
      await _playIndex(0);
    } catch (_) {
      if (mounted) setState(() => _error = 'error');
    }
  }

  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    final ayah = _playlist[index];
    final surah = _surah;
    setState(() {
      _index = index;
      _loadingTrack = true;
      _ignoreComplete = true;
    });
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(ayah.audioUrl),
          tag: MediaItem(
            id: '${surah?.info.number ?? widget.surahNumber}-${ayah.numberInSurah}',
            album: 'رووناهى',
            title: '${surah?.info.nameArabic ?? ''} · ${ayah.numberInSurah}',
            artist: _reciterName,
          ),
        ),
      );
      if (!mounted) return;
      _ignoreComplete = false;
      setState(() => _loadingTrack = false);
      await _player.play();
    } catch (_) {
      _ignoreComplete = false;
      if (mounted) setState(() => _loadingTrack = false);
      if (index + 1 < _playlist.length) {
        await _playIndex(index + 1);
      }
    }
  }

  String _ayahProgressLabel(String ayahLabel, QuranAyahAudio current) {
    final total = _surah?.info.ayahCount ?? _playlist.length;
    // LTR mark keeps "١ / ١٧٦" from flipping in RTL layouts.
    return '$ayahLabel \u200E${_arabicDigits(current.numberInSurah)} / ${_arabicDigits(total)}';
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    if (_error != null) {
      return CatalogPageScaffold(
        title: strings.quranListenTitle,
        child: StatusPanel(
          title: strings.errorTitle,
          body: strings.quranListenError,
          actionLabel: strings.retry,
          onAction: () {
            setState(() {
              _error = null;
              _ready = false;
            });
            _prepare();
          },
        ),
      );
    }
    if (!_ready || _surah == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F4F7),
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );
    }

    final current = _playlist[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          CatalogHeroHeader(
            title: _surah!.info.nameArabic,
            useQuranTitle: true,
            meta: _ayahProgressLabel(strings.quranAyah, current),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: _QuranReader(
                ayahs: _playlist,
                currentIndex: _index,
                onAyahTap: _playIndex,
                fontScale: ref.watch(settingsProvider).quranFontScale,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _ayahProgressLabel(strings.quranAyah, current),
                      style: const TextStyle(color: AppColors.goldSoft, fontFamily: AppTypography.uiFamily),
                    ),
                    StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = _player.duration ?? Duration.zero;
                        final max = duration.inMilliseconds <= 0 ? 1.0 : duration.inMilliseconds.toDouble();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.gold,
                                inactiveTrackColor: AppColors.gold.withValues(alpha: 0.25),
                                thumbColor: AppColors.goldSoft,
                              ),
                              child: Slider(
                                min: 0,
                                max: max,
                                value: position.inMilliseconds.clamp(0, max.toInt()).toDouble(),
                                onChanged: (value) => _player.seek(Duration(milliseconds: value.round())),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Text(
                                    _format(position),
                                    style: const TextStyle(color: AppColors.textOnNavy, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _format(duration),
                                    style: const TextStyle(color: AppColors.textOnNavy, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _index <= 0 ? null : () => _playIndex(_index - 1),
                          icon: const Icon(Icons.skip_previous_rounded, color: AppColors.white, size: 34),
                        ),
                        DecoratedBox(
                          decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                          child: StreamBuilder<PlayerState>(
                            stream: _player.playerStateStream,
                            builder: (context, snapshot) {
                              final playing = snapshot.data?.playing ?? _player.playing;
                              return IconButton(
                                iconSize: 42,
                                onPressed: _loadingTrack
                                    ? null
                                    : () {
                                        if (playing) {
                                          unawaited(_player.pause());
                                        } else {
                                          unawaited(_player.play());
                                        }
                                      },
                                icon: _loadingTrack
                                    ? const SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                                      )
                                    : Icon(
                                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: AppColors.navy,
                                      ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: _index >= _playlist.length - 1 ? null : () => _playIndex(_index + 1),
                          icon: const Icon(Icons.skip_next_rounded, color: AppColors.white, size: 34),
                        ),
                      ],
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

class _QuranReader extends StatefulWidget {
  const _QuranReader({
    required this.ayahs,
    required this.currentIndex,
    required this.onAyahTap,
    this.fontScale = 1,
  });

  final List<QuranAyahAudio> ayahs;
  final int currentIndex;
  final ValueChanged<int> onAyahTap;
  final double fontScale;

  @override
  State<_QuranReader> createState() => _QuranReaderState();
}

class _QuranReaderState extends State<_QuranReader> {
  double? _pageWidth;
  double? _pageHeight;
  int _ayahCount = 0;
  List<int> _pageStarts = const [0];

  static const _fontSize = 24.0;

  TextStyle get _ayahStyle =>
      AppTypography.quran(size: _fontSize, scale: widget.fontScale, color: AppColors.navy).copyWith(height: 1.9);

  @override
  void didUpdateWidget(covariant _QuranReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayahs.length != widget.ayahs.length || oldWidget.fontScale != widget.fontScale) {
      _pageWidth = null;
    }
  }

  double _measure(QuranAyahAudio ayah, double width) {
    final painter = TextPainter(
      text: TextSpan(text: '${_plainAyah(ayah.text)}  ${ayah.numberInSurah}', style: _ayahStyle),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: (width - 44).clamp(80.0, width));
    // Block padding/margin plus the circular ayah badge, which is taller than a digit.
    return painter.height + 48;
  }

  void _rebuildPages(double width, double height) {
    if (_pageWidth == width && _pageHeight == height && _ayahCount == widget.ayahs.length) return;
    _pageWidth = width;
    _pageHeight = height;
    _ayahCount = widget.ayahs.length;
    final starts = <int>[0];
    var start = 0;
    while (start < widget.ayahs.length) {
      var used = 0.0;
      var count = 0;
      for (var i = start; i < widget.ayahs.length; i++) {
        final h = _measure(widget.ayahs[i], width);
        if (count > 0 && used + h > height) break;
        used += h;
        count++;
      }
      final next = (start + count.clamp(1, widget.ayahs.length - start)).clamp(start + 1, widget.ayahs.length);
      if (next >= widget.ayahs.length) break;
      starts.add(next);
      start = next;
    }
    _pageStarts = starts;
  }

  int _pageIndexFor(int ayahIndex) {
    for (var i = _pageStarts.length - 1; i >= 0; i--) {
      if (ayahIndex >= _pageStarts[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.quranPage,
                fit: BoxFit.fill,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('quran page asset failed: $error');
                  return Image.asset(
                    'assets/images/quran page.png',
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.parchment),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 48, 36, 36),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _rebuildPages(constraints.maxWidth, constraints.maxHeight.clamp(40.0, 4000.0));
                    final pageIndex = _pageIndexFor(widget.currentIndex);
                    final from = _pageStarts[pageIndex];
                    final to = pageIndex + 1 < _pageStarts.length ? _pageStarts[pageIndex + 1] : widget.ayahs.length;
                    final page = Column(
                      key: ValueKey('page-$pageIndex'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = from; i < to; i++)
                          _AyahBlock(
                            ayah: widget.ayahs[i],
                            active: i == widget.currentIndex,
                            style: _ayahStyle,
                            onTap: () => widget.onAyahTap(i),
                          ),
                      ],
                    );

                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(child: page),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahBlock extends StatelessWidget {
  const _AyahBlock({
    required this.ayah,
    required this.active,
    required this.style,
    required this.onTap,
  });

  final QuranAyahAudio ayah;
  final bool active;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.goldSoft.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.navy.withValues(alpha: 0.22) : Colors.transparent),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${_plainAyah(ayah.text)} ',
                style: style.copyWith(
                  color: active ? AppColors.deepNavy : AppColors.navy,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _AyahNumberBadge(number: ayah.numberInSurah, active: active),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

class _AyahNumberBadge extends StatelessWidget {
  const _AyahNumberBadge({required this.number, required this.active});

  final int number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.navy : AppColors.white,
        border: Border.all(color: AppColors.navy, width: 1.3),
      ),
      child: Text(
        _arabicDigits(number),
        style: TextStyle(
          fontFamily: AppTypography.uiFamily,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.white : AppColors.navy,
        ),
      ),
    );
  }
}

String _plainAyah(String text) {
  return text
      .replaceAll('\uFEFF', '')
      .replaceAll(RegExp(r'[﴿﴾۝\u06DD\u06DE\u06E9]'), '')
      // Drop trailing ayah digits already shown in the circular badge.
      .replaceAll(RegExp(r'[\s\u06F0-\u06F9٠-٩0-9]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _arabicDigits(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((ch) {
    final index = western.indexOf(ch);
    return index == -1 ? ch : eastern[index];
  }).join();
}
