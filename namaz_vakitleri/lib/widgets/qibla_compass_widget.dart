import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import '../config/color_system.dart';
import '../config/localization.dart';
import 'dart:math' as math;

class QiblaCompassWidget extends StatefulWidget {
  final String locale;
  final Duration startRotationDelay;

  const QiblaCompassWidget({
    Key? key,
    required this.locale,
    this.startRotationDelay = const Duration(milliseconds: 700),
  }) : super(key: key);

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  double _heading = 0.0; // radians
  bool _hasHeading = false;
  StreamSubscription<CompassEvent>? _compassSub;

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

    // Start rotation after the hero/expansion finishes
    Future.delayed(widget.startRotationDelay, () {
      // Try to listen to device compass. If there's no valid heading, fallback to animated rotation
      try {
        _compassSub = FlutterCompass.events?.listen((event) {
          final hd = event.heading;
          if (hd != null) {
            if (mounted) {
              setState(() {
                _hasHeading = true;
                // convert degrees to radians and invert so needle points to qibla direction
                _heading = (hd) * (math.pi / 180);
              });
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

  @override
  void dispose() {
    _rotationController.dispose();
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRTL = AppLocalizations.isRTL(widget.locale);

    // Build a compact compass with a rotating needle
    final compassSize = 160.0;

    return LayoutBuilder(builder: (context, constraints) {
      // Determine a size that fits the incoming Hero constraints to avoid overflow
      double maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : compassSize;
      final size = math.min(maxWidth, compassSize);
      final showLabel = size >= 120;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Static compass marks
                CustomPaint(
                  size: Size.square(size),
                  painter: CompassPainter(isDark: isDark),
                ),

                // Rotating needle
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    final angle = _hasHeading ? -_heading : _rotationAnimation.value;
                    return Transform.rotate(
                      angle: angle,
                      child: child,
                    );
                  },
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: math.max(4, size * 0.04),
                      height: size * 0.42,
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPrimary.withOpacity(0.45),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center Kaaba dot
                Container(
                  width: math.max(20, size * 0.22),
                  height: math.max(20, size * 0.22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentPrimary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPrimary.withOpacity(0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(child: Text('🕌', style: TextStyle(fontSize: math.max(10, size * 0.09)))),
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
    });
  }
}

/// Fullscreen wrapper that participates in a Hero shared element
class QiblaFullScreen extends StatelessWidget {
  final String locale;

  const QiblaFullScreen({Key? key, required this.locale}) : super(key: key);

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
              padding: const EdgeInsets.only(top: 64.0, right: 20.0),
              child: Hero(
                tag: 'qiblaHero',
                createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                  child: Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  child: QiblaCompassWidget(locale: locale, startRotationDelay: const Duration(milliseconds: 420)),
                ),
              ),
            ),
          ),

          // Close button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: AppColors.accentPrimary),
                  ),
                ),
              ),
            ),
          ),
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
                ? AppColors.accentPrimary
                : AppColors.accentPrimary.withOpacity(0.3))
        ..strokeWidth = i % 30 == 0 ? 2 : 1;

      canvas.drawLine(start, end, paint);
    }

    // Draw decorative circles
    final circlePaint = Paint()
      ..color = AppColors.accentPrimary.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius * 0.7, circlePaint);
    canvas.drawCircle(center, radius * 0.4, circlePaint);
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) => false;
}
