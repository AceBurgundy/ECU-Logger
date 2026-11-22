---
id: telemetry-engine
title: Telemetry Engine, VE Calculator & Dual-Stream File Logger
type: implementation
status: ready
revision: 1
depends_on:
  - ble-obd-service
touches:
  - lib/services/telemetry_engine.dart
  - lib/services/file_logger_service.dart
  - lib/models/remap_matrix.dart
---

# Telemetry Engine, VE Calculator & Dual-Stream File Logger

## Summary
Processes raw CAN payloads and OBD responses into engineering metrics, evaluates real-time Volumetric Efficiency (VE%), populates the 16x11 matrix, and writes the three session files directly to local storage.

## Tasks
1. Create `lib/services/telemetry_engine.dart`:
   - Decodes Yamaha CAN frames (`0x770` RPM & TPS, `0x20A` Powertrain broadcast, `0x212` VVA bit).
   - Evaluates Speed-Density VE% and Fuel-Corrected VE%.
   - VVA hysteresis: engages at >= 7,400 RPM (when ECT >= 60°C), disengages < 7,000 RPM.
2. Create `lib/models/remap_matrix.dart`:
   - 16x11 dual-cam matrix accumulator for Low-Cam and High-Cam.
3. Create `lib/services/file_logger_service.dart`:
   - Initializes `raw_can_<ts>.log`, `telemetry_<ts>.csv`, and `remap_matrix_<ts>.json`.
   - Streaming writes with buffered flushing.
   - Lifecycle listener: auto-flushes and closes files on app pause, backgrounding, or BLE disconnect.

## Verification
- Unit test for VE formula accuracy, VVA hysteresis logic, and CSV stream output.
