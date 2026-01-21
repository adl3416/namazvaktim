## SETUP INSTRUCTIONS - Namaz Vakitleri

### 🎯 Quick Start

1. **Install Flutter**
   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   flutter doctor  # Check setup
   ```

2. **Dependencies Already Installed**
   ```bash
   flutter pub get  # Already done ✓
   ```

3. **Run the App**
   ```bash
   # Android
   flutter run
   
   # iOS
   cd ios && pod install && cd ..
   flutter run
   ```

### 📦 What's Been Built

✅ **Design System** (`lib/config/color_system.dart`)
- Soft pastel colors (light & dark modes)
- Typography system with custom styles
- Spacing utilities (Tailwind-like)
- Opacity levels and border radius tokens

✅ **Localization** (`lib/config/localization.dart`)
- Turkish (Türkçe)
- English 
- Arabic (العربية) with RTL support
- Auto-detection of system language

✅ **Data Models** (`lib/models/prayer_model.dart`)
- PrayerTime
- PrayerTimes (for a full day)
- GeoLocation
- Mosque

✅ **Services**
- `aladhan_service.dart` - AlAdhan Prayer Times API integration
- `location_service.dart` - Geolocation and city search
- `notification_service.dart` - Local notifications with Adhan support

✅ **State Management** (Provider Pattern)
- `app_settings.dart` - User preferences (language, theme, notifications)
- `prayer_provider.dart` - Prayer times and location state

✅ **UI Components** (`lib/widgets/common_widgets.dart`)
- SoftButton - No harsh styling
- SoftIconButton - Icon-only buttons
- PrayerTimeRow - Prayer time display
- CountdownDisplay - Large countdown timer

✅ **Main Screen** (`lib/screens/home_screen.dart`)
- Top bar with settings, location, qibla
- Countdown to next prayer
- Prayer times list
- Nearby mosques button
- Settings modal with all options

### 🎨 Design Philosophy Implemented

- ✅ NO cards
- ✅ NO containers with borders
- ✅ NO sharp outlines
- ✅ NO elevated surfaces
- ✅ Soft, continuous canvas feel
- ✅ Opacity and subtle tints for separation
- ✅ Calm, spiritual aesthetic

### 🌐 API Setup

Using **AlAdhan Prayer Times API**:
- Method 13 (Diyanet - Turkey/Hanafi)
- Automatic caching
- Offline support
- Monthly prefetch option

No API key required!

### 📱 Platform-Specific Setup

#### Android
**Already configured in**: `android/app/src/main/AndroidManifest.xml`

Required permissions:
- ✅ INTERNET
- ✅ ACCESS_FINE_LOCATION
- ✅ ACCESS_COARSE_LOCATION
- ✅ POST_NOTIFICATIONS
- ✅ SCHEDULE_EXACT_ALARM

#### iOS
**Update**: `ios/Runner/Info.plist`

Add these keys:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show prayer times for your area.</string>

<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
```

### 🔧 Configuration Files

**pubspec.yaml** - All dependencies installed
```
✅ provider (state management)
✅ http (API calls)
✅ shared_preferences (local storage)
✅ flutter_local_notifications
✅ geolocator & geocoding
✅ flutter_compass
✅ intl (i18n)
✅ timezone
```

### 🚀 Next Steps (Features to Complete)

1. **Qibla Compass**
   - Already has placeholder button
   - Use `flutter_compass` for real compass direction
   - Calculate qibla angle from user location

2. **Nearby Mosques**
   - Placeholder button ready
   - Can use Google Places API or OpenStreetMap
   - Show list and map view

3. **Refine Colors**
   - Current palette is based on your description
   - **ATTACH REFERENCE IMAGE** to match exact colors
   - All color tokens are in `color_system.dart`

4. **Testing**
   - Build APK/IPA
   - Test on actual devices
   - Verify notifications work

5. **Customization**
   - Font choices (currently using generic Dart fonts)
   - Add custom fonts if desired
   - Fine-tune spacing and sizing

### 📝 File Locations

```
namaz_vakitleri/
├── lib/
│   ├── config/          # Design system & localization
│   ├── models/          # Data structures
│   ├── providers/       # State management
│   ├── services/        # API & location services
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable components
│   └── main.dart        # Entry point
├── android/
│   └── app/src/main/AndroidManifest.xml  # ✅ Permissions configured
├── ios/
│   ├── Runner/Info.plist  # Add location description
│   └── Podfile            # CocoaPods dependencies
└── pubspec.yaml         # ✅ All dependencies installed
```

### ⚠️ Important Notes

1. **Location Permissions**: App will request on first run
2. **Notifications**: Android 13+ requires runtime permission
3. **Offline Mode**: Prayer times cached locally after first fetch
4. **RTL Support**: Arabic language automatically sets RTL layout direction
5. **Timezone**: Uses device timezone for notifications

### 🐛 Troubleshooting

**Issue**: "flutter command not found"
```bash
# Add Flutter to PATH (Windows)
# Find Flutter installation and add to Environment Variables
```

**Issue**: Android build errors
```bash
flutter clean
flutter pub get
flutter run
```

**Issue**: iOS Pod issues
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run
```

**Issue**: Location not working
- Check permissions in app settings
- Grant location access for the app

### 📊 Build Commands

```bash
# Development
flutter run

# Production Android
flutter build apk --release

# Production Android (App Bundle)
flutter build appbundle --release

# Production iOS
flutter build ios --release
```

### 🎯 Current Status

- ✅ Project structure complete
- ✅ Design system implemented
- ✅ All services integrated
- ✅ State management set up
- ✅ Main UI screen created
- ✅ Localization configured
- ✅ Android permissions set
- ⏳ iOS Info.plist configuration needed
- ⏳ Color refinement (needs reference image)
- ⏳ Qibla compass implementation
- ⏳ Nearby mosques feature

### 📧 Next Action

**⚠️ PLEASE PROVIDE THE REFERENCE IMAGE** mentioned in your requirements so I can:
1. Match exact colors perfectly
2. Adjust layout/spacing to match
3. Verify UI hierarchy matches your vision

---

**Ready to run!** Just execute `flutter run` to see the app in action.
