import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../data/models/library_book.dart';

/// Book reader powered by [page_flip] + pdfrx pages.
class PageTurnReader extends StatefulWidget {
  const PageTurnReader({
    super.key,
    required this.document,
    required this.pageCount,
    required this.initialPage,
    required this.rtl,
    required this.animationEnabled,
    required this.animationSpeed,
    required this.brightness,
    required this.onPageChanged,
    required this.onTurnSound,
    required this.onCancelSound,
    this.onTapPage,
    this.controls,
  });

  final PdfDocument document;
  final int pageCount;
  final int initialPage;
  final bool rtl;
  final bool animationEnabled;
  final double animationSpeed;
  final double brightness;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<double> onTurnSound;
  final VoidCallback onCancelSound;
  /// Called on a light tap (not a swipe) — used for reader chrome.
  final VoidCallback? onTapPage;
  final Widget? controls;

  @override
  State<PageTurnReader> createState() => PageTurnReaderState();
}

class PageTurnReaderState extends State<PageTurnReader> {
  final _flipKey = GlobalKey<PageFlipWidgetState>();
  late final PageFlipController _flipController;
  late int _page;
  double _scale = 1;
  final _zoom = TransformationController();

  Offset _pointerStart = Offset.zero;
  double _dragDx = 0;
  bool _soundPlayed = false;
  int _pointerCount = 0;

  int get page => _page;
  int get pageCount => widget.pageCount;

  @override
  void initState() {
    super.initState();
    _flipController = PageFlipController();
    _page = widget.initialPage.clamp(1, math.max(1, widget.pageCount));
  }

  @override
  void dispose() {
    imageData.clear();
    _zoom.dispose();
    super.dispose();
  }

  void goTo(int page, {bool animate = true}) {
    final target = page.clamp(1, widget.pageCount);
    if (target == _page) return;
    final index = target - 1;
    if (animate && widget.animationEnabled) {
      widget.onTurnSound(1);
    }
    _flipController.goToPage(index);
    setState(() => _page = target);
    widget.onPageChanged(_page);
  }

  Duration get _duration {
    final ms = (420 / widget.animationSpeed.clamp(0.6, 1.6)).round();
    return Duration(milliseconds: ms);
  }

  void _onFlipped(int index) {
    final next = (index + 1).clamp(1, widget.pageCount);
    if (next == _page) return;
    setState(() => _page = next);
    widget.onPageChanged(_page);
  }

  void _resetZoom() {
    _zoom.value = Matrix4.identity();
    setState(() => _scale = 1);
  }

  void _toggleZoom() {
    if (_scale > 1.05) {
      _resetZoom();
    } else {
      _zoom.value = Matrix4.diagonal3Values(1.9, 1.9, 1);
      setState(() => _scale = 1.9);
    }
  }

  bool get _zoomed => _scale > 1.05;

  @override
  Widget build(BuildContext context) {
    final count = math.max(1, widget.pageCount);
    final initial = (_page - 1).clamp(0, count - 1);

    return ColoredBox(
      color: const Color(0xFFEFE6D6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              _pointerCount++;
              if (_pointerCount == 1) {
                _pointerStart = e.localPosition;
                _dragDx = 0;
                _soundPlayed = false;
              }
            },
            onPointerMove: (e) {
              if (_zoomed || _soundPlayed || _pointerCount != 1) return;
              _dragDx += e.delta.dx;
              // Fire paper sound at the first hint of a page turn.
              if (_dragDx.abs() >= 4) {
                _soundPlayed = true;
                widget.onTurnSound(1);
              }
            },
            onPointerUp: (e) {
              _pointerCount = math.max(0, _pointerCount - 1);
              if (_pointerCount > 0) return;
              final moved = (e.localPosition - _pointerStart).distance;
              // Light tap → show/hide controls (page_flip eats GestureDetector onTap).
              if (!_zoomed && moved < 12 && _dragDx.abs() < 10) {
                widget.onTapPage?.call();
              }
              _dragDx = 0;
              _soundPlayed = false;
            },
            onPointerCancel: (_) {
              _pointerCount = math.max(0, _pointerCount - 1);
              _dragDx = 0;
              _soundPlayed = false;
            },
            child: InteractiveViewer(
              transformationController: _zoom,
              minScale: 1,
              maxScale: 3.5,
              // Only pan when zoomed so horizontal swipes flip pages at 1x.
              panEnabled: _zoomed,
              scaleEnabled: true,
              onInteractionUpdate: (details) {
                final next = _zoom.value.getMaxScaleOnAxis();
                if ((next - _scale).abs() > 0.01) {
                  setState(() => _scale = next);
                }
              },
              onInteractionEnd: (_) {
                final next = _zoom.value.getMaxScaleOnAxis();
                setState(() => _scale = next);
                if (next < 1.05) _resetZoom();
              },
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onDoubleTap: _toggleZoom,
                child: IgnorePointer(
                  // While zoomed, block page_flip so pinch/pan work cleanly.
                  ignoring: _zoomed,
                  child: PageFlipWidget(
                    key: _flipKey,
                    controller: _flipController,
                    backgroundColor: const Color(0xFFFBF6EA),
                    duration: _duration,
                    isRightSwipe: true,
                    initialIndex: initial,
                    onPageFlipped: _onFlipped,
                    children: [
                      for (var i = 1; i <= count; i++)
                        _PdfFlipPage(
                          document: widget.document,
                          pageNumber: i,
                          brightness: widget.brightness,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.controls != null) widget.controls!,
        ],
      ),
    );
  }
}

class _PdfFlipPage extends StatelessWidget {
  const _PdfFlipPage({
    required this.document,
    required this.pageNumber,
    required this.brightness,
  });

  final PdfDocument document;
  final int pageNumber;
  final double brightness;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFBF6EA),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF6EA),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(<double>[
                brightness, 0, 0, 0, 0,
                0, brightness, 0, 0, 0,
                0, 0, brightness, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: PdfPageView(
                document: document,
                pageNumber: pageNumber,
                alignment: Alignment.center,
                backgroundColor: const Color(0xFFFBF6EA),
                decoration: const BoxDecoration(color: Color(0xFFFBF6EA)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<List<BookSearchHit>> searchPdfText(PdfDocument document, String query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final hits = <BookSearchHit>[];
  try {
    for (var i = 0; i < document.pages.length; i++) {
      final page = document.pages[i];
      final text = await page.loadText();
      final full = text?.fullText ?? '';
      if (full.isEmpty) continue;
      final index = full.toLowerCase().indexOf(q.toLowerCase());
      if (index < 0) continue;
      final start = math.max(0, index - 24);
      final end = math.min(full.length, index + q.length + 36);
      hits.add(
        BookSearchHit(
          page: i + 1,
          preview: full.substring(start, end).replaceAll('\n', ' ').trim(),
        ),
      );
      if (hits.length >= 40) break;
    }
  } catch (_) {
    return const [];
  }
  return hits;
}

Future<bool> pdfHasTextLayer(PdfDocument document, {int samplePages = 5}) async {
  final limit = math.min(samplePages, document.pages.length);
  for (var i = 0; i < limit; i++) {
    try {
      final text = await document.pages[i].loadText();
      final full = (text?.fullText ?? '').trim();
      if (full.length > 12) return true;
    } catch (_) {}
  }
  return false;
}
