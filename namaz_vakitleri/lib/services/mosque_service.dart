import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/mosque_model.dart';
import '../models/prayer_model.dart';

class MosqueService {
  static final List<Uri> _overpassMirrors = [
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://overpass.kumi.systems/api/interpreter'),
    Uri.parse('https://maps.mail.ru/osm/tools/overpass/api/interpreter'),
  ];

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
  static const List<String> _mosqueKeywords = [
    'mosque', 'masjid', 'masjed', 'masdjid', 'cami', 'camii', 'jami',
    'mescit', 'mesjid', 'musalla', 'جامع', 'مسجد', 'جماعت', 'muslim', 'islam',
  ];

  static Future<List<Mosque>> getNearbyMosques({
    required GeoLocation location,
    required double radiusKm,
  }) async {
    final radii = <double>{
      if (radiusKm > 3) 3.0,
      if (radiusKm > 5) 5.0,
      radiusKm,
    }.toList()
      ..sort();

    for (final probeRadius in radii) {
      try {
        final results = await _fetchFromOverpass(
          latitude: location.latitude,
          longitude: location.longitude,
          radiusKm: probeRadius,
        );
        if (results.isNotEmpty) return results;
      } catch (e) {
        print('Overpass failed for ${probeRadius}km: $e');
      }
    }

    try {
      final results = await _fetchFromNominatim(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: radiusKm,
      );
      if (results.isNotEmpty) return results;
    } catch (e) {
      print('Nominatim failed: $e');
    }

    // 3. Hardcoded city fallback
    return _fallbackForCity(location, radiusKm);
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
  nwr["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="mosque"](around:$radiusMeters,$latitude,$longitude);
  nwr["place_of_worship"="mosque"](around:$radiusMeters,$latitude,$longitude);
  nwr["name"~"cami|camii|mosque|masjid|mescit|mesjid",i](around:$radiusMeters,$latitude,$longitude);
);
out center tags;
''';

    http.Response? response;
    Object? lastError;
    for (final mirror in _overpassMirrors) {
      try {
        response = await http
            .post(
              mirror,
              headers: {
                'Content-Type':
                    'application/x-www-form-urlencoded; charset=UTF-8',
                'User-Agent':
                    'NamazVaktimApp/1.0 (Flutter; Android; contact@namazvaktim.app)',
                'Accept': 'application/json',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) break;
        lastError = Exception('Overpass error: ${response.statusCode}');
      } catch (e) {
        lastError = e;
        response = null;
        continue;
      }
    }

    if (response == null || response.statusCode != 200) {
      throw lastError ?? Exception('All Overpass mirrors failed');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List<dynamic>? ?? const []);

    final results = <Mosque>[];
    final seen = <String>{};

    for (final rawElement in elements) {
      final element = rawElement as Map<String, dynamic>;
      final tags = element['tags'] as Map<String, dynamic>? ?? const {};
      final coords = _extractCoordinates(element);

      if (coords == null) continue;
      if (!_looksLikeMosque(tags)) continue;

      final mosque = Mosque(
        name: _readName(tags, coords.$1, coords.$2),
        address: _readAddress(tags),
        latitude: coords.$1,
        longitude: coords.$2,
        distance: _calculateDistance(
          latitude,
          longitude,
          coords.$1,
          coords.$2,
        ),
        phone: _readPhone(tags),
        website: _readWebsite(tags),
        prayerTimesSource: 'OpenStreetMap',
      );

      final key =
          '${mosque.name}_${mosque.latitude.toStringAsFixed(5)}_${mosque.longitude.toStringAsFixed(5)}';
      if (seen.add(key)) {
        results.add(mosque);
      }
    }

    results.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return results;
  }

  static Future<List<Mosque>> _fetchFromNominatim({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final deltaLat = radiusKm / 111.0;
    final deltaLon =
        radiusKm / (111.0 * math.cos(latitude * math.pi / 180.0));

    // viewbox format: left,top,right,bottom (lon_min,lat_max,lon_max,lat_min)
    final viewbox =
        '${longitude - deltaLon},${latitude + deltaLat},${longitude + deltaLon},${latitude - deltaLat}';

    final uri =
        Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'amenity': 'place_of_worship',
        'format': 'json',
        'limit': '50',
        'addressdetails': '1',
        'extratags': '1',
        'bounded': '1',
        'viewbox': viewbox,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'NamazVaktimApp/1.0 (Flutter; Android; contact@namazvaktim.app)',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Nominatim error: ${response.statusCode}');
    }

    final elements = jsonDecode(response.body) as List<dynamic>;
    final results = <Mosque>[];
    final seen = <String>{};

    // Common mosque name keywords across languages for worldwide filtering
    const _mosqueKeywords = [
      'mosque', 'masjid', 'masjed', 'masdjid', 'cami', 'camii', 'jami',
      'جامع', 'مسجد', 'جماعت', 'namaz', 'islam', 'muslim',
    ];

    for (final raw in elements) {
      final el = raw as Map<String, dynamic>;
      final lat = double.tryParse(el['lat']?.toString() ?? '');
      final lon = double.tryParse(el['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final dist = _calculateDistance(latitude, longitude, lat, lon);
      if (dist > radiusKm) continue;

      // Filter to Muslim places only via extratags or name keywords
      final extratags =
          el['extratags'] as Map<String, dynamic>? ?? {};
      final religion = extratags['religion']?.toString().toLowerCase() ?? '';
      final denomination =
          extratags['denomination']?.toString().toLowerCase() ?? '';
      final nameRaw = el['name']?.toString().trim() ?? '';
      final nameLower = nameRaw.toLowerCase();

      final isMosque = religion == 'muslim' ||
          religion == 'islam' ||
          denomination == 'muslim' ||
          _mosqueKeywords.any((kw) => nameLower.contains(kw));
      if (!isMosque || nameRaw.isEmpty) continue;

      final addr = el['address'] as Map<String, dynamic>? ?? {};
      final name = nameRaw;

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
        name: name,
        address: addrParts.isNotEmpty
            ? addrParts.join(', ')
            : el['display_name']?.toString().split(',').take(2).join(',') ??
                'Adres bilgisi yok',
        latitude: lat,
        longitude: lon,
        distance: dist,
        prayerTimesSource: 'Nominatim',
      );

      final key = '${lat.toStringAsFixed(5)}_${lon.toStringAsFixed(5)}';
      if (seen.add(key)) results.add(mosque);
    }

    results.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return results;
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
    final religion = tags['religion']?.toString().toLowerCase() ?? '';
    final denomination = tags['denomination']?.toString().toLowerCase() ?? '';
    final amenity = tags['amenity']?.toString().toLowerCase() ?? '';
    final building = tags['building']?.toString().toLowerCase() ?? '';
    final placeOfWorship =
        tags['place_of_worship']?.toString().toLowerCase() ?? '';
    final names = [
      tags['name'],
      tags['name:tr'],
      tags['official_name'],
      tags['alt_name'],
    ]
        .whereType<String>()
        .join(' ')
        .toLowerCase();

    if (religion == 'muslim' || religion == 'islam') return true;
    if (denomination == 'muslim') return true;
    if (amenity == 'mosque' ||
        building == 'mosque' ||
        placeOfWorship == 'mosque') {
      return true;
    }

    return _mosqueKeywords.any((keyword) => names.contains(keyword));
  }

  static List<Mosque> _fallbackForCity(GeoLocation location, double radiusKm) {
    final cityKey = _normalizeCity(location.city);
    final source = _fallbackMosques[cityKey] ?? const <Mosque>[];

    final results = source
        .map((mosque) => Mosque(
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
            ))
        .where((mosque) => (mosque.distance ?? 0) <= radiusKm)
        .toList();

    results.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return results;
  }

  static String _normalizeCity(String city) {
    return city
        .replaceAll('İ', 'I')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C');
  }

  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
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
