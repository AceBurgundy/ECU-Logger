---
id: adr-003-ble-connectivity-flow
title: ADR-003 BLE Lifecycle, Permission Gates & Auto-Save
type: architecture
status: ready
revision: 1
depends_on: []
touches:
  - lib/services/ble_service.dart
  - lib/services/storage_permission_service.dart
---

# ADR-003: BLE Lifecycle, Permission Gates & Auto-Save

## Context
Mobile operating systems aggressively suspend background Bluetooth tasks and throttle file I/O unless proper foreground lifecycle handling and permissions are established.

## Decision
1. **Permission Flow**:
   - Check `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and `ACCESS_FINE_LOCATION` on first launch.
   - Request `MANAGE_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` with a top-centered GitHub toast prompt.
2. **Connection Cycle**:
   - Floating Bluetooth icon changes: Grey (Disconnected) -> Blue/Orange (Scanning/Connecting) -> Green (Connected & Logging).
   - Tap FAB -> opens dialog with scanned devices and known NexLink MACs.
   - If connected, dialog reveals a red Disconnect button.
3. **Fail-Safe Auto-Save**:
   - On explicit disconnect, app backgrounding (`AppLifecycleState.paused` / `inactive`), or low battery notification, all open log buffers (`.flush()`) are closed and finalized cleanly.
