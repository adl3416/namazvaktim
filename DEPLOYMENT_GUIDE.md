# Namaz Vakitleri - Deployment & Production Guide

## 📋 Pre-Deployment Checklist

### ✅ Code Quality
- [ ] Run `flutter analyze` - No errors or warnings
- [ ] Run `flutter test` - All tests pass
- [ ] Code reviewed for performance
- [ ] No console errors or warnings in debug mode

### ✅ Testing
- [ ] Tested on Android device (physical + emulator)
- [ ] Tested on iOS device (physical + simulator)
- [ ] All features working correctly
- [ ] Notifications triggered at correct times
- [ ] Location permissions working
- [ ] Offline mode functional with cached data

### ✅ Configuration
- [ ] App name finalized: "Namaz Vakitleri"
- [ ] Version code set correctly
- [ ] All permissions configured
- [ ] API endpoints verified
- [ ] Environment variables set

### ✅ Assets & Branding
- [ ] App icon created and added
- [ ] Splash screen designed
- [ ] Screenshots prepared (at least 2-3 per platform)
- [ ] Promotional graphics ready

---

## 🏗️ Build Process

### Android Build

#### 1. Generate Keystore
```bash
cd android
keytool -genkey -v -keystore release.keystore \
  -alias release-key \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -dname "CN=Namaz Vakitleri,O=Prayer Times,C=TR"
cd ..
```

#### 2. Create Key Properties
Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=release-key
storeFile=release.keystore
```

#### 3. Update Build Configuration
Edit `android/app/build.gradle.kts`:
```kotlin
signingConfigs {
    release {
        keyAlias = keystoreProperties['keyAlias']
        keyPassword = keystoreProperties['keyPassword']
        storeFile = file(keystoreProperties['storeFile'])
        storePassword = keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.release
    }
}
```

#### 4. Build APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### 5. Build App Bundle (for Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS Build

#### 1. Update iOS Configuration
Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Namaz Vakitleri</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show prayer times for your area.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Location is used to calculate accurate prayer times.</string>

<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
```

#### 2. Update App Version
Edit `ios/Runner.xcodeproj` or use `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

#### 3. Build iOS Archive
```bash
flutter build ios --release

# If needed, create Xcode archive:
cd ios
xcodebuild archive -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive
cd ..
```

---

## 📱 App Store Submission

### Google Play Store

#### 1. Create Developer Account
- Go to [Google Play Console](https://play.google.com/console)
- Pay $25 registration fee
- Set up developer profile

#### 2. Create App Listing
```
App name: Namaz Vakitleri
Package name: com.vakit.app (or your chosen name)
Category: Health & Fitness / Lifestyle
Content rating: 3+ years
```

#### 3. Upload APK/AAB
- Upload `app-release.aab` (recommended)
- Add store listing details:
  - Title: "Namaz Vakitleri - Prayer Times"
  - Short description (80 chars)
  - Full description (4000 chars)
  - Screenshots (at least 2)
  - Feature graphic (1024x500)
  - Icon (512x512)

#### 4. Release
- Set pricing (Free recommended)
- Select countries
- Click "Release to Production"

### Apple App Store

#### 1. Create Developer Account
- Go to [Apple Developer](https://developer.apple.com)
- Pay $99/year
- Set up signing certificates

#### 2. Register App Identifier
- Bundle ID: `com.vakit.app`
- App Name: `Namaz Vakitleri`

#### 3. Create App Store Record
- In [App Store Connect](https://appstoreconnect.apple.com)
- Fill app information
- Add screenshots, descriptions

#### 4. Upload Build
```bash
# Create App Store build
flutter build ios --release

# Or use Xcode
# Product > Archive > Upload to App Store
```

#### 5. Submit for Review
- Complete app information
- Add testing notes
- Select age rating
- Submit for review (typically 24-48 hours)

---

## 🔐 Security & Performance Optimization

### Android Security
```bash
# Enable code obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### iOS Security
- Enable Bitcode: `YES` in Xcode
- Use Xcode code signing

### Performance Optimization

#### Reduce App Size
```bash
# Android
flutter build apk --release --split-per-abi

# iOS
flutter build ios --release
```

#### ProGuard Rules (Android)
Create `android/app/proguard-rules.pro`:
```
# Prayer Times API
-keep class com.example.models.** { *; }
-keep class com.example.services.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
```

---

## 📊 Monitoring & Analytics (Optional)

### Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Add Firebase to project
flutter pub add firebase_core firebase_analytics

# Configure
flutterfire configure
```

### Add Analytics
```dart
// In main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

FirebaseAnalytics analytics = FirebaseAnalytics.instance;

// Track events
analytics.logEvent(name: 'prayer_time_viewed');
analytics.logEvent(name: 'location_set', parameters: {'city': city});
```

---

## 🐛 Post-Release Support

### Monitoring Issues
1. Check user reviews and ratings
2. Monitor crash reports on Play Console / App Store Connect
3. Response time: within 24 hours

### Update Process
```bash
# Increment version
# In pubspec.yaml: version: 1.0.1+2

flutter clean
flutter pub get

# Rebuild for stores
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

---

## 📈 Marketing & Promotion

### Pre-Launch
- Create landing page/website
- Social media presence
- Beta testing with friends/community

### Launch Day
- Announce on social media
- Share in prayer time/Islamic communities
- Reddit, Instagram, Twitter posts

### Ongoing
- Respond to user feedback
- Regular updates with features
- Community engagement

---

## 💰 Monetization Options

### Free with Ads (Optional)
```bash
flutter pub add google_mobile_ads
```

### Premium Features (Optional)
- Remove ads
- Advanced statistics
- Prayer journal
- Export features

### Donation Model
- In-app donation option
- Support button in settings

---

## 🔄 CI/CD Pipeline (GitHub Actions)

Create `.github/workflows/build.yml`:
```yaml
name: Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📝 Version History

```
v1.0.0 - Initial Release
- Basic prayer times display
- Location-based timing
- Notifications
- Multi-language support (TR, EN, AR)
- Dark mode

v1.0.1 - Bug Fixes
- Location permission handling
- Notification timing accuracy
- UI refinements

v1.1.0 - New Features (Planned)
- Qibla compass
- Nearby mosques
- Prayer journal
- Advanced statistics
```

---

## ⚠️ Important Notes

1. **API Rate Limits**: AlAdhan API is free and unlimited, but consider implementing caching
2. **Notification Permissions**: iOS notifications require system permissions
3. **Location Services**: Location must be enabled for accurate prayer times
4. **Network**: App requires internet for initial setup; works offline after first sync
5. **Timezone**: App uses device timezone for prayer time calculations

---

## 🆘 Troubleshooting

### Build Fails
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter build [platform] --release
```

### Signing Issues (Android)
- Ensure keystore file exists and path is correct
- Check key.properties permissions
- Verify all keystore details

### iOS Code Signing
- Update provisioning profiles in Apple Developer
- Re-run `flutter pub get`
- Clean build: `flutter clean` then rebuild

### Store Rejection
- Check app store guidelines
- Ensure all permissions are documented
- Test on real devices
- Resubmit with detailed release notes

---

## 📞 Support & Feedback

- GitHub Issues: For bug reports
- Email: For direct support
- Social Media: For community engagement

---

**Ready for production!** Follow this guide for a smooth release process.
