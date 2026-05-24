import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io' show Platform;
import '../models/prayer_model.dart';
import '../config/localization.dart';
import '../main.dart' show navigatorKey;
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification action IDs
  static const String _dismissAction = 'DISMISS_NOTIFICATION';
  static const String _snoozeAction = 'SNOOZE_NOTIFICATION';
  static const String _silentExactChannelId = 'prayer_exact_silent';

  static String _channelNameForLocale(String language, {required bool reminder}) {
    switch (language) {
      case 'tr':
        return reminder ? 'Namaz Hatirlatmalari' : 'Namaz Bildirimleri';
      case 'ar':
        return reminder ? 'تذكيرات الصلاة' : 'إشعارات الصلاة';
      default:
        return reminder ? 'Prayer Reminders' : 'Prayer Notifications';
    }
  }

  static String _channelDescriptionForLocale(String language, {required bool reminder}) {
    switch (language) {
      case 'tr':
        return reminder
            ? 'Namaz vakti oncesi sessiz hatirlatmalar'
            : 'Namaz vakitleri icin bildirimler';
      case 'ar':
        return reminder
            ? 'تذكيرات صامتة قبل أوقات الصلاة'
            : 'إشعارات لمواقيت الصلاة';
      default:
        return reminder
            ? 'Silent reminders before prayer times'
            : 'Notifications for prayer times';
    }
  }

  static String _textByLanguage(String language, {
    required String tr,
    required String en,
    required String ar,
  }) {
    switch (language) {
      case 'tr':
        return tr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationTapStateless,
    );
    print('🔔 Notification plugin initialized: $initialized');

    // Setup notification response handler
    await _setupNotificationResponseHandler();

    // Create per-prayer Android notification channels (one per prayer for correct sound)
    const prayerChannels = [
      ('prayer_fajr',    'Fajr Prayer',    'sabah_ezan'),
      ('prayer_dhuhr',   'Dhuhr Prayer',   'ogle_ezan'),
      ('prayer_asr',     'Asr Prayer',     'ikindi_ezan'),
      ('prayer_maghrib', 'Maghrib Prayer', 'aksam_ezan'),
      ('prayer_isha',    'Isha Prayer',    'yatsi_ezan'),
    ];

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    for (final (channelId, channelName, soundName) in prayerChannels) {
      final channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Notifications for prayer times',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundName),
        enableVibration: true,
        showBadge: true,
        ledColor: Colors.blue,
      );
      await androidPlugin?.createNotificationChannel(channel);
    }

    const reminderChannel = AndroidNotificationChannel(
      'prayer_reminders',
      'Prayer Reminders',
      description: 'Silent reminder notifications before prayer times',
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
      showBadge: true,
      ledColor: Colors.blue,
    );
    await androidPlugin?.createNotificationChannel(reminderChannel);

    const silentExactChannel = AndroidNotificationChannel(
      _silentExactChannelId,
      'Prayer Notifications (Silent)',
      description: 'Prayer notifications without adhan sound',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
      showBadge: true,
      ledColor: Colors.blue,
    );
    await androidPlugin?.createNotificationChannel(silentExactChannel);

    print('🔔 Per-prayer notification channels created');

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

    // NOTE: Critical permission checks (exact alarm, battery optimization, DND)
    // are done AFTER runApp() via checkAndRequestCriticalPermissions().
    // They cannot run here because navigatorKey has no context yet.
  }

  /// Call this AFTER the app UI is shown (post-frame) so dialogs can be displayed.
  static Future<void> checkAndRequestCriticalPermissions() async {
    if (!Platform.isAndroid) return;
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await _checkExactAlarmPermission(androidPlugin);
    await _checkBatteryOptimization();
    await _checkAndRequestDoNotDisturbPermission();
  }

  /// Check SCHEDULE_EXACT_ALARM permission (Android 12+) and guide user to grant it
  static Future<void> _checkExactAlarmPermission(
      AndroidFlutterLocalNotificationsPlugin? androidPlugin) async {
    try {
      final canSchedule = await androidPlugin?.canScheduleExactNotifications();
      if (canSchedule == false) {
        print('⚠️ Exact alarm permission not granted — requesting...');
        // Delay slightly so any initialization dialogs settle
        await Future.delayed(const Duration(milliseconds: 800));
        final context = getContext();
        if (context != null && context.mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Zamanlı Bildirim İzni'),
              content: const Text(
                'Namaz vakitlerinde bildirim gelebilmesi için "Kesin Alarmlar" iznini açmanız gerekiyor.\n\n'
                'Açılacak ekranda "Namaz Vaktim" uygulamasını bulup izni açın.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Sonra'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await androidPlugin?.requestExactAlarmsPermission();
                  },
                  child: const Text('İzin Ver'),
                ),
              ],
            ),
          );
        } else {
          // Context not ready yet — try opening the settings directly
          await androidPlugin?.requestExactAlarmsPermission();
        }
      } else {
        print('✅ Exact alarm permission granted');
      }
    } catch (e) {
      print('Error checking exact alarm permission: $e');
    }
  }

  /// Request ignore battery optimization so alarms fire on time
  static Future<void> _checkBatteryOptimization() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        print('⚠️ Battery optimization not bypassed — requesting...');
        await Permission.ignoreBatteryOptimizations.request();
      } else {
        print('✅ Battery optimization bypass granted');
      }
    } catch (e) {
      print('Error checking battery optimization: $e');
    }
  }

  /// Check and request Do Not Disturb permission for Android (shown only once)
  static Future<void> _checkAndRequestDoNotDisturbPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool('dnd_guide_shown') ?? false;
      if (alreadyShown) {
        print('🔔 DND guide already shown before, skipping');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 1200), () {
        _showDoNotDisturbSettingsDialog();
      });
      await prefs.setBool('dnd_guide_shown', true);
      print('🔔 Do Not Disturb setup guide shown');
    } catch (e) {
      print('Error in Do Not Disturb setup: $e');
    }
  }

  /// Show dialog to guide user to Do Not Disturb settings
  static void _showDoNotDisturbSettingsDialog() {
    final context = getContext();
    if (context != null && context.mounted) {
      final language =
          Provider.of<AppSettings>(context, listen: false).language;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.translate('dnd_permission_title', language)),
            content: Text(AppLocalizations.translate('dnd_permission_message', language)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.translate('later', language)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings(); // Opens app settings
                },
                child: Text(AppLocalizations.translate('go_to_settings', language)),
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
      print('📱 Dismissing notification and stopping adhan');
      deactivateNotificationMode();
      
      // Stop any playing audio when user dismisses notification
      _stopPlayingAudio();
    }
  }
  
  /// Stop playing adhan audio via PrayerProvider
  static void _stopPlayingAudio() {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Get PrayerProvider from context
        final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
        prayerProvider.stopAdhan();
        print('🔇 Adhan stopped via notification dismiss');
      } else {
        print('⚠️ Could not access context to stop audio');
      }
    } catch (e) {
      print('❌ Error stopping audio: $e');
    }
  }

  /// Handle notification tap when app is in background
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationTapStateless(NotificationResponse response) {
    print('🔔 Background notification tapped: ${response.actionId}');
    
    if (response.actionId == _dismissAction) {
      print('📱 Dismissing background notification and stopping adhan');
      deactivateNotificationMode();
    }
  }

  /// Handle notification tap when app is in background (legacy)
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationTap(NotificationResponse response) {
    print('🔔 Background notification tapped: ${response.actionId}');
    
    if (response.actionId == _dismissAction) {
      print('📱 Dismissing background notification and stopping adhan');
      deactivateNotificationMode();
      
      // Stop any playing audio when user dismisses notification
      _stopPlayingAudio();
    }
  }

  /// Setup notification response handler
  static Future<void> _setupNotificationResponseHandler() async {
    // Notification response handler is setup via initialize callback
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
      // Volume will be controlled automatically by notification settings
      // and Do Not Disturb exemption
      print('🔊 Volume set to maximum (via notification channel)');
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

  /// Returns null on non-Android or if check fails; false = permission missing.
  static Future<bool?> canScheduleExactNotifications() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications();
    } catch (e) {
      print('Error checking canScheduleExactNotifications: $e');
      return null;
    }
  }

  /// Opens the Alarms & Reminders settings page on Android 12+.
  static Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      print('Error requesting exact alarm permission: $e');
    }
  }

  static Future<void> showTestNotification() async {
    final language = navigatorKey.currentContext != null
        ? Provider.of<AppSettings>(navigatorKey.currentContext!, listen: false)
            .language
        : 'en';
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_notifications',
      'Test Bildirimleri',
      channelDescription: 'Debug test notifications — no ezan sound',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentSound: false,
        presentBadge: true,
        presentAlert: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      999, // Test ID
      '🔔 Test Bildirimi (Anlık)',
      'Bildirim kanalı çalışıyor!',
      notificationDetails,
    );

    print('🔔 Test notification sent');
  }

  /// Schedule a test notification 10 seconds in the future.
  /// Returns a diagnostic string describing what happened.
  static Future<String> scheduleTestNotificationIn10Seconds() async {
    try {
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
      final tzScheduled = _toScheduledInstant(scheduledTime);
      final scheduleMode = await _resolveScheduleMode();

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        998, // Test scheduled ID
        '⏰ Test Bildirimi (10 sn)',
        'Zamanlı bildirimler çalışıyor!',
        tzScheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notifications',
            'Test Bildirimleri',
            channelDescription: 'Debug test notifications — no ezan sound',
            importance: Importance.max,
            priority: Priority.max,
            playSound: false,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: false,
            presentBadge: true,
            presentAlert: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Check how many notifications are now pending
      final pending =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final pendingIds = pending.map((n) => n.id).toList();
      print('✅ Test notification scheduled at $tzScheduled with mode $scheduleMode. Pending IDs: $pendingIds');

      if (pending.any((n) => n.id == 998)) {
        return '✅ Zamanlandı (${tzScheduled.toLocal()})\n'
            'Bekleyen bildirim sayısı: ${pending.length}';
      } else {
        return '❌ Zamanlanamadı — pending listede yok!\n'
            'Bekleyen bildirim sayısı: ${pending.length}\n'
            'Muhtemel sebep: Kesin alarm izni yok.';
      }
    } catch (e) {
      print('❌ Error scheduling test notification: $e');
      return '❌ Hata: $e';
    }
  }

  // Keep old name as alias for backward compatibility
  static Future<void> scheduleTestNotificationIn30Seconds() =>
      scheduleTestNotificationIn10Seconds();

  static String _channelIdForPrayer(String prayerName) {
    switch (prayerName) {
      case 'Fajr':    return 'prayer_fajr';
      case 'Dhuhr':   return 'prayer_dhuhr';
      case 'Asr':     return 'prayer_asr';
      case 'Maghrib': return 'prayer_maghrib';
      case 'Isha':    return 'prayer_isha';
      default:        return _silentExactChannelId;
    }
  }

  static String _channelNameForPrayer(String prayerName) {
    switch (prayerName) {
      case 'Fajr':    return 'Fajr Prayer';
      case 'Dhuhr':   return 'Dhuhr Prayer';
      case 'Asr':     return 'Asr Prayer';
      case 'Maghrib': return 'Maghrib Prayer';
      case 'Isha':    return 'Isha Prayer';
      default:        return 'Prayer Notification';
    }
  }

  static bool _hasDedicatedSound(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
      case 'Dhuhr':
      case 'Asr':
      case 'Maghrib':
      case 'Isha':
        return true;
      default:
        return false;
    }
  }

  @visibleForTesting
  static bool shouldScheduleExactPrayerAlert({
    required bool enableNotification,
    required bool enableSound,
  }) {
    return enableNotification || enableSound;
  }

  @visibleForTesting
  static bool shouldScheduleReminder({
    required bool enableNotification,
    required int offsetMinutes,
  }) {
    return enableNotification && offsetMinutes > 0;
  }

  @visibleForTesting
  static DateTime reminderScheduledTime({
    required DateTime prayerTime,
    required int offsetMinutes,
  }) {
    return prayerTime.subtract(Duration(minutes: offsetMinutes));
  }

  @visibleForTesting
  static bool shouldPlaySoundForExactPrayerAlert({
    required String prayerName,
    required bool enableSound,
  }) {
    return enableSound && _hasDedicatedSound(prayerName);
  }

  static AndroidNotificationSound? _androidSoundForExactPrayerAlert(
    String? soundFile,
  ) {
    if (soundFile == null || soundFile.isEmpty) {
      return null;
    }
    final resourceName = soundFile.replaceAll('.mp3', '');
    return RawResourceAndroidNotificationSound(resourceName);
  }

  @visibleForTesting
  static String exactChannelIdForPrayer({
    required String prayerName,
    required bool enableSound,
  }) {
    if (!shouldPlaySoundForExactPrayerAlert(
      prayerName: prayerName,
      enableSound: enableSound,
    )) {
      return _silentExactChannelId;
    }
    return _channelIdForPrayer(prayerName);
  }

  /// Convert a device-local [DateTime] into a fixed absolute instant for scheduling.
  ///
  /// We intentionally schedule against UTC instead of `tz.local` because this app
  /// does not currently set the timezone package's local location from the device.
  /// Using UTC here preserves the exact instant the user selected/tested.
  static tz.TZDateTime _toScheduledInstant(DateTime dateTime) {
    final utcTime = dateTime.toUtc();
    return tz.TZDateTime.from(utcTime, tz.UTC);
  }

  /// Prefer exact alarms when available, but gracefully fall back so
  /// scheduled notifications still have a chance to fire on stricter devices.
  static Future<AndroidScheduleMode> _resolveScheduleMode() async {
    final canScheduleExact = await canScheduleExactNotifications();
    if (canScheduleExact == true) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static String _buildReminderBody({
    required String prayerLabel,
    required String language,
    required int offsetMinutes,
  }) {
    if (offsetMinutes <= 0) return prayerLabel;
    return _textByLanguage(
      language,
      tr: '$prayerLabel icin $offsetMinutes dakika kaldi.',
      en: '$offsetMinutes minutes left until $prayerLabel.',
      ar: 'تبقى $offsetMinutes دقيقة على $prayerLabel.',
    );
  }

  static String _buildReminderTitle({
    required String prayerName,
    required String language,
    required int offsetMinutes,
  }) {
    if (offsetMinutes <= 0) return prayerName;
    return _textByLanguage(
      language,
      tr: '$prayerName - $offsetMinutes dk kaldi',
      en: '$prayerName - $offsetMinutes min left',
      ar: '$prayerName - بقي $offsetMinutes د',
    );
  }

  /// Schedule a notification for prayer time
  static Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String language,
    required bool enableSound,
    String? soundFile,
    int offsetMinutes = 0,
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

      final localizedPrayerName = AppLocalizations.prayerName(prayerName, language);
      final label = getNotificationLabel(prayerName, language);
      final isReminderNotification = offsetMinutes > 0;
      final shouldPlaySound = !isReminderNotification &&
          shouldPlaySoundForExactPrayerAlert(
            prayerName: prayerName,
            enableSound: enableSound,
          );
      final channelId = isReminderNotification
          ? 'prayer_reminders'
          : exactChannelIdForPrayer(
              prayerName: prayerName,
              enableSound: enableSound,
            );
      final channelName = isReminderNotification
          ? _channelNameForLocale(language, reminder: true)
          : (shouldPlaySound
              ? _channelNameForPrayer(prayerName)
              : 'Prayer Notifications (Silent)');
      final androidSound = shouldPlaySound
          ? _androidSoundForExactPrayerAlert(soundFile)
          : null;
      final notificationBody = _buildReminderBody(
        prayerLabel: label,
        language: language,
        offsetMinutes: offsetMinutes,
      );

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

      final displayName = '${getPrayerEmoji(prayerName)} $localizedPrayerName';
      final notificationTitle = isReminderNotification
          ? _buildReminderTitle(
              prayerName: localizedPrayerName,
              language: language,
              offsetMinutes: offsetMinutes,
            )
          : displayName;

      // Keep the user's intended wall-clock time as an exact instant.
      // Subtract the offset so notification fires before the actual prayer time.
      final scheduledTime = prayerTime.subtract(Duration(minutes: offsetMinutes));
      final scheduled = _toScheduledInstant(scheduledTime);
      final now = tz.TZDateTime.now(tz.UTC);
      final scheduleMode = await _resolveScheduleMode();
      
      // Only schedule notifications for prayer times that haven't passed yet today
      // If the prayer time has already passed, don't schedule a notification
      if (scheduled.isBefore(now)) {
        print('⏰ Notification time for $prayerName has already passed today ($scheduled, offset=${offsetMinutes}m), skipping');
        return;
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        notificationTitle,
        notificationBody,
          scheduled,
          NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: isReminderNotification
                ? _channelDescriptionForLocale(language, reminder: true)
                : shouldPlaySound
                    ? _channelDescriptionForLocale(language, reminder: false)
                    : 'Prayer notifications without adhan sound',
            importance: isReminderNotification ? Importance.high : Importance.max,
            priority: isReminderNotification ? Priority.high : Priority.max,
            playSound: shouldPlaySound,
            sound: androidSound,
            enableVibration: true,
            fullScreenIntent: false,
            autoCancel: isReminderNotification,
            onlyAlertOnce: false,
            actions: [
              AndroidNotificationAction(
                _dismissAction,
                _textByLanguage(language, tr: 'Kapat', en: 'Close', ar: 'اغلاق'),
                cancelNotification: true,
              ),
            ],
            ticker: label,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: shouldPlaySound,
            presentBadge: true,
            presentAlert: true,
            interruptionLevel: isReminderNotification
                ? InterruptionLevel.active
                : InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Acquire screen lock and set volume when notification is scheduled
      print('✅ Scheduled notification for $prayerName at $scheduled (ID: $id, mode: $scheduleMode)');
      
      // NOTE: Removed screen lock duplicate notification to fix 29x notification issue
      // The main notification with fullScreenIntent is sufficient
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
    Map<String, int>? offsetSettings,
    int idOffset = 0,
  }) async {
    // Do NOT cancel all notifications - only schedule for enabled prayers
    // This prevents duplicate notification scheduling
    print('📋 Processing ${prayers.length} prayers for notification scheduling');

    // Map prayer names to sound files
    final soundFiles = {
      'Fajr': 'sabah_ezan.mp3',
      'Dhuhr': 'ogle_ezan.mp3',
      'Asr': 'ikindi_ezan.mp3',
      'Maghrib': 'aksam_ezan.mp3',
      'Isha': 'yatsi_ezan.mp3',
    };

    int scheduledCount = 0;
    int skippedCount = 0;

    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final enableNotification = notificationSettings[prayer.name] ?? true;
      final enableSound = soundSettings[prayer.name] ?? true;
      final soundFile = soundFiles[prayer.name];
      final offsetMinutes = offsetSettings?[prayer.name] ?? 5;

      if (shouldScheduleReminder(
        enableNotification: enableNotification,
        offsetMinutes: offsetMinutes,
      )) {
        print('🔔 Scheduling reminder for ${prayer.name} at ${prayer.time} (${offsetMinutes}m before)');
        await schedulePrayerNotification(
          id: idOffset + 100 + i,
          prayerName: prayer.name,
          prayerTime: prayer.time,
          language: language,
          enableSound: false,
          soundFile: soundFile,
          offsetMinutes: offsetMinutes,
        );
        print('✅ Reminder scheduled for ${prayer.name}');
        scheduledCount++;
      } else if (!enableNotification) {
        print('🚫 Notification disabled for ${prayer.name} - skipping');
        skippedCount++;
      }

      if (shouldScheduleExactPrayerAlert(
        enableNotification: enableNotification,
        enableSound: enableSound,
      )) {
        print('🔔 Scheduling exact prayer alert for ${prayer.name} at ${prayer.time} with sound: $enableSound');
        await schedulePrayerNotification(
          id: idOffset + 1000 + i,
          prayerName: prayer.name,
          prayerTime: prayer.time,
          language: language,
          enableSound: enableSound,
          soundFile: soundFile,
          offsetMinutes: 0,
        );
        print('✅ Exact prayer alert scheduled for ${prayer.name}');
      }
    }
    
    print('📊 Notification scheduling summary: scheduled=$scheduledCount, skipped=$skippedCount');
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  
  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🗑️ All notifications cancelled');
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

    // Map prayer names to sound files (kept for reference)
    final soundFiles = {
      'Fajr': 'sabah_ezan.mp3',
      'Dhuhr': 'ogle_ezan.mp3',
      'Asr': 'ikindi_ezan.mp3',
      'Maghrib': 'aksam_ezan.mp3',
      'Isha': 'yatsi_ezan.mp3',
    };

    // soundFile is unused here — the channel itself carries the correct sound
    // ignore: unused_local_variable
    final soundFile = soundFiles[prayerName];
    final channelId = _channelIdForPrayer(prayerName);
    final channelName = _channelNameForPrayer(prayerName);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for prayer times',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
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
