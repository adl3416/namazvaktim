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
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Map<String, bool> _azanSoundEnabled = {};
  final Map<String, bool> _notificationEnabled = {};
  final Map<String, int> _notificationOffset = {}; // 5 or 15 minutes before

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = context.read<AppSettings>();
    setState(() {
      _azanSoundEnabled.clear();
      _notificationEnabled.clear();
      _notificationOffset.clear();
      _azanSoundEnabled.addAll(settings.prayerSounds);
      _notificationEnabled.addAll(settings.prayerNotifications);
      _notificationOffset.addAll(settings.prayerNotificationOffsets);
    });
  }

  void _saveSettings() {
    final settings = context.read<AppSettings>();
    _azanSoundEnabled.forEach((prayer, enabled) {
      settings.setPrayerSound(prayer, enabled);
    });
    _notificationEnabled.forEach((prayer, enabled) {
      settings.setPrayerNotification(prayer, enabled);
    });
    _notificationOffset.forEach((prayer, offset) {
      settings.setPrayerNotificationOffset(prayer, offset);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ayarlar kaydedildi'),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
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

  // Prayer time color mapping matching home_screen.dart
  Color _getPrayerPhaseColor(String prayerName) {
    switch (prayerName) {
      case 'İmsak':
        return const Color(0xFFFFF3E0); // Early morning warm
      case 'Güneş':
        return const Color(0xFFFFE0B2); // Sunrise golden
      case 'Öğle':
        return const Color(0xFFC8E6C9); // Noon green
      case 'İkindi':
        return const Color(0xFFB3E5FC); // Afternoon blue
      case 'Akşam':
        return const Color(0xFFFFCDD2); // Evening pink-red
      case 'Yatsı':
        return const Color(0xFFEDE7F6); // Night purple
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getPrayerTextColor(String prayerName) {
    switch (prayerName) {
      case 'İmsak':
        return const Color(0xFFE65100); // Dark orange
      case 'Güneş':
        return const Color(0xFFF57F17); // Dark golden
      case 'Öğle':
        return const Color(0xFF1B5E20); // Dark green
      case 'İkindi':
        return const Color(0xFF01579B); // Dark blue
      case 'Akşam':
        return const Color(0xFFC62828); // Dark red
      case 'Yatsı':
        return const Color(0xFF4A148C); // Dark purple
      default:
        return const Color(0xFF212121);
    }
  }

  IconData _getPrayerIcon(String prayer) {
    switch (prayer) {
      case 'İmsak':
        return Icons.wb_sunny_outlined;
      case 'Güneş':
        return Icons.wb_sunny;
      case 'Öğle':
        return Icons.brightness_high;
      case 'İkindi':
        return Icons.brightness_medium;
      case 'Akşam':
        return Icons.brightness_low;
      case 'Yatsı':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<AppSettings>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
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
          AppLocalizations.translate('notification_settings', settings.language),
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
            // Header section
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Namaz Vakitleri',
                    style: AppTypography.h2.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Her namaz için bildirim ve ezan sesi ayarları',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Column headers
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Vakit',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        'Bildirim',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        'Ezan',
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

            // Prayer list
            ..._buildPrayerList(isDark),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bildirim Testi',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Anlık bildirim + 30 sn sonra zamanlanmış bildirim gönderir.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.alarm, size: 18),
              label: const Text('Test bildirimi gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _runNotificationTest(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runNotificationTest() async {
    // Step 1: Check exact alarm permission and show diagnostic info
    final canSchedule =
        await NotificationService.canScheduleExactNotifications();

    if (canSchedule == false) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('İzin Gerekli'),
          content: const Text(
            '"Kesin Alarmlar" izni verilmemiş.\n\n'
            'Açılacak ekranda "Namaz Vaktim" uygulamasını bulup izni açın, '
            'sonra geri dönüp tekrar deneyin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await NotificationService.requestExactAlarmPermission();
              },
              child: const Text('Ayarlara Git'),
            ),
          ],
        ),
      );
      return;
    }

    // Step 2: Send immediate notification (verifies channel works)
    await NotificationService.showTestNotification();

    // Step 3: Schedule one for 10 seconds later (verifies zonedSchedule works)
    final String scheduleResult =
        await NotificationService.scheduleTestNotificationIn10Seconds();

    if (!mounted) return;

    // Show full diagnostic info in a dialog
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Sonucu'),
        content: Text(
          'İzin durumu: ${canSchedule == true ? "✅ İzin var" : "⚠️ Bilinmiyor"}\n\n'
          'Anlık bildirim: ✅ Gönderildi\n\n'
          'Zamanlanmış (10 sn) bildirim:\n$scheduleResult\n\n'
          '10 saniye bekleyin. Bildirim gelirse sistem çalışıyor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrayerList(bool isDark) {
    // Map Turkish names to English prayer names used in settings
    final Map<String, String> turkishToEnglish = {
      'İmsak': 'Fajr',
      'Güneş': 'Sunrise',
      'Öğle': 'Dhuhr',
      'İkindi': 'Asr',
      'Akşam': 'Maghrib',
      'Yatsı': 'Isha',
    };
    
    final prayers = ['İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];
    return List.generate(
      prayers.length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildSimplePrayerRow(prayers[index], turkishToEnglish[prayers[index]]!, isDark),
      ),
    );
  }

  Widget _buildSimplePrayerRow(String displayName, String prayerName, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          // Prayer icon and name - 3 parts
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Prayer icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPrayerPhaseColor(displayName),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPrayerIcon(displayName),
                    color: _getPrayerTextColor(displayName),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Prayer name
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

          // Notification button - 1 part
          Expanded(
            flex: 1,
            child: Center(
              child: _buildNotificationButton(
                isDark: isDark,
                prayerName: prayerName,
              ),
            ),
          ),

          // Azan button - 1 part
          Expanded(
            flex: 1,
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
                  final prayerProvider = context.read<PrayerProvider>();
                  await settings.setPrayerSound(prayerName, newValue);
                  await prayerProvider.rescheduleNotifications();
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
  }) {
    final isActive = _notificationEnabled[prayerName] ?? false;
    final currentOffset = _notificationOffset[prayerName] ?? 5;

    return PopupMenuButton<int>(
      onSelected: (int selectedOffset) async {
        setState(() {
          if (selectedOffset == 0) {
            _notificationEnabled[prayerName] = false;
          } else {
            _notificationEnabled[prayerName] = true;
            _notificationOffset[prayerName] = selectedOffset;
          }
        });
        // Save immediately so closing the app doesn't lose the change
        final settings = context.read<AppSettings>();
        await settings.setPrayerNotification(prayerName, selectedOffset != 0);
        if (selectedOffset != 0) {
          await settings.setPrayerNotificationOffset(prayerName, selectedOffset);
        }
        // Reschedule so the new offset takes effect right away
        await context.read<PrayerProvider>().rescheduleNotifications();
      },
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(
                !isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: !isActive
                    ? const Color(0xFFEF4444)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 10),
              Text(
                'Kapali',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: !isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 5,
          child: Row(
            children: [
              Icon(
                isActive && currentOffset == 5 ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isActive && currentOffset == 5
                    ? const Color(0xFF2196F3)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 10),
              Text(
                '5 dk önce',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: isActive && currentOffset == 5
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 15,
          child: Row(
            children: [
              Icon(
                isActive && currentOffset == 15 ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isActive && currentOffset == 15
                    ? const Color(0xFF2196F3)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 10),
              Text(
                '15 dk önce',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: isActive && currentOffset == 15
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
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
