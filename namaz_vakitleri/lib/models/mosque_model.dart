class Mosque {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distance; // in kilometers
  final String? phone;
  final String? website;
  final String? prayerTimesSource;

  Mosque({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.phone,
    this.website,
    this.prayerTimesSource,
  });

  factory Mosque.fromJson(Map<String, dynamic> json) {
    return Mosque(
      name: json['name'] ?? 'Unknown Mosque',
      address: json['address'] ?? 'Unknown Address',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      distance: json['distance'],
      phone: json['phone'],
      website: json['website'],
      prayerTimesSource: json['prayerTimesSource'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'phone': phone,
      'website': website,
      'prayerTimesSource': prayerTimesSource,
    };
  }
}
