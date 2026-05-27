import 'dart:async';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:vibration/vibration.dart';

import '../config/localization.dart';
import '../models/prayer_model.dart';
import '../services/location_service.dart';

class QiblaTelemetry {
  const QiblaTelemetry({
    this.heading,
    this.qiblaBearing,
    this.relativeAngle,
    this.isAligned = false,
    this.hasCompass = false,
    this.hasLocation = false,
  });

  final double? heading;
  final double? qiblaBearing;
  final double? relativeAngle;
  final bool isAligned;
  final bool hasCompass;
  final bool hasLocation;

  @override
  bool operator ==(Object other) {
    return other is QiblaTelemetry &&
        other.heading == heading &&
        other.qiblaBearing == qiblaBearing &&
        other.relativeAngle == relativeAngle &&
        other.isAligned == isAligned &&
        other.hasCompass == hasCompass &&
        other.hasLocation == hasLocation;
  }

  @override
  int get hashCode => Object.hash(
        heading,
        qiblaBearing,
        relativeAngle,
        isAligned,
        hasCompass,
        hasLocation,
      );
}

class QiblaCompassWidget extends StatefulWidget {
  const QiblaCompassWidget({
    Key? key,
    required this.locale,
    this.startRotationDelay = const Duration(milliseconds: 150),
    this.onTap,
    this.sensitivity = 3.0,
    this.alignmentColor,
    this.userLocation,
    this.backgroundColor,
    this.onTelemetry,
    this.vibrationEnabled = true,
  }) : super(key: key);

  final String locale;
  final Duration startRotationDelay;
  final VoidCallback? onTap;
  final double sensitivity;
  final Color? alignmentColor;
  final GeoLocation? userLocation;
  final Color? backgroundColor;
  final ValueChanged<QiblaTelemetry>? onTelemetry;
  final bool vibrationEnabled;

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fallbackController;
  StreamSubscription<CompassEvent>? _compassSub;

  GeoLocation? _deviceLocation;
  double? _qiblaBearing;
  double? _heading;
  double _needleRadians = 0;
  bool _hasCompass = false;
  bool _isAligned = false;
  bool _vibrationCooldown = false;

  @override
  void initState() {
    super.initState();
    _fallbackController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    Future.delayed(widget.startRotationDelay, () async {
      if (!mounted) return;
      await _loadLocation();
      _listenCompass();
    });
  }

  Future<void> _loadLocation() async {
    GeoLocation? location = widget.userLocation;
    location ??= await LocationService.getCurrentLocation();
    if (!mounted) return;

    setState(() {
      _deviceLocation = location;
      _qiblaBearing = location == null
          ? null
          : _normalizeDegrees(Qibla(Coordinates(
              location.latitude,
              location.longitude,
            )).direction);
    });

    _emitTelemetry();
  }

  void _listenCompass() {
    _compassSub?.cancel();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _emitTelemetry();
      return;
    }

