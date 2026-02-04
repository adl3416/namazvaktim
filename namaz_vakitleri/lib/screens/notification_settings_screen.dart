import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Map<String, bool> _azanSoundEnabled = {};
  final Map<String, bool> _notificationEnabled = {};

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
      _azanSoundEnabled.addAll(settings.prayerSounds);
      _notificationEnabled.addAll(settings.prayerNotifications);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ayarlar kaydedildi'),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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

  List<Widget> _buildPrayerList(bool isDark) {
    final prayers = ['İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];
    return List.generate(
      prayers.length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildSimplePrayerRow(prayers[index], isDark),
      ),
    );
  }

  Widget _buildSimplePrayerRow(String prayerName, bool isDark) {
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

                // Prayer name
                Text(
                  prayerName,
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
              child: _buildIconButton(
                isDark: isDark,
                isActive: _notificationEnabled[prayerName] ?? false,
                icon: Icons.notifications_outlined,
                onTap: () {
                  setState(() {
                    _notificationEnabled[prayerName] = !(_notificationEnabled[prayerName] ?? false);
                  });
                },
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
                onTap: () {
                  setState(() {
                    _azanSoundEnabled[prayerName] = !(_azanSoundEnabled[prayerName] ?? false);
                  });
                },
              ),
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