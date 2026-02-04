import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/localization.dart';

class AppSettings extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _initialized = false;

  // Settings
  String _language = 'en';
  ThemeMode _themeMode = ThemeMode.system;
  bool _enableAdhanSound = true;
  bool _enablePrayerNotifications = true;

  // Prayer-specific notification settings
  Map<String, bool> _prayerNotifications = {
    'Fajr': true,
    'Sunrise': false,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
  };

  Map<String, bool> _prayerSounds = {
    'Fajr': true,
    'Sunrise': false,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
  };

  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get enableAdhanSound => _enableAdhanSound;
  bool get enablePrayerNotifications => _enablePrayerNotifications;
  Map<String, bool> get prayerNotifications => Map.unmodifiable(_prayerNotifications);
  Map<String, bool> get prayerSounds => Map.unmodifiable(_prayerSounds);

  // Theme palettes stored as name -> (section -> ARGB int)
  Map<String, Map<String, int>> _palettes = {};
  String? _activePaletteName;

  Map<String, Map<String, int>> get palettes => Map.unmodifiable(_palettes);
  String? get activePaletteName => _activePaletteName;
  Map<String, int>? get activePaletteMapping => _activePaletteName != null ? _palettes[_activePaletteName!] : null;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await loadSettings();
    _initialized = true;
    print('⚙️ AppSettings initialized');
  }

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    _language = _prefs.getString('language') ?? 
        AppLocalizations.getLocale(null);
    
    final themeModeString = _prefs.getString('themeMode') ?? 'system';
    _themeMode = _parseThemeMode(themeModeString);
    
    _enableAdhanSound = _prefs.getBool('enableAdhanSound') ?? true;
    _enablePrayerNotifications = _prefs.getBool('enablePrayerNotifications') ?? true;

    // Load prayer-specific settings
    final prayerNotificationsRaw = _prefs.getString('prayer_notifications');
    if (prayerNotificationsRaw != null) {
      try {
        final decoded = jsonDecode(prayerNotificationsRaw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (_prayerNotifications.containsKey(key)) {
            _prayerNotifications[key] = value as bool;
          }
        });
      } catch (_) {}
    }

    final prayerSoundsRaw = _prefs.getString('prayer_sounds');
    if (prayerSoundsRaw != null) {
      try {
        final decoded = jsonDecode(prayerSoundsRaw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (_prayerSounds.containsKey(key)) {
            _prayerSounds[key] = value as bool;
          }
        });
      } catch (_) {}
    }

    // Load palettes (stored as JSON)
    final raw = _prefs.getString('theme_palettes_json') ?? '';
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((name, map) {
          if (map is Map) {
            final inner = <String, int>{};
            (map as Map).forEach((k, v) {
              final val = v is int ? v : int.tryParse(v.toString());
              if (val != null) inner[k.toString()] = val;
            });
            _palettes[name] = inner;
          }
        });
      } catch (_) {}
    }
    _activePaletteName = _prefs.getString('active_theme_palette');
    _initialized = true;
    
    notifyListeners();
  }

  // remove JSON helper

  Future<void> savePalette(String name, Map<String, int> mapping) async {
    _palettes[name] = Map<String, int>.from(mapping);
    if (_initialized) {
      await _prefs.setString('theme_palettes_json', jsonEncode(_palettes));
    }
    notifyListeners();
  }

  Future<void> applyPalette(String name) async {
    if (_palettes.containsKey(name)) {
      _activePaletteName = name;
      if (_initialized) {
        await _prefs.setString('active_theme_palette', name);
      }
      notifyListeners();
    }
  }

  Future<void> savePaletteIfNotExists(String name, Map<String, int> mapping) async {
    if (!_palettes.containsKey(name)) {
      await savePalette(name, mapping);
    }
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    if (_initialized) {
      await _prefs.setString('language', language);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    if (_initialized) {
      await _prefs.setString('themeMode', _themeModeToString(mode));
    }
    notifyListeners();
  }

  Future<void> setEnableAdhanSound(bool enable) async {
    _enableAdhanSound = enable;
    if (_initialized) {
      await _prefs.setBool('enableAdhanSound', enable);
    }
    notifyListeners();
  }

  Future<void> setEnablePrayerNotifications(bool enable) async {
    _enablePrayerNotifications = enable;
    if (_initialized) {
      await _prefs.setBool('enablePrayerNotifications', enable);
    }
    notifyListeners();
  }

  Future<void> resetPalette() async {
    _activePaletteName = null;
    if (_initialized) {
      await _prefs.remove('active_theme_palette');
    }
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

  Future<void> setPrayerNotification(String prayerName, bool enabled) async {
    if (_prayerNotifications.containsKey(prayerName)) {
      _prayerNotifications[prayerName] = enabled;
      if (_initialized) {
        await _prefs.setString('prayer_notifications', jsonEncode(_prayerNotifications));
      }
      notifyListeners();
    }
  }

  Future<void> setPrayerSound(String prayerName, bool enabled) async {
    if (_prayerSounds.containsKey(prayerName)) {
      _prayerSounds[prayerName] = enabled;
      if (_initialized) {
        await _prefs.setString('prayer_sounds', jsonEncode(_prayerSounds));
      }
      notifyListeners();
    }
  }
}
