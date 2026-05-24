import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_model.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final scheme = _paletteForPrayer(prayerProvider.activePrayer?.name);
        final nextPrayer = prayerProvider.nextPrayer;
        final countdown = prayerProvider.countdownDuration;
        final prayerTimes =
            prayerProvider.currentPrayerTimes?.prayerTimesList ?? const <PrayerTime>[];
        final completedCount = prayerTimes
            .where((prayer) => prayer.time.isBefore(DateTime.now()))
            .length;
        final progress = prayerTimes.isEmpty
            ? 0.0
            : completedCount / prayerTimes.length;

        return Scaffold(
          backgroundColor: scheme.background,
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.background,
                      scheme.backgroundAccent,
                      scheme.backgroundSoft,
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  color: scheme.primary,
                  onRefresh: prayerProvider.fetchPrayerTimes,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyTopHeaderDelegate(
                          scheme: scheme,
                          city: prayerProvider.savedCity.isNotEmpty
                              ? prayerProvider.savedCity
                              : 'Istanbul',
                          onRefreshLocation: () =>
                              _refreshLocation(context, prayerProvider),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroCountdownCard(
                                scheme: scheme,
                                nextPrayer: nextPrayer,
                                countdown: countdown,
                                errorMessage: prayerProvider.errorMessage,
                                isLoading: prayerProvider.isLoading,
                                progress: progress,
                                completedCount: completedCount,
                                totalCount: prayerTimes.length,
                                activePrayerName: prayerProvider.activePrayer?.name,
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 28),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final prayer = prayerTimes[index];
                            final isActive =
                                prayerProvider.activePrayer?.name == prayer.name;
                            final isNext =
                                prayerProvider.nextPrayer?.name == prayer.name;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _PrayerTile(
                                prayer: prayer,
                                label: _prayerNameTr(prayer.name),
                                scheme: scheme,
                                isActive: isActive,
                                isNext: isNext,
                                isCompleted: prayer.time.isBefore(DateTime.now()),
                              ),
                            );
                          }, childCount: prayerTimes.length),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating "stop adhan" bar — visible only while adhan is playing
              if (prayerProvider.isAdhanPlaying)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 110,
                  child: _AdhanStopBar(
                    scheme: scheme,
                    onLower: () => prayerProvider.lowerAdhanVolume(),
                    onMute: () => prayerProvider.muteAdhan(),
                    onStop: () => prayerProvider.stopAdhan(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshLocation(
    BuildContext context,
    PrayerProvider prayerProvider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Konum yenileniyor...')),
    );

    try {
      await prayerProvider.refreshLocation();
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Konum güncellendi: ${prayerProvider.savedCity.isNotEmpty ? prayerProvider.savedCity : 'Bilinmiyor'}',
          ),
          backgroundColor: const Color(0xFF0F766E),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Konum alinamadi'),
          backgroundColor: Color(0xFFB42318),
        ),
      );
    }
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.scheme,
    required this.city,
    required this.onRefreshLocation,
    this.compact = false,
  });

  final _HomePalette scheme;
  final String city;
  final VoidCallback onRefreshLocation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              city,
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: compact ? FontWeight.w700 : FontWeight.w700,
                letterSpacing: compact ? -0.2 : -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Material(
          color: Colors.white.withOpacity(compact ? 0.14 : 0.18),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onRefreshLocation,
            child: Padding(
              padding: EdgeInsets.all(compact ? 8 : 9),
              child: Icon(
                Icons.my_location_rounded,
                color: Colors.white,
                size: compact ? 16 : 17,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StickyTopHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyTopHeaderDelegate({
    required this.scheme,
    required this.city,
    required this.onRefreshLocation,
  });

  final _HomePalette scheme;
  final String city;
  final VoidCallback onRefreshLocation;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final compact = progress > 0.45;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        compact ? 2 : 4,
        20,
        compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(scheme.primary, scheme.secondary, progress * 0.35)!
                .withOpacity(0.92),
            Color.lerp(scheme.secondary, scheme.tertiary, progress * 0.35)!
                .withOpacity(0.88),
          ],
        ),
        border: overlapsContent
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.10),
                  width: 1,
                ),
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: _TopHeader(
          scheme: scheme,
          city: city,
          onRefreshLocation: onRefreshLocation,
          compact: compact,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTopHeaderDelegate oldDelegate) {
    return oldDelegate.scheme != scheme ||
        oldDelegate.city != city ||
        oldDelegate.onRefreshLocation != onRefreshLocation;
  }
}

