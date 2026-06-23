import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import 'home_screen.dart';
import 'nearby_mosques_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'zikirmatik_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final locale = settings.language;
        final palette = _navPaletteForPrayer(
          prayerProvider.activePrayer?.name,
          isDark,
        );
        final mediaQuery = MediaQuery.of(context);
        final bottomInset = mediaQuery.padding.bottom;
        final compactBottomInset = bottomInset == 0
            ? 6.0
            : bottomInset.clamp(4.0, 12.0).toDouble();
        final navLabelFontSize = locale == 'de' ? 10.5 : 12.0;
        final hideBottomNav = prayerProvider.requiresManualLocationSelection;

        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (didPop) {
              print('Back button pressed - exiting app');
            }
          },
          child: Scaffold(
            extendBody: true,
            body: [
              const HomeScreen(),
              const QiblaScreen(),
              const NearbyMosquesScreen(),
              ZikirmatikScreen(
                onExitRequested: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              const SettingsScreen(),
            ][_selectedIndex],
            bottomNavigationBar: hideBottomNav
                ? null
                : Container(
              padding: EdgeInsets.fromLTRB(0, 0, 0, compactBottomInset),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    palette.primary.withOpacity(0.92),
                    Color.lerp(
                      palette.secondary,
                      palette.tertiary,
                      0.35,
                    )!
                        .withOpacity(0.88),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withOpacity(0.24),
                    blurRadius: 22,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.transparent,
                    height: 72,
                    elevation: 0,
                    indicatorColor: isDark
                        ? Colors.white.withOpacity(0.14)
                        : Colors.white.withOpacity(0.20),
                    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
                      states,
                    ) {
                      final selected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        size: 23,
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.72),
                      );
                    }),
                    labelTextStyle:
                        WidgetStateProperty.resolveWith<TextStyle>((states) {
                      final selected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontSize: navLabelFontSize,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.78),
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.access_time_rounded),
                        selectedIcon: const Icon(Icons.access_time_filled_rounded),
                        label: _text(
                          locale,
                          tr: 'Vakitler',
                          en: 'Times',
                          ar: 'الأوقات',
                        ),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.explore_outlined),
                        selectedIcon: const Icon(Icons.explore_rounded),
                        label: AppLocalizations.translate('qibla', locale),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.mosque_outlined),
                        selectedIcon: const Icon(Icons.mosque_rounded),
                        label: _text(
                          locale,
                          tr: 'Camiler',
                          en: 'Mosques',
                          ar: 'المساجد',
                        ),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.touch_app_outlined),
                        selectedIcon: const Icon(Icons.touch_app_rounded),
                        label: _text(
                          locale,
                          tr: 'Zikir',
                          en: 'Dhikr',
                          ar: 'الذكر',
                        ),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_outlined),
                        selectedIcon: const Icon(Icons.settings_rounded),
                        label: AppLocalizations.translate('settings', locale),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _text(
  String locale, {
  required String tr,
  required String en,
  required String ar,
  String? de,
}) {
  switch (locale) {
    case 'tr':
      return tr;
    case 'de':
      return de ?? en;
    case 'ar':
      return ar;
    default:
      return en;
  }
}

class _NavPalette {
  const _NavPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
}

_NavPalette _navPaletteForPrayer(String? prayerName, bool isDark) {
  final normalized = prayerName?.toLowerCase() ?? '';

  if (normalized.contains('fajr') || normalized.contains('imsak')) {
    return _shadePalette(
      const _NavPalette(
        primary: Color(0xFF4338CA),
        secondary: Color(0xFF6366F1),
        tertiary: Color(0xFF818CF8),
      ),
      isDark,
    );
  }

  if (normalized.contains('sunrise') || normalized.contains('gunes')) {
    return _shadePalette(
      const _NavPalette(
        primary: Color(0xFFC2410C),
        secondary: Color(0xFFEA580C),
        tertiary: Color(0xFFFB923C),
      ),
      isDark,
    );
  }

  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return _shadePalette(
      const _NavPalette(
        primary: Color(0xFF1D4ED8),
        secondary: Color(0xFF3B82F6),
        tertiary: Color(0xFF60A5FA),
      ),
      isDark,
    );
  }

  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return _shadePalette(
      const _NavPalette(
        primary: Color(0xFFB45309),
        secondary: Color(0xFFD97706),
        tertiary: Color(0xFFF59E0B),
      ),
      isDark,
    );
  }

  if (normalized.contains('maghrib') || normalized.contains('aksam')) {
    return _shadePalette(
      const _NavPalette(
        primary: Color(0xFFCB1E13),
        secondary: Color(0xFFFF4C36),
        tertiary: Color(0xFFFF8577),
      ),
      isDark,
    );
  }

  if (normalized.contains('isha') || normalized.contains('yatsi')) {
    return _shadePalette(
      const _NavPalette(
        primary: Color(0xFF5B2BE0),
        secondary: Color(0xFF7A4DFF),
        tertiary: Color(0xFFA78BFA),
      ),
      isDark,
    );
  }

  return _shadePalette(
    const _NavPalette(
      primary: Color(0xFF5B21B6),
      secondary: Color(0xFF7C3AED),
      tertiary: Color(0xFF8B5CF6),
    ),
    isDark,
  );
}

_NavPalette _shadePalette(_NavPalette palette, bool isDark) {
  if (!isDark) return palette;

  return _NavPalette(
    primary: Color.lerp(palette.primary, const Color(0xFF0F172A), 0.48)!,
    secondary: Color.lerp(palette.secondary, const Color(0xFF111827), 0.42)!,
    tertiary: Color.lerp(palette.tertiary, const Color(0xFF1E293B), 0.35)!,
  );
}
