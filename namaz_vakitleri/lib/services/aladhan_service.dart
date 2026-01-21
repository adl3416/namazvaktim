import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';

class AlAdhanService {
  static const String baseUrl = 'https://api.aladhan.com/v1';
  static const String cacheKeyPrefix = 'prayer_times_';

  /// Fetch prayer times for a specific location
  /// method = 13 (Diyanet - Turkey/Hanafi)
  static Future<PrayerTimes?> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateStr = '${targetDate.day}-${targetDate.month}-${targetDate.year}';
      
      final url =
          '$baseUrl/timings/$dateStr?latitude=$latitude&longitude=$longitude&method=13';

      print('📡 Fetching prayer times from: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      print('📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ API Response code: ${jsonResponse['code']}');
        print('✅ API Response status: ${jsonResponse['status']}');
        
        final prayerData = jsonResponse['data'] as Map<String, dynamic>? ?? {};
        print('✅ Prayer data keys: ${prayerData.keys.toList()}');
        
        final timings = prayerData['timings'] as Map<String, dynamic>? ?? {};
        if (timings.isEmpty) {
          print('⚠️ WARNING: No timings found in API response!');
          print('🔍 Full response: ${jsonResponse.toString().substring(0, 500)}');
        }
        print('✅ Timings keys: ${timings.keys.toList()}');

        final prayerTimes = PrayerTimes.fromJson({
          ...prayerData,
          'city': city,
          'country': country,
          'latitude': latitude,
          'longitude': longitude,
        });

        print('✅ Parsed Prayer Times: ${prayerTimes.prayerTimesList.length} prayers');
        prayerTimes.prayerTimesList.forEach((p) {
          print('  - ${p.name}: ${p.time.hour.toString().padLeft(2, '0')}:${p.time.minute.toString().padLeft(2, '0')}');
        });

        // Cache the result
        await _cachePrayerTimes(prayerTimes);

        return prayerTimes;
      } else {
        print('❌ AlAdhan API Error: Status ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }

      // Try to return cached data on failure
      final cached = await _getCachedPrayerTimes(city, targetDate);
      if (cached != null) {
        print('ℹ️ Using cached prayer times');
        return cached;
      }
      
      return null;
    } catch (e, stacktrace) {
      print('❌ Error fetching prayer times: $e');
      print(stacktrace);
      
      // Try to return cached data as fallback
      final now = DateTime.now();
      final cached = await _getCachedPrayerTimes(city, now);
      if (cached != null) {
        print('ℹ️ Using cached prayer times as fallback');
        return cached;
      }
      
      return null;
    }
  }

  /// Fetch prayer times for multiple days (for caching)
  static Future<List<PrayerTimes>> getPrayerTimesForMonth({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    required int month,
    required int year,
  }) async {
    final List<PrayerTimes> allTimes = [];

    try {
      final url =
          '$baseUrl/timingsByCity?city=$city&country=$country&method=13&month=$month&year=$year';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final timings = json['data'] as List<dynamic>? ?? [];

        for (var timing in timings) {
          try {
            final prayerData = timing as Map<String, dynamic>;
            final prayerTimes = PrayerTimes.fromJson({
              ...prayerData,
              'city': city,
              'country': country,
              'latitude': latitude,
              'longitude': longitude,
            });

            allTimes.add(prayerTimes);
            await _cachePrayerTimes(prayerTimes);
          } catch (e) {
            print('Error parsing prayer time: $e');
          }
        }
      }
    } catch (e) {
      print('Error fetching monthly prayer times: $e');
    }

    return allTimes;
  }

  /// Cache prayer times locally
  static Future<void> _cachePrayerTimes(PrayerTimes prayerTimes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey =
          '${prayerTimes.date.year}-${prayerTimes.date.month.toString().padLeft(2, '0')}-${prayerTimes.date.day.toString().padLeft(2, '0')}';
      final cacheKey = '$cacheKeyPrefix${prayerTimes.city}_$dateKey';

      final cacheData = {
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

  /// Get cached prayer times
  static Future<PrayerTimes?> _getCachedPrayerTimes(
    String city,
    DateTime date,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final cacheKey = '$cacheKeyPrefix${city}_$dateKey';

      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;

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
      }
    } catch (e) {
      print('Error retrieving cached prayer times: $e');
    }

    return null;
  }

  /// Get all cached prayer times for a city
  static Future<Map<String, PrayerTimes>> getAllCachedPrayerTimes(
    String city,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final Map<String, PrayerTimes> result = {};

      for (var key in allKeys) {
        if (key.startsWith('$cacheKeyPrefix${city}_')) {
          final cached = prefs.getString(key);
          if (cached != null) {
            try {
              final json = jsonDecode(cached) as Map<String, dynamic>;

              final Map<String, DateTime> times = {};
              final timesJson = json['times'] as Map<String, dynamic>? ?? {};
              timesJson.forEach((k, value) {
                if (value is String) {
                  times[k] = DateTime.parse(value);
                }
              });

              final prayerTimes = PrayerTimes(
                date:
                    DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
                latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
                longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
                city: json['city'] ?? 'Unknown',
                country: json['country'] ?? 'Unknown',
                times: times,
              );

              result[key] = prayerTimes;
            } catch (e) {
              print('Error parsing cached prayer time: $e');
            }
          }
        }
      }

      return result;
    } catch (e) {
      print('Error retrieving all cached prayer times: $e');
      return {};
    }
  }
}
