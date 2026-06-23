import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      number: '01',
      titleTr: 'Namaz vakitlerini kolayca takip et',
      titleEn: 'Track prayer times with ease',
      titleAr: 'تابع أوقات الصلاة بسهولة',
      descriptionTr:
          'Bulundugun sehre gore namaz vakitlerini anlik olarak goruntule, gunun ritmini kacirma.',
      descriptionEn:
          'See prayer times instantly for your city and stay in sync with the day.',
      descriptionAr:
          'اعرض أوقات الصلاة لمدينتك بشكل فوري ولا تفوّت إيقاع يومك.',
      heroType: _HeroType.times,
    ),
    _OnboardingStep(
      number: '02',
      titleTr: 'Bildirimlerini kendine gore ayarla',
      titleEn: 'Tune notifications your way',
      titleAr: 'اضبط التنبيهات كما تريد',
      descriptionTr:
          'Her vakit icin bildirim, ezan sesi ve hatirlatma zamanlarini ayri ayri yonet.',
      descriptionEn:
          'Manage notifications, adhan sounds, and reminder times for each prayer.',
      descriptionAr:
          'تحكم في التنبيهات وصوت الأذان وأوقات التذكير لكل صلاة.',
      heroType: _HeroType.notifications,
    ),
    _OnboardingStep(
      number: '03',
      titleTr: 'Sehrini sec, kibleyi ve camileri kesfet',
      titleEn: 'Choose your city and explore more',
      titleAr: 'اختر مدينتك واستكشف المزيد',
      descriptionTr:
          'Ilk kurulumdan sonra sehrini sec, kible yonunu bul ve yakindaki camileri gor.',
      descriptionEn:
          'Pick your city, find the qibla direction, and discover nearby mosques.',
      descriptionAr:
          'اختر مدينتك، واعثر على اتجاه القبلة، واستكشف المساجد القريبة.',
      heroType: _HeroType.explore,
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
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    await context.read<AppSettings>().setOnboardingCompleted(true);

    if (!mounted) return;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().language;
    final isLastPage = _currentPage == _steps.length - 1;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF3),
              Color(0xFFFFF2D7),
              Color(0xFFFFF8EE),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              children: [
                _OnboardingHeader(
                  locale: locale,
                  onSkip: isLastPage ? null : _completeOnboarding,
                  skipLabel: _text(
                    locale,
                    tr: 'Gec',
                    en: 'Skip',
                    ar: 'تخطي',
                  ),
                ),
                const SizedBox(height: 14),
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
                      return _OnboardingSlide(
                        step: step,
                        locale: locale,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _OnboardingFooter(
                  currentPage: _currentPage,
                  pageCount: _steps.length,
                  buttonLabel: _text(
                    locale,
                    tr: isLastPage ? 'Baslayalim' : 'Devam et',
                    en: isLastPage ? 'Let\'s begin' : 'Continue',
                    ar: isLastPage ? 'لنبدأ' : 'متابعة',
                  ),
                  welcomeLabel: _text(
                    locale,
                    tr: 'Huzur veren bir deneyime hos geldiniz',
                    en: 'Welcome to a calming experience',
                    ar: 'مرحبًا بك في تجربة تبعث على السكينة',
                  ),
                  isLoading: _isCompleting,
                  onPressed: _isCompleting
                      ? null
                      : () async {
                          if (isLastPage) {
                            await _completeOnboarding();
                            return;
                          }

                          await _pageController.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.locale,
    required this.onSkip,
    required this.skipLabel,
  });

  final String locale;
  final VoidCallback? onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/icon3.jpg',
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Ezanlar',
                style: TextStyle(
                  color: Color(0xFF143D36),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (onSkip != null)
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD28B13),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(skipLabel),
          ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.step,
    required this.locale,
  });

  final _OnboardingStep step;
  final String locale;

  String _localizedTitle() {
    switch (locale) {
      case 'tr':
        return step.titleTr;
      case 'ar':
        return step.titleAr;
      default:
        return step.titleEn;
    }
  }

  String _localizedDescription() {
    switch (locale) {
      case 'tr':
        return step.descriptionTr;
      case 'ar':
        return step.descriptionAr;
      default:
        return step.descriptionEn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 360,
          child: _TopScene(heroType: step.heroType),
        ),
        Positioned(
          left: 10,
          right: 10,
          top: 292,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withOpacity(0.92)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE4C370).withOpacity(0.16),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 86, 26, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF8ECD2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE0C17A).withOpacity(0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      step.number,
                      style: const TextStyle(
                        color: Color(0xFFCC8C18),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _localizedTitle(),
                    style: const TextStyle(
                      color: Color(0xFF133F38),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 58,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0A125),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _localizedDescription(),
                    style: const TextStyle(
                      color: Color(0xFF6E7786),
                      fontSize: 17,
                      height: 1.58,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 118,
          child: Center(
            child: _HeroShowcase(heroType: step.heroType),
          ),
        ),
      ],
    );
  }
}

