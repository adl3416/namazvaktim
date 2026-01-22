import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/prayer_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request iOS permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Schedule a notification for prayer time
  static Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String language,
    required bool enableSound,
  }) async {
    try {
      final labels = {
        'tr': {
          'Fajr': 'İmsak namaz vakti',
          'Sunrise': 'Güneş vakti',
          'Dhuhr': 'Öğle namaz vakti',
          'Asr': 'İkindi namaz vakti',
          'Maghrib': 'Akşam namaz vakti',
          'Isha': 'Yatsı namaz vakti',
        },
        'en': {
          'Fajr': 'Time for Fajr prayer',
          'Sunrise': 'Sunrise',
          'Dhuhr': 'Time for Dhuhr prayer',
          'Asr': 'Time for Asr prayer',
          'Maghrib': 'Time for Maghrib prayer',
          'Isha': 'Time for Isha prayer',
        },
        'ar': {
          'Fajr': 'حان وقت الإِمساك',
          'Sunrise': 'شروق الشمس',
          'Dhuhr': 'حان وقت صلاة الظهر',
          'Asr': 'حان وقت صلاة العصر',
          'Maghrib': 'حان وقت صلاة المغرب',
          'Isha': 'حان وقت صلاة العشاء',
        },
      };

      final label = labels[language]?[prayerName] ?? 'Prayer time';

      // Convert to TZDateTime in local zone and ensure it's in the future
      tz.TZDateTime scheduled = tz.TZDateTime.from(prayerTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);
      if (scheduled.isBefore(now)) {
        // If the scheduled time is already past for today, schedule for next day
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        prayerName,
        label,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',
            'Prayer Notifications',
            channelDescription: 'Notifications for prayer times',
            importance: Importance.high,
            priority: Priority.high,
            playSound: enableSound,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: enableSound,
            presentBadge: true,
            presentAlert: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('Scheduled notification for $prayerName at $prayerTime');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// Schedule notifications for all prayers in a day
  static Future<void> scheduleAllPrayerNotifications({
    required List<PrayerTime> prayers,
    required String language,
    required bool enableSound,
  }) async {
    // Cancel all previous notifications
    await _flutterLocalNotificationsPlugin.cancelAll();

    for (int i = 0; i < prayers.length; i++) {
      await schedulePrayerNotification(
        id: i,
        prayerName: prayers[i].name,
        prayerTime: prayers[i].time,
        language: language,
        enableSound: enableSound,
      );
    }
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
