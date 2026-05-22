import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:namaz_vakitleri/providers/prayer_provider.dart';
import 'package:namaz_vakitleri/services/notification_service.dart';

import '../config/localization.dart';
import '../providers/app_settings.dart';
import 'country_selection_screen.dart';
import 'language_selection_screen.dart';
import 'notification_settings_screen.dart';
import 'theme_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
        final locationName =
            prayerProvider.currentLocation?.city ??
                _text(locale, tr: 'Konum secilmedi', en: 'Location not selected', ar: 'لم يتم تحديد الموقع');

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
                  Text(
                    AppLocalizations.translate('settings', locale),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Color(0xFF1E1A16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _text(
                      locale,
                      tr: 'Diyanet tarzi yardimci ayarlar ile uygulamani konum, bildirim ve tema bazinda hizlica sekillendir.',
                      en: 'Shape the app quickly with helper settings for location, notifications, and theme.',
                      ar: 'خصص التطبيق بسرعة عبر إعدادات الموقع والإشعارات والمظهر.',
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.black.withOpacity(0.60),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SettingsHeroCard(
                    locationName: locationName,
                    language: settings.language.toUpperCase(),
                  ),
                  const SizedBox(height: 18),
                  _SettingsTile(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: AppLocalizations.translate('location', locale),
                    subtitle: locationName,
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
                    subtitle: _text(locale, tr: 'Ezan, hatirlatma ve vakit ayarlarini yonet', en: 'Manage adhan, reminders, and prayer time settings', ar: 'أدر الأذان والتذكيرات وإعدادات أوقات الصلاة'),
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
                    subtitle: _text(locale, tr: 'Uygulamanin gorunusunu degistir', en: 'Change the look of the app', ar: 'غيّر مظهر التطبيق'),
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
                    subtitle: '${_text(locale, tr: 'Su an', en: 'Current', ar: 'الحالية')}: ${settings.language.toUpperCase()}',
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
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFF0891B2),
                    title: _text(locale, tr: 'Test bildirimi', en: 'Test notification', ar: 'إشعار تجريبي'),
                    subtitle: _text(locale, tr: 'Aninda test gondererek sistemi kontrol et', en: 'Verify the system with an instant test', ar: 'تحقق من النظام عبر اختبار فوري'),
                    trailing: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF0891B2),
                    ),
                    onTap: () async {
                      await NotificationService.initialize();
                      await NotificationService.showTestNotification();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_text(locale, tr: 'Test bildirimi gonderildi', en: 'Test notification sent', ar: 'تم إرسال الإشعار التجريبي')),
                          backgroundColor: Color(0xFF15803D),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFFB45309),
                    title: _text(locale, tr: 'Iletisim ve destek', en: 'Contact and support', ar: 'التواصل والدعم'),
                    subtitle: _text(locale, tr: 'Geri bildirim ve yardim bolumu', en: 'Feedback and help section', ar: 'قسم الملاحظات والمساعدة'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_text(locale, tr: 'Destek bolumu yakinda eklenecek', en: 'Support section will be added soon', ar: 'سيتم إضافة قسم الدعم قريباً')),
                          backgroundColor: Color(0xFF1F4C43),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.76),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.80)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/app_icon.png'),
                              fit: BoxFit.contain,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Namaz Vakitim',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E1A16),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'v1.0.0 • daha temiz, daha modern ibadet deneyimi',
                                style: TextStyle(
                                  color: Color(0xFF655B51),
                                  height: 1.4,
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

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.locationName,
    required this.language,
  });

  final String locationName;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3E3128),
            Color(0xFF655040),
            Color(0xFF8D745E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3E3128).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Hazir profil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Uygulamayi kendine gore ayarla',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Konum: $locationName\nDil: $language',
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              height: 1.5,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1A16),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF655B51),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing ??
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
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
