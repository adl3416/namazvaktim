import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
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
    final settings = context.watch<AppSettings>();

    final languages = {
      'tr': {'name': 'Türkçe', 'native': 'Türkçe', 'flag': '🇹🇷'},
      'en': {'name': 'English', 'native': 'English', 'flag': '🇺🇸'},
      'ar': {'name': 'العربية', 'native': 'العربية', 'flag': '🇸🇦'},
      'de': {'name': 'Deutsch', 'native': 'Deutsch', 'flag': '🇩🇪'},
      'fr': {'name': 'Français', 'native': 'Français', 'flag': '🇫🇷'},
      'es': {'name': 'Español', 'native': 'Español', 'flag': '🇪🇸'},
      'it': {'name': 'Italiano', 'native': 'Italiano', 'flag': '🇮🇹'},
      'pt': {'name': 'Português', 'native': 'Português', 'flag': '🇵🇹'},
      'ru': {'name': 'Русский', 'native': 'Русский', 'flag': '🇷🇺'},
      'zh': {'name': '中文', 'native': '中文', 'flag': '🇨🇳'},
      'ja': {'name': '日本語', 'native': '日本語', 'flag': '🇯🇵'},
      'ko': {'name': '한국어', 'native': '한국어', 'flag': '🇰🇷'},
      'hi': {'name': 'हिन्दी', 'native': 'हिन्दी', 'flag': '🇮🇳'},
      'ur': {'name': 'اردو', 'native': 'اردو', 'flag': '🇵🇰'},
      'fa': {'name': 'فارسی', 'native': 'فارسی', 'flag': '🇮🇷'},
      'nl': {'name': 'Nederlands', 'native': 'Nederlands', 'flag': '🇳🇱'},
      'sv': {'name': 'Svenska', 'native': 'Svenska', 'flag': '🇸🇪'},
      'da': {'name': 'Dansk', 'native': 'Dansk', 'flag': '🇩🇰'},
      'no': {'name': 'Norsk', 'native': 'Norsk', 'flag': '🇳🇴'},
      'fi': {'name': 'Suomi', 'native': 'Suomi', 'flag': '🇫🇮'},
      'pl': {'name': 'Polski', 'native': 'Polski', 'flag': '🇵🇱'},
      'cs': {'name': 'Čeština', 'native': 'Čeština', 'flag': '🇨🇿'},
      'sk': {'name': 'Slovenčina', 'native': 'Slovenčina', 'flag': '🇸🇰'},
      'hu': {'name': 'Magyar', 'native': 'Magyar', 'flag': '🇭🇺'},
      'ro': {'name': 'Română', 'native': 'Română', 'flag': '🇷🇴'},
      'bg': {'name': 'Български', 'native': 'Български', 'flag': '🇧🇬'},
      'hr': {'name': 'Hrvatski', 'native': 'Hrvatski', 'flag': '🇭🇷'},
      'sl': {'name': 'Slovenščina', 'native': 'Slovenščina', 'flag': '🇸🇮'},
      'et': {'name': 'Eesti', 'native': 'Eesti', 'flag': '🇪🇪'},
      'lv': {'name': 'Latviešu', 'native': 'Latviešu', 'flag': '🇱🇻'},
      'lt': {'name': 'Lietuvių', 'native': 'Lietuvių', 'flag': '🇱🇹'},
      'el': {'name': 'Ελληνικά', 'native': 'Ελληνικά', 'flag': '🇬🇷'},
      'he': {'name': 'עברית', 'native': 'עברית', 'flag': '🇮🇱'},
      'th': {'name': 'ไทย', 'native': 'ไทย', 'flag': '🇹🇭'},
      'vi': {'name': 'Tiếng Việt', 'native': 'Tiếng Việt', 'flag': '🇻🇳'},
      'id': {'name': 'Bahasa Indonesia', 'native': 'Bahasa Indonesia', 'flag': '🇮🇩'},
      'ms': {'name': 'Bahasa Melayu', 'native': 'Bahasa Melayu', 'flag': '🇲🇾'},
      'tl': {'name': 'Filipino', 'native': 'Filipino', 'flag': '🇵🇭'},
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
          'Dil Seçimi',
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
              'Uygulama Dili',
              style: AppTypography.h2.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            Text(
              'Uygulamanın dilini seçin. Değişiklikler anında uygulanacaktır.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            // Languages List
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
                            ? (isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary)
                            : (isDark ? AppColors.darkDivider : AppColors.divider),
                        width: isSelected ? 2 : 0.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(AppSpacing.md),
                      leading: Text(
                        langData['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        langData['name']!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                      onTap: () {
                        settings.setLanguage(langCode);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${langData['name']} dili seçildi'),
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