// Simple test file to verify prayer times parsing works correctly
void main() {
  // Simulate API response
  final apiResponse = {
    'data': {
      'timings': {
        'Fajr': '05:30',
        'Sunrise': '08:17',
        'Dhuhr': '12:48',
        'Asr': '15:30',
        'Sunset': '17:39',
        'Maghrib': '17:39',
        'Isha': '20:30',
        'Imsak': '05:20',
        'Midnight': '23:03',
        'Firstthird': '20:22',
        'Lastthird': '01:44'
      },
      'date': {'readable': '21 Jan 2026', 'timestamp': 1737417600},
      'meta': {
        'latitude': 41.0082,
        'longitude': 28.9784,
        'timezone': 'Europe/Istanbul',
        'method': {
          'id': 13,
          'name': 'Diyanet',
          'params': {'Fajr': 18, 'Isha': 17}
        },
        'offset': {'Imsak': 0, 'Fajr': 0, 'Sunrise': 0, 'Dhuhr': 0, 'Asr': 0, 'Sunset': 0, 'Maghrib': 0, 'Isha': 0}
      }
    },
    'code': 200,
    'status': 'OK'
  };

  // Parse timings
  final prayerData = apiResponse['data'] as Map<String, dynamic>? ?? {};
  final timings = prayerData['timings'] as Map<String, dynamic>? ?? {};

  print('Raw timings keys: ${timings.keys.toList()}');
  
  // Map expected prayer times
  final Map<String, DateTime> parsedTimes = {};
  final today = DateTime.now();
  
  timings.forEach((key, value) {
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
        }
      } catch (e) {
        print('❌ Error parsing $key:$value - $e');
      }
    }
  });

  print('\nParsed times map keys: ${parsedTimes.keys.toList()}');
  print('Parsed times count: ${parsedTimes.length}');
  
  // Check for required prayer times
  const requiredPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  print('\nChecking required prayers:');
  for (final prayer in requiredPrayers) {
    if (parsedTimes.containsKey(prayer)) {
      final time = parsedTimes[prayer]!;
      print('✅ $prayer: ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    } else {
      print('❌ $prayer: MISSING!');
    }
  }
}
