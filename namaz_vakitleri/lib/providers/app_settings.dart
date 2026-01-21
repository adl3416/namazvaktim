import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/localization.dart';

class AppSettings extends ChangeNotifier {
  late SharedPreferences _prefs;

  // Settings
  String _language = 'en';
  ThemeMode _themeMode = ThemeMode.system;
  bool _enableAdhanSound = true;
  bool _enablePrayerNotifications = true;

  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get enableAdhanSound => _enableAdhanSound;
  bool get enablePrayerNotifications => _enablePrayerNotifications;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    _language = _prefs.getString('language') ?? 
        AppLocalizations.getLocale(null);
    
    final themeModeString = _prefs.getString('themeMode') ?? 'system';
    _themeMode = _parseThemeMode(themeModeString);
    
    _enableAdhanSound = _prefs.getBool('enableAdhanSound') ?? true;
    _enablePrayerNotifications = _prefs.getBool('enablePrayerNotifications') ?? true;
    
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _prefs.setString('language', language);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString('themeMode', _themeModeToString(mode));
    notifyListeners();
  }

  Future<void> setEnableAdhanSound(bool enable) async {
    _enableAdhanSound = enable;
    await _prefs.setBool('enableAdhanSound', enable);
    notifyListeners();
  }

  Future<void> setEnablePrayerNotifications(bool enable) async {
    _enablePrayerNotifications = enable;
    await _prefs.setBool('enablePrayerNotifications', enable);
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Would need to get from MediaQuery in actual usage
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }
}
