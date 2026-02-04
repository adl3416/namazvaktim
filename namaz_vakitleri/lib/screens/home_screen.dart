import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../widgets/qibla_compass_widget.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _colorAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  late AnimationController _qiblaExpansionController;
  late Animation<double> _qiblaScaleAnimation;
  late Animation<double> _qiblaRotationAnimation;

  Color? _currentBackgroundColor;
  bool _isQiblaExpanded = false;
  late GlobalKey _qiblaIconKey;

  @override
  void initState() {
    super.initState();
    _qiblaIconKey = GlobalKey();

    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _backgroundColorAnimation = ColorTween().animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _backgroundColorAnimation.addListener(() => setState(() {}));

    // Çiçek gibi açılma animasyonu - daha yavaş
    _qiblaExpansionController = AnimationController(
      duration: const Duration(milliseconds: 1000), // 600'den 1000'e
      vsync: this,
    );

    _qiblaScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _qiblaExpansionController,
        curve: Curves.easeOutBack, // elasticOut'u easeOutBack ile değiştir
      ),
    );

    _qiblaRotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159 * 1.5)
        .animate(
          CurvedAnimation(
            parent: _qiblaExpansionController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    _qiblaExpansionController.dispose();
    super.dispose();
  }

  // Zengin renk paleti - namaz saatleri
  Map<String, Color> get _colorMap => {
    'imsak_sunrise': const Color(0xFFFFF3E0), // Açık portakal
    'sunrise_noon': const Color(0xFFFFF8DC), // Krem
    'noon': const Color(0xFFE8F5E9), // Açık yeşil
    'noon_afternoon': const Color(0xFFF3E5F5), // Lavanta
    'afternoon': const Color(0xFFF3E5F5), // Mor-lavanta
    'afternoon_evening': const Color(0xFFFFF3E0), // Sarı
    'evening': const Color(0xFFFFEBEE), // Pembe
    'evening_night': const Color(0xFFE1F5FE), // Açık mavi
    'night': const Color(0xFFF1F8E9), // Açık yeşil-sarı
  };

  String _getCurrentPhase(PrayerProvider prayerProvider) {
    final active = prayerProvider.activePrayer?.name.toLowerCase() ?? '';
    final next = prayerProvider.nextPrayer?.name.toLowerCase() ?? '';

    if (active.contains('fajr') || active.contains('imsak')) {
      if (next.contains('sunrise') || next.contains('gunes'))
        return 'imsak_sunrise';
      return 'night';
    }
    if (active.contains('sunrise') || active.contains('gunes'))
      return 'sunrise_noon';
    if (active.contains('dhuhr') || active.contains('ogle')) return 'noon';
    if (active.contains('asr') || active.contains('ikindi')) {
      if (next.contains('maghrib') || next.contains('aksam'))
        return 'afternoon_evening';
      return 'afternoon';
    }
    if (active.contains('maghrib') || active.contains('aksam'))
      return 'evening';
    if (active.contains('isha') || active.contains('yatsi'))
      return 'evening_night';

    return 'imsak_sunrise';
  }

  Color _getTextColor(String phase) {
    const textColors = {
      'imsak_sunrise': Color(0xFF5D4037), // Kahverengi
      'sunrise_noon': Color(0xFF1565C0), // Koyu mavi
      'noon': Color(0xFF33691E), // Koyu yeşil
      'noon_afternoon': Color(0xFF4A148C), // Koyu mor
      'afternoon': Color(0xFF4A148C), // Koyu mor
      'afternoon_evening': Color(0xFFE65100), // Koyu portakal
      'evening': Color(0xFFC2185B), // Koyu pembe
      'evening_night': Color(0xFF01579B), // Çok koyu mavi
      'night': Color(0xFF33691E), // Koyu yeşil
    };
    return textColors[phase] ?? const Color(0xFF5D4037);
  }

  void _updateBackgroundColor(String phase) {
    final newColor = _colorMap[phase] ?? _colorMap['imsak_sunrise']!;
    if (_currentBackgroundColor != newColor) {
      _backgroundColorAnimation =
          ColorTween(
            begin: _currentBackgroundColor ?? newColor,
            end: newColor,
          ).animate(
            CurvedAnimation(
              parent: _colorAnimationController,
              curve: Curves.easeInOut,
            ),
          );
      _colorAnimationController.forward(from: 0.0);
      _currentBackgroundColor = newColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final phase = _getCurrentPhase(prayerProvider);
        _updateBackgroundColor(phase);
        final bgColor = _backgroundColorAnimation.value ?? _colorMap[phase]!;
        final textColor = _getTextColor(phase);

        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (didPop) {
              print('🔙 Back button pressed - exiting app');
            }
          },
          child: Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(prayerProvider, textColor),
                      _buildHeroSection(prayerProvider, textColor),
                      Expanded(
                        child: _buildPrayerTimesList(prayerProvider, textColor),
                      ),
                    ],
                  ),
                ),
                // Çiçek gibi açılan kible pusulası overlay
                if (_isQiblaExpanded)
                  _buildQiblaOverlay(context, prayerProvider, bgColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(PrayerProvider prayerProvider, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: Icon(Icons.settings_outlined, color: textColor, size: 24),
          ),
          GestureDetector(
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Konum alınıyor...')),
              );
              try {
                await prayerProvider.refreshLocation();
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Konum: ${prayerProvider.savedCity}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Konum alınamadı'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Row(
              children: [
                Text(
                  prayerProvider.savedCity.isNotEmpty
                      ? prayerProvider.savedCity
                      : 'İstanbul',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.location_on_outlined, size: 14, color: textColor),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([
              _qiblaScaleAnimation,
              _qiblaRotationAnimation,
            ]),
            builder: (context, child) {
              return GestureDetector(
                key: _qiblaIconKey,
                onTap: () {
                  setState(() => _isQiblaExpanded = !_isQiblaExpanded);
                  if (_isQiblaExpanded) {
                    _qiblaExpansionController.forward();
                  } else {
                    _qiblaExpansionController.reverse();
                  }
                },
                child: Transform.rotate(
                  angle: _qiblaRotationAnimation.value,
                  child: Transform.scale(
                    scale: 1.0 + (_qiblaScaleAnimation.value * 0.15),
                    child: Icon(
                      _isQiblaExpanded ? Icons.close : Icons.explore,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(PrayerProvider prayerProvider, Color textColor) {
    final nextPrayer = prayerProvider.nextPrayer;
    if (nextPrayer == null) return const SizedBox.shrink();

    final countdown = prayerProvider.countdownDuration;
    final hours = countdown?.inHours ?? 0;
    final minutes = (countdown?.inMinutes ?? 0) % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Text(
            '${_prayerNameTr(nextPrayer.name)} Vaktine',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hours.toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'sa',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                minutes.toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'dk',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList(PrayerProvider prayerProvider, Color textColor) {
    final prayerTimes =
        prayerProvider.currentPrayerTimes?.prayerTimesList ?? [];
    final activePrayer = prayerProvider.activePrayer;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: prayerTimes.length,
      itemBuilder: (context, index) {
        final prayer = prayerTimes[index];
        final isActive = activePrayer?.name == prayer.name;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: isActive
                ? textColor.withOpacity(0.1)
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: textColor.withOpacity(0.4), width: 2)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: textColor.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _prayerNameTr(prayer.name),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              Text(
                '${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: textColor.withOpacity(isActive ? 1.0 : 0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQiblaOverlay(
    BuildContext context,
    PrayerProvider prayerProvider,
    Color bgColor,
  ) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() => _isQiblaExpanded = false);
          _qiblaExpansionController.reverse();
        },
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _qiblaScaleAnimation,
              _qiblaRotationAnimation,
            ]),
            builder: (context, child) {
              // Çiçek açılması gibi yapraklar
              return Stack(
                children: [
                  // Ana pusula - daha küçük
                  Align(
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: _qiblaScaleAnimation.value,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: QiblaCompassWidget(
                            locale: 'tr',
                            userLocation: prayerProvider.currentLocation,
                            startRotationDelay: const Duration(
                              milliseconds: 200,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _prayerNameTr(String name) {
    final n = name.toLowerCase();
    if (n.contains('fajr') || n.contains('imsak')) return 'İmsak';
    if (n.contains('sunrise') || n.contains('gunes')) return 'Güneş';
    if (n.contains('dhuhr') || n.contains('ogle')) return 'Öğle';
    if (n.contains('asr') || n.contains('ikindi')) return 'İkindi';
    if (n.contains('maghrib') || n.contains('aksam')) return 'Akşam';
    if (n.contains('isha') || n.contains('yatsi')) return 'Yatsı';
    return name;
  }
}
