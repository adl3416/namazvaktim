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
  Color? _targetBackgroundColor;

  // Qibla compass expansion
  bool _isQiblaExpanded = false;
  late AnimationController _qiblaExpansionController;
  late Animation<double> _qiblaExpansionAnimation;
  late Animation<double> _qiblaRotationAnimation;
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

    _backgroundColorAnimation.addListener(() {
      setState(() {});
    });

    // Qibla expansion animations
    _qiblaExpansionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _qiblaExpansionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _qiblaExpansionController,
      curve: Curves.elasticOut,
    ));

    _qiblaRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _qiblaExpansionController,
      curve: Curves.easeInOut,
    ));

    _qiblaExpansionAnimation.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    _qiblaExpansionController.dispose();
    super.dispose();
  }

  // Color states based on prayer time intervals
  Map<String, Color> get _colorStates => {
    // State 1: İmsak → Güneş → Öğle (Warm peach/cream)
    'imsak_gunes_ogle': const Color(0xFFFFF8F0), // Very light warm peach
    'gunes_ogle': const Color(0xFFFFF8F0),
    'yatsi_imsak': const Color(0xFFFFF8F0),

    // State 2: Öğle → İkindi (Soft lavender/periwinkle)
    'ogle_ikindi': const Color(0xFFF8F5FF), // Soft lavender

    // State 3: İkindi → Akşam → Yatsı (Soft rose/blush)
    'ikindi_aksam': const Color(0xFFFFF5F7), // Very soft rose
    'aksam_yatsi': const Color(0xFFFFF5F7),
  };

  String _getCurrentColorState(PrayerProvider prayerProvider) {
    final activePrayer = prayerProvider.activePrayer?.name.toLowerCase() ?? '';
    final nextPrayer = prayerProvider.nextPrayer?.name.toLowerCase() ?? '';

    // State 1: İmsak → Güneş → Öğle
    if ((activePrayer.contains('fajr') || activePrayer.contains('imsak')) &&
        (nextPrayer.contains('sunrise') || nextPrayer.contains('güneş') || nextPrayer.contains('gunes'))) {
      return 'imsak_gunes_ogle';
    }
    if ((activePrayer.contains('sunrise') || activePrayer.contains('güneş') || activePrayer.contains('gunes')) &&
        (nextPrayer.contains('dhuhr') || nextPrayer.contains('öğle') || nextPrayer.contains('ogle'))) {
      return 'gunes_ogle';
    }
    if ((activePrayer.contains('isha') || activePrayer.contains('yatsı') || activePrayer.contains('yatsi')) &&
        (nextPrayer.contains('fajr') || nextPrayer.contains('imsak'))) {
      return 'yatsi_imsak';
    }

    // State 2: Öğle → İkindi
    if ((activePrayer.contains('dhuhr') || activePrayer.contains('öğle') || activePrayer.contains('ogle')) &&
        (nextPrayer.contains('asr') || nextPrayer.contains('ikindi'))) {
      return 'ogle_ikindi';
    }

    // State 3: İkindi → Akşam → Yatsı
    if ((activePrayer.contains('asr') || activePrayer.contains('ikindi')) &&
        (nextPrayer.contains('maghrib') || nextPrayer.contains('akşam') || nextPrayer.contains('aksam'))) {
      return 'ikindi_aksam';
    }
    if ((activePrayer.contains('maghrib') || activePrayer.contains('akşam') || activePrayer.contains('aksam')) &&
        (nextPrayer.contains('isha') || nextPrayer.contains('yatsı') || nextPrayer.contains('yatsi'))) {
      return 'aksam_yatsi';
    }

    // Default to State 1
    return 'imsak_gunes_ogle';
  }

  void _updateBackgroundColor(String colorState) {
    final newColor = _colorStates[colorState] ?? _colorStates['imsak_gunes_ogle']!;

    if (_currentBackgroundColor != newColor) {
      _targetBackgroundColor = newColor;
      _backgroundColorAnimation = ColorTween(
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
        final colorState = _getCurrentColorState(prayerProvider);
        _updateBackgroundColor(colorState);

        final backgroundColor = _backgroundColorAnimation.value ?? _colorStates[colorState]!;

        // Define color palettes based on state
        late Color primaryTextColor;
        late Color secondaryTextColor;
        late Color accentColor;
        late Color activePrayerHighlight;

        switch (colorState) {
          case 'ogle_ikindi': // State 2
            primaryTextColor = const Color(0xFF4C5FD5); // Indigo
            secondaryTextColor = const Color(0xFF8B7FB8); // Desaturated blue-purple
            accentColor = const Color(0xFF6B73D6); // Muted indigo
            activePrayerHighlight = const Color(0xFFE8E6F5); // Slightly darker lavender tint
            break;

          case 'ikindi_aksam': // State 3
          case 'aksam_yatsi': // State 3
            primaryTextColor = const Color(0xFF8B2543); // Deep rose
            secondaryTextColor = const Color(0xFFC48B9F); // Lighter pink-red
            accentColor = const Color(0xFFA0375C); // Muted crimson
            activePrayerHighlight = const Color(0xFFF5E6E8); // Soft rose tint
            break;

          default: // State 1
            primaryTextColor = const Color(0xFF8B4513); // Warm brown
            secondaryTextColor = const Color(0xFFD2B48C); // Lighter peach-brown
            accentColor = const Color(0xFFA0522D); // Soft warm brown
            activePrayerHighlight = const Color(0xFFFFF0E6); // Light peach tint
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Top Row
                    _buildTopRow(settings, prayerProvider, accentColor),

                    // Hero Section
                    _buildHeroSection(prayerProvider, primaryTextColor, secondaryTextColor),

                    // Prayer Times List
                    Expanded(
                      child: _buildPrayerTimesList(
                        prayerProvider,
                        primaryTextColor,
                        secondaryTextColor,
                        accentColor,
                        activePrayerHighlight,
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded Qibla Compass Overlay
              if (_isQiblaExpanded)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isQiblaExpanded = false;
                      });
                      _qiblaExpansionController.reverse();
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.7 * _qiblaExpansionAnimation.value),
                    ),
                  ),
                ),

              if (_isQiblaExpanded)
                AnimatedBuilder(
                  animation: _qiblaExpansionAnimation,
                  builder: (context, child) {
                    final screenSize = MediaQuery.of(context).size;
                    final centerTop = 120.0; // Position in upper area
                    final centerLeft = screenSize.width - 200; // Right side position
                    final RenderBox? box = _qiblaIconKey.currentContext?.findRenderObject() as RenderBox?;
                    double startTop = centerTop;
                    double startLeft = centerLeft;
                    double startSize = 28;
                    if (box != null) {
                      final position = box.localToGlobal(Offset.zero);
                      startTop = position.dy;
                      startLeft = position.dx;
                      startSize = box.size.width;
                    }
                    final currentTop = startTop + (centerTop - startTop) * _qiblaExpansionAnimation.value;
                    final currentLeft = startLeft + (centerLeft - startLeft) * _qiblaExpansionAnimation.value;
                    final currentSize = startSize + (150 - startSize) * _qiblaExpansionAnimation.value;
                    return Positioned(
                      top: currentTop,
                      left: currentLeft,
                      width: currentSize,
                      height: currentSize,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: backgroundColor.withOpacity(0.9),
                            border: Border.all(
                              color: accentColor.withOpacity(0.5),
                              width: 3,
                            ),
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
                            backgroundColor: backgroundColor,
                            alignmentColor: accentColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopRow(AppSettings settings, PrayerProvider prayerProvider, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Settings Icon
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: Icon(
              Icons.settings_outlined,
              color: accentColor,
              size: 28,
            ),
          ),

          // City Name - Clickable for automatic location update
          GestureDetector(
            onTap: () async {
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Konum alınıyor...'),
                  duration: Duration(seconds: 2),
                ),
              );

              try {
                await prayerProvider.refreshLocation();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Konum güncellendi: ${prayerProvider.savedCity}'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Konum alınamadı. İnternet bağlantınızı kontrol edin.'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Row(
              children: [
                Text(
                  prayerProvider.savedCity.isNotEmpty
                      ? prayerProvider.savedCity
                      : 'İstanbul',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.location_on_outlined,
                  color: accentColor.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),

          // Qibla Icon
          GestureDetector(
            key: _qiblaIconKey,
            onTap: () {
              setState(() {
                _isQiblaExpanded = !_isQiblaExpanded;
              });
              if (_isQiblaExpanded) {
                _qiblaExpansionController.forward();
              } else {
                _qiblaExpansionController.reverse();
              }
            },
            child: AnimatedBuilder(
              animation: _qiblaExpansionAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _qiblaRotationAnimation.value,
                  child: Icon(
                    _isQiblaExpanded ? Icons.close : Icons.explore_outlined,
                    color: accentColor,
                    size: 28 + (_qiblaExpansionAnimation.value * 10),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(PrayerProvider prayerProvider, Color primaryTextColor, Color secondaryTextColor) {
    final nextPrayer = prayerProvider.nextPrayer;
    if (nextPrayer == null) {
      return const SizedBox.shrink();
    }

    final countdown = prayerProvider.countdownDuration;
    final hours = countdown?.inHours ?? 0;
    final minutes = (countdown?.inMinutes ?? 0) % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Next Prayer Text
          Text(
            '${_getPrayerNameInTurkish(nextPrayer.name)} Vaktine',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Large Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hours.toString(),
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'sa',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                minutes.toString(),
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'dk',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          // Optional secondary text for Iftar
          if (nextPrayer.name.toLowerCase().contains('maghrib') ||
              nextPrayer.name.toLowerCase().contains('akşam') ||
              nextPrayer.name.toLowerCase().contains('aksam'))
            Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryTextColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'İftar vaktine: ${hours} sa ${minutes} dk',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList(
    PrayerProvider prayerProvider,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color accentColor,
    Color activePrayerHighlight,
  ) {
    final prayerTimes = prayerProvider.currentPrayerTimes?.prayerTimesList ?? [];
    final activePrayer = prayerProvider.activePrayer;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: prayerTimes.length,
      itemBuilder: (context, index) {
        final prayer = prayerTimes[index];
        final isActive = activePrayer?.name == prayer.name;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: isActive
              ? BoxDecoration(
                  color: activePrayerHighlight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getPrayerNameInTurkish(prayer.name),
                style: TextStyle(
                  color: isActive ? primaryTextColor : primaryTextColor.withOpacity(0.6),
                  fontSize: 18,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              Text(
                '${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isActive ? primaryTextColor : primaryTextColor.withOpacity(0.6),
                  fontSize: 18,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPrayerNameInTurkish(String englishName) {
    final name = englishName.toLowerCase();
    if (name.contains('fajr') || name.contains('imsak')) return 'İmsak';
    if (name.contains('sunrise') || name.contains('güneş') || name.contains('gunes')) return 'Güneş';
    if (name.contains('dhuhr') || name.contains('öğle') || name.contains('ogle')) return 'Öğle';
    if (name.contains('asr') || name.contains('ikindi')) return 'İkindi';
    if (name.contains('maghrib') || name.contains('akşam') || name.contains('aksam')) return 'Akşam';
    if (name.contains('isha') || name.contains('yatsı') || name.contains('yatsi')) return 'Yatsı';
    return englishName;
  }
}
