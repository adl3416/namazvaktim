import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  static const List<_OnboardingStep> _steps = [
    _OnboardingStep(
      icon: Icons.mosque_rounded,
      title: 'Ezanlar ile gununu duzenle',
      description:
          'Bulundugun sehre gore namaz vakitlerini takip et, gunun ritmini sade ve huzurlu bir ekranda gor.',
      accent: Color(0xFF1F6F8B),
    ),
    _OnboardingStep(
      icon: Icons.notifications_active_rounded,
      title: 'Bildirimlerini kendine gore ayarla',
      description:
          'Her vakit icin bildirim ve ezan sesini ayri ayri acip kapatabilir, hatirlatma dakikalarini belirleyebilirsin.',
      accent: Color(0xFFCB7A2A),
    ),
    _OnboardingStep(
      icon: Icons.place_rounded,
      title: 'Sehrini elle secerek basla',
      description:
          'Ilk kurulumdan sonra ulke ve sehrini sen sececeksin. Camiler bolumu cihaz konumunu kullansa da ana ekran sehrin degismez.',
      accent: Color(0xFF1F4C43),
    ),
  ];

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

  Future<void> _completeOnboarding() async {
    if (_isCompleting) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    await context.read<AppSettings>().setOnboardingCompleted(true);

    if (!mounted) {
      return;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<AppSettings>().language;
    final isLastPage = _currentPage == _steps.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF09121F),
                    Color(0xFF0F1B2C),
                    Color(0xFF14263C),
                  ]
                : const [
                    Color(0xFFE9F4FB),
                    Color(0xFFF8F3EA),
                    Color(0xFFF6FBFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.10)
                              : const Color(0xFFD7E2EC),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mosque_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkAccentPrimary
                                : AppColors.accentPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ezanlar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!isLastPage)
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          _text(
                            locale,
                            tr: 'Gec',
                            en: 'Skip',
                            ar: 'Skip',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _steps.length,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return _OnboardingStepView(
                        step: step,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) {
                    final selected = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: selected ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: selected
                            ? (isDark
                                ? AppColors.darkAccentPrimary
                                : AppColors.accentPrimary)
                            : (isDark
                                ? Colors.white.withOpacity(0.22)
                                : const Color(0xFFC5D3DF)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isCompleting
                        ? null
                        : () async {
                            if (isLastPage) {
                              await _completeOnboarding();
                              return;
                            }

                            await _pageController.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkAccentPrimary
                          : AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isCompleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _text(
                              locale,
                              tr: isLastPage ? 'Baslayalim' : 'Devam et',
                              en: isLastPage ? 'Let\'s begin' : 'Continue',
                              ar: isLastPage ? 'Let\'s begin' : 'Continue',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({
    required this.step,
    required this.isDark,
  });

  final _OnboardingStep step;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Color.lerp(step.accent, Colors.black, 0.55)!,
                        Color.lerp(step.accent, Colors.black, 0.72)!,
                      ]
                    : [
                        Color.lerp(step.accent, Colors.white, 0.82)!,
                        Color.lerp(step.accent, Colors.white, 0.92)!,
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: step.accent.withOpacity(isDark ? 0.18 : 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      step.icon,
                      size: 38,
                      color: step.accent,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : step.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '0${_OnboardingScreenState._steps.indexOf(step) + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : step.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : const Color(0xFF14202B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF425466),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
}
