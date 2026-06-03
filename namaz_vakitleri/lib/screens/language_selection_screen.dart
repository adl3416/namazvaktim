import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  String _text(
    String locale, {
    required String tr,
    required String en,
    required String ar,
    String? de,
  }) {
    switch (locale) {
      case 'tr':
        return tr;
      case 'de':
        return de ?? en;
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

    const languages = {
      'tr': {'name': 'Türkçe', 'native': 'Türkçe', 'flag': 'TR'},
      'en': {'name': 'English', 'native': 'English', 'flag': 'EN'},
      'ar': {'name': 'العربية', 'native': 'العربية', 'flag': 'AR'},
      'de': {'name': 'Deutsch', 'native': 'Deutsch', 'flag': 'DE'},
    };

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
            tr: 'Dil Seçimi',
            en: 'Language Selection',
            ar: 'اختيار اللغة',
            de: 'Sprachauswahl',
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
                  tr: 'Uygulama Dili',
                  en: 'App Language',
                  ar: 'لغة التطبيق',
                  de: 'App-Sprache',
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
                  de: 'Sprachänderungen werden sofort im gesamten sichtbaren Bereich der App angewendet.',
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
                      child: ListTile(
                        contentPadding: EdgeInsets.all(AppSpacing.md),
                        leading: CircleAvatar(
                          backgroundColor:
                              isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.04),
                          child: Text(
                            langData['flag']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        title: Text(
                          langData['name']!,
                          style: AppTypography.bodyMedium.copyWith(
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          langData['native']!,
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                          ),
                        ),
                        trailing:
                            isSelected
                                ? Icon(
                                  Icons.check_circle,
                                  color:
                                      isDark
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
                                  de: 'Deutsch ausgewählt',
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
      ),
    );
  }
}
