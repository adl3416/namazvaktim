import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/color_system.dart';
import '../models/mosque_model.dart';
import '../models/prayer_model.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../services/location_service.dart';
import '../services/mosque_service.dart';

class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  Future<List<Mosque>>? _nearbyMosquesFuture;
  final MapController _mapController = MapController();
  double _searchRadius = 10.0;
  String? _lastLocationSignature;
  String? _lastMapFitSignature;
  bool _isRefreshingLocation = false;
  GeoLocation? _mosqueSearchLocation;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tryLoadMosques(forceRefreshLocation: true),
    );
  }

  String? _locationSignature(GeoLocation? location) {
    if (location == null) {
      return null;
    }

    return '${location.latitude.toStringAsFixed(5)}_${location.longitude.toStringAsFixed(5)}_${_searchRadius.toStringAsFixed(1)}';
  }

  Future<void> _tryLoadMosques({bool forceRefreshLocation = false}) async {
    if (!mounted) return;

    if (_mosqueSearchLocation == null || forceRefreshLocation) {
      setState(() {
        _isRefreshingLocation = true;
        if (forceRefreshLocation) {
          _nearbyMosquesFuture = null;
          _lastLocationSignature = null;
        }
      });

      try {
        _mosqueSearchLocation = await LocationService.getCurrentLocation(
          preferFresh: true,
          maxLastKnownAge: const Duration(minutes: 2),
          freshTimeout: const Duration(seconds: 12),
        );
      } catch (_) {
        if (!mounted) return;
      } finally {
        if (mounted) {
          setState(() {
            _isRefreshingLocation = false;
          });
        }
      }
    }

    final location = _mosqueSearchLocation;
    final signature = _locationSignature(location);
    if (location != null &&
        signature != null &&
        (_nearbyMosquesFuture == null ||
            _lastLocationSignature != signature ||
            forceRefreshLocation)) {
      setState(() {
        _lastLocationSignature = signature;
        _nearbyMosquesFuture = MosqueService.getNearbyMosques(
          location: location,
          radiusKm: _searchRadius,
        );
      });
    }
  }

  void _updateRadius(double value) {
    setState(() {
      _searchRadius = value;
    });
  }

  void _applyRadius(double value) {
    setState(() {
      _searchRadius = value;
    });
    _tryLoadMosques(forceRefreshLocation: true);
  }

  List<Mosque> _visibleMosques(List<Mosque> source) {
    final filtered = source
        .where((mosque) => (mosque.distance ?? double.infinity) <= _searchRadius)
        .toList();
    filtered.sort((a, b) =>
        (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
    return filtered;
  }

  void _fitMapToResults(GeoLocation location, List<Mosque> mosques) {
    final points = <LatLng>[
      LatLng(location.latitude, location.longitude),
      ...mosques.map((mosque) => LatLng(mosque.latitude, mosque.longitude)),
    ];

    if (points.isEmpty) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(36),
        maxZoom: 15.5,
        minZoom: 4,
      ),
    );
  }

  Future<void> _launchExternal(String url) async {
    final normalized = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openNavigation(Mosque mosque) async {
    final locale = context.read<AppSettings>().language;
    final options = await _availableNavigationOptions(mosque);

    if (!mounted) return;

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              locale,
              tr: 'Bu cihazda acilabilecek bir navigasyon uygulamasi bulunamadi',
              en: 'No navigation app could be opened on this device',
              ar: 'No navigation app could be opened on this device',
            ),
          ),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<_NavigationOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final background = isDark ? const Color(0xFF111827) : Colors.white;
        final foreground = isDark ? Colors.white : const Color(0xFF0F172A);

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.32 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: foreground.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _text(
                      locale,
                      tr: 'Navigasyon uygulamasi sec',
                      en: 'Choose navigation app',
                      ar: 'Choose navigation app',
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mosque.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: foreground.withOpacity(0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...options.map(
                    (option) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 21,
                        backgroundColor: option.color.withOpacity(0.14),
                        child: Icon(option.icon, color: option.color),
                      ),
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                      subtitle: Text(
                        option.subtitle,
                        style: TextStyle(
                          color: foreground.withOpacity(0.62),
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: foreground.withOpacity(0.4),
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    final launched = await launchUrl(
      selected.uri,
      mode: LaunchMode.externalApplication,
    );

    if (launched) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            locale,
            tr: 'Secilen navigasyon uygulamasi acilamadi',
            en: 'The selected navigation app could not be opened',
            ar: 'The selected navigation app could not be opened',
          ),
        ),
        backgroundColor: const Color(0xFFB42318),
      ),
    );
  }

  Future<List<_NavigationOption>> _availableNavigationOptions(Mosque mosque) async {
    final lat = mosque.latitude;
    final lon = mosque.longitude;
    final encodedLabel = Uri.encodeComponent(mosque.name);
    final locale = context.read<AppSettings>().language;

    final candidates = <_NavigationOption>[
      if (Platform.isAndroid)
        _NavigationOption(
          label: 'Google Maps',
          subtitle: _text(
            locale,
            tr: 'Google Maps ile yol tarifi al',
            en: 'Get directions with Google Maps',
            ar: 'Get directions with Google Maps',
          ),
          icon: Icons.map_rounded,
          color: const Color(0xFF1A73E8),
          uri: Uri.parse('google.navigation:q=$lat,$lon'),
        ),
      if (Platform.isIOS)
        _NavigationOption(
          label: 'Apple Maps',
          subtitle: _text(
            locale,
            tr: 'Apple Maps ile yol tarifi al',
            en: 'Get directions with Apple Maps',
            ar: 'Get directions with Apple Maps',
          ),
          icon: Icons.map_outlined,
          color: const Color(0xFF111827),
          uri: Uri.parse('http://maps.apple.com/?daddr=$lat,$lon&dirflg=d'),
        ),
      _NavigationOption(
        label: 'Waze',
        subtitle: _text(
          locale,
          tr: 'Waze ile trafik destekli rota ac',
          en: 'Open a traffic-aware route with Waze',
          ar: 'Open a traffic-aware route with Waze',
        ),
        icon: Icons.alt_route_rounded,
        color: const Color(0xFF33CCFF),
        uri: Uri.parse('waze://?ll=$lat,$lon&navigate=yes'),
      ),
      if (Platform.isAndroid)
        _NavigationOption(
          label: _text(
            locale,
            tr: 'Haritalar',
            en: 'Maps',
            ar: 'Maps',
          ),
          subtitle: _text(
            locale,
            tr: 'Cihazin varsayilan harita uygulamasini kullan',
            en: 'Use the device default map app',
            ar: 'Use the device default map app',
          ),
          icon: Icons.place_rounded,
          color: const Color(0xFF0F766E),
          uri: Uri.parse('geo:$lat,$lon?q=$lat,$lon($encodedLabel)'),
        ),
      _NavigationOption(
        label: _text(
          locale,
          tr: 'Tarayicida Google Maps',
          en: 'Google Maps in browser',
          ar: 'Google Maps in browser',
        ),
        subtitle: _text(
          locale,
          tr: 'Uygulama yoksa web uzerinden ac',
          en: 'Open on the web if no app is available',
          ar: 'Open on the web if no app is available',
        ),
        icon: Icons.public_rounded,
        color: const Color(0xFF2563EB),
        uri: Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
        ),
      ),
    ];

    final available = <_NavigationOption>[];
    for (final option in candidates) {
      if (await canLaunchUrl(option.uri)) {
        available.add(option);
      }
    }
    return available;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, PrayerProvider>(
      builder: (context, settings, prayerProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final locale = settings.language;
        final location = _mosqueSearchLocation;
        final locationSignature = _locationSignature(location);

        if (locationSignature != null &&
            (_nearbyMosquesFuture == null ||
                _lastLocationSignature != locationSignature)) {
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
                  final mosques = _visibleMosques(
                    snapshot.data ?? const <Mosque>[],
                  );

                  if (location != null && mosques.isNotEmpty) {
                    final mapFitSignature =
                        '${location.latitude.toStringAsFixed(5)}_${location.longitude.toStringAsFixed(5)}_${mosques.length}_${_searchRadius.toStringAsFixed(1)}';
                    if (_lastMapFitSignature != mapFitSignature) {
                      _lastMapFitSignature = mapFitSignature;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _fitMapToResults(location, mosques);
                      });
                    }
                  }

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
                                              _text(
                                                locale,
                                                tr: 'Yakındaki Camiler',
                                                en: 'Nearby Mosques',
                                                ar: 'المساجد القريبة',
                                              ),
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
                                            _text(
                                              locale,
                                              tr: '${location.city} çevresinde',
                                              en: 'Around ${location.city}',
                                              ar: 'حول ${location.city}',
                                            ),
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
                                  IconButton(
                                    onPressed: _isRefreshingLocation
                                        ? null
                                        : () => _tryLoadMosques(
                                              forceRefreshLocation: true,
                                            ),
                                    tooltip: _text(
                                      locale,
                                      tr: 'Konumu bul ve tara',
                                      en: 'Find location and scan',
                                      ar: 'Find location and scan',
                                    ),
                                    icon: _isRefreshingLocation
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : const Color(0xFF1F1A16),
                                            ),
                                          )
                                        : Icon(
                                            Icons.my_location_rounded,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : const Color(0xFF1F1A16),
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _CompactRadiusCard(
                                 radius: _searchRadius,
                                 onChanged: _updateRadius,
                                 onChangeEnd: _applyRadius,
                                 isDark: isDark,
                                 locale: locale,
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
                            locale: locale,
                            icon: Icons.location_off_rounded,
                            title: _text(
                              locale,
                              tr: 'Konum gerekli',
                              en: 'Location required',
                              ar: 'الموقع مطلوب',
                            ),
                            message: _text(
                              locale,
                              tr: 'Yakındaki camileri görebilmek için uygulamanın konum iznine ihtiyacı var.',
                              en: 'The app needs location permission to show nearby mosques.',
                              ar: 'يحتاج التطبيق إلى إذن الموقع لعرض المساجد القريبة.',
                            ),
                            actionLabel: _text(
                              locale,
                              tr: 'Konumu bul',
                              en: 'Find location',
                              ar: 'Find location',
                            ),
                            onAction: _isRefreshingLocation
                                ? null
                                : () => _tryLoadMosques(
                                      forceRefreshLocation: true,
                                    ),
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
                            locale: locale,
                            icon: Icons.error_outline_rounded,
                            title: _text(
                              locale,
                              tr: 'Liste yüklenemedi',
                              en: 'List could not load',
                              ar: 'تعذر تحميل القائمة',
                            ),
                            message: 'Hata: ${snapshot.error}',
                          ),
                        )
                      else if (mosques.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyMosqueState(
                            isDark: isDark,
                            locale: locale,
                            icon: Icons.travel_explore_rounded,
                            title: _text(
                              locale,
                              tr: 'Bu alanda sonuç yok',
                              en: 'No results in this area',
                              ar: 'لا توجد نتائج في هذه المنطقة',
                            ),
                            message: _text(
                              locale,
                              tr: 'Arama yarıçapını genişleterek daha fazla cami görebilirsin.',
                              en: 'You can widen the search radius to see more mosques.',
                              ar: 'يمكنك توسيع نطاق البحث لرؤية المزيد من المساجد.',
                            ),
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
                                  mapController: _mapController,
                                  key: ValueKey(
                                    '${locationSignature}_${mosques.length}_${_searchRadius.toStringAsFixed(1)}',
                                  ),
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
                              _text(
                                locale,
                                tr: 'En yakından sıralandı',
                                en: 'Sorted by nearest',
                                ar: 'مرتبة حسب الأقرب',
                              ),
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
                                  locale: locale,
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

class _NavigationOption {
  const _NavigationOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.uri,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Uri uri;
}

class _CompactRadiusCard extends StatelessWidget {
  const _CompactRadiusCard({
    required this.radius,
    required this.onChanged,
    required this.onChangeEnd,
    required this.isDark,
    required this.locale,
  });

  final double radius;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final bool isDark;
  final String locale;

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
            locale == 'tr'
                ? 'Yarıçap'
                : locale == 'ar'
                    ? 'النطاق'
                    : 'Radius',
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
                onChangeEnd: onChangeEnd,
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
    required this.locale,
    required this.mosque,
    required this.rank,
    required this.onNavigate,
    this.onOpenWebsite,
  });

  final bool isDark;
  final String locale;
  final Mosque mosque;
  final int rank;
  final VoidCallback onNavigate;
  final VoidCallback? onOpenWebsite;

  @override
  Widget build(BuildContext context) {
    final distKm = mosque.distance ?? 0.0;
    final distText = distKm < 1.0
        ? locale == 'tr'
            ? '${(distKm * 1000).round()} m uzaklıkta'
            : locale == 'ar'
                ? 'يبعد ${(distKm * 1000).round()} م'
                : '${(distKm * 1000).round()} m away'
        : locale == 'tr'
            ? '${distKm.toStringAsFixed(1)} km uzaklıkta'
            : locale == 'ar'
                ? 'يبعد ${distKm.toStringAsFixed(1)} كم'
                : '${distKm.toStringAsFixed(1)} km away';

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
    required this.locale,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final bool isDark;
  final String locale;
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.my_location_rounded),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F4C43),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
