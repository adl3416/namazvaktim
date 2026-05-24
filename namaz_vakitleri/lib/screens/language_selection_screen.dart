import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Color _getTimeBasedScaffoldColor(bool isDark) {
    final now = DateTime.now();
    final hour = now.hour;

    if (isDark) {
      if (hour >= 5 && hour < 11) return const Color(0xFF4A3A4A);
      if (hour >= 11 && hour < 15) return const Color(0xFF4A4A2A);
      if (hour >= 15 && hour < 19) return const Color(0xFF4A2A2A);
      return const Color(0xFF2A2A4A);
    }

    if (hour >= 5 && hour < 11) return const Color(0xFFF8E8E8);
    if (hour >= 11 && hour < 15) return const Color(0xFFFFF8E1);
    if (hour >= 15 && hour < 19) return const Color(0xFFFFE8E1);
    return const Color(0xFFE8E8F8);
  }

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

    const languages = {
      'tr': {'name': 'Türkçe', 'native': 'Türkçe', 'flag': 'TR'},
      'en': {'name': 'English', 'native': 'English', 'flag': 'EN'},
      'ar': {'name': 'العربية', 'native': 'العربية', 'flag': 'AR'},
    };

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
          _text(
            locale,
            tr: 'Dil Seçimi',
            en: 'Language Selection',
            ar: 'اختيار اللغة',
          ),
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
            Text(
              _text(
                locale,
                tr: 'Uygulama Dili',
                en: 'App Language',
                ar: 'لغة التطبيق',
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
                tr: 'Dil değişikliği anında tüm görünür alanlara uygulanır.',
                en: 'Language changes are applied immediately across the app.',
                ar: 'يتم تطبيق تغيير اللغة فورًا على كل الأجزاء الظاهرة في التطبيق.',
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final langCode = languages.keys.elementAt(index);
                  final langData = languages[langCode]!;
                  final isSelected = settings.language == langCode;

                  return Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBgSecondary
                          : AppColors.lightBgSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkAccentPrimary
                                : AppColors.accentPrimary)
                            : (isDark
                                ? AppColors.darkDivider
                                : AppColors.divider),
                        width: isSelected ? 2 : 0.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(AppSpacing.md),
                      leading: CircleAvatar(
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        child: Text(
                          langData['flag']!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(
                        langData['name']!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        langData['native']!,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: isDark
                                  ? AppColors.darkAccentPrimary
                                  : AppColors.accentPrimary,
                            )
                          : null,
                      onTap: () async {
                        await settings.setLanguage(langCode);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _text(
                                langCode,
                                tr: 'Türkçe seçildi',
                                en: 'English selected',
                                ar: 'تم اختيار العربية',
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
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
}
