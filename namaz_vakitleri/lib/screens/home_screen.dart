import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Color? _currentBackgroundColor;

  bool _isQiblaExpanded = false;
  late AnimationController _qiblaExpansionController;
  late GlobalKey _qiblaIconKey;

  @override
  void initState() {
    super.initState();
    _qiblaIconKey = GlobalKey();
    
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundColorAnimation = ColorTween().animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _backgroundColorAnimation.addListener(() {
      setState(() {});
    });

    _qiblaExpansionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    _qiblaExpansionController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(String prayerPhase) {
    const colorMap = {
      'imsak_sunrise_noon': Color(0xFFFFF8F0),      // Warm peach
      'noon_afternoon': Color(0xFFF8F5FF),          // Soft lavender
      'afternoon_evening': Color(0xFFFFF5F7),       // Soft rose
      'evening_night': Color(0xFFFFF5F7),           // Soft rose
      'night_fajr': Color(0xFFFFF8F0),              // Warm peach
    };
    return colorMap[prayerPhase] ?? const Color(0xFFFFF8F0);
  }

  String _getCurrentPhase(PrayerProvider prayerProvider) {
    final active = prayerProvider.activePrayer?.name.toLowerCase() ?? '';
    final next = prayerProvider.nextPrayer?.name.toLowerCase() ?? '';

    if (active.contains('fajr') || active.contains('imsak')) {
      if (next.contains('sunrise') || next.contains('gunes')) return 'imsak_sunrise_noon';
      return 'night_fajr';
    }
    if (active.contains('sunrise') || active.contains('gunes')) return 'imsak_sunrise_noon';
    if (active.contains('dhuhr') || active.contains('ogle')) return 'noon_afternoon';
    if (active.contains('asr') || active.contains('ikindi')) return 'afternoon_evening';
    if (active.contains('maghrib') || active.contains('aksam')) return 'evening_night';
    if (active.contains('isha') || active.contains('yatsi')) return 'evening_night';

    return 'imsak_sunrise_noon';
  }

  void _updateBackgroundColor(String phase) {
    final newColor = _getBackgroundColor(phase);
    if (_currentBackgroundColor != newColor) {
      _backgroundColorAnimation = ColorTween(
        begin: _currentBackgroundColor ?? newColor,
        end: newColor,
      ).animate(
        CurvedAnimation(parent: _colorAnimationController, curve: Curves.easeInOut),
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
        final bgColor = _backgroundColorAnimation.value ?? _getBackgroundColor(phase);

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    _buildTopBar(prayerProvider),
                    // Hero Section
                    _buildHeroSection(prayerProvider),
                    // Prayer Times List
                    Expanded(
                      child: _buildPrayerTimesList(prayerProvider),
                    ),
                  ],
                ),
              ),
              // Qibla Overlay
              if (_isQiblaExpanded) _buildQiblaOverlay(context, prayerProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(PrayerProvider prayerProvider) {
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
            icon: const Icon(Icons.settings_outlined, size: 24),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.location_on_outlined, size: 14),
              ],
            ),
          ),
          GestureDetector(
            key: _qiblaIconKey,
            onTap: () {
              setState(() => _isQiblaExpanded = !_isQiblaExpanded);
              if (_isQiblaExpanded) {
                _qiblaExpansionController.forward();
              } else {
                _qiblaExpansionController.reverse();
              }
            },
            child: Icon(
              _isQiblaExpanded ? Icons.close : Icons.explore_outlined,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(PrayerProvider prayerProvider) {
    final nextPrayer = prayerProvider.nextPrayer;
    if (nextPrayer == null) return const SizedBox.shrink();

    final countdown = prayerProvider.countdownDuration;
    final hours = countdown?.inHours ?? 0;
    final minutes = (countdown?.inMinutes ?? 0) % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Text(
            '${_prayerNameTr(nextPrayer.name)} Vaktine',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hours.toString(),
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Text('sa', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 16),
              Text(
                minutes.toString(),
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Text('dk', style: TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList(PrayerProvider prayerProvider) {
    final prayerTimes = prayerProvider.currentPrayerTimes?.prayerTimesList ?? [];
    final activePrayer = prayerProvider.activePrayer;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: prayerTimes.length,
      itemBuilder: (context, index) {
        final prayer = prayerTimes[index];
        final isActive = activePrayer?.name == prayer.name;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: isActive
                ? BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _prayerNameTr(prayer.name),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Text(
                  '${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQiblaOverlay(BuildContext context, PrayerProvider prayerProvider) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() => _isQiblaExpanded = false);
          _qiblaExpansionController.reverse();
        },
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 220,
                height: 220,
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
                  startRotationDelay: const Duration(milliseconds: 300),
                ),
              ),
            ),
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
