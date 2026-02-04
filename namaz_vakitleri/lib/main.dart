import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:namaz_vakitleri/config/color_system.dart';
import 'package:namaz_vakitleri/providers/app_settings.dart';
import 'package:namaz_vakitleri/providers/prayer_provider.dart';
import 'package:namaz_vakitleri/screens/home_screen.dart';
import 'package:namaz_vakitleri/services/notification_service.dart';
import 'package:namaz_vakitleri/services/location_service.dart';

// Global navigator key for accessing context from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();

  // Initialize notifications
  print('🚀 Initializing notifications...');
  await NotificationService.initialize();
  print('✅ Notifications initialized');

  // Request location permission early
  print('📍 Requesting location permission...');
  await LocationService.requestLocationPermission();
  print('✅ Location permission requested');

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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _appSettings = AppSettings();
    _prayerProvider = PrayerProvider(appSettings: _appSettings);
    _setupMethodChannels();
    _initializeApp();
  }

  /// Set up method channels to receive volume button presses from Android
  void _setupMethodChannels() {
    const platform = MethodChannel('com.vakit.app.namaz_vakitleri/adhan');
    
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onVolumeButtonPressed') {
        // Stop adhan when volume button is pressed
        await _prayerProvider.stopAdhan();
        print('🔊 Volume button pressed - stopping adhan');
      }
      return null;
    });
  }

  Future<void> _initializeApp() async {
    try {
      print('⚙️ Initializing app settings...');
      await _appSettings.initialize();
      print('✅ App settings initialized');

      print('📱 Initializing prayer provider...');
      await _prayerProvider.initialize();
      print('✅ Prayer provider initialized');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      print('🎉 App initialization complete');
    } catch (e) {
      print('❌ Error initializing app: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Continue even with errors
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.teal,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Namaz Vakitleri Yükleniyor...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appSettings),
        ChangeNotifierProvider.value(value: _prayerProvider),
      ],
      child: Consumer<AppSettings>(
        builder: (context, appSettings, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Namaz Vakitleri',
            debugShowCheckedModeBanner: false,
            locale: Locale(appSettings.language),
            supportedLocales: const [
              Locale('en'),
              Locale('tr'),
              Locale('ar'),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null) {
                for (final supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
              }
              return supportedLocales.first;
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: appSettings.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const HomeScreen(),
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
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        displaySmall: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        labelMedium: AppTypography.caption.copyWith(color: AppColors.textLight),
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
