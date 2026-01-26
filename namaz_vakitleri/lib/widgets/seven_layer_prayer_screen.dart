import 'package:flutter/material.dart';

/// Seven layered stacked prayer screen
/// Usage: provide `cityName`, `countdownText`, `prayerTimes` map and `activePrayer` key.
class SevenLayerPrayerScreen extends StatelessWidget {
  final String cityName;
  final String countdownText;
  final Map<String, String> prayerTimes; // keys: imsak,gunes,ogle,ikindi,aksam,yatsi
  final String? activePrayer; // e.g. 'aksam'

  const SevenLayerPrayerScreen({
    Key? key,
    required this.cityName,
    required this.countdownText,
    required this.prayerTimes,
    this.activePrayer,
  }) : super(key: key);

  static const _layerColors = [
    Color(0xFFE3F2FD), // Layer 1: location & countdown
    Color(0xFFBBDEFB), // Layer 2: İmsak
    Color(0xFF90CAF9), // Layer 3: Güneş
    Color(0xFF64B5F6), // Layer 4: Öğle
    Color(0xFF42A5F5), // Layer 5: İkindi
    Color(0xFF1E88E5), // Layer 6: Akşam
    Color(0xFF1565C0), // Layer 7: Yatsı
  ];

  static const _darkBlue = Color(0xFF0D47A1);

  Widget _buildRow({
    required BuildContext context,
    required Color background,
    required Widget left,
    required Widget right,
    bool active = false,
    Color? leftColor,
    Color? rightColor,
  }) {
    final border = active
        ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
        : null;

    return Expanded(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: border,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: leftColor,
                ),
                child: left,
              ),
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: rightColor,
                  fontWeight: FontWeight.w700,
                ),
                child: right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure keys exist with fallbacks
    final imsak = prayerTimes['imsak'] ?? prayerTimes['fajr'] ?? '--:--';
    final gunes = prayerTimes['gunes'] ?? prayerTimes['sunrise'] ?? '--:--';
    final ogle = prayerTimes['ogle'] ?? prayerTimes['dhuhr'] ?? '--:--';
    final ikindi = prayerTimes['ikindi'] ?? prayerTimes['asr'] ?? '--:--';
    final aksam = prayerTimes['aksam'] ?? prayerTimes['maghrib'] ?? '--:--';
    final yatsi = prayerTimes['yatsi'] ?? prayerTimes['isha'] ?? '--:--';

    return Column(
      children: [
        // Layer 1: Location & Countdown
        _buildRow(
          context: context,
          background: _layerColors[0],
          active: activePrayer == 'sayim' || activePrayer == 'countdown',
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cityName.toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Kalan Süre',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _darkBlue),
              ),
            ],
          ),
          right: Text(
            countdownText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBlue),
          ),
          leftColor: _darkBlue,
          rightColor: _darkBlue,
        ),

        // Layer 2: İmsak
        _buildRow(
          context: context,
          background: _layerColors[1],
          left: const Text('İmsak'),
          right: Text(imsak),
          active: activePrayer == 'imsak',
          leftColor: _darkBlue,
          rightColor: _darkBlue,
        ),

        // Layer 3: Güneş
        _buildRow(
          context: context,
          background: _layerColors[2],
          left: const Text('Güneş'),
          right: Text(gunes),
          active: activePrayer == 'gunes',
          leftColor: _darkBlue,
          rightColor: _darkBlue,
        ),

        // Layer 4: Öğle
        _buildRow(
          context: context,
          background: _layerColors[3],
          left: const Text('Öğle'),
          right: Text(ogle),
          active: activePrayer == 'ogle',
          leftColor: Colors.white,
          rightColor: Colors.white,
        ),

        // Layer 5: İkindi
        _buildRow(
          context: context,
          background: _layerColors[4],
          left: const Text('İkindi'),
          right: Text(ikindi),
          active: activePrayer == 'ikindi',
          leftColor: Colors.white,
          rightColor: Colors.white,
        ),

        // Layer 6: Akşam
        _buildRow(
          context: context,
          background: _layerColors[5],
          left: const Text('Akşam'),
          right: Text(aksam),
          active: activePrayer == 'aksam',
          leftColor: Colors.white,
          rightColor: Colors.white,
        ),

        // Layer 7: Yatsı
        _buildRow(
          context: context,
          background: _layerColors[6],
          left: const Text('Yatsı'),
          right: Text(yatsi),
          active: activePrayer == 'yatsi',
          leftColor: Colors.white,
          rightColor: Colors.white,
        ),
      ],
    );
  }
}
