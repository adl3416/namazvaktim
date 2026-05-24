import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vakitleri/services/notification_service.dart';

void main() {
  group('NotificationService exact prayer alert decisions', () {
    test('all adhan prayers use sounded channels only when sound is enabled', () {
      const expectedChannels = {
        'Fajr': 'prayer_fajr',
        'Dhuhr': 'prayer_dhuhr',
        'Asr': 'prayer_asr',
        'Maghrib': 'prayer_maghrib',
        'Isha': 'prayer_isha',
      };

      for (final entry in expectedChannels.entries) {
        expect(
          NotificationService.exactChannelIdForPrayer(
            prayerName: entry.key,
            enableSound: true,
          ),
          entry.value,
        );
        expect(
          NotificationService.exactChannelIdForPrayer(
            prayerName: entry.key,
            enableSound: false,
          ),
          'prayer_exact_silent',
        );
      }
    });

    test('uses silent channel when notification is enabled but adhan sound is disabled', () {
      final channelId = NotificationService.exactChannelIdForPrayer(
        prayerName: 'Dhuhr',
        enableSound: false,
      );

      expect(channelId, 'prayer_exact_silent');
      expect(
        NotificationService.shouldPlaySoundForExactPrayerAlert(
          prayerName: 'Dhuhr',
          enableSound: false,
        ),
        isFalse,
      );
    });

    test('uses sounded channel when prayer supports adhan and sound is enabled', () {
      final channelId = NotificationService.exactChannelIdForPrayer(
        prayerName: 'Dhuhr',
        enableSound: true,
      );

      expect(channelId, 'prayer_dhuhr');
      expect(
        NotificationService.shouldPlaySoundForExactPrayerAlert(
          prayerName: 'Dhuhr',
          enableSound: true,
        ),
        isTrue,
      );
    });

    test('sunrise stays silent even if sound is requested', () {
      final channelId = NotificationService.exactChannelIdForPrayer(
        prayerName: 'Sunrise',
        enableSound: true,
      );

      expect(channelId, 'prayer_exact_silent');
      expect(
        NotificationService.shouldPlaySoundForExactPrayerAlert(
          prayerName: 'Sunrise',
          enableSound: true,
        ),
        isFalse,
      );
    });

    test('exact alert is skipped only when both notification and sound are disabled', () {
      expect(
        NotificationService.shouldScheduleExactPrayerAlert(
          enableNotification: false,
          enableSound: false,
        ),
        isFalse,
      );
      expect(
        NotificationService.shouldScheduleExactPrayerAlert(
          enableNotification: true,
          enableSound: false,
        ),
        isTrue,
      );
      expect(
        NotificationService.shouldScheduleExactPrayerAlert(
          enableNotification: false,
          enableSound: true,
        ),
        isTrue,
      );
    });

    test('reminder follows selected offset for all prayers', () {
      final prayerTime = DateTime(2026, 5, 24, 13, 15);
      const prayers = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

      for (final prayer in prayers) {
        expect(
          NotificationService.shouldScheduleReminder(
            enableNotification: true,
            offsetMinutes: 5,
          ),
          isTrue,
          reason: '$prayer should schedule a 5-minute reminder when enabled',
        );
        expect(
          NotificationService.reminderScheduledTime(
            prayerTime: prayerTime,
            offsetMinutes: 5,
          ),
          DateTime(2026, 5, 24, 13, 10),
        );
        expect(
          NotificationService.shouldScheduleReminder(
            enableNotification: true,
            offsetMinutes: 15,
          ),
          isTrue,
          reason: '$prayer should schedule a 15-minute reminder when enabled',
        );
        expect(
          NotificationService.reminderScheduledTime(
            prayerTime: prayerTime,
            offsetMinutes: 15,
          ),
          DateTime(2026, 5, 24, 13, 0),
        );
        expect(
          NotificationService.shouldScheduleReminder(
            enableNotification: false,
            offsetMinutes: 5,
          ),
          isFalse,
          reason: '$prayer should not schedule reminder when notification is disabled',
        );
      }
    });
  });
}