class _TopScene extends StatelessWidget {
  const _TopScene({required this.heroType});

  final _HeroType heroType;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(42),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFBF4),
                  Color(0xFFFFF0CC),
                  Color(0xFFFFD36B),
                  Color(0x15FFFFFF),
                ],
                stops: [0.0, 0.55, 0.88, 1.0],
              ),
            ),
          ),
          CustomPaint(
            painter: _OnboardingScenePainter(
              accent: heroType == _HeroType.notifications
                  ? const Color(0xFFE2A62D)
                  : const Color(0xFFF0B241),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroShowcase extends StatelessWidget {
  const _HeroShowcase({required this.heroType});

  final _HeroType heroType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 350,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 290,
            height: 290,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE6AE33),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD99C1F).withOpacity(0.12),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          ...List.generate(12, (index) {
            final angle = (math.pi * 2 / 12) * index;
            final dx = math.cos(angle) * 136;
            final dy = math.sin(angle) * 136;
            return Positioned(
              left: 175 + dx - 2,
              top: 175 + dy - 12,
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: 4,
                  height: index.isEven ? 18 : 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECC97F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
          Positioned(
            top: 38,
            right: 54,
            child: Icon(
              Icons.nightlight_round,
              color: const Color(0xFFE5A722),
              size: 62,
            ),
          ),
          Positioned(
            bottom: 30,
            right: 48,
            child: Icon(
              Icons.mosque_rounded,
              color: const Color(0xFFD9991A),
              size: 90,
            ),
          ),
          Container(
            width: 170,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE2BC72).withOpacity(0.36),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: _HeroInnerCard(heroType: heroType),
          ),
        ],
      ),
    );
  }
}

class _HeroInnerCard extends StatelessWidget {
  const _HeroInnerCard({required this.heroType});

  final _HeroType heroType;

  @override
  Widget build(BuildContext context) {
    switch (heroType) {
      case _HeroType.times:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _HeroCardHeader(title: 'Bugun'),
            SizedBox(height: 10),
            _HeroPrayerRow(icon: Icons.nightlight_round, label: 'Imsak', time: '03:41'),
            _HeroPrayerRow(
              icon: Icons.wb_sunny_rounded,
              label: 'Gunes',
              time: '05:09',
              active: true,
            ),
            _HeroPrayerRow(icon: Icons.light_mode_outlined, label: 'Ogle', time: '13:39'),
            _HeroPrayerRow(icon: Icons.wb_twilight_outlined, label: 'Ikindi', time: '17:09'),
            _HeroPrayerRow(icon: Icons.brightness_4_outlined, label: 'Aksam', time: '20:01'),
            _HeroPrayerRow(icon: Icons.dark_mode_outlined, label: 'Yatsi', time: '21:31'),
          ],
        );
      case _HeroType.notifications:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _HeroCardHeader(title: 'Hatirlatmalar'),
            SizedBox(height: 12),
            _HeroToggleRow(label: 'Sabah bildirimi', time: '20 dk once', enabled: true),
            _HeroToggleRow(label: 'Ogle ezani', time: 'Vaktinde', enabled: true),
            _HeroToggleRow(label: 'Aksam hatirlatma', time: '10 dk once', enabled: false),
            SizedBox(height: 8),
            _HeroMiniBadge(label: 'Sessiz gunler ve ozel ayarlar'),
          ],
        );
      case _HeroType.explore:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _HeroCardHeader(title: 'Kesfet'),
            SizedBox(height: 12),
            _HeroExploreRow(icon: Icons.explore_rounded, label: 'Kible yonu hazir'),
            _HeroExploreRow(icon: Icons.mosque_rounded, label: 'Yakinda 12 cami'),
            _HeroExploreRow(icon: Icons.location_city_rounded, label: 'Sehrin kaydedildi'),
            SizedBox(height: 8),
            _HeroMiniBadge(label: 'Konumuna gore hizli erisim'),
          ],
        );
    }
  }
}

class _HeroCardHeader extends StatelessWidget {
  const _HeroCardHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.chevron_left_rounded, color: Color(0xFFB28118)),
        const Icon(Icons.chevron_left_rounded, color: Color(0xFFB28118), size: 20),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFB28118),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB28118), size: 20),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB28118)),
      ],
    );
  }
}

