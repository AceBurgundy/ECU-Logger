---
id: architecture-core
title: ECU Logger Core Architecture & Invariants
type: architecture
status: ready
revision: 1
depends_on: []
touches:
  - pubspec.yaml
  - lib/main.dart
  - lib/core/**
invariants:
  - "The application is strictly a dedicated, decoupled logger (ecu_logger); it does not attempt ECU ROM flash writing."
  - "Logging operates autonomously upon BLE connection regardless of motorcycle ignition/engine status."
  - "All status messages and operational warnings are displayed exclusively as top-centered toast bubbles."
  - "The UI strictly adheres to GitHub design aesthetics (dark/light Primer palette, line icons, clean cards)."
  - "Fonts are strictly bound: Canela for App Title, Google Sans for General UI, Google Sans Code for Loggers/Hex."
  - "Lock screen provides a full-page translucent overlay with a dynamic 4-digit numeric keypad, keeping the live logging dashboard visible underneath."
  - "Auto-save is guaranteed on BLE disconnect, app pause, or app backgrounding to prevent data loss."
---

# ECU Logger Architecture Specification

## 1. System Intent & Scope
`ecu_logger` is a standalone, performance-focused mobile telemetry recorder for Android built with Flutter. It connects to the NEXAS NexLink BLE 5.0 adapter (and generic ELM327 BLE transceivers) on the Yamaha XSR155 to continuously stream and persist live powertrain CAN bus broadcasts and OBD-II Mode 01 diagnostic streams directly to local device storage.

## 2. Invariants & Non-Negotiables
1. **Decoupled Architecture**: No dependencies on heavy legacy UI packages; pure Flutter + reactive BLE + file streaming.
2. **Passive High-Rate Stream**: Passive CAN listening (50-100Hz) augmented with periodic Mode 01 ground truth.
3. **Pocket/Handlebar Lock**: Accidental touch prevention via dynamic 4-digit PIN translucent overlay without pausing the background logging stream.
4. **Data Integrity**: Flush-on-write file streams ensuring zero log corruption even if battery disconnects.
