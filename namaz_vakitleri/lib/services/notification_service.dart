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

    final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('🔔 Notification plugin initialized: $initialized');

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_channel',
      'Prayer Notifications',
      description: 'Notifications for prayer times',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sabah_ezan'),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('🔔 Notification channel created');

    // Request iOS permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request Android permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    print('🔔 Notification permissions requested');
  }

  /// Test notification to verify notifications are working
  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Notifications',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sabah_ezan'),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentBadge: true,
        presentAlert: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      999, // Test ID
      '🔔 Test Notification',
      'Namaz vakti uygulaması çalışıyor!',
      notificationDetails,
    );

    print('🔔 Test notification sent');
  }

  /// Schedule a notification for prayer time
  static Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String language,
    required bool enableSound,
    String? soundFile,
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

      // Add emoji to prayer name based on prayer time
      String getPrayerEmoji(String prayer) {
        switch (prayer) {
          case 'Fajr':
            return '🌅'; // Güneş doğmak üzere
          case 'Sunrise':
            return '☀️'; // Güneş doğdu
          case 'Dhuhr':
            return '🌞'; // Öğle güneşi
          case 'Asr':
            return '🌇'; // İkindi/akşam yaklaşımı
          case 'Maghrib':
            return '🌆'; // Güneş batışı
          case 'Isha':
            return '🌙'; // Hilal/gece
          default:
            return '🕌';
        }
      }

      final displayName = '${getPrayerEmoji(prayerName)} $prayerName';

      // Convert to TZDateTime in local zone and ensure it's in the future
      tz.TZDateTime scheduled = tz.TZDateTime.from(prayerTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);
      
      // Only schedule notifications for prayer times that haven't passed yet today
      // If the prayer time has already passed, don't schedule a notification
      if (scheduled.isBefore(now)) {
        print('⏰ Prayer time for $prayerName has already passed today ($scheduled), skipping notification');
        return;
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        displayName,
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
            sound: enableSound && soundFile != null
                ? RawResourceAndroidNotificationSound(soundFile.replaceAll('.mp3', ''))
                : null,
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

      print('✅ Scheduled notification for $prayerName at $scheduled (ID: $id)');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// Schedule notifications for all prayers in a day with individual settings
  static Future<void> scheduleAllPrayerNotificationsWithSettings({
    required List<PrayerTime> prayers,
    required String language,
    required Map<String, bool> notificationSettings,
    required Map<String, bool> soundSettings,
  }) async {
    // Cancel all previous notifications
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Map prayer names to sound files
    final soundFiles = {
      'Fajr': 'sabah_ezan.mp3',
      'Dhuhr': 'ogle_ezan.mp3',
      'Asr': 'ikindi_ezan.mp3',
      'Maghrib': 'aksam_ezan.mp3',
      'Isha': 'yatsi_ezan.mp3',
    };

    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final enableNotification = notificationSettings[prayer.name] ?? true;
      final enableSound = soundSettings[prayer.name] ?? true;
      final soundFile = soundFiles[prayer.name];

      if (enableNotification) {
        print('🔔 Scheduling notification for ${prayer.name} at ${prayer.time} with sound: $enableSound ($soundFile)');
        await schedulePrayerNotification(
          id: i,
          prayerName: prayer.name,
          prayerTime: prayer.time,
          language: language,
          enableSound: enableSound,
          soundFile: soundFile,
        );
        print('✅ Notification scheduled for ${prayer.name}');
      } else {
        print('🚫 Notification disabled for ${prayer.name}');
      }
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
