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
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2430).withOpacity(0.94)
                      : const Color(0xFFFCFBF8).withOpacity(0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFDDD4C8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.24 : 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: Colors.transparent,
                      height: 74,
                      elevation: 0,
                      indicatorColor: isDark
                          ? const Color(0xFF3E665B)
                          : const Color(0xFFD8C29D),
                      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
                        states,
                      ) {
                        final selected =
                            states.contains(WidgetState.selected);
                        return IconThemeData(
                          size: 24,
                          color: selected
                              ? (isDark
                                  ? const Color(0xFFF7F4EE)
                                  : const Color(0xFF1E3A34))
                              : (isDark
                                  ? const Color(0xFFAFB7C5)
                                  : const Color(0xFF6F6A63)),
                        );
                      }),
                      labelTextStyle:
                          WidgetStateProperty.resolveWith<TextStyle>((states) {
                        final selected =
                            states.contains(WidgetState.selected);
                        return TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? (isDark
                                  ? const Color(0xFFF7F4EE)
                                  : const Color(0xFF1E3A34))
                              : (isDark
                                  ? const Color(0xFFAFB7C5)
                                  : const Color(0xFF6F6A63)),
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
          ),
        );
      },
    );
  }
}
