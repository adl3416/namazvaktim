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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final wave = math.sin(_controller.value * math.pi * 2);
            final glow = 0.18 + ((wave + 1) / 2) * 0.16;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8F1DF),
                    Color(0xFFF3E4C1),
                    Color(0xFFE8D1A0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(0, wave * 6),
                          child: Container(
                            width: 126,
                            height: 126,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2C6A63),
                                  Color(0xFF205A54),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF205A54)
                                      .withOpacity(glow),
                                  blurRadius: 34,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mosque_rounded,
                              color: Color(0xFFF7E4B0),
                              size: 58,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _text(
                            locale,
                            tr: 'Namaz Vakitleri',
                            en: 'Prayer Times',
                            ar: 'مواقيت الصلاة',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF205A54),
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _text(
                            locale,
                            tr: 'Vakitlerin huzuruyla güne bağlanın',
                            en: 'Start your day with the peace of prayer times',
                            ar: 'ابدأ يومك بسكينة مواقيت الصلاة',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF6B5A3A).withOpacity(0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Container(
                          width: 180,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0x33205A54),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Align(
                            alignment: Alignment(-1 + (_controller.value * 2), 0),
                            child: Container(
                              width: 92,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2C6A63),
                                    Color(0xFFE0B455),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _text(
                            locale,
                            tr: 'Konum ve vakit bilgileri hazırlanıyor...',
                            en: 'Preparing location and prayer time data...',
                            ar: 'جارٍ تجهيز بيانات الموقع ومواقيت الصلاة...',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF7C6B4D).withOpacity(0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
