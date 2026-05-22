import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glowShift = math.sin(_controller.value * math.pi * 2);

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF9F3E6),
                    Color(0xFFF4E8CD),
                    Color(0xFFE8D3A0),
                  ],
                  stops: [0.0, 0.62, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -30,
                    child: _GlowOrb(
                      size: 240,
                      color: const Color(0x55D9B35F),
                      offsetY: glowShift * 12,
                    ),
                  ),
                  Positioned(
                    left: -60,
                    bottom: 120,
                    child: _GlowOrb(
                      size: 200,
                      color: const Color(0x33497A73),
                      offsetY: -glowShift * 10,
                    ),
                  ),
                  Positioned(
                    top: 120,
                    left: -30,
                    child: Opacity(
                      opacity: 0.08,
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 180,
                        color: const Color(0xFF2C6A63),
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
                              offset: Offset(0, glowShift * 6),
                              child: _LogoSeal(rotationValue: _controller.value),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Namaz Vakitleri',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF205A54),
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Vakitlerin huzuruyla gune baglanin',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF6B5A3A).withOpacity(0.9),
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
                                alignment: Alignment(
                                  -1 + (_controller.value * 2),
                                  0,
                                ),
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
                              'Konum ve vakit bilgileri hazirlaniyor...',
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LogoSeal extends StatelessWidget {
  const _LogoSeal({required this.rotationValue});

  final double rotationValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotationValue * math.pi * 2,
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x44FFFFFF),
                  width: 1.4,
                ),
              ),
            ),
          ),
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xCCFFFDF6),
                  Color(0xFFF0DFC0),
                ],
              ),
              border: Border.all(
                color: const Color(0x99D7B978),
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30205A54),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
          ),
          ClipOval(
            child: Container(
              width: 124,
              height: 124,
              color: Colors.white.withOpacity(0.52),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.offsetY,
  });

  final double size;
  final Color color;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.18),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
