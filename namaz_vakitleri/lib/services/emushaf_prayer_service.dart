import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_model.dart';

class EmushafPrayerService {
  static const String _baseUrl = 'https://ezanvakti.emushaf.net';
  static const String _cacheKeyPrefix = 'emushaf_prayer_times_v2_';
  static const String _legacyCacheKeyPrefix = 'prayer_times_';
  static const String _previousCacheKeyPrefix = 'emushaf_prayer_times_v1_';
  static const String _cacheSource = 'emushaf_v2';
  static const String _cacheMigrationKey = 'emushaf_cache_migrated_v2';

  static List<_Country>? _countryCache;
  static final Map<String, List<_City>> _cityCache = {};
  static final Map<String, List<_District>> _districtCache = {};

  static Future<PrayerTimes?> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    bool bypassCache = false,
    String? countryId,
    String? cityId,
    String? districtId,
    String? state,
    String? district,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    await _migrateLegacyCacheIfNeeded();
    if (!bypassCache) {
      final cached = await _getCachedPrayerTimes(
        city,
        targetDate,
        countryId: countryId,
        cityId: cityId,
        districtId: districtId,
        country: country,
        state: state,
        district: district,
      );
      if (cached != null) {
        print('Using cached prayer times for $city');
        return cached;
      }
    }

