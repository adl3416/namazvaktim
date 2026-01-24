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
            color: (isDark ? AppColors.darkTextLight : AppColors.textLight)
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
                    textColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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
          color: (isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary).withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          iconSize: size,
        ),
      );
    }

    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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
  final Color? overrideBaseColor;
  final bool useSameHue;

  const PrayerTimeRow({
    Key? key,
    required this.prayerName,
    required this.prayerTime,
    required this.isActive,
    required this.locale,
    this.overrideBaseColor,
    this.useSameHue = false,
  }) : super(key: key);

  Color _getPrayerTimeColor(String prayerName, bool isDark) {
    return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  }

  Color _getPrayerBackgroundColor(String prayerName, bool isDark, {Color? baseOverride}) {
    final name = prayerName.toLowerCase();
    final base = baseOverride ?? (isDark ? AppColors.darkBaseBg : AppColors.lightBaseBg);
    double t = 0.85;
    if (name.contains('fajr') || name.contains('imsak') || name.contains('sabah')) t = 0.9;
    else if (name.contains('sunrise') || name.contains('gunes') || name.contains('güneş')) t = 0.92;
    else if (name.contains('dhuhr') || name.contains('ogle') || name.contains('öğle')) t = 0.75;
    else if (name.contains('asr') || name.contains('ikindi')) t = 0.7;
    else if (name.contains('maghrib') || name.contains('aksam') || name.contains('akşam')) t = 0.6;
    else if (name.contains('isha') || name.contains('yatsi') || name.contains('yatsı')) t = 0.55;

    t = t.clamp(0.0, 1.0);
    return Color.lerp(base, Colors.white, t) ?? base;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = overrideBaseColor ?? (isDark ? AppColors.darkBaseBg : AppColors.lightBaseBg);
    final rowColor = Color.lerp(baseColor, Colors.white, isDark ? 0.15 : 0.85)!;
    // stronger contrast for time and label: lerp more toward black on light backgrounds
    final timeColor = isDark
      ? AppColors.darkTextPrimary
      : (Color.lerp(baseColor, Colors.black, 0.45) ?? AppColors.textPrimary);
    final labelColor = isDark ? AppColors.darkTextPrimary : (Color.lerp(baseColor, Colors.black, 0.38) ?? AppColors.textPrimary);
    final borderColor = Color.lerp(baseColor, Colors.black, 0.12)!;

    final bgColor = _getPrayerBackgroundColor(prayerName, isDark, baseOverride: baseColor);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl + 4,
        vertical: AppSpacing.md,
      ),
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: isActive
            ? Border.all(
                color: isDark ? AppColors.darkDivider.withOpacity(0.18) : AppColors.divider.withOpacity(0.18),
                width: 1.0,
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(
                AppLocalizations.translate(prayerName.toLowerCase(), locale),
                style: AppTypography.bodyLarge.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
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
                    fontSize: 18,
                    color: timeColor,
                    fontWeight: FontWeight.w800,
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

class DottedPatternPainter extends CustomPainter {
  final Color color;

  DottedPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
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
  final Color? accentColor;

  const CountdownDisplay({
    Key? key,
    required this.countdown,
    required this.locale,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = countdown?.inHours ?? 0;
    final minutes = countdown?.inMinutes.remainder(60) ?? 0;
    final seconds = countdown?.inSeconds.remainder(60) ?? 0;

    final defaultTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final numberColor = accentColor ?? AppColors.accentPrimary;
    TextStyle numberStyle = AppTypography.countdownLarge.copyWith(
      fontSize: 64,
      color: numberColor,
      fontWeight: FontWeight.w800,
    );
    TextStyle labelStyle = AppTypography.bodySmall.copyWith(
      fontSize: 22,
      color: numberColor.withOpacity(0.95),
      fontWeight: FontWeight.w700,
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

class PermissionPrompt extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;
  final Color? accentColor;

  const PermissionPrompt({
    Key? key,
    required this.title,
    required this.message,
    required this.onRequest,
    required this.onOpenSettings,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = accentColor ?? AppColors.accentPrimary;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTypography.h2.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
          SizedBox(height: AppSpacing.md),
          Text(message, style: AppTypography.bodyMedium.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: SoftButton(
                  label: 'Allow',
                  onPressed: onRequest,
                  locale: AppLocalizations.getLocale(null),
                  backgroundColor: primary,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: SoftButton(
                  label: 'Open Settings',
                  onPressed: onOpenSettings,
                  locale: AppLocalizations.getLocale(null),
                  backgroundColor: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
                  textColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
