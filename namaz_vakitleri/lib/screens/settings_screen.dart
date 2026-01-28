import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakitleri/config/color_system.dart';
import 'package:namaz_vakitleri/config/localization.dart';
import 'package:namaz_vakitleri/providers/app_settings.dart';
import 'package:namaz_vakitleri/providers/prayer_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/city_search_dialog.dart';
import 'country_selection_screen.dart';
import 'notification_settings_screen.dart';
import 'theme_selection_screen.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Color _getTimeBasedScaffoldColor(bool isDark) {
    final now = DateTime.now();
    final hour = now.hour;

    if (isDark) {
      // Dark mode için daha koyu tonlar
      if (hour >= 5 && hour < 11) {
        return const Color(0xFF4A3A4A); // Koyu pembe
      } else if (hour >= 11 && hour < 15) {
        return const Color(0xFF4A4A2A); // Koyu sarı
      } else if (hour >= 15 && hour < 19) {
        return const Color(0xFF4A2A2A); // Koyu turuncu
      } else {
        return const Color(0xFF2A2A4A); // Koyu mavi
      }
    } else {
      // Light mode için pastel tonlar
      if (hour >= 5 && hour < 11) {
        return const Color(0xFFF8E8E8); // Açık pembe - sabah
      } else if (hour >= 11 && hour < 15) {
        return const Color(0xFFFFF8E1); // Açık sarı - öğlen
      } else if (hour >= 15 && hour < 19) {
        return const Color(0xFFFFE8E1); // Açık turuncu - akşam
      } else {
        return const Color(0xFFE8E8F8); // Açık mavi - gece
      }
    }
  }

  LinearGradient _getTimeBasedGradient(bool isDark) {
    final now = DateTime.now();
    final hour = now.hour;

    if (isDark) {
      // Dark mode için gradient'ler
      if (hour >= 5 && hour < 11) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A3A4A), Color(0xFF2A1A2A)],
        );
      } else if (hour >= 11 && hour < 15) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A4A2A), Color(0xFF2A2A1A)],
        );
      } else if (hour >= 15 && hour < 19) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A2A2A), Color(0xFF2A1A1A)],
        );
      } else {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2A4A), Color(0xFF1A1A2A)],
        );
      }
    } else {
      // Light mode için gradient'ler
      if (hour >= 5 && hour < 11) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8E8E8), Color(0xFFE8D8D8)],
        );
      } else if (hour >= 11 && hour < 15) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFE8E0D1)],
        );
      } else if (hour >= 15 && hour < 19) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE8E1), Color(0xFFE8D8D1)],
        );
      } else {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8E8F8), Color(0xFFD8D8E8)],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final locale = settings.language;
        final isRTL = AppLocalizations.isRTL(locale);

        // 🎨 Günün zamanına göre gradient arka plan belirleme
        final timeBasedGradient = _getTimeBasedGradient(isDark);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: timeBasedGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: (isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary).withOpacity(0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Text(
                          AppLocalizations.translate('settings', locale),
                          style: AppTypography.h2.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body Content
                  Expanded(
                    child: Directionality(
                      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                      child: Container(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location Section
                              _buildSettingCard(
                                label: AppLocalizations.translate('location', locale),
                                icon: Icons.location_on,
                                isDark: isDark,
                                locale: locale,
                                showLabel: true,
                                child: GestureDetector(
                                  onTap: () {
                                    _showCitySearch(context, prayerProvider);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                          ? AppColors.darkBgSecondary
                                          : AppColors.lightBgSecondary).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(
                                        color: (isDark ? AppColors.darkTextLight : AppColors.textLight).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            prayerProvider.currentLocation?.city ?? 'Select Location',
                                            style: AppTypography.bodyLarge.copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.textPrimary,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: isDark
                                              ? AppColors.darkTextLight
                                              : AppColors.textLight,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: AppSpacing.md),

                              // Notifications Section
                              _buildSettingCard(
                                label: 'Bildirimler',
                                icon: Icons.notifications,
                                isDark: isDark,
                                locale: locale,
                                showLabel: false,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const NotificationSettingsScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                          ? AppColors.darkBgSecondary
                                          : AppColors.lightBgSecondary).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(
                                        color: (isDark ? AppColors.darkTextLight : AppColors.textLight).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B35).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                          child: Icon(
                                            Icons.notifications,
                                            color: const Color(0xFFFF6B35),
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            'Bildirimler',
                                            style: AppTypography.bodyLarge.copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.textPrimary,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: isDark
                                              ? AppColors.darkTextLight
                                              : AppColors.textLight,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: AppSpacing.md),

                              // Theme Section
                              _buildSettingCard(
                                label: 'Tema',
                                icon: Icons.palette,
                                isDark: isDark,
                                locale: locale,
                                showLabel: false,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ThemeSelectionScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                          ? AppColors.darkBgSecondary
                                          : AppColors.lightBgSecondary).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(
                                        color: (isDark ? AppColors.darkTextLight : AppColors.textLight).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF9C27B0).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                          child: Icon(
                                            Icons.palette,
                                            color: const Color(0xFF9C27B0),
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            'Tema',
                                            style: AppTypography.bodyLarge.copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.textPrimary,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: isDark
                                              ? AppColors.darkTextLight
                                              : AppColors.textLight,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: AppSpacing.md),

                              // Language Section
                              _buildSettingCard(
                                label: 'Dil',
                                icon: Icons.language,
                                isDark: isDark,
                                locale: locale,
                                showLabel: false,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LanguageSelectionScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                          ? AppColors.darkBgSecondary
                                          : AppColors.lightBgSecondary).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(
                                        color: (isDark ? AppColors.darkTextLight : AppColors.textLight).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                          child: Icon(
                                            Icons.language,
                                            color: const Color(0xFF4CAF50),
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            'Dil',
                                            style: AppTypography.bodyLarge.copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.textPrimary,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: isDark
                                              ? AppColors.darkTextLight
                                              : AppColors.textLight,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: AppSpacing.md),

                              // Support Section
                              _buildSettingCard(
                                label: 'İletişim',
                                icon: Icons.mail_outline,
                                isDark: isDark,
                                locale: locale,
                                showLabel: false,
                                child: GestureDetector(
                                  onTap: () {
                                    // TODO: Navigate to support/contact screen
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('İletişim özelliği yakında eklenecek'),
                                        backgroundColor: AppColors.accentPrimary,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                          ? AppColors.darkBgSecondary
                                          : AppColors.lightBgSecondary).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(
                                        color: (isDark ? AppColors.darkTextLight : AppColors.textLight).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2196F3).withOpacity(0.2), // Mavi renk
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                          child: Icon(
                                            Icons.mail_outline,
                                            color: const Color(0xFF2196F3), // Mavi renk
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            'İletişim ve Destek',
                                            style: AppTypography.bodyLarge.copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.textPrimary,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: isDark
                                              ? AppColors.darkTextLight
                                              : AppColors.textLight,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // App Logo at the bottom
                              SizedBox(height: AppSpacing.xl),
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                    border: Border.all(
                                      color: (isDark ? AppColors.darkTextLight : AppColors.textLight).withOpacity(0.1),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // App Logo
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(AppRadius.lg),
                                          image: const DecorationImage(
                                            image: AssetImage('assets/images/app_icon.png'),
                                            fit: BoxFit.contain,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.md),
                                      // App Name
                                      Text(
                                        'Namaz Vakitim',
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: AppSpacing.sm),
                                      // Version
                                      Text(
                                        'v1.0.0',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCitySearch(BuildContext context, PrayerProvider prayerProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CountrySelectionScreen(),
      ),
    );
  }

  Color _getIconColor(IconData icon, bool isDark) {
    switch (icon) {
      case Icons.location_on:
        return Colors.blue; // Konum ikonu mavi
      case Icons.notifications:
        return const Color(0xFFFF6B35); // Akşam güneşi rengi - turuncu/kırmızı
      case Icons.language:
        return const Color(0xFF4CAF50); // Dil ikonu yeşil
      case Icons.palette:
        return const Color(0xFF9C27B0); // Tema ikonu mor
      case Icons.mail_outline:
        return const Color(0xFF2196F3); // İletişim ikonu mavi
      default:
        return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    }
  }

  Widget _buildSettingCard({
    required String label,
    required IconData icon,
    required bool isDark,
    required String locale,
    required Widget child,
    bool showLabel = false,
  }) {
    final iconColor = _getIconColor(icon, isDark);
    
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Icon (only for location)
          if (showLabel) ...[
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // Card Container
          Container(
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary).withOpacity(0.95),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required String locale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accentPrimary : (isDark ? AppColors.darkTextLight : AppColors.textLight),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accentPrimary,
        ),
      ],
    );
  }
}