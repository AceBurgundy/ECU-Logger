---
id: scaffold-and-assets
title: Scaffold Flutter Project & Asset Pipeline
type: implementation
status: ready
revision: 1
depends_on: []
touches:
  - pubspec.yaml
  - assets/fonts/**
  - android/app/src/main/AndroidManifest.xml
---

# Scaffold Flutter Project & Asset Pipeline

## Summary
Scaffolds the `ecu_logger` Flutter project structure, copies custom fonts (`GoogleSans-Regular.ttf`, `GoogleSansCode-Regular.ttf`, `CanelaText-Regular.otf` from `D:\Documents\fonts`), configures pubspec assets and permissions in `AndroidManifest.xml`.

## Tasks
1. Run `flutter create --org com.antigravity.ecu --platforms android ecu_logger`.
2. Copy font families from `D:\Documents\fonts` to `assets/fonts/`:
   - `GoogleSans-Regular.ttf` -> `assets/fonts/GoogleSans-Regular.ttf`
   - `GoogleSansCode-Regular.ttf` -> `assets/fonts/GoogleSansCode-Regular.ttf`
   - `CanelaText-*.otf` -> `assets/fonts/CanelaText-Regular.otf`
3. Configure `pubspec.yaml` with:
   - `flutter_blue_plus: ^2.1.0`
   - `permission_handler: ^12.0.1`
   - `path_provider: ^2.1.5`
   - `intl: ^0.20.2`
   - font asset declarations for `Google Sans`, `Google Sans Code`, and `Canela`.
4. Configure `AndroidManifest.xml` with Bluetooth, Location, and Storage permissions.

## Verification
- `flutter pub get` exits 0.
- `flutter build apk --debug` builds successfully.
