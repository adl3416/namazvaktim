import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import 'country_selection_screen.dart';
import 'language_selection_screen.dart';
import 'notification_settings_screen.dart';
import 'support_legal_screen.dart';
import 'theme_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final locale = settings.language;
        final currentCity =
            prayerProvider.savedCity.isNotEmpty ? prayerProvider.savedCity : 'Istanbul';
        final currentCountry = prayerProvider.savedCountry.isNotEmpty
            ? prayerProvider.savedCountry
            : 'Turkey';
        final locationModeText = prayerProvider.useAutomaticLocation
            ? _text(
                locale,
                tr: 'Otomatik konum açık',
                en: 'Automatic location is on',
                ar: 'الموقع التلقائي مفعل',
              )
            : _text(
                locale,
                tr: 'Manuel şehir seçili',
                en: 'Manual city selected',
                ar: 'تم اختيار مدينة يدويًا',
              );

        return Scaffold(
          backgroundColor: const Color(0xFFF6F1E8),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF6F0E6),
                  Color(0xFFE7DCCB),
                  Color(0xFFF9F6F1),
                ],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _SettingsHero(
                    title: AppLocalizations.translate('settings', locale),
                  ),
                  const SizedBox(height: 22),
                  _SettingsTile(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: _text(
                      locale,
                      tr: 'Mevcut konum',
                      en: 'Current location',
                      ar: 'الموقع الحالي',
                    ),
                    subtitle: '$currentCity, $currentCountry • $locationModeText',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CountrySelectionScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFEA580C),
                    title: AppLocalizations.translate('notifications', locale),
                    subtitle: _text(
                      locale,
                      tr: 'Ezan, hatırlatma ve vakit ayarlarını yönet',
                      en: 'Manage adhan, reminders, and prayer time settings',
                      ar: 'أدر الأذان والتذكيرات وإعدادات أوقات الصلاة',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.palette_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    title: AppLocalizations.translate('theme', locale),
                    subtitle: _text(
                      locale,
                      tr: 'Uygulamanın görünüşünü değiştir',
                      en: 'Change the look of the app',
                      ar: 'غيّر مظهر التطبيق',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeSelectionScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF15803D),
                    title: AppLocalizations.translate('language', locale),
                    subtitle:
                        '${_text(locale, tr: 'Şu an', en: 'Current', ar: 'الحالية')}: ${settings.language.toUpperCase()}',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LanguageSelectionScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.info_rounded,
                    iconColor: const Color(0xFF0F766E),
                    title: _text(
                      locale,
                      tr: 'Uygulama hakkında ve destek',
                      en: 'About and support',
                      ar: 'حول التطبيق والدعم',
                    ),
                    subtitle: _text(
                      locale,
                      tr: 'Gizlilik, yasal bilgi ve destek alanı',
                      en: 'Privacy, legal information, and support area',
                      ar: 'الخصوصية والمعلومات القانونية والدعم',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SupportLegalScreen(language: locale),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.82)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/app_icon.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Namaz Vakitim',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E1A16),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _text(
                                  locale,
                                  tr: 'Sürüm 1.0.0',
                                  en: 'Version 1.0.0',
                                  ar: 'الإصدار 1.0.0',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF655B51),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 78),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.82)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA58E69).withOpacity(0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1A16),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF655B51),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                trailing ??
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFF8A7B6A),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withOpacity(0.86)),
        image: const DecorationImage(
          image: AssetImage('assets/images/arkafon.png'),
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.22),
                    Colors.white.withOpacity(0.02),
                    Colors.white.withOpacity(0.08),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1A16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
