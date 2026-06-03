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

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
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

  Color _surfaceColor(bool isDark) =>
      isDark
          ? AppColors.darkBgSecondary.withOpacity(0.92)
          : Colors.white.withOpacity(0.9);

  Color _borderColor(bool isDark) =>
      isDark
          ? AppColors.darkDivider.withOpacity(0.9)
          : Colors.white.withOpacity(0.9);

  Color _accentColor(bool isDark) =>
      isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary;

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
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? const [
                      AppColors.darkBg,
                      Color(0xFF111827),
                      AppColors.darkBg,
                    ]
                    : const [
                      Color(0xFFF3F8FC),
                      AppColors.lightBg,
                      Colors.white,
                    ],
          ),
        ),
        child: SingleChildScrollView(
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
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
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
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
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
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
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
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
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
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
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
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                Expanded(
                  child: Text(
                    displayName,
                    style: AppTypography.bodyLarge.copyWith(
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
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
                  if (newValue) {
                    await NotificationService.checkAndRequestCriticalPermissions();
                  }
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
        if (selectedOffset != 0) {
          await NotificationService.checkAndRequestCriticalPermissions();
        }
      },
      color: _surfaceColor(isDark),
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _borderColor(isDark)),
      ),
      itemBuilder: (context) => [
        _buildOffsetItem(
          isDark: isDark,
          language: language,
          value: 0,
          currentOffset: currentOffset,
          isActive: isActive,
          label: _text(language, tr: 'Kapalı', en: 'Off', ar: 'إيقاف'),
        ),
        _buildOffsetItem(
          isDark: isDark,
          language: language,
          value: 5,
          currentOffset: currentOffset,
          isActive: isActive,
          label: _text(language, tr: '5 dk önce', en: '5 min before', ar: 'قبل 5 دقائق'),
        ),
        _buildOffsetItem(
          isDark: isDark,
          language: language,
          value: 15,
          currentOffset: currentOffset,
          isActive: isActive,
          label: _text(language, tr: '15 dk önce', en: '15 min before', ar: 'قبل 15 دقيقة'),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              isActive
                  ? _accentColor(isDark).withOpacity(0.18)
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isActive
                    ? _accentColor(isDark).withOpacity(0.35)
                    : _borderColor(isDark),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 18,
              color:
                  isActive
                      ? _accentColor(isDark)
                      : (isDark
                          ? AppColors.darkTextLight
                          : AppColors.textLight),
            ),
            if (isActive)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: _accentColor(isDark),
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
            color:
                isSelected
                    ? (value == 0
                        ? const Color(0xFFEF4444)
                        : _accentColor(isDark))
                    : (isDark
                        ? AppColors.darkTextLight
                        : AppColors.textLight),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
          color:
              isActive
                  ? _accentColor(isDark).withOpacity(0.18)
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isActive
                    ? _accentColor(isDark).withOpacity(0.35)
                    : _borderColor(isDark),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color:
              isActive
                  ? _accentColor(isDark)
                  : (isDark ? AppColors.darkTextLight : AppColors.textLight),
        ),
      ),
    );
  }
}
