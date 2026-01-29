import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakitleri/config/color_system.dart';
import 'package:namaz_vakitleri/config/localization.dart';
import 'package:namaz_vakitleri/providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/qibla_compass_widget.dart';
import '../services/notification_service.dart';
import 'settings_screen.dart';
import 'country_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final locale = settings.language;
        final isRTL = AppLocalizations.isRTL(locale);

        // Choose home background based on current active prayer (fallback to next prayer)
        final currentPrayerName =
            prayerProvider.activePrayer?.name ??
            prayerProvider.nextPrayer?.name;
        final Color computedBg = currentPrayerName != null
            ? AppColors.getPrayerTimeBackground(currentPrayerName, isDark)
            : AppColors.getBackground(isDark);

        // If user has an active preset, use it; otherwise use computed
        final paletteMap = settings.activePaletteMapping;
        Color? paletteColor;
        // If current time is between öğle and ikindi, prefer the öğle/ikindi yellow tone
        try {
          final now = DateTime.now();
          final times = prayerProvider.currentPrayerTimes?.prayerTimesList;
          if (times != null && times.isNotEmpty) {
            DateTime? ogleTime;
            DateTime? ikindiTime;
            for (var t in times) {
              final n = t.name.toLowerCase();
              if (n.contains('dhuhr') ||
                  n.contains('ogle') ||
                  n.contains('öğle') ||
                  n.contains('zuhr'))
                ogleTime = t.time;
              if (n.contains('asr') ||
                  n.contains('ikindi') ||
                  n.contains('asir'))
                ikindiTime = t.time;
            }
            if (ogleTime != null && ikindiTime != null) {
              DateTime s = ogleTime;
              DateTime e = ikindiTime;
              if (e.isBefore(s)) e = e.add(const Duration(days: 1));
              if (now.isAfter(s) && now.isBefore(e)) {
                // apply ikindi tone (or blended); prefer palette if available
                if (paletteMap != null) {
                  final v = paletteMap['ikindi'] ?? paletteMap['ogle'];
                  if (v != null) paletteColor = Color(v);
                }
                paletteColor ??= AppColors.getPrayerTimeBackground(
                  'ikindi',
                  Theme.of(context).brightness == Brightness.dark,
                );
              }
            }
          }
        } catch (_) {}
        if (paletteMap != null && currentPrayerName != null) {
          // map prayer name to palette key
          String key = currentPrayerName.toLowerCase();
          if (key.contains('fajr') ||
              key.contains('imsak') ||
              key.contains('sabah'))
            key = 'imsak';
          else if (key.contains('sunrise') ||
              key.contains('gunes') ||
              key.contains('güneş'))
            key = 'gunes';
          else if (key.contains('dhuhr') ||
              key.contains('ogle') ||
              key.contains('öğle') ||
              key.contains('zuhr'))
            key = 'ogle';
          else if (key.contains('asr') ||
              key.contains('ikindi') ||
              key.contains('asir'))
            key = 'ikindi';
          else if (key.contains('maghrib') ||
              key.contains('aksam') ||
              key.contains('akşam') ||
              key.contains('magrib'))
            key = 'aksam';
          else if (key.contains('isha') ||
              key.contains('yatsı') ||
              key.contains('yatsi') ||
              key.contains('esha'))
            key = 'yatsi';
          else
            key = 'sayim';

          final val = paletteMap[key];
          if (val != null) paletteColor = Color(val);
        }

        final homeBackground = paletteColor ?? computedBg;

        // Debug: Print current background color
        print('🖌️ === ANA SAYFA RENK DEBUG ===');
        print('🖌️ Current Prayer Name (raw): $currentPrayerName');
        print('🖌️ Active Prayer: ${prayerProvider.activePrayer?.name}');
        print('🖌️ Next Prayer: ${prayerProvider.nextPrayer?.name}');
        print('🖌️ Active Prayer Time: ${prayerProvider.activePrayer?.time}');
        print('🖌️ Next Prayer Time: ${prayerProvider.nextPrayer?.time}');
        print('🖌️ Current Time: ${DateTime.now()}');
        print('🖌️ Is Dark Mode: $isDark');
        print('🖌️ Home Background Color: ${homeBackground.toString()}');
        print('🖌️ RGB: (${homeBackground.red}, ${homeBackground.green}, ${homeBackground.blue})');
        print('🖌️ Hex: #${homeBackground.value.toRadixString(16).padLeft(8, '0').toUpperCase()}');
        print('🖌️ Active Palette: ${settings.activePaletteName}');
        print('🖌️ Palette Override: ${paletteColor != null ? 'EVET' : 'HAYIR'}');
        if (paletteColor != null) {
          print('🖌️ Palette Color: ${paletteColor.toString()}');
        }
        print('🖌️ Computed BG: ${computedBg.toString()}');
        print('🖌️ === DEBUG SON ===');

        // Apply dynamic base color globally so AppColors getters reflect current vakit
        AppColors.setDynamicBase(homeBackground);
        // Foreground accent: ensure good contrast in dark mode; otherwise base on background luminance
        final foregroundAccent = isDark
            ? AppColors.darkTextPrimary
            : (homeBackground.computeLuminance() > 0.5
                  ? AppColors.accentPrimary
                  : AppColors.textPrimary);

        // Compute whether now is between öğle and ikindi
        bool isBetweenOgleAndIkindi = false;
        Color? ogleIkindiBaseColor;
        try {
          final now = DateTime.now();
          final times = prayerProvider.currentPrayerTimes?.prayerTimesList;
          if (times != null && times.isNotEmpty) {
            DateTime? ogleTime;
            DateTime? ikindiTime;
            for (var t in times) {
              final n = t.name.toLowerCase();
              if (n.contains('dhuhr') ||
                  n.contains('ogle') ||
                  n.contains('öğle') ||
                  n.contains('zuhr'))
                ogleTime = t.time;
              if (n.contains('asr') ||
                  n.contains('ikindi') ||
                  n.contains('asir'))
                ikindiTime = t.time;
            }
            if (ogleTime != null && ikindiTime != null) {
              DateTime s = ogleTime;
              DateTime e = ikindiTime;
              if (e.isBefore(s)) e = e.add(const Duration(days: 1));
              if (now.isAfter(s) && now.isBefore(e)) {
                isBetweenOgleAndIkindi = true;
                ogleIkindiBaseColor = AppColors.ogleBase; // Sabit ana renk
              }
            }
          }
        } catch (_) {}

        // Compute whether now is between güneş and öğle
        bool isBetweenGunesAndOgle = false;
        try {
          final now = DateTime.now();
          final times = prayerProvider.currentPrayerTimes?.prayerTimesList;
          if (times != null && times.isNotEmpty) {
            DateTime? gunesTime;
            DateTime? ogleTime2;
            for (var t in times) {
              final n = t.name.toLowerCase();
              if (n.contains('sunrise') ||
                  n.contains('gunes') ||
                  n.contains('güneş'))
                gunesTime = t.time;
              if (n.contains('dhuhr') ||
                  n.contains('ogle') ||
                  n.contains('öğle') ||
                  n.contains('zuhr'))
                ogleTime2 = t.time;
            }
            if (gunesTime != null && ogleTime2 != null) {
              DateTime s = gunesTime;
              DateTime e = ogleTime2;
              if (e.isBefore(s)) e = e.add(const Duration(days: 1));
              if (now.isAfter(s) && now.isBefore(e))
                isBetweenGunesAndOgle = true;
            }
          }
        } catch (_) {}

        // Her aralıkta sadece ana rengin tonları kullanılacak
        Color mainBaseColor = computedBg;
        if (isBetweenOgleAndIkindi) mainBaseColor = AppColors.ogleBase;
        // Diğer aralıklar için de benzer şekilde ana renk atanabilir
        final bottomBarBackground = mainBaseColor;

        // Seed provided default palettes if missing (names: 'kirmizi','buz','turuncu')
        if (!settings.palettes.containsKey('buz')) {
          Future.microtask(() {
            settings.savePaletteIfNotExists('buz', {
              'sayim': AppColors.gunesBase.value, // Turuncu - güneş rengi
              'imsak': AppColors.imsakBase.value, // Açık mavi
              'gunes': AppColors.gunesBase.value, // Turuncu - güneş rengi
              'ogle': AppColors.ogleBase.value,   // Altın sarısı
              'ikindi': AppColors.ikindiBase.value, // Koyu turuncu
              'aksam': AppColors.aksamBase.value,   // Kırmızı-turuncu
              'yatsi': AppColors.yatsiBase.value,   // Royal blue
            });
          });
        }

        if (!settings.palettes.containsKey('kirmizi')) {
          Future.microtask(() {
            settings.savePaletteIfNotExists('kirmizi', {
              'sayim': AppColors.sayimBase.value,
              'imsak': AppColors.imsakBase.value,
              'gunes': AppColors.gunesBase.value,
              'ogle': AppColors.ogleBase.value,
              'ikindi': AppColors.ikindiBase.value,
              'aksam': AppColors.aksamBase.value,
              'yatsi': AppColors.yatsiBase.value,
            });
          });
        }

        if (!settings.palettes.containsKey('turuncu')) {
          Future.microtask(() {
            settings.savePaletteIfNotExists('turuncu', {
              'sayim': 0xFFFFF3E0,
              'imsak': 0xFFFFE0B2,
              'gunes': 0xFFFFCC80,
              'ogle': 0xFFF57C00,
              'ikindi': 0xFFE65100,
              'aksam': 0xFFBF360C,
              'yatsi': 0xFF5D4037,
            });
          });
        }

        // 🎨 Günün zamanına göre ana scaffold rengi belirleme
        final gradientColors = _getGradientColors(isDark);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
            child: Directionality(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                children: [
                  _buildTopBar(
                    context,
                    settings,
                    prayerProvider,
                    isDark,
                    locale,
                    homeBackground,
                  ),

                  // Main Content - Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          children: [
                            // Loading State
                            if (prayerProvider.isLoading)
                              Center(
                                child: Column(
                                  children: [
                                    SizedBox(height: AppSpacing.huge),
                                    const CircularProgressIndicator(),
                                    SizedBox(height: AppSpacing.lg),
                                    Text(
                                      AppLocalizations.translate(
                                        'loading',
                                        locale,
                                      ),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.xxxl),
                                  ],
                                ),
                              ),

                            // Error State
                            if (prayerProvider.errorMessage.isNotEmpty &&
                                !prayerProvider.isLoading)
                              Center(
                                child: Column(
                                  children: [
                                    SizedBox(height: AppSpacing.xxxl),
                                    Icon(
                                      Icons.error_outline,
                                      color: isDark
                                          ? AppColors.darkAccentSecondary
                                          : AppColors.accentSecondary,
                                      size: 48,
                                    ),
                                    SizedBox(height: AppSpacing.lg),
                                    Text(
                                      'Hata',
                                      style: AppTypography.h3.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.md),
                                    Text(
                                      prayerProvider.errorMessage,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.xl),
                                    SoftButton(
                                      label: 'Tekrar Dene',
                                      onPressed: () {
                                        prayerProvider.fetchPrayerTimes();
                                      },
                                      locale: locale,
                                    ),
                                    SizedBox(height: AppSpacing.xxxl),
                                  ],
                                ),
                              ),

                            // Countdown Section
                            if (prayerProvider.nextPrayer != null &&
                                !prayerProvider.isLoading &&
                                prayerProvider.errorMessage.isEmpty)
                              _buildCountdownSection(
                                context,
                                prayerProvider,
                                settings,
                                isDark,
                                locale,
                                homeBackground,
                              ),

                            SizedBox(height: AppSpacing.xxxl),

                            // Prayer Times List
                            if (prayerProvider.currentPrayerTimes != null &&
                                !prayerProvider.isLoading &&
                                prayerProvider.errorMessage.isEmpty)
                              _buildPrayerTimesList(
                                context,
                                prayerProvider,
                                isDark,
                                locale,
                                baseColor: gradientColors[0],
                                useSameHue: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Settings button moved to top right
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppSettings settings,
    PrayerProvider prayerProvider,
    bool isDark,
    String locale,
    Color homeBackground,
  ) {
    final isRTL = AppLocalizations.isRTL(locale);

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        // transparent so top bar appears as part of the gradient/background
        color: Colors.transparent,
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Settings and Location Refresh
            Row(
              children: [
                SoftIconButton(
                  icon: Icons.settings_outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                SizedBox(width: AppSpacing.sm),
                SoftIconButton(
                  icon: Icons.notifications_off,
                  onPressed: () async {
                    await NotificationService.cancelAllNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tüm bildirimler durduruldu!'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                SizedBox(width: AppSpacing.sm),
                SoftIconButton(
                  icon: Icons.my_location,
                  onPressed: () async {
                    await _refreshCurrentLocation(prayerProvider);
                  },
                ),
              ],
            ),

            // Location/City - Clickable
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _showCitySearch(context, prayerProvider);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBgSecondary
                          : AppColors.lightBgSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Text(
                            prayerProvider.savedCity.isEmpty
                                ? AppLocalizations.translate(
                                    'search_city',
                                    locale,
                                  )
                                : prayerProvider.savedCity,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Qibla Compass (shared element hero)
            Hero(
              tag: 'qiblaHero',
              child: Material(
                type: MaterialType.transparency,
                child: SoftIconButton(
                  icon: Icons.explore_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        transitionDuration: const Duration(milliseconds: 700),
                        reverseTransitionDuration: const Duration(
                          milliseconds: 700,
                        ),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return QiblaFullScreen(
                            locale: locale,
                            userLocation: Provider.of<PrayerProvider>(
                              context,
                              listen: false,
                            ).currentLocation,
                          );
                        },
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              // No extra transition; hero handles the motion
                              return child;
                            },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownSection(
    BuildContext context,
    PrayerProvider prayerProvider,
    AppSettings settings,
    bool isDark,
    String locale,
    Color homeBackground,
  ) {
    final nextPrayer = prayerProvider.nextPrayer;
    if (nextPrayer == null) return SizedBox.shrink();

    return Column(
      children: [
        Container(
          constraints: BoxConstraints(minHeight: 120),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocalizations.translate(nextPrayer.name.toLowerCase(), locale)} ${AppLocalizations.translate('prayer_time_label', locale)}',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              CountdownDisplay(
                countdown: prayerProvider.countdownDuration,
                locale: locale,
                accentColor: homeBackground.computeLuminance() > 0.5
                    ? AppColors.accentPrimary
                    : AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerTimesList(
    BuildContext context,
    PrayerProvider prayerProvider,
    bool isDark,
    String locale, {
    required Color baseColor,
    required bool useSameHue,
  }) {
    final prayers = prayerProvider.currentPrayerTimes?.prayerTimesList ?? [];
    Color mapPrayerToColor(String name) {
      final n = name.toLowerCase();
      if (useSameHue) {
        // generate tonal variants of baseColor from lightest (sayim) to darker (ogle)
        double t = 0.5; // default
        if (n.contains('sayim'))
          t = 0.85;
        else if (n.contains('fajr') ||
            n.contains('sabah') ||
            n.contains('imsak'))
          t = 0.7;
        else if (n.contains('sunrise') ||
            n.contains('gunes') ||
            n.contains('güneş'))
          t = 0.45;
        else if (n.contains('dhuhr') ||
            n.contains('ogle') ||
            n.contains('öğle') ||
            n.contains('zuhr'))
          t = 0.2;
        else if (n.contains('asr') || n.contains('ikindi'))
          t = 0.0;
        else if (n.contains('maghrib') || n.contains('akşam'))
          t = 0.0;
        else if (n.contains('isha') || n.contains('yatsı'))
          t = 0.0;

        // lerp towards white for lighter tones; clamp between 0..1
        t = t.clamp(0.0, 1.0);
        return Color.lerp(baseColor, Colors.white, t) ?? baseColor;
      }

      // Fallback: original palette mapping
      if (n.contains('fajr') || n.contains('sabah') || n.contains('imsak'))
        return isDark ? AppColors.darkAccentPrimary : AppColors.accentSecondary;
      if (n.contains('dhuhr') || n.contains('öğle'))
        return isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary;
      if (n.contains('asr') || n.contains('ikindi'))
        return isDark
            ? AppColors.darkAccentSecondary
            : AppColors.accentSecondary;
      if (n.contains('maghrib') || n.contains('akşam'))
        return isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary;
      if (n.contains('isha') || n.contains('yatsı'))
        return isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary;
      return isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary;
    }

    return Column(
      children: [
        for (var i = 0; i < prayers.length; i++) ...[
          (() {
            final prayer = prayers[i];
            final next = i + 1 < prayers.length ? prayers[i + 1] : null;
            final timeStr =
                '${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')}';

            final currColor = mapPrayerToColor(prayer.name);
            final nextColor = next != null
                ? mapPrayerToColor(next.name)
                : currColor;

            return Padding(
              padding: EdgeInsets.only(bottom: 0),
              child: Column(
                children: [
                  PrayerTimeRow(
                    prayerName: AppLocalizations.translate(prayer.name, locale),
                    prayerTime: timeStr,
                    prayerDateTime: prayer.time,
                    isActive: prayer.isActive,
                    locale: locale,
                    overrideBaseColor: baseColor,
                    useSameHue: useSameHue,
                  ),
                  if (next != null)
                    Container(
                      height: 0,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            currColor.withOpacity(0.3),
                            nextColor.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(0.5),
                      ),
                    ),
                ],
              ),
            );
          }()),
        ],
      ],
    );
  }

  void _showCitySearch(BuildContext context, PrayerProvider prayerProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CountrySelectionScreen(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String locale) {
    // Calculate homeBackground like in build method
    final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
    final settings = Provider.of<AppSettings>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate current prayer name for background
    String currentPrayerName = '';
    try {
      final now = DateTime.now();
      final times = prayerProvider.currentPrayerTimes?.prayerTimesList;
      if (times != null && times.isNotEmpty) {
        for (var t in times) {
          if (t.isActive) {
            currentPrayerName = t.name;
            break;
          }
        }
      }
    } catch (_) {}

    // Get computed background
    final computedBg = _getTimeBasedScaffoldColor(isDark);

    // Check for palette override
    Color? paletteColor;
    if (settings.activePaletteName != null) {
      final paletteMap = settings.activePaletteMapping;
      if (paletteMap != null) {
        String key = currentPrayerName.toLowerCase();
        if (key.contains('fajr') || key.contains('imsak'))
          key = 'imsak';
        else if (key.contains('sunrise') || key.contains('gunes'))
          key = 'gunes';
        else if (key.contains('dhuhr') || key.contains('ogle'))
          key = 'ogle';
        else if (key.contains('asr') || key.contains('ikindi'))
          key = 'ikindi';
        else if (key.contains('maghrib') || key.contains('aksam'))
          key = 'aksam';
        else if (key.contains('isha') || key.contains('yatsi'))
          key = 'yatsi';
        else
          key = 'sayim';

        final val = paletteMap[key];
        if (val != null) paletteColor = Color(val);
      }
    }

    final homeBackground = paletteColor ?? computedBg;

    // For Qibla button - show compass
    print('🧭 Qibla button tapped!');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBg
                : AppColors.lightBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.accentPrimary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColors.accentPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  // Import qibla compass widget
                  _buildQiblaCompass(context, locale, homeBackground),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQiblaCompass(BuildContext context, String locale, Color homeBackground) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compass
            _buildCompassUI(context, locale, homeBackground),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassUI(BuildContext context, String locale, Color homeBackground) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRTL = AppLocalizations.isRTL(locale);

    return Column(
      children: [
        // Animated compass circle
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  homeBackground.withOpacity(0.2),
                  homeBackground.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: homeBackground.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cardinal directions
                Positioned(
                  top: 12,
                  child: Text(
                    '${isRTL ? 'ش' : 'N'}',
                    style: AppTypography.h1.copyWith(
                      color: homeBackground,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  child: Text(
                    '${isRTL ? 'ج' : 'S'}',
                    style: AppTypography.h3.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  child: Text(
                    '${isRTL ? 'غ' : 'E'}',
                    style: AppTypography.h3.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  child: Text(
                    '${isRTL ? 'ب' : 'W'}',
                    style: AppTypography.h3.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),

                // Center Kaaba indicator
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: homeBackground.withOpacity(0.15),
                    border: Border.all(
                      color: homeBackground,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: homeBackground.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: homeBackground,
                        boxShadow: [
                          BoxShadow(
                            color: homeBackground.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text('🕌', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                ),

                // Direction arrow pointer
                Positioned(
                  top: 8,
                  child: Container(
                    width: 5,
                    height: 35,
                    decoration: BoxDecoration(
                      color: homeBackground,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: homeBackground.withOpacity(0.7),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xxl),
        // Info text
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: homeBackground.withOpacity(0.08),
            border: Border.all(
              color: homeBackground.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              Text(
                AppLocalizations.translate('qibla', locale),
                style: AppTypography.h3.copyWith(
                  color: homeBackground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                isRTL ? 'اتجاه الكعبة المشرفة' : 'Direction to Kaaba',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _refreshCurrentLocation(PrayerProvider prayerProvider) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum alınıyor...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Force refresh location
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
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🎨 Namaz vakitlerine göre scaffold arka plan rengini belirle
  Color _getTimeBasedScaffoldColor(bool isDark) {
    final now = DateTime.now();
    final prayerTimes = Provider.of<PrayerProvider>(context, listen: false).currentPrayerTimes?.prayerTimesList;

    if (prayerTimes == null || prayerTimes.isEmpty) {
      // Fallback to fixed hours if prayer times not available
      final hour = now.hour;
      if (isDark) {
        if (hour >= 5 && hour < 11) return const Color(0xFF366483);
        else if (hour >= 11 && hour < 15) return const Color(0xFF3A2A1A);
        else if (hour >= 15 && hour < 19) return const Color(0xFF4A1A1A);
        else return const Color(0xFF1A1A2A);
      } else {
        if (hour >= 5 && hour < 11) return const Color(0xFF5DADE2);
        else if (hour >= 11 && hour < 15) return const Color(0xFFFFF9E6);
        else if (hour >= 15 && hour < 19) return const Color(0xFFFFE8D6);
        else return const Color(0xFFE8E8F8);
      }
    }

    // Find prayer times
    DateTime? fajr, sunrise, dhuhr, asr, maghrib, isha;

    for (var prayer in prayerTimes) {
      final name = prayer.name.toLowerCase();
      if (name.contains('fajr') || name.contains('imsak')) {
        fajr = prayer.time;
      } else if (name.contains('sunrise') || name.contains('gunes')) {
        sunrise = prayer.time;
      } else if (name.contains('dhuhr') || name.contains('ogle')) {
        dhuhr = prayer.time;
      } else if (name.contains('asr') || name.contains('ikindi')) {
        asr = prayer.time;
      } else if (name.contains('maghrib') || name.contains('aksam')) {
        maghrib = prayer.time;
      } else if (name.contains('isha') || name.contains('yatsi')) {
        isha = prayer.time;
      }
    }

    // Determine which interval we're in
    String interval = 'night'; // default

    if (fajr != null && sunrise != null && now.isAfter(fajr) && now.isBefore(sunrise)) {
      interval = 'fajr_to_sunrise'; // Sabah vakti
    } else if (sunrise != null && dhuhr != null && now.isAfter(sunrise) && now.isBefore(dhuhr)) {
      interval = 'sunrise_to_dhuhr'; // Güneş - öğle arası
    } else if (dhuhr != null && asr != null && now.isAfter(dhuhr) && now.isBefore(asr)) {
      interval = 'dhuhr_to_asr'; // Öğle - ikindi arası
    } else if (asr != null && maghrib != null && now.isAfter(asr) && now.isBefore(maghrib)) {
      interval = 'asr_to_maghrib'; // İkindi - akşam arası
    } else if (maghrib != null && isha != null && now.isAfter(maghrib) && now.isBefore(isha)) {
      interval = 'maghrib_to_isha'; // Akşam - yatsı arası
    } else if (isha != null && fajr != null) {
      // Handle overnight: from isha to fajr next day
      DateTime ishaTime = isha;
      DateTime fajrTime = fajr.isBefore(isha) ? fajr.add(const Duration(days: 1)) : fajr;
      if (now.isAfter(ishaTime) && now.isBefore(fajrTime)) {
        interval = 'isha_to_fajr'; // Yatsı - imsak arası
      }
    }

    // Return color based on interval
    if (isDark) {
      switch (interval) {
        case 'fajr_to_sunrise':
          return const Color(0xFF366483); // Koyu mavi (sabah)
        case 'sunrise_to_dhuhr':
          return const Color(0xFF3B7BBF); // Koyu mavi (#64B5F6'nın koyu tonu)
        case 'dhuhr_to_asr':
          return const Color(0xFF4A2A1A); // Koyu bakır (öğleden sonra)
        case 'asr_to_maghrib':
          return const Color(0xFF5A1A1A); // Koyu kırmızımsı (akşam)
        case 'maghrib_to_isha':
          return const Color(0xFF2A1A2A); // Koyu morumsu (gece)
        case 'isha_to_fajr':
          return const Color(0xFF1A1A2A); // Koyu lacivert (gece yarısı)
        default:
          return const Color(0xFF1A1A2A);
      }
    } else {
      switch (interval) {
        case 'fajr_to_sunrise':
          return const Color(0xFF5DADE2); // Mavi tonlu sabah rengi (#5DADE2)
        case 'sunrise_to_dhuhr':
          return const Color(0xFF64B5F6); // Mavi ton (#64B5F6)
        case 'dhuhr_to_asr':
          return const Color(0xFFFFE4B5); // Açık bakır (öğleden sonra)
        case 'asr_to_maghrib':
          return const Color(0xFFFFDAB9); // Açık turuncu (akşam)
        case 'maghrib_to_isha':
          return const Color(0xFFE6E6FA); // Açık lavanta (gece)
        case 'isha_to_fajr':
          return const Color(0xFFE8E8F8); // Açık lacivert (gece yarısı)
        default:
          return const Color(0xFFE8E8F8);
      }
    }
  }

  // 🎨 Namaz vakitlerine göre gradient renklerini belirle
  List<Color> _getGradientColors(bool isDark) {
    final now = DateTime.now();
    final prayerTimes = Provider.of<PrayerProvider>(context, listen: false).currentPrayerTimes?.prayerTimesList;

    if (prayerTimes == null || prayerTimes.isEmpty) {
      // Fallback
      final fallbackColor = isDark ? const Color(0xFF1A1A2A) : const Color(0xFFE8E8F8);
      return [
        fallbackColor.withOpacity(0.95),
        fallbackColor.withOpacity(0.65),
      ];
    }

    // Find prayer times
    DateTime? fajr, sunrise, dhuhr, asr, maghrib, isha;

    for (var prayer in prayerTimes) {
      final name = prayer.name.toLowerCase();
      if (name.contains('fajr') || name.contains('imsak')) {
        fajr = prayer.time;
      } else if (name.contains('sunrise') || name.contains('gunes')) {
        sunrise = prayer.time;
      } else if (name.contains('dhuhr') || name.contains('ogle')) {
        dhuhr = prayer.time;
      } else if (name.contains('asr') || name.contains('ikindi')) {
        asr = prayer.time;
      } else if (name.contains('maghrib') || name.contains('aksam')) {
        maghrib = prayer.time;
      } else if (name.contains('isha') || name.contains('yatsi')) {
        isha = prayer.time;
      }
    }

    // Determine which interval we're in
    String interval = 'night';

    if (fajr != null && sunrise != null && now.isAfter(fajr) && now.isBefore(sunrise)) {
      interval = 'fajr_to_sunrise';
    } else if (sunrise != null && dhuhr != null && now.isAfter(sunrise) && now.isBefore(dhuhr)) {
      interval = 'sunrise_to_dhuhr';
    } else if (dhuhr != null && asr != null && now.isAfter(dhuhr) && now.isBefore(asr)) {
      interval = 'dhuhr_to_asr';
    } else if (asr != null && maghrib != null && now.isAfter(asr) && now.isBefore(maghrib)) {
      interval = 'asr_to_maghrib';
    } else if (maghrib != null && isha != null && now.isAfter(maghrib) && now.isBefore(isha)) {
      interval = 'maghrib_to_isha';
    } else if (isha != null && fajr != null) {
      DateTime ishaTime = isha;
      DateTime fajrTime = fajr.isBefore(isha) ? fajr.add(const Duration(days: 1)) : fajr;
      if (now.isAfter(ishaTime) && now.isBefore(fajrTime)) {
        interval = 'isha_to_fajr';
      }
    }

    // Return gradient colors based on interval - canlı ve canlı renkler
    if (isDark) {
      switch (interval) {
        case 'fajr_to_sunrise':
          return [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]; // Koyu mavi -> orta mavi
        case 'sunrise_to_dhuhr':
          return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]; // Canlı mavi -> biraz daha açık mavi
        case 'dhuhr_to_asr':
          return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]; // Canlı mavi -> açık mavi
        case 'asr_to_maghrib':
          return [const Color(0xFF60A5FA), const Color(0xFF93C5FD)]; // Açık mavi -> çok açık mavi
        case 'maghrib_to_isha':
          return [const Color(0xFF93C5FD), const Color(0xFFBFDBFE)]; // Çok açık mavi -> açık mavi
        case 'isha_to_fajr':
          return [const Color(0xFFBFDBFE), const Color(0xFF1E3A8A)]; // Açık mavi -> koyu mavi
        default:
          return [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)];
      }
    } else {
      switch (interval) {
        case 'fajr_to_sunrise':
          return [const Color(0xFF60A5FA), const Color(0xFF93C5FD)]; // Açık mavi -> çok açık mavi
        case 'sunrise_to_dhuhr':
          return [const Color(0xFF93C5FD), const Color(0xFF60A5FA)]; // Çok açık mavi -> açık mavi
        case 'dhuhr_to_asr':
          return [const Color(0xFF60A5FA), const Color(0xFF93C5FD)]; // Açık mavi -> çok açık mavi
        case 'asr_to_maghrib':
          return [const Color(0xFF93C5FD), const Color(0xFFDBEAFE)]; // Çok açık mavi -> en açık mavi
        case 'maghrib_to_isha':
          return [const Color(0xFFDBEAFE), const Color(0xFFE0F2FE)]; // En açık mavi -> gökyüzü mavisi
        case 'isha_to_fajr':
          return [const Color(0xFFE0F2FE), const Color(0xFF3B82F6)]; // Gökyüzü mavisi -> canlı mavi
        default:
          return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
      }
    }
  }
}

class CitySearchDialog extends StatefulWidget {
  final PrayerProvider prayerProvider;

  const CitySearchDialog({Key? key, required this.prayerProvider})
    : super(key: key);

  @override
  State<CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<CitySearchDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  // Popular cities in Turkey
  final List<String> _popularCities = [
    'Istanbul',
    'Ankara',
    'Izmir',
    'Bursa',
    'Antalya',
    'Adana',
    'Gaziantep',
    'Konya',
    'Kayseri',
    'Samsun',
    'Diyarbakır',
    'Mersin',
    'Eskişehir',
    'Malatya',
    'Erzurum',
    'Rize',
    'Çanakkale',
    'Muğla',
    'Denizli',
    'Trabzon',
  ];

  Future<void> _selectCity(String city) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.prayerProvider.setLocation(city, 'TR');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şehir bulunamadı: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.read<AppSettings>().language;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.translate('search_city', locale),
              style: AppTypography.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Search Field
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Istanbul, Ankara, Izmir...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                ),
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkAccentPrimary
                        : AppColors.accentPrimary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _selectCity(value);
                }
              },
            ),

            SizedBox(height: AppSpacing.xl),

            // Show Popular Cities only when field is not focused and empty
            if (!_hasFocus && _controller.text.trim().isEmpty) ...[
              Text(
                'Popüler Şehirler',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // Cities Grid
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _popularCities.map((city) {
                      return GestureDetector(
                        onTap: _isLoading ? null : () => _selectCity(city),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBgSecondary
                                : AppColors.lightBgSecondary,
                            border: Border.all(
                              color: AppColors.divider,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            city,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            SizedBox(height: AppSpacing.xl),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SoftButton(
                  label: AppLocalizations.translate('cancel', locale),
                  onPressed: _isLoading ? () {} : () => Navigator.pop(context),
                  locale: locale,
                  width: 100,
                ),
                SizedBox(width: AppSpacing.md),
                SoftButton(
                  label: _isLoading
                      ? AppLocalizations.translate('loading', locale)
                      : AppLocalizations.translate('search', locale),
                  onPressed: _isLoading || _controller.text.isEmpty
                      ? () {}
                      : () => _selectCity(_controller.text),
                  locale: locale,
                  width: 100,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
