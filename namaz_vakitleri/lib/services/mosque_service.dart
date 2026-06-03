import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/mosque_model.dart';
import '../models/prayer_model.dart';

class MosqueService {
  static final Map<String, ({DateTime timestamp, List<Mosque> mosques})>
      _nearbyCache = {};
  static DateTime? _overpassBlockedUntil;

  static final List<Uri> _overpassMirrors = [
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://overpass.kumi.systems/api/interpreter'),
    Uri.parse('https://maps.mail.ru/osm/tools/overpass/api/interpreter'),
  ];

  static const List<String> _mosqueKeywords = [
    'cami',
    'camii',
    'mosque',
    'masjid',
    'mescit',
    'mesjid',
    'moschee',
    'ditip',
    'ditib',
  ];

  static const String _keywordRegex =
      'cami|camii|mosque|masjid|mescit|mesjid|moschee|ditip|ditib';

  static final Map<String, List<Mosque>> _fallbackMosques = {
    'Istanbul': [
      Mosque(
        name: 'Suleymaniye Camii',
        address: 'Fatih, Istanbul',
        latitude: 41.0162,
        longitude: 28.9636,
        distance: 0.0,
        phone: '+90 212 458 00 00',
        website: 'https://www.suleymaniyevakfi.org.tr/',
      ),
      Mosque(
        name: 'Fatih Camii',
        address: 'Fatih, Istanbul',
        latitude: 41.0193,
        longitude: 28.9498,
        distance: 0.0,
      ),
    ],
    'Ankara': [
      Mosque(
        name: 'Kocatepe Camii',
        address: 'Cankaya, Ankara',
        latitude: 39.9179,
        longitude: 32.8605,
        distance: 0.0,
      ),
    ],
    'Izmir': [
      Mosque(
        name: 'Hisar Camii',
        address: 'Konak, Izmir',
        latitude: 38.4199,
        longitude: 27.1287,
        distance: 0.0,
      ),
    ],
  };

  static Future<List<Mosque>> getNearbyMosques({
    required GeoLocation location,
    required double radiusKm,
  }) async {
    final cacheKey = _cacheKey(
      location.latitude,
      location.longitude,
      radiusKm,
    );
    final cached = _nearbyCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <
            const Duration(seconds: 30)) {
      return cached.mosques;
    }

    final merged = <Mosque>[];
    final probeRadii = _buildProbeRadii(radiusKm);
    final canUseOverpass =
        _overpassBlockedUntil == null ||
        DateTime.now().isAfter(_overpassBlockedUntil!);

    if (canUseOverpass) {
      for (final probeRadius in probeRadii) {
        try {
          final overpass = await _fetchFromOverpass(
            latitude: location.latitude,
            longitude: location.longitude,
            radiusKm: probeRadius,
          );
          _mergeMosques(merged, overpass, location, radiusKm);
        } catch (e) {
          _overpassBlockedUntil = DateTime.now().add(const Duration(minutes: 3));
          print('Overpass temporarily unavailable, switching to fallback search: $e');
          break;
        }
      }
    }

    try {
      final nominatim = await _fetchFromNominatim(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: radiusKm,
      );
      _mergeMosques(merged, nominatim, location, radiusKm);
    } catch (e) {
      print('Nominatim failed: $e');
    }

    if (merged.isEmpty) {
      _mergeMosques(merged, _fallbackForCity(location, radiusKm), location, radiusKm);
    }

