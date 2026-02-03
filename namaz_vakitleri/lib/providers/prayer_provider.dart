import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/prayer_model.dart';
import '../services/aladhan_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../providers/app_settings.dart';

class PrayerProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  late AppSettings _appSettings;

  PrayerProvider({required AppSettings appSettings}) {
    _appSettings = appSettings;
  }

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
  
  // Adhan playing
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _lastAdhanPlayedForPrayer;
  final Duration _adhanThreshold = const Duration(minutes: 15);

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

      // Set up audio context for adhan playback before playing any sounds
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      // Listen for audio focus changes to stop adhan when volume keys are pressed
      _audioPlayer.onPlayerStateChanged.listen((state) {
        print('🎵 Audio player state changed: $state');
      });

      // Handle audio interruptions (like volume key presses)
      _audioPlayer.onPlayerComplete.listen((event) {
        print('✅ Adhan playback completed');
      });

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

        // Reset adhan tracking for new prayer cycle
        _lastAdhanPlayedForPrayer = null;

        print(
          '✅ Prayer Times Loaded: ${prayerTimes.prayerTimesList.length} prayers',
        );
        print(
          '⏭️ Next Prayer: ${_nextPrayer?.name} at ${_nextPrayer?.time.hour}:${_nextPrayer?.time.minute.toString().padLeft(2, '0')}',
        );

        // Schedule notifications
        await NotificationService.scheduleAllPrayerNotificationsWithSettings(
          prayers: prayerTimes.prayerTimesList,
          language: _appSettings.language,
          notificationSettings: _appSettings.prayerNotifications,
          soundSettings: _appSettings.prayerSounds,
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

      // Update active prayer in real-time
      if (_currentPrayerTimes != null) {
        final newActivePrayer = _currentPrayerTimes!.activePrayer;
        if (newActivePrayer?.name != _activePrayer?.name) {
          _activePrayer = newActivePrayer;
          print('🔄 Active prayer changed to: ${_activePrayer?.name}');

          // Play adhan for newly active prayer if sounds are enabled
          if (_activePrayer != null) {
            await _checkAndPlayAdhanForActivePrayer(_activePrayer!);
          }
        }
      }

      if (_nextPrayer != null && _nextPrayer!.time.isAfter(now)) {
        _countdownDuration = _nextPrayer!.time.difference(now);
        _lastCountdownUpdate = now;

        // Check if we should play adhan for approaching prayer
        await _checkAndPlayAdhan(_nextPrayer!, _countdownDuration!);

        notifyListeners();
        return;
      }

      // Prayer time has arrived or passed - play adhan if not already played
      if (_nextPrayer != null && !_isFetching) {
        final timeDiff = _nextPrayer!.time.difference(now);

        // If prayer time has just arrived (within last minute) or just passed, play adhan
        if (timeDiff <= Duration.zero && timeDiff > Duration(minutes: -1)) {
          await _checkAndPlayAdhanOnTime(_nextPrayer!);
        }

        // Schedule next prayer times
        await fetchPrayerTimes();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.dispose();
  }

  /// Check if adhan should be played when approaching prayer time
  Future<void> _checkAndPlayAdhan(PrayerTime prayer, Duration remaining) async {
    // Only play adhan if sound is enabled for this prayer
    final soundEnabled = _appSettings.prayerSounds[prayer.name] ?? true;
    if (!soundEnabled) return;

    // Check if we're within the threshold and haven't played for this prayer yet
    if (remaining <= _adhanThreshold && remaining > Duration.zero) {
      if (_lastAdhanPlayedForPrayer != prayer.name) {
        await _playAdhanForPrayer(prayer.name);
        _lastAdhanPlayedForPrayer = prayer.name;
      }
    } else if (remaining > _adhanThreshold) {
      // Reset when we're outside the threshold (new prayer cycle)
      _lastAdhanPlayedForPrayer = null;
    }
  }

  /// Play adhan for the currently active prayer (when app starts with active prayer)
  Future<void> _checkAndPlayAdhanForActivePrayer(PrayerTime prayer) async {
    print('🔔 Checking adhan for active prayer: ${prayer.name}');
    
    // Only play adhan if sound is enabled for this prayer
    final soundEnabled = _appSettings.prayerSounds[prayer.name] ?? true;
    print('🔔 Sound enabled for ${prayer.name}: $soundEnabled');
    
    if (!soundEnabled) return;

    // Only play adhan if the prayer time is recent (within last 30 minutes)
    // This prevents adhan from playing if app is opened hours after prayer time
    final now = DateTime.now();
    final timeSincePrayer = now.difference(prayer.time);
    const maxTimeForAdhan = Duration(minutes: 30);
    
    print('🔔 Time since prayer: ${timeSincePrayer.inMinutes} minutes');
    
    if (timeSincePrayer > maxTimeForAdhan) {
      print('🔔 Prayer time too old (${timeSincePrayer.inMinutes} minutes ago), skipping adhan');
      return;
    }

    // Check if we haven't played adhan for this active prayer yet
    if (_lastAdhanPlayedForPrayer != '${prayer.name}_active') {
      print('🔔 Active prayer detected: ${prayer.name} - Playing adhan');
      await _playAdhanForPrayer(prayer.name);
      _lastAdhanPlayedForPrayer = '${prayer.name}_active';
    } else {
      print('🔔 Adhan already played for active prayer: ${prayer.name}');
    }
  }

  /// Play adhan when prayer time arrives
  Future<void> _checkAndPlayAdhanOnTime(PrayerTime prayer) async {
    // Only play adhan if sound is enabled for this prayer
    final soundEnabled = _appSettings.prayerSounds[prayer.name] ?? true;
    final notificationEnabled = _appSettings.prayerNotifications[prayer.name] ?? true;

    // If neither sound nor notification is enabled, return
    if (!soundEnabled && !notificationEnabled) return;

    // Check if we haven't played adhan for this prayer yet
    if (_lastAdhanPlayedForPrayer != '${prayer.name}_ontime') {
      print('🔔 Prayer time arrived: ${prayer.name} - Playing adhan and showing notification');

      // Show notification if enabled
      if (notificationEnabled) {
        await NotificationService.showPrayerTimeNotification(
          prayerName: prayer.name,
          language: _appSettings.language,
        );
      }

      // Play adhan if sound is enabled
      if (soundEnabled) {
        await _playAdhanForPrayer(prayer.name);
      }

      _lastAdhanPlayedForPrayer = '${prayer.name}_ontime';
    }
  }

  /// Play adhan sound for a specific prayer
  Future<void> _playAdhanForPrayer(String prayerName) async {
    try {
      // Stop any currently playing audio first
      await _audioPlayer.stop();
      
      // Map prayer names to sound files
      final soundFiles = {
        'Fajr': 'sabah_ezan.mp3',
        'Dhuhr': 'ogle_ezan.mp3',
        'Asr': 'ikindi_ezan.mp3',
        'Maghrib': 'aksam_ezan.mp3',
        'Isha': 'yatsi_ezan.mp3',
      };

      final soundFile = soundFiles[prayerName];
      if (soundFile != null) {
        print('🎵 Playing adhan for $prayerName: $soundFile');
        
        // Set audio source and play
        await _audioPlayer.setSource(AssetSource('sounds/$soundFile'));
        await _audioPlayer.resume();
        
        // Listen for completion to stop the player
        _audioPlayer.onPlayerComplete.listen((event) {
          print('✅ Adhan playback completed for $prayerName');
          _audioPlayer.stop();
        });
        
        // Also listen for errors
        _audioPlayer.onPlayerStateChanged.listen((state) {
          print('🎵 Audio player state: $state for $prayerName');
        });
        
        // Safety timeout - stop after 2 minutes max
        Future.delayed(const Duration(minutes: 2), () {
          if (_audioPlayer.state == PlayerState.playing) {
            print('⏰ Safety timeout: stopping adhan playback for $prayerName');
            _audioPlayer.stop();
          }
        });
        
      } else {
        print('❌ No sound file found for prayer: $prayerName');
      }
    } catch (e) {
      print('❌ Error playing adhan for $prayerName: $e');
      // Ensure player is stopped on error
      await _audioPlayer.stop();
    }
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

  /// Stop currently playing adhan
  Future<void> stopAdhan() async {
    try {
      await _audioPlayer.stop();
      print('🛑 Adhan stopped manually');
    } catch (e) {
      print('❌ Error stopping adhan: $e');
    }
  }
}
