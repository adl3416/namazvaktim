import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import 'package:namaz_vakitleri/services/location_service.dart';
import 'package:namaz_vakitleri/models/prayer_model.dart';
import 'package:namaz_vakitleri/config/color_system.dart';
import 'package:namaz_vakitleri/config/localization.dart';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:vibration/vibration.dart';

class QiblaCompassWidget extends StatefulWidget {
  final String locale;
  final Duration startRotationDelay;
  final VoidCallback? onTap;
  final double sensitivity;
  final Color? alignmentColor;
  final GeoLocation? userLocation;
  final Color? backgroundColor;

  const QiblaCompassWidget({
    Key? key,
    required this.locale,
    this.startRotationDelay = const Duration(milliseconds: 700),
    this.onTap,
    this.sensitivity = 0.8,
    this.alignmentColor,
    this.userLocation,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late AnimationController _pulseController;
  bool _hasHeading = false;
  StreamSubscription<CompassEvent>? _compassSub;
  double _smoothedHeading = 0.0;
  GeoLocation? _deviceLocation;
  double? _qiblaBearing;
  bool _isAligned = false;
  bool _wasAlignedBefore = false;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationAnimation =
        Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.linear),
        );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _initializeCompass();
  }

  Future<void> _initializeCompass() async {
    await Future.delayed(widget.startRotationDelay);

    if (!mounted) return;

    // Get location
    try {
      if (widget.userLocation != null) {
        _deviceLocation = widget.userLocation;
      } else {
        _deviceLocation = await LocationService.getCurrentLocation();
      }

      if (_deviceLocation != null && mounted) {
        // Calculate Qibla bearing using Adhan library
        final coordinates = Coordinates(
          _deviceLocation!.latitude,
          _deviceLocation!.longitude,
        );
        _qiblaBearing = Qibla(coordinates).direction;

        setState(() {});
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    // Listen to compass
    try {
      _compassSub = FlutterCompass.events?.listen((event) {
        if (!mounted) return;

        final heading = event.heading;
        if (heading != null) {
          // Smooth the heading with low-pass filter
          const alpha = 0.15;
          _smoothedHeading =
              alpha * heading + (1 - alpha) * _smoothedHeading;

          setState(() {
            _hasHeading = true;
          });

          if (_rotationController.isAnimating) {
            _rotationController.stop();
          }

          // Check alignment
          _checkAlignment();
        }
      });

      if (!_hasHeading) {
        _rotationController.repeat();
      }
    } catch (e) {
      debugPrint('Compass error: $e');
      _rotationController.repeat();
    }
  }

  void _checkAlignment() {
    if (_qiblaBearing == null || !_hasHeading) return;

    // Calculate angle difference
    double diff = _smoothedHeading - _qiblaBearing!;
    diff = ((diff + 180) % 360) - 180; // Normalize to -180 to 180
    if (diff < 0) diff += 360;
    diff = math.min(diff, 360 - diff); // Get minimum angle

    final sensitivityDegrees = widget.sensitivity;
    final aligned = diff <= sensitivityDegrees;

    if (aligned && !_wasAlignedBefore) {
      // Just aligned
      _provideAlignmentFeedback();
      if (_pulseController.isCompleted || _pulseController.isDismissed) {
        _pulseController.forward(from: 0.0);
      }
    }

    setState(() {
      _isAligned = aligned;
      _wasAlignedBefore = aligned;
    });
  }

  Future<void> _provideAlignmentFeedback() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(
          pattern: [0, 100, 50, 100],
          intensities: [0, 200, 0, 200],
        );
      }
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  double get _displayHeading => _hasHeading ? _smoothedHeading : 0.0;

  double get _needleAngle {
    if (!_hasHeading || _qiblaBearing == null) {
      return _rotationAnimation.value;
    }

    // Calculate angle from device heading to Qibla bearing
    double angle = _displayHeading - _qiblaBearing!;
    return (angle * math.pi / 180.0);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compassSize = 180.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compass Circle
          SizedBox(
            width: compassSize,
            height: compassSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring with gradient
                Container(
                  width: compassSize,
                  height: compassSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        isDark ? Colors.grey[800]! : Colors.grey[100]!,
                        isDark ? Colors.grey[900]! : Colors.grey[200]!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Compass markings
                CustomPaint(
                  size: Size.square(compassSize),
                  painter: _CompassPainter(isDark: isDark),
                ),

                // Pulse effect when aligned
                if (_isAligned)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final progress = _pulseController.value;
                      return Container(
                        width: compassSize * (0.7 + 0.3 * progress),
                        height: compassSize * (0.7 + 0.3 * progress),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4CAF50)
                                .withValues(alpha: 0.5 * (1 - progress)),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),

                // Rotating needle
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _rotationController,
                    _pulseController,
                  ]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _needleAngle,
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Qibla arrow (top)
                      Container(
                        width: 8,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isAligned
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: (_isAligned
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF2196F3))
                                  .withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Center point
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAligned
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2196F3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      // Counter-weight (bottom)
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Status text
          if (_qiblaBearing != null)
            Column(
              children: [
                if (_isAligned)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: const Color(0xFF4CAF50), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Kibe doğru!',
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mükemmel yön bulundu',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else if (_hasHeading)
                  Column(
                    children: [
                      Text(
                        'Kibeye dön',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cihazınızı döndürerek kibleyi bulun',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Pusula başlatılıyor...',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),

          // Location info
          if (_deviceLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '📍 Konum: ${_deviceLocation!.latitude.toStringAsFixed(3)}°, ${_deviceLocation!.longitude.toStringAsFixed(3)}°',
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final bool isDark;

  _CompassPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final double radius = (size.width / 2 - 10).toDouble();

    // Draw degree marks
    for (int i = 0; i < 360; i += 10) {
      final angle = (i - 90) * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final isIntercardinal = i % 45 == 0;

      final markLength = isCardinal ? 20.0 : (isIntercardinal ? 15.0 : 8.0);
      final markWidth = isCardinal ? 2.5 : (isIntercardinal ? 2.0 : 1.0);

      final startX = (centerX + (radius - markLength) * math.cos(angle)).toDouble();
      final startY = (centerY + (radius - markLength) * math.sin(angle)).toDouble();
      final endX = (centerX + radius * math.cos(angle)).toDouble();
      final endY = (centerY + radius * math.sin(angle)).toDouble();

      final paint = Paint()
        ..color = isDark ? Colors.grey[400]! : Colors.grey[600]!
        ..strokeWidth = markWidth;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Draw cardinal directions
    const directions = [
      ('N', 0.0),
      ('E', 90.0),
      ('S', 180.0),
      ('W', 270.0),
    ];

    for (final (label, angle) in directions) {
      final rad = (angle - 90) * math.pi / 180;
      final x = (centerX + (radius - 35) * math.cos(rad)).toDouble();
      final y = (centerY + (radius - 35) * math.sin(rad)).toDouble();

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Center circle
    final centerPaint = Paint()
      ..color = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    canvas.drawCircle(Offset(centerX, centerY), 6, centerPaint);
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
