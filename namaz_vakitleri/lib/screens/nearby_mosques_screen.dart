import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/color_system.dart';
import '../models/mosque_model.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../services/mosque_service.dart';

class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  Future<List<Mosque>>? _nearbyMosquesFuture;
  double _searchRadius = 5.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoadMosques());
  }

  void _tryLoadMosques() {
    if (!mounted) return;
    final location = context.read<PrayerProvider>().currentLocation;
    if (location != null && _nearbyMosquesFuture == null) {
      setState(() {
        _nearbyMosquesFuture = MosqueService.getNearbyMosques(
          location: location,
          radiusKm: _searchRadius,
        );
      });
    }
  }

  void _updateRadius(double value) {
    final location = context.read<PrayerProvider>().currentLocation;
    setState(() {
      _searchRadius = value;
      if (location != null) {
        _nearbyMosquesFuture = MosqueService.getNearbyMosques(
          location: location,
          radiusKm: value,
        );
      }
    });
  }

  Future<void> _launchExternal(String url) async {
    final normalized = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openNavigation(Mosque mosque) async {
    final label = Uri.encodeComponent(mosque.name);
    final lat = mosque.latitude;
    final lon = mosque.longitude;

    final candidates = <Uri>[
      if (Platform.isAndroid)
        Uri.parse('google.navigation:q=$lat,$lon')
      else
        Uri.parse('http://maps.apple.com/?daddr=$lat,$lon&dirflg=d'),
      Uri.parse('geo:$lat,$lon?q=$lat,$lon($label)'),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
      ),
    ];

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigasyon uygulamasi acilamadi'),
        backgroundColor: Color(0xFFB42318),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final location = prayerProvider.currentLocation;

        if (location != null && _nearbyMosquesFuture == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoadMosques());
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F0E8),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        Color(0xFF0F172A),
                        Color(0xFF111827),
                        Color(0xFF172033),
                      ]
                    : const [
                        Color(0xFFF5F0E7),
                        Color(0xFFE8DDD0),
                        Color(0xFFF8F5EF),
                      ],
              ),
            ),
            child: SafeArea(
              child: FutureBuilder<List<Mosque>>(
                future: _nearbyMosquesFuture,
                builder: (context, snapshot) {
                  final mosques = snapshot.data ?? const <Mosque>[];

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Yakındaki Camiler',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.4,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : const Color(0xFF1F1A16),
                                              ),
                                            ),
                                            if (mosques.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1F4C43),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  '${mosques.length} cami',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (location != null)
                                          Text(
                                            '${location.city} çevresinde',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.darkTextLight
                                                  : Colors.black.withOpacity(0.45),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _CompactRadiusCard(
                                radius: _searchRadius,
                                onChanged: _updateRadius,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (location == null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyMosqueState(
                            isDark: isDark,
                            icon: Icons.location_off_rounded,
                            title: 'Konum gerekli',
                            message:
                                'Yakindaki camileri gorebilmek icin uygulamanin konum iznine ihtiyaci var.',
                          ),
                        )
                      else if (snapshot.connectionState == ConnectionState.waiting)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1F4C43),
                            ),
                          ),
                        )
                      else if (snapshot.hasError)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyMosqueState(
                            isDark: isDark,
                            icon: Icons.error_outline_rounded,
                            title: 'Liste yüklenemedi',
                            message: 'Hata: ${snapshot.error}',
                          ),
                        )
                      else if (mosques.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyMosqueState(
                            isDark: isDark,
                            icon: Icons.travel_explore_rounded,
                            title: 'Bu alanda sonuç yok',
                            message:
                                'Arama yarıçapını genişleterek daha fazla cami görebilirsin.',
                          ),
                        )
                      else ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                height: 220,
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      location.latitude,
                                      location.longitude,
                                    ),
                                    initialZoom: 14.0,
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.all,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.namaz_vakitleri',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(
                                            location.latitude,
                                            location.longitude,
                                          ),
                                          width: 22,
                                          height: 22,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1F4C43),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF1F4C43)
                                                      .withOpacity(0.45),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        ...mosques.map(
                                          (mosque) => Marker(
                                            point: LatLng(
                                              mosque.latitude,
                                              mosque.longitude,
                                            ),
                                            width: 36,
                                            height: 36,
                                            child: GestureDetector(
                                              onTap: () => _openNavigation(mosque),
                                              child: const Icon(
                                                Icons.mosque_rounded,
                                                color: Color(0xFFD97706),
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: Text(
                              'En yakından sıralandı',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextLight
                                    : Colors.black.withOpacity(0.45),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final mosque = mosques[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _MosqueListTile(
                                  isDark: isDark,
                                  mosque: mosque,
                                  rank: index + 1,
                                  onNavigate: () => _openNavigation(mosque),
                                  onOpenWebsite: mosque.website == null
                                      ? null
                                      : () => _launchExternal(mosque.website!),
                                ),
                              );
                            }, childCount: mosques.length),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactRadiusCard extends StatelessWidget {
  const _CompactRadiusCard({
    required this.radius,
    required this.onChanged,
    required this.isDark,
  });

  final double radius;
  final ValueChanged<double> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBgSecondary.withOpacity(0.92)
            : const Color(0xFF1F4C43).withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF1F4C43).withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar_rounded, color: Color(0xFF1F4C43), size: 15),
          const SizedBox(width: 4),
          Text(
            'Yarıçap',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF1F4C43),
              fontSize: 12,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF1F4C43),
                inactiveTrackColor: const Color(0xFF1F4C43).withOpacity(0.20),
                thumbColor: const Color(0xFF1F4C43),
                overlayColor: const Color(0xFF1F4C43).withOpacity(0.10),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: radius,
                min: 1,
                max: 25,
                divisions: 24,
                onChanged: onChanged,
              ),
            ),
          ),
          Text(
            '${radius.toStringAsFixed(0)} km',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF1F4C43),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MosqueListTile extends StatelessWidget {
  const _MosqueListTile({
    required this.isDark,
    required this.mosque,
    required this.rank,
    required this.onNavigate,
    this.onOpenWebsite,
  });

  final bool isDark;
  final Mosque mosque;
  final int rank;
  final VoidCallback onNavigate;
  final VoidCallback? onOpenWebsite;

  @override
  Widget build(BuildContext context) {
    final distKm = mosque.distance ?? 0.0;
    final distText = distKm < 1.0
        ? '${(distKm * 1000).round()} m uzaklıkta'
        : '${distKm.toStringAsFixed(1)} km uzaklıkta';

    return Material(
      color: isDark
          ? AppColors.darkBgSecondary.withOpacity(0.92)
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onNavigate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFEDE9E3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F4C43),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mosque.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mosque.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.black.withOpacity(0.50),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      distText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.darkTextLight
                    : const Color(0xFFB0A898),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMosqueState extends StatelessWidget {
  const _EmptyMosqueState({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.message,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 62, color: const Color(0xFF1F4C43)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : const Color(0xFF1F1A16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF61584E),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
