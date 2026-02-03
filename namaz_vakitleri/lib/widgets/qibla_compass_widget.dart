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
  final double sensitivity; // degrees margin for alignment
  final Color? alignmentColor;
  final GeoLocation? userLocation; // User's location for accurate qibla calculation
  final Color? backgroundColor; // Main screen background color

  const QiblaCompassWidget({
    Key? key,
    required this.locale,
    this.startRotationDelay = const Duration(milliseconds: 700),
    this.onTap,
    this.sensitivity = 2.0, // 2 degrees sensitivity for alignment
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
  double _heading = 0.0; // radians
  bool _hasHeading = false;
  StreamSubscription<CompassEvent>? _compassSub;
  double _displayHeading = 0.0; // smoothed heading used for rendering
  late AnimationController _needleController;
  Animation<double>? _needleAnimation;
  GeoLocation? _deviceLocation;
  double? _qiblaBearingRad;
  bool _lastAligned = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Rotation controller only; scaling is handled by the Hero expansion
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOutCubic),
    );

    // Start rotation after the hero/expansion finishes
    Future.delayed(widget.startRotationDelay, () {
      // Try to listen to device compass. If there's no valid heading, fallback to animated rotation
      try {
        // Use provided userLocation or get current location
        if (widget.userLocation != null && mounted) {
          setState(() {
            _deviceLocation = widget.userLocation;
            _qiblaBearingRad = _computeQiblaBearing(widget.userLocation!.latitude, widget.userLocation!.longitude);
          });
        } else {
          // Fallback: get device location if not provided
          LocationService.getCurrentLocation().then((loc) {
            if (loc != null && mounted) {
              setState(() {
                _deviceLocation = loc;
                _qiblaBearingRad = _computeQiblaBearing(loc.latitude, loc.longitude);
              });
            }
          }).catchError((_) {});
        }

        _compassSub = FlutterCompass.events?.listen((event) {
          final hd = event.heading;
          if (hd != null) {
            if (mounted) {
              final headingRad = hd * (math.pi / 180);
              // compute desired needle angle: bearing - heading (if bearing available)
              final desired = _qiblaBearingRad != null ? _qiblaBearingRad! - headingRad : headingRad;
              final normalized = _normalizeAngle(desired);

              // Debug: print heading/bearing info to help verify correctness
              try {
                final headingDeg = (headingRad * 180 / math.pi).toStringAsFixed(2);
                final qiblaDeg = _qiblaBearingRad != null ? (_qiblaBearingRad! * 180 / math.pi).toStringAsFixed(2) : 'null';
                final desiredDeg = (desired * 180 / math.pi).toStringAsFixed(2);
                final normDeg = (normalized * 180 / math.pi).toStringAsFixed(2);
                debugPrint('Compass event: hd=$headingDeg°, qibla=$qiblaDeg°, desired=$desiredDeg°, normalized=$normDeg°');
              } catch (_) {}

              // animate smoothly to normalized target with small-deadzone smoothing
              if (mounted) {
                setState(() {
                  _hasHeading = true;
                });
                // only animate for meaningful jumps; otherwise apply light smoothing to reduce jitter
                final diff = _normalizeAngle(normalized - _displayHeading);
                final minMoveRad = 0.5 * (math.pi / 180.0); // 0.5 degrees
                if (diff.abs() < minMoveRad) {
                  // small jitter — nudge display heading slightly towards target
                  setState(() {
                    _displayHeading = _normalizeAngle(_displayHeading + diff * 0.22);
                  });
                } else {
                  _animateNeedleTo(normalized);
                }
                // ensure fallback spinner stops
                if (_rotationController.isAnimating) _rotationController.stop();
              }
            }
          }
        });
      } catch (e) {
        // ignore and fallback
      }

      if (!_hasHeading && mounted) {
        _rotationController.repeat();
      }
    });
  }

  // Provide haptic and audio feedback when Qibla is aligned
  Future<void> _provideAlignmentFeedback() async {
    try {
      // Check if vibration is available
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      final hasAmplitudeControl = await Vibration.hasAmplitudeControl() ?? false;
      
      if (hasVibrator) {
        if (hasAmplitudeControl) {
          // Strong vibration pattern for alignment
          await Vibration.vibrate(
            pattern: [0, 100, 50, 100, 50, 200],
            intensities: [0, 128, 0, 255, 0, 128],
          );
        } else {
          // Simple vibration for devices without amplitude control
          await Vibration.vibrate(duration: 500);
        }
      }
      
      // Note: Audio feedback could be added here if desired
      // For now, the visual lantern effect provides sufficient feedback
      
    } catch (e) {
      // Silently fail if vibration is not available or fails
      debugPrint('Haptic feedback not available: $e');
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _compassSub?.cancel();
    _scaleController.dispose();
    _needleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRTL = AppLocalizations.isRTL(widget.locale);

    // Build a compact compass with a rotating needle
    final compassSize = 140.0;

    return LayoutBuilder(builder: (context, constraints) {
      // Determine a size that fits the incoming Hero constraints to avoid overflow
        double maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : compassSize;
        double maxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
          ? constraints.maxHeight
          : compassSize;

        // Choose a square size that fits both width and height constraints.
        final size = math.min(math.min(maxWidth, maxHeight), compassSize);

        // Show the label only when there's enough vertical space for compass + label.
        final labelHeightEstimate = 28.0; // spacing + text
        final showLabel = size >= 120 && (!constraints.maxHeight.isFinite || constraints.maxHeight >= size + labelHeightEstimate);

        // Determine alignment state with higher precision: when needle is very close to zero angle
        final sensitivityRad = 1.0 * (math.pi / 180.0); // 1 degree sensitivity for high accuracy
        final aligned = _hasHeading && (_normalizeAngle(_displayHeading).abs() < sensitivityRad);
        final alignColor = widget.alignmentColor ?? (isDark ? AppColors.darkAccentMint : AppColors.accentMint);
        
        // Check if alignment state changed for haptic feedback
        if (aligned != _lastAligned && mounted) {
          setState(() {
            _lastAligned = aligned;
          });
          
          // Provide haptic feedback when alignment is achieved
          if (aligned) {
            _provideAlignmentFeedback();
            debugPrint('🎯 QIBLA ALIGNED! Perfect direction found.');
          }
        }
        
        // Debug: Print qibla accuracy info
        if (_qiblaBearingRad != null && _hasHeading) {
          final headingDeg = (_displayHeading * 180 / math.pi).toStringAsFixed(1);
          final qiblaDeg = (_qiblaBearingRad! * 180 / math.pi).toStringAsFixed(1);
          final diffDeg = (_normalizeAngle(_displayHeading) * 180 / math.pi).toStringAsFixed(1);
          print('🧭 Qibla Debug: Heading=$headingDeg°, Qibla=$qiblaDeg°, Diff=$diffDeg°, Aligned=$aligned');
          
          // Print location if available
          if (_deviceLocation != null) {
            print('📍 Location: ${_deviceLocation!.latitude}, ${_deviceLocation!.longitude}');
          }
        }
      // Wrap with scale animation when used as a tappable, full-screen element
      Widget content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bezel / subtle background gradient
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.2),
                      ],
                      center: Alignment(-0.2, -0.2),
                      radius: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                // Static compass marks
                CustomPaint(
                  size: Size.square(size),
                  painter: CompassPainter(isDark: isDark),
                ),

                // Rotating needle with enhanced alignment effects
                AnimatedBuilder(
                  animation: Listenable.merge([_rotationController, _needleController]),
                  builder: (context, child) {
                    // Use smoothed display heading when available, otherwise fallback to spinning animation
                    final angle = _hasHeading ? _displayHeading : _rotationAnimation.value;
                    return Transform.rotate(
                      angle: angle,
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Glowing background effect when aligned (lantern effect)
                      if (aligned)
                        Container(
                          width: size * 0.25,
                          height: size * 0.65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.0),
                              ],
                              center: Alignment.topCenter,
                              radius: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      
                      // Main needle
                      SizedBox(
                        width: size * 0.16,
                        height: size * 0.56,
                        child: CustomPaint(
                          painter: NeedlePainter(
                            color: Colors.black,
                            isAligned: aligned,
                          ),
                        ),
                      ),
                      
                      // Pulsing light effect at needle tip when aligned
                      if (aligned)
                        Positioned(
                          top: 0,
                          child: AnimatedBuilder(
                            animation: _scaleController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.8),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Center Kaaba dot (subtle)
                Container(
                  width: math.max(12, size * 0.12),
                  height: math.max(12, size * 0.12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                // Alignment check indicator (top-right)
                Positioned(
                  top: math.max(6, size * 0.05),
                  right: math.max(6, size * 0.05),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.black,
                    size: math.max(18, size * 0.12),
                  ),
                ),
              ],
            ),
          ),
          if (showLabel) SizedBox(height: AppSpacing.sm),
          if (showLabel)
            Text(
              AppLocalizations.translate('qibla', widget.locale),
              style: AppTypography.h3.copyWith(color: AppColors.accentPrimary),
            ),
        ],
      );

      if (widget.onTap != null) {
        content = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            // Play shrink animation, animate needle back gently, then call onTap to close (Hero will reverse)
            try {
              await _scaleController.forward();
            } catch (_) {}
            // animate needle back to neutral (0) so closing feels smooth
            try {
              await _animateNeedleToAndWait(0.0, timeout: const Duration(milliseconds: 600));
            } catch (_) {}
            widget.onTap?.call();
            // reset scale for next show
            _scaleController.reset();
          },
          child: AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              return Transform.scale(scale: _scaleAnimation.value, child: child);
            },
            child: content,
          ),
        );
      }

      return content;
    });
  }

  Future<void> _animateNeedleToAndWait(double target, {Duration? timeout}) async {
    if (!mounted) return;
    final completer = Completer<void>();
    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (!completer.isCompleted) completer.complete();
        _needleController.removeStatusListener(statusListener);
      }
    }

    _needleController.addStatusListener(statusListener);
    _animateNeedleTo(target);
    try {
      await completer.future.timeout(timeout ?? const Duration(milliseconds: 600));
    } catch (_) {
      // ignore timeout
    }
  }

  double _normalizeAngle(double angle) {
    // Normalize to -pi..pi
    var a = angle % (2 * math.pi);
    if (a > math.pi) a -= 2 * math.pi;
    if (a <= -math.pi) a += 2 * math.pi;
    return a;
  }

  void _animateNeedleTo(double target) {
    // Ensure both current and target use shortest path
    final current = _displayHeading;
    var delta = target - current;
    // wrap to -pi..pi
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    final end = current + delta;

    _needleAnimation?.removeListener(_needleListener);
    _needleAnimation = Tween<double>(begin: current, end: end).animate(CurvedAnimation(parent: _needleController, curve: Curves.easeInOut));
    _needleAnimation!.addListener(_needleListener);
    _needleController.reset();
    _needleController.forward();
    // stop fallback spinner while animating to real heading
    if (_rotationController.isAnimating) _rotationController.stop();
  }

  void _needleListener() {
    setState(() {
      _displayHeading = _needleAnimation?.value ?? _displayHeading;
    });
  }

  // Compute initial bearing from (lat1, lon1) to Kaaba using adhan library for high accuracy
  double _computeQiblaBearing(double lat1Deg, double lon1Deg) {
    try {
      final coordinates = Coordinates(lat1Deg, lon1Deg);
      final qibla = Qibla(coordinates);
      
      // adhan returns direction in degrees (0-360), convert to radians
      final bearingDeg = qibla.direction;
      final bearingRad = bearingDeg * math.pi / 180.0;
      
      // Debug: print accurate qibla calculation
      debugPrint('Adhan Qibla calculation: ${bearingDeg.toStringAsFixed(2)}° from (${lat1Deg.toStringAsFixed(4)}, ${lon1Deg.toStringAsFixed(4)})');
      
      return bearingRad;
    } catch (e) {
      // Fallback to manual calculation if adhan fails
      debugPrint('Adhan Qibla calculation failed, using fallback: $e');
      return _computeQiblaBearingFallback(lat1Deg, lon1Deg);
    }
  }

  // Fallback manual calculation (original implementation)
  double _computeQiblaBearingFallback(double lat1Deg, double lon1Deg) {
    // Kaaba coordinates (Mecca)
    const lat2Deg = 21.422487; // degrees
    const lon2Deg = 39.826206; // degrees

    final lat1 = lat1Deg * math.pi / 180.0;
    final lon1 = lon1Deg * math.pi / 180.0;
    final lat2 = lat2Deg * math.pi / 180.0;
    final lon2 = lon2Deg * math.pi / 180.0;

    final dLon = lon2 - lon1;
    final x = math.sin(dLon) * math.cos(lat2);
    final y = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(x, y); // radians
    // normalize to 0..2pi
    final bearingNorm = (bearing + 2 * math.pi) % (2 * math.pi);
    return bearingNorm;
  }
}