    merged.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    _nearbyCache[cacheKey] = (
      timestamp: DateTime.now(),
      mosques: merged,
    );
    return merged;
  }

  static List<double> _buildProbeRadii(double radiusKm) {
    final radii = <double>{
      if (radiusKm > 3) 3,
      if (radiusKm > 5) 5,
      if (radiusKm > 10) 10,
      radiusKm,
    }.toList()
      ..sort();
    return radii;
  }

  static Future<List<Mosque>> _fetchFromOverpass({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final radiusMeters = (radiusKm * 1000).round();
    final query = '''
[out:json][timeout:12];
(
  nwr["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="place_of_worship"]["religion"="islam"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="place_of_worship"]["denomination"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="place_of_worship"]["place_of_worship"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="place_of_worship"]["place_of_worship"="mosque"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="community_centre"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="community_centre"]["religion"="islam"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="social_centre"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="social_centre"]["religion"="islam"](around:$radiusMeters,$latitude,$longitude);
  nwr["office"="religion"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nwr["office"="religion"]["religion"="islam"](around:$radiusMeters,$latitude,$longitude);
  nwr["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nwr["religion"="islam"](around:$radiusMeters,$latitude,$longitude);
  nwr["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="mosque"](around:$radiusMeters,$latitude,$longitude);
  nwr["place_of_worship"="mosque"](around:$radiusMeters,$latitude,$longitude);
  nwr["name"~"$_keywordRegex",i](around:$radiusMeters,$latitude,$longitude);
  nwr["name:tr"~"$_keywordRegex",i](around:$radiusMeters,$latitude,$longitude);
  nwr["official_name"~"$_keywordRegex",i](around:$radiusMeters,$latitude,$longitude);
  nwr["alt_name"~"$_keywordRegex",i](around:$radiusMeters,$latitude,$longitude);
  nwr["short_name"~"$_keywordRegex",i](around:$radiusMeters,$latitude,$longitude);
  nwr["operator"~"$_keywordRegex",i](around:$radiusMeters,$latitude,$longitude);
  nwr["brand"~"$_keywordRegex",i](around:$radiusMeters,$latitude,$longitude);
  nwr["description"~"$_keywordRegex",i](around:$radiusMeters,$latitude,$longitude);
);
out center tags;
''';

    final responses = await Future.wait(
      _overpassMirrors.map((mirror) async {
        return _callOverpassMirror(mirror, query);
      }),
    );

    final response = responses.cast<http.Response?>().firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    if (response == null || response.statusCode != 200) {
      throw Exception('All Overpass mirrors failed');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? const [];

    final results = <Mosque>[];
    final seen = <String>{};

    for (final rawElement in elements) {
      final element = rawElement as Map<String, dynamic>;
      final tags = element['tags'] as Map<String, dynamic>? ?? const {};
      final coords = _extractCoordinates(element);
      if (coords == null) continue;
      if (!_looksLikeMosque(tags)) continue;

      final distance = _calculateDistance(
        latitude,
        longitude,
        coords.$1,
        coords.$2,
      );
      if (distance > radiusKm) continue;

      final mosque = Mosque(
        name: _readName(tags, coords.$1, coords.$2),
        address: _readAddress(tags),
        latitude: coords.$1,
        longitude: coords.$2,
        distance: distance,
        phone: _readPhone(tags),
        website: _readWebsite(tags),
        prayerTimesSource: 'OpenStreetMap',
      );

      final key = _dedupeKey(mosque);
      if (seen.add(key)) {
        results.add(mosque);
      }
    }

    results.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return results;
  }

  static Future<http.Response?> _callOverpassMirror(
    Uri mirror,
    String query,
  ) async {
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'User-Agent':
          'NamazVaktimApp/1.0 (Flutter; Android; contact@namazvaktim.app)',
      'Accept': 'application/json',
    };

    try {
      final postResponse = await http
          .post(
            mirror,
            headers: headers,
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 10));
      if (postResponse.statusCode == 200) {
        return postResponse;
      }
    } catch (_) {}

    try {
      final getUri = mirror.replace(
        queryParameters: {'data': query},
      );
      final getResponse = await http
          .get(
            getUri,
            headers: {
              'User-Agent':
                  'NamazVaktimApp/1.0 (Flutter; Android; contact@namazvaktim.app)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (getResponse.statusCode == 200) {
        return getResponse;
      }
    } catch (_) {}

    return null;
  }

  static Future<List<Mosque>> _fetchFromNominatim({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final deltaLat = radiusKm / 111.0;
    final safeCos = math.max(
      0.2,
      math.cos(latitude * math.pi / 180.0).abs(),
    );
    final deltaLon = radiusKm / (111.0 * safeCos);
    final viewbox =
        '${longitude - deltaLon},${latitude + deltaLat},${longitude + deltaLon},${latitude - deltaLat}';

    final results = <Mosque>[];
    final seen = <String>{};

    final searchTerms = _mosqueKeywords.toSet().toList();
    final responses = await Future.wait(
      searchTerms.map((term) async {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search',
        ).replace(
          queryParameters: {
            'q': term,
            'format': 'jsonv2',
            'limit': '50',
            'addressdetails': '1',
            'extratags': '1',
            'namedetails': '1',
            'bounded': '1',
            'viewbox': viewbox,
          },
        );

        try {
          final response = await http.get(
            uri,
            headers: {
              'User-Agent':
                  'NamazVaktimApp/1.0 (Flutter; Android; contact@namazvaktim.app)',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 8));

          if (response.statusCode != 200) {
            return const <dynamic>[];
          }

          return jsonDecode(response.body) as List<dynamic>;
        } catch (_) {
          return const <dynamic>[];
        }
      }),
    );

    for (final responseList in responses) {
      for (final raw in responseList) {
        final el = raw as Map<String, dynamic>;
        final lat = double.tryParse(el['lat']?.toString() ?? '');
        final lon = double.tryParse(el['lon']?.toString() ?? '');
        if (lat == null || lon == null) continue;

        final dist = _calculateDistance(latitude, longitude, lat, lon);
        if (dist > radiusKm) continue;

        if (!_looksLikeNominatimMosque(el)) continue;

        final nameRaw = _readNominatimName(el);
        if (nameRaw.isEmpty) continue;

        final addr = el['address'] as Map<String, dynamic>? ?? {};
        final addrParts = <String>[
          if ((addr['road'] ?? addr['pedestrian'])?.toString().isNotEmpty == true)
            (addr['road'] ?? addr['pedestrian']).toString(),
          if (addr['suburb']?.toString().isNotEmpty == true)
            addr['suburb'].toString(),
          if ((addr['city'] ?? addr['town'] ?? addr['village'])
                  ?.toString()
                  .isNotEmpty ==
              true)
            (addr['city'] ?? addr['town'] ?? addr['village']).toString(),
        ];

        final mosque = Mosque(
          name: nameRaw,
          address:
              addrParts.isNotEmpty
                  ? addrParts.join(', ')
                  : el['display_name']?.toString().split(',').take(2).join(',') ??
                      'Adres bilgisi yok',
          latitude: lat,
          longitude: lon,
          distance: dist,
          prayerTimesSource: 'Nominatim',
        );

        final key = _dedupeKey(mosque);
        if (seen.add(key)) {
          results.add(mosque);
        }
      }
    }

    results.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return results;
  }

  static bool _looksLikeNominatimMosque(Map<String, dynamic> el) {
    final extratags = el['extratags'] as Map<String, dynamic>? ?? {};
    final namedetails = el['namedetails'] as Map<String, dynamic>? ?? {};
    final religion = extratags['religion']?.toString().toLowerCase() ?? '';
    final denomination =
        extratags['denomination']?.toString().toLowerCase() ?? '';
    final category = el['category']?.toString().toLowerCase() ?? '';
    final type = el['type']?.toString().toLowerCase() ?? '';
    final text = [
      el['name'],
      el['display_name'],
      type,
      category,
      extratags['place'],
      extratags['religion'],
      extratags['denomination'],
      extratags['official_name'],
      extratags['alt_name'],
      extratags['operator'],
      namedetails['name'],
      namedetails['official_name'],
      namedetails['short_name'],
    ].whereType<String>().join(' ').toLowerCase();

    if (type == 'mosque' || type == 'place_of_worship' || category == 'amenity') {
      if (text.contains('mosque') ||
          religion == 'muslim' ||
          religion == 'islam' ||
          denomination == 'muslim' ||
          denomination == 'islam') {
        return true;
      }
    }

    if (religion == 'muslim' ||
        religion == 'islam' ||
        denomination == 'muslim' ||
        denomination == 'islam') {
      return true;
    }

    return text.contains('mosque') ||
        text.contains('moschee') ||
        text.contains('cami') ||
        text.contains('camii') ||
        text.contains('masjid') ||
        text.contains('mescit') ||
        text.contains('mesjid') ||
        text.contains('ditip') ||
        text.contains('ditib');
  }

  static String _readNominatimName(Map<String, dynamic> el) {
    final namedetails = el['namedetails'] as Map<String, dynamic>? ?? {};
    final candidates = [
      el['name'],
      namedetails['name'],
      namedetails['official_name'],
      namedetails['short_name'],
      namedetails['name:tr'],
    ];

    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  static (double, double)? _extractCoordinates(Map<String, dynamic> element) {
    final lat = (element['lat'] as num?)?.toDouble();
    final lon = (element['lon'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      return (lat, lon);
    }

    final center = element['center'] as Map<String, dynamic>?;
    final centerLat = (center?['lat'] as num?)?.toDouble();
    final centerLon = (center?['lon'] as num?)?.toDouble();
    if (centerLat != null && centerLon != null) {
      return (centerLat, centerLon);
    }

    return null;
  }

  static String _readName(Map<String, dynamic> tags, double lat, double lon) {
    final candidates = [
      tags['name'],
      tags['name:tr'],
      tags['official_name'],
      tags['alt_name'],
      tags['short_name'],
    ];

    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Yakin cami (${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)})';
  }

  static String _readAddress(Map<String, dynamic> tags) {
    final street = tags['addr:street']?.toString();
    final number = tags['addr:housenumber']?.toString();
    final suburb = tags['addr:suburb']?.toString();
    final city = tags['addr:city']?.toString();

    final parts = <String>[
      if (street != null && street.isNotEmpty) street,
      if (number != null && number.isNotEmpty) number,
      if (suburb != null && suburb.isNotEmpty) suburb,
      if (city != null && city.isNotEmpty) city,
    ];

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    final fallback = tags['address']?.toString();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return 'Adres bilgisi yok';
  }

  static String? _readPhone(Map<String, dynamic> tags) {
    final phone = tags['phone']?.toString() ?? tags['contact:phone']?.toString();
    return phone != null && phone.isNotEmpty ? phone : null;
  }

  static String? _readWebsite(Map<String, dynamic> tags) {
    final website =
        tags['website']?.toString() ?? tags['contact:website']?.toString();
    return website != null && website.isNotEmpty ? website : null;
  }

  static bool _looksLikeMosque(Map<String, dynamic> tags) {
    final amenity = tags['amenity']?.toString().toLowerCase() ?? '';
    final building = tags['building']?.toString().toLowerCase() ?? '';
    final office = tags['office']?.toString().toLowerCase() ?? '';
    final placeOfWorship =
        tags['place_of_worship']?.toString().toLowerCase() ?? '';
    final religion = tags['religion']?.toString().toLowerCase() ?? '';
    final denomination = tags['denomination']?.toString().toLowerCase() ?? '';
    final text = [
      tags['name'],
      tags['name:tr'],
      tags['official_name'],
      tags['alt_name'],
      tags['short_name'],
      tags['loc_name'],
      tags['operator'],
      tags['brand'],
      tags['description'],
    ].whereType<String>().join(' ').toLowerCase();

    if (amenity == 'mosque' ||
        building == 'mosque' ||
        placeOfWorship == 'mosque') {
      return true;
    }

    if (amenity == 'place_of_worship' &&
        (religion == 'muslim' ||
            religion == 'islam' ||
            denomination == 'muslim' ||
            denomination == 'islam' ||
            placeOfWorship == 'muslim')) {
      return true;
    }

    if ((amenity == 'community_centre' ||
            amenity == 'social_centre' ||
            office == 'religion') &&
        (religion == 'muslim' ||
          religion == 'islam' ||
          denomination == 'muslim' ||
          denomination == 'islam' ||
            _containsMosqueKeyword(text))) {
      return true;
    }

    return _containsMosqueKeyword(text);
  }

  static bool _containsMosqueKeyword(String text) {
    return _mosqueKeywords.any((keyword) => text.contains(keyword));
  }

  static void _mergeMosques(
    List<Mosque> target,
    List<Mosque> incoming,
    GeoLocation location,
    double radiusKm,
  ) {
    for (final mosque in incoming) {
      final distance =
          mosque.distance ??
          _calculateDistance(
            location.latitude,
            location.longitude,
            mosque.latitude,
            mosque.longitude,
          );
      if (distance > radiusKm) continue;

      final normalized = Mosque(
        name: mosque.name,
        address: mosque.address,
        latitude: mosque.latitude,
        longitude: mosque.longitude,
        distance: distance,
        phone: mosque.phone,
        website: mosque.website,
        prayerTimesSource: mosque.prayerTimesSource,
      );

      final key = _dedupeKey(normalized);
      final existingIndex = target.indexWhere((item) => _dedupeKey(item) == key);
      if (existingIndex == -1) {
        target.add(normalized);
        continue;
      }

      final existing = target[existingIndex];
      if ((normalized.distance ?? double.infinity) <
          (existing.distance ?? double.infinity)) {
        target[existingIndex] = normalized;
      }
    }
  }

  static String _dedupeKey(Mosque mosque) {
    final normalizedName = mosque.name.toLowerCase().trim();
    return '${normalizedName}_${mosque.latitude.toStringAsFixed(5)}_${mosque.longitude.toStringAsFixed(5)}';
  }

  static String _cacheKey(double latitude, double longitude, double radiusKm) {
    return '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}_${radiusKm.toStringAsFixed(1)}';
  }

  static List<Mosque> _fallbackForCity(GeoLocation location, double radiusKm) {
    final cityKey = _normalizeCity(location.city);
    final source = _fallbackMosques[cityKey] ?? const <Mosque>[];

    final results =
        source
            .map(
              (mosque) => Mosque(
                name: mosque.name,
                address: mosque.address,
                latitude: mosque.latitude,
                longitude: mosque.longitude,
                distance: _calculateDistance(
                  location.latitude,
                  location.longitude,
                  mosque.latitude,
                  mosque.longitude,
                ),
                phone: mosque.phone,
                website: mosque.website,
                prayerTimesSource: 'Fallback',
              ),
            )
            .where((mosque) => (mosque.distance ?? 0) <= radiusKm)
            .toList();

    results.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return results;
  }

  static String _normalizeCity(String city) {
    return city
        .replaceAll('Ä°', 'I')
        .replaceAll('Ä±', 'i')
        .replaceAll('ÅŸ', 's')
        .replaceAll('Åž', 'S')
        .replaceAll('ÄŸ', 'g')
        .replaceAll('Äž', 'G')
        .replaceAll('Ã¼', 'u')
        .replaceAll('Ãœ', 'U')
        .replaceAll('Ã¶', 'o')
        .replaceAll('Ã–', 'O')
        .replaceAll('Ã§', 'c')
        .replaceAll('Ã‡', 'C');
  }

  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
