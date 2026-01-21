import 'package:flutter/material.dart';

/// Soft Pastel Color System - Lavender Theme
/// All colors are low saturation, calm, spiritual tones
class AppColors {
  // Light Mode - Lavender Palette
  static const Color lightBg = Color(0xFFEDE8FF); // LavenderVariant
  static const Color lightBgSecondary = Color(0xFFF6F5FF); // OffWhite
  
  // Prayer Time Colors - Subtle Tints
  static const Color fajrBg = Color(0xFFF0EAFF); // Purple-tinted
  static const Color dhuhrBg = Color(0xFFF3F0FF); // Lavender-tinted
  static const Color asrBg = Color(0xFFF1ECFF); // Purple-tinted
  static const Color maghribBg = Color(0xFFF4F1FF); // Lavender-tinted
  static const Color ishaBg = Color(0xFFEFEAFF); // Deep purple-tinted
  
  // Text Colors - Light Mode
  static const Color textPrimary = Color(0xFF1C1820); // NearBlack
  static const Color textSecondary = Color(0xFF2E2A36); // OnBackground
  static const Color textLight = Color(0xFF655F76); // Muted lavender-gray
  
  // Accent Colors
  static const Color accentPrimary = Color(0xFF6359B1); // LavenderPrimary
  static const Color accentSecondary = Color(0xFFD7D1F7); // LavenderSecondary
  static const Color accentMint = Color(0xFFBEECD5); // MintPastel
  
  // Dark Mode
  static const Color darkBg = Color(0xFF2A2633); // Dark lavender
  static const Color darkBgSecondary = Color(0xFF342E42); // Slightly lighter
  
  // Prayer Time Colors - Dark Mode
  static const Color darkFajrBg = Color(0xFF3D3651); // Dark purple-tinted
  static const Color darkDhuhrBg = Color(0xFF3B354E); // Dark lavender-tinted
  static const Color darkAsrBg = Color(0xFF3C354F); // Dark purple-tinted
  static const Color darkMaghribBg = Color(0xFF39334C); // Dark lavender
  static const Color darkIshaBg = Color(0xFF37304A); // Dark deep purple
  
  // Text Colors - Dark Mode
  static const Color darkTextPrimary = Color(0xFFFAF8FE); // Very light lavender
  static const Color darkTextSecondary = Color(0xFFE8E4F0); // Light lavender-gray
  static const Color darkTextLight = Color(0xFF9B96AB); // Muted lavender
  
  // Accent Colors - Dark Mode
  static const Color darkAccentPrimary = Color(0xFF9E95D6); // Lighter lavender
  static const Color darkAccentSecondary = Color(0xFFB5ADCE); // Soft lavender
  static const Color darkAccentMint = Color(0xFF97D4B3); // Soft mint
  
  // Borders & Dividers
  static const Color divider = Color(0xFFCBC6E8); // SoftStroke
  static const Color darkDivider = Color(0xFF4A4359); // Dark stroke
  
  // Active State (for prayer countdown)
  static const Color activeCardBg = Color(0xFFF6F2FE); // LavenderPrimary @8%
  
  // Status Colors (Subtle)
  static const Color success = Color(0xFFB5D4A8);
  static const Color error = Color(0xFFD4A8A8);
  static const Color warning = Color(0xFFD4C4A8);
  
  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : textPrimary;
  
  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : textSecondary;
  
  static Color getTextLight(bool isDark) =>
      isDark ? darkTextLight : textLight;
  
  static Color getBackground(bool isDark) =>
      isDark ? darkBg : lightBg;
  
  static Color getBackgroundSecondary(bool isDark) =>
      isDark ? darkBgSecondary : lightBgSecondary;
  
  static Color getPrayerTimeBackground(String prayerName, bool isDark) {
    if (isDark) {
      switch (prayerName.toLowerCase()) {
        case 'fajr':
          return darkFajrBg;
        case 'dhuhr':
          return darkDhuhrBg;
        case 'asr':
          return darkAsrBg;
        case 'maghrib':
          return darkMaghribBg;
        case 'isha':
          return darkIshaBg;
        default:
          return darkBgSecondary;
      }
    } else {
      switch (prayerName.toLowerCase()) {
        case 'fajr':
          return fajrBg;
        case 'dhuhr':
          return dhuhrBg;
        case 'asr':
          return asrBg;
        case 'maghrib':
          return maghribBg;
        case 'isha':
          return ishaBg;
        default:
          return lightBgSecondary;
      }
    }
  }
}

/// Spacing System - Inspired by Tailwind
class AppSpacing {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

/// Typography System
class AppTypography {
  static const String fontFamily = 'Inter'; // Modern, clean
  
  // Heading Styles
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  
  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
  
  // Special Styles
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );
  
  static const TextStyle countdownLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );
  
  static const TextStyle countdownLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
}

/// Opacity System
class AppOpacity {
  static const double full = 1.0;
  static const double high = 0.87;
  static const double medium = 0.6;
  static const double low = 0.38;
  static const double veryLow = 0.12;
}

/// Border Radius - Soft, modern
class AppRadius {
  static const double none = 0;
  static const double sm = 6;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

/// Shadow System - Very subtle
class AppShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x00000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> none = [];
}
