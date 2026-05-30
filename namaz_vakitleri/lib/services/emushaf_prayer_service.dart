import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_model.dart';

class EmushafPrayerService {
  static const String _baseUrl = 'https://ezanvakti.emushaf.net';
  static const String _cacheKeyPrefix = 'emushaf_prayer_times_v1_';
  static const String _legacyCacheKeyPrefix = 'prayer_times_';
  static const String _cacheSource = 'emushaf';
  static const String _cacheMigrationKey = 'emushaf_cache_migrated_v1';

  static List<_Country>? _countryCache;
  static final Map<String, List<_City>> _cityCache = {};
  static final Map<String, List<_District>> _districtCache = {};

  static Future<PrayerTimes?> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    String? state,
    String? district,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    await _migrateLegacyCacheIfNeeded();
    final cached = await _getCachedPrayerTimes(city, targetDate);
    if (cached != null) {
      print('Using cached prayer times for $city');
      return cached;
    }

    try {
      final countryMatch = await _resolveCountry(country);
      if (countryMatch == null) {
        print('No country match found for $country');
        return null;
      }

      final cityMatch = await _resolveCity(
        countryId: countryMatch.id,
        countryName: country,
        city: city,
        state: state,
      );
      if (cityMatch == null) {
        print('No city/state match found for city=$city state=$state country=$country');
        return null;
      }

      final districtMatch = await _resolveDistrict(
        cityId: cityMatch.id,
        city: city,
        state: state,
        district: district,
      );
      if (districtMatch == null) {
        print('No district match found for district=$district city=$city state=$state');
        return null;
      }

      final prayerTimes = await _fetchMonthAndExtractDay(
        districtId: districtMatch.id,
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        targetDate: targetDate,
      );

      return prayerTimes;
    } catch (e, stacktrace) {
      print('Error fetching prayer times from Emushaf: $e');
      print(stacktrace);

      final fallback = await _getCachedPrayerTimes(city, targetDate);
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
        month: month,
        year: year,
      );
    } catch (e) {
      print('Error fetching monthly prayer times from Emushaf: $e');
      return [];
    }
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
    required DateTime targetDate,
  }) async {
    final monthItems = await _fetchMonthPrayerTimes(
      districtId: districtId,
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
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
        await _cachePrayerTimes(parsed);
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
      'sunrise': 'GunesDogus',
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
    final iso = item['MiladiTarihUzunIso8601']?.toString();
    if (iso != null && iso.isNotEmpty) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    final shortDate = item['MiladiTarihKisaIso8601']?.toString() ??
        item['MiladiTarihKisa']?.toString();
    if (shortDate == null || shortDate.isEmpty) {
      return null;
    }

    final isoShort = DateTime.tryParse(shortDate);
    if (isoShort != null) {
      return DateTime(isoShort.year, isoShort.month, isoShort.day);
    }

    final parts = shortDate.split('.');
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

    return null;
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
      if (state != null && state.trim().isNotEmpty) {
        values.add(state);
      }
      values.add(city);
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
      if (district != null && district.trim().isNotEmpty) district,
      city,
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

  static Future<String> _getJson(String path) async {
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
      throw Exception('Emushaf API error ${response.statusCode} for $path');
    }

    return response.body;
  }

  static Future<void> _cachePrayerTimes(PrayerTimes prayerTimes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey =
          '${prayerTimes.date.year}-${prayerTimes.date.month.toString().padLeft(2, '0')}-${prayerTimes.date.day.toString().padLeft(2, '0')}';
      final cacheKey = '$_cacheKeyPrefix${prayerTimes.city}_$dateKey';

      final cacheData = {
        'source': _cacheSource,
        'date': prayerTimes.date.toIso8601String(),
        'latitude': prayerTimes.latitude,
        'longitude': prayerTimes.longitude,
        'city': prayerTimes.city,
        'country': prayerTimes.country,
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
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final cacheKey = '$_cacheKeyPrefix${city}_$dateKey';

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

  static Future<void> _migrateLegacyCacheIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_cacheMigrationKey) ?? false) {
      return;
    }

    final legacyKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(_legacyCacheKeyPrefix))
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
