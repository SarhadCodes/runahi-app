import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SceneBackground extends StatelessWidget {
  const SceneBackground({super.key, this.scrim = 0});

  final double scrim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.parchment),
        Image.asset(
          AppAssets.homeBackground,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
        ),
        if (scrim > 0)
          ColoredBox(color: AppColors.parchment.withValues(alpha: scrim)),
      ],
    );
  }
}

class IslamicPatternPainter extends CustomPainter {
  IslamicPatternPainter({this.opacity = 0.06, this.color = AppColors.navy});

  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const step = 42.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x, y), 14, paint);
        _star(canvas, Offset(x + step / 2, y + step / 2), 7, paint);
      }
    }
  }

  void _star(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + (math.pi / 4) * i;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.color != color;
  }
}

class RounahiLogo extends StatelessWidget {
  const RounahiLogo({
    super.key,
    this.size = 48,
    this.color = AppColors.navy,
    this.showMark = true,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final double size;
  final Color color;
  final bool showMark;
  final BoxFit fit;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.22;
    return Semantics(
      header: true,
      label: AppConstants.appName,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: ColoredBox(
            color: AppColors.navy,
            child: Image.asset(
              AppAssets.appLogo,
              width: size,
              height: size,
              fit: fit,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('App logo failed: $error');
                return Image.asset(
                  AppAssets.appLogoAdaptive,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, error2, _) {
                    debugPrint('App logo adaptive failed: $error2');
                    return Center(
                      child: Text(
                        'ر',
                        style: TextStyle(
                          color: AppColors.goldSoft,
                          fontSize: size * 0.42,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTypography.uiFamily,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class WhatsAppLogo extends StatelessWidget {
  const WhatsAppLogo({super.key, this.size = 28, this.fit = BoxFit.contain});

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.whatsAppLogo,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      isAntiAlias: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('WhatsApp logo failed: $error');
        // Branded fallback (not Material chat) if the PNG asset fails to resolve.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: Center(
            child: Icon(
              Icons.phone_rounded,
              size: size * 0.55,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.tint,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? tint;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: selected ? AppColors.gold : AppColors.border,
          width: selected ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.builder,
    required this.emptyTitle,
    required this.emptyBody,
    required this.errorTitle,
    required this.errorBody,
    required this.retryLabel,
    required this.onRetry,
  });

  final AsyncSnapshot<T> value;
  final Widget Function(T data) builder;
  final String emptyTitle;
  final String emptyBody;
  final String errorTitle;
  final String errorBody;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasError) {
      return StatusPanel(
        title: errorTitle,
        body: errorBody,
        actionLabel: retryLabel,
        onAction: onRetry,
      );
    }
    if (!value.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      );
    }
    final data = value.data as T;
    if (data is Iterable && data.isEmpty) {
      return StatusPanel(title: emptyTitle, body: emptyBody);
    }
    return builder(data);
  }
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionScaffold extends StatelessWidget {
  const SectionScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.floating,
    this.onSearch,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final Widget? floating;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: floating,
      body: Stack(
        children: [
          const SceneBackground(scrim: 0.62),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                      if (onSearch != null)
                        IconButton(
                          onPressed: onSearch,
                          icon: const Icon(Icons.search_rounded),
                        ),
                      ...actions,
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RounahiSearchField extends StatelessWidget {
  const RounahiSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.autofocus = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selected;
          return ChoiceChip(
            label: Text(item),
            selected: isSelected,
            onSelected: (_) => onSelected(item),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.white : AppColors.navy,
              fontFamily: AppTypography.uiFamily,
            ),
            selectedColor: AppColors.navy,
            backgroundColor: AppColors.lightBlue,
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class WhatsAppCta extends StatelessWidget {
  const WhatsAppCta({
    super.key,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      tint: AppColors.lightBlue,
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const WhatsAppLogo(size: 22),
            label: Text(
              buttonLabel,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
