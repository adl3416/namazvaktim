class PrayerTime {
  final String name;
  final DateTime time;
  final DateTime? nextTime;

  PrayerTime({
    required this.name,
    required this.time,
    this.nextTime,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      name: json['name'] ?? '',
      time: DateTime.parse(json['time'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isActive {
    final now = DateTime.now();
    if (nextTime == null) return false;
    return now.isAfter(time) && now.isBefore(nextTime!);
  }

  Duration? get timeUntil {
    final now = DateTime.now();
    if (time.isBefore(now)) return null;
    return time.difference(now);
  }

  Duration? get timeUntilNext {
    final now = DateTime.now();
    if (nextTime == null) return null;
    if (nextTime!.isBefore(now)) return null;
    return nextTime!.difference(now);
  }
}

class PrayerTimes {
  final DateTime date;
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final Map<String, DateTime> times;

  PrayerTimes({
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.times,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    print('🔍 PrayerTimes.fromJson called');
    print('🔍 JSON keys: ${json.keys.toList()}');
    print('🔍 JSON: $json');
    
    final timings = json['timings'] as Map<String, dynamic>? ?? {};
    
    print('🔍 Raw timings from JSON: ${timings.keys.toList()}');
    print('🔍 Timings count: ${timings.length}');
    
    // Parse times and remove seconds
    final Map<String, DateTime> parsedTimes = {};
    final today = DateTime.now();
    
    timings.forEach((key, value) {
      print('🔍 Processing timing key: $key = $value (type: ${value.runtimeType})');
      
      if (value is String && value.isNotEmpty) {
        try {
          final parts = value.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            final dateTime = DateTime(
              today.year,
              today.month,
              today.day,
              hour,
              minute,
            );
            parsedTimes[key.toLowerCase()] = dateTime;
            print('✅ Parsed $key: $hour:$minute → ${key.toLowerCase()}');
          } else {
            print('❌ Invalid time format for $key: $value (parts: $parts)');
          }
        } catch (e) {
          print('❌ Error parsing $key:$value - $e');
        }
      } else {
        print('⚠️ Skipping $key: not a non-empty string (value: $value, type: ${value.runtimeType})');
      }
    });

    print('📊 Parsed times map keys: ${parsedTimes.keys.toList()}');
    print('📊 Parsed times count: ${parsedTimes.length}');
    
    if (parsedTimes.isEmpty) {
      print('⚠️ WARNING: No prayer times were parsed! Using default times for debugging.');
      // Add default times for debugging if parsing failed
      parsedTimes['fajr'] = DateTime(today.year, today.month, today.day, 5, 30);
      parsedTimes['dhuhr'] = DateTime(today.year, today.month, today.day, 12, 30);
      parsedTimes['asr'] = DateTime(today.year, today.month, today.day, 15, 30);
      parsedTimes['maghrib'] = DateTime(today.year, today.month, today.day, 18, 30);
      parsedTimes['isha'] = DateTime(today.year, today.month, today.day, 20, 30);
    }

    print('📊 Final parsed times: ${parsedTimes.toString().substring(0, 200)}...');

    return PrayerTimes(
      date: DateTime.now(),
      latitude: json['latitude'] as double? ?? 0.0,
      longitude: json['longitude'] as double? ?? 0.0,
      city: json['city'] as String? ?? 'Unknown',
      country: json['country'] as String? ?? 'Unknown',
      times: parsedTimes,
    );
  }

  List<PrayerTime> get prayerTimesList {
    // Include Sunrise between Fajr (İmsak) and Dhuhr
    const prayerOrder = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final result = <PrayerTime>[];
    
    for (int i = 0; i < prayerOrder.length; i++) {
      final name = prayerOrder[i];
      final lowerName = name.toLowerCase();
      DateTime? time;

      // Special handling: prefer 'imsak' if available for Fajr
      if (lowerName == 'fajr') {
        time = times['imsak'] ?? times['fajr'];
      } else {
        time = times[lowerName];
      }
      
      if (time == null) {
        print('⚠️ Missing time for prayer: $lowerName');
        continue;
      }
      
      // Find next prayer time
      DateTime? nextTime;
      
      if (i < prayerOrder.length - 1) {
        final nextName = prayerOrder[i + 1].toLowerCase();
        // For Sunrise, the key is 'sunrise' in parsed times
        if (nextName == 'sunrise') {
          nextTime = times['sunrise'];
        } else if (nextName == 'fajr') {
          nextTime = times['imsak'] ?? times['fajr'];
        } else {
          nextTime = times[nextName];
        }
      } else {
        // Last prayer, next is tomorrow's Fajr
        final tomorrow = DateTime.now().add(Duration(days: 1));
        final fajrTime = times['fajr'] ?? times['imsak'];
        if (fajrTime != null) {
          nextTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day,
              fajrTime.hour, fajrTime.minute);
        }
      }
      
      result.add(PrayerTime(
        name: name,
        time: time,
        nextTime: nextTime,
      ));
    }
    
    return result;
  }

  PrayerTime? get nextPrayer {
    final now = DateTime.now();
    try {
      final list = prayerTimesList;
      if (list.isEmpty) {
        print('❌ nextPrayer: prayerTimesList is empty!');
        return null;
      }
      
      // Find first prayer after now
      final future = list.where((p) => p.time.isAfter(now)).toList();
      if (future.isNotEmpty) {
        return future.first;
      }
      
      // No future prayers today; return tomorrow's first prayer
      print('ℹ️ No future prayers today, returning tomorrow\'s Fajr');
      final tomorrow = now.add(const Duration(days: 1));
      final fajrTime = list.first.time;
      final tomorrowFajr = DateTime(
        tomorrow.year, 
        tomorrow.month, 
        tomorrow.day,
        fajrTime.hour,
        fajrTime.minute,
      );
      
      return PrayerTime(
        name: list.first.name,
        time: tomorrowFajr,
        nextTime: list.length > 1 ? DateTime(
          tomorrow.year, 
          tomorrow.month, 
          tomorrow.day,
          list[1].time.hour,
          list[1].time.minute,
        ) : null,
      );
    } catch (e, stacktrace) {
      print('❌ Error getting nextPrayer: $e');
      print(stacktrace);
      return null;
    }
  }

  PrayerTime? get activePrayer {
    final now = DateTime.now();
    try {
      final list = prayerTimesList;
      if (list.isEmpty) return null;
      
      for (var prayer in list) {
        if (prayer.isActive) {
          return prayer;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting activePrayer: $e');
      return null;
    }
  }
}

class GeoLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;

  GeoLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
  });
}

class Mosque {
  final String name;
  final double latitude;
  final double longitude;
  final double distance; // in km
  final String? address;
  final String? phone;

  Mosque({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.address,
    this.phone,
  });
}
