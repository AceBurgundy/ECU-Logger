---
id: ble-obd-service
title: BLE Connection Manager & ELM327 Stream Protocol
type: implementation
status: ready
revision: 1
depends_on:
  - scaffold-and-assets
touches:
  - lib/services/ble_service.dart
  - lib/services/elm327_protocol.dart
---

# BLE Connection Manager & ELM327 Stream Protocol

## Summary
Implements BLE scanning, automated service/characteristic discovery for SPP (Serial Port Profile, UUID `FFF0`/`FFF1` or `FFE0`/`FFE1`), ELM327 AT command handshake, and command queue management.

## Tasks
1. Create `lib/services/ble_service.dart`:
   - Scans for BLE devices advertising OBD or serial services.
   - Filters and presents device list in GitHub dialog.
   - Reconnect logic with state stream: `disconnected`, `scanning`, `connecting`, `connected`, `error`.
2. Create `lib/services/elm327_protocol.dart`:
   - Initializes adapter: `ATZ`, `ATE0`, `ATL0`, `ATH1`, `ATSP6` (ISO 15765-4 CAN 500k 11b).
   - Reads battery voltage via `ATRV`.
   - Supports both active Mode 01 queries (`010C`, `010B`, `0111`) and raw CAN bank sniffing (`ATCF 200`, `ATCM 700`, `ATMA`).
   - Clean buffer parsing handling prompt desync and `STOPPED` tokens.

## Verification
- Unit test for ELM hex parsing and state stream transitions.
