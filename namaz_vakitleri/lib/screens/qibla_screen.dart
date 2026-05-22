import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../widgets/qibla_compass_widget.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  QiblaTelemetry _telemetry = const QiblaTelemetry();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final locale = settings.language;
        final hasLocation = prayerProvider.currentLocation != null;

        return Scaffold(
          backgroundColor: const Color(0xFFF3EEE5),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5EFE3),
                  Color(0xFFE2D4C0),
                  Color(0xFFEEE8DE),
                ],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Text(
                    AppLocalizations.translate('qibla', locale),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Color(0xFF1E1A16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cihazi duz tut, yavasca kendi etrafinda don ve oku merkezde sabitle.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.black.withOpacity(0.62),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E3A34),
                          Color(0xFF2E5A50),
                          Color(0xFF4B7A6D),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A34).withOpacity(0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF8F3EC),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.24),
                                width: 10,
                              ),
                            ),
                            padding: const EdgeInsets.all(26),
                            child: QiblaCompassWidget(
                              locale: locale,
                              userLocation: prayerProvider.currentLocation,
                              alignmentColor: const Color(0xFFD7B56D),
                              backgroundColor: const Color(0xFFF8F3EC),
                              onTelemetry: (telemetry) {
                                if (!mounted || telemetry == _telemetry) return;
                                setState(() {
                                  _telemetry = telemetry;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _StatusBadge(aligned: _telemetry.isAligned),
                        const SizedBox(height: 14),
                        Text(
                          _headlineForTelemetry(_telemetry),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _detailForTelemetry(_telemetry),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.80),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Kible acisi',
                          value: _telemetry.qiblaBearing != null
                              ? '${_telemetry.qiblaBearing!.round()}°'
                              : '--',
                          icon: Icons.navigation_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MetricCard(
                          label: 'Sapma',
                          value: _telemetry.relativeAngle != null
                              ? '${_telemetry.relativeAngle!.abs().round()}°'
                              : '--',
                          icon: Icons.track_changes_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MetricCard(
                    label: 'Konum durumu',
                    value: hasLocation
                        ? '${prayerProvider.savedCity.isNotEmpty ? prayerProvider.savedCity : 'Hazir'} • ${prayerProvider.currentLocation!.latitude.toStringAsFixed(2)}, ${prayerProvider.currentLocation!.longitude.toStringAsFixed(2)}'
                        : 'Konum bekleniyor',
                    icon: Icons.place_rounded,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.74),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Daha dogru sonuc icin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1A16),
                          ),
                        ),
                        SizedBox(height: 12),
                        _TipLine(text: 'Telefonu metal yuzeylerden ve elektronik cihazlardan uzak tut.'),
                        _TipLine(text: 'Pusula kalibrasyonu icin cihazi sekiz cizerek kisa bir hareketle yeniden dengele.'),
                        _TipLine(text: 'Altin renkli ibre merkeze geldiginde kible yonunu yakalamis olursun.'),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.aligned});

  final bool aligned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: aligned
            ? const Color(0xFFD7B56D).withOpacity(0.24)
            : Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        aligned ? 'Kible hizalandi' : 'Yon araniyor',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF204B43).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF204B43)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.56),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1E1A16),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  const _TipLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.circle,
              size: 8,
              color: Color(0xFF204B43),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF554C43),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _headlineForTelemetry(QiblaTelemetry telemetry) {
  if (!telemetry.hasCompass) return 'Pusula verisi bekleniyor';
  if (telemetry.isAligned) return 'Kible yonu yakalandi';
  if (telemetry.relativeAngle == null) return 'Yon hesaplanamadi';

  return telemetry.relativeAngle! > 0
      ? 'Biraz saga don'
      : 'Biraz sola don';
}

String _detailForTelemetry(QiblaTelemetry telemetry) {
  if (!telemetry.hasLocation) {
    return 'Konum izni olmadan dogru kible acisi hesaplanamaz.';
  }
  if (!telemetry.hasCompass) {
    return 'Cihazindan pusula verisi gelmiyor. Sensoru destekleyen bir cihazda tekrar dene.';
  }
  if (telemetry.isAligned) {
    return 'Telefonu bu hizada tutarak namaz yonunu guvenle takip edebilirsin.';
  }
  final offset = telemetry.relativeAngle?.abs().round();
  if (offset == null) {
    return 'Yon bilgisi guncellenirken kisa bir an bekle.';
  }
  return '$offset derece fark kaldi. Cihazi yavasca dondurmeye devam et.';
}
