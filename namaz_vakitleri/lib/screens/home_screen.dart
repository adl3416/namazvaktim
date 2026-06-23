import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/localization.dart';
import '../models/prayer_model.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import 'country_selection_screen.dart';
import 'notification_settings_screen.dart';
import 'zikirmatik_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final locale = settings.language;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final mediaQuery = MediaQuery.of(context);
        final bottomInset = mediaQuery.padding.bottom;
        final navigationClearance = 122.0 + (bottomInset == 0
            ? 12.0
            : bottomInset.clamp(8.0, 18.0).toDouble());
        final prayerTimes =
            prayerProvider.currentPrayerTimes?.prayerTimesList ?? const <PrayerTime>[];
        final activePrayer = prayerProvider.activePrayer;
        final nextPrayer = prayerProvider.nextPrayer;
        final prayerKey = activePrayer?.name ?? nextPrayer?.name;
        final theme = _homeThemeForPrayer(prayerKey, isDark);
        final today = prayerProvider.currentPrayerTimes?.date ?? DateTime.now();
        final vird = _virdForPrayer(prayerKey, today, locale);

        return Scaffold(
          backgroundColor: theme.pageBackground,
          body: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.pageBackground,
                      theme.pageBackgroundSoft,
                      const Color(0xFFF7F9FF),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              RefreshIndicator(
                color: theme.accent,
                onRefresh: prayerProvider.refreshPrayerTimes,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HeroSection(
                        theme: theme,
                        locale: locale,
                        activePrayer: activePrayer,
                        nextPrayer: nextPrayer,
                        countdown: prayerProvider.countdownDuration,
                        locationLabel: prayerProvider.savedLocationLabel,
                        today: today,
                        isLoading: prayerProvider.isLoading,
                        errorMessage: prayerProvider.errorMessage,
                        vird: vird,
                        onOpenLocationSettings: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CountrySelectionScreen(),
                            ),
                          );
                        },
                        onRefreshLocation: () =>
                            _refreshLocationLocalized(context, prayerProvider),
                        onOpenNotifications: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const NotificationSettingsScreen(),
                            ),
                          );
                        },
                        onOpenZikirmatik: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ZikirmatikScreen(
                                openLibraryFirst: true,
                              ),
                            ),
                          );
                        },
                        onOpenPrivacyPolicy: () =>
                            _showPrivacyPolicyDialog(context),
                        onStartDhikr: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ZikirmatikScreen(
                                initialZikirName: vird.title,
                                initialTargetCount: vird.targetCount,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        18,
                        14,
                        navigationClearance,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _PrayerTimesCard(
                          theme: theme,
                          locale: locale,
                          prayerTimes: prayerTimes,
                          activePrayer: activePrayer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (prayerProvider.isAdhanPlaying)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 96,
                  child: _AdhanControlBar(
                    theme: theme,
                    locale: locale,
                    onLower: prayerProvider.lowerAdhanVolume,
                    onMute: prayerProvider.muteAdhan,
                    onStop: prayerProvider.stopAdhan,
                  ),
                ),
              if (prayerProvider.requiresManualLocationSelection)
                Positioned.fill(
                  child: _ManualLocationSetupOverlay(
                    theme: theme,
                    locale: locale,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshLocationLocalized(
    BuildContext context,
    PrayerProvider prayerProvider,
  ) async {
    final locale = context.read<AppSettings>().language;
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _text(
            locale,
            tr: 'Sehir verisi guncelleniyor...',
            en: 'Refreshing city data...',
            ar: 'Refreshing city data...',
          ),
        ),
      ),
    );

    try {
      await prayerProvider.refreshLocation();
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F766E),
          content: Text(
              _text(
                locale,
                tr: 'Sehir verisi guncellendi: ${prayerProvider.savedLocationLabel}',
                en: 'City data updated: ${prayerProvider.savedLocationLabel}',
                ar: 'City data updated: ${prayerProvider.savedLocationLabel}',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFB42318),
          content: Text(
            _text(
              locale,
              tr: 'Konum alinamadi',
              en: 'Location could not be fetched',
              ar: 'Location could not be fetched',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showPrivacyPolicyDialog(BuildContext context) async {
    final locale = context.read<AppSettings>().language;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _text(
              locale,
              tr: 'Gizlilik Politikasi',
              en: 'Privacy Policy',
              ar: 'Privacy Policy',
            ),
          ),
          content: Text(
            _text(
              locale,
              tr: 'Bu uygulamada kisisel verileriniz saklanmaz veya depolanmaz. '
                  'Gizliliginiz bizim icin cok onemlidir ve verileriniz cihazinizda kalir.',
              en: 'This app does not store or persist your personal data. '
                  'Your privacy is very important to us and your data stays on your device.',
              ar: 'This app does not store or persist your personal data. '
                  'Your privacy is very important to us and your data stays on your device.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                _text(
                  locale,
                  tr: 'Tamam',
                  en: 'OK',
                  ar: 'OK',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ManualLocationSetupOverlay extends StatelessWidget {
  const _ManualLocationSetupOverlay({
    required this.theme,
    required this.locale,
  });

  final _HomeTheme theme;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: theme.pageBackground.withOpacity(0.92),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFCF6),
                            Color(0xFFFFF2DA),
                            Color(0xFFFFFBF2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(color: Colors.white.withOpacity(0.92)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE1B04D).withOpacity(0.18),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7EBCF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFE8C97E),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/icon3.jpg',
                                width: 26,
                                height: 26,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _text(
                                locale,
                                tr: 'Ezanlar',
                                en: 'Ezanlar',
                                ar: 'Ezanlar',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF153E37),
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE3AB30),
                                width: 3,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 22,
                            child: Icon(
                              Icons.nightlight_round,
                              color: const Color(0xFFE2A62D),
                              size: 36,
                            ),
                          ),
                          Container(
                            width: 136,
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE5C177).withOpacity(0.34),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 42,
                                  color: const Color(0xFFE2A62D),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Şehir',
                                  style: TextStyle(
                                    color: Color(0xFF143D36),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Seçimi',
                                  style: TextStyle(
                                    color: Color(0xFF143D36),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _text(
                          locale,
                          tr: 'Namaz vakitlerini görmek için önce şehrinizi seçin',
                          en: 'Select your city before viewing prayer times',
                          ar: 'Select your city before viewing prayer times',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF143D36),
                          height: 1.16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 62,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2A62D),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _text(
                          locale,
                          tr: 'İlk kurulumda konum otomatik alınmaz. Devam etmek için ülke ve şehir seçmeniz gerekir.',
                          en: 'Location is not filled automatically on first install. Choose your country and city to continue.',
                          ar: 'Location is not filled automatically on first install. Choose your country and city to continue.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6D7684),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE7A72B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CountrySelectionScreen(canPop: false),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _text(
                                  locale,
                                  tr: 'Ülke ve Şehir Seç',
                                  en: 'Choose Country and City',
                                  ar: 'Choose Country and City',
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.arrow_forward_rounded, size: 28),
                            ],
                          ),
                        ),
                      ),
                          ],
                        ),
                      ),
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

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.theme,
    required this.locale,
    required this.activePrayer,
    required this.nextPrayer,
    required this.countdown,
    required this.locationLabel,
    required this.today,
    required this.isLoading,
    required this.errorMessage,
    required this.vird,
    required this.onOpenLocationSettings,
    required this.onRefreshLocation,
    required this.onOpenNotifications,
    required this.onOpenZikirmatik,
    required this.onOpenPrivacyPolicy,
    required this.onStartDhikr,
  });

  final _HomeTheme theme;
  final String locale;
  final PrayerTime? activePrayer;
  final PrayerTime? nextPrayer;
  final Duration? countdown;
  final String locationLabel;
  final DateTime today;
  final bool isLoading;
  final String errorMessage;
  final _VirdModel vird;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onRefreshLocation;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenZikirmatik;
  final VoidCallback onOpenPrivacyPolicy;
  final VoidCallback onStartDhikr;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final targetPrayer = nextPrayer ?? activePrayer;
    final backgroundPrayerName = activePrayer?.name ?? nextPrayer?.name;
    final prayerLabel = targetPrayer == null
        ? _text(
            locale,
            tr: 'Namaz vakti',
            en: 'Prayer time',
            ar: 'Prayer time',
          )
        : AppLocalizations.prayerName(targetPrayer.name, locale);

    return SizedBox(
      height: 400,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.98),
                        Colors.white.withOpacity(0.90),
                        Colors.white.withOpacity(0.72),
                        Colors.white.withOpacity(0.36),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.52, 0.72, 0.86, 0.94, 1.0],
                    ).createShader(bounds),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                        ColorFiltered(
                          colorFilter: _backgroundColorFilterForPrayer(
                            backgroundPrayerName,
                          ),
                          child: Image.asset(
                            _backgroundAssetForPrayer(backgroundPrayerName),
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, 0.42),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _heroImageTopShadeForPrayer(backgroundPrayerName),
                                theme.overlayTop,
                                theme.overlayBottom,
                              ],
                              stops: const [0.0, 0.36, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 160,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.10),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroTopBar(
                  locale: locale,
                  locationLabel: locationLabel,
                  onOpenLocationSettings: onOpenLocationSettings,
                  onRefreshLocation: onRefreshLocation,
                  onOpenNotifications: onOpenNotifications,
                  onOpenZikirmatik: onOpenZikirmatik,
                  onOpenPrivacyPolicy: onOpenPrivacyPolicy,
                ),
                const SizedBox(height: 22),
                Text(
                  '$prayerLabel ${_text(locale, tr: 'Vaktine', en: 'Time', ar: 'Time')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: _buildCountdownText(countdown),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DateChip(
                      icon: Icons.calendar_today_rounded,
                      label: _formatMiladiDate(locale, today),
                    ),
                    const SizedBox(width: 10),
                    _DateChip(
                      icon: Icons.nightlight_round,
                      label: _formatHijriDate(locale, today),
                    ),
                  ],
                ),
                if (isLoading || errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: errorMessage.isNotEmpty
                            ? const Color(0xFF991B1B).withOpacity(0.72)
                            : Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              errorMessage.isNotEmpty
                                  ? errorMessage
                                  : _text(
                                      locale,
                                      tr: 'Veriler yenileniyor',
                                      en: 'Refreshing data',
                                      ar: 'Refreshing data',
                                    ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: -6,
            child: _VirdPanel(
              theme: theme,
              locale: locale,
              vird: vird,
              onTap: onStartDhikr,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTopBar extends StatelessWidget {
  const _HeroTopBar({
    required this.locale,
    required this.locationLabel,
    required this.onOpenLocationSettings,
    required this.onRefreshLocation,
    required this.onOpenNotifications,
    required this.onOpenZikirmatik,
    required this.onOpenPrivacyPolicy,
  });

  final String locale;
  final String locationLabel;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onRefreshLocation;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenZikirmatik;
  final VoidCallback onOpenPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopIconButton(
          icon: Icons.menu_rounded,
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.touch_app_rounded),
                      title: Text(
                        _text(
                          locale,
                          tr: 'Zikir Sayaci',
                          en: 'Dhikr Counter',
                          ar: 'Dhikr Counter',
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop('counter'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(
                        _text(
                          locale,
                          tr: 'Gizlilik Politikasi',
                          en: 'Privacy Policy',
                          ar: 'Privacy Policy',
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop('privacy'),
                    ),
                  ],
                ),
              ),
            );

            if (selected == 'counter') {
              onOpenZikirmatik();
            } else if (selected == 'privacy') {
              onOpenPrivacyPolicy();
            }
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenLocationSettings,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationLabel,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.settings_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.88),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _TopIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white,
            size: 23,
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VirdPanel extends StatelessWidget {
  const _VirdPanel({
    required this.theme,
    required this.locale,
    required this.vird,
    required this.onTap,
  });

  final _HomeTheme theme;
  final String locale;
  final _VirdModel vird;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.90),
                theme.cardTint.withOpacity(0.92),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.70),
              width: 1.1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.34),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                top: 8,
                bottom: 8,
                width: 124,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CardOrnamentPainter(
                      color: theme.accent.withOpacity(0.12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.accent.withOpacity(0.96),
                            theme.accentDark,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.56),
                          width: 1.4,
                        ),
                      ),
                      child: ClipOval(
                        child: SizedBox.expand(
                          child: Image.asset(
                            'assets/images/tesbih.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _text(
                              locale,
                              tr: 'VAKTİN VİRDİ',
                              en: 'CURRENT DHIKR',
                              ar: 'CURRENT DHIKR',
                            ),
                            style: TextStyle(
                              color: theme.accentDark.withOpacity(0.82),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              _text(
                                locale,
                                tr: 'VAKTIN VIRDI',
                                en: 'CURRENT DHIKR',
                                ar: 'CURRENT DHIKR',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.transparent,
                                fontSize: 0.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                                height: 0.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            vird.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF15203B),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.accent.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${vird.targetCount} ${_text(locale, tr: 'Defa', en: 'Times', ar: 'Times')}',
                              style: TextStyle(
                                color: theme.accentDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _text(
                                    locale,
                                    tr: 'VAKTÄ°N VÄ°RDÄ°',
                                    en: 'CURRENT DHIKR',
                                    ar: 'CURRENT DHIKR',
                                  ),
                                  style: TextStyle(
                                    color: Colors.transparent,
                                    fontSize: 0.1,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                    height: 0.1,
                                  ),
                                ),
                                const SizedBox(width: 0),
                                _StartDhikrButton(
                                  theme: theme,
                                  locale: locale,
                                  onTap: onTap,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartDhikrButton extends StatelessWidget {
  const _StartDhikrButton({
    required this.theme,
    required this.locale,
    required this.onTap,
  });

  final _HomeTheme theme;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [
              theme.accent,
              theme.accentDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.accent.withOpacity(0.32),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _text(locale, tr: 'Virde Basla', en: 'Start Wird', ar: 'Start'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.accentDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimesCard extends StatelessWidget {
  const _PrayerTimesCard({
    required this.theme,
    required this.locale,
    required this.prayerTimes,
    required this.activePrayer,
  });

  final _HomeTheme theme;
  final String locale;
  final List<PrayerTime> prayerTimes;
  final PrayerTime? activePrayer;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF243B6B).withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          children: [
            for (var index = 0; index < prayerTimes.length; index++) ...[
              _PrayerTimeRow(
                theme: theme,
                locale: locale,
                prayer: prayerTimes[index],
                isActive: activePrayer?.name == prayerTimes[index].name,
                isCompleted: now.isAfter(prayerTimes[index].time) &&
                    activePrayer?.name != prayerTimes[index].name,
              ),
              if (index != prayerTimes.length - 1)
                Divider(
                  height: 18,
                  thickness: 1,
                  color: const Color(0xFFE8EDF8),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  const _PrayerTimeRow({
    required this.theme,
    required this.locale,
    required this.prayer,
    required this.isActive,
    required this.isCompleted,
  });

  final _HomeTheme theme;
  final String locale;
  final PrayerTime prayer;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final localizedName = AppLocalizations.prayerName(prayer.name, locale);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isActive
            ? LinearGradient(
                colors: [
                  theme.accent.withOpacity(0.12),
                  theme.accent.withOpacity(0.05),
                ],
              )
            : null,
        border: Border.all(
          color: isActive
              ? theme.accent.withOpacity(0.26)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? theme.accent.withOpacity(0.16)
                  : const Color(0xFFF3F6FC),
            ),
            child: Icon(
              _iconForPrayer(prayer.name),
              color: isActive ? theme.accentDark : const Color(0xFF7C8AA8),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    localizedName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? theme.accentDark : const Color(0xFF1C2841),
                      fontSize: 17,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 10),
                  Text(
                    _text(locale, tr: 'Su an', en: 'Now', ar: 'Now'),
                    style: TextStyle(
                      color: theme.accentDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatClock(prayer.time),
            style: TextStyle(
              color: isActive ? theme.accentDark : const Color(0xFF1D2A44),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          _StatusDot(
            theme: theme,
            isActive: isActive,
            isCompleted: isCompleted,
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.theme,
    required this.isActive,
    required this.isCompleted,
  });

  final _HomeTheme theme;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE7F7EE),
          border: Border.all(color: const Color(0xFFCDEBD9)),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 13,
          color: Color(0xFF17844E),
        ),
      );
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? theme.accent : const Color(0xFFD6DCE9),
      ),
    );
  }
}

class _AdhanControlBar extends StatelessWidget {
  const _AdhanControlBar({
    required this.theme,
    required this.locale,
    required this.onLower,
    required this.onMute,
    required this.onStop,
  });

  final _HomeTheme theme;
  final String locale;
  final VoidCallback onLower;
  final VoidCallback onMute;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accent.withOpacity(0.22),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _text(
                  locale,
                  tr: 'Ezan caliyor',
                  en: 'Adhan is playing',
                  ar: 'Adhan is playing',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _MiniActionChip(
              label: _text(locale, tr: 'Azalt', en: 'Lower', ar: 'Lower'),
              onTap: onLower,
            ),
            const SizedBox(width: 8),
            _MiniActionChip(
              label: _text(locale, tr: 'Sessiz', en: 'Mute', ar: 'Mute'),
              onTap: onMute,
            ),
            const SizedBox(width: 8),
            _MiniActionChip(
              label: _text(locale, tr: 'Kapat', en: 'Stop', ar: 'Stop'),
              onTap: onStop,
              emphasis: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  const _MiniActionChip({
    required this.label,
    required this.onTap,
    this.emphasis = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasis ? const Color(0xFFF04A4A) : Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardOrnamentPainter extends CustomPainter {
  const _CardOrnamentPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fillPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width * 0.72;
    final centerY = size.height * 0.50;
    final width = size.width * 0.46;
    final height = size.height * 0.64;

    path.moveTo(centerX, centerY - height / 2);
    path.quadraticBezierTo(
      centerX + width / 2,
      centerY - height / 4,
      centerX + width / 2,
      centerY + height / 7,
    );
    path.quadraticBezierTo(
      centerX + width / 3,
      centerY + height / 2,
      centerX,
      centerY + height / 2,
    );
    path.quadraticBezierTo(
      centerX - width / 3,
      centerY + height / 2,
      centerX - width / 2,
      centerY + height / 7,
    );
    path.quadraticBezierTo(
      centerX - width / 2,
      centerY - height / 4,
      centerX,
      centerY - height / 2,
    );

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    for (var i = 0; i < 3; i++) {
      final inset = 10.0 + i * 12;
      final inner = Rect.fromLTWH(
        centerX - width / 2 + inset,
        centerY - height / 2 + inset,
        width - inset * 2,
        height - inset * 2,
      );
      canvas.drawArc(inner, math.pi, math.pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardOrnamentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _HomeTheme {
  const _HomeTheme({
    required this.pageBackground,
    required this.pageBackgroundSoft,
    required this.accent,
    required this.accentDark,
    required this.overlayTop,
    required this.overlayBottom,
    required this.cardTint,
    required this.shadow,
  });

  final Color pageBackground;
  final Color pageBackgroundSoft;
  final Color accent;
  final Color accentDark;
  final Color overlayTop;
  final Color overlayBottom;
  final Color cardTint;
  final Color shadow;
}

class _VirdModel {
  const _VirdModel({
    required this.title,
    required this.targetCount,
    required this.description,
  });

  final String title;
  final int targetCount;
  final String description;
}

_HomeTheme _homeThemeForPrayer(String? prayerName, bool isDark) {
  final normalized = (prayerName ?? '').toLowerCase();

  if (normalized.contains('sunrise') || normalized.contains('gunes')) {
    return const _HomeTheme(
      pageBackground: Color(0xFFF7E7B2),
      pageBackgroundSoft: Color(0xFFFFF4D6),
      accent: Color(0xFFF4B61D),
      accentDark: Color(0xFFC98900),
      overlayTop: Color(0x2B573100),
      overlayBottom: Color(0xBB6B3A00),
      cardTint: Color(0xFFFFD770),
      shadow: Color(0xFF8B5B00),
    );
  }

  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return const _HomeTheme(
      pageBackground: Color(0xFFDDEEFF),
      pageBackgroundSoft: Color(0xFFF1F8FF),
      accent: Color(0xFF3A89FF),
      accentDark: Color(0xFF1E5EDB),
      overlayTop: Color(0x060D4F9A),
      overlayBottom: Color(0x180A5AB5),
      cardTint: Color(0xFF81B6FF),
      shadow: Color(0xFF164A9C),
    );
  }

  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return const _HomeTheme(
      pageBackground: Color(0xFFFFE2C5),
      pageBackgroundSoft: Color(0xFFFFF0E0),
      accent: Color(0xFFFF8A1E),
      accentDark: Color(0xFFDB5D00),
      overlayTop: Color(0x105A3E10),
      overlayBottom: Color(0x386A3412),
      cardTint: Color(0xFFFFB263),
      shadow: Color(0xFFA34E00),
    );
  }

  if (normalized.contains('maghrib') || normalized.contains('aksam')) {
    return const _HomeTheme(
      pageBackground: Color(0xFFFFD1CB),
      pageBackgroundSoft: Color(0xFFFFF0EE),
      accent: Color(0xFFFF4C36),
      accentDark: Color(0xFFCB1E13),
      overlayTop: Color(0x290C0000),
      overlayBottom: Color(0xB07D1208),
      cardTint: Color(0xFFFF8577),
      shadow: Color(0xFF8A1810),
    );
  }

  if (normalized.contains('isha') || normalized.contains('yatsi')) {
    return const _HomeTheme(
      pageBackground: Color(0xFFE1DAFF),
      pageBackgroundSoft: Color(0xFFF2EEFF),
      accent: Color(0xFF7E4DFF),
      accentDark: Color(0xFF5A29D9),
      overlayTop: Color(0x22040024),
      overlayBottom: Color(0xB0240B64),
      cardTint: Color(0xFFB69EFF),
      shadow: Color(0xFF361378),
    );
  }

  return _HomeTheme(
    pageBackground: isDark ? const Color(0xFF0D1730) : const Color(0xFFD7E3FF),
    pageBackgroundSoft: isDark ? const Color(0xFF111E3F) : const Color(0xFFEDF3FF),
    accent: const Color(0xFF2F6BFF),
    accentDark: const Color(0xFF1C3FA2),
    overlayTop: const Color(0x26010016),
    overlayBottom: const Color(0xBA071735),
    cardTint: const Color(0xFF84A6FF),
    shadow: const Color(0xFF1A2B60),
  );
}

Color _heroImageTopShadeForPrayer(String? prayerName) {
  final normalized = (prayerName ?? '').toLowerCase();
  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return Colors.black.withOpacity(0.02);
  }
  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return Colors.black.withOpacity(0.05);
  }
  return Colors.black.withOpacity(0.08);
}

ColorFilter _backgroundColorFilterForPrayer(String? prayerName) {
  final normalized = (prayerName ?? '').toLowerCase();

  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return const ColorFilter.matrix(<double>[
      1.08, 0, 0, 0, 0,
      0, 1.10, 0, 0, 0,
      0, 0, 1.18, 0, 8,
      0, 0, 0, 1, 0,
    ]);
  }

  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return const ColorFilter.matrix(<double>[
      1.04, 0, 0, 0, -2,
      0, 1.08, 0, 0, -2,
      0, 0, 1.14, 0, 6,
      0, 0, 0, 1, 0,
    ]);
  }

  return const ColorFilter.mode(
    Colors.transparent,
    BlendMode.srcOver,
  );
}

_VirdModel _virdForPrayer(String? prayerName, DateTime date, String locale) {
  final virdler = _allVirds(locale);
  final slotIndex = _prayerSlotIndex(prayerName);
  final dayIndex = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(2024, 1, 1)).inDays;
  final index = (dayIndex + slotIndex) % virdler.length;
  return virdler[index];
}

List<_VirdModel> _allVirds(String locale) {
  return [
    _VirdModel(
      title: _text(
        locale,
        tr: 'Estagfirullah',
        en: 'Astaghfirullah',
        ar: 'Astaghfirullah',
      ),
      targetCount: 100,
      description: _text(
        locale,
        tr: 'Gunaha tovbe ve kalbi arindirmak icin.',
        en: 'To seek forgiveness and purify the heart.',
        ar: 'To seek forgiveness and purify the heart.',
      ),
    ),
    _VirdModel(
      title: _text(
        locale,
        tr: 'Subhanallah',
        en: 'Subhanallah',
        ar: 'Subhanallah',
      ),
      targetCount: 100,
      description: _text(
        locale,
        tr: 'Allahi her turlu eksiklikten tenzih etmek icin.',
        en: 'To glorify Allah beyond all imperfection.',
        ar: 'To glorify Allah beyond all imperfection.',
      ),
    ),
    _VirdModel(
      title: _text(locale, tr: 'Ya Allah', en: 'Ya Allah', ar: 'Ya Allah'),
      targetCount: 66,
      description: _text(
        locale,
        tr: "Kalbi Allah'a yoneltmek ve O'na siginmak icin.",
        en: 'To turn the heart toward Allah and seek His shelter.',
        ar: 'To turn the heart toward Allah and seek His shelter.',
      ),
    ),
    _VirdModel(
      title: _text(locale, tr: 'Ya Latif', en: 'Ya Latif', ar: 'Ya Latif'),
      targetCount: 129,
      description: _text(
        locale,
        tr: "Allah'in lutfunu ve ince rahmetini hatirlamak icin.",
        en: "To remember Allah's subtle kindness and mercy.",
        ar: "To remember Allah's subtle kindness and mercy.",
      ),
    ),
    _VirdModel(
      title: _text(
        locale,
        tr: 'La ilahe illallah',
        en: 'La ilaha illallah',
        ar: 'La ilaha illallah',
      ),
      targetCount: 100,
      description: _text(
        locale,
        tr: 'Kalbi huzur ve imanla guclendirmek icin.',
        en: 'To strengthen the heart with peace and faith.',
        ar: 'To strengthen the heart with peace and faith.',
      ),
    ),
    _VirdModel(
      title: _text(
        locale,
        tr: 'Allahumme salli ala seyyidina Muhammed',
        en: 'Salawat',
        ar: 'Salawat',
      ),
      targetCount: 100,
      description: _text(
        locale,
        tr: "Peygamber Efendimiz'e salat ve selam getirmek icin.",
        en: 'To send blessings and peace upon the Prophet.',
        ar: 'To send blessings and peace upon the Prophet.',
      ),
    ),
  ];
}

int _prayerSlotIndex(String? prayerName) {
  final normalized = (prayerName ?? '').toLowerCase();
  if (normalized.contains('sunrise') || normalized.contains('gunes')) {
    return 1;
  }
  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return 2;
  }
  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return 3;
  }
  if (normalized.contains('maghrib') || normalized.contains('aksam')) {
    return 4;
  }
  if (normalized.contains('isha') || normalized.contains('yatsi')) {
    return 5;
  }
  return 0;
}

String _backgroundAssetForPrayer(String? prayerName) {
  final normalized = (prayerName ?? '').toLowerCase();

  if (normalized.contains('sunrise') || normalized.contains('gunes')) {
    return 'assets/images/gunes_bg.png';
  }
  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return 'assets/images/ogle_bg.png';
  }
  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return 'assets/images/ikindi_bg.png';
  }
  if (normalized.contains('maghrib') || normalized.contains('aksam')) {
    return 'assets/images/aksam_bg.png';
  }
  if (normalized.contains('isha') || normalized.contains('yatsi')) {
    return 'assets/images/yatsi_bg.png';
  }
  return 'assets/images/imsak_bg.png';
}

String _formatCountdown(Duration? duration) {
  if (duration == null) return '--:--:--';
  final totalSeconds = duration.inSeconds.abs();
  final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

TextSpan _buildCountdownText(Duration? duration) {
  final formatted = _formatCountdown(duration).split(':');
  final hours = formatted.isNotEmpty ? formatted[0] : '--';
  final minutes = formatted.length > 1 ? formatted[1] : '--';
  final seconds = formatted.length > 2 ? formatted[2] : '--';

  const mainStyle = TextStyle(
    color: Colors.white,
    fontSize: 52,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    height: 0.98,
    shadows: [
      Shadow(
        color: Color(0xCCFFFFFF),
        blurRadius: 10,
      ),
      Shadow(
        color: Color(0xB3000000),
        offset: Offset(0, 2),
        blurRadius: 8,
      ),
    ],
  );

  return TextSpan(
    style: mainStyle,
    children: [
      TextSpan(text: '$hours:$minutes'),
      TextSpan(
        text: ':$seconds',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          shadows: [
            Shadow(
              color: Color(0xCCFFFFFF),
              blurRadius: 8,
            ),
            Shadow(
              color: Color(0xB3000000),
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    ],
  );
}

String _formatClock(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatMiladiDate(String locale, DateTime date) {
  const trMonths = <String>[
    'Ocak',
    'Subat',
    'Mart',
    'Nisan',
    'Mayis',
    'Haziran',
    'Temmuz',
    'Agustos',
    'Eylul',
    'Ekim',
    'Kasim',
    'Aralik',
  ];
  const enMonths = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final months = locale == 'tr' ? trMonths : enMonths;
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatHijriDate(String locale, DateTime date) {
  final hijri = _toHijri(date);
  const trMonths = <String>[
    'Muharrem',
    'Safer',
    'Rebiulevvel',
    'Rebiulahir',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Saban',
    'Ramazan',
    'Sevval',
    'Zilkade',
    'Zilhicce',
  ];
  const enMonths = <String>[
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Shaban',
    'Ramadan',
    'Shawwal',
    'Dhul Qadah',
    'Dhul Hijjah',
  ];
  final months = locale == 'tr' ? trMonths : enMonths;
  return '${hijri.day} ${months[hijri.month - 1]} ${hijri.year}';
}

_HijriDate _toHijri(DateTime date) {
  final julianDay = _gregorianToJulian(date.year, date.month, date.day);
  var l = julianDay - 1948440 + 10632;
  final n = ((l - 1) / 10631).floor();
  l = l - 10631 * n + 354;
  final j = (((10985 - l) / 5316).floor()) *
          (((50 * l) / 17719).floor()) +
      ((l / 5670).floor()) * (((43 * l) / 15238).floor());
  l = l -
      (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) -
      ((j / 16).floor()) * (((15238 * j) / 43).floor()) +
      29;
  final month = ((24 * l) / 709).floor();
  final day = l - ((709 * month) / 24).floor();
  final year = 30 * n + j - 30;
  return _HijriDate(day: day, month: month, year: year);
}

int _gregorianToJulian(int year, int month, int day) {
  final a = ((14 - month) / 12).floor();
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day +
      (((153 * m) + 2) / 5).floor() +
      365 * y +
      (y / 4).floor() -
      (y / 100).floor() +
      (y / 400).floor() -
      32045;
}

class _HijriDate {
  const _HijriDate({
    required this.day,
    required this.month,
    required this.year,
  });

  final int day;
  final int month;
  final int year;
}

IconData _iconForPrayer(String prayerName) {
  final normalized = prayerName.toLowerCase();

  if (normalized.contains('fajr') || normalized.contains('imsak')) {
    return Icons.dark_mode_rounded;
  }
  if (normalized.contains('sunrise') || normalized.contains('gunes')) {
    return Icons.wb_sunny_rounded;
  }
  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return Icons.light_mode_rounded;
  }
  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return Icons.wb_twilight_rounded;
  }
  if (normalized.contains('maghrib') || normalized.contains('aksam')) {
    return Icons.wb_twilight_rounded;
  }
  return Icons.nightlight_round;
}

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

