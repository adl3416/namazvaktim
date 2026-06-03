import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  String _text(
    String locale, {
    required String tr,
    required String en,
    required String ar,
  }) {
    switch (locale) {
      case 'tr':
        return tr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<AppSettings>();
    final locale = settings.language;
    final scaffoldColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _text(
            locale,
            tr: 'Tema Seçimi',
            en: 'Theme Selection',
            ar: 'اختيار المظهر',
          ),
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
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
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _text(
                  locale,
                  tr: 'Uygulama Teması',
                  en: 'App Theme',
                  ar: 'مظهر التطبيق',
                ),
                style: AppTypography.h2.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                _text(
                  locale,
                  tr: 'Uygulamanın görünümünü istediğiniz gibi özelleştirin.',
                  en: 'Customize the app appearance the way you want.',
                  ar: 'خصص مظهر التطبيق بالطريقة التي تريدها.',
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                _text(
                  locale,
                  tr: 'Tema Modu',
                  en: 'Theme Mode',
                  ar: 'وضع المظهر',
                ),
                style: AppTypography.h3.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              _ThemeModeOption(
                title: _text(
                  locale,
                  tr: 'Açık Tema',
                  en: 'Light Theme',
                  ar: 'المظهر الفاتح',
                ),
                subtitle: _text(
                  locale,
                  tr: 'Her zaman açık tema kullan',
                  en: 'Always use the light theme',
                  ar: 'استخدم المظهر الفاتح دائمًا',
                ),
                icon: Icons.light_mode,
                isSelected: settings.themeMode == ThemeMode.light,
                onTap: () => settings.setThemeMode(ThemeMode.light),
                isDark: isDark,
              ),
              SizedBox(height: AppSpacing.md),
              _ThemeModeOption(
                title: _text(
                  locale,
                  tr: 'Koyu Tema',
                  en: 'Dark Theme',
                  ar: 'المظهر الداكن',
                ),
                subtitle: _text(
                  locale,
                  tr: 'Her zaman koyu tema kullan',
                  en: 'Always use the dark theme',
                  ar: 'استخدم المظهر الداكن دائمًا',
                ),
                icon: Icons.dark_mode,
                isSelected: settings.themeMode == ThemeMode.dark,
                onTap: () => settings.setThemeMode(ThemeMode.dark),
                isDark: isDark,
              ),
              SizedBox(height: AppSpacing.md),
              _ThemeModeOption(
                title: _text(
                  locale,
                  tr: 'Sistem Teması',
                  en: 'System Theme',
                  ar: 'مظهر النظام',
                ),
                subtitle: _text(
                  locale,
                  tr: 'Cihaz ayarlarını takip et',
                  en: 'Follow device settings',
                  ar: 'اتبع إعدادات الجهاز',
                ),
                icon: Icons.settings_system_daydream,
                isSelected: settings.themeMode == ThemeMode.system,
                onTap: () => settings.setThemeMode(ThemeMode.system),
                isDark: isDark,
              ),
              SizedBox(height: AppSpacing.xxxl),
              Text(
                _text(
                  locale,
                  tr: 'Renk Paletleri',
                  en: 'Color Palettes',
                  ar: 'لوحات الألوان',
                ),
                style: AppTypography.h3.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Expanded(
                child:
                    settings.palettes.isEmpty
                        ? Center(
                          child: Text(
                            _text(
                              locale,
                              tr: 'Henüz kaydedilmiş palet yok',
                              en: 'No saved palettes yet',
                              ar: 'لا توجد لوحات محفوظة بعد',
                            ),
                            style: AppTypography.bodyMedium.copyWith(
                              color:
                                  isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: settings.palettes.length,
                          itemBuilder: (context, index) {
                            final paletteName =
                                settings.palettes.keys.elementAt(index);
                            final isActive =
                                settings.activePaletteName == paletteName;

                            return _SurfaceCard(
                              isDark: isDark,
                              isSelected: isActive,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  paletteName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color:
                                        isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                    fontWeight:
                                        isActive
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                subtitle:
                                    isActive
                                        ? Text(
                                          _text(
                                            locale,
                                            tr: 'Aktif',
                                            en: 'Active',
                                            ar: 'نشط',
                                          ),
                                          style: AppTypography.bodySmall.copyWith(
                                            color:
                                                isDark
                                                    ? AppColors.darkAccentPrimary
                                                    : AppColors.accentPrimary,
                                          ),
                                        )
                                        : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          settings.palettes[paletteName]!['sayim'] ??
                                              0xFFFFE7BF,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.sm,
                                        ),
                                        border: Border.all(
                                          color:
                                              isDark
                                                  ? AppColors.darkDivider
                                                  : AppColors.divider,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.sm),
                                    if (!isActive)
                                      IconButton(
                                        icon: Icon(
                                          Icons.check_circle_outline,
                                          color:
                                              isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.textSecondary,
                                        ),
                                        onPressed:
                                            () =>
                                                settings.applyPalette(paletteName),
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
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _SurfaceCard(
        isDark: isDark,
        isSelected: isSelected,
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? (isDark
                          ? AppColors.darkAccentPrimary
                          : AppColors.accentPrimary)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
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
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          isDark
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
                color:
                    isDark
                        ? AppColors.darkAccentPrimary
                        : AppColors.accentPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.isDark,
    required this.child,
    this.isSelected = false,
  });

  final bool isDark;
  final bool isSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkBgSecondary.withOpacity(0.92)
                : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color:
              isSelected
                  ? (isDark
                      ? AppColors.darkAccentPrimary
                      : AppColors.accentPrimary)
                  : (isDark
                      ? AppColors.darkDivider.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