    _compassSub = stream.listen((event) {
      final heading = event.heading;
      if (heading == null || !mounted) return;

      final qiblaBearing = _qiblaBearing;
      final relativeAngle =
          qiblaBearing == null ? null : _normalizeDegrees(qiblaBearing - heading);
      final aligned =
          relativeAngle != null && relativeAngle.abs() <= widget.sensitivity;

      setState(() {
        _hasCompass = true;
        _heading = heading;
        _needleRadians = relativeAngle == null ? 0 : _degToRad(relativeAngle);
        _isAligned = aligned;
      });

      if (_fallbackController.isAnimating) {
        _fallbackController.stop();
      }

      _emitTelemetry();
      _vibrateIfNeeded(aligned);
    });
  }

  Future<void> _vibrateIfNeeded(bool aligned) async {
    if (!widget.vibrationEnabled || !aligned || _vibrationCooldown) return;
    _vibrationCooldown = true;
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: 120);
      }
    } catch (_) {
      // Ignore vibration errors.
    } finally {
      Future.delayed(const Duration(milliseconds: 900), () {
        _vibrationCooldown = false;
      });
    }
  }

  void _emitTelemetry() {
    widget.onTelemetry?.call(
      QiblaTelemetry(
        heading: _heading == null ? null : _round(_heading!),
        qiblaBearing: _qiblaBearing == null ? null : _round(_qiblaBearing!),
        relativeAngle: (_heading == null || _qiblaBearing == null)
            ? null
            : _round(_normalizeDegrees(_qiblaBearing! - _heading!)),
        isAligned: _isAligned,
        hasCompass: _hasCompass,
        hasLocation: _deviceLocation != null,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant QiblaCompassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userLocation != widget.userLocation) {
      _loadLocation();
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.alignmentColor ?? const Color(0xFFD7B56D);
    final bg = widget.backgroundColor ?? const Color(0xFF0B141B);

    Widget compass = LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    bg,
                    Color.lerp(bg, Colors.black, 0.24) ?? bg,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.26),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size.square(size),
              painter: _CompassDialPainter(
                color: const Color(0xFFF4E6CC),
                accentColor: accent,
                isAligned: _isAligned,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isAligned
                    ? accent.withOpacity(0.22)
                    : Colors.transparent,
                boxShadow: _isAligned
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.38),
                          blurRadius: 34,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: const Color(0xFFE0B86D).withOpacity(0.22),
                          blurRadius: 46,
                          spreadRadius: 6,
                        ),
                      ]
                    : const [],
              ),
            ),
            AnimatedBuilder(
              animation: _fallbackController,
              builder: (context, child) {
                final angle = _hasCompass
                    ? _needleRadians
                    : _fallbackController.value * 2 * math.pi;
                return Transform.rotate(angle: angle, child: child);
              },
              child: Icon(
                Icons.navigation_rounded,
                size: size * 0.46,
                color: _isAligned ? accent : const Color(0xFFE0B86D),
                shadows: [
                  if (_isAligned)
                    Shadow(
                      color: const Color(0xFF4ADE80).withOpacity(0.55),
                      blurRadius: 28,
                    ),
                  if (_isAligned)
                    Shadow(
                      color: const Color(0xFFE0B86D).withOpacity(0.38),
                      blurRadius: 18,
                    ),
                  Shadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _fallbackController,
              builder: (context, child) {
                final angle = _hasCompass
                    ? _needleRadians
                    : _fallbackController.value * 2 * math.pi;
                return Transform.rotate(
                  angle: angle,
                  child: Transform.translate(
                    offset: Offset(0, -size * 0.24),
                    child: child,
                  ),
                );
              },
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _isAligned ? 1 : 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: math.max(4, size * 0.014),
                      vertical: math.max(2, size * 0.008),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFE0B86D).withOpacity(0.65),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.32),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '🕋',
                      style: TextStyle(
                        fontSize: math.max(11, size * 0.05),
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: math.max(22, size * 0.14),
              height: math.max(22, size * 0.14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFF4D089),
                    Color(0xFFB8873D),
                    Color(0xFF6A4A20),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFF4E6CC).withOpacity(0.65),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isAligned
                        ? const Color(0xFF4ADE80).withOpacity(0.34)
                        : Colors.black.withOpacity(0.24),
                    blurRadius: _isAligned ? 20 : 14,
                    spreadRadius: _isAligned ? 2 : 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: math.max(12, size * 0.07),
                  height: math.max(12, size * 0.07),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0B141B),
                    border: Border.all(
                      color: const Color(0xFFF4D089).withOpacity(0.40),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size * 0.12,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: math.max(12, size * 0.05),
                  vertical: math.max(7, size * 0.025),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.86),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _isAligned
                        ? const Color(0xFF6EE7B7).withOpacity(0.75)
                        : const Color(0xFFE1BF84).withOpacity(0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAligned
                          ? Icons.check_circle_rounded
                          : Icons.explore_rounded,
                      size: math.max(12, size * 0.05),
                      color: _isAligned
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFC89B53),
                    ),
                    SizedBox(width: math.max(5, size * 0.018)),
                    Text(
                      _isAligned
                          ? 'KIBLE'
                          : AppLocalizations.translate('qibla', widget.locale)
                              .toUpperCase(),
                      style: TextStyle(
                        fontSize: math.max(10, size * 0.045),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: _isAligned
                            ? const Color(0xFF166534)
                            : const Color(0xFF7A5A28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.onTap != null) {
      compass = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: compass,
      );
    }

    return compass;
  }

  double _normalizeDegrees(double degrees) {
    var normalized = degrees % 360;
    if (normalized > 180) normalized -= 360;
    if (normalized < -180) normalized += 360;
    return normalized;
  }

  double _degToRad(double degrees) => degrees * math.pi / 180;

  double _round(double value) => double.parse(value.toStringAsFixed(1));
}

