import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  static const supportedLanguages = <String>['tr', 'en', 'ar', 'de'];

  static const Map<String, Map<String, String>> translations = {
    'tr': {
      'app_title': 'Ezanlar',
      'fajr': 'İmsak',
      'sunrise': 'Güneş',
      'dhuhr': 'Öğle',
      'asr': 'İkindi',
      'maghrib': 'Akşam',
      'isha': 'Yatsı',
      'settings': 'Ayarlar',
      'location': 'Konum',
      'qibla': 'Kıble',
      'search_city': 'Şehir Ara',
      'select_country': 'Ülke Seç',
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
      'hour': 'SA',
      'minute': 'DK',
      'second': 'SN',
      'cancel': 'İptal',
      'search': 'Ara',
      'loading': 'Yükleniyor...',
      'allow': 'İzin Ver',
      'open_settings': 'Ayarları Aç',
      'notification_imsak': 'İmsak namaz vakti',
      'notification_sunrise': 'Güneş vakti',
      'notification_noon': 'Öğle namaz vakti',
      'notification_afternoon': 'İkindi namaz vakti',
      'notification_sunset': 'Akşam namaz vakti',
      'notification_night': 'Yatsı namaz vakti',
      'adhan_enabled': 'Ezan Sesi Açık',
      'adhan_disabled': 'Ezan Sesi Kapalı',
      'notification_enabled': 'Bildirim Açık',
      'notification_disabled': 'Bildirim Kapalı',
      'notification_settings': 'Bildirim Ayarları',
      'dnd_permission_title': 'Rahatsız Etme İzni',
      'dnd_permission_message':
          'Namaz bildirimlerinin Rahatsız Etme modunda çalışması için izin vermeniz gerekiyor. Ayarlara giderek "Rahatsız Etme erişimi" iznini etkinleştirin.',
      'later': 'Sonra',
      'go_to_settings': 'Ayarlara Git',
    },
    'en': {
      'app_title': 'Ezanlar',
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'settings': 'Settings',
      'location': 'Location',
      'qibla': 'Qibla',
      'search_city': 'Search City',
      'select_country': 'Select Country',
      'nearby_mosques': 'Nearby Mosques',
      'prayer_time_label': 'Until prayer',
      'iftar_time': 'Time to Iftar',
      'theme': 'Theme',
      'language': 'Language',
      'notifications': 'Notifications',
      'enable_adhan': 'Enable Adhan Sound',
      'prayer_notifications': 'Prayer Notifications',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'hour': 'HR',
      'minute': 'MIN',
      'second': 'SEC',
      'cancel': 'Cancel',
      'search': 'Search',
      'loading': 'Loading...',
      'allow': 'Allow',
      'open_settings': 'Open Settings',
      'notification_imsak': 'Time for Fajr prayer',
      'notification_sunrise': 'Sunrise time',
      'notification_noon': 'Time for Dhuhr prayer',
      'notification_afternoon': 'Time for Asr prayer',
      'notification_sunset': 'Time for Maghrib prayer',
      'notification_night': 'Time for Isha prayer',
      'adhan_enabled': 'Adhan Sound Enabled',
      'adhan_disabled': 'Adhan Sound Disabled',
      'notification_enabled': 'Notifications Enabled',
      'notification_disabled': 'Notifications Disabled',
      'notification_settings': 'Notification Settings',
      'dnd_permission_title': 'Do Not Disturb Permission',
      'dnd_permission_message':
          'To allow prayer notifications to work in Do Not Disturb mode, you need to grant permission. Go to settings and enable "Do Not Disturb access".',
      'later': 'Later',
      'go_to_settings': 'Go to Settings',
    },
    'ar': {
      'app_title': 'Ezanlar',
      'fajr': 'الفجر',
      'sunrise': 'الشروق',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'settings': 'الإعدادات',
      'location': 'الموقع',
      'qibla': 'القبلة',
      'search_city': 'ابحث عن مدينة',
      'select_country': 'اختر الدولة',
      'nearby_mosques': 'المساجد القريبة',
      'prayer_time_label': 'حتى الصلاة',
      'iftar_time': 'حتى الإفطار',
      'theme': 'المظهر',
      'language': 'اللغة',
      'notifications': 'الإشعارات',
      'enable_adhan': 'تفعيل صوت الأذان',
      'prayer_notifications': 'إشعارات الصلاة',
      'system': 'النظام',
      'light': 'فاتح',
      'dark': 'داكن',
      'hour': 'سا',
      'minute': 'د',
      'second': 'ث',
      'cancel': 'إلغاء',
      'search': 'بحث',
      'loading': 'جارٍ التحميل...',
      'allow': 'السماح',
      'open_settings': 'افتح الإعدادات',
      'notification_imsak': 'حان وقت صلاة الفجر',
      'notification_sunrise': 'وقت الشروق',
      'notification_noon': 'حان وقت صلاة الظهر',
      'notification_afternoon': 'حان وقت صلاة العصر',
      'notification_sunset': 'حان وقت صلاة المغرب',
      'notification_night': 'حان وقت صلاة العشاء',
      'adhan_enabled': 'صوت الأذان مفعّل',
      'adhan_disabled': 'صوت الأذان معطّل',
      'notification_enabled': 'الإشعارات مفعّلة',
      'notification_disabled': 'الإشعارات معطّلة',
      'notification_settings': 'إعدادات الإشعارات',
      'dnd_permission_title': 'إذن عدم الإزعاج',
      'dnd_permission_message':
          'حتى تعمل إشعارات الصلاة في وضع عدم الإزعاج، يجب منح الإذن. انتقل إلى الإعدادات وفعّل "الوصول إلى عدم الإزعاج".',
      'later': 'لاحقًا',
      'go_to_settings': 'الذهاب إلى الإعدادات',
    },
    'de': {
      'app_title': 'Ezanlar',
      'fajr': 'Fadschr',
      'sunrise': 'Sonnenaufgang',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'settings': 'Einstellungen',
      'location': 'Standort',
      'qibla': 'Qibla',
      'search_city': 'Stadt suchen',
      'select_country': 'Land auswählen',
      'nearby_mosques': 'Moscheen in der Nähe',
      'prayer_time_label': 'Bis zum Gebet',
      'iftar_time': 'Zeit bis Iftar',
      'theme': 'Design',
      'language': 'Sprache',
      'notifications': 'Benachrichtigungen',
      'enable_adhan': 'Adhan-Ton aktivieren',
      'prayer_notifications': 'Gebetsbenachrichtigungen',
      'system': 'System',
      'light': 'Hell',
      'dark': 'Dunkel',
      'hour': 'STD',
      'minute': 'MIN',
      'second': 'SEK',
      'cancel': 'Abbrechen',
      'search': 'Suchen',
      'loading': 'Wird geladen...',
      'allow': 'Erlauben',
      'open_settings': 'Einstellungen öffnen',
      'notification_imsak': 'Zeit für das Fadschr-Gebet',
      'notification_sunrise': 'Zeit für den Sonnenaufgang',
      'notification_noon': 'Zeit für das Dhuhr-Gebet',
      'notification_afternoon': 'Zeit für das Asr-Gebet',
      'notification_sunset': 'Zeit für das Maghrib-Gebet',
      'notification_night': 'Zeit für das Isha-Gebet',
      'adhan_enabled': 'Adhan-Ton aktiviert',
      'adhan_disabled': 'Adhan-Ton deaktiviert',
      'notification_enabled': 'Benachrichtigungen aktiviert',
      'notification_disabled': 'Benachrichtigungen deaktiviert',
      'notification_settings': 'Benachrichtigungseinstellungen',
      'dnd_permission_title': 'Nicht-stören-Berechtigung',
      'dnd_permission_message':
          'Damit Gebetsbenachrichtigungen auch im Nicht-stören-Modus funktionieren, musst du den Zugriff erlauben. Öffne die Einstellungen und aktiviere den Zugriff auf "Nicht stören".',
      'later': 'Später',
      'go_to_settings': 'Zu den Einstellungen',
    },
  };

  static String translate(String key, String locale) {
    final normalized = normalizeLocale(locale);
    return translations[normalized]?[key] ?? translations['en']?[key] ?? key;
  }

  static String normalizeLocale(String? locale) {
    final value = locale?.toLowerCase() ?? '';
    if (supportedLanguages.contains(value)) return value;
    return 'en';
  }

  static String getLocale(String? preferredLanguage) {
    final preferred = preferredLanguage?.trim().toLowerCase();
    if (preferred != null && preferred.isNotEmpty) {
      final normalized = normalizeLocale(preferred);
      if (supportedLanguages.contains(normalized) && normalized.isNotEmpty) {
        return normalized;
      }
    }

    final systemLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode
            .toLowerCase();
    return supportedLanguages.contains(systemLocale) ? systemLocale : 'en';
  }

  static bool isRTL(String locale) => normalizeLocale(locale) == 'ar';

  static String prayerName(String prayerKey, String locale) {
    final normalizedPrayer = prayerKey.toLowerCase();
    if (normalizedPrayer.contains('fajr') || normalizedPrayer.contains('imsak')) {
      return translate('fajr', locale);
    }
    if (normalizedPrayer.contains('sunrise') ||
        normalizedPrayer.contains('gunes') ||
        normalizedPrayer.contains('güneş')) {
      return translate('sunrise', locale);
    }
    if (normalizedPrayer.contains('dhuhr') ||
        normalizedPrayer.contains('ogle') ||
        normalizedPrayer.contains('öğle') ||
        normalizedPrayer.contains('zuhr')) {
      return translate('dhuhr', locale);
    }
    if (normalizedPrayer.contains('asr') || normalizedPrayer.contains('ikindi')) {
      return translate('asr', locale);
    }
    if (normalizedPrayer.contains('maghrib') ||
        normalizedPrayer.contains('aksam') ||
        normalizedPrayer.contains('akşam')) {
      return translate('maghrib', locale);
    }
    if (normalizedPrayer.contains('isha') ||
        normalizedPrayer.contains('yatsi') ||
        normalizedPrayer.contains('yatsı')) {
      return translate('isha', locale);
    }
    return toBeginningOfSentenceCase(prayerKey) ?? prayerKey;
  }
}
