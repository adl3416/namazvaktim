import 'package:flutter/material.dart';
import '../../config/color_system.dart';
import '../../config/localization.dart';

class SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final bool isLoading;
  final String locale;

  const SoftButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.isLoading = false,
    required this.locale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: width ?? double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark
                  ? AppColors.darkBgSecondary.withOpacity(0.5)
                  : AppColors.lightBgSecondary.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: (isDark
                    ? AppColors.darkTextLight
                    : AppColors.textLight)
                .withOpacity(AppOpacity.veryLow),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ??
                        (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
                  ),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor ??
                      (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class SoftIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final bool showBackground;

  const SoftIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.showBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (showBackground) {
      return Container(
        decoration: BoxDecoration(
          color: (isDark
                  ? AppColors.darkBgSecondary
                  : AppColors.lightBgSecondary)
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color ??
              (isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary),
          iconSize: size,
        ),
      );
    }

    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: color ??
          (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      iconSize: size,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    );
  }
}

class PrayerTimeRow extends StatelessWidget {
  final String prayerName;
  final String prayerTime;
  final bool isActive;
  final String locale;

  const PrayerTimeRow({
    Key? key,
    required this.prayerName,
    required this.prayerTime,
    required this.isActive,
    required this.locale,
  }) : super(key: key);

  // Get color intensity based on prayer type
  Color _getPrayerTimeColor(String prayerName, bool isDark) {
    // Prayer times get progressively darker throughout the day
    // Sabah (Fajr) - Light
    // Öğle (Dhuhr) - Medium Light
    // İkindi (Asr) - Medium Dark
    // Akşam (Maghrib) - Dark
    // Yatsı (Isha) - Darkest
    
    final baseColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    final name = prayerName.toLowerCase();
    
    if (name.contains('fajr') || name.contains('sabah')) {
      // Lightest - 35% opacity
      return baseColor.withOpacity(isDark ? 0.35 : 0.25);
    } else if (name.contains('dhuhr') || name.contains('öğle')) {
      // Light - 45% opacity
      return baseColor.withOpacity(isDark ? 0.50 : 0.35);
    } else if (name.contains('asr') || name.contains('ikindi')) {
      // Medium - 60% opacity
      return baseColor.withOpacity(isDark ? 0.65 : 0.50);
    } else if (name.contains('maghrib') || name.contains('akşam')) {
      // Dark - 75% opacity
      return baseColor.withOpacity(isDark ? 0.80 : 0.65);
    } else if (name.contains('isha') || name.contains('yatsı')) {
      // Darkest - 90% opacity
      return baseColor.withOpacity(isDark ? 0.95 : 0.80);
    }
    
    // Default
    return baseColor.withOpacity(isDark ? 0.70 : 0.60);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pattern background using dots
    final patternPaint = Paint()
      ..color = (isDark
              ? AppColors.darkTextPrimary
              : AppColors.textPrimary)
          .withOpacity(0.05)
      ..strokeWidth = 1;

    final timeColor = _getPrayerTimeColor(prayerName, isDark);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg + 4,
      ),
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark
                ? AppColors.accentPrimary.withOpacity(0.2)
                : AppColors.accentPrimary.withOpacity(0.12))
            : (isDark
                ? AppColors.darkBgSecondary.withOpacity(0.4)
                : AppColors.lightBgSecondary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: DottedPatternPainter(
                color: (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary)
                    .withOpacity(0.04),
              ),
            ),
          ),
          // Content
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Prayer name
              Expanded(
                child: Text(
                  AppLocalizations.translate(
                    prayerName.toLowerCase(),
                    locale,
                  ),
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              // Prayer time - color-coded background
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 4,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: timeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  prayerTime,
                  style: AppTypography.bodyLarge.copyWith(
                    color: timeColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dotted pattern background
class DottedPatternPainter extends CustomPainter {
  final Color color;

  DottedPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 12.0;
    const dotRadius = 0.8;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DottedPatternPainter oldDelegate) => false;
}

class CountdownDisplay extends StatelessWidget {
  final Duration? countdown;
  final String locale;

  const CountdownDisplay({
    Key? key,
    required this.countdown,
    required this.locale,
  }) : super(key: key);

  String _formatCountdown() {
    if (countdown == null) return '0 ${AppLocalizations.translate('hour', locale)}';

    final hours = countdown!.inHours;
    final minutes = countdown!.inMinutes.remainder(60);
    final seconds = countdown!.inSeconds.remainder(60);

    final hourLabel = AppLocalizations.translate('hour', locale);
    final minuteLabel = AppLocalizations.translate('minute', locale);
    final secondLabel = AppLocalizations.translate('second', locale);

    if (hours > 0) {
      return '$hours $hourLabel ${minutes.toString().padLeft(2, '0')} $minuteLabel';
    }

    return '$minutes $minuteLabel ${seconds.toString().padLeft(2, '0')} $secondLabel';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatCountdown(),
          style: AppTypography.countdownLarge.copyWith(
            // Slightly reduce the displayed countdown font without changing global style
            fontSize: 50,
            color: isDark
                ? AppColors.darkAccentPrimary
                : AppColors.accentPrimary,
          ),
        ),
      ],
    );
  }
}
