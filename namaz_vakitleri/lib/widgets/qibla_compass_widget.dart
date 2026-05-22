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
  }) : super(key: key);

  final String locale;
  final Duration startRotationDelay;
  final VoidCallback? onTap;
  final double sensitivity;
  final Color? alignmentColor;
  final GeoLocation? userLocation;
  final Color? backgroundColor;
  final ValueChanged<QiblaTelemetry>? onTelemetry;

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
    if (!aligned || _vibrationCooldown) return;
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
    final bg = widget.backgroundColor ?? const Color(0xFFF8F3EC);

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
                    Color.lerp(bg, Colors.black, 0.05) ?? bg,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size.square(size),
              painter: _CompassDialPainter(
                color: const Color(0xFF2E2924),
                accentColor: accent,
                isAligned: _isAligned,
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
                size: size * 0.42,
                color: _isAligned ? accent : const Color(0xFF204B43),
              ),
            ),
            Container(
              width: math.max(16, size * 0.09),
              height: math.max(16, size * 0.09),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF201A16),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            Positioned(
              bottom: size * 0.16,
              child: Text(
                _isAligned ? 'Kible' : AppLocalizations.translate('qibla', widget.locale),
                style: TextStyle(
                  fontSize: math.max(12, size * 0.06),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF204B43),
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
      ..strokeWidth = radius * 0.08
      ..color = color.withOpacity(0.10);
    canvas.drawCircle(center, radius - ringPaint.strokeWidth / 2, ringPaint);

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
        ..color = degree == 0 && isAligned
            ? accentColor
            : color.withOpacity(longMark ? 0.85 : 0.35);

      canvas.drawLine(start, end, markPaint);
    }

    _drawLabel(canvas, center, radius, 'N', -90);
    _drawLabel(canvas, center, radius, 'E', 0);
    _drawLabel(canvas, center, radius, 'S', 90);
    _drawLabel(canvas, center, radius, 'W', 180);
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
          color: color.withOpacity(0.85),
          fontWeight: FontWeight.w800,
          fontSize: math.max(12, radius * 0.16),
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
