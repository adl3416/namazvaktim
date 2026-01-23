import 'package:flutter/material.dart';
import 'package:namaz_vakitleri/config/color_system.dart';
import 'dart:math' as math;

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
  // Kaaba coordinates (Mecca)
  static const double kabaaLatitude = 21.422487;
  static const double kabaaLongitude = 39.826206;

  /// Calculate qibla direction (bearing) from a location
  /// Returns angle in radians (0 to 2π)
  static double calculateQiblaDirection(
    double userLatitude,
    double userLongitude,
  ) {
    final lat1 = userLatitude * math.pi / 180.0;
    final lon1 = userLongitude * math.pi / 180.0;
    final lat2 = kabaaLatitude * math.pi / 180.0;
    final lon2 = kabaaLongitude * math.pi / 180.0;

    final dLon = lon2 - lon1;
    final x = math.sin(dLon) * math.cos(lat2);
    final y = math.cos(lat1) * math.sin(lat2) - 
              math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    
    final bearing = math.atan2(x, y); // radians
    // Normalize to 0..2π
    final bearingNorm = (bearing + 2 * math.pi) % (2 * math.pi);
    
    return bearingNorm;
  }

  /// Convert radians to degrees
  static double radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  /// Convert degrees to radians
  static double degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
