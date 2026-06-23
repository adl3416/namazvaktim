import 'package:flutter/services.dart';

import '../config/localization.dart';
import '../models/prayer_model.dart';

class HomeWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.vakit.app.ezanlar/widget',
  );

  static Future<void> syncPrayerTimes({
    required PrayerTimes prayerTimes,
    required String language,
    List<PrayerTime> additionalPrayers = const [],
  }) async {
    final allPrayers = <PrayerTime>[
      ...prayerTimes.prayerTimesList,
      ...additionalPrayers,
    ];

    final prayers = allPrayers
        .map(
          (prayer) => {
            'name': prayer.name,
            'time': prayer.time.toIso8601String(),
            'displayLabel': AppLocalizations.prayerName(prayer.name, language),
            'shortLabel': _shortPrayerLabel(prayer.name, language),
          },
        )
        .toList();

    final payload = <String, dynamic>{
      'city': prayerTimes.city,
      'country': prayerTimes.country,
      'language': AppLocalizations.normalizeLocale(language),
      'dateIso': prayerTimes.date.toIso8601String(),
      'dateLabel': _formatDateLabel(prayerTimes.date),
      'activePrayerName': prayerTimes.activePrayer?.name,
      'prayers': prayers,
    };

    await _channel.invokeMethod('updatePrayerWidget', payload);
  }

  static String _formatDateLabel(DateTime date) {
    const months = <String>[
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    final month = months[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  static String _shortPrayerLabel(String prayerName, String language) {
    final normalizedLocale = AppLocalizations.normalizeLocale(language);
    final normalizedPrayer = prayerName.toLowerCase();

    if (normalizedLocale == 'tr') {
      if (normalizedPrayer.contains('fajr') || normalizedPrayer.contains('imsak')) {
        return 'İmsaka';
      }
      if (normalizedPrayer.contains('sunrise') || normalizedPrayer.contains('gunes')) {
        return 'Güneşe';
      }
      if (normalizedPrayer.contains('dhuhr') ||
          normalizedPrayer.contains('ogle') ||
          normalizedPrayer.contains('zuhr')) {
        return 'Öğleye';
      }
      if (normalizedPrayer.contains('asr') || normalizedPrayer.contains('ikindi')) {
        return 'İkindiye';
      }
      if (normalizedPrayer.contains('maghrib') || normalizedPrayer.contains('aksam')) {
        return 'Akşama';
      }
      if (normalizedPrayer.contains('isha') || normalizedPrayer.contains('yatsi')) {
        return 'Yatsıya';
      }
    }

    return AppLocalizations.prayerName(prayerName, normalizedLocale);
  }
}
