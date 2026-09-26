import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _HomeBackdropPainter(), child: SizedBox.expand());
  }
}

class _HomeBackdropPainter extends CustomPainter {
  const _HomeBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.parchment);

    final pattern = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    const step = 46.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x, y), 11, pattern);
        _star(canvas, Offset(x + step / 2, y + step / 2), 6.5, pattern);
      }
    }

    _mosques(canvas, size);
  }

  void _star(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + (math.pi / 4) * i;
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _mosques(Canvas canvas, Size size) {
    final fill = Paint()..color = AppColors.navy.withValues(alpha: 0.07);
    final skyline = Path();
    final base = size.height * 0.78;
    skyline.moveTo(0, size.height);
    skyline.lineTo(0, base + 40);
    _dome(skyline, size.width * 0.08, base + 18, 22);
    _minaret(skyline, size.width * 0.18, base - 8, 10, 70);
    _dome(skyline, size.width * 0.32, base + 6, 36);
    _minaret(skyline, size.width * 0.48, base - 22, 12, 92);
    _dome(skyline, size.width * 0.62, base + 10, 28);
    _minaret(skyline, size.width * 0.78, base - 4, 10, 64);
    _dome(skyline, size.width * 0.92, base + 20, 24);
    skyline.lineTo(size.width, size.height);
    skyline.close();
    canvas.drawPath(skyline, fill);
  }

  void _dome(Path path, double x, double y, double r) {
    path.lineTo(x - r, y);
    path.quadraticBezierTo(x, y - r * 1.55, x + r, y);
  }

  void _minaret(Path path, double x, double y, double w, double h) {
    path.lineTo(x - w / 2, y);
    path.lineTo(x - w / 2, y - h);
    path.lineTo(x, y - h - 14);
    path.lineTo(x + w / 2, y - h);
    path.lineTo(x + w / 2, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MihrabHeader extends StatelessWidget {
  const MihrabHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: AppTypography.uiFamily,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
                height: 1.1,
                fontSize: 36,
                shadows: [
                  Shadow(color: Color(0x66FFFFFF), blurRadius: 12),
                ],
              ),
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.uiFamily,
              fontSize: 13,
              color: AppColors.navy.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class OrnateMedallionBorder extends StatelessWidget {
  const OrnateMedallionBorder({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _MedallionPainter(),
        child: Padding(padding: EdgeInsets.all(size * 0.13), child: FittedBox(child: child)),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  const _MedallionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final navy = Paint()
      ..shader = const RadialGradient(
        colors: [AppColors.navySoft, AppColors.navy, AppColors.deepNavy],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r * 0.86, navy);

    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final goldSoft = Paint()
      ..color = AppColors.goldSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(c, r * 0.97, goldSoft);
    canvas.drawCircle(c, r * 0.90, gold);
    canvas.drawCircle(c, r * 0.82, goldSoft);

    final bead = Paint()..color = AppColors.gold;
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      canvas.drawCircle(
        Offset(c.dx + r * 0.935 * math.cos(a), c.dy + r * 0.935 * math.sin(a)),
        i.isEven ? 1.7 : 1.1,
        bead,
      );
    }

    final star = Path();
    const spikes = 8;
    for (var i = 0; i < spikes * 2; i++) {
      final rr = i.isEven ? r * 0.78 : r * 0.72;
      final a = -math.pi / 2 + i * math.pi / spikes;
      final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
