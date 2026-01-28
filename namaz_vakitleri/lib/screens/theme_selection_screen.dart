import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
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
    final settings = context.watch<AppSettings>();

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tema Seçimi',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Uygulama Teması',
              style: AppTypography.h2.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            Text(
              'Uygulamanın görünümünü istediğiniz gibi özelleştirin.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            // Theme Mode Selection
            Text(
              'Tema Modu',
              style: AppTypography.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Light Mode
            _buildThemeModeOption(
              title: 'Açık Tema',
              subtitle: 'Her zaman açık tema kullan',
              icon: Icons.light_mode,
              isSelected: settings.themeMode == ThemeMode.light,
              onTap: () => settings.setThemeMode(ThemeMode.light),
              isDark: isDark,
            ),

            SizedBox(height: AppSpacing.md),

            // Dark Mode
            _buildThemeModeOption(
              title: 'Koyu Tema',
              subtitle: 'Her zaman koyu tema kullan',
              icon: Icons.dark_mode,
              isSelected: settings.themeMode == ThemeMode.dark,
              onTap: () => settings.setThemeMode(ThemeMode.dark),
              isDark: isDark,
            ),

            SizedBox(height: AppSpacing.md),

            // System Mode
            _buildThemeModeOption(
              title: 'Sistem Teması',
              subtitle: 'Cihaz ayarlarını takip et',
              icon: Icons.settings_system_daydream,
              isSelected: settings.themeMode == ThemeMode.system,
              onTap: () => settings.setThemeMode(ThemeMode.system),
              isDark: isDark,
            ),

            SizedBox(height: AppSpacing.xxxl),

            // Color Palettes Section
            Text(
              'Renk Paletleri',
              style: AppTypography.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            Expanded(
              child: settings.palettes.isEmpty
                  ? Center(
                      child: Text(
                        'Henüz kaydedilmiş palet yok',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: settings.palettes.length,
                      itemBuilder: (context, index) {
                        final paletteName = settings.palettes.keys.elementAt(index);
                        final isActive = settings.activePaletteName == paletteName;

                        return Container(
                          margin: EdgeInsets.only(bottom: AppSpacing.md),
                          padding: EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBgSecondary
                                : AppColors.lightBgSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isActive
                                  ? (isDark
                                      ? AppColors.darkAccentPrimary
                                      : AppColors.accentPrimary)
                                  : (isDark ? AppColors.darkDivider : AppColors.divider),
                              width: isActive ? 2 : 0.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              paletteName,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: isActive
                                ? Text(
                                    'Aktif',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkAccentPrimary
                                          : AppColors.accentPrimary,
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Color preview
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Color(settings.palettes[paletteName]!['sayim'] ?? 0xFFFFE7BF),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                if (!isActive)
                                  IconButton(
                                    icon: Icon(
                                      Icons.check_circle_outline,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                    onPressed: () => settings.applyPalette(paletteName),
                                  ),
                              ],
                            ),
                            onTap: () => settings.applyPalette(paletteName),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkBgSecondary
              : AppColors.lightBgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              size: 24,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark
                    ? AppColors.darkAccentPrimary
                    : AppColors.accentPrimary,
              ),
          ],
        ),
      ),
    );
  }
}