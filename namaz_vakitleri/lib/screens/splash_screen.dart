import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final locale = context.watch<AppSettings>().language;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final wave = math.sin(_controller.value * math.pi * 2);
            final pulse = (wave + 1) / 2;
            final glow = 0.16 + (pulse * 0.28);
            final drift = math.cos(_controller.value * math.pi * 2) * 22;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [
                    Color(0xFF0C3B53),
                    Color(0xFF0F4A5E),
                    Color(0xFF176078),
                    Color(0xFF2A7A88),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -110 + drift,
                    right: -80,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x66A1E3FF).withOpacity(0.22 + pulse * 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -120 - drift,
                    left: -100,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x66FFE3AA).withOpacity(0.18 + pulse * 0.08),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.14),
                            Colors.transparent,
                            Colors.black.withOpacity(0.20),
                          ],
                          stops: const [0.0, 0.44, 1.0],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(0, wave * 6),
                              child: Container(
                                width: 156,
                                height: 156,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(42),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFF5E2B9),
                                      Color(0xFFEBD3A0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFDDBA78).withOpacity(glow),
                                      blurRadius: 38,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(34),
                                    color: Colors.white.withOpacity(0.84),
                                  ),
                                  child: const Icon(
                                    Icons.mosque_rounded,
                                    color: Color(0xFF195865),
                                    size: 78,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 34),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.22),
                                ),
                              ),
                              child: const Text(
                                'Ezanlar',
                                style: TextStyle(
                                  color: Color(0xFFFFF3D8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _text(
                                locale,
                                tr: 'Ezanlar',
                                en: 'Ezanlar',
                                ar: 'Ezanlar',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _text(
                                locale,
                                tr: 'Namaz vakitleri, ezan bildirimleri ve kıble yönü',
                                en: 'Prayer times, adhan notifications, and qibla direction',
                                ar: 'مواقيت الصلاة وتنبيهات الأذان واتجاه القبلة',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFEAF7FF).withOpacity(0.94),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              width: 232,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.26)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      minHeight: 6,
                                      value: pulse,
                                      backgroundColor: Colors.white.withOpacity(0.26),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFFD98A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _text(
                                      locale,
                                      tr: 'Konum ve vakit bilgileri hazırlanıyor...',
                                      en: 'Preparing location and prayer time data...',
                                      ar: 'جارٍ تجهيز بيانات الموقع ومواقيت الصلاة...',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.94),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
