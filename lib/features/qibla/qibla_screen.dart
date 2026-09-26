import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:imanikurd/imanikurd.dart' as iman;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/catalog_chrome.dart';
import '../../data/providers.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  late String _cityKey;
  iman.Coordinates? _gps;
  double? _heading;
  StreamSubscription<CompassEvent>? _compass;
  String? _error;
  bool _locating = false;

  iman.City get _city {
    return iman.getCity(_cityKey) ?? iman.kurdistanCities.first;
  }

  double get _lat => _gps?.lat ?? _city.lat;
  double get _lng => _gps?.lng ?? _city.lng;

  @override
  void initState() {
    super.initState();
    _cityKey = ref.read(localStoreProvider).qiblaCityKey();
    _listenCompass();
  }

  void _listenCompass() {
    if (kIsWeb) return;
    try {
      _compass = FlutterCompass.events?.listen((event) {
        if (!mounted) return;
        setState(() => _heading = event.heading);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _compass?.cancel();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw StateError('off');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw StateError('denied');
      }
      final position = await Geolocator.getCurrentPosition();
      final nearest = iman.getCityByCoordinates(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _gps = iman.Coordinates(lat: position.latitude, lng: position.longitude);
        _cityKey = nearest.key;
      });
      await ref.read(localStoreProvider).setQiblaCityKey(nearest.key);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = ref.read(stringsProvider).qiblaLocationDenied);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _selectCity(String key) async {
    setState(() {
      _cityKey = key;
      _gps = null;
      _error = null;
    });
    await ref.read(localStoreProvider).setQiblaCityKey(key);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final qibla = iman.calculateQibla(_lat, _lng);
    final distance = iman.getDistanceToKaaba(_lat, _lng);
    final heading = _heading;
    final facing = heading != null && iman.isFacingQibla(heading, _lat, _lng, tolerance: 8);
    final needle = qibla.toDouble() - (heading ?? 0);

    return CatalogPageScaffold(
      title: strings.qiblaTitle,
      meta: '${_city.nameKurdish} · ${strings.qiblaBearing(qibla)}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: facing ? AppColors.gold.withValues(alpha: 0.55) : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 260,
                    child: _QiblaDial(
                      angle: needle,
                      aligned: facing,
                      kaabaLabel: strings.qiblaKaaba,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    facing ? strings.qiblaFacing : strings.qiblaTurn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: facing ? AppColors.success : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.qiblaBearing(qibla),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.navy,
                          fontFamily: AppTypography.uiFamily,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.qiblaKm(distance),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: AppTypography.uiFamily,
                        ),
                  ),
                  if (heading == null) ...[
                    const SizedBox(height: 10),
                    Text(
                      strings.qiblaNorthHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: AppTypography.uiFamily,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          CatalogListCard(
            title: strings.qiblaCity,
            titleWidget: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: iman.getCity(_cityKey) == null ? iman.kurdistanCities.first.key : _cityKey,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
                borderRadius: BorderRadius.circular(16),
                items: [
                  for (final city in iman.kurdistanCities)
                    DropdownMenuItem(
                      value: city.key,
                      child: Text(
                        city.nameKurdish,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.uiFamily,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) _selectCity(value);
                },
              ),
            ),
            leading: const CatalogIconBadge(icon: Icons.place_rounded),
          ),
          const SizedBox(height: 12),
          CatalogListCard(
            title: strings.qiblaUseLocation,
            footer: _gps == null ? null : strings.qiblaGpsActive,
            leading: CatalogIconBadge(
              icon: _locating ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
            ),
            trailing: _locating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                  )
                : Icon(Icons.chevron_right_rounded, color: AppColors.navy.withValues(alpha: 0.35)),
            onTap: _locating ? () {} : _useGps,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontFamily: AppTypography.uiFamily,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QiblaDial extends StatelessWidget {
  const _QiblaDial({
    required this.angle,
    required this.aligned,
    required this.kaabaLabel,
  });

  final double angle;
  final bool aligned;
  final String kaabaLabel;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DialPainter(aligned: aligned),
      child: Center(
        child: Transform.rotate(
          angle: angle * math.pi / 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.navigation_rounded,
                size: 64,
                color: aligned ? AppColors.gold : AppColors.navy,
              ),
              Text(
                kaabaLabel,
                style: TextStyle(
                  fontFamily: AppTypography.uiFamily,
                  fontWeight: FontWeight.w800,
                  color: aligned ? AppColors.goldMuted : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.aligned});

  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = aligned ? AppColors.gold : AppColors.navy;
    final inner = Paint()..color = AppColors.lightBlue.withValues(alpha: 0.85);
    canvas.drawCircle(center, radius, inner);
    canvas.drawCircle(center, radius, ring);
    final tick = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2;
    for (var i = 0; i < 36; i++) {
      final rad = i * 10 * math.pi / 180;
      final outer = Offset(center.dx + radius * math.sin(rad), center.dy - radius * math.cos(rad));
      final innerPt = Offset(
        center.dx + (radius - (i % 9 == 0 ? 18 : 10)) * math.sin(rad),
        center.dy - (radius - (i % 9 == 0 ? 18 : 10)) * math.cos(rad),
      );
      canvas.drawLine(innerPt, outer, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.aligned != aligned;
}
