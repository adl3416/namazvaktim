import 'package:flutter/services.dart';

import '../models/prayer_model.dart';

class HomeWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.vakit.app.ezanlar/widget',
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
}
