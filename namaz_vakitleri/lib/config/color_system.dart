import 'package:flutter/material.dart';

class AppColors {
  // Light mode backgrounds
  static const Color lightBg = Color(0xFFEBF5FB);
  static const Color lightBgSecondary = Color(0xFFFAFAFA);
  
  // Prayer time backgrounds (light mode)
  static const Color lightFajrBg = Color(0xFFD6EAF8);
  static const Color lightSunriseBg = Color(0xFFAED6F1);
  static const Color lightDhuhrBg = Color(0xFF5DADE2);
  static const Color lightAsrBg = Color(0xFF3498DB);
  static const Color lightMaghribBg = Color(0xFF2E86C1);
  static const Color lightIshaBg = Color(0xFF1B4F72);
  
  // Dark mode backgrounds
  static const Color darkBg = Color(0xFF2A2633);
  static const Color darkBgSecondary = Color(0xFF3D3645);
  
  // Prayer time backgrounds (dark mode)
  static const Color darkFajrBg = Color(0xFF3B354E);
  static const Color darkSunriseBg = Color(0xFF4A4359);
  static const Color darkDhuhrBg = Color(0xFF3B354E);
  static const Color darkAsrBg = Color(0xFF5A5268);
  static const Color darkMaghribBg = Color(0xFF6B6379);
  static const Color darkIshaBg = Color(0xFF7A7288);
  
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
  static const Color accentPrimary = Color(0xFF5DADE2);
  static const Color darkAccentPrimary = Color(0xFF3B80C0);
  static const Color accentSecondary = Color(0xFF85C1E2);
  static const Color darkAccentSecondary = Color(0xFF6AACDB);
  
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
  
  // Prayer time background getter with name mapping
  static Color getPrayerTimeBackground(String prayerName, bool isDark) {
    final name = prayerName.toLowerCase().trim();
    
    // Imsak (Fajr) variants
    if (name == 'imsak' || name == 'fajr' || name == 'sabah') {
      return isDark ? darkFajrBg : lightFajrBg;
    }
    
    // Sunrise variants
    if (name == 'sunrise' || name == 'gunes' || name == 'güneş') {
      return isDark ? darkSunriseBg : lightSunriseBg;
    }
    
    // Dhuhr (Noon) variants
    if (name == 'dhuhr' || name == 'ogle' || name == 'öğle' || name == 'zuhr') {
      return isDark ? darkDhuhrBg : lightDhuhrBg;
    }
    
    // Asr (Afternoon) variants
    if (name == 'asr' || name == 'ikindi' || name == 'asir') {
      return isDark ? darkAsrBg : lightAsrBg;
    }
    
    // Maghrib (Sunset) variants
    if (name == 'maghrib' || name == 'akşam' || name == 'aksam' || name == 'magrib') {
      return isDark ? darkMaghribBg : lightMaghribBg;
    }
    
    // Isha (Night) variants
    if (name == 'isha' || name == 'yatsi' || name == 'yatsı' || name == 'esha') {
      return isDark ? darkIshaBg : lightIshaBg;
    }
    
    // Default fallback
    return isDark ? darkBg : lightBg;
  }
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
