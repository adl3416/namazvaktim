import 'package:flutter/material.dart';

class AppColors {
  // Light mode backgrounds
  static const Color lightBg = Color(0xFFEBF5FB);
  static const Color lightBgSecondary = Color(0xFFFAFAFA);
  
  // Prayer time backgrounds (light mode) - Sadece ana renk ve tonları kullanılacak
  static const Color lightBaseBg = Color(0xFFFFE7BF); // Ana renk (ör: öğle-ikindi arası)
  
  // Dark mode backgrounds
  static const Color darkBg = Color(0xFF2A2633);
  static const Color darkBgSecondary = Color(0xFF3D3645);
  
  // Prayer time backgrounds (dark mode) - Sadece ana rengin koyu tonu
  static const Color darkBaseBg = Color(0xFFBFA770); // Ana rengin koyu tonu (ör: #FFE7BF'in koyusu)

  // getPrayerTimeBackground fonksiyonu sadeleştirildi, sadece ana renk döner
  // Map vakit names to specific base colors (light mode). Dark mode color
  // is computed by darkening the light base.
  static Color getPrayerTimeBackground(String prayerName, bool isDark) {
    final n = prayerName.toLowerCase();

    Color lightBase = lightBaseBg; // default

    if (n.contains('fajr') || n.contains('imsak') || n.contains('sabah')) {
      lightBase = imsakBase; // İmsak – Güneş arası (açık buz mavisi)
    } else if (n.contains('sunrise') || n.contains('gunes') || n.contains('güneş')) {
      lightBase = gunesBase; // Güneş – Öğle arası (çok açık mavi/beyaz)
    } else if (n.contains('dhuhr') || n.contains('ogle') || n.contains('öğle') || n.contains('zuhr')) {
      lightBase = ogleBase; // Öğle – İkindi arası (sarımsı)
    } else if (n.contains('asr') || n.contains('ikindi') || n.contains('asir')) {
      lightBase = ikindiBase; // İkindi – Akşam arası (daha koyu sarı/turuncu)
    } else if (n.contains('maghrib') || n.contains('aksam') || n.contains('akşam') || n.contains('magrib')) {
      lightBase = aksamBase; // Akşam – Yatsı arası (turuncu/gün batımı)
    } else if (n.contains('isha') || n.contains('yatsı') || n.contains('yatsi') || n.contains('esha')) {
      lightBase = yatsiBase; // Yatsı – İmsak arası (koyu buz mavisi/gece)
    }

    if (isDark) {
      // Derive a darker tone for dark mode
      return Color.lerp(lightBase, Colors.black, 0.42) ?? darkBaseBg;
    }

    return lightBase;
  }

  // Allow runtime setting of a dynamic base color (e.g., current vakit base color)
  static void setDynamicBase(Color base) {
    dynamicBase = base;
    // Derive a subtle accent from the base by darkening slightly.
    dynamicAccent = Color.lerp(base, Colors.black, 0.16);
    // Debug: print current dynamic base & accent so we can verify runtime changes
    debugPrint('AppColors.setDynamicBase -> base: ${base.value.toRadixString(16)}, accent: ${dynamicAccent?.value.toRadixString(16)}');
  }
  
  // Text colors (all black per user requirement)
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF000000);
  static const Color textLight = Color(0xFF000000);
  static const Color darkTextPrimary = Color(0xFF000000);
  static const Color darkTextSecondary = Color(0xFF000000);
  static const Color darkTextLight = Color(0xFF000000);
  
  // UI elements
  static const Color accentMint = Color(0xFFBEECD5);
  static const Color darkAccentMint = Color(0xFF8B9FA3);
  // Defaults for accents
  static const Color _accentPrimaryDefault = Color(0xFF5DADE2);
  static const Color _darkAccentPrimaryDefault = Color(0xFF3B80C0);
  static const Color _accentSecondaryDefault = Color(0xFF85C1E2);
  static const Color _darkAccentSecondaryDefault = Color(0xFF6AACDB);

  // Dynamic overrides (can be set at runtime to tint the UI per vakit interval)
  static Color? dynamicBase;
  static Color? dynamicAccent;

  static Color get accentPrimary => dynamicAccent ?? _accentPrimaryDefault;
  static Color get darkAccentPrimary => dynamicAccent ?? _darkAccentPrimaryDefault;
  static Color get accentSecondary => dynamicAccent ?? _accentSecondaryDefault;
  static Color get darkAccentSecondary => dynamicAccent ?? _darkAccentSecondaryDefault;
  
  // Dividers
  static const Color divider = Color(0xFFE0E0E0);
  static const Color darkDivider = Color(0xFF4A4359);
  static const Color lightDivider = Color(0xFFE0E0E0);
  
  // Status colors
  static const Color success = Color(0xFFB5D4A8);
  static const Color error = Color(0xFFD4A8A8);
  static const Color warning = Color(0xFFD4C4A8);
  
  // Theme-aware getters
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : textPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : textSecondary;
  static Color getTextLight(bool isDark) => isDark ? darkTextLight : textLight;
  static Color getBackground(bool isDark) => isDark ? darkBg : lightBg;
  static Color getDivider(bool isDark) => isDark ? darkDivider : lightDivider;
  
  // NOTE: getPrayerTimeBackground simplified above to return base tones.

  // Named base colors per vakit (light-mode). Use these constants when a specific
  // vakit base is needed in code; prefer `getPrayerTimeBackground` for name-based lookup.
  static const Color sayimBase = Color(0xFFFFEBEE); // very light pink
  static const Color imsakBase = Color(0xFFFFCDD2);
  static const Color gunesBase = Color(0xFFEF9A9A);
  static const Color ogleBase = Color(0xFFE57373);
  static const Color ikindiBase = Color(0xFFEF5350);
  static const Color aksamBase = Color(0xFFE53935);
  static const Color yatsiBase = Color(0xFFC62828);
}

class AppSpacing {
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
}

class AppTypography {
  static const TextStyle h1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: Color(0xFF000000),
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: Color(0xFF000000),
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: Color(0xFF000000),
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: Color(0xFF000000),
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: Color(0xFF000000),
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: Color(0xFF000000),
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.normal,
    color: Color(0xFF000000),
  );
  
  static const TextStyle countdownLarge = TextStyle(
    fontSize: 48.0,
    fontWeight: FontWeight.bold,
    color: Color(0xFF000000),
  );
  
  static const TextStyle countdownLabel = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: Color(0xFF000000),
  );
}

class AppOpacity {
  static const double full = 1.0;
  static const double high = 0.87;
  static const double medium = 0.60;
  static const double low = 0.38;
  static const double veryLow = 0.12;
}

class AppRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 999.0;
}

class AppShadows {
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 2.0,
    offset: Offset(0, 1),
  );
  
  static const BoxShadow soft = BoxShadow(
    color: Color(0x24000000),
    blurRadius: 8.0,
    offset: Offset(0, 2),
  );
  
  static const BoxShadow none = BoxShadow(color: Colors.transparent);
}
