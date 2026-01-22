import 'package:flutter/material.dart';
import 'package:namaz_vakitleri/config/color_system.dart';

/// Qibla Compass - Shows direction to Mecca
class QiblaCompass extends StatelessWidget {
  final double qiblaDirection; // 0-360 degrees
  final double deviceHeading;  // 0-360 degrees
  final bool isDark;

  const QiblaCompass({
    Key? key,
    required this.qiblaDirection,
    required this.deviceHeading,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the angle between device heading and qibla
    final angleDifference = _normalizeAngle(qiblaDirection - deviceHeading);

    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Compass circle background
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkBgSecondary.withOpacity(0.3)
                    : AppColors.lightBgSecondary.withOpacity(0.3),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkTextLight.withOpacity(0.3)
                      : AppColors.textLight.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),

            // Cardinal directions
            Positioned(
              top: 20,
              child: Text(
                'N',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Positioned(
              right: 20,
              child: Text(
                'E',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              child: Text(
                'S',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Positioned(
              left: 20,
              child: Text(
                'W',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Device heading indicator (North pointer)
            Positioned(
              top: 15,
              child: Container(
                width: 8,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Qibla needle (rotates to show direction)
            Transform.rotate(
              angle: (angleDifference * 3.14159 / 180),
              child: Positioned(
                top: 50,
                child: Container(
                  width: 6,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark
                            ? AppColors.darkAccentPrimary
                            : AppColors.accentPrimary,
                        isDark
                            ? AppColors.darkAccentSecondary
                            : AppColors.accentSecondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Center circle
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkAccentPrimary
                    : AppColors.accentPrimary,
              ),
              child: Icon(
                Icons.location_on,
                size: 16,
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
              ),
            ),

            // Direction display
            Positioned(
              bottom: 40,
              child: Column(
                children: [
                  Text(
                    '${angleDifference.toStringAsFixed(1)}°',
                    style: AppTypography.h2.copyWith(
                      color: isDark
                          ? AppColors.darkAccentPrimary
                          : AppColors.accentPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    _getDirectionName(angleDifference),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Normalize angle to 0-360 range
  double _normalizeAngle(double angle) {
    while (angle < 0) {
      angle += 360;
    }
    while (angle >= 360) {
      angle -= 360;
    }
    return angle;
  }

  // Get readable direction name
  String _getDirectionName(double angle) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((angle + 11.25) / 22.5).toInt() % 16;
    return directions[index];
  }
}

/// Calculate qibla direction for a given location
class QiblaCalculator {
  // Kaaba coordinates
  static const double kabaaLatitude = 21.4225;
  static const double kabaaLongitude = 39.8262;
  static const double pi = 3.14159265359;

  /// Calculate qibla direction (bearing) from a location
  /// Returns angle in degrees (0-360)
  static double calculateQiblaDirection(
    double userLatitude,
    double userLongitude,
  ) {
    final latitude1 = userLatitude * pi / 180;
    final longitude1 = userLongitude * pi / 180;
    final latitude2 = kabaaLatitude * pi / 180;
    final longitude2 = kabaaLongitude * pi / 180;

    final dLongitude = longitude2 - longitude1;

    final x = _sin(dLongitude) * _cos(latitude2);
    final y = _cos(latitude1) * _sin(latitude2) -
        _sin(latitude1) * _cos(latitude2) * _cos(dLongitude);

    var bearing = _atan2(x, y) * 180 / pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  // Simple sin calculation
  static double _sin(double angle) {
    final x = angle;
    return x -
        (x * x * x) / 6 +
        (x * x * x * x * x) / 120 -
        (x * x * x * x * x * x * x) / 5040;
  }

  // Simple cos calculation
  static double _cos(double angle) {
    final x = angle;
    return 1 - (x * x) / 2 + (x * x * x * x) / 24 - (x * x * x * x * x * x) / 720;
  }

  // Simple atan2 calculation
  static double _atan2(double y, double x) {
    if (x > 0) {
      return _atan(y / x);
    } else if (x < 0 && y >= 0) {
      return _atan(y / x) + pi;
    } else if (x < 0 && y < 0) {
      return _atan(y / x) - pi;
    } else if (x == 0 && y > 0) {
      return pi / 2;
    } else if (x == 0 && y < 0) {
      return -pi / 2;
    }
    return 0;
  }

  // Simple atan calculation (Taylor series)
  static double _atan(double x) {
    final x2 = x * x;
    final x3 = x2 * x;
    final x5 = x3 * x2;
    final x7 = x5 * x2;
    return x - x3 / 3 + x5 / 5 - x7 / 7;
  }
}
