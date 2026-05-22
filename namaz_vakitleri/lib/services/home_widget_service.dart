import 'package:flutter/services.dart';

import '../models/prayer_model.dart';

class HomeWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.vakit.app.namaz_vakitleri/widget',
  );

  static Future<void> syncPrayerTimes({
    required PrayerTimes prayerTimes,
  }) async {
    final prayers = prayerTimes.prayerTimesList
        .map(
          (prayer) => {
            'name': prayer.name,
            'time': prayer.time.toIso8601String(),
          },
        )
        .toList();

    final payload = <String, dynamic>{
      'city': prayerTimes.city,
      'country': prayerTimes.country,
      'dateIso': prayerTimes.date.toIso8601String(),
      'dateLabel': _formatDateLabel(prayerTimes.date),
      'prayers': prayers,
    };

    await _channel.invokeMethod('updatePrayerWidget', payload);
  }

  static String _formatDateLabel(DateTime date) {
    const months = <String>[
      'Ocak',
      'Subat',
      'Mart',
      'Nisan',
      'Mayis',
      'Haziran',
      'Temmuz',
      'Agustos',
      'Eylul',
      'Ekim',
      'Kasim',
      'Aralik',
    ];

    final month = months[date.month - 1];
    return '${date.day} $month ${date.year}';
  }
}
