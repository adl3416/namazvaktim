# Quick Start Guide - Prayer Times App Debugging

## How to Run the App

### 1. Run Main App (Production)
```bash
cd C:\Users\Lenovo\Desktop\vakit27\namaz_vakitleri
flutter run -d <device_name>
```

Available devices:
- `SM A536B` (Android phone - RZCT40YAY0P)
- `windows` (Windows desktop)
- `chrome` (Web browser)
- `edge` (Edge browser)

### 2. Run Debug Version (Development)
```bash
flutter run -d <device_name> --target=lib/main_debug.dart
```

Debug version shows:
- Real-time initialization logs
- Provider status (loading, errors, data)
- Prayer times list
- Manual retry button

### 3. Run Tests
```bash
# Test API connectivity
dart test_api_connectivity.dart

# Test prayer parsing logic
dart test_prayer_parsing.dart
```

## Expected Output on First Launch

### Logs (should see in Flutter console):
```
🚀 App starting...
✅ Timezone initialized
✅ Notifications initialized
📱 Initializing app...
📱 PrayerProvider initializing...
📍 Attempting to get current location...
[May request permission on device]
📍 Final Location: Istanbul (41.0082, 28.9784)
🔄 Fetching prayer times for: Istanbul
📡 Fetching prayer times from: https://api.aladhan.com/v1/timings/...
📡 API Response Status: 200
✅ Parsed Prayer Times: 5 prayers
✅ Prayer Times Loaded: 5 prayers
⏭️ Next Prayer: [Prayer Name] at [Time]
```

### UI Display:
- Loading spinner briefly appears
- Then shows:
  - City name at top (Istanbul)
  - Countdown to next prayer (e.g., "Dhuhr in 3:45:20")
  - List of 5 prayers with times

## If Something Goes Wrong

### Prayer times don't appear
**Check:**
1. Logs show any error message?
2. Device has internet connection?
3. Device clock is correct?
4. Check logs for "🔄 Fetching" message

### App shows loading spinner forever
**Try:**
1. Close app and reopen
2. Check device internet connection
3. Run debug version to see status
4. Tap "Tekrar Dene" (Retry) button if visible

### Error message displayed
**Common errors:**
- "Konum mevcut değil" (Location not available)
  → Grant location permission or use city search
- "Namaz vakitleri yüklenemedi" (Prayer times failed to load)
  → Check internet connection, try retry

## Key Files Modified in This Session

| File | What Changed | Why |
|------|--------------|-----|
| `lib/models/prayer_model.dart` | Added comprehensive logging and safeguards | Trace parsing issues |
| `lib/services/aladhan_service.dart` | Added API response logging | Debug API calls |
| `lib/providers/prayer_provider.dart` | Added initialization logging | Track provider setup |
| `lib/main_debug.dart` | NEW: Debug UI | Visual debugging |
| `test_api_connectivity.dart` | NEW: API test | Verify API works |
| `test_prayer_parsing.dart` | NEW: Parsing test | Verify logic works |

## Verification Checklist

- [x] API is reachable and responds correctly
- [x] Parsing logic works with real API data
- [x] App initializes without crashes
- [x] No compile errors
- [x] Location detection falls back to Istanbul
- [x] Prayer times cached to SharedPreferences
- [x] Error handling shows user-friendly messages

## Next Testing Steps

1. **Run the app**: `flutter run -d RZCT40YAY0P`
2. **Check console logs** for the "✅ Prayer Times Loaded" message
3. **If successful**: Verify prayer list displays on screen
4. **If failed**: Note error message and check DEBUG_GUIDE.md

## Debug Version Features

When you run `lib/main_debug.dart`:
- Shows "Initializing AppSettings..."
- Shows "Initializing PrayerProvider..."
- Real-time display of provider status
- Shows prayer list as soon as loaded
- Manual "Retry Prayer Times" button

Perfect for seeing exactly what's happening without checking logs!

---

**Last Updated**: Current Session
**Status**: ✅ Ready for Device Testing
**Expected Behavior**: Prayer times load within 2 seconds on first launch
