import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const List<String> _prayers = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  final Map<String, bool> _azanSoundEnabled = {};
  final Map<String, bool> _notificationEnabled = {};
  final Map<String, int> _notificationOffset = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = context.read<AppSettings>();
    setState(() {
      _azanSoundEnabled
        ..clear()
        ..addAll(settings.prayerSounds);
      _notificationEnabled
        ..clear()
        ..addAll(settings.prayerNotifications);
      _notificationOffset
        ..clear()
        ..addAll(settings.prayerNotificationOffsets);
    });
  }

  String _text(
    String language, {
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

  String _prayerLabel(String prayerName, String language) =>
      AppLocalizations.prayerName(prayerName, language);

  void _saveSettings() {
    final settings = context.read<AppSettings>();
    final language = AppLocalizations.getLocale(settings.language);

    _azanSoundEnabled.forEach(settings.setPrayerSound);
    _notificationEnabled.forEach(settings.setPrayerNotification);
    _notificationOffset.forEach(settings.setPrayerNotificationOffset);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            language,
            tr: 'Ayarlar kaydedildi',
            en: 'Settings saved',
            ar: 'تم حفظ الإعدادات',
          ),
        ),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getPrayerPhaseColor(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return const Color(0xFFFFF3E0);
      case 'Sunrise':
        return const Color(0xFFFFE0B2);
      case 'Dhuhr':
        return const Color(0xFFC8E6C9);
      case 'Asr':
        return const Color(0xFFB3E5FC);
      case 'Maghrib':
        return const Color(0xFFFFCDD2);
      case 'Isha':
        return const Color(0xFFEDE7F6);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getPrayerTextColor(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return const Color(0xFFE65100);
      case 'Sunrise':
        return const Color(0xFFF57F17);
      case 'Dhuhr':
        return const Color(0xFF1B5E20);
      case 'Asr':
        return const Color(0xFF01579B);
      case 'Maghrib':
        return const Color(0xFFC62828);
      case 'Isha':
        return const Color(0xFF4A148C);
      default:
        return const Color(0xFF212121);
    }
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return Icons.wb_sunny_outlined;
      case 'Sunrise':
        return Icons.wb_sunny;
      case 'Dhuhr':
        return Icons.brightness_high;
      case 'Asr':
        return Icons.brightness_medium;
      case 'Maghrib':
        return Icons.brightness_low;
      case 'Isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<AppSettings>();
    final language = AppLocalizations.getLocale(settings.language);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () {
            _saveSettings();
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.translate('notification_settings', language),
          style: AppTypography.h3.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(
                      language,
                      tr: 'Ezanlar',
                      en: 'Ezanlar',
                      ar: 'Ezanlar',
                    ),
                    style: AppTypography.h2.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _text(
                      language,
                      tr: 'Her vakit için bildirim ve ezan ayarları',
                      en: 'Notification and adhan settings for each prayer',
                      ar: 'إعدادات الإشعارات والأذان لكل صلاة',
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _text(
                        language,
                        tr: 'Vakit',
                        en: 'Prayer',
                        ar: 'الوقت',
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _text(
                          language,
                          tr: 'Bildirim',
                          en: 'Alert',
                          ar: 'الإشعار',
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _text(
                          language,
                          tr: 'Ezan',
                          en: 'Adhan',
                          ar: 'الأذان',
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._buildPrayerList(isDark, language),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton(bool isDark, String language) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(
              language,
              tr: 'Bildirim Testi',
              en: 'Notification Test',
              ar: 'اختبار الإشعار',
            ),
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _text(
              language,
              tr: 'Anlık bildirim ve 30 saniye sonra zamanlanmış bildirim gönderir.',
              en: 'Sends an instant notification and another one 30 seconds later.',
              ar: 'يرسل إشعارًا فوريًا وآخر بعد 30 ثانية.',
            ),
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.alarm, size: 18),
              label: Text(
                _text(
                  language,
                  tr: 'Test bildirimi gönder',
                  en: 'Send test notification',
                  ar: 'أرسل إشعارًا تجريبيًا',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _runNotificationTest,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runNotificationTest() async {
    final language = AppLocalizations.getLocale(
      context.read<AppSettings>().language,
    );
    final canSchedule =
        await NotificationService.canScheduleExactNotifications();

    if (canSchedule == false) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            _text(
              language,
              tr: 'İzin Gerekli',
              en: 'Permission Required',
              ar: 'يلزم منح الإذن',
            ),
          ),
          content: Text(
            _text(
              language,
              tr:
                  '"Kesin Alarmlar" izni verilmemiş.\n\nAçılacak ekranda uygulamayı bulup izni açın, sonra geri dönüp tekrar deneyin.',
              en:
                  'Exact alarm permission is not granted.\n\nOpen the next screen, enable the permission for this app, then return and try again.',
              ar:
                  'لم يتم منح إذن المنبهات الدقيقة.\n\nافتح الشاشة التالية وفعّل الإذن لهذا التطبيق ثم ارجع وجرّب مرة أخرى.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.translate('cancel', language)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await NotificationService.requestExactAlarmPermission();
              },
              child: Text(
                AppLocalizations.translate('go_to_settings', language),
              ),
            ),
          ],
        ),
      );
      return;
    }

    await NotificationService.showTestNotification();
    final scheduleResult =
        await NotificationService.scheduleTestNotificationIn10Seconds();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _text(
            language,
            tr: 'Test Sonucu',
            en: 'Test Result',
            ar: 'نتيجة الاختبار',
          ),
        ),
        content: Text(
          _text(
            language,
            tr:
                'İzin durumu: ${canSchedule == true ? "İzin var" : "Bilinmiyor"}\n\nAnlık bildirim: Gönderildi\n\nZamanlanmış (10 sn) bildirim:\n$scheduleResult\n\n10 saniye bekleyin. Bildirim gelirse sistem çalışıyor.',
            en:
                'Permission status: ${canSchedule == true ? "Granted" : "Unknown"}\n\nInstant notification: Sent\n\nScheduled (10 sec) notification:\n$scheduleResult\n\nWait 10 seconds. If the notification arrives, the system is working.',
            ar:
                'حالة الإذن: ${canSchedule == true ? "ممنوح" : "غير معروف"}\n\nالإشعار الفوري: تم الإرسال\n\nالإشعار المجدول (10 ثوان):\n$scheduleResult\n\nانتظر 10 ثوانٍ. إذا وصل الإشعار فهذا يعني أن النظام يعمل.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _text(
                language,
                tr: 'Tamam',
                en: 'OK',
                ar: 'حسنًا',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrayerList(bool isDark, String language) {
    return _prayers
        .map(
          (prayer) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPrayerRow(
              prayerName: prayer,
              displayName: _prayerLabel(prayer, language),
              isDark: isDark,
              language: language,
            ),
          ),
        )
        .toList();
  }

  Widget _buildPrayerRow({
    required String prayerName,
    required String displayName,
    required bool isDark,
    required String language,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPrayerPhaseColor(prayerName),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPrayerIcon(prayerName),
                    color: _getPrayerTextColor(prayerName),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  displayName,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _buildNotificationButton(
                isDark: isDark,
                prayerName: prayerName,
                language: language,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildIconButton(
                isDark: isDark,
                isActive: _azanSoundEnabled[prayerName] ?? false,
                icon: Icons.volume_up_outlined,
                onTap: () async {
                  final newValue = !(_azanSoundEnabled[prayerName] ?? false);
                  setState(() {
                    _azanSoundEnabled[prayerName] = newValue;
                  });
                  final settings = context.read<AppSettings>();
                  await settings.setPrayerSound(prayerName, newValue);
                  await context.read<PrayerProvider>().rescheduleNotifications();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton({
    required bool isDark,
    required String prayerName,
    required String language,
  }) {
    final isActive = _notificationEnabled[prayerName] ?? false;
    final currentOffset = _notificationOffset[prayerName] ?? 5;

    return PopupMenuButton<int>(
      onSelected: (selectedOffset) async {
        setState(() {
          if (selectedOffset == 0) {
            _notificationEnabled[prayerName] = false;
          } else {
            _notificationEnabled[prayerName] = true;
            _notificationOffset[prayerName] = selectedOffset;
          }
        });
        final settings = context.read<AppSettings>();
        await settings.setPrayerNotification(prayerName, selectedOffset != 0);
        if (selectedOffset != 0) {
          await settings.setPrayerNotificationOffset(
            prayerName,
            selectedOffset,
          );
        }
        await context.read<PrayerProvider>().rescheduleNotifications();
      },
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        _buildOffsetItem(
          isDark: isDark,
          language: language,
          value: 0,
          currentOffset: currentOffset,
          isActive: isActive,
          label: _text(
            language,
            tr: 'Kapalı',
            en: 'Off',
            ar: 'إيقاف',
          ),
        ),
        _buildOffsetItem(
          isDark: isDark,
          language: language,
          value: 5,
          currentOffset: currentOffset,
          isActive: isActive,
          label: _text(
            language,
            tr: '5 dk önce',
            en: '5 min before',
            ar: 'قبل 5 دقائق',
          ),
        ),
        _buildOffsetItem(
          isDark: isDark,
          language: language,
          value: 15,
          currentOffset: currentOffset,
          isActive: isActive,
          label: _text(
            language,
            tr: '15 dk önce',
            en: '15 min before',
            ar: 'قبل 15 دقيقة',
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2196F3).withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 18,
              color: isActive
                  ? const Color(0xFF2196F3)
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
            if (isActive)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$currentOffset',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildOffsetItem({
    required bool isDark,
    required String language,
    required int value,
    required int currentOffset,
    required bool isActive,
    required String label,
  }) {
    final isSelected =
        value == 0 ? !isActive : (isActive && currentOffset == value);

    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isSelected
                ? (value == 0
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF2196F3))
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required bool isDark,
    required bool isActive,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2196F3).withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive
              ? const Color(0xFF2196F3)
              : (isDark ? Colors.grey[500] : Colors.grey[400]),
        ),
      ),
    );
  }
}
