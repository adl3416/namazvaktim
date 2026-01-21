import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/qibla_compass_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AppSettings, PrayerProvider>(
        builder: (context, settings, prayerProvider, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final locale = settings.language;
          final isRTL = AppLocalizations.isRTL(locale);

          return Directionality(
            textDirection:
                isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(
                  context,
                  settings,
                  prayerProvider,
                  isDark,
                  locale,
                ),

                // Main Content - Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          // Loading State
                          if (prayerProvider.isLoading)
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(height: AppSpacing.xxxl),
                                  const CircularProgressIndicator(),
                                  SizedBox(height: AppSpacing.lg),
                                  Text(
                                    AppLocalizations.translate('loading', locale),
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
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer - Nearby Mosques
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBgSecondary
                        : AppColors.lightBgSecondary,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.divider,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: SoftButton(
                      label: AppLocalizations.translate(
                        'nearby_mosques',
                        locale,
                      ),
                      onPressed: () {
                        _showComingSoon(context, locale);
                      },
                      locale: locale,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppSettings settings,
    PrayerProvider prayerProvider,
    bool isDark,
    String locale,
  ) {
    final isRTL = AppLocalizations.isRTL(locale);

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Settings
            SoftIconButton(
              icon: Icons.settings_outlined,
              onPressed: () {
                _showSettingsSheet(context, settings);
              },
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
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            prayerProvider.savedCity.isEmpty
                                ? AppLocalizations.translate(
                                    'search_city',
                                    locale,
                                  )
                                : prayerProvider.savedCity,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
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
                    Navigator.of(context).push(PageRouteBuilder(
                      opaque: false,
                      transitionDuration: const Duration(milliseconds: 700),
                      reverseTransitionDuration: const Duration(milliseconds: 700),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return QiblaFullScreen(locale: locale);
                      },
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        // No extra transition; hero handles the motion
                        return child;
                      },
                    ));
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
  ) {
    final nextPrayer = prayerProvider.nextPrayer;
    if (nextPrayer == null) return SizedBox.shrink();

    return Column(
      children: [
        Text(
          '${AppLocalizations.translate(
            nextPrayer.name.toLowerCase(),
            locale,
          )} ${AppLocalizations.translate('prayer_time_label', locale)}',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        CountdownDisplay(
          countdown: prayerProvider.countdownDuration,
          locale: locale,
        ),
      ],
    );
  }

  Widget _buildPrayerTimesList(
    BuildContext context,
    PrayerProvider prayerProvider,
    bool isDark,
    String locale,
  ) {
    final prayers = prayerProvider.currentPrayerTimes?.prayerTimesList ?? [];

    return Column(
      children: [
        ...prayers.map(
          (prayer) {
            final timeStr =
                '${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')}';

            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: PrayerTimeRow(
                prayerName: prayer.name,
                prayerTime: timeStr,
                isActive: prayer.isActive,
                locale: locale,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context, AppSettings settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = settings.language;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: AppLocalizations.isRTL(locale)
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Container(
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Consumer<AppSettings>(
              builder: (context, settings, _) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      AppLocalizations.translate('settings', locale),
                      style: AppTypography.h2.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl),

                    // Theme
                    _buildSettingSection(
                      label: AppLocalizations.translate('theme', locale),
                      isDark: isDark,
                      locale: locale,
                      child: Column(
                        children: [
                          _buildSettingOption(
                            label: AppLocalizations.translate('system', locale),
                            isSelected: settings.themeMode == ThemeMode.system,
                            onTap: () =>
                                settings.setThemeMode(ThemeMode.system),
                            isDark: isDark,
                            locale: locale,
                          ),
                          _buildSettingOption(
                            label: AppLocalizations.translate('light', locale),
                            isSelected: settings.themeMode == ThemeMode.light,
                            onTap: () =>
                                settings.setThemeMode(ThemeMode.light),
                            isDark: isDark,
                            locale: locale,
                          ),
                          _buildSettingOption(
                            label: AppLocalizations.translate('dark', locale),
                            isSelected: settings.themeMode == ThemeMode.dark,
                            onTap: () =>
                                settings.setThemeMode(ThemeMode.dark),
                            isDark: isDark,
                            locale: locale,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppSpacing.xxl),

                    // Language
                    _buildSettingSection(
                      label: AppLocalizations.translate('language', locale),
                      isDark: isDark,
                      locale: locale,
                      child: Column(
                        children: [
                          _buildSettingOption(
                            label: 'Türkçe',
                            isSelected: settings.language == 'tr',
                            onTap: () => settings.setLanguage('tr'),
                            isDark: isDark,
                            locale: locale,
                          ),
                          _buildSettingOption(
                            label: 'English',
                            isSelected: settings.language == 'en',
                            onTap: () => settings.setLanguage('en'),
                            isDark: isDark,
                            locale: locale,
                          ),
                          _buildSettingOption(
                            label: 'العربية',
                            isSelected: settings.language == 'ar',
                            onTap: () => settings.setLanguage('ar'),
                            isDark: isDark,
                            locale: locale,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppSpacing.xxl),

                    // Notifications
                    _buildSettingToggle(
                      label: AppLocalizations.translate(
                        'enable_adhan',
                        locale,
                      ),
                      value: settings.enableAdhanSound,
                      onChanged: (value) =>
                          settings.setEnableAdhanSound(value),
                      isDark: isDark,
                    ),

                    SizedBox(height: AppSpacing.lg),

                    _buildSettingToggle(
                      label: AppLocalizations.translate(
                        'prayer_notifications',
                        locale,
                      ),
                      value: settings.enablePrayerNotifications,
                      onChanged: (value) =>
                          settings.setEnablePrayerNotifications(value),
                      isDark: isDark,
                    ),

                    SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingSection({
    required String label,
    required bool isDark,
    required String locale,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }

  Widget _buildSettingOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required String locale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark
                          ? AppColors.darkAccentPrimary
                          : AppColors.accentPrimary)
                      : (isDark
                          ? AppColors.darkTextLight
                          : AppColors.textLight),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.darkAccentPrimary
                              : AppColors.accentPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary,
          inactiveTrackColor: isDark
              ? AppColors.darkTextLight.withOpacity(0.3)
              : AppColors.textLight.withOpacity(0.3),
        ),
      ],
    );
  }

  void _showCitySearch(BuildContext context, PrayerProvider prayerProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return CitySearchDialog(prayerProvider: prayerProvider);
      },
    );
  }

  void _showComingSoon(BuildContext context, String locale) {
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
                  _buildQiblaCompass(context, locale),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQiblaCompass(BuildContext context, String locale) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compass
            _buildCompassUI(context, locale),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassUI(BuildContext context, String locale) {
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
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accentPrimary.withOpacity(0.2),
                  AppColors.accentPrimary.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: AppColors.accentPrimary.withOpacity(0.4),
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
                      color: AppColors.accentPrimary,
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
                    color: AppColors.accentPrimary.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors.accentPrimary,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPrimary.withOpacity(0.4),
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
                        color: AppColors.accentPrimary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPrimary.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '🕌',
                          style: TextStyle(fontSize: 22),
                        ),
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
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPrimary.withOpacity(0.7),
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
            color: AppColors.accentPrimary.withOpacity(0.08),
            border: Border.all(
              color: AppColors.accentPrimary.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              Text(
                AppLocalizations.translate('qibla', locale),
                style: AppTypography.h3.copyWith(
                  color: AppColors.accentPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                isRTL
                    ? 'اتجاه الكعبة المشرفة'
                    : 'Direction to Kaaba',
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
}

class CitySearchDialog extends StatefulWidget {
  final PrayerProvider prayerProvider;
  
  const CitySearchDialog({
    Key? key,
    required this.prayerProvider,
  }) : super(key: key);

  @override
  State<CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<CitySearchDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

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
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Istanbul, Ankara, Izmir...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextLight
                      : AppColors.textLight,
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
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.divider,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.divider,
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

            // Popular Cities
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
            
            SizedBox(height: AppSpacing.xl),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SoftButton(
                  label: AppLocalizations.translate('cancel', locale),
                  onPressed: _isLoading
                      ? () {}
                      : () => Navigator.pop(context),
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
    super.dispose();
  }
}
