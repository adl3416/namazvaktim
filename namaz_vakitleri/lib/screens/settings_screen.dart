import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/color_system.dart';
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

  String _backgroundAssetForPrayer(String? prayerName) {
    final normalized = (prayerName ?? '').toLowerCase();

    if (normalized.contains('sunrise') || normalized.contains('gunes')) {
      return 'assets/images/gunes_bg.png';
    }
    if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
      return 'assets/images/ogle_bg.png';
    }
    if (normalized.contains('asr') || normalized.contains('ikindi')) {
      return 'assets/images/ikindi_bg.png';
    }
    if (normalized.contains('maghrib') || normalized.contains('aksam')) {
      return 'assets/images/aksam_bg.png';
    }
    if (normalized.contains('isha') || normalized.contains('yatsi')) {
      return 'assets/images/yatsi_bg.png';
    }
    return 'assets/images/imsak_bg.png';
  }

  String _text(
    String language, {
    required String tr,
    required String en,
    required String ar,
    String? de,
  }) {
    switch (language) {
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

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.vakit.app.ezanlar',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareApp(String locale) async {
    const url =
        'https://play.google.com/store/apps/details?id=com.vakit.app.ezanlar';
    final message = _text(
      locale,
      tr:
          'Ezanlar uygulamasını dene. Namaz vakitleri, kıble ve yakındaki camiler tek yerde.\n$url',
      en:
          'Try the Ezanlar app. Prayer times, qibla, and nearby mosques in one place.\n$url',
      ar:
          'جرّب تطبيق Ezanlar. مواقيت الصلاة والقبلة والمساجد القريبة في مكان واحد.\n$url',
      de:
          'Probier die Ezanlar-App aus. Gebetszeiten, Qibla und Moscheen in der Nähe an einem Ort.\n$url',
    );
    await Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final locale = settings.language;
        final bottomSafeSpace = MediaQuery.of(context).padding.bottom + 112;
        final heroPrayerName =
            prayerProvider.activePrayer?.name ?? prayerProvider.nextPrayer?.name;
        final currentCity =
            prayerProvider.savedLocationLabel.isNotEmpty
                ? prayerProvider.savedLocationLabel
                : _text(
                  locale,
                  tr: 'Seçilmedi',
                  en: 'Not selected',
                  ar: 'غير محدد',
                );
        final currentCountry =
            prayerProvider.savedCountry.isNotEmpty
                ? prayerProvider.savedCountry
                : _text(
                  locale,
                  tr: 'Seçilmedi',
                  en: 'Not selected',
                  ar: 'غير محدد',
                );
        final locationModeText =
            prayerProvider.useAutomaticLocation
                ? _text(
                  locale,
                  tr: 'Otomatik konum açık',
                  en: 'Automatic location is on',
                  ar: 'الموقع التلقائي مفعّل',
                )
                : _text(
                  locale,
                  tr: 'Manuel şehir seçili',
                  en: 'Manual city selected',
                  ar: 'تم اختيار مدينة يدويًا',
                );

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF6F1E8),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    isDark
                        ? const [
                          Color(0xFF0F172A),
                          Color(0xFF111827),
                          Color(0xFF172033),
                        ]
                        : const [
                          Color(0xFFF6F0E6),
                          Color(0xFFE7DCCB),
                          Color(0xFFF9F6F1),
                        ],
              ),
            ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, bottomSafeSpace),
                  children: [
                  _SettingsHero(
                    title: AppLocalizations.translate('settings', locale),
                    isDark: isDark,
                    backgroundAsset: _backgroundAssetForPrayer(heroPrayerName),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                  _SettingsTile(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: _text(
                      locale,
                      tr: 'Mevcut konum',
                      en: 'Current location',
                      ar: 'الموقع الحالي',
                    ),
                    subtitle:
                        '$currentCity, $currentCountry • $locationModeText',
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
                          builder:
                              (context) => const NotificationSettingsScreen(),
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
                          builder: (context) => const LanguageSelectionScreen(),
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
                          builder: (context) => SupportLegalScreen(language: locale),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: _text(
                      locale,
                      tr: 'Uygulamayı değerlendir',
                      en: 'Rate the app',
                      ar: 'قيّم التطبيق',
                      de: 'App bewerten',
                    ),
                    subtitle: _text(
                      locale,
                      tr: 'Play Store üzerinden puan ver ve yorum bırak',
                      en: 'Rate the app and leave a review on Play Store',
                      ar: 'قيّم التطبيق واترك مراجعة على متجر Play',
                      de: 'Bewerte die App und hinterlasse eine Rezension im Play Store',
                    ),
                    onTap: _openPlayStore,
                  ),
                  _SettingsTile(
                    icon: Icons.share_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: _text(
                      locale,
                      tr: 'Uygulamayı paylaş',
                      en: 'Share the app',
                      ar: 'شارك التطبيق',
                      de: 'App teilen',
                    ),
                    subtitle: _text(
                      locale,
                      tr: 'Uygulama bağlantısını başkalarıyla gönder',
                      en: 'Send the app link to others',
                      ar: 'أرسل رابط التطبيق إلى الآخرين',
                      de: 'Sende den App-Link an andere weiter',
                    ),
                    onTap: () => _shareApp(locale),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.10)
                            : Colors.black.withOpacity(0.08),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ezanlar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF1E1A16),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _text(
                            locale,
                            tr: 'Sürüm 1.0.0',
                            en: 'Version 1.0.0',
                            ar: 'الإصدار 1.0.0',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF655B51),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color:
            isDark
                ? AppColors.darkBgSecondary.withOpacity(0.92)
                : Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.82),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.20 : 0.08),
                  blurRadius: 13,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF1E1A16),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF655B51),
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color:
                      isDark
                          ? AppColors.darkTextLight
                          : const Color(0xFF8A7B6A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtonCard extends StatelessWidget {
  const _ActionButtonCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color:
          isDark
              ? AppColors.darkBgSecondary.withOpacity(0.92)
              : Colors.white.withOpacity(0.86),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.82),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF1E1A16),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.title,
    required this.isDark,
    required this.backgroundAsset,
  });

  final String title;
  final bool isDark;
  final String backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkBgSecondary.withOpacity(0.92)
                : Colors.white.withOpacity(0.72),
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.black).withOpacity(
                      isDark ? 0.34 : 0.08,
                    ),
                    (isDark ? Colors.black : Colors.black).withOpacity(
                      isDark ? 0.10 : 0.01,
                    ),
                    (isDark ? Colors.black : Colors.black).withOpacity(
                      isDark ? 0.16 : 0.04,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF1E1A16),
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
