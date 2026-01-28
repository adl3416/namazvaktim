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
          color:
              backgroundColor ??
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
                  color:
                      textColor ??
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
          color:
              (isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary)
                  .withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color:
              color ??
              (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          iconSize: size,
        ),
      );
    }

    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color:
          color ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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

  Color _getPrayerBackgroundColor(
    String prayerName,
    bool isDark, {
    Color? baseOverride,
  }) {
    final name = prayerName.toLowerCase();
    final base =
        baseOverride ?? (isDark ? AppColors.darkBaseBg : AppColors.lightBaseBg);
    double t = 0.85;
    if (name.contains('fajr') ||
        name.contains('imsak') ||
        name.contains('sabah'))
      t = 0.9;
    else if (name.contains('sunrise') ||
        name.contains('gunes') ||
        name.contains('güneş'))
      t = 0.92;
    else if (name.contains('dhuhr') ||
        name.contains('ogle') ||
        name.contains('öğle'))
      t = 0.75;
    else if (name.contains('asr') || name.contains('ikindi'))
      t = 0.7;
    else if (name.contains('maghrib') ||
        name.contains('aksam') ||
        name.contains('akşam'))
      t = 0.6;
    else if (name.contains('isha') ||
        name.contains('yatsi') ||
        name.contains('yatsı'))
      t = 0.55;

    t = t.clamp(0.0, 1.0);
    return Color.lerp(base, Colors.white, t) ?? base;
  }

  // Get tonal color based on scaffold background and prayer order
  Color _getScaffoldBasedTonalColor(
    String prayerName,
    bool isDark,
    Color scaffoldBase,
  ) {
    // Namaz sırasına göre opacity belirle (%10'dan %60'a kadar)
    final name = prayerName.toLowerCase();
    double opacityFactor;

    if (name.contains('fajr') ||
        name.contains('imsak') ||
        name.contains('sabah')) {
      opacityFactor = 0.10; // %10 - En açık
    } else if (name.contains('sunrise') ||
        name.contains('gunes') ||
        name.contains('güneş')) {
      opacityFactor = 0.20; // %20
    } else if (name.contains('dhuhr') ||
        name.contains('ogle') ||
        name.contains('öğle')) {
      opacityFactor = 0.30; // %30
    } else if (name.contains('asr') || name.contains('ikindi')) {
      opacityFactor = 0.40; // %40
    } else if (name.contains('maghrib') ||
        name.contains('aksam') ||
        name.contains('akşam')) {
      opacityFactor = 0.50; // %50
    } else if (name.contains('isha') ||
        name.contains('yatsi') ||
        name.contains('yatsı')) {
      opacityFactor = 0.60; // %60 - En koyu
    } else {
      opacityFactor = 0.30; // default
    }

    // Scaffold arka plan rengini kullanarak opacity'li renk oluştur
    if (isDark) {
      // Dark mode'da scaffold rengini beyazla karıştırıp opacity uygula
      final lightedScaffold =
          Color.lerp(scaffoldBase, Colors.white, 0.3) ?? scaffoldBase;
      return lightedScaffold.withOpacity(opacityFactor);
    } else {
      // Light mode'da scaffold rengini direkt opacity ile kullan
      return scaffoldBase.withOpacity(opacityFactor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        overrideBaseColor ??
        (isDark ? AppColors.darkBaseBg : AppColors.lightBaseBg);
    final rowColor = Color.lerp(baseColor, Colors.white, isDark ? 0.15 : 0.85)!;
    // stronger contrast for time and label: lerp more toward black on light backgrounds
    final timeColor = isDark
        ? AppColors.darkTextPrimary
        : (Color.lerp(baseColor, Colors.black, 0.45) ?? AppColors.textPrimary);
    final labelColor = isDark
        ? AppColors.darkTextPrimary
        : (Color.lerp(baseColor, Colors.black, 0.38) ?? AppColors.textPrimary);
    final borderColor = Color.lerp(baseColor, Colors.black, 0.12)!;

    final bgColor = _getPrayerBackgroundColor(
      prayerName,
      isDark,
      baseOverride: baseColor,
    );

    // Get scaffold-based tonal color for this prayer time
    final prayerTonalColor = _getScaffoldBasedTonalColor(
      prayerName,
      isDark,
      baseColor,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl + 4,
        vertical: AppSpacing.md + (isActive ? 4 : 0),
      ),
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isActive ? prayerTonalColor.withOpacity(0.95) : prayerTonalColor,
        border: isActive
            ? Border.all(
                color: isDark
                    ? AppColors.darkAccentPrimary.withOpacity(0.7)
                    : AppColors.accentPrimary.withOpacity(0.8),
                width: 2.5,
              )
            : Border.all(
                color: isDark
                    ? AppColors.darkDivider.withOpacity(0.1)
                    : AppColors.divider.withOpacity(0.1),
                width: 1.0,
              ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color:
                      (isDark
                              ? AppColors.darkAccentPrimary
                              : AppColors.accentPrimary)
                          .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: prayerTonalColor.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: prayerTonalColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Aktif namaz için ek highlight indicator
          // if (isActive)
          // Positioned(
          //   left: 0,
          //   top: 0,
          //   bottom: 0,
          //   child: Container(
          //     width: 100,
          //     decoration: BoxDecoration(
          //       color: isDark
          //           ? AppColors.darkAccentPrimary
          //           : AppColors.accentPrimary,
          //       borderRadius: BorderRadius.circular(2),
          //     ),
          //   ),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.translate(prayerName.toLowerCase(), locale),
                  style: AppTypography.bodyLarge.copyWith(
                    color: isActive
                        ? (isDark
                              ? AppColors.darkAccentPrimary
                              : AppColors.accentPrimary)
                        : labelColor,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                    fontSize: isActive ? 17 : 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg + (isActive ? 4 : 0),
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                            ? AppColors.darkAccentPrimary.withOpacity(0.2)
                            : AppColors.accentPrimary.withOpacity(0.15))
                      : prayerTonalColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color:
                                (isDark
                                        ? AppColors.darkAccentPrimary
                                        : AppColors.accentPrimary)
                                    .withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: prayerTonalColor.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  prayerTime,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: isActive ? 19 : 18,
                    color: isActive
                        ? (isDark
                              ? AppColors.darkAccentPrimary
                              : AppColors.accentPrimary)
                        : timeColor,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w800,
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

    final defaultTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
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
    final hourLabelText = isTr
        ? 'sa'
        : AppLocalizations.translate('hour', locale);
    final minuteLabelText = isTr
        ? 'dk'
        : AppLocalizations.translate('minute', locale);
    final secondLabelText = isTr
        ? 'sn'
        : AppLocalizations.translate('second', locale);

    if (hours > 0) {
      spans.add(TextSpan(text: '$hours', style: numberStyle));
      spans.add(TextSpan(text: ' $hourLabelText', style: labelStyle));
      spans.add(TextSpan(text: '  '));
      spans.add(
        TextSpan(
          text: '${minutes.toString().padLeft(2, '0')}',
          style: numberStyle,
        ),
      );
      spans.add(TextSpan(text: ' $minuteLabelText', style: labelStyle));
    } else {
      spans.add(TextSpan(text: '${minutes.toString()}', style: numberStyle));
      spans.add(TextSpan(text: ' $minuteLabelText', style: labelStyle));
      spans.add(TextSpan(text: '  '));
      spans.add(
        TextSpan(
          text: '${seconds.toString().padLeft(2, '0')}',
          style: numberStyle.copyWith(fontSize: 44),
        ),
      );
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
          Text(
            title,
            style: AppTypography.h2.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
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
                  backgroundColor: isDark
                      ? AppColors.darkBgSecondary
                      : AppColors.lightBgSecondary,
                  textColor: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
