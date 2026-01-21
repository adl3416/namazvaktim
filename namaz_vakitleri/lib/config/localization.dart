import 'package:intl/intl.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> translations = {
    'tr': {
      'app_title': 'Namaz Vakitleri',
      'fajr': 'Sabah',
      'dhuhr': 'Öğle',
      'asr': 'İkindi',
      'maghrib': 'Akşam',
      'isha': 'Yatsı',
      'settings': 'Ayarlar',
      'location': 'Konum',
      'qibla': 'Kibe',
      'search_city': 'Şehir Ara',
      'nearby_mosques': 'Yakındaki Camiler',
      'prayer_time_label': 'Vaktine',
      'iftar_time': 'İftar vaktine',
      'theme': 'Tema',
      'language': 'Dil',
      'notifications': 'Bildirimler',
      'enable_adhan': 'Ezan Sesini Aç',
      'prayer_notifications': 'Namaz Saati Bildirimleri',
      'system': 'Sistem',
      'light': 'Açık',
      'dark': 'Koyu',
      'hour': 'sa',
      'minute': 'dk',
      'second': 'sn',
      'cancel': 'İptal',
      'search': 'Ara',
      'loading': 'Yükleniyor...',
    },
    'en': {
      'app_title': 'Prayer Times',
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'settings': 'Settings',
      'location': 'Location',
      'qibla': 'Qibla',
      'search_city': 'Search City',
      'nearby_mosques': 'Nearby Mosques',
      'prayer_time_label': 'Prayer Time',
      'iftar_time': 'Time to Iftar',
      'theme': 'Theme',
      'language': 'Language',
      'notifications': 'Notifications',
      'enable_adhan': 'Enable Adhan Sound',
      'prayer_notifications': 'Prayer Notifications',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'hour': 'hr',
      'minute': 'min',
      'second': 'sec',
      'cancel': 'Cancel',
      'search': 'Search',
      'loading': 'Loading...',
    },
    'ar': {
      'app_title': 'مواقيت الصلاة',
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'settings': 'الإعدادات',
      'location': 'الموقع',
      'qibla': 'القبلة',
      'search_city': 'البحث عن المدينة',
      'nearby_mosques': 'المساجد القريبة',
      'prayer_time_label': 'وقت الصلاة',
      'iftar_time': 'وقت الإفطار',
      'theme': 'المظهر',
      'language': 'اللغة',
      'notifications': 'الإخطارات',
      'enable_adhan': 'تفعيل صوت الأذان',
      'prayer_notifications': 'إخطارات وقت الصلاة',
      'system': 'النظام',
      'light': 'فاتح',
      'dark': 'داكن',
      'hour': 'ساعة',
      'minute': 'دقيقة',
      'second': 'ثانية',
      'cancel': 'إلغاء',
      'search': 'بحث',
      'loading': 'جاري التحميل...',
    },
  };

  static String translate(String key, String locale) {
    return translations[locale]?[key] ?? translations['en']?[key] ?? key;
  }

  static String getLocale(String? preferredLanguage) {
    if (preferredLanguage != null && translations.containsKey(preferredLanguage)) {
      return preferredLanguage;
    }

    final String systemLocale = Intl.systemLocale.split('_')[0].toLowerCase();
    if (translations.containsKey(systemLocale)) {
      return systemLocale;
    }

    return 'en';
  }

  static bool isRTL(String locale) => locale == 'ar';
}