class QiblaFullScreen extends StatelessWidget {
  const QiblaFullScreen({
    Key? key,
    required this.locale,
    this.userLocation,
  }) : super(key: key);

  final String locale;
  final GeoLocation? userLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.10),
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Hero(
              tag: 'qiblaHero',
              createRectTween: (begin, end) =>
                  MaterialRectArcTween(begin: begin, end: end),
              child: Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F3EC),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: QiblaCompassWidget(
                  locale: locale,
                  userLocation: userLocation,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({
    required this.color,
    required this.accentColor,
    required this.isAligned,
  });

  final Color color;
  final Color accentColor;
  final bool isAligned;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF6E4D24),
          Color(0xFFE8C27A),
          Color(0xFF8C6330),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - ringPaint.strokeWidth / 2, ringPaint);

    final innerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.02
      ..color = (isAligned
              ? const Color(0xFF86EFAC)
              : const Color(0xFFF1D39A))
          .withOpacity(isAligned ? 0.34 : 0.18);
    canvas.drawCircle(center, radius * 0.92, innerGlowPaint);

    final guideRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.012
      ..color = color.withOpacity(0.10);
    canvas.drawCircle(center, radius * 0.68, guideRingPaint);
    canvas.drawCircle(center, radius * 0.82, guideRingPaint);

    for (int degree = 0; degree < 360; degree += 15) {
      final angle = (degree - 90) * math.pi / 180;
      final longMark = degree % 45 == 0;
      final startRadius = radius * (longMark ? 0.72 : 0.78);
      final endRadius = radius * 0.90;

      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );

      final markPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = longMark ? 2.4 : 1.2
        ..color = degree % 90 == 0
            ? const Color(0xFF4ADE80).withOpacity(isAligned ? 0.95 : 0.74)
            : degree == 0
                ? accentColor
                : color.withOpacity(longMark ? 0.72 : 0.24);

      canvas.drawLine(start, end, markPaint);
    }

    for (int degree = 0; degree < 360; degree += 30) {
      _drawDegreeLabel(canvas, center, radius, degree);
    }

    _drawLabel(canvas, center, radius, 'N', -90);
    _drawLabel(canvas, center, radius, 'E', 0);
    _drawLabel(canvas, center, radius, 'S', 90);
    _drawLabel(canvas, center, radius, 'W', 180);
  }

  void _drawDegreeLabel(
    Canvas canvas,
    Offset center,
    double radius,
    int degree,
  ) {
    final angle = (degree - 90) * math.pi / 180;
    final position = Offset(
      center.dx + radius * 0.80 * math.cos(angle),
      center.dy + radius * 0.80 * math.sin(angle),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: degree.toString(),
        style: TextStyle(
          color: color.withOpacity(0.52),
          fontWeight: FontWeight.w700,
          fontSize: math.max(8, radius * 0.07),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        position.dx - painter.width / 2,
        position.dy - painter.height / 2,
      ),
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String label,
    double degrees,
  ) {
    final angle = degrees * math.pi / 180;
    final position = Offset(
      center.dx + radius * 0.62 * math.cos(angle),
      center.dy + radius * 0.62 * math.sin(angle),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: label == 'N'
              ? (isAligned ? const Color(0xFF86EFAC) : const Color(0xFFF4E6CC))
              : color.withOpacity(0.78),
          fontWeight: label == 'N' ? FontWeight.w900 : FontWeight.w700,
          fontSize: label == 'N'
              ? math.max(12, radius * 0.17)
              : math.max(10, radius * 0.12),
          letterSpacing: label == 'N' ? 0.5 : 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        position.dx - painter.width / 2,
        position.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isAligned != isAligned;
  }
}
