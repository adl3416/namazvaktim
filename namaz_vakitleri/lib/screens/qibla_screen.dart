import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../widgets/qibla_compass_widget.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  QiblaTelemetry _telemetry = const QiblaTelemetry();
  bool _vibrationEnabled = true;

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
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final locale = settings.language;
        final location = prayerProvider.currentLocation;
        final city = prayerProvider.savedLocationLabel.isNotEmpty
            ? prayerProvider.savedLocationLabel
            : (prayerProvider.currentLocation?.city ??
                _text(
                  locale,
                  tr: 'Konum bekleniyor',
                  en: 'Waiting for location',
                  ar: 'بانتظار الموقع',
                ));

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF6F1E8),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [
                                Color(0xFF172033),
                                Color(0xFF111827),
                                Color(0xFF1E293B),
                              ]
                            : const [
                                Color(0xFFFBF8F2),
                                Color(0xFFF2E9DA),
                                Color(0xFFF7F1E6),
                              ],
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFE5D8C2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.24 : 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _TopActionButton(
                              icon: Icons.place_rounded,
                              active: true,
                              isDark: isDark,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _text(
                                      locale,
                                      tr: 'KIBLE PUSULASI',
                                      en: 'QIBLA COMPASS',
                                      ar: 'بوصلة القبلة',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : const Color(0xFF8C7140),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _text(
                                      locale,
                                      tr: 'Kıbleye yönelin',
                                      en: 'Face the Qibla',
                                      ar: 'اتجه نحو القبلة',
                                    ),
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextLight
                                          : const Color(0xFF7B6A53),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _TopActionButton(
                              icon: _vibrationEnabled
                                  ? Icons.vibration_rounded
                                  : Icons.mobile_off_rounded,
                              active: _vibrationEnabled,
                              isDark: isDark,
                              onTap: () {
                                setState(() {
                                  _vibrationEnabled = !_vibrationEnabled;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SideInfoCard(
                          icon: Icons.location_on_rounded,
                          title: _text(
                            locale,
                            tr: 'Konumunuz',
                            en: 'Your location',
                            ar: 'موقعك',
                          ),
                          value: city,
                          isDark: isDark,
                          lightStyle: true,
                          multiline: true,
                          trailingIcon: Icons.gps_fixed_rounded,
                        ),
                        const SizedBox(height: 18),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: QiblaCompassWidget(
                              locale: locale,
                              userLocation: location,
                              alignmentColor: const Color(0xFFE0B86D),
                              backgroundColor:
                                  isDark ? const Color(0xFF071018) : const Color(0xFF0B141B),
                              vibrationEnabled: _vibrationEnabled,
                              onTelemetry: (telemetry) {
                                if (!mounted || telemetry == _telemetry) return;
                                setState(() {
                                  _telemetry = telemetry;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _StatusBadge(
                          aligned: _telemetry.isAligned,
                          isDark: isDark,
                          alignedLabel: _text(
                            locale,
                            tr: 'Kıble hizalandı',
                            en: 'Qibla aligned',
                            ar: 'تمت محاذاة القبلة',
                          ),
                          searchingLabel: _headlineForTelemetry(locale, _telemetry),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _BottomStat(
                                isDark: isDark,
                                label: _text(
                                  locale,
                                  tr: 'Kıble Yönü',
                                  en: 'Qibla Bearing',
                                  ar: 'اتجاه القبلة',
                                ),
                                value: _telemetry.qiblaBearing == null
                                    ? '--'
                                    : '${_telemetry.qiblaBearing!.round()}°',
                              ),
                            ),
                            Expanded(
                              child: _BottomStat(
                                isDark: isDark,
                                label: _text(
                                  locale,
                                  tr: 'Enlem',
                                  en: 'Latitude',
                                  ar: 'خط العرض',
                                ),
                                value: location == null
                                    ? '--'
                                    : '${location.latitude.toStringAsFixed(4)}°',
                              ),
                            ),
                            Expanded(
                              child: _BottomStat(
                                isDark: isDark,
                                label: _text(
                                  locale,
                                  tr: 'Boylam',
                                  en: 'Longitude',
                                  ar: 'خط الطول',
                                ),
                                value: location == null
                                    ? '--'
                                    : '${location.longitude.toStringAsFixed(4)}°',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: isDark
                                ? AppColors.darkBgSecondary.withOpacity(0.92)
                                : Colors.white.withOpacity(0.80),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFE4D7C2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFC89B53).withOpacity(0.12),
                                  border: Border.all(
                                    color: const Color(0xFFC89B53).withOpacity(0.30),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFFE1BF84),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _text(
                                    locale,
                                    tr: 'Kıble; nerede olursan ol, yönün aynı olsun.',
                                    en: 'Wherever you are, let your direction remain the same.',
                                    ar: 'أينما كنت، فلتبق وجهتك واحدة.',
                                  ),
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF4B3D2B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
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

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    required this.isDark,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? AppColors.darkBgSecondary.withOpacity(0.92)
          : const Color(0xFFFFFBF5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (active
                      ? const Color(0xFFE1BF84)
                      : const Color(0xFFE0D2BA))
                  .withOpacity(isDark ? 0.22 : 0.45),
            ),
          ),
          child: Icon(
            icon,
            color: active
                ? const Color(0xFFC89B53)
                : isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF8A7758),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SideInfoCard extends StatelessWidget {
  const _SideInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
    this.emphasized = false,
    this.lightStyle = false,
    this.multiline = false,
    this.trailingIcon,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isDark;
  final bool emphasized;
  final bool lightStyle;
  final bool multiline;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBgSecondary.withOpacity(0.92)
            : lightStyle
                ? const Color(0xFFF7F1E7)
                : Colors.white.withOpacity(0.66),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? emphasized
                  ? const Color(0xFF4ADE80).withOpacity(0.34)
                  : Colors.white.withOpacity(0.08)
              : lightStyle
                  ? const Color(0xFFE2D2BC)
                  : emphasized
                      ? const Color(0xFF4ADE80).withOpacity(0.34)
                      : const Color(0xFFE8DCC8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? emphasized
                      ? const Color(0xFF14532D).withOpacity(0.42)
                      : const Color(0xFFE1BF84).withOpacity(0.12)
                  : lightStyle
                      ? const Color(0xFFC89B53).withOpacity(0.12)
                      : emphasized
                          ? const Color(0xFF14532D).withOpacity(0.42)
                          : const Color(0xFFE1BF84).withOpacity(0.12),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? emphasized
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFE1BF84)
                  : lightStyle
                      ? const Color(0xFFB28A4B)
                      : emphasized
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFE1BF84),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: multiline
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextLight
                              : lightStyle
                                  ? const Color(0xFF6E5C45)
                                  : const Color(0xFF8D775C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? emphasized
                                  ? const Color(0xFF86EFAC)
                                  : AppColors.darkTextPrimary
                              : lightStyle
                                  ? const Color(0xFF1E1A16)
                                  : emphasized
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF1E1A16),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '$title  $value',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? emphasized
                              ? const Color(0xFF86EFAC)
                              : AppColors.darkTextPrimary
                          : lightStyle
                              ? const Color(0xFF1E1A16)
                              : emphasized
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF1E1A16),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(
              trailingIcon,
              size: 20,
              color: isDark
                  ? AppColors.darkTextLight
                  : const Color(0xFF8C7453),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.aligned,
    required this.isDark,
    required this.alignedLabel,
    required this.searchingLabel,
  });

  final bool aligned;
  final bool isDark;
  final String alignedLabel;
  final String searchingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: aligned
            ? const Color(0xFF14532D).withOpacity(0.42)
            : isDark
                ? AppColors.darkBgSecondary.withOpacity(0.92)
                : Colors.white.withOpacity(0.74),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: aligned
              ? const Color(0xFF6EE7B7).withOpacity(0.55)
              : isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2D4BE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            aligned ? Icons.check_circle_rounded : Icons.explore_rounded,
            size: 18,
            color: aligned ? const Color(0xFF86EFAC) : const Color(0xFFE1BF84),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              aligned ? alignedLabel : searchingLabel,
              style: TextStyle(
                color: aligned
                    ? const Color(0xFF86EFAC)
                    : isDark
                        ? AppColors.darkTextPrimary
                        : const Color(0xFF2B241B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomStat extends StatelessWidget {
  const _BottomStat({
    required this.isDark,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextLight
                  : const Color(0xFF8A775B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF2A2218),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

String _headlineForTelemetry(String locale, QiblaTelemetry telemetry) {
  if (!telemetry.hasCompass) {
    switch (locale) {
      case 'tr':
        return 'Pusula verisi bekleniyor';
      case 'ar':
        return 'بانتظار بيانات البوصلة';
      default:
        return 'Waiting for compass data';
    }
  }
  if (telemetry.relativeAngle == null) {
    switch (locale) {
      case 'tr':
        return 'Yön hesaplanamadı';
      case 'ar':
        return 'تعذر حساب الاتجاه';
      default:
        return 'Direction unavailable';
    }
  }
  if (telemetry.relativeAngle! > 0) {
    switch (locale) {
      case 'tr':
        return 'Biraz sağa dön';
      case 'ar':
        return 'استدر قليلاً إلى اليمين';
      default:
        return 'Turn slightly right';
    }
  }
  switch (locale) {
    case 'tr':
      return 'Biraz sola dön';
    case 'ar':
      return 'استدر قليلاً إلى اليسار';
    default:
      return 'Turn slightly left';
  }
}
