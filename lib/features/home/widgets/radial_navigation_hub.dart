import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class RadialNavItem {
  const RadialNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.dark = false,
    this.badge,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;
  final bool dark;
  final IconData? badge;
}

class RadialNavigationHub extends StatelessWidget {
  const RadialNavigationHub({
    super.key,
    required this.items,
    required this.center,
    required this.onSelected,
    this.selectedId,
  });

  final List<RadialNavItem> items;
  final Widget center;
  final ValueChanged<RadialNavItem> onSelected;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        if (shortest <= 0) return const SizedBox.shrink();
        final size = shortest;
        final petalW = size * 0.22;
        final petalH = size * 0.275;
        final centerSize = size * 0.29;
        final radius = size * 0.332;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      AppAssets.flowerNav,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.expand(),
                    ),
                  ),
                ),
                for (var i = 0; i < items.length; i++)
                  _PetalPositioned(
                    index: i,
                    count: items.length,
                    radius: radius,
                    width: petalW,
                    height: petalH,
                    item: items[i],
                    selected: selectedId == items[i].id,
                    dimmed: selectedId != null && selectedId != items[i].id,
                    onSelected: onSelected,
                  ),
                SizedBox(
                  width: centerSize,
                  height: centerSize,
                  child: ClipOval(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.all(centerSize * 0.08),
                        child: center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PetalPositioned extends StatelessWidget {
  const _PetalPositioned({
    required this.index,
    required this.count,
    required this.radius,
    required this.width,
    required this.height,
    required this.item,
    required this.selected,
    required this.dimmed,
    required this.onSelected,
  });

  final int index;
  final int count;
  final double radius;
  final double width;
  final double height;
  final RadialNavItem item;
  final bool selected;
  final bool dimmed;
  final ValueChanged<RadialNavItem> onSelected;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi / 2 + (2 * math.pi * index / count);
    final offset = Offset(radius * math.cos(angle), radius * math.sin(angle));
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle + math.pi / 2,
        child: _PetalCard(
          item: item,
          width: width,
          height: height,
          selected: selected,
          dimmed: dimmed,
          contentRotation: -(angle + math.pi / 2),
          onTap: () => onSelected(item),
        ),
      ),
    );
  }
}

class _PetalCard extends StatelessWidget {
  const _PetalCard({
    required this.item,
    required this.width,
    required this.height,
    required this.selected,
    required this.dimmed,
    required this.contentRotation,
    required this.onTap,
  });

  final RadialNavItem item;
  final double width;
  final double height;
  final bool selected;
  final bool dimmed;
  final double contentRotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = item.dark;
    final foreground = dark ? AppColors.white : AppColors.navy;
    return Semantics(
      button: true,
      label: item.label,
      selected: selected,
      child: AnimatedScale(
        scale: selected ? 1.08 : (dimmed ? 0.92 : 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: dimmed ? 0.72 : 1,
          child: SizedBox(
            width: width,
            height: height,
            child: Material(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.18)
                  : Colors.transparent,
              shape: const _PetalShape(),
              child: InkWell(
                onTap: onTap,
                customBorder: const _PetalShape(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    width * 0.16,
                    height * 0.22,
                    width * 0.16,
                    height * 0.2,
                  ),
                  child: Transform.rotate(
                    angle: contentRotation,
                    child: FittedBox(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                item.icon,
                                color: dark
                                    ? AppColors.goldSoft
                                    : AppColors.navy,
                                size: 20,
                              ),
                              if (item.badge != null)
                                Positioned(
                                  right: -8,
                                  bottom: -6,
                                  child: Icon(
                                    item.badge,
                                    size: 11,
                                    color: const Color(0xFF25D366),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFamily,
                              fontSize: 12,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetalShape extends ShapeBorder {
  const _PetalShape();

  Path _path(Rect rect) => petalPath(rect.size, rect.topLeft);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

Path petalPath(Size size, [Offset origin = Offset.zero]) {
  final w = size.width;
  final h = size.height;
  final x = origin.dx;
  final y = origin.dy;
  return Path()
    ..moveTo(x + w / 2, y)
    ..cubicTo(
      x + w * 0.08,
      y + h * 0.22,
      x + w * 0.02,
      y + h * 0.48,
      x + w * 0.18,
      y + h * 0.82,
    )
    ..quadraticBezierTo(x + w / 2, y + h, x + w * 0.82, y + h * 0.82)
    ..cubicTo(
      x + w * 0.98,
      y + h * 0.48,
      x + w * 0.92,
      y + h * 0.22,
      x + w / 2,
      y,
    )
    ..close();
}

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    super.key,
    required this.soraniLabel,
    required this.badiniLabel,
    required this.soraniSelected,
    required this.onSorani,
    required this.onBadini,
    required this.semanticLabel,
  });

  final String soraniLabel;
  final String badiniLabel;
  final bool soraniSelected;
  final VoidCallback onSorani;
  final VoidCallback onBadini;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final selected = soraniSelected ? soraniLabel : badiniLabel;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: PopupMenuButton<int>(
        tooltip: semanticLabel,
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (value) => value == 0 ? onSorani() : onBadini(),
        itemBuilder: (context) => [
          PopupMenuItem(value: 0, child: Text(soraniLabel)),
          PopupMenuItem(value: 1, child: Text(badiniLabel)),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 16, color: AppColors.navy),
              const SizedBox(width: 6),
              Text(
                selected,
                style: const TextStyle(
                  fontFamily: AppTypography.uiFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeCircleButton extends StatelessWidget {
  const HomeCircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.uiFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
