import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/prayer_model.dart';
import '../services/emushaf_prayer_service.dart';
import '../services/home_widget_service.dart';
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
  bool _allowAutomaticPrayerRefresh = false;
  DateTime? _lastFetchTime;
  final Duration _minFetchInterval = const Duration(minutes: 5);
  String _errorMessage = '';

  // Location
  GeoLocation? _currentLocation;
  String _savedCity = '';
  String _savedState = '';
  String _savedCountry = '';
  String _savedDistrict = '';
  String _savedCountryId = '';
  String _savedCityId = '';
  String _savedDistrictId = '';
  bool _hasCompletedLocationSetup = false;
  bool _locationBootstrapCompleted = false;
  bool _useAutomaticLocation = false;

  // Countdown
  DateTime? _lastCountdownUpdate;
  Duration? _countdownDuration;
  Timer? _countdownTimer;
  
  // Adhan playing
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAdhanPlaying = false;
  double _currentAdhanVolume = 1.0;
  String? _lastAdhanPlayedForPrayer;
  String? _manuallyDismissedAdhanPrayerKey;
  final Duration _adhanThreshold = const Duration(minutes: 15);
  
  // Track audio player listeners to avoid duplicates
  StreamSubscription<void>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  
  // Track scheduled notifications to avoid duplicates
  Set<String> _scheduledNotifications = {};

  PrayerTimes? get currentPrayerTimes => _currentPrayerTimes;
  PrayerTime? get nextPrayer => _nextPrayer;
  PrayerTime? get activePrayer => _activePrayer;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  GeoLocation? get currentLocation => _currentLocation;
  String get savedCity => _savedCity;
  String get savedState => _savedState;
  String get savedCountry => _savedCountry;
  bool get useAutomaticLocation => _useAutomaticLocation;
  String get savedLocationLabel {
    final district = _savedDistrict.trim();
    final city = _savedCity.trim();
    final country = _savedCountry.trim();

    if (!_useAutomaticLocation && _isMeaningfulLocationValue(district)) {
      return district;
    }

    if (!_isMeaningfulLocationValue(city)) {
      return _isMeaningfulLocationValue(country) ? country : '';
    }

    return city;
  }
  Duration? get countdownDuration => _countdownDuration;
  bool get isAdhanPlaying => _isAdhanPlaying;
  double get currentAdhanVolume => _currentAdhanVolume;

  bool get _hasManualLookupContext {
    return !_useAutomaticLocation &&
        _savedCity.trim().isNotEmpty &&
        _savedCountry.trim().isNotEmpty;
  }

  bool get requiresManualLocationSelection {
    if (!_locationBootstrapCompleted) {
      return false;
    }

    if (_hasCompletedLocationSetup) {
      return false;
    }

    final hasSavedLookupContext =
        _isMeaningfulLocationValue(_savedCity) && _isMeaningfulLocationValue(_savedCountry);
    return !hasSavedLookupContext;
  }

  bool _isMeaningfulLocationValue(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return normalized.isNotEmpty && normalized != 'unknown';
  }

  String get _lookupCity {
    if (_hasManualLookupContext) {
      return _savedCity.trim();
    }
    if (_isMeaningfulLocationValue(_currentLocation?.city)) {
      return _currentLocation!.city.trim();
    }
    if (_isMeaningfulLocationValue(_savedCity)) {
      return _savedCity.trim();
    }
    return '';
  }

  String get _lookupCountry {
    if (_hasManualLookupContext) {
      return _savedCountry.trim();
    }
    if (_isMeaningfulLocationValue(_currentLocation?.country)) {
      return _currentLocation!.country.trim();
    }
    if (_isMeaningfulLocationValue(_savedCountry)) {
      return _savedCountry.trim();
    }
    return '';
  }

  String? get _lookupState {
    if (_hasManualLookupContext) {
      final value = _savedState.trim();
      return value.isEmpty ? null : value;
    }
    final value = _isMeaningfulLocationValue(_currentLocation?.state)
        ? _currentLocation!.state.trim()
        : _savedState.trim();
    return value.isEmpty ? null : value;
  }

  String? get _lookupDistrict {
    if (_hasManualLookupContext) {
      final value = _savedDistrict.trim();
      return value.isEmpty ? null : value;
    }
    final value = _isMeaningfulLocationValue(_currentLocation?.district)
        ? _currentLocation!.district.trim()
        : _savedDistrict.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      print('⚙️ Settings loaded: notifications=${_appSettings.prayerNotifications}, sounds=${_appSettings.prayerSounds}');

      _savedCity = _prefs.getString('city') ?? '';
      _savedState = _prefs.getString('state') ?? '';
      _savedCountry = _prefs.getString('country') ?? '';
      _savedDistrict = _prefs.getString('district') ?? '';
      _savedCountryId = _prefs.getString('emushaf_country_id') ?? '';
      _savedCityId = _prefs.getString('emushaf_city_id') ?? '';
      _savedDistrictId = _prefs.getString('emushaf_district_id') ?? '';
      _hasCompletedLocationSetup =
          _prefs.getBool('has_completed_location_setup') ?? false;
      _useAutomaticLocation = _prefs.getBool('use_automatic_location') ?? false;

      if (!_hasCompletedLocationSetup &&
          _isMeaningfulLocationValue(_savedCity) &&
          _isMeaningfulLocationValue(_savedCountry)) {
        _hasCompletedLocationSetup = true;
        await _prefs.setBool('has_completed_location_setup', true);
      }

      print('📱 PrayerProvider initializing...');

      _loadLocationFromCache();
      _locationBootstrapCompleted = true;

      if (_useAutomaticLocation) {
        await _loadCurrentLocation();
      }

      print(
        '📍 Final Location: ${_currentLocation?.city} (${_currentLocation?.latitude}, ${_currentLocation?.longitude})',
      );

      if (requiresManualLocationSelection) {
        print('📍 Manual location selection required before loading prayer times');
        _startCountdownTimer();
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _loadCachedPrayerTimesForStartup();

      await fetchPrayerTimes();

      // Set up audio context for adhan playback before playing any sounds
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      // Start countdown timer only after initial fetch is complete
      // This prevents auto-playing adhan on app startup
      _startCountdownTimer();
    } catch (e, stacktrace) {
      print('❌ Error initializing PrayerProvider: $e');
      print(stacktrace);
    } finally {
      _locationBootstrapCompleted = true;
    }
  }

  void _loadLocationFromCache() {
    try {
      print('📍 Loading location from cache...');
      final lat = _prefs.getDouble('latitude');
      final lon = _prefs.getDouble('longitude');
      final city = _prefs.getString('city') ?? '';
      final country = _prefs.getString('country') ?? '';
      final state = _prefs.getString('state') ?? '';
      final district = _prefs.getString('district') ?? '';
      final countryId = _prefs.getString('emushaf_country_id') ?? '';
      final cityId = _prefs.getString('emushaf_city_id') ?? '';
      final districtId = _prefs.getString('emushaf_district_id') ?? '';

      if (lat != null && lon != null && city.isNotEmpty) {
        _currentLocation = GeoLocation(
          latitude: lat,
          longitude: lon,
          city: city,
          state: state.isNotEmpty ? state : city,
          country: country,
          district: district,
        );
        _savedCity = city;
        _savedState = state;
        _savedCountry = country;
        _savedDistrict = district;
        _savedCountryId = countryId;
        _savedCityId = cityId;
        _savedDistrictId = districtId;
        _hasCompletedLocationSetup = true;
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
        _useAutomaticLocation = true;
        await _prefs.setBool('use_automatic_location', true);
        await _prefs.setDouble('latitude', location.latitude);
        await _prefs.setDouble('longitude', location.longitude);

        if (_isMeaningfulLocationValue(location.city) &&
            _isMeaningfulLocationValue(location.country)) {
          await _prefs.setString('city', location.city);
          await _prefs.setString('state', location.state);
          await _prefs.setString('country', location.country);
          await _prefs.setString('district', location.district);
          await _prefs.remove('emushaf_country_id');
          await _prefs.remove('emushaf_city_id');
          await _prefs.remove('emushaf_district_id');

          _savedCity = location.city;
          _savedState = location.state;
          _savedCountry = location.country;
          _savedDistrict = location.district;
          _savedCountryId = '';
          _savedCityId = '';
          _savedDistrictId = '';
          _hasCompletedLocationSetup = true;
          await _prefs.setBool('has_completed_location_setup', true);
        } else {
          print(
            '⚠️ Current location text is incomplete, keeping saved lookup context: '
            'city=${location.city}, state=${location.state}, country=${location.country}, district=${location.district}',
          );
        }

        _useAutomaticLocation = true;
        await _prefs.setBool('use_automatic_location', true);
      } else {
        print('⚠️ getCurrentLocation returned null');
      }
    } catch (e, stacktrace) {
      print('❌ Error loading location: $e');
      print(stacktrace);
    }
  }

  Future<void> fetchPrayerTimes({bool bypassCache = false}) async {
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

      final lookupCity = _lookupCity;
      final lookupCountry = _lookupCountry;
      final lookupState = _lookupState;
      final lookupDistrict = _lookupDistrict;

      print(
        '🔄 Fetching prayer times for: $lookupCity (${_currentLocation!.latitude}, ${_currentLocation!.longitude})',
      );
      print(
        '🧭 Fetch context => '
        'country=$lookupCountry, state=$lookupState, district=$lookupDistrict, '
        'savedCountryId=$_savedCountryId, savedCityId=$_savedCityId, savedDistrictId=$_savedDistrictId',
      );

      PrayerTimes? prayerTimes = await EmushafPrayerService.getPrayerTimes(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        city: lookupCity,
        country: lookupCountry,
        bypassCache: bypassCache,
        countryId: _savedCountryId.trim().isEmpty ? null : _savedCountryId,
        cityId: _savedCityId.trim().isEmpty ? null : _savedCityId,
        districtId: _savedDistrictId.trim().isEmpty ? null : _savedDistrictId,
        state: lookupState,
        district: lookupDistrict,
      );

      if (prayerTimes == null &&
          (lookupDistrict != null ||
              lookupState != null ||
              _savedDistrictId.trim().isNotEmpty ||
              _savedCityId.trim().isNotEmpty ||
              _savedCountryId.trim().isNotEmpty)) {
        print('↩️ Retrying prayer times fetch with relaxed location matching...');
        prayerTimes = await EmushafPrayerService.getPrayerTimes(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          city: lookupCity,
          country: lookupCountry,
          bypassCache: true,
          state: null,
          district: null,
        );
      }

      if (prayerTimes == null && _savedState.trim().isNotEmpty) {
        print('↩️ Retrying prayer times fetch with saved state as city fallback...');
        prayerTimes = await EmushafPrayerService.getPrayerTimes(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          city: _savedState.trim(),
          country: lookupCountry,
          bypassCache: true,
          state: null,
          district: null,
        );
      }

      print(
        '📦 Prayer Times Result: ${prayerTimes != null ? "Received" : "Null"}',
      );

      if (prayerTimes != null && prayerTimes.prayerTimesList.isNotEmpty) {
        _applyPrayerTimes(prayerTimes, allowAutomaticRefresh: true);

        _lastFetchTime = DateTime.now();

        await HomeWidgetService.syncPrayerTimes(prayerTimes: prayerTimes);

        // Reset adhan tracking for new prayer cycle
        _lastAdhanPlayedForPrayer = null;

        // If the app is opened while a prayer alert is actively sounding,
        // continue playback inside the app so opening it doesn't silence the adhan.
        print(
          '✅ Prayer Times Loaded: ${prayerTimes.prayerTimesList.length} prayers',
        );
        print(
          '⏭️ Next Prayer: ${_nextPrayer?.name} at ${_nextPrayer?.time.hour}:${_nextPrayer?.time.minute.toString().padLeft(2, '0')}',
        );

        await _scheduleNotificationsForCurrentAndNextDay(prayerTimes);

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

  Future<void> refreshPrayerTimes() async {
    _lastFetchTime = null;
    _scheduledNotifications.clear();
    await fetchPrayerTimes(bypassCache: true);
  }

  Future<void> setManualLocation(
    String city,
    String country, {
    String? district,
    String? state,
    String? countryId,
    String? cityId,
    String? districtId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final trimmedDistrict = district?.trim();
      final trimmedState = state?.trim();
      final hasDistrict = trimmedDistrict != null && trimmedDistrict.isNotEmpty;
      final hasState = trimmedState != null && trimmedState.isNotEmpty;
      final hasDistinctState = hasState &&
          _normalizeLookupValue(trimmedState!) != _normalizeLookupValue(country);
      final searchQuery = hasDistrict
          ? '$trimmedDistrict, $city, $country'
          : hasDistinctState
              ? '$city, ${trimmedState!}, $country'
              : '$city, $country';
      final locations = await LocationService.searchLocation(searchQuery);

      if (locations.isEmpty) {
        throw Exception('Konum bulunamadı');
      }

      final normalizedCountry = _normalizeCountryValue(country);
      _currentLocation = locations.firstWhere(
        (location) => _normalizeCountryValue(location.country) == normalizedCountry,
        orElse: () => locations.first,
      );
      final resolvedLocation = _currentLocation!;
      _savedCity = city.trim();
      _savedState = hasState ? trimmedState! : '';
      _savedCountry = country.trim();
      _savedDistrict = trimmedDistrict ?? '';
      _savedCountryId = countryId?.trim() ?? '';
      _savedCityId = cityId?.trim() ?? '';
      _savedDistrictId = districtId?.trim() ?? '';
      _currentLocation = GeoLocation(
        latitude: resolvedLocation.latitude,
        longitude: resolvedLocation.longitude,
        city: _savedCity,
        state: hasState ? trimmedState! : resolvedLocation.state,
        country: _savedCountry,
        district: hasDistrict ? trimmedDistrict! : resolvedLocation.district,
      );
      _useAutomaticLocation = false;
      _lastFetchTime = null;
      _scheduledNotifications.clear();

      await _prefs.setString('city', _savedCity);
      await _prefs.setString('state', _savedState);
      await _prefs.setString('country', _savedCountry);
      await _prefs.setString('district', _savedDistrict);
      await _prefs.setString('emushaf_country_id', _savedCountryId);
      await _prefs.setString('emushaf_city_id', _savedCityId);
      await _prefs.setString('emushaf_district_id', _savedDistrictId);
      await _prefs.setBool('has_completed_location_setup', true);
      await _prefs.setBool('use_automatic_location', false);
      await _prefs.setDouble('latitude', _currentLocation!.latitude);
      await _prefs.setDouble('longitude', _currentLocation!.longitude);
      _hasCompletedLocationSetup = true;

      await fetchPrayerTimes(bypassCache: true);
    } catch (e) {
      _errorMessage = 'Error setting location: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startCountdownTimer() {
    if (_countdownTimer != null) {
      return;
    }

    // Use a periodic timer to update the countdown once per second.
    // If the next prayer has already passed, attempt to refresh prayer times
    // but avoid hammering the API by waiting a short cooldown after each fetch.
    const cooldownAfterFetch = Duration(seconds: 30);
    // Keep a reference to the timer so we can cancel it on dispose if needed.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();

      // Update active prayer in real-time
      if (_currentPrayerTimes != null) {
        final newActivePrayer = _currentPrayerTimes!.activePrayer;
        if (newActivePrayer?.name != _activePrayer?.name) {
          _activePrayer = newActivePrayer;
          print('🔄 Active prayer changed to: ${_activePrayer?.name}');

          try {
            await HomeWidgetService.syncPrayerTimes(
              prayerTimes: _currentPrayerTimes!,
            );
          } catch (e) {
            print('⚠️ Failed to sync widget on active prayer change: $e');
          }

          // NOTE: Adhan playback is now handled only through notifications
          // Do NOT play adhan here - let the notification service handle it
          // BUG FIX: Removed automatic adhan playing for active prayers
          // User can enable/disable adhan from settings
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

      // Prayer time has arrived or passed - handle adhan and refresh
      if (_nextPrayer != null && !_isFetching) {
        final timeDiff = _nextPrayer!.time.difference(now);

        // If prayer time has just arrived (within last 3 minutes), trigger adhan.
        // Wide window so the app catching up after brief background/Doze still plays adhan.
        if (timeDiff <= Duration.zero && timeDiff > Duration(minutes: -3)) {
          print('🔔 PRAYER TIME ARRIVED: ${_nextPrayer!.name} - Triggering immediate actions');
          // Only trigger once per prayer time
          if (_lastAdhanPlayedForPrayer != '${_nextPrayer!.name}_ontime') {
            await _checkAndPlayAdhanOnTime(_nextPrayer!);
            _lastAdhanPlayedForPrayer = '${_nextPrayer!.name}_ontime';
          }
        }

        // Only fetch new times if prayer has passed by more than 1 minute
        if (_allowAutomaticPrayerRefresh && timeDiff < Duration(minutes: -1)) {
          print('🔄 Prayer time passed, fetching next prayer times...');
          await fetchPrayerTimes();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
    // Cancel audio player subscriptions
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
  }

  /// Force-reschedule all notifications with the latest settings.
  /// Call this whenever notification settings (offset, enabled, sound) change.
  Future<void> rescheduleNotifications() async {
    if (_currentPrayerTimes == null) return;
    print('🔄 Rescheduling notifications with updated settings...');
    _scheduledNotifications.clear();
    await NotificationService.cancelAllNotifications();
    await NotificationService.scheduleAllPrayerNotificationsWithSettings(
      prayers: _currentPrayerTimes!.prayerTimesList,
      language: _appSettings.language,
      notificationSettings: _appSettings.prayerNotifications,
      soundSettings: _appSettings.prayerSounds,
      offsetSettings: _appSettings.prayerNotificationOffsets,
    );
    final today = DateTime.now().toString().split(' ')[0];
    _scheduledNotifications.add('${today}_${_appSettings.language}');
    print('✅ Notifications rescheduled');
  }

  /// Reset adhan tracking state when approaching a new prayer cycle
  Future<void> _checkAndPlayAdhan(PrayerTime prayer, Duration remaining) async {
    // Adhan plays ONLY at the exact prayer time via _checkAndPlayAdhanOnTime.
    // This function now only resets the tracking state for the next cycle.
    if (remaining > _adhanThreshold) {
      _lastAdhanPlayedForPrayer = null;
      _manuallyDismissedAdhanPrayerKey = null;
    }
  }

  /// Play adhan for the currently active prayer (when app starts with active prayer)
  Future<void> _checkAndPlayAdhanForActivePrayer(PrayerTime prayer) async {
    print('🔔 Checking adhan for active prayer: ${prayer.name}');
    
    // Only play adhan if sound is enabled for this prayer
    final soundEnabled = _appSettings.prayerSounds[prayer.name] ?? true;
    final notificationEnabled = _appSettings.prayerNotifications[prayer.name] ?? true;
    print('🔔 Sound enabled for ${prayer.name}: $soundEnabled');
    
    if (!soundEnabled) return;

    // If the exact prayer notification is enabled, let the notification
    // channel handle the audio so we do not play the adhan twice.
    if (notificationEnabled) {
      print('📢 Exact notification is enabled for ${prayer.name}; skipping in-app adhan to avoid duplicate playback');
      return;
    }

    // Only continue adhan if the prayer time is very recent.
    // This lets the app take over when opened during the adhan,
    // without replaying it long after the prayer time has started.
    final now = DateTime.now();
    final timeSincePrayer = now.difference(prayer.time);
    const maxTimeForAdhan = Duration(minutes: 2);
    
    print('🔔 Time since prayer: ${timeSincePrayer.inMinutes} minutes');
    
    if (timeSincePrayer > maxTimeForAdhan) {
      print('🔔 Prayer time too old (${timeSincePrayer.inMinutes} minutes ago), skipping adhan');
      return;
    }

    final prayerKey = _buildPrayerPlaybackKey(prayer);
    if (_manuallyDismissedAdhanPrayerKey == prayerKey) {
      print('ℹ️ Adhan was manually dismissed for ${prayer.name}, skipping resume');
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
    // Notification and adhan settings are independent:
    // notification decides whether a scheduled alert exists,
    // sound decides whether the adhan audio should play in-app.
    final soundEnabled = _appSettings.prayerSounds[prayer.name] ?? true;
    final notificationEnabled = _appSettings.prayerNotifications[prayer.name] ?? true;

    print('🔔 Prayer Time Check: ${prayer.name} | Sound: $soundEnabled | Notification: $notificationEnabled');

    // Check if we haven't played adhan for this prayer yet
    if (_lastAdhanPlayedForPrayer != '${prayer.name}_ontime') {
      print('🔔 Prayer time arrived: ${prayer.name}');

      // If the notification is enabled, its channel already carries the prayer audio.
      // Skipping in-app playback prevents Maghrib and other prayers from sounding twice.
      if (notificationEnabled) {
        print('📢 Exact notification is enabled for ${prayer.name}; skipping in-app adhan to avoid duplicate playback');
        _lastAdhanPlayedForPrayer = '${prayer.name}_ontime';
        return;
      }

      if (soundEnabled) {
        print('🎵 Playing adhan sound for ${prayer.name}');
        await _playAdhanForPrayer(prayer.name);
      } else {
        print('🔇 Sound disabled for ${prayer.name}, skipping in-app adhan');
      }

      if (notificationEnabled) {
        print('📢 Scheduled notification remains enabled for ${prayer.name}');
      } else {
        print('🔕 Scheduled notification disabled for ${prayer.name}');
      }

      _lastAdhanPlayedForPrayer = '${prayer.name}_ontime';
    }
  }

  Future<void> resumeActivePrayerAdhanIfNeeded() async {
    final activePrayer = _activePrayer;
    if (activePrayer == null) return;
    if (_isAdhanPlaying) return;
    if (_manuallyDismissedAdhanPrayerKey == _buildPrayerPlaybackKey(activePrayer)) {
      return;
    }
    await _checkAndPlayAdhanForActivePrayer(activePrayer);
  }

  Future<void> _scheduleNotificationsForCurrentAndNextDay(
    PrayerTimes todayPrayerTimes,
  ) async {
    final scheduleAnchor = DateTime.now();
    final dayKey =
        '${scheduleAnchor.year}-${scheduleAnchor.month.toString().padLeft(2, '0')}-${scheduleAnchor.day.toString().padLeft(2, '0')}';
    final cityKey = _currentLocation?.city ?? _savedCity;
    final scheduleKey = '${dayKey}_${_appSettings.language}_$cityKey';

    if (_scheduledNotifications.contains(scheduleKey)) {
      print('⏭️ Notifications already scheduled for horizon ($scheduleKey), skipping');
      return;
    }

    print('📢 Clearing old notifications and scheduling current + next day ($scheduleKey)...');
    await NotificationService.cancelAllNotifications();

    await NotificationService.scheduleAllPrayerNotificationsWithSettings(
      prayers: todayPrayerTimes.prayerTimesList,
      language: _appSettings.language,
      notificationSettings: _appSettings.prayerNotifications,
      soundSettings: _appSettings.prayerSounds,
      offsetSettings: _appSettings.prayerNotificationOffsets,
      idOffset: 0,
    );

    try {
      if (_currentLocation != null) {
        final lookupCity = _lookupCity;
        final lookupCountry = _lookupCountry;
        final lookupState = _lookupState;
        final lookupDistrict = _lookupDistrict;
        final tomorrowPrayerTimes = await EmushafPrayerService.getPrayerTimes(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          city: lookupCity,
          country: lookupCountry,
          countryId: _savedCountryId.trim().isEmpty ? null : _savedCountryId,
          cityId: _savedCityId.trim().isEmpty ? null : _savedCityId,
          districtId: _savedDistrictId.trim().isEmpty ? null : _savedDistrictId,
          state: lookupState,
          district: lookupDistrict,
          date: DateTime.now().add(const Duration(days: 1)),
        );

        if (tomorrowPrayerTimes != null &&
            tomorrowPrayerTimes.prayerTimesList.isNotEmpty) {
          await NotificationService.scheduleAllPrayerNotificationsWithSettings(
            prayers: tomorrowPrayerTimes.prayerTimesList,
            language: _appSettings.language,
            notificationSettings: _appSettings.prayerNotifications,
            soundSettings: _appSettings.prayerSounds,
            offsetSettings: _appSettings.prayerNotificationOffsets,
            idOffset: 10000,
          );
          print('✅ Tomorrow notifications scheduled');
        } else {
          print('⚠️ Tomorrow prayer times unavailable, only current day scheduled');
        }
      }
    } catch (e) {
      print('⚠️ Error scheduling tomorrow notifications: $e');
    }

    _scheduledNotifications
      ..clear()
      ..add(scheduleKey);
  }

  /// Play adhan sound for a specific prayer
  Future<void> _playAdhanForPrayer(String prayerName) async {
    try {
      // Cancel any previous listeners to prevent duplicates
      await _playerStateSubscription?.cancel();
      await _playerCompleteSubscription?.cancel();
      
      // Stop any currently playing audio first
      await _audioPlayer.stop();
      _currentAdhanVolume = 1.0;
      
      // Notify Android that adhan is starting (for volume button monitoring).
      // Wrapped in try-catch: if the native channel is unavailable, audio still plays.
      try {
        const platform = MethodChannel('com.vakit.app.ezanlar/adhan');
        await platform.invokeMethod('startAdhanPlayback');
      } catch (e) {
        print('ℹ️ Native adhan channel unavailable, continuing with audio: $e');
      }
      
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
        
        _manuallyDismissedAdhanPrayerKey = null;

        // Set audio source and play
        await _audioPlayer.setSource(AssetSource('sounds/$soundFile'));
        await _audioPlayer.setVolume(_currentAdhanVolume);
        await _audioPlayer.resume();
        _isAdhanPlaying = true;
        notifyListeners();
        
        // Flag to prevent multiple state callbacks for the same stop event
        bool _stopHandled = false;
        
        // Listen for completion to stop the player
        _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
          if (!_stopHandled) {
            _stopHandled = true;
            print('✅ Adhan playback completed for $prayerName');
            _notifyAdhanStopped();
          }
        });
        
        // Listen for state changes ONLY (don't call stop again - it causes loop)
        _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
          if (!_stopHandled) {
            // If paused by volume button or user action, mark as handled
            if (state == PlayerState.paused || state == PlayerState.stopped) {
              _stopHandled = true;
              print('🔇 Adhan stopped: $state');
              _notifyAdhanStopped();
            }
          }
        });
        
        // Safety timeout - stop after 2 minutes max
        Future.delayed(const Duration(minutes: 2), () {
          if (!_stopHandled && _audioPlayer.state == PlayerState.playing) {
            _stopHandled = true;
            print('⏰ Safety timeout: stopping adhan playback for $prayerName');
            _notifyAdhanStopped();
            _audioPlayer.stop();
          }
        });
        
      } else {
        print('❌ No sound file found for prayer: $prayerName');
        _notifyAdhanStopped();
      }
    } catch (e) {
      print('❌ Error playing adhan for $prayerName: $e');
      // Ensure player is stopped on error
      _notifyAdhanStopped();
      await _audioPlayer.stop();
    }
  }
  
  /// Notify Android that adhan playback has stopped
  Future<void> _notifyAdhanStopped() async {
    _isAdhanPlaying = false;
    _currentAdhanVolume = 1.0;
    notifyListeners();
    try {
      const platform = MethodChannel('com.vakit.app.ezanlar/adhan');
      await platform.invokeMethod('stopAdhanPlayback');
    } catch (e) {
      print('⚠️ Error notifying adhan stop: $e');
    }
  }
  
  /// Get current audio player state (for testing and debugging)
  PlayerState get currentAudioState => _audioPlayer.state;

  /// Force refresh current location and prayer times
  Future<void> refreshLocation({bool forceAutomatic = false}) async {
    try {
      print('🔄 Force refreshing location...');

      if (!_useAutomaticLocation && !forceAutomatic) {
        await refreshPrayerTimes();
        return;
      }

      // Force get current location
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        print('✅ New location: ${location.city}, ${location.country}');
        _currentLocation = location;
        _useAutomaticLocation = true;
        await _prefs.setBool('use_automatic_location', true);
        await _prefs.setDouble('latitude', location.latitude);
        await _prefs.setDouble('longitude', location.longitude);

        if (_isMeaningfulLocationValue(location.city) &&
            _isMeaningfulLocationValue(location.country)) {
          _savedDistrict = location.district;
          _savedState = location.state;
          await _prefs.setString('city', location.city);
          await _prefs.setString('state', location.state);
          await _prefs.setString('country', location.country);
          await _prefs.setString('district', location.district);
          await _prefs.remove('emushaf_country_id');
          await _prefs.remove('emushaf_city_id');
          await _prefs.remove('emushaf_district_id');
          await _prefs.setBool('has_completed_location_setup', true);

          _savedCity = location.city;
          _savedState = location.state;
          _savedCountry = location.country;
          _savedCountryId = '';
          _savedCityId = '';
          _savedDistrictId = '';
          _hasCompletedLocationSetup = true;
        } else {
          print(
            '⚠️ Refreshed coordinates are valid but placemark text is incomplete; '
            'continuing with saved city/country fallback',
          );
        }

        // Reset last fetch time to force prayer times refresh
        _lastFetchTime = null;

        // Fetch new prayer times for the new location
        await fetchPrayerTimes(bypassCache: true);

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
      final activePrayer = _activePrayer;
      if (activePrayer != null) {
        _manuallyDismissedAdhanPrayerKey = _buildPrayerPlaybackKey(activePrayer);
      }
      await _audioPlayer.stop();
      await _notifyAdhanStopped();
      print('🛑 Adhan stopped manually');
    } catch (e) {
      print('❌ Error stopping adhan: $e');
    }
  }

  String _buildPrayerPlaybackKey(PrayerTime prayer) {
    return '${prayer.name}_${prayer.time.toIso8601String()}';
  }

  Future<void> lowerAdhanVolume() async {
    if (!_isAdhanPlaying) return;
    try {
      _currentAdhanVolume = (_currentAdhanVolume - 0.25).clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_currentAdhanVolume);
      notifyListeners();
      print('🔉 Adhan volume lowered to $_currentAdhanVolume');
    } catch (e) {
      print('❌ Error lowering adhan volume: $e');
    }
  }

  Future<void> muteAdhan() async {
    if (!_isAdhanPlaying) return;
    try {
      _currentAdhanVolume = 0.0;
      await _audioPlayer.setVolume(0.0);
      notifyListeners();
      print('🔇 Adhan muted');
    } catch (e) {
      print('❌ Error muting adhan: $e');
    }
  }

  String _normalizeLookupValue(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _loadCachedPrayerTimesForStartup() async {
    final cachedPrayerTimes = await EmushafPrayerService.getCachedPrayerTimesForDate(
      city: _lookupCity,
      country: _lookupCountry,
      countryId: _savedCountryId.trim().isEmpty ? null : _savedCountryId,
      cityId: _savedCityId.trim().isEmpty ? null : _savedCityId,
      districtId: _savedDistrictId.trim().isEmpty ? null : _savedDistrictId,
      state: _lookupState,
      district: _lookupDistrict,
      date: DateTime.now(),
    );
    if (cachedPrayerTimes == null || cachedPrayerTimes.prayerTimesList.isEmpty) {
      print('No cached prayer times found for startup');
      return;
    }

    _applyPrayerTimes(cachedPrayerTimes, allowAutomaticRefresh: false);
    _errorMessage = '';
    print('Loaded cached prayer times for startup');
  }

  void _applyPrayerTimes(
    PrayerTimes prayerTimes, {
    required bool allowAutomaticRefresh,
  }) {
    _currentPrayerTimes = prayerTimes;
    _nextPrayer = prayerTimes.nextPrayer;
    _activePrayer = prayerTimes.activePrayer;
    _allowAutomaticPrayerRefresh = allowAutomaticRefresh;
    final now = DateTime.now();
    if (_nextPrayer != null && _nextPrayer!.time.isBefore(now)) {
      _nextPrayer = PrayerTime(
        name: _nextPrayer!.name,
        time: _nextPrayer!.time.add(const Duration(days: 1)),
        nextTime: _nextPrayer!.nextTime?.add(const Duration(days: 1)),
      );
    }

    if (_nextPrayer != null) {
      _countdownDuration = _nextPrayer!.time.difference(now);
      if (_countdownDuration!.isNegative) {
        _countdownDuration = Duration.zero;
      }
      _lastCountdownUpdate = now;
    } else {
      _countdownDuration = null;
      _lastCountdownUpdate = null;
    }
  }

  String _normalizeCountryValue(String value) {
    final normalized = _normalizeLookupValue(value);
    const aliases = <String, String>{
      'turkiye': 'turkey',
      'turkey': 'turkey',
      'almanya': 'germany',
      'deutschland': 'germany',
      'germany': 'germany',
      'hollanda': 'netherlands',
      'netherlands': 'netherlands',
      'amerika birlesik devletleri': 'usa',
      'united states': 'usa',
      'united states of america': 'usa',
      'usa': 'usa',
      'abd': 'usa',
      'birlesik krallik': 'united kingdom',
      'ingiltere': 'united kingdom',
      'great britain': 'united kingdom',
      'united kingdom': 'united kingdom',
      'birlesik arap emirlikleri': 'united arab emirates',
      'uae': 'united arab emirates',
      'united arab emirates': 'united arab emirates',
    };
    return aliases[normalized] ?? normalized;
  }
}




