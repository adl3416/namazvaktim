import 'package:flutter/material.dart';
import 'package:namaz_vakitleri/config/color_system.dart';
import 'package:namaz_vakitleri/config/localization.dart';

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
    // All prayers use the same text color for professional appearance
    return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  }
  
  // Get background color for prayer container
  Color _getPrayerBackgroundColor(String prayerName, bool isDark) {
    final name = prayerName.toLowerCase();

    // Light colors for background - prayer specific backgrounds
    const fajrBg = Color(0xFFD6EAF8); // İmsak
    const sunriseBg = Color(0xFFAED6F1); // Güneş
    const dhuhrBg = Color(0xFF5DADE2); // Öğle
    const asrBg = Color(0xFF3498DB); // İkindi
    const maghribBg = Color(0xFF2E86C1); // Akşam
    const ishaBg = Color(0xFF1B4F72); // Yatsı

    if (name.contains('fajr') || name.contains('sabah') || name.contains('imsak')) return fajrBg;
    if (name.contains('sunrise') || name.contains('gunes') || name.contains('güneş')) return sunriseBg;
    if (name.contains('dhuhr') || name.contains('öğle')) return dhuhrBg;
    if (name.contains('asr') || name.contains('ikindi')) return asrBg;
    if (name.contains('maghrib') || name.contains('akşam')) return maghribBg;
    if (name.contains('isha') || name.contains('yatsı')) return ishaBg;

    return isDark ? AppColors.darkBg : AppColors.lightBg;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final timeColor = _getPrayerTimeColor(prayerName, isDark);
    final bgColor = _getPrayerBackgroundColor(prayerName, isDark);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl + 4,
        vertical: AppSpacing.md,
      ),
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        // Transparent so the card blends with the parent background
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          // (pattern overlay removed per user request)
          // Content
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Prayer name
              Text(
                AppLocalizations.translate(
                  prayerName.toLowerCase(),
                  locale,
                ),
                style: AppTypography.bodyLarge.copyWith(
                  color: timeColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              // Prayer time - background with prayer color
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(0.20),
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
    // Build a RichText so numeric parts are large and labels are smaller/lighter
    final hours = countdown?.inHours ?? 0;
    final minutes = countdown?.inMinutes.remainder(60) ?? 0;
    final seconds = countdown?.inSeconds.remainder(60) ?? 0;

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    TextStyle numberStyle = AppTypography.countdownLarge.copyWith(
      fontSize: 62,
      color: textColor,
      fontWeight: FontWeight.w700,
    );
    TextStyle labelStyle = AppTypography.bodySmall.copyWith(
      fontSize: 22,
      color: textColor,
      fontWeight: FontWeight.w600,
    );

    List<InlineSpan> spans = [];
    final isTr = locale.toLowerCase().startsWith('tr');
    final hourLabelText = isTr ? 'sa' : AppLocalizations.translate('hour', locale);
    final minuteLabelText = isTr ? 'dk' : AppLocalizations.translate('minute', locale);
    final secondLabelText = isTr ? 'sn' : AppLocalizations.translate('second', locale);

    if (hours > 0) {
      spans.add(TextSpan(text: '$hours', style: numberStyle));
      spans.add(TextSpan(text: ' $hourLabelText', style: labelStyle));
      spans.add(TextSpan(text: '  '));
      spans.add(TextSpan(text: '${minutes.toString().padLeft(2, '0')}', style: numberStyle));
      spans.add(TextSpan(text: ' $minuteLabelText', style: labelStyle));
    } else {
      spans.add(TextSpan(text: '${minutes.toString()}', style: numberStyle));
      spans.add(TextSpan(text: ' $minuteLabelText', style: labelStyle));
      spans.add(TextSpan(text: '  '));
      spans.add(TextSpan(text: '${seconds.toString().padLeft(2, '0')}', style: numberStyle.copyWith(fontSize: 44)));
      spans.add(TextSpan(text: ' $secondLabelText', style: labelStyle));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: spans),
        ),
      ],
    );
  }
}
