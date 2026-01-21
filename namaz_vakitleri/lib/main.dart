import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'config/color_system.dart';
import 'config/localization.dart';
import 'providers/app_settings.dart';
import 'providers/prayer_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppSettings _appSettings;
  late PrayerProvider _prayerProvider;

  @override
  void initState() {
    super.initState();
    _appSettings = AppSettings();
    _prayerProvider = PrayerProvider();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _appSettings.initialize();
    await _prayerProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: _appSettings),
        ChangeNotifierProvider<PrayerProvider>.value(value: _prayerProvider),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          final isDark = settings.isDarkMode ||
              (settings.themeMode == ThemeMode.system &&
                  MediaQuery.of(context).platformBrightness ==
                      Brightness.dark);

          return MaterialApp(
            title: AppLocalizations.translate('app_title', settings.language),
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: settings.themeMode,
            locale: Locale(settings.language),
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.h3.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(
          color: AppColors.textPrimary,
        ),
        displayMedium: AppTypography.h2.copyWith(
          color: AppColors.textPrimary,
        ),
        displaySmall: AppTypography.h3.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        labelMedium: AppTypography.caption.copyWith(
          color: AppColors.textLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBgSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.textLight.withOpacity(AppOpacity.veryLow),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.textLight.withOpacity(AppOpacity.veryLow),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.accentPrimary.withOpacity(0.6),
          ),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textLight,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(AppColors.accentPrimary),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.accentPrimary.withOpacity(0.5);
          }
          return AppColors.textLight.withOpacity(0.3);
        }),
      ),
      colorScheme: ColorScheme.light(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.lightBgSecondary,
        background: AppColors.lightBg,
        error: AppColors.error,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: AppTypography.h3.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        displayMedium: AppTypography.h2.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        displaySmall: AppTypography.h3.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelMedium: AppTypography.caption.copyWith(
          color: AppColors.darkTextLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBgSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.darkTextLight.withOpacity(AppOpacity.veryLow),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.darkTextLight.withOpacity(AppOpacity.veryLow),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.darkAccentPrimary.withOpacity(0.6),
          ),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextLight,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(AppColors.darkAccentPrimary),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.darkAccentPrimary.withOpacity(0.5);
          }
          return AppColors.darkTextLight.withOpacity(0.3);
        }),
      ),
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkAccentPrimary,
        secondary: AppColors.darkAccentSecondary,
        surface: AppColors.darkBgSecondary,
        background: AppColors.darkBg,
        error: AppColors.error,
      ),
    );
  }
}
