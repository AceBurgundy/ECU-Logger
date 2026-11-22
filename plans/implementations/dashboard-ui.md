---
id: dashboard-ui
title: Minimalist Dashboard, Monospace Drawer & Translucent Lock Overlay
type: implementation
status: ready
revision: 1
depends_on:
  - toast-and-theme
  - telemetry-engine
touches:
  - lib/screens/home_screen.dart
  - lib/widgets/metric_card.dart
  - lib/widgets/log_drawer.dart
  - lib/widgets/lock_overlay.dart
  - lib/widgets/bluetooth_dialog.dart
---

# Minimalist Dashboard, Monospace Drawer & Translucent Lock Overlay

## Summary
Constructs the primary screen conforming to Option 3: Top header, 6 metric readouts, collapsible bottom log drawer, floating Bluetooth and Lock buttons, and full-page translucent PIN unlock overlay.

## Tasks
1. Create `lib/widgets/metric_card.dart`:
   - GitHub style card with title in Google Sans, large metric value in Google Sans Code, unit, and subtle status accent.
2. Create `lib/widgets/log_drawer.dart`:
   - Collapsible panel showing rolling 200 lines of raw CAN frames and decoded lines in Google Sans Code.
3. Create `lib/widgets/bluetooth_dialog.dart`:
   - GitHub styled dialog displaying discovered devices, signal strength, connect action, and disconnect button (when connected).
4. Create `lib/widgets/lock_overlay.dart`:
   - Full-page translucent modal overlay.
   - Dynamic 4-digit code generation on trigger (`Press "4 8 2 1" to unlock`).
   - Clean numeric keypad (0-9, Clear).
   - Keeps underlying metrics completely readable while blocking touches.
5. Create `lib/screens/home_screen.dart`:
   - Assembles app bar, dashboard grid, log drawer, floating Bluetooth FAB, and lock FAB.

## Verification
- Widget tests for lock screen challenge/response and Bluetooth FAB status color changes.
