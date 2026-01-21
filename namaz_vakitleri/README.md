# Namaz Vakitleri - Flutter Prayer Times App

A beautiful, modern Flutter application for displaying Islamic prayer times with a soft pastel design aesthetic.

## Features

✨ **Design Philosophy**
- Soft, continuous canvas with no hard boxes or containers
- Tailwind-like utility styling system
- Calming pastel color palette
- Seamless spiritual atmosphere

🕌 **Prayer Times**
- Real-time countdown to next prayer
- Complete daily prayer schedule (Fajr, Dhuhr, Asr, Maghrib, Isha)
- AlAdhan Prayer Times API integration (Diyanet method for Turkey)
- Offline-first with local caching
- Monthly data prefetching

🧭 **Navigation & Location**
- Automatic location detection
- City search functionality
- Qibla direction finder with compass
- Nearby mosque discovery

⏰ **Notifications & Reminders**
- Scheduled prayer time notifications
- Customizable Adhan sound
- Local notifications support
- Timezone-aware timing

🌍 **Internationalization**
- Turkish (Türkçe)
- English
- Arabic (العربية) with RTL support
- System language auto-detection

🎨 **Customization**
- Light/Dark/System theme modes
- Language selection
- Notification preferences
- Adhan sound toggle

## Project Structure

```
lib/
├── config/
│   ├── color_system.dart      # Design tokens, colors, typography, spacing
│   └── localization.dart      # Multi-language support
├── models/
│   └── prayer_model.dart      # Data models for prayers and locations
├── providers/
│   ├── app_settings.dart      # Settings state management
│   └── prayer_provider.dart   # Prayer times state management
├── services/
│   ├── aladhan_service.dart   # Prayer times API integration
│   ├── location_service.dart  # Geolocation and geocoding
│   └── notification_service.dart # Local notifications
├── screens/
│   └── home_screen.dart       # Main application screen
├── widgets/
│   └── common_widgets.dart    # Reusable UI components
└── main.dart                  # App entry point
```

## Dependencies

- **State Management**: Provider
- **HTTP**: http
- **Local Storage**: shared_preferences, sqflite
- **Notifications**: flutter_local_notifications, timezone
- **Location**: geolocator, geocoding
- **UI**: flutter_svg, animations

## Getting Started

### Prerequisites
- Flutter SDK 3.6.0+
- Android SDK (for Android development)
- iOS SDK (for iOS development)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd namaz_vakitleri
```

2. Get dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Color System

### Light Mode Palette
- **Base**: Soft cream (#FEFBf8)
- **Text Primary**: Dark gray (#3A3A3A)
- **Text Secondary**: Medium gray (#8B8B8B)
- **Accents**: Warm tan, soft peach, muted orange

### Dark Mode Palette
- **Base**: Very dark (#1A1A1A)
- **Text Primary**: Light gray (#E8E8E8)
- **Text Secondary**: Medium gray (#9B9B9B)
- **Accents**: Warm tans (darker shades)

Each prayer time has a subtle pastel tint that transitions smoothly when active.

## API Usage

Uses **AlAdhan Prayer Times API** with method 13 (Diyanet - Turkey/Hanafi school).

```
Endpoint: https://api.aladhan.com/v1/timings/{date}
Parameters: latitude, longitude, method=13
```

## Notifications

- Scheduled via local notifications
- Uses device timezone
- Customizable per user preference
- Supports Adhan sound playback

## Permissions Required

- **Android**:
  - `INTERNET` - For API calls
  - `ACCESS_FINE_LOCATION` - For user location
  - `ACCESS_COARSE_LOCATION` - For approximate location
  - `POST_NOTIFICATIONS` - For notification display
  - `SCHEDULE_EXACT_ALARM` - For precise notification timing

- **iOS**:
  - `NSLocationWhenInUseUsageDescription` - For location access
  - Notification permissions (requested at runtime)

## Configuration

Settings are stored in SharedPreferences:
- `language` - User's preferred language
- `themeMode` - Theme preference (light/dark/system)
- `city` - Last selected city
- `country` - Last selected country
- `enableAdhanSound` - Adhan notification sound
- `enablePrayerNotifications` - Prayer time notifications toggle

## Performance Optimizations

- Monthly prayer times prefetching
- Local caching with SharedPreferences
- Efficient countdown calculation
- Optimized build methods with selectors
- No unnecessary rebuilds

## Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Future Enhancements

- [ ] Qibla compass (currently placeholder)
- [ ] Nearby mosques map integration
- [ ] Advanced notification customization
- [ ] Prayer journal/history
- [ ] Widgets for home screen
- [ ] Health/Prayer streak tracking
- [ ] Alternative prayer calculation methods
- [ ] Offline map for nearby mosques

## Troubleshooting

**Issue**: Location permission denied
- **Solution**: Check app settings and grant location permissions

**Issue**: Prayer times not updating
- **Solution**: Check internet connection, ensure API is accessible

**Issue**: Notifications not showing
- **Solution**: Verify notification permissions are granted in app settings

## Contributing

Contributions are welcome! Please follow the established code style and add tests for new features.

## License

This project is open source and available under the MIT License.

## Support

For issues, feature requests, or questions, please open an issue on the repository.

---

**Built with ❤️ for the Muslim community**