/// Fullscreen wrapper that participates in a Hero shared element
class QiblaFullScreen extends StatelessWidget {
  final String locale;
  final GeoLocation? userLocation;

  const QiblaFullScreen({
    Key? key,
    required this.locale,
    this.userLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // No dark backdrop — keep background visible so only compass appears
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              color: Colors.transparent,
            ),
          ),

          // Shared element Hero - the icon expands into a compact top-right panel
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              // moved slightly higher and more to the right
              padding: const EdgeInsets.only(top: 48.0, right: 12.0),
              child: Hero(
                tag: 'qiblaHero',
                createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
                child: Container(
                  width: 150,
                  height: 150,
                  alignment: Alignment.center,
                  child: QiblaCompassWidget(
                    locale: locale,
                    userLocation: userLocation,
                    startRotationDelay: const Duration(milliseconds: 420),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),

          // No explicit close button — tap the compass to close
        ],
      ),
    );
  }
}

/// Custom painter for compass marks
class CompassPainter extends CustomPainter {
  final bool isDark;

  CompassPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw degree marks
    for (int i = 0; i < 360; i += 10) {
      final angle = (i - 90) * math.pi / 180;
      final startRadius = radius - 20;
      final endRadius = i % 30 == 0 ? radius - 8 : radius - 12;

      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );

      final paint = Paint()
        ..color = (i % 30 == 0
                ? Colors.black
                : Colors.black.withOpacity(0.3))
        ..strokeWidth = i % 30 == 0 ? 2 : 1;

      canvas.drawLine(start, end, paint);
    }

    // Draw decorative circles
    final circlePaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius * 0.7, circlePaint);
    canvas.drawCircle(center, radius * 0.4, circlePaint);

    // Outer bezel / frame
    final bezelPaint = Paint()
      ..color = Colors.black.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, radius * 0.06);
    canvas.drawCircle(center, radius - (bezelPaint.strokeWidth / 2), bezelPaint);

    // Draw 'N' label at top
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.black,
          fontSize: math.max(10, radius * 0.12),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final tpOffset = Offset(center.dx - textPainter.width / 2, center.dy - radius + 6);
    textPainter.paint(canvas, tpOffset);
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) => false;
}

class NeedlePainter extends CustomPainter {
  final Color color;
  final bool isAligned;

  NeedlePainter({required this.color, this.isAligned = false});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    
    // Enhanced gradient for aligned state
    final colors = isAligned 
      ? [color, color.withOpacity(0.95), color.withOpacity(0.85)]
      : [color, color.withOpacity(0.85)];
    
    final stops = isAligned ? [0.0, 0.7, 1.0] : [0.0, 1.0];
    
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX, 0),
        Offset(centerX, size.height),
        colors,
        stops,
      )
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path path = Path();
    // pointed triangle
    path.moveTo(centerX, 0);
    path.lineTo(size.width * 0.92, size.height * 0.88);
    path.lineTo(size.width * 0.08, size.height * 0.88);
    path.close();

    // Enhanced shadow for aligned state
    final shadowOpacity = isAligned ? 0.25 : 0.18;
    final shadowBlur = isAligned ? 8.0 : 6.0;
    
    canvas.drawShadow(path, Colors.black.withOpacity(shadowOpacity), shadowBlur, true);
    canvas.drawPath(path, paint);
    
    // Add inner glow effect when aligned
    if (isAligned) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, 3.0);
      
      canvas.drawPath(path, glowPaint);
    }

    // small highlight
    final highlight = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final Path h = Path();
    h.moveTo(centerX, size.height * 0.06);
    h.lineTo(size.width * 0.7, size.height * 0.76);
    h.lineTo(size.width * 0.3, size.height * 0.76);
    h.close();
    canvas.drawPath(h, highlight);
  }

  @override
  bool shouldRepaint(covariant NeedlePainter oldDelegate) => color != oldDelegate.color;
}
