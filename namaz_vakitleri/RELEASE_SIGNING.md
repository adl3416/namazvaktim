# Release Signing Notes

This file keeps a simple history of Play Store release metadata and signing details for future updates.

## Recommended Release Flow

Use this command for the next Play Store bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release_aab.ps1
```

What it does automatically:

- increases patch version and build number in `pubspec.yaml`
- keeps using the existing upload keystore from `android/key.properties`
- builds the release AAB
- appends version and signing details to this file

Useful options:

```powershell
# Build again without increasing the version
powershell -ExecutionPolicy Bypass -File .\scripts\release_aab.ps1 -BuildOnly

# Only increase version, skip the build
powershell -ExecutionPolicy Bypass -File .\scripts\release_aab.ps1 -SkipBuild
```

## Current Play Store Release Candidate

- Date: 2026-06-16
- Version name: `1.0.6`
- Version code: `10`
- `pubspec.yaml`: `1.0.6+10`
- AAB artifact: `build/app/outputs/bundle/release/app-release.aab`
- Android package: `com.vakit.app.ezanlar`
- Upload keystore: `android/upload-keystore.jks`
- Key alias: `upload`

## Signing Fingerprints

- SHA1: `6B:41:E1:E5:1D:EB:C7:5C:55:2A:09:87:13:25:23:D8:9D:E6:F9:32`
- SHA256: `65:11:55:37:CC:19:1F:36:0E:D9:F6:DC:F5:C3:BB:60:79:CC:7C:4E:9B:00:BF:68:70:A4:53:2D:66:7A:14:65`

## Previous Play Store Version

- Last known live version: `1.0.5`
- Last known live version code: `9`

## Update Safety Note

As long as future Play Store uploads continue to use the same upload keystore and alias listed above, existing users should receive updates without a signing mismatch.
