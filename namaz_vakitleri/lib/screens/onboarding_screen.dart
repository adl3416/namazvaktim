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
          'Bulunduğun şehre göre namaz vakitlerini anlık olarak görüntüle, günün ritmini kaçırma.',
      descriptionEn:
          'See prayer times instantly for your city and stay in sync with the day.',
      descriptionAr:
          'اعرض أوقات الصلاة لمدينتك بشكل فوري ولا تفوّت إيقاع يومك.',
      heroType: _HeroType.times,
    ),
    _OnboardingStep(
      number: '02',
      titleTr: 'Bildirimlerini kendine göre ayarla',
      titleEn: 'Tune notifications your way',
      titleAr: 'اضبط التنبيهات كما تريد',
      descriptionTr:
          'Her vakit için bildirim, ezan sesi ve hatırlatma zamanlarını ayrı ayrı yönet.',
      descriptionEn:
          'Manage notifications, adhan sounds, and reminder times for each prayer.',
      descriptionAr:
          'تحكم في التنبيهات وصوت الأذان وأوقات التذكير لكل صلاة.',
      heroType: _HeroType.notifications,
    ),
    _OnboardingStep(
      number: '03',
      titleTr: 'Şehrini seç, kıbleyi ve camileri keşfet',
      titleEn: 'Choose your city and explore more',
      titleAr: 'اختر مدينتك واستكشف المزيد',
      descriptionTr:
          'İlk kurulumdan sonra şehrini seç, kıble yönünü bul ve yakındaki camileri gör.',
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
                    tr: 'Geç',
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
                    tr: isLastPage ? 'Başlayalım' : 'Devam et',
                    en: isLastPage ? 'Let\'s begin' : 'Continue',
                    ar: isLastPage ? 'لنبدأ' : 'متابعة',
                  ),
                  welcomeLabel: _text(
                    locale,
                    tr: 'Huzur veren bir deneyime hoş geldiniz',
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
        Expanded(
          child: Padding(
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
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ezanlar',
                      style: TextStyle(
                        color: Color(0xFF143D36),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale =
            (constraints.maxWidth / 390).clamp(0.86, 1.18).toDouble();
        final heightScale =
            (constraints.maxHeight / 844).clamp(0.76, 1.10).toDouble();
        final compact = constraints.maxHeight < 690 || constraints.maxWidth < 360;
        final veryCompact = constraints.maxHeight < 620;
        final sceneBase = constraints.maxHeight * (compact ? 0.54 : 0.58);
        final topSceneHeight = sceneBase.clamp(320.0, 470.0).toDouble();
        final heroSize = (330.0 * widthScale).clamp(300.0, 420.0).toDouble();
        final cardTop =
            (topSceneHeight - (heroSize * 0.26)).clamp(250.0, 360.0).toDouble();
        final heroTop =
            (topSceneHeight * 0.18).clamp(64.0, 108.0).toDouble();
        final contentHeight = math.max(
          constraints.maxHeight,
          veryCompact
              ? topSceneHeight + 470
              : (compact ? topSceneHeight + 430 : 0.0),
        );
        final cardPaddingTop = (heroSize * (compact ? 0.36 : 0.40))
            .clamp(86.0, 132.0)
            .toDouble();
        final titleFontSize =
            (30.0 * widthScale).clamp(24.0, 34.0).toDouble();
        final descriptionFontSize =
            (17.0 * widthScale).clamp(15.0, 18.0).toDouble();
        final heroScale =
            ((widthScale + heightScale) / 2).clamp(0.92, 1.18).toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: SizedBox(
              height: contentHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: topSceneHeight,
                    child: _TopScene(heroType: step.heroType),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: cardTop,
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
                        padding: EdgeInsets.fromLTRB(
                          26,
                          cardPaddingTop,
                          26,
                          compact ? 20 : 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: (compact ? 48.0 : 54.0) * widthScale,
                              height: (compact ? 48.0 : 54.0) * widthScale,
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
                                style: TextStyle(
                                  color: const Color(0xFFCC8C18),
                                  fontSize: (compact ? 16.0 : 18.0) * widthScale,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            SizedBox(height: (compact ? 20.0 : 28.0) * heightScale),
                            Text(
                              _localizedTitle(),
                              style: TextStyle(
                                color: const Color(0xFF133F38),
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w900,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 58 * widthScale,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0A125),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            SizedBox(height: (compact ? 18.0 : 24.0) * heightScale),
                            Text(
                              _localizedDescription(),
                              style: TextStyle(
                                color: const Color(0xFF6E7786),
                                fontSize: descriptionFontSize,
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
                    top: heroTop,
                    child: Center(
                      child: _HeroShowcase(
                        heroType: step.heroType,
                        scale: heroScale,
                        size: heroSize,
                      ),
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
  const _HeroShowcase({
    required this.heroType,
    this.scale = 1,
    this.size = 350,
  });

  final _HeroType heroType;
  final double scale;
  final double size;

  @override
  Widget build(BuildContext context) {
    final outerCircle = size * 0.83;
    final cardWidth = size * 0.49;
    final center = size / 2;
    final orbitRadius = outerCircle * 0.47;

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: outerCircle,
              height: outerCircle,
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
              final dx = math.cos(angle) * orbitRadius;
              final dy = math.sin(angle) * orbitRadius;
              return Positioned(
                left: center + dx - 2,
                top: center + dy - 12,
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
              top: size * 0.11,
              right: size * 0.15,
              child: Icon(
                Icons.nightlight_round,
                color: const Color(0xFFE5A722),
                size: size * 0.18,
              ),
            ),
            Positioned(
              bottom: size * 0.09,
              right: size * 0.14,
              child: Icon(
                Icons.mosque_rounded,
                color: const Color(0xFFD9991A),
                size: size * 0.26,
              ),
            ),
            Container(
              width: cardWidth,
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
            SizedBox(height: 6),
            _HeroPrayerRow(icon: Icons.nightlight_round, label: 'Imsak', time: '03:41'),
            _HeroPrayerRow(icon: Icons.wb_sunny_rounded, label: 'Gunes', time: '05:09'),
            _HeroPrayerRow(icon: Icons.light_mode_outlined, label: 'Ogle', time: '13:39'),
            _HeroPrayerRow(icon: Icons.wb_twilight_outlined, label: 'Ikindi', time: '17:09'),
          ],
        );
      case _HeroType.notifications:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset(
                'assets/images/icon3.jpg',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ezanlar',
              style: TextStyle(
                color: Color(0xFF143D36),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const _HeroMiniBadge(label: 'Bildirimlerini kolayca yonet'),
          ],
        );
      case _HeroType.explore:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _HeroCardHeader(title: 'Kesfet'),
            SizedBox(height: 8),
            _HeroExploreRow(icon: Icons.explore_rounded, label: 'Kible hazir'),
            _HeroExploreRow(icon: Icons.mosque_rounded, label: '12 cami'),
            _HeroExploreRow(icon: Icons.location_city_rounded, label: 'Sehir kayitli'),
            SizedBox(height: 8),
            _HeroMiniBadge(label: 'Hizli erisim'),
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
        const Icon(Icons.chevron_left_rounded, color: Color(0xFFB28118), size: 18),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFB28118),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB28118), size: 18),
      ],
    );
  }
}

class _HeroPrayerRow extends StatelessWidget {
  const _HeroPrayerRow({
    required this.icon,
    required this.label,
    required this.time,
  });

  final IconData icon;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF4E565B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF263238),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCompactTile extends StatelessWidget {
  const _HeroCompactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF5DE) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? const Color(0xFFF2D596) : const Color(0xFFF0E6CF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFFE2A62D),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF233137),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? const Color(0xFFB28118) : const Color(0xFF8B94A0),
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE2A62D), size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF233137),
                fontSize: 10.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8ECD2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFB28118),
          fontSize: 10,
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
    final widthScale =
        (MediaQuery.of(context).size.width / 390).clamp(0.88, 1.08).toDouble();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (index) {
            final active = index == currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.symmetric(horizontal: 5 * widthScale),
              width: active ? 30 * widthScale : 12 * widthScale,
              height: 12 * widthScale,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE4A62D)
                    : const Color(0xFFD9D4C7),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        SizedBox(height: 16 * widthScale),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            welcomeLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFE2A62D),
              fontSize: 16 * widthScale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: 18 * widthScale),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE9A82B),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20 * widthScale),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28 * widthScale),
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
                        style: TextStyle(
                          fontSize: 18 * widthScale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 14 * widthScale),
                      Icon(Icons.arrow_forward_rounded, size: 30 * widthScale),
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
