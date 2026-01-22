import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/prayer_model.dart';

class LocationService {
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
      if (last != null && last.timestamp != null) {
        final age = now.difference(last.timestamp!);
        if (age.inMinutes <= 5) {
          // recent enough, use it
          final placemarks = await geo.placemarkFromCoordinates(
            last.latitude,
            last.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            return GeoLocation(
              latitude: last.latitude,
              longitude: last.longitude,
              city: place.locality ?? 'Unknown',
              state: place.administrativeArea ?? 'Unknown',
              country: place.country ?? 'Unknown',
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
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
      } on TimeoutException catch (e) {
        // fallback to last known if available
        print('Location request timed out, falling back to last known: $e');
        position = await Geolocator.getLastKnownPosition();
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
      return GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: place.locality ?? 'Unknown',
        state: place.administrativeArea ?? 'Unknown',
        country: place.country ?? 'Unknown',
      );
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

        result.add(GeoLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          city: place?.locality ?? 'Unknown',
          state: place?.administrativeArea ?? 'Unknown',
          country: place?.country ?? 'Unknown',
        ));
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

  /// Calculate distance between two coordinates
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = (1 - Math.cos(dLat)) / 2 +
        Math.cos(_toRad(lat1)) *
            Math.cos(_toRad(lat2)) *
            (1 - Math.cos(dLon)) /
            2;

    final c = 2 * Math.asin(Math.sqrt(a));

    return earthRadius * c;
  }

  static double _toRad(double degree) => degree * Math.pi / 180;
}

class Math {
  static const double pi = 3.14159265359;

  static double cos(double angle) => (1 - (angle * angle) / 2 +
      (angle * angle * angle * angle) / 24 -
      (angle * angle * angle * angle * angle * angle) / 720);

  static double sin(double angle) => (angle -
      (angle * angle * angle) / 6 +
      (angle * angle * angle * angle * angle) / 120);

  static double sqrt(double value) {
    if (value < 0) return 0;
    if (value == 0) return 0;

    double x = value;
    double y = (x + 1) / 2;

    while (y < x) {
      x = y;
      y = (x + value / x) / 2;
    }

    return x;
  }

  static double asin(double value) {
    return (value * 180 / pi);
  }
}
