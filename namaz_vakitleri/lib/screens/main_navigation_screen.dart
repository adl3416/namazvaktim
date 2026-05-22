import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import 'home_screen.dart';
import 'nearby_mosques_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    QiblaScreen(),
    NearbyMosquesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final palette = _navPaletteForPrayer(prayerProvider.activePrayer?.name);
        final bottomInset = MediaQuery.of(context).padding.bottom;

        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (didPop) {
              print('Back button pressed - exiting app');
            }
          },
          child: Scaffold(
            extendBody: true,
            body: _screens[_selectedIndex],
            bottomNavigationBar: Container(
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? <Color>[
                          palette.primary.withOpacity(0.92),
                          palette.secondary.withOpacity(0.88),
                        ]
                      : <Color>[
                          palette.primary,
                          palette.secondary,
                        ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withOpacity(isDark ? 0.34 : 0.22),
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
                    height: 68,
                    elevation: 0,
                    indicatorColor: Colors.white.withOpacity(isDark ? 0.18 : 0.22),
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
                        fontSize: 12,
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
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.access_time_rounded),
                        selectedIcon: Icon(Icons.access_time_filled_rounded),
                        label: 'Vakitler',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore_rounded),
                        label: 'Kible',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.mosque_outlined),
                        selectedIcon: Icon(Icons.mosque_rounded),
                        label: 'Camiler',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: 'Ayarlar',
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

class _NavPalette {
  const _NavPalette({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;
}

_NavPalette _navPaletteForPrayer(String? prayerName) {
  final normalized = prayerName?.toLowerCase() ?? '';

  if (normalized.contains('fajr') || normalized.contains('imsak')) {
    return const _NavPalette(
      primary: Color(0xFF4338CA),
      secondary: Color(0xFF6366F1),
    );
  }

  if (normalized.contains('sunrise') || normalized.contains('gunes')) {
    return const _NavPalette(
      primary: Color(0xFFC2410C),
      secondary: Color(0xFFEA580C),
    );
  }

  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return const _NavPalette(
      primary: Color(0xFF1D4ED8),
      secondary: Color(0xFF3B82F6),
    );
  }

  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return const _NavPalette(
      primary: Color(0xFFB45309),
      secondary: Color(0xFFF59E0B),
    );
  }

  if (normalized.contains('maghrib') || normalized.contains('aksam')) {
    return const _NavPalette(
      primary: Color(0xFF9F1239),
      secondary: Color(0xFFFB7185),
    );
  }

  if (normalized.contains('isha') || normalized.contains('yatsi')) {
    return const _NavPalette(
      primary: Color(0xFF1F3A8A),
      secondary: Color(0xFF312E81),
    );
  }

  return const _NavPalette(
    primary: Color(0xFF166534),
    secondary: Color(0xFF16A34A),
  );
}