class _HeroCountdownCard extends StatelessWidget {
  const _HeroCountdownCard({
    required this.scheme,
    required this.nextPrayer,
    required this.countdown,
    required this.errorMessage,
    required this.isLoading,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.activePrayerName,
  });

  final _HomePalette scheme;
  final PrayerTime? nextPrayer;
  final Duration? countdown;
  final String errorMessage;
  final bool isLoading;
  final double progress;
  final int completedCount;
  final int totalCount;
  final String? activePrayerName;

  @override
  Widget build(BuildContext context) {
    final hours = countdown?.inHours ?? 0;
    final minutes = (countdown?.inMinutes ?? 0) % 60;
    final seconds = (countdown?.inSeconds ?? 0) % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.secondary,
            scheme.tertiary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.38),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Next prayer label
          LayoutBuilder(
            builder: (context, constraints) {
              final title = nextPrayer != null
                  ? '${_prayerNameTr(nextPrayer!.name)} Vaktine'
                  : 'Vakit Bilgisi Bekleniyor';
              final isShortTitle = title.length <= 16;
              final fontSize = isShortTitle ? 20.0 : 16.0;

              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          // Active prayer pill
          if (false && activePrayerName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Şu an: ${_prayerNameTr(activePrayerName!)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.80),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (isLoading)
            const SizedBox(
              height: 60,
              child: Center(
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Color(0x33FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else ...[
            _CountdownDisplay(hours: hours, minutes: minutes, seconds: seconds),
            const SizedBox(height: 6),
            if (nextPrayer != null)
              Text(
                _formatTime(nextPrayer!.time),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
          ],
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _DateBadge(
                  icon: Icons.calendar_today_rounded,
                  label: _miladiDate(),
                  scheme: scheme,
                  useLightStyle: true,
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: _DateBadge(
                  icon: Icons.brightness_3_rounded,
                  label: _hijriDate(),
                  scheme: scheme,
                  useLightStyle: true,
                  alignment: Alignment.centerRight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.scheme});

  final _HomePalette scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DateBadge(
          icon: Icons.calendar_today_rounded,
          label: _miladiDate(),
          scheme: scheme,
        ),
        const SizedBox(width: 10),
        _DateBadge(
          icon: Icons.brightness_3_rounded,
          label: _hijriDate(),
          scheme: scheme,
        ),
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.icon,
    required this.label,
    required this.scheme,
    this.useLightStyle = false,
    this.alignment = Alignment.center,
  });

  final IconData icon;
  final String label;
  final _HomePalette scheme;
  final bool useLightStyle;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: useLightStyle
              ? Colors.white.withOpacity(0.16)
              : scheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: useLightStyle
                ? Colors.white.withOpacity(0.22)
                : scheme.primary.withOpacity(0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: useLightStyle ? Colors.white : scheme.primary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: useLightStyle ? Colors.white : scheme.textPrimary,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating adhan stop bar
// ---------------------------------------------------------------------------
class _AdhanStopBar extends StatelessWidget {
  const _AdhanStopBar({
    required this.scheme,
    required this.onLower,
    required this.onMute,
    required this.onStop,
  });
  final _HomePalette scheme;
  final VoidCallback onLower;
  final VoidCallback onMute;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ezan okunuyor...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionButton(
                      icon: Icons.volume_down_rounded,
                      label: 'Kıs',
                      onTap: onLower,
                    ),
                    _actionButton(
                      icon: Icons.volume_off_rounded,
                      label: 'Sessiz',
                      onTap: onMute,
                    ),
                    _actionButton(
                      icon: Icons.stop_rounded,
                      label: 'Durdur',
                      onTap: onStop,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ezan okunuyor…',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            GestureDetector(
              onTap: onLower,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_down_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Kis',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onMute,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_off_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Sessiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onStop,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Durdur',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
    required this.prayer,
    required this.label,
    required this.scheme,
    required this.isActive,
    required this.isNext,
    required this.isCompleted,
  });

  final PrayerTime prayer;
  final String label;
  final _HomePalette scheme;
  final bool isActive;
  final bool isNext;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final badgeLabel = isActive
        ? 'Şu an'
        : isNext
            ? 'Sıradaki'
            : isCompleted
                ? 'Tamamlandı'
                : _slotLabel(prayer.time);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isActive
            ? scheme.surfaceStrong
            : Colors.white.withOpacity(isCompleted ? 0.58 : 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? scheme.primary.withOpacity(0.55)
              : Colors.white.withOpacity(0.62),
          width: isActive ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(isActive ? 0.26 : 0.10),
            blurRadius: isActive ? 18 : 13,
            offset: const Offset(0, 8),
          ),
        ],
      ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? scheme.primary
                    : isCompleted
                        ? scheme.textSecondary.withOpacity(0.10)
                        : scheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForPrayer(prayer.name),
                color: isActive
                    ? Colors.white
                    : isCompleted
                        ? scheme.textSecondary
                        : scheme.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.textPrimary,
                      fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badgeLabel,
                  style: TextStyle(
                    color: isNext ? scheme.primary : scheme.textSecondary,
                      fontSize: 8,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
           const SizedBox(width: 8),
           Container(
             width: 7,
             height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? scheme.primary
                  : isNext
                      ? scheme.secondary
                      : isCompleted
                          ? scheme.textSecondary.withOpacity(0.35)
                          : Colors.white,
              border: Border.all(
                color: isCompleted
                    ? scheme.textSecondary.withOpacity(0.25)
                    : scheme.primary.withOpacity(0.22),
              ),
            ),
          ),
           const SizedBox(width: 8),
           Text(
             _formatTime(prayer.time),
             style: TextStyle(
               color: scheme.textPrimary,
               fontSize: 19,
               fontWeight: FontWeight.w900,
               letterSpacing: -0.8,
             ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressBar extends StatelessWidget {
  const _DailyProgressBar({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  final double progress;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Günlük İlerleme',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              '$completedCount/$totalCount',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }
}

class _CountdownDisplay extends StatelessWidget {
  const _CountdownDisplay({
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int hours;
  final int minutes;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _TimeUnit(value: hours, label: 'SA'),
        const _Separator(),
        _TimeUnit(value: minutes, label: 'DK'),
        const _Separator(),
        _TimeUnit(value: seconds, label: 'SN'),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30, left: 4, right: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withOpacity(0.50),
          fontSize: 34,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: -2.0,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomePalette {
  const _HomePalette({
    required this.background,
    required this.backgroundAccent,
    required this.backgroundSoft,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surfaceStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadow,
  });

  final Color background;
  final Color backgroundAccent;
  final Color backgroundSoft;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surfaceStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color shadow;
}

_HomePalette _paletteForPrayer(String? prayerName) {
  final normalized = prayerName?.toLowerCase() ?? '';

  // İmsak / Fajr — derin lacivert-indigo (gece sonu)
  if (normalized.contains('fajr') || normalized.contains('imsak')) {
    return const _HomePalette(
      background: Color(0xFFEEF2FF),
      backgroundAccent: Color(0xFFE0E7FF),
      backgroundSoft: Color(0xFFF8F9FF),
      primary: Color(0xFF4338CA),
      secondary: Color(0xFF6366F1),
      tertiary: Color(0xFF818CF8),
      surfaceStrong: Color(0xFFF0F2FF),
      textPrimary: Color(0xFF1E1B4B),
      textSecondary: Color(0xFF6B72A8),
      shadow: Color(0xFF4338CA),
    );
  }

  // Güneş / Sunrise — turuncu-altın (şafak)
  if (normalized.contains('sunrise') || normalized.contains('gunes')) {
    return const _HomePalette(
      background: Color(0xFFFFF7ED),
      backgroundAccent: Color(0xFFFFEDD5),
      backgroundSoft: Color(0xFFFFFBF5),
      primary: Color(0xFFC2410C),
      secondary: Color(0xFFEA580C),
      tertiary: Color(0xFFFB923C),
      surfaceStrong: Color(0xFFFFF8F0),
      textPrimary: Color(0xFF431407),
      textSecondary: Color(0xFF9A4A25),
      shadow: Color(0xFFC2410C),
    );
  }

  // Öğle / Dhuhr — gökyüzü mavisi (öğlen)
  if (normalized.contains('dhuhr') || normalized.contains('ogle')) {
    return const _HomePalette(
      background: Color(0xFFEFF6FF),
      backgroundAccent: Color(0xFFDCEEFB),
      backgroundSoft: Color(0xFFF5FAFF),
      primary: Color(0xFF1D4ED8),
      secondary: Color(0xFF3B82F6),
      tertiary: Color(0xFF60A5FA),
      surfaceStrong: Color(0xFFF0F8FF),
      textPrimary: Color(0xFF1E3A5F),
      textSecondary: Color(0xFF4A7AA8),
      shadow: Color(0xFF1D4ED8),
    );
  }

  // İkindi / Asr — kehribar-amber (ikindi güneşi)
  if (normalized.contains('asr') || normalized.contains('ikindi')) {
    return const _HomePalette(
      background: Color(0xFFFFFBEB),
      backgroundAccent: Color(0xFFFEF3C7),
      backgroundSoft: Color(0xFFFFFDF5),
      primary: Color(0xFFB45309),
      secondary: Color(0xFFD97706),
      tertiary: Color(0xFFF59E0B),
      surfaceStrong: Color(0xFFFFF8EA),
      textPrimary: Color(0xFF451A03),
      textSecondary: Color(0xFF92520A),
      shadow: Color(0xFFB45309),
    );
  }

  // Akşam / Maghrib — kızıl-pembe (gün batımı)
  if (normalized.contains('maghrib') || normalized.contains('aksam')) {
    return const _HomePalette(
      background: Color(0xFFFFF1F2),
      backgroundAccent: Color(0xFFFFE4E6),
      backgroundSoft: Color(0xFFFFF8F9),
      primary: Color(0xFF9F1239),
      secondary: Color(0xFFE11D48),
      tertiary: Color(0xFFFB7185),
      surfaceStrong: Color(0xFFFFF0F2),
      textPrimary: Color(0xFF4C0519),
      textSecondary: Color(0xFFAD5162),
      shadow: Color(0xFF9F1239),
    );
  }

  // Yatsı / Isha — mor-violet (gece)
  return const _HomePalette(
    background: Color(0xFFF5F3FF),
    backgroundAccent: Color(0xFFEDE9FE),
    backgroundSoft: Color(0xFFFAF9FF),
    primary: Color(0xFF5B21B6),
    secondary: Color(0xFF7C3AED),
    tertiary: Color(0xFF8B5CF6),
    surfaceStrong: Color(0xFFF2EEFF),
    textPrimary: Color(0xFF2E1065),
    textSecondary: Color(0xFF7C5AC3),
    shadow: Color(0xFF5B21B6),
  );
}

String _formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String _miladiDate() {
  const months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  final now = DateTime.now();
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}

String _hijriDate() {
  final now = DateTime.now();
  int y = now.year, m = now.month, d = now.day;
  if (m <= 2) {
    y--;
    m += 12;
  }
  final a = y ~/ 100;
  final b = 2 - a + a ~/ 4;
  final jd = (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524;
  final l = jd - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  final l2 = l - 10631 * n + 354;
  final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
      (l2 ~/ 5670) * ((43 * l2) ~/ 15238);
  final l3 = l2 -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final hMonth = (24 * l3) ~/ 709;
  final hDay = l3 - (709 * hMonth) ~/ 24;
  final hYear = 30 * n + j - 30;
  const hijriMonths = [
    'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir',
    'Cemaziyelevvel', 'Cemaziyelahir', 'Recep', 'Şaban',
    'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce',
  ];
  return '$hDay ${hijriMonths[(hMonth - 1).clamp(0, 11)]} $hYear';
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Pazartesi';
    case DateTime.tuesday:
      return 'Sali';
    case DateTime.wednesday:
      return 'Carsamba';
    case DateTime.thursday:
      return 'Persembe';
    case DateTime.friday:
      return 'Cuma';
    case DateTime.saturday:
      return 'Cumartesi';
    default:
      return 'Pazar';
  }
}

String _slotLabel(DateTime time) {
  if (time.hour < 8) return 'Sabah';
  if (time.hour < 12) return 'Gündüz';
  if (time.hour < 17) return 'Öğleden Sonra';
  if (time.hour < 21) return 'Akşam';
  return 'Gece';
}

IconData _iconForPrayer(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('fajr') || normalized.contains('imsak')) {
    return Icons.nightlight_round;
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
  return Icons.brightness_2_rounded;
}

String _prayerNameTr(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('fajr') || normalized.contains('imsak')) return 'İmsak';
  if (normalized.contains('sunrise') || normalized.contains('gunes')) return 'Güneş';
  if (normalized.contains('dhuhr') || normalized.contains('ogle')) return 'Öğle';
  if (normalized.contains('asr') || normalized.contains('ikindi')) return 'İkindi';
  if (normalized.contains('maghrib') || normalized.contains('aksam')) return 'Akşam';
  if (normalized.contains('isha') || normalized.contains('yatsi')) return 'Yatsı';
  return name;
}
