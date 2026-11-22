---
id: adr-002-github-minimalist-ui
title: ADR-002 GitHub Minimalist UI & Translucent Lock Overlay
type: architecture
status: ready
revision: 1
depends_on: []
touches:
  - lib/theme/github_theme.dart
  - lib/screens/home_screen.dart
  - lib/widgets/lock_overlay.dart
---

# ADR-002: GitHub Minimalist UI & Translucent Lock Overlay

## Context
Riding in bright outdoor sunlight on a handlebar mount or keeping the phone in a jacket pocket requires:
1. High contrast, clean, scannable layout following GitHub Primer aesthetics.
2. Accidental touch prevention that does NOT hide or pause the live logging stream.

## Decision
1. **Option 3 Minimalist Dashboard**:
   - Top status bar with Canela title, connection indicator badge, and elapsed time.
   - 6 high-contrast GitHub-styled metric cards (RPM, TPS, MAP kPa, VE %, ECT °C, VVA State).
   - Collapsible bottom drawer showing scrolling Google Sans Code monospace frames.
2. **Translucent Lock Screen**:
   - Triggered by the lock FAB beside the Bluetooth FAB.
   - Renders a semi-transparent dark backdrop (`rgba(13, 17, 23, 0.85)`).
   - Shows dynamic prompt: `Press "X X X X" to unlock`.
   - 10-key clean line keypad at the bottom.
   - Dashboard metrics remain visibly readable through the overlay while locked.