class _HeroPrayerRow extends StatelessWidget {
  const _HeroPrayerRow({
    required this.icon,
    required this.label,
    required this.time,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String time;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFF5DE) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? const Color(0xFFE2A62D) : const Color(0xFF4E565B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF263238),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (active)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFE2A62D),
                shape: BoxShape.circle,
              ),
            ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroToggleRow extends StatelessWidget {
  const _HeroToggleRow({
    required this.label,
    required this.time,
    required this.enabled,
  });

  final String label;
  final String time;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0E6CF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF233137),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF8B94A0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 34,
            height: 20,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFE2A62D) : const Color(0xFFD7DDE3),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroExploreRow extends StatelessWidget {
  const _HeroExploreRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE2A62D), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF233137),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMiniBadge extends StatelessWidget {
  const _HeroMiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8ECD2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFB28118),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.currentPage,
    required this.pageCount,
    required this.buttonLabel,
    required this.welcomeLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final int currentPage;
  final int pageCount;
  final String buttonLabel;
  final String welcomeLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (index) {
            final active = index == currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: active ? 30 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE4A62D)
                    : const Color(0xFFD9D4C7),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          welcomeLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE2A62D),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE9A82B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.arrow_forward_rounded, size: 30),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingScenePainter extends CustomPainter {
  const _OnboardingScenePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0x66FFF2C2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.44),
      34,
      glowPaint,
    );

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = accent.withOpacity(0.18)
      ..strokeWidth = 1.4;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.60),
      size.width * 0.32,
      orbitPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.60),
      size.width * 0.24,
      orbitPaint..color = accent.withOpacity(0.12),
    );

    final starPaint = Paint()..color = Colors.white.withOpacity(0.95);
    for (final point in <Offset>[
      Offset(size.width * 0.08, size.height * 0.25),
      Offset(size.width * 0.14, size.height * 0.42),
      Offset(size.width * 0.86, size.height * 0.24),
      Offset(size.width * 0.92, size.height * 0.46),
    ]) {
      canvas.drawCircle(point, 2, starPaint);
    }

    final skylinePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x55B57C13),
          Color(0x11B57C13),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.30, size.width, size.height * 0.50));

    final mosquePath = Path()
      ..moveTo(0, size.height * 0.74)
      ..lineTo(size.width * 0.04, size.height * 0.48)
      ..lineTo(size.width * 0.05, size.height * 0.74)
      ..lineTo(size.width * 0.13, size.height * 0.56)
      ..lineTo(size.width * 0.15, size.height * 0.74)
      ..lineTo(size.width * 0.18, size.height * 0.74)
      ..lineTo(size.width * 0.19, size.height * 0.44)
      ..lineTo(size.width * 0.21, size.height * 0.74)
      ..lineTo(size.width * 0.29, size.height * 0.74)
      ..lineTo(size.width * 0.31, size.height * 0.40)
      ..lineTo(size.width * 0.33, size.height * 0.74)
      ..lineTo(size.width * 0.41, size.height * 0.74)
      ..lineTo(size.width * 0.42, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.74)
      ..lineTo(size.width * 0.56, size.height * 0.74)
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.72,
        size.width * 0.86,
        size.height * 0.74,
      )
      ..lineTo(size.width * 0.96, size.height * 0.54)
      ..lineTo(size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mosquePath, skylinePaint);

    final bridgePaint = Paint()
      ..color = accent.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final bridge = Path()
      ..moveTo(size.width * 0.58, size.height * 0.67)
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.58,
        size.width * 0.94,
        size.height * 0.67,
      );
    canvas.drawPath(bridge, bridgePaint);
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.61),
      Offset(size.width * 0.64, size.height * 0.70),
      bridgePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.92, size.height * 0.56),
      Offset(size.width * 0.92, size.height * 0.70),
      bridgePaint,
    );

    final birdPaint = Paint()
      ..color = accent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    void bird(double x, double y, double scale) {
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + (10 * scale), y - (6 * scale), x + (20 * scale), y)
        ..moveTo(x + (20 * scale), y)
        ..quadraticBezierTo(x + (30 * scale), y - (6 * scale), x + (40 * scale), y);
      canvas.drawPath(path, birdPaint);
    }

    bird(size.width * 0.68, size.height * 0.38, 0.9);
    bird(size.width * 0.80, size.height * 0.42, 1.0);
    bird(size.width * 0.34, size.height * 0.52, 0.6);
  }

  @override
  bool shouldRepaint(covariant _OnboardingScenePainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.number,
    required this.titleTr,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.heroType,
  });

  final String number;
  final String titleTr;
  final String titleEn;
  final String titleAr;
  final String descriptionTr;
  final String descriptionEn;
  final String descriptionAr;
  final _HeroType heroType;
}

enum _HeroType { times, notifications, explore }
