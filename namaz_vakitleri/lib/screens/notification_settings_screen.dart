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

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Map<String, bool> _azanSoundEnabled = {
    'İmsak': false,
    'Güneş': false,
    'Öğle': false,
    'İkindi': false,
    'Akşam': false,
    'Yatsı': false,
  };

  final Map<String, bool> _notificationEnabled = {
    'İmsak': false,
    'Güneş': false,
    'Öğle': false,
    'İkindi': false,
    'Akşam': false,
    'Yatsı': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = context.read<AppSettings>();
    setState(() {
      _azanSoundEnabled.addAll(settings.prayerSounds);
      _notificationEnabled.addAll(settings.prayerNotifications);
    });
  }

  void _saveSettings() {
    final settings = context.read<AppSettings>();
    // Save prayer-specific settings
    _azanSoundEnabled.forEach((prayer, enabled) {
      settings.setPrayerSound(prayer, enabled);
    });
    _notificationEnabled.forEach((prayer, enabled) {
      settings.setPrayerNotification(prayer, enabled);
    });
  }

  Color _getTimeBasedScaffoldColor(bool isDark) {
    final now = DateTime.now();
    final hour = now.hour;

    if (isDark) {
      if (hour >= 5 && hour < 11) {
        return const Color(0xFF4A3A4A);
      } else if (hour >= 11 && hour < 15) {
        return const Color(0xFF4A4A2A);
      } else if (hour >= 15 && hour < 19) {
        return const Color(0xFF4A2A2A);
      } else {
        return const Color(0xFF2A2A4A);
      }
    } else {
      if (hour >= 5 && hour < 11) {
        return const Color(0xFFF8E8E8);
      } else if (hour >= 11 && hour < 15) {
        return const Color(0xFFFFF8E1);
      } else if (hour >= 15 && hour < 19) {
        return const Color(0xFFFFE8E1);
      } else {
        return const Color(0xFFE8E8F8);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.read<AppSettings>().language;

    return Scaffold(
      backgroundColor: _getTimeBasedScaffoldColor(isDark),
      appBar: AppBar(
        backgroundColor: _getTimeBasedScaffoldColor(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () {
            _saveSettings();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Bildirim Ayarları',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.xl),

            Expanded(
              child: ListView(
                children: [
                  // Header card with column titles
                  Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBgSecondary
                          : AppColors.lightBgSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isDark ? AppColors.darkDivider : AppColors.divider,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Prayer name space
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Namaz Vakti',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Spacer
                        Expanded(child: SizedBox()),
                        // Column headers
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(
                                'Ezan',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 70,
                              child: Text(
                                'Bildirim',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildPrayerTimeSetting('İmsak', 'imsak'),
                  _buildPrayerTimeSetting('Güneş', 'gunes'),
                  _buildPrayerTimeSetting('Öğle', 'ogle'),
                  _buildPrayerTimeSetting('İkindi', 'ikindi'),
                  _buildPrayerTimeSetting('Akşam', 'aksam'),
                  _buildPrayerTimeSetting('Yatsı', 'yatsi'),
                  // Logo at the bottom
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/app_icon.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'v1.0.0',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeSetting(String prayerName, String prayerKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get icon and color for each prayer time
    IconData getPrayerIcon(String prayer) {
      switch (prayer) {
        case 'İmsak':
          return Icons.wb_sunny_outlined; // Güneş doğmak üzere
        case 'Güneş':
          return Icons.wb_sunny; // Güneş doğdu
        case 'Öğle':
          return Icons.brightness_high; // Güneş parlak
        case 'İkindi':
          return Icons.brightness_medium; // Güneş az parlak
        case 'Akşam':
          return Icons.brightness_low; // Güneş batıyor
        case 'Yatsı':
          return Icons.nightlight_round; // Hilal
        default:
          return Icons.access_time;
      }
    }

    Color getPrayerIconColor(String prayer) {
      switch (prayer) {
        case 'İmsak':
          return const Color(0xFFFFA726); // Turuncu - güneş doğmak üzere
        case 'Güneş':
          return const Color(0xFFFFD54F); // Sarı - güneş doğdu
        case 'Öğle':
          return const Color(0xFFFFEB3B); // Parlak sarı - öğle güneşi
        case 'İkindi':
          return const Color(0xFFFFC107); // Altın sarısı - ikindi güneşi
        case 'Akşam':
          return const Color(0xFFFF5722); // Kırmızı-turuncu - güneş batıyor
        case 'Yatsı':
          return const Color(0xFF3F51B5); // Mavi - gece/hilal
        default:
          return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBgSecondary
            : AppColors.lightBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Prayer name and icon on the left
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Icon(
                  getPrayerIcon(prayerName),
                  color: getPrayerIconColor(prayerName),
                  size: 20,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    prayerName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Spacer to push switches to the right
          Expanded(child: SizedBox()),
          // Switches on the right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Azan Sound Toggle
              SizedBox(
                width: 70,
                child: Switch(
                  value: _azanSoundEnabled[prayerName] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _azanSoundEnabled[prayerName] = value;
                    });
                  },
                  activeColor: isDark
                      ? AppColors.darkAccentPrimary
                      : AppColors.accentPrimary,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              // Notification Toggle
              SizedBox(
                width: 70,
                child: Switch(
                  value: _notificationEnabled[prayerName] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _notificationEnabled[prayerName] = value;
                    });
                  },
                  activeColor: isDark
                      ? AppColors.darkAccentPrimary
                      : AppColors.accentPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}