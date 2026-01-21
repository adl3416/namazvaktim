/// Utility functions for the Prayer Times app

class TimeFormatter {
  /// Format Duration to readable string (e.g., "1 sa 41 dk")
  static String formatDuration(Duration duration, String locale) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours h ${minutes.toString().padLeft(2, '0')} m';
    }

    if (minutes > 0) {
      return '$minutes m ${seconds.toString().padLeft(2, '0')} s';
    }

    return '${seconds.toString().padLeft(2, '0')} s';
  }

  /// Format time to 12-hour format
  static String formatTo12Hour(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Format time to 24-hour format
  static String formatTo24Hour(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class DateFormatter {
  /// Get Islamic month name
  static String getIslamicMonth(int month) {
    const months = [
      'Muharram',
      'Safar',
      'Rabi\' al-awwal',
      'Rabi\' al-thani',
      'Jumada al-awwal',
      'Jumada al-thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah',
    ];
    return months[month - 1] ?? 'Unknown';
  }

  /// Get Gregorian month name
  static String getGregorianMonth(int month, String locale) {
    final monthMap = {
      'en': [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ],
      'tr': [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ],
      'ar': [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ],
    };

    return monthMap[locale]?[month - 1] ?? 'Unknown';
  }

  /// Format date for display
  static String formatDate(DateTime date, String locale) {
    final day = date.day;
    final month = getGregorianMonth(date.month, locale);
    final year = date.year;
    return '$day $month $year';
  }
}

class ValidationHelper {
  /// Validate location data
  static bool isValidLocation(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && 
           longitude >= -180 && longitude <= 180;
  }

  /// Validate prayer time
  static bool isValidPrayerTime(DateTime time) {
    return time.isAfter(DateTime.now().subtract(Duration(days: 1))) &&
           time.isBefore(DateTime.now().add(Duration(days: 7)));
  }

  /// Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,9}$');
    return phoneRegex.hasMatch(phone);
  }
}

class DistanceCalculator {
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = (1 - _cos(dLat)) / 2 +
        _cos(_toRad(lat1)) *
            _cos(_toRad(lat2)) *
            (1 - _cos(dLon)) /
            2;

    final c = 2 * _asin(_sqrt(a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRad(double degree) {
    const pi = 3.14159265359;
    return degree * pi / 180;
  }

  /// Simple cos calculation
  static double _cos(double angle) {
    final x = angle;
    return 1 - (x * x) / 2 + (x * x * x * x) / 24 - (x * x * x * x * x * x) / 720;
  }

  /// Simple sqrt calculation
  static double _sqrt(double value) {
    if (value < 0) return 0;
    if (value == 0) return 0;

    double x = value;
    double y = (x + 1) / 2;

    while (y < x) {
      x = y;
      y = (x + value / x) / 2;
    }

    return x;
  }

  /// Simple asin calculation
  static double _asin(double value) {
    if (value > 1) value = 1;
    if (value < -1) value = -1;

    const pi = 3.14159265359;
    return value * pi / 2;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

class PrayerTimeHelper {
  /// Get prayer name in English
  static String getPrayerNameEn(String prayer) {
    const nameMap = {
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
    };
    return nameMap[prayer.toLowerCase()] ?? prayer;
  }

  /// Get prayer icon
  static String getPrayerIcon(String prayer) {
    const iconMap = {
      'fajr': '🌙',
      'dhuhr': '☀️',
      'asr': '🌤️',
      'maghrib': '🌅',
      'isha': '⭐',
    };
    return iconMap[prayer.toLowerCase()] ?? '📿';
  }

  /// Get prayer color code (hex)
  static String getPrayerColorHex(String prayer) {
    const colorMap = {
      'fajr': '#FBF5F0',
      'dhuhr': '#FBF8F2',
      'asr': '#FAF5F0',
      'maghrib': '#FBF7F2',
      'isha': '#F6F2F9',
    };
    return colorMap[prayer.toLowerCase()] ?? '#FEFBF8';
  }

  /// Check if prayer time is within next hour
  static bool isWithinNextHour(DateTime prayerTime) {
    final now = DateTime.now();
    final oneHourLater = now.add(Duration(hours: 1));
    return prayerTime.isAfter(now) && prayerTime.isBefore(oneHourLater);
  }

  /// Check if prayer time has passed
  static bool hasPrayerPassed(DateTime prayerTime) {
    return DateTime.now().isAfter(prayerTime);
  }
}

class LocaleHelper {
  /// Get locale code from language name
  static String getLocaleCode(String language) {
    const localeMap = {
      'English': 'en',
      'Türkçe': 'tr',
      'العربية': 'ar',
    };
    return localeMap[language] ?? 'en';
  }

  /// Get language name from locale code
  static String getLanguageName(String locale) {
    const languageMap = {
      'en': 'English',
      'tr': 'Türkçe',
      'ar': 'العربية',
    };
    return languageMap[locale] ?? 'English';
  }

  /// Check if language is RTL
  static bool isRTL(String locale) {
    return locale == 'ar';
  }
}

class CacheManager {
  /// Generate cache key for prayer times
  static String generatePrayerTimeCacheKey(String city, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'prayer_times_${city}_$dateStr';
  }

  /// Generate cache key for location
  static String generateLocationCacheKey(double latitude, double longitude) {
    return 'location_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
  }

  /// Calculate cache expiry time (24 hours)
  static bool isCacheExpired(DateTime cacheTime) {
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    return difference.inHours > 24;
  }
}
