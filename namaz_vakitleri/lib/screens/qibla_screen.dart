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
  bool _vibrationEnabled = true;

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.translate('qibla', locale),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: Color(0xFF1E1A16),
                          ),
                        ),
                      ),
                      Material(
                        color: const Color(0xFF1E3A34).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              _vibrationEnabled = !_vibrationEnabled;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              _vibrationEnabled
                                  ? Icons.vibration_rounded
                                  : Icons.mobile_off_rounded,
                              color: const Color(0xFF1E3A34),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
                        Row(
                          children: [
                            _CompassStatPill(
                              label: 'QIBLA',
                              value: _telemetry.qiblaBearing != null
                                  ? '${_telemetry.qiblaBearing!.round()}°'
                                  : '--',
                            ),
                            const SizedBox(width: 10),
                            _CompassStatPill(
                              label: 'SAPMA',
                              value: _telemetry.relativeAngle != null
                                  ? '${_telemetry.relativeAngle!.abs().round()}°'
                                  : '--',
                              highlighted: _telemetry.isAligned,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AspectRatio(
                          aspectRatio: 1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF8F3EC),
                              border: Border.all(
                                color: _telemetry.isAligned
                                    ? const Color(0xFF34D399)
                                    : Colors.white.withOpacity(0.24),
                                width: _telemetry.isAligned ? 12 : 10,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _telemetry.isAligned
                                      ? const Color(0xFF22C55E).withOpacity(0.38)
                                      : Colors.black.withOpacity(0.10),
                                  blurRadius: _telemetry.isAligned ? 30 : 18,
                                  spreadRadius: _telemetry.isAligned ? 4 : 0,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: QiblaCompassWidget(
                              locale: locale,
                              userLocation: prayerProvider.currentLocation,
                              alignmentColor: const Color(0xFFD7B56D),
                              backgroundColor: const Color(0xFFF8F3EC),
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
                        const SizedBox(height: 14),
                        _StatusBadge(aligned: _telemetry.isAligned),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                  if (!hasLocation) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.76),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.78),
                        ),
                      ),
                      child: const Text(
                        'Konum olmadan kible yonu tam hesaplanamaz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF554C43),
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
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
            ? const Color(0xFF34D399).withOpacity(0.22)
            : Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: aligned
              ? const Color(0xFF6EE7B7).withOpacity(0.55)
              : Colors.white.withOpacity(0.10),
        ),
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

class _CompassStatPill extends StatelessWidget {
  const _CompassStatPill({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFF34D399).withOpacity(0.18)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlighted
                ? const Color(0xFF6EE7B7).withOpacity(0.55)
                : Colors.white.withOpacity(0.14),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.66),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
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
