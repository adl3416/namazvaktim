import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  final Map<String, String> _prayerKeys = {
    'Fajr': 'İmsak',
    'Sunrise': 'Güneş',
    'Dhuhr': 'Öğle',
    'Asr': 'İkindi',
    'Maghrib': 'Akşam',
    'Isha': 'Yatsı',
  };

  final Map<String, bool> _azanSoundEnabled = {};
  final Map<String, bool> _notificationEnabled = {};
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
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
        content: Text(
          'Ayarlar kaydedildi',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
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
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header section with description
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Her namaz vakti için ayarlar',
                                    style: AppTypography.h4.copyWith(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ezan sesini ve bildirimleri kontrol edin',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.notifications_active_rounded,
                              color: const Color(0xFF2196F3),
                              size: 32,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Prayer times settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Namaz Vakitleri',
                    style: AppTypography.h4.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildPrayerList(isDark, settings.language),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Global settings section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genel Ayarlar',
                    style: AppTypography.h4.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGlobalSettings(isDark, settings),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrayerList(bool isDark, String language) {
    final prayers = ['İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];
    return List.generate(
      prayers.length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildPrayerCard(prayers[index], isDark),
      ),
    );
  }

  Widget _buildPrayerCard(String prayerName, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : _getPrayerPhaseColor(prayerName).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.grey[700]!
              : _getPrayerTextColor(prayerName).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        child: Row(
          children: [
            // Prayer icon and name
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getPrayerPhaseColor(prayerName),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getPrayerIcon(prayerName),
                color: _getPrayerTextColor(prayerName),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Prayer name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerName,
                    style: AppTypography.h5.copyWith(
                      color: isDark ? Colors.white : _getPrayerTextColor(prayerName),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ezan ve bildirim seçenekleri',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Toggle switches with icons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Azan sound toggle
                Tooltip(
                  message: 'Ezan Sesi',
                  child: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _azanSoundEnabled[prayerName] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _azanSoundEnabled[prayerName] = value;
                        });
                      },
                      activeColor: const Color(0xFF2196F3),
                      inactiveThumbColor: Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🔊',
                  style: AppTypography.caption,
                ),
              ],
            ),

            const SizedBox(width: 4),

            // Notification toggle
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Bildirim',
                  child: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _notificationEnabled[prayerName] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _notificationEnabled[prayerName] = value;
                        });
                      },
                      activeColor: const Color(0xFF2196F3),
                      inactiveThumbColor: Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🔔',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSettings(bool isDark, AppSettings settings) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildGlobalSettingRow(
                isDark,
                'Tüm Ezanları Aç',
                'Tüm namaz vaitleri için ezan sesini etkinleştir',
                Icons.volume_up_rounded,
                () {
                  setState(() {
                    _azanSoundEnabled.updateAll((key, value) => true);
                  });
                },
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              _buildGlobalSettingRow(
                isDark,
                'Tüm Bildirimler Aç',
                'Tüm namaz vaitleri için bildirimleri etkinleştir',
                Icons.notifications_rounded,
                () {
                  setState(() {
                    _notificationEnabled.updateAll((key, value) => true);
                  });
                },
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              _buildGlobalSettingRow(
                isDark,
                'Tüm Ezanları Kapat',
                'Tüm namaz vaitleri için ezan sesini devre dışı bırak',
                Icons.volume_off_rounded,
                () {
                  setState(() {
                    _azanSoundEnabled.updateAll((key, value) => false);
                  });
                },
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              _buildGlobalSettingRow(
                isDark,
                'Tüm Bildirimler Kapat',
                'Tüm namaz vaitleri için bildirimleri devre dışı bırak',
                Icons.notifications_off_rounded,
                () {
                  setState(() {
                    _notificationEnabled.updateAll((key, value) => false);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalSettingRow(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }