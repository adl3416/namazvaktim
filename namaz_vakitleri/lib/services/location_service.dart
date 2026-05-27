import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/prayer_model.dart';

class LocationService {
  static GeoLocation _buildGeoLocation(
    double latitude,
    double longitude,
    geo.Placemark? place,
  ) {
    final country = place?.country ?? 'Unknown';
    final normalizedCountry = country.toLowerCase();
    final isTurkey = normalizedCountry == 'turkey' ||
        normalizedCountry == 'türkiye';
    final city = isTurkey
        ? (place?.subAdministrativeArea ??
            place?.locality ??
            place?.administrativeArea ??
            'Unknown')
        : (place?.locality ??
            place?.subAdministrativeArea ??
            place?.administrativeArea ??
            'Unknown');
    final state = place?.administrativeArea ??
        place?.subAdministrativeArea ??
        'Unknown';

    return GeoLocation(
      latitude: latitude,
      longitude: longitude,
      city: city,
      state: state,
      country: country,
    );
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current location
  static Future<GeoLocation?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      // Try a quick last-known position first to avoid waiting on slow GPS startups
      Position? last = await Geolocator.getLastKnownPosition();
      final now = DateTime.now();
      if (last != null) {
        final age = now.difference(last.timestamp);
        if (age.inMinutes <= 5) {
          // recent enough, use it
          final placemarks = await geo.placemarkFromCoordinates(
            last.latitude,
            last.longitude,
          );
          if (placemarks.isNotEmpty) {
            return _buildGeoLocation(
              last.latitude,
              last.longitude,
              placemarks.first,
            );
          }
          return GeoLocation(
            latitude: last.latitude,
            longitude: last.longitude,
            city: 'Unknown',
            state: 'Unknown',
            country: 'Unknown',
          );
        }
      }

      // If last-known is stale or missing, ask for a fresh position but allow a longer timeout
      Position? position;
      try {
        print('📍 Requesting fresh GPS location (timeout: 45 seconds)...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 45), // Increased timeout for slower connections
        );
        print(
          '✅ Got fresh GPS location: ${position.latitude}, ${position.longitude}',
        );
      } on TimeoutException catch (e) {
        // fallback to last known if available
        print('⏰ Location request timed out, falling back to last known: $e');
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          print(
            '📍 Using last known position: ${position.latitude}, ${position.longitude}',
          );
        }
      } catch (e) {
        print('❌ Error getting current position: $e');
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          print(
            '📍 Fallback to last known position: ${position.latitude}, ${position.longitude}',
          );
        }
      }

      if (position == null) return null;

      final placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return GeoLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          city: 'Unknown',
          state: 'Unknown',
          country: 'Unknown',
        );
      }

      final place = placemarks.first;
      return _buildGeoLocation(position.latitude, position.longitude, place);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Search for a location by city name
  static Future<List<GeoLocation>> searchLocation(String query) async {
    try {
      final locations = await geo.locationFromAddress(query);
      final result = <GeoLocation>[];

      for (var location in locations) {
        final placemarks = await geo.placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        final place = placemarks.isNotEmpty ? placemarks.first : null;
        final resolved = place == null
            ? GeoLocation(
                latitude: location.latitude,
                longitude: location.longitude,
                city: 'Unknown',
                state: 'Unknown',
                country: 'Unknown',
              )
            : _buildGeoLocation(location.latitude, location.longitude, place);

        result.add(resolved);
      }

      return result;
    } catch (e) {
      print('Error searching location: $e');
      return [];
    }
  }

  /// Get city suggestions based on partial input
  static Future<List<String>> getCitySuggestions(String partial) async {
    // This would typically use a city database or API
    // For now, returning empty - can be expanded with a database
    try {
      final locations = await geo.locationFromAddress(partial);
      return locations
          .map((loc) => '${loc.latitude}, ${loc.longitude}')
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  static double _toRad(double degree) => degree * math.pi / 180;
}
