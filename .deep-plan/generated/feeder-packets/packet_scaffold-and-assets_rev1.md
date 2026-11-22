# IMPLEMENTATION PACKET: scaffold-and-assets
**Revision**: 1 | **Generated**: 2026-11-22T04:51:13.072602+00:00
**Estimated Tokens**: ~493 / Budget: 8000

---
## CONTEXT PROVENANCE
- Tier 4 [scaffold-and-assets.md]: Target contract
- Tier 0 [core.md]: Global invariants

---

## GLOBAL INVARIANTS (core):
- The application is strictly a dedicated, decoupled logger (ecu_logger); it does not attempt ECU ROM flash writing.
- Logging operates autonomously upon BLE connection regardless of motorcycle ignition/engine status.
- All status messages and operational warnings are displayed exclusively as top-centered toast bubbles.
- The UI strictly adheres to GitHub design aesthetics (dark/light Primer palette, line icons, clean cards).
- Fonts are strictly bound: Canela for App Title, Google Sans for General UI, Google Sans Code for Loggers/Hex.
- Lock screen provides a full-page translucent overlay with a dynamic 4-digit numeric keypad, keeping the live logging dashboard visible underneath.
- Auto-save is guaranteed on BLE disconnect, app pause, or app backgrounding to prevent data loss.


# CURRENT PLAN: Scaffold Flutter Project & Asset Pipeline

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
