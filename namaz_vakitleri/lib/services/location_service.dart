import 'dart:async';
import 'dart:math' as math;

import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../models/prayer_model.dart';

class LocationService {
  static GeoLocation _buildGeoLocation(
    double latitude,
    double longitude,
    geo.Placemark? place,
  ) {
    final country = place?.country ?? 'Unknown';
    final normalizedCountry = country.toLowerCase();
    final isTurkey =
        normalizedCountry == 'turkey' || normalizedCountry == 'turkiye';

    final state =
        place?.administrativeArea ?? place?.subAdministrativeArea ?? 'Unknown';
    final district = isTurkey
        ? (place?.subAdministrativeArea ??
            place?.locality ??
            place?.subLocality ??
            '')
        : (place?.subLocality ?? place?.subAdministrativeArea ?? '');
    final city = isTurkey
        ? (district.isNotEmpty
            ? district
            : (place?.locality ?? place?.administrativeArea ?? 'Unknown'))
        : (place?.locality ??
            place?.subAdministrativeArea ??
            place?.administrativeArea ??
            'Unknown');

    return GeoLocation(
      latitude: latitude,
      longitude: longitude,
      city: city,
      state: state,
      country: country,
      district: district,
    );
  }

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

  static Future<GeoLocation?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position? last = await Geolocator.getLastKnownPosition();
      final now = DateTime.now();
      if (last != null && last.timestamp != null) {
        final age = now.difference(last.timestamp!);
        if (age.inMinutes <= 5) {
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
            district: '',
          );
        }
      }

      Position? position;
      try {
        print('Requesting fresh GPS location (timeout: 45 seconds)...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 45),
        );
        print(
          'Got fresh GPS location: ${position.latitude}, ${position.longitude}',
        );
      } on TimeoutException catch (e) {
        print('Location request timed out, falling back to last known: $e');
        position = await Geolocator.getLastKnownPosition();
      } catch (e) {
        print('Error getting current position: $e');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return null;
      }

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
          district: '',
        );
      }

      return _buildGeoLocation(
        position.latitude,
        position.longitude,
        placemarks.first,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  static Future<List<GeoLocation>> searchLocation(String query) async {
    try {
      final locations = await geo.locationFromAddress(query);
      final result = <GeoLocation>[];

      for (final location in locations) {
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
                district: '',
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

  static Future<List<String>> getCitySuggestions(String partial) async {
    try {
      final locations = await geo.locationFromAddress(partial);
      return locations
          .map((loc) => '${loc.latitude}, ${loc.longitude}')
          .toList();
    } catch (e) {
      return [];
    }
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371;
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