    try {
      final hasPinnedIds =
          (countryId != null && countryId.trim().isNotEmpty) ||
          (cityId != null && cityId.trim().isNotEmpty) ||
          (districtId != null && districtId.trim().isNotEmpty);

      final countryMatch = countryId != null && countryId.trim().isNotEmpty
          ? _Country(id: countryId.trim(), name: country, englishName: country)
          : await _resolveCountry(country);
      if (countryMatch == null) {
        print('No country match found for $country');
        return null;
      }

      var cityMatch = cityId != null && cityId.trim().isNotEmpty
          ? _City(id: cityId.trim(), name: city, englishName: city)
          : await _resolveCity(
              countryId: countryMatch.id,
              countryName: country,
              city: city,
              state: state,
            );
      if (cityMatch == null && hasPinnedIds) {
        cityMatch = await _resolveCity(
          countryId: countryMatch.id,
          countryName: country,
          city: city,
          state: state,
        );
      }
      if (cityMatch == null) {
        print('No city/state match found for city=$city state=$state country=$country');
        return null;
      }

      var districtMatch = districtId != null && districtId.trim().isNotEmpty
          ? _District(
              id: districtId.trim(),
              name: district?.trim().isNotEmpty == true ? district!.trim() : city,
              englishName:
                  district?.trim().isNotEmpty == true ? district!.trim() : city,
            )
          : await _resolveDistrict(
              cityId: cityMatch.id,
              city: city,
              state: state,
              district: district,
            );
      if (districtMatch == null && hasPinnedIds) {
        districtMatch = await _resolveDistrict(
          cityId: cityMatch.id,
          city: city,
          state: state,
          district: district,
        );
      }
      if (districtMatch == null) {
        print('No district match found for district=$district city=$city state=$state');
        return null;
      }

      print(
        '📍 Emushaf resolved => '
        'country=${countryMatch.name}(${countryMatch.id}), '
        'city=${cityMatch.name}(${cityMatch.id}), '
        'district=${districtMatch.name}(${districtMatch.id})',
      );

      final prayerTimes = await _fetchMonthAndExtractDay(
        districtId: districtMatch.id,
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        countryId: countryMatch.id,
        cityId: cityMatch.id,
        state: state,
        district: district,
        targetDate: targetDate,
      );

      if (prayerTimes == null && hasPinnedIds) {
        print('Pinned Emushaf IDs did not return prayer times, retrying with name resolution');
        return getPrayerTimes(
          latitude: latitude,
          longitude: longitude,
          city: city,
          country: country,
          bypassCache: true,
          state: state,
          district: district,
          date: targetDate,
        );
      }

      return prayerTimes;
    } catch (e, stacktrace) {
      print('Error fetching prayer times from Emushaf: $e');
      print(stacktrace);

      final fallback = await _getCachedPrayerTimes(
        city,
        targetDate,
        countryId: countryId,
        cityId: cityId,
        districtId: districtId,
        country: country,
        state: state,
        district: district,
      );
      if (fallback != null) {
        print('Using cached prayer times as fallback');
        return fallback;
      }
      return null;
    }
  }

  static Future<List<EmushafCountry>> fetchCountries() async {
    final countries = await _getCountries();
    return countries
        .map(
          (item) => EmushafCountry(
            id: item.id,
            name: item.name,
            englishName: item.englishName,
          ),
        )
        .toList();
  }

  static Future<List<EmushafLookupItem>> fetchCities(String countryId) async {
    final cities = await _getCities(countryId);
    return cities
        .map(
          (item) => EmushafLookupItem(
            id: item.id,
            name: item.name,
            englishName: item.englishName,
          ),
        )
        .toList();
  }

  static Future<List<EmushafLookupItem>> fetchDistricts(String cityId) async {
    final districts = await _getDistricts(cityId);
    return districts
        .map(
          (item) => EmushafLookupItem(
            id: item.id,
            name: item.name,
            englishName: item.englishName,
          ),
        )
        .toList();
  }

  static Future<List<PrayerTimes>> getPrayerTimesForMonth({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    String? state,
    String? district,
    required int month,
    required int year,
  }) async {
    try {
      await _migrateLegacyCacheIfNeeded();
      final countryMatch = await _resolveCountry(country);
      if (countryMatch == null) {
        return [];
      }

      final cityMatch = await _resolveCity(
        countryId: countryMatch.id,
        countryName: country,
        city: city,
        state: state,
      );
      if (cityMatch == null) {
        return [];
      }

      final districtMatch = await _resolveDistrict(
        cityId: cityMatch.id,
        city: city,
        state: state,
        district: district,
      );
      if (districtMatch == null) {
        return [];
      }

      return _fetchMonthPrayerTimes(
        districtId: districtMatch.id,
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        countryId: countryMatch.id,
        cityId: cityMatch.id,
        state: state,
        district: district,
        month: month,
        year: year,
      );
    } catch (e) {
      print('Error fetching monthly prayer times from Emushaf: $e');
      return [];
    }
  }

  static Future<PrayerTimes?> getCachedPrayerTimesForDate({
    required String city,
    required String country,
    String? countryId,
    String? cityId,
    String? districtId,
    String? state,
    String? district,
    DateTime? date,
  }) async {
    await _migrateLegacyCacheIfNeeded();
    final targetDate = date ?? DateTime.now();
    return _getCachedPrayerTimes(
      city,
      targetDate,
      countryId: countryId,
      cityId: cityId,
      districtId: districtId,
      country: country,
      state: state,
      district: district,
    );
  }

  static Future<List<_Country>> _getCountries() async {
    if (_countryCache != null) {
      return _countryCache!;
    }

    final response = await _getJson('/ulkeler');
    final list = (jsonDecode(response) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(_Country.fromJson)
        .toList();
    _countryCache = list;
    return list;
  }

  static Future<List<_City>> _getCities(String countryId) async {
    final cached = _cityCache[countryId];
    if (cached != null) {
      return cached;
    }

    final response = await _getJson('/sehirler/$countryId');
    final list = (jsonDecode(response) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(_City.fromJson)
        .toList();
    _cityCache[countryId] = list;
    return list;
  }

  static Future<List<_District>> _getDistricts(String cityId) async {
    final cached = _districtCache[cityId];
    if (cached != null) {
      return cached;
    }

    final response = await _getJson('/ilceler/$cityId');
    final list = (jsonDecode(response) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(_District.fromJson)
        .toList();
    _districtCache[cityId] = list;
    return list;
  }

  static Future<PrayerTimes?> _fetchMonthAndExtractDay({
    required String districtId,
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    String? countryId,
    String? cityId,
    String? state,
    String? district,
    required DateTime targetDate,
  }) async {
    final monthItems = await _fetchMonthPrayerTimes(
      districtId: districtId,
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      countryId: countryId,
      cityId: cityId,
      state: state,
      district: district,
      month: targetDate.month,
      year: targetDate.year,
    );

    for (final item in monthItems) {
      if (_isSameDay(item.date, targetDate)) {
        return item;
      }
    }

    if (monthItems.isNotEmpty) {
      monthItems.sort(
        (a, b) => a.date.difference(targetDate).abs().compareTo(
              b.date.difference(targetDate).abs(),
            ),
      );
      final fallback = monthItems.first;
      print(
        'No exact prayer time entry found for $targetDate; '
        'using nearest available date ${fallback.date}',
      );
      return fallback;
    }

    return null;
  }

  static Future<List<PrayerTimes>> _fetchMonthPrayerTimes({
    required String districtId,
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    String? countryId,
    String? cityId,
    String? state,
    String? district,
    required int month,
    required int year,
  }) async {
    final response = await _getJson('/vakitler/$districtId');
    final decoded = jsonDecode(response) as List<dynamic>;
    final result = <PrayerTimes>[];

    for (final item in decoded.whereType<Map<String, dynamic>>()) {
      final parsed = _parsePrayerTimesItem(
        item,
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
      );
      if (parsed == null) {
        continue;
      }
      if (parsed.date.year == year && parsed.date.month == month) {
        result.add(parsed);
        await _cachePrayerTimes(
          parsed,
          city: city,
          country: country,
          countryId: countryId,
          cityId: cityId,
          districtId: districtId,
          state: state,
          district: district,
        );
      }
    }

    return result;
  }

  static PrayerTimes? _parsePrayerTimesItem(
    Map<String, dynamic> item, {
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  }) {
    final date = _parseApiDate(item);
    if (date == null) {
      return null;
    }

    final times = <String, DateTime>{};
    final mapping = <String, String>{
      'imsak': 'Imsak',
      'fajr': 'Imsak',
      'sunrise': 'Gunes',
      'gunes': 'Gunes',
      'dhuhr': 'Ogle',
      'ogle': 'Ogle',
      'asr': 'Ikindi',
      'ikindi': 'Ikindi',
      'maghrib': 'Aksam',
      'aksam': 'Aksam',
      'isha': 'Yatsi',
      'yatsi': 'Yatsi',
    };

    mapping.forEach((targetKey, sourceKey) {
      final value = item[sourceKey];
      if (value is String && value.isNotEmpty) {
        final parsed = _parseClock(date, value);
        if (parsed != null) {
          times[targetKey] = parsed;
        }
      }
    });

    print(
      '🕰️ Parsed Emushaf row => '
      'date=${date.toIso8601String().split('T').first}, '
      'imsak=${times['imsak']?.toIso8601String()}, '
      'gunes=${times['sunrise']?.toIso8601String()}, '
      'ogle=${times['dhuhr']?.toIso8601String()}, '
      'ikindi=${times['asr']?.toIso8601String()}, '
      'aksam=${times['maghrib']?.toIso8601String()}, '
      'yatsi=${times['isha']?.toIso8601String()}',
    );

    if (times.isEmpty) {
      return null;
    }

    return PrayerTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      times: times,
    );
  }

  static DateTime? _parseApiDate(Map<String, dynamic> item) {
    final shortDate = item['MiladiTarihKisaIso8601']?.toString() ??
        item['MiladiTarihKisa']?.toString();
    final parsedShortDate = _parseApiShortDate(shortDate);

    final longIso = item['MiladiTarihUzunIso8601']?.toString();
    final parsedLongIso = _parseApiIsoDate(longIso);

    if (parsedShortDate != null && parsedLongIso != null && !_isSameDay(parsedShortDate, parsedLongIso)) {
      print(
        '⚠️ Emushaf date mismatch detected: '
        'MiladiTarihKisa=${item['MiladiTarihKisa']} / '
        'MiladiTarihKisaIso8601=${item['MiladiTarihKisaIso8601']} / '
        'MiladiTarihUzunIso8601=$longIso. '
        'Using short date ${parsedShortDate.toIso8601String().split('T').first}.',
      );
    }

    return parsedShortDate ?? parsedLongIso;
  }

  static DateTime? _parseApiIsoDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime? _parseApiShortDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final isoShort = DateTime.tryParse(value);
    if (isoShort != null) {
      return DateTime(isoShort.year, isoShort.month, isoShort.day);
    }

    final parts = value.split('.');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static DateTime? _parseClock(DateTime date, String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static Future<_Country?> _resolveCountry(String country) async {
    final countries = await _getCountries();
    final target = _normalizedCountry(country);

    _Country? exact;
    for (final item in countries) {
      final names = [
        item.name,
        item.englishName,
      ];
      if (names.any((name) => _normalize(name) == target)) {
        exact = item;
        break;
      }
    }
    if (exact != null) {
      return exact;
    }

    for (final item in countries) {
      final names = [
        item.name,
        item.englishName,
      ];
      if (names.any((name) =>
          _normalize(name).contains(target) || target.contains(_normalize(name)))) {
        return item;
      }
    }

    return null;
  }

  static Future<_City?> _resolveCity({
    required String countryId,
    required String countryName,
    required String city,
    String? state,
  }) async {
    final cities = await _getCities(countryId);
    if (cities.isEmpty) {
      return null;
    }
    if (cities.length == 1) {
      return cities.first;
    }
    final candidates = _cityCandidates(countryName, city, state);

    for (final candidate in candidates) {
      final match = _bestCityMatch(cities, candidate);
      if (match != null) {
        return match;
      }
    }

    final fallback = _bestCityMatch(cities, city);
    if (fallback != null) {
      print('City match fallback selected for city="$city": ${fallback.name}');
      return fallback;
    }

    print('City match not found for city="$city", state="$state", country="$countryName"');
    return cities.first;
  }

  static Future<_District?> _resolveDistrict({
    required String cityId,
    required String city,
    String? state,
    String? district,
  }) async {
    final districts = await _getDistricts(cityId);
    if (districts.isEmpty) {
      return null;
    }
    if (districts.length == 1) {
      return districts.first;
    }

    final candidates = _districtCandidates(city, state, district);
    for (final candidate in candidates) {
      final match = _bestDistrictMatch(districts, candidate);
      if (match != null) {
        return match;
      }
    }

    final hasExplicitDistrict = district != null && district.trim().isNotEmpty;
    if (hasExplicitDistrict) {
      print('District match not found for "$district" in city="$city"');
      return null;
    }

    final fallback = _bestDistrictMatch(districts, city);
    if (fallback != null) {
      print('District match fallback selected for city="$city": ${fallback.name}');
      return fallback;
    }

    print('District match not found for city="$city", state="$state"');
    return districts.first;
  }

  static _City? _bestCityMatch(List<_City> cities, String candidate) {
    final target = _normalize(candidate);
    for (final city in cities) {
      if (_normalize(city.name) == target || _normalize(city.englishName) == target) {
        return city;
      }
    }
    for (final city in cities) {
      final variants = [_normalize(city.name), _normalize(city.englishName)];
      if (variants.any((value) => value.contains(target) || target.contains(value))) {
        return city;
      }
    }

    _City? bestMatch;
    var bestScore = 0.0;
    for (final city in cities) {
      final variants = [_normalize(city.name), _normalize(city.englishName)];
      for (final variant in variants) {
        final score = _tokenSimilarity(variant, target);
        if (score > bestScore) {
          bestScore = score;
          bestMatch = city;
        }
      }
    }

    if (bestScore >= 0.35) {
      return bestMatch;
    }

    return null;
  }

  static _District? _bestDistrictMatch(
    List<_District> districts,
    String candidate,
  ) {
    final target = _normalize(candidate);
    for (final district in districts) {
      if (_normalize(district.name) == target ||
          _normalize(district.englishName) == target) {
        return district;
      }
    }
    for (final district in districts) {
      final variants = [_normalize(district.name), _normalize(district.englishName)];
      if (variants.any((value) => value.contains(target) || target.contains(value))) {
        return district;
      }
    }

    _District? bestMatch;
    var bestScore = 0.0;
    for (final district in districts) {
      final variants = [_normalize(district.name), _normalize(district.englishName)];
      for (final variant in variants) {
        final score = _tokenSimilarity(variant, target);
        if (score > bestScore) {
          bestScore = score;
          bestMatch = district;
        }
      }
    }

    if (bestScore >= 0.35) {
      return bestMatch;
    }

    return null;
  }

  static List<String> _cityCandidates(
    String countryName,
    String city,
    String? state,
  ) {
    final normalizedCountry = _normalizedCountry(countryName);
    final values = <String>[];
    if (normalizedCountry == 'turkey') {
      if (state != null && state.trim().isNotEmpty) {
        values.add(state);
      }
      values.add(city);
    } else {
      values.add(city);
      if (state != null && state.trim().isNotEmpty) {
        values.add(state);
      }
      values.add(countryName);
    }
    return values.where((value) => value.trim().isNotEmpty).toList();
  }

  static List<String> _districtCandidates(
    String city,
    String? state,
    String? district,
  ) {
    final values = <String>[
      city,
      if (district != null && district.trim().isNotEmpty) district,
      if (state != null && state.trim().isNotEmpty) state,
    ];
    return values.where((value) => value.trim().isNotEmpty).toList();
  }

  static String _normalizedCountry(String value) {
    final normalized = _normalize(value);
    const aliases = <String, String>{
      'turkiye': 'turkey',
      'turkiye cumhuriyeti': 'turkey',
      'turkey': 'turkey',
      'almanya': 'germany',
      'germany': 'germany',
      'deutschland': 'germany',
      'amerika birlesik devletleri': 'usa',
      'united states': 'usa',
      'united states of america': 'usa',
      'usa': 'usa',
      'abd': 'usa',
      'birlesik krallik': 'united kingdom',
      'ingiltere': 'united kingdom',
      'united kingdom': 'united kingdom',
      'great britain': 'united kingdom',
      'suudi arabistan': 'saudi arabia',
      'saudi arabia': 'saudi arabia',
      'birlesik arap emirlikleri': 'united arab emirates',
      'united arab emirates': 'united arab emirates',
      'uae': 'united arab emirates',
      'hollanda': 'netherlands',
      'netherlands': 'netherlands',
      'fransa': 'france',
      'france': 'france',
      'kanada': 'canada',
      'canada': 'canada',
      'avustralya': 'australia',
      'australia': 'australia',
    };
    return aliases[normalized] ?? normalized;
  }

  static String _normalize(String value) {
    final lower = value.trim().toLowerCase();
    const replacements = <String, String>{
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'i̇': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'â': 'a',
      'î': 'i',
      'û': 'u',
      'ä': 'a',
      'á': 'a',
      'à': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ñ': 'n',
      '-': ' ',
      '\'': ' ',
      '.': ' ',
      ',': ' ',
      '(': ' ',
      ')': ' ',
      '/': ' ',
    };

    var normalized = lower;
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  static double _tokenSimilarity(String left, String right) {
    final leftTokens = left
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();
    final rightTokens = right
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();

    if (leftTokens.isEmpty || rightTokens.isEmpty) {
      return 0;
    }

    final intersection = leftTokens.intersection(rightTokens).length;
    final union = leftTokens.union(rightTokens).length;
    if (union == 0) {
      return 0;
    }

    return intersection / union;
  }

  static String _cachePart(String? value) {
    final normalized = _normalize(value ?? '');
    if (normalized.isEmpty) {
      return 'na';
    }
    return normalized.replaceAll(' ', '-');
  }

  static String _buildCacheKey({
    required String city,
    required DateTime date,
    String? countryId,
    String? cityId,
    String? districtId,
    String? country,
    String? state,
    String? district,
  }) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final cityKey = _cachePart(city);
    final countryIdKey = _cachePart(countryId);
    final cityIdKey = _cachePart(cityId);
    final districtIdKey = _cachePart(districtId);
    final countryKey = _cachePart(country);
    final stateKey = _cachePart(state);
    final districtKey = _cachePart(district);
    return '$_cacheKeyPrefix${cityKey}_${dateKey}_${countryIdKey}_${cityIdKey}_${districtIdKey}_${countryKey}_${stateKey}_$districtKey';
  }

  static Future<String> _getJson(String path) async {
    Object? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('$_baseUrl$path'),
              headers: const {
                'accept': 'application/json',
                'user-agent': 'namaz-vakitleri-app/1.0',
              },
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) {
          throw HttpException(
            'Emushaf API error ${response.statusCode} for $path',
          );
        }

        return response.body;
      } on SocketException catch (e) {
        lastError = Exception(
          'ezanvakti.emushaf.net host bulunamadi. Internet/DNS baglantisini kontrol edin. Detay: $e',
        );
      } catch (e) {
        lastError = e;
      }

      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    throw lastError ?? Exception('Emushaf API istegi basarisiz oldu: $path');
  }


  static Future<void> _cachePrayerTimes(
    PrayerTimes prayerTimes, {
    required String city,
    required String country,
    String? countryId,
    String? cityId,
    String? districtId,
    String? state,
    String? district,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _buildCacheKey(
        city: city,
        date: prayerTimes.date,
        countryId: countryId,
        cityId: cityId,
        districtId: districtId,
        country: country,
        state: state,
        district: district,
      );

      final cacheData = {
        'source': _cacheSource,
        'date': prayerTimes.date.toIso8601String(),
        'latitude': prayerTimes.latitude,
        'longitude': prayerTimes.longitude,
        'city': city,
        'country': country,
        'countryId': countryId,
        'cityId': cityId,
        'districtId': districtId,
        'state': state,
        'district': district,
        'times': prayerTimes.times.map(
          (key, value) => MapEntry(key, value.toIso8601String()),
        ),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching prayer times: $e');
    }
  }

  static Future<PrayerTimes?> _getCachedPrayerTimes(
    String city,
    DateTime date,
    {
    String? countryId,
    String? cityId,
    String? districtId,
    String? country,
    String? state,
    String? district,
  }
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _buildCacheKey(
        city: city,
        date: date,
        countryId: countryId,
        cityId: cityId,
        districtId: districtId,
        country: country,
        state: state,
        district: district,
      );

      final cached = prefs.getString(cacheKey);
      if (cached == null) {
        return null;
      }

      final json = jsonDecode(cached) as Map<String, dynamic>;
      if (json['source'] != _cacheSource) {
        return null;
      }
      final Map<String, DateTime> times = {};
      final timesJson = json['times'] as Map<String, dynamic>? ?? {};
      timesJson.forEach((key, value) {
        if (value is String) {
          times[key] = DateTime.parse(value);
        }
      });

      return PrayerTimes(
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        city: json['city'] ?? 'Unknown',
        country: json['country'] ?? 'Unknown',
        times: times,
      );
    } catch (e) {
      print('Error retrieving cached prayer times: $e');
      return null;
    }
  }

  static Future<PrayerTimes?> getLatestCachedPrayerTimes(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityPrefix = '$_cacheKeyPrefix${_cachePart(city)}_';
      final matchingKeys = prefs
          .getKeys()
          .where((key) => key.startsWith(cityPrefix))
          .toList()
        ..sort();

      for (final key in matchingKeys.reversed) {
        final cached = prefs.getString(key);
        if (cached == null) {
          continue;
        }

        final prayerTimes = _prayerTimesFromCache(cached);
        if (prayerTimes != null) {
          return prayerTimes;
        }
      }
    } catch (e) {
      print('Error retrieving latest cached prayer times: $e');
    }

    return null;
  }

  static PrayerTimes? _prayerTimesFromCache(String cached) {
    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      if (json['source'] != _cacheSource) {
        return null;
      }

      final Map<String, DateTime> times = {};
      final timesJson = json['times'] as Map<String, dynamic>? ?? {};
      timesJson.forEach((key, value) {
        if (value is String) {
          times[key] = DateTime.parse(value);
        }
      });

      return PrayerTimes(
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        city: json['city'] ?? 'Unknown',
        country: json['country'] ?? 'Unknown',
        times: times,
      );
    } catch (e) {
      print('Error parsing cached prayer times: $e');
      return null;
    }
  }

  static Future<void> _migrateLegacyCacheIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_cacheMigrationKey) ?? false) {
      return;
    }

    final legacyKeys = prefs
        .getKeys()
        .where((key) =>
            key.startsWith(_legacyCacheKeyPrefix) ||
            key.startsWith(_previousCacheKeyPrefix))
        .toList();

    for (final key in legacyKeys) {
      await prefs.remove(key);
    }

    await prefs.setBool(_cacheMigrationKey, true);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _Country {
  _Country({
    required this.id,
    required this.name,
    required this.englishName,
  });

  final String id;
  final String name;
  final String englishName;

  factory _Country.fromJson(Map<String, dynamic> json) {
    return _Country(
      id: json['UlkeID']?.toString() ?? '',
      name: json['UlkeAdi']?.toString() ?? '',
      englishName: json['UlkeAdiEn']?.toString() ?? '',
    );
  }
}

