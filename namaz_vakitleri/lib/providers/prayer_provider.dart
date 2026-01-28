import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';
import '../services/aladhan_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class PrayerProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  PrayerTimes? _currentPrayerTimes;
  PrayerTime? _nextPrayer;
  PrayerTime? _activePrayer;

  bool _isLoading = false;
  bool _isFetching = false;
  DateTime? _lastFetchTime;
  final Duration _minFetchInterval = const Duration(minutes: 5);
  String _errorMessage = '';

  // Location
  GeoLocation? _currentLocation;
  String _savedCity = '';
  String _savedCountry = '';

  // Countdown
  DateTime? _lastCountdownUpdate;
  Duration? _countdownDuration;

  PrayerTimes? get currentPrayerTimes => _currentPrayerTimes;
  PrayerTime? get nextPrayer => _nextPrayer;
  PrayerTime? get activePrayer => _activePrayer;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  GeoLocation? get currentLocation => _currentLocation;
  String get savedCity => _savedCity;
  String get savedCountry => _savedCountry;
  Duration? get countdownDuration => _countdownDuration;

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      _savedCity = _prefs.getString('city') ?? '';
      _savedCountry = _prefs.getString('country') ?? '';

      print('📱 PrayerProvider initializing...');

      // Always try to get current location first
      await _loadCurrentLocation();

      // If current location failed, load from cache as backup
      if (_currentLocation == null) {
        _loadLocationFromCache();
      }

      // If still no location, use default (Istanbul) as last resort
      if (_currentLocation == null) {
        print('📍 Using default location: Istanbul');
        _currentLocation = GeoLocation(
          latitude: 41.0082,
          longitude: 28.9784,
          city: 'Istanbul',
          state: 'Istanbul',
          country: 'Turkey',
        );
        _savedCity = 'Istanbul';
        _savedCountry = 'Turkey';
        await _prefs.setString('city', 'Istanbul');
        await _prefs.setString('country', 'Turkey');
        await _prefs.setDouble('latitude', 41.0082);
        await _prefs.setDouble('longitude', 28.9784);
      }

      print(
        '📍 Final Location: ${_currentLocation?.city} (${_currentLocation?.latitude}, ${_currentLocation?.longitude})',
      );

      await fetchPrayerTimes();

      // Start countdown timer
      _startCountdownTimer();
    } catch (e, stacktrace) {
      print('❌ Error initializing PrayerProvider: $e');
      print(stacktrace);
    }
  }

  void _loadLocationFromCache() {
    try {
      print('📍 Loading location from cache...');
      final lat = _prefs.getDouble('latitude');
      final lon = _prefs.getDouble('longitude');
      final city = _prefs.getString('city') ?? '';
      final country = _prefs.getString('country') ?? '';

      if (lat != null && lon != null && city.isNotEmpty) {
        _currentLocation = GeoLocation(
          latitude: lat,
          longitude: lon,
          city: city,
          state: city,
          country: country,
        );
        _savedCity = city;
        _savedCountry = country;
        print('✅ Loaded location from cache: $city, $country');
      } else {
        print(
          '⚠️ Incomplete cached location data: lat=$lat, lon=$lon, city=$city, country=$country',
        );
      }
    } catch (e, stacktrace) {
      print('❌ Error loading location from cache: $e');
      print(stacktrace);
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      print('📍 Attempting to get current location...');
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        print('✅ Got location: ${location.city}, ${location.country}');
        _currentLocation = location;
        await _prefs.setString('city', location.city);
        await _prefs.setString('country', location.country);
        await _prefs.setDouble('latitude', location.latitude);
        await _prefs.setDouble('longitude', location.longitude);

        _savedCity = location.city;
        _savedCountry = location.country;
      } else {
        print('⚠️ getCurrentLocation returned null');
      }
    } catch (e, stacktrace) {
      print('❌ Error loading location: $e');
      print(stacktrace);
    }
  }

  Future<void> fetchPrayerTimes() async {
    if (_isFetching) return;
    final now = DateTime.now();
    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _minFetchInterval) {
      // Skip fetch; recently fetched
      print('⏱️ Skipping fetch: within min fetch interval');
      return;
    }

    try {
      _isFetching = true;
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      print('📍 Current Location: $_currentLocation');

      if (_currentLocation == null) {
        _errorMessage = 'Konum mevcut değil';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print(
        '🔄 Fetching prayer times for: ${_currentLocation!.city} (${_currentLocation!.latitude}, ${_currentLocation!.longitude})',
      );

      final prayerTimes = await AlAdhanService.getPrayerTimes(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        city: _currentLocation!.city,
        country: _currentLocation!.country,
      );

      print(
        '📦 Prayer Times Result: ${prayerTimes != null ? "Received" : "Null"}',
      );

      if (prayerTimes != null && prayerTimes.prayerTimesList.isNotEmpty) {
        _currentPrayerTimes = prayerTimes;
        _nextPrayer = prayerTimes.nextPrayer;
        _activePrayer = prayerTimes.activePrayer;

        // Debug: print active prayer for quick visibility
        try {
          debugPrint(
            '🔔 Active prayer: ${_activePrayer?.name} at ${_activePrayer?.time}',
          );
        } catch (_) {}

        // If the computed next prayer is in the past (some APIs return today's
        // first prayer when there are no more for today), treat it as next day's prayer
        // to avoid immediate repeated fetches.
        final now2 = DateTime.now();
        if (_nextPrayer != null && _nextPrayer!.time.isBefore(now2)) {
          print('ℹ️ nextPrayer was in the past; adjusting to next day');
          _nextPrayer = PrayerTime(
            name: _nextPrayer!.name,
            time: _nextPrayer!.time.add(const Duration(days: 1)),
            nextTime: _nextPrayer!.nextTime?.add(const Duration(days: 1)),
          );
        }

        _lastFetchTime = DateTime.now();

        print(
          '✅ Prayer Times Loaded: ${prayerTimes.prayerTimesList.length} prayers',
        );
        print(
          '⏭️ Next Prayer: ${_nextPrayer?.name} at ${_nextPrayer?.time.hour}:${_nextPrayer?.time.minute.toString().padLeft(2, '0')}',
        );

        // Schedule notifications
        await NotificationService.scheduleAllPrayerNotifications(
          prayers: prayerTimes.prayerTimesList,
          language: _prefs.getString('language') ?? 'en',
          enableSound: _prefs.getBool('enableAdhanSound') ?? true,
        );

        _errorMessage = '';
      } else {
        _errorMessage = 'Namaz vakitleri yüklenemedi';
        print(
          '❌ Failed: prayerTimes is ${prayerTimes == null ? "null" : "empty"}',
        );
        if (prayerTimes != null) {
          print(
            '   prayerTimesList length: ${prayerTimes.prayerTimesList.length}',
          );
          print('   times map: ${prayerTimes.times}');
        }
      }
    } catch (e, stacktrace) {
      _errorMessage = 'Hata: $e';
      print('❌ Error fetching prayer times: $e');
      print(stacktrace);
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> setLocation(String city, String country) async {
    try {
      final locations = await LocationService.searchLocation(city);
      if (locations.isNotEmpty) {
        _currentLocation = locations.first;
        _savedCity = city;
        _savedCountry = country;

        await _prefs.setString('city', city);
        await _prefs.setString('country', country);
        await _prefs.setDouble('latitude', _currentLocation!.latitude);
        await _prefs.setDouble('longitude', _currentLocation!.longitude);

        await fetchPrayerTimes();
      }
    } catch (e) {
      _errorMessage = 'Error setting location: $e';
      notifyListeners();
    }
  }

  void _startCountdownTimer() {
    // Use a periodic timer to update the countdown once per second.
    // If the next prayer has already passed, attempt to refresh prayer times
    // but avoid hammering the API by waiting a short cooldown after each fetch.
    const cooldownAfterFetch = Duration(seconds: 30);
    // Keep a reference to the timer so we can cancel it on dispose if needed.
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();

      if (_nextPrayer != null && _nextPrayer!.time.isAfter(now)) {
        _countdownDuration = _nextPrayer!.time.difference(now);
        _lastCountdownUpdate = now;
        notifyListeners();
        return;
      }

      // If next prayer is missing or in the past, avoid hammering the API.
      // If we fetched recently, assume the next prayer is the same prayer next day
      // and show countdown towards that.
      final last = _lastFetchTime;
      if (last == null || now.difference(last) >= _minFetchInterval) {
        if (!_isFetching) {
          // attempt a fetch to refresh times
          await fetchPrayerTimes();
        }
      } else {
        // Use the existing _nextPrayer but move it to next day to keep a stable countdown
        if (_nextPrayer != null) {
          _countdownDuration = _nextPrayer!.time
              .add(const Duration(days: 1))
              .difference(now);
          _lastCountdownUpdate = now;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Force refresh current location and prayer times
  Future<void> refreshLocation() async {
    try {
      print('🔄 Force refreshing location...');

      // Force get current location
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        print('✅ New location: ${location.city}, ${location.country}');
        _currentLocation = location;
        await _prefs.setString('city', location.city);
        await _prefs.setString('country', location.country);
        await _prefs.setDouble('latitude', location.latitude);
        await _prefs.setDouble('longitude', location.longitude);

        _savedCity = location.city;
        _savedCountry = location.country;

        // Reset last fetch time to force prayer times refresh
        _lastFetchTime = null;

        // Fetch new prayer times for the new location
        await fetchPrayerTimes();

        notifyListeners();
      } else {
        throw Exception('Konum alınamadı');
      }
    } catch (e) {
      print('❌ Error refreshing location: $e');
      throw e;
    }
  }
}
