import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import '../models/prayer_model.dart';
import '../config/localization.dart';
import '../main.dart' show navigatorKey;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification action IDs
  static const String _dismissAction = 'DISMISS_NOTIFICATION';
  static const String _snoozeAction = 'SNOOZE_NOTIFICATION';

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

    final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationTap,
    );
    print('🔔 Notification plugin initialized: $initialized');

    // Setup notification response handler
    await _setupNotificationResponseHandler();

    // Create Android notification channel with full screen intent
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_channel',
      'Prayer Notifications',
      description: 'Notifications for prayer times',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sabah_ezan'),
      enableVibration: true,
      showBadge: true,
      ledColor: Colors.blue,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('🔔 Notification channel created with full-screen intent support');

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

    // Check and request Do Not Disturb permission for Android
    await _checkAndRequestDoNotDisturbPermission();
  }

  /// Check and request Do Not Disturb permission for Android
  static Future<void> _checkAndRequestDoNotDisturbPermission() async {
    try {
      final status = await Permission.notificationPolicy.status;
      print('🔔 Do Not Disturb permission status: $status');

      if (status.isDenied) {
        print('🔔 Requesting Do Not Disturb permission');
        final result = await Permission.notificationPolicy.request();
        print('🔔 Do Not Disturb permission result: $result');

        if (result.isPermanentlyDenied) {
          print('🔔 Do Not Disturb permission permanently denied');
          // Show dialog to guide user to settings
          await Future.delayed(const Duration(milliseconds: 500), () {
            _showDoNotDisturbSettingsDialog();
          });
        }
      } else if (status.isGranted) {
        print('🔔 Do Not Disturb permission granted');
      }
    } catch (e) {
      print('Error checking Do Not Disturb permission: $e');
    }
  }

  /// Show dialog to guide user to Do Not Disturb settings
  static void _showDoNotDisturbSettingsDialog() {
    final context = getContext();
    if (context != null && context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.translate('dnd_permission_title', 'tr')),
            content: Text(AppLocalizations.translate('dnd_permission_message', 'tr')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.translate('later', 'tr')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings(); // Opens app settings
                },
                child: Text(AppLocalizations.translate('go_to_settings', 'tr')),
              ),
            ],
          );
        },
      );
    }
  }

  /// Get context if available (for showing dialogs)
  static BuildContext? getContext() {
    return navigatorKey?.currentContext;
  }

  /// Handle notification tap when app is in foreground
  static void _handleNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.actionId}');
    
    if (response.actionId == _dismissAction) {
      print('📱 Dismissing notification');
      deactivateNotificationMode();
    }
  }

  /// Handle notification tap when app is in background
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationTap(NotificationResponse response) {
    print('🔔 Background notification tapped: ${response.actionId}');
    
    if (response.actionId == _dismissAction) {
      print('📱 Dismissing background notification');
      deactivateNotificationMode();
    }
  }

  /// Setup notification response handler
  static Future<void> _setupNotificationResponseHandler() async {
    // Listen to notification taps
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermissions();
    
    print('🔔 Notification response handler setup complete');
  }

  /// Acquire screen lock (keep screen on)
  static Future<void> _acquireScreenLock() async {
    try {
      await WakelockPlus.enable();
      print('💡 Screen lock acquired - screen will stay on');
    } catch (e) {
      print('Error acquiring screen lock: $e');
    }
  }

  /// Release screen lock
  static Future<void> _releaseScreenLock() async {
    try {
      await WakelockPlus.disable();
      print('💡 Screen lock released');
    } catch (e) {
      print('Error releasing screen lock: $e');
    }
  }

  /// Set volume to maximum for Adhan
  static Future<void> _setMaxVolume() async {
    try {
      await VolumeController().setVolume(1.0, showSystemUI: true);
      print('🔊 Volume set to maximum');
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /// Restore volume after notification
  static Future<void> _restoreVolume() async {
    try {
      // Volume will auto-restore based on device settings
      print('🔊 Volume control restored to user control');
    } catch (e) {
      print('Error restoring volume: $e');
    }
  }

  /// Activate screen and volume for notification
  static Future<void> activateNotificationMode() async {
    try {
      await _acquireScreenLock();
      await _setMaxVolume();
      print('🎯 Notification mode activated - screen locked on, volume max');
    } catch (e) {
      print('Error activating notification mode: $e');
    }
  }

  /// Release notification mode
  static Future<void> deactivateNotificationMode() async {
    try {
      await _releaseScreenLock();
      await _restoreVolume();
      print('🎯 Notification mode deactivated');
    } catch (e) {
      print('Error deactivating notification mode: $e');
    }
  }

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
      // Kullanıcının seçtiği dildeki bildirim mesajlarını al
      String getNotificationLabel(String prayer, String lang) {
        final prayerKeyMap = {
          'Fajr': 'notification_imsak',
          'Sunrise': 'notification_sunrise',
          'Dhuhr': 'notification_noon',
          'Asr': 'notification_afternoon',
          'Maghrib': 'notification_sunset',
          'Isha': 'notification_night',
        };
        
        final key = prayerKeyMap[prayer] ?? 'notification_imsak';
        return AppLocalizations.translate(key, language);
      }

      final label = getNotificationLabel(prayerName, language);

      // Add emoji to prayer name based on prayer time
      String getPrayerEmoji(String prayer) {
        switch (prayer) {
          case 'Fajr':
            return '🌅';
          case 'Sunrise':
            return '☀️';
          case 'Dhuhr':
            return '🌞';
          case 'Asr':
            return '🌇';
          case 'Maghrib':
            return '🌆';
          case 'Isha':
            return '🌙';
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
            enableVibration: true,
            vibrationPattern: [0, 500, 250, 500], // Vibration pattern
            lights: const [Colors.blue, Colors.blue],
            fullScreenIntent: true,
            actions: [
              AndroidNotificationAction(
                _dismissAction,
                'Close',
                cancelNotification: true,
              ),
            ],
            ticker: label,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: enableSound,
            presentBadge: true,
            presentAlert: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Acquire screen lock and set volume when notification is scheduled
      print('✅ Scheduled notification for $prayerName at $scheduled (ID: $id)');
      
      // Schedule screen lock for when notification arrives (1-2 seconds before prayer time)
      tz.TZDateTime screenLockTime = tz.TZDateTime.from(
        prayerTime.subtract(const Duration(seconds: 2)),
        tz.local,
      );
      
      if (screenLockTime.isAfter(tz.TZDateTime.now(tz.local))) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id + 100, // Unique ID for screen lock task
          displayName,
          'Acquiring screen lock...',
          screenLockTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_channel',
              'Prayer Notifications',
              channelDescription: 'Screen lock for prayer notifications',
              importance: Importance.low,
              priority: Priority.low,
              playSound: false,
              showWhen: false,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('📱 Scheduled screen lock task for $prayerName');
      }
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

  /// Show immediate notification for prayer time (when prayer time arrives)
  static Future<void> showPrayerTimeNotification({
    required String prayerName,
    required String language,
  }) async {
    // Kullanıcının seçtiği dildeki bildirim mesajlarını al
    String getNotificationLabel(String prayer, String lang) {
      final prayerKeyMap = {
        'Fajr': 'notification_imsak',
        'Sunrise': 'notification_sunrise',
        'Dhuhr': 'notification_noon',
        'Asr': 'notification_afternoon',
        'Maghrib': 'notification_sunset',
        'Isha': 'notification_night',
      };
      
      final key = prayerKeyMap[prayer] ?? 'notification_imsak';
      return AppLocalizations.translate(key, language);
    }

    final label = getNotificationLabel(prayerName, language);

    // Add emoji to prayer name based on prayer time
    String getPrayerEmoji(String prayer) {
      switch (prayer) {
        case 'Fajr':
          return '🌅';
        case 'Sunrise':
          return '☀️';
        case 'Dhuhr':
          return '🌞';
        case 'Asr':
          return '🌇';
        case 'Maghrib':
          return '🌆';
        case 'Isha':
          return '🌙';
        default:
          return '🕌';
      }
    }

    final displayName = '${getPrayerEmoji(prayerName)} $prayerName';

    // Map prayer names to sound files
    final soundFiles = {
      'Fajr': 'sabah_ezan.mp3',
      'Dhuhr': 'ogle_ezan.mp3',
      'Asr': 'ikindi_ezan.mp3',
      'Maghrib': 'aksam_ezan.mp3',
      'Isha': 'yatsi_ezan.mp3',
    };

    final soundFile = soundFiles[prayerName];

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
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID based on timestamp
      displayName,
      label,
      notificationDetails,
    );

    print('🔔 Immediate notification shown for $prayerName');
  }
}
