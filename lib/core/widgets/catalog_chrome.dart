import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_widgets.dart';

/// Shared navy arched header + floating search used across catalog screens.
class CatalogHeroHeader extends StatelessWidget {
  const CatalogHeroHeader({
    super.key,
    required this.title,
    this.meta,
    this.searchHint,
    this.onQueryChanged,
    this.onBack,
    this.actions = const [],
    this.useQuranTitle = false,
  });

  final String title;
  final String? meta;
  final String? searchHint;
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool useQuranTitle;

  @override
  Widget build(BuildContext context) {
    final showSearch = searchHint != null && onQueryChanged != null;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: showSearch ? 24 : 0),
          child: ClipPath(
            clipper: const CatalogHeaderArcClipper(),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.navySoft, AppColors.navy, AppColors.deepNavy],
                ),
              ),
              child: CustomPaint(
                painter: IslamicPatternPainter(opacity: 0.08, color: AppColors.goldSoft),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, showSearch ? 28 : 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CatalogHeaderIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: onBack ?? () => Navigator.of(context).maybePop(),
                            ),
                            const Spacer(),
                            ...actions,
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (useQuranTitle)
                          QuranText(title, size: 28, color: AppColors.white)
                        else
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontFamily: AppTypography.uiFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        if (meta != null && meta!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.78),
                              fontFamily: AppTypography.uiFamily,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Material(
              elevation: 8,
              shadowColor: AppColors.navy.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(28),
              color: AppColors.white,
              child: TextField(
                onChanged: onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: searchHint,
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
                  suffixIcon: const Icon(Icons.tune_rounded, color: AppColors.navy),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.navy, width: 1),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CatalogHeaderIconButton extends StatelessWidget {
  const CatalogHeaderIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.white),
        ),
      ),
    );
  }
}

class CatalogHeaderArcClipper extends CustomClipper<Path> {
  const CatalogHeaderArcClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 28);
    path.quadraticBezierTo(size.width / 2, size.height + 10, size.width, size.height - 28);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Full-screen catalog layout with navy header and light gray body.
class CatalogPageScaffold extends StatefulWidget {
  const CatalogPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.meta,
    this.searchHint,
    this.onQueryChanged,
    this.headerActions = const [],
    this.useQuranTitle = false,
    this.showScrollToTop = true,
  });

  final String title;
  final String? meta;
  final String? searchHint;
  final ValueChanged<String>? onQueryChanged;
  final List<Widget> headerActions;
  final bool useQuranTitle;
  final Widget child;
  final bool showScrollToTop;

  @override
  State<CatalogPageScaffold> createState() => _CatalogPageScaffoldState();
}

class _CatalogPageScaffoldState extends State<CatalogPageScaffold> {
  final ScrollController _scrollController = ScrollController();
  ScrollPosition? _position;
  bool _showScrollToTop = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;
    // Ignore nested horizontal/inner lists (e.g. featured carousels).
    if (notification.depth > 0) return;

    final ctx = notification.context;
    if (ctx != null) {
      _position = Scrollable.maybeOf(ctx)?.position ?? _position;
    }
    if (metrics is ScrollPosition) {
      _position = metrics;
    }

    // Show after scrolling down; keep visible near the bottom.
    final shouldShow = metrics.maxScrollExtent > 80 &&
        (metrics.pixels >= 180 || metrics.extentAfter <= 160);
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Future<void> _scrollToTop() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final position = _position;
    if (position == null || !position.hasContentDimensions) return;
    await position.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: widget.showScrollToTop && _showScrollToTop
          ? FloatingActionButton(
              heroTag: 'catalog_scroll_to_top',
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.goldSoft,
              elevation: 6,
              onPressed: _scrollToTop,
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 30),
            )
          : null,
      body: Column(
        children: [
          CatalogHeroHeader(
            title: widget.title,
            meta: widget.meta,
            searchHint: widget.searchHint,
            onQueryChanged: widget.onQueryChanged,
            actions: widget.headerActions,
            useQuranTitle: widget.useQuranTitle,
          ),
          Expanded(
            child: PrimaryScrollController(
              controller: _scrollController,
              // Web/desktop do not inherit by default — force it so lists share this controller.
              automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _onScrollNotification(notification);
                  return false;
                },
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White card with optional gray footer band (same pattern as verse cards).
class CatalogListCard extends StatelessWidget {
  const CatalogListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.footer,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleWidget,
  });

  final String title;
  final String? subtitle;
  final String? footer;
  final Widget? leading;
  final Widget? trailing;
  final Widget? titleWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleWidget ??
                              Text(
                                title,
                                style: AppTypography.contentStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                  height: 1.45,
                                ),
                              ),
                          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              subtitle!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.contentStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.65,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
              if (footer != null && footer!.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Text(
                    footer!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.navy,
                      fontFamily: AppTypography.uiFamily,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatalogIconBadge extends StatelessWidget {
  const CatalogIconBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: AppColors.navy),
    );
  }
}

class WhatsAppIconBadge extends StatelessWidget {
  const WhatsAppIconBadge({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: WhatsAppLogo(size: size, fit: BoxFit.cover),
      ),
    );
  }
}