class _City {
  _City({
    required this.id,
    required this.name,
    required this.englishName,
  });

  final String id;
  final String name;
  final String englishName;

  factory _City.fromJson(Map<String, dynamic> json) {
    return _City(
      id: json['SehirID']?.toString() ?? '',
      name: json['SehirAdi']?.toString() ?? '',
      englishName: json['SehirAdiEn']?.toString() ?? '',
    );
  }
}

class _District {
  _District({
    required this.id,
    required this.name,
    required this.englishName,
  });

  final String id;
  final String name;
  final String englishName;

  factory _District.fromJson(Map<String, dynamic> json) {
    return _District(
      id: json['IlceID']?.toString() ?? '',
      name: json['IlceAdi']?.toString() ?? '',
      englishName: json['IlceAdiEn']?.toString() ?? '',
    );
  }
}

class EmushafCountry {
  EmushafCountry({
    required this.id,
    required this.name,
    required this.englishName,
  });

  final String id;
  final String name;
  final String englishName;

  bool get isTurkey {
    final normalizedEnglish = englishName.trim().toLowerCase();
    final normalizedName = name.trim().toLowerCase();
    return normalizedEnglish == 'turkey' || normalizedName.contains('turki');
  }

  String get searchName => englishName.isNotEmpty ? englishName : name;
}

class EmushafLookupItem {
  EmushafLookupItem({
    required this.id,
    required this.name,
    required this.englishName,
  });

  final String id;
  final String name;
  final String englishName;

  String get searchName => englishName.isNotEmpty ? englishName : name;
}
