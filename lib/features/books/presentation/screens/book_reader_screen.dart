import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../data/providers.dart';
import '../../data/models/library_book.dart';
import '../books_providers.dart';
import '../widgets/page_turn_reader.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  const BookReaderScreen({super.key, required this.id, this.initialChapter});

  final String id;
  /// Legacy query param ignored — progress is page-based.
  final int? initialChapter;

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen>
    with SingleTickerProviderStateMixin {
  PdfDocument? _document;
  Object? _error;
  bool _opening = true;
  bool _controlsVisible = false;
  bool _searchable = true;
  int _page = 1;
  int _pageCount = 1;
  Timer? _hideTimer;
  final _readerKey = GlobalKey<PageTurnReaderState>();
  late final AnimationController _openCtrl;
  List<BookPageBookmark> _bookmarks = const [];

  @override
  void initState() {
    super.initState();
    _openCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final book = await ref.read(libraryBookProvider(widget.id).future);
    if (!mounted) return;
    if (book == null || !book.hasPdf) {
      setState(() => _error = 'missing');
      return;
    }
    final progress = ref.read(readingProgressMapProvider)[book.id];
    final start = (progress?.currentPage ?? 1).clamp(1, 999999);
    _bookmarks = ref.read(bookBookmarkServiceProvider).forBook(book.id);
    await ref.read(pageSoundServiceProvider).warmUp();
    try {
      await pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
      final doc = await _openPdf(book.pdfUrl);
      if (!mounted) {
        await doc.dispose();
        return;
      }
      final count = doc.pages.length;
      if (count < 1) {
        await doc.dispose();
        setState(() => _error = 'empty-pdf');
        return;
      }
      final initial = start.clamp(1, count);
      final searchable = await pdfHasTextLayer(doc);
      setState(() {
        _document = doc;
        _pageCount = count;
        _page = initial;
        _searchable = searchable;
      });
      await _openCtrl.forward();
      if (mounted) setState(() => _opening = false);
      _applyKeepAwake(ref.read(readerPreferencesProvider).keepAwake);
      await ref.read(readingProgressMapProvider.notifier).save(book.id, _page);
    } catch (e, st) {
      debugPrint('book open failed: $e\n$st');
      if (mounted) setState(() => _error = e);
    }
  }

  Future<PdfDocument> _openPdf(String rawUrl) async {
    final url = rawUrl.trim();
    final uri = Uri.parse(url);
    try {
      return await PdfDocument.openUri(uri, preferRangeAccess: true);
    } catch (first) {
      debugPrint('openUri failed, trying bytes: $first');
      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/pdf,*/*'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('PDF HTTP ${response.statusCode}');
      }
      if (response.bodyBytes.isEmpty) {
        throw StateError('PDF empty response');
      }
      return PdfDocument.openData(response.bodyBytes, sourceName: url);
    }
  }

  void _applyKeepAwake(bool on) {
    if (on) {
      WakelockPlus.enable();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      WakelockPlus.disable();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _openCtrl.dispose();
    _document?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_controlsVisible) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _onPageChanged(int page) async {
    setState(() => _page = page);
    await ref.read(readingProgressMapProvider.notifier).save(widget.id, page);
  }

  Future<void> _toggleBookmark() async {
    await ref.read(bookBookmarkServiceProvider).toggle(widget.id, _page);
    setState(() => _bookmarks = ref.read(bookBookmarkServiceProvider).forBook(widget.id));
    _scheduleHide();
  }

  bool get _isBookmarked => _bookmarks.any((b) => b.page == _page);

  Future<void> _playSound(double intensity) async {
    final prefs = ref.read(readerPreferencesProvider);
    final ms = (450 / prefs.animationSpeed.clamp(0.6, 1.6)).round();
    // Don't block the gesture/animation on audio.
    unawaited(
      ref.read(pageSoundServiceProvider).play(
        enabled: prefs.pageSound,
        intensity: intensity,
        flipDuration: Duration(milliseconds: ms),
      ),
    );
  }

  Future<void> _cancelSound() async {
    await ref.read(pageSoundServiceProvider).cancel();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final prefs = ref.watch(readerPreferencesProvider);
    final bookAsync = ref.watch(libraryBookProvider(widget.id));

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A2433),
        body: StatusPanel(
          title: strings.errorTitle,
          body: strings.errorBody,
          actionLabel: strings.semanticBack,
          onAction: () => context.pop(),
        ),
      );
    }

    return bookAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF1A2433),
        body: Center(child: CircularProgressIndicator(color: AppColors.goldSoft)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: const Color(0xFF1A2433),
        body: StatusPanel(title: strings.errorTitle, body: strings.errorBody),
      ),
      data: (book) {
        if (book == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A2433),
            body: StatusPanel(title: strings.emptyTitle, body: strings.emptyBody),
          );
        }
        final rtl = _isRtlBook(book.language);
        return Scaffold(
          backgroundColor: const Color(0xFF1A2433),
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_document != null && !_opening)
                  PageTurnReader(
                    key: _readerKey,
                    document: _document!,
                    pageCount: _pageCount,
                    initialPage: _page,
                    rtl: rtl,
                    animationEnabled: prefs.pageAnimation,
                    animationSpeed: prefs.animationSpeed,
                    brightness: prefs.brightness,
                    onPageChanged: _onPageChanged,
                    onTurnSound: _playSound,
                    onCancelSound: _cancelSound,
                    onTapPage: _toggleControls,
                  ),
                if (_opening || _document == null)
                  _OpeningOverlay(
                    book: book,
                    languageCode: language.code,
                    progress: _openCtrl,
                    title: book.title.resolve(language),
                    author: book.author.resolve(language),
                  ),
                if (_controlsVisible && !_opening && _document != null)
                  _ReaderChrome(
                    title: book.title.resolve(language),
                    page: _page,
                    pageCount: _pageCount,
                    bookmarked: _isBookmarked,
                    pageLabel: strings.pageOfTotal
                        .replaceFirst('{current}', '$_page')
                        .replaceFirst('{total}', '$_pageCount'),
                    onBack: () => context.pop(),
                    onBookmark: _toggleBookmark,
                    onSearch: () => _openSearch(strings),
                    onSettings: () => _openSettings(strings),
                    onBookmarksList: () => _openBookmarks(strings),
                    bookmarkSemantic: strings.bookmark,
                    searchSemantic: strings.searchInBook,
                    settingsSemantic: strings.readerSettings,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isRtlBook(String language) {
    final code = language.toLowerCase();
    return code.contains('ar') ||
        code.contains('ku') ||
        code.contains('ckb') ||
        code.contains('kmr') ||
        code.contains('fa') ||
        code.contains('ur') ||
        code == 'سۆرانی' ||
        code == 'بادینی';
  }

  Future<void> _openSearch(AppStrings strings) async {
    if (_document == null) return;
    if (!_searchable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.searchUnavailable)),
      );
      return;
    }
    final hits = await showModalBottomSheet<List<BookSearchHit>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SearchSheet(document: _document!, strings: strings),
    );
    if (hits != null && hits.isNotEmpty && mounted) {
      _readerKey.currentState?.goTo(hits.first.page);
    }
    _scheduleHide();
  }

  Future<void> _openBookmarks(AppStrings strings) async {
    final page = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final items = ref.read(bookBookmarkServiceProvider).forBook(widget.id);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.bookmarksTitle,
                    style: const TextStyle(
                      fontFamily: AppTypography.uiFamily,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    Text(strings.emptyTitle, style: const TextStyle(color: AppColors.textSecondary))
                  else
                    ...items.map(
                      (b) => ListTile(
                        title: Text(
                          strings.bookmarkPage.replaceFirst('{n}', '${b.page}'),
                          style: const TextStyle(fontFamily: AppTypography.uiFamily, color: AppColors.navy),
                        ),
                        onTap: () => Navigator.pop(context, b.page),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (page != null) _readerKey.currentState?.goTo(page);
    _scheduleHide();
  }

  Future<void> _openSettings(AppStrings strings) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final current = ref.watch(readerPreferencesProvider);
            final notifier = ref.read(readerPreferencesProvider.notifier);
            final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.readerSettings,
                        style: const TextStyle(
                          fontFamily: AppTypography.uiFamily,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          fontSize: 18,
                        ),
                      ),
                      SwitchListTile(
                        title: Text(strings.pageSound),
                        value: current.pageSound,
                        activeThumbColor: AppColors.navy,
                        onChanged: (v) => notifier.update(current.copyWith(pageSound: v)),
                      ),
                      SwitchListTile(
                        title: Text(strings.pageAnimation),
                        value: current.pageAnimation,
                        activeThumbColor: AppColors.navy,
                        onChanged: (v) => notifier.update(current.copyWith(pageAnimation: v)),
                      ),
                      ListTile(
                        title: Text(strings.animationSpeed),
                        subtitle: Slider(
                          value: current.animationSpeed.clamp(0.6, 1.6),
                          min: 0.6,
                          max: 1.6,
                          divisions: 5,
                          activeColor: AppColors.navy,
                          onChanged: (v) => notifier.update(current.copyWith(animationSpeed: v)),
                        ),
                      ),
                      ListTile(
                        title: Text(strings.readerBrightness),
                        subtitle: Slider(
                          value: current.brightness.clamp(0.7, 1.2),
                          min: 0.7,
                          max: 1.2,
                          divisions: 10,
                          activeColor: AppColors.navy,
                          onChanged: (v) => notifier.update(current.copyWith(brightness: v)),
                        ),
                      ),
                      SwitchListTile(
                        title: Text(strings.keepScreenAwake),
                        value: current.keepAwake,
                        activeThumbColor: AppColors.navy,
                        onChanged: (v) {
                          notifier.update(current.copyWith(keepAwake: v));
                          _applyKeepAwake(v);
                        },
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref.read(readingProgressMapProvider.notifier).reset(widget.id);
                          _readerKey.currentState?.goTo(1, animate: false);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(strings.resetReadingPosition),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    _scheduleHide();
  }
}

class _OpeningOverlay extends StatelessWidget {
  const _OpeningOverlay({
    required this.book,
    required this.languageCode,
    required this.progress,
    required this.title,
    required this.author,
  });

  final LibraryBook book;
  final String languageCode;
  final AnimationController progress;
  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(progress.value);
        final coverOpacity = (1 - (t - 0.55).clamp(0, 1) / 0.45);
        final scale = 0.92 + 0.08 * t;
        return ColoredBox(
          color: const Color(0xFF1A2433),
          child: Center(
            child: Opacity(
              opacity: coverOpacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 220,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: book.coverImageUrl == null || book.coverImageUrl!.isEmpty
                              ? ColoredBox(
                                  color: AppColors.navy,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: AppColors.goldSoft),
                                      ),
                                    ),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: book.coverImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFamily,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(author, style: const TextStyle(color: AppColors.goldSoft, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReaderChrome extends StatelessWidget {
  const _ReaderChrome({
    required this.title,
    required this.page,
    required this.pageCount,
    required this.bookmarked,
    required this.pageLabel,
    required this.onBack,
    required this.onBookmark,
    required this.onSearch,
    required this.onSettings,
    required this.onBookmarksList,
    required this.bookmarkSemantic,
    required this.searchSemantic,
    required this.settingsSemantic,
  });

  final String title;
  final int page;
  final int pageCount;
  final bool bookmarked;
  final String pageLabel;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onBookmarksList;
  final String bookmarkSemantic;
  final String searchSemantic;
  final String settingsSemantic;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: AppColors.navy.withValues(alpha: 0.92),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFamily,
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: bookmarkSemantic,
                    onPressed: onBookmark,
                    icon: Icon(
                      bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: AppColors.goldSoft,
                    ),
                  ),
                  IconButton(
                    tooltip: searchSemantic,
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded, color: AppColors.white),
                  ),
                  IconButton(
                    tooltip: settingsSemantic,
                    onPressed: onSettings,
                    icon: const Icon(Icons.tune_rounded, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Material(
            color: AppColors.navy.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pageLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFamily,
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onBookmarksList,
                    icon: const Icon(Icons.bookmarks_outlined, color: AppColors.goldSoft, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pageCount <= 0 ? 0 : page / pageCount,
              minHeight: 4,
              backgroundColor: Colors.white24,
              color: AppColors.goldMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.document, required this.strings});

  final PdfDocument document;
  final AppStrings strings;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  List<BookSearchHit> _hits = const [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    final hits = await searchPdfText(widget.document, _controller.text);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: strings.searchInBook,
              suffixIcon: IconButton(onPressed: _run, icon: const Icon(Icons.search)),
            ),
            onSubmitted: (_) => _run(),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.navy),
            )
          else if (_hits.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(strings.noResults),
            )
          else
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: ListView.builder(
                itemCount: _hits.length,
                itemBuilder: (context, index) {
                  final hit = _hits[index];
                  return ListTile(
                    title: Text(
                      strings.bookmarkPage.replaceFirst('{n}', '${hit.page}'),
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFamily,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(hit.preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(context, [hit]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
