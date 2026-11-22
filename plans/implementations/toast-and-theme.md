---
id: toast-and-theme
title: GitHub Primer Theme & Centered Top Toast System
type: implementation
status: ready
revision: 1
depends_on:
  - scaffold-and-assets
touches:
  - lib/theme/github_theme.dart
  - lib/widgets/toast_overlay.dart
---

# GitHub Primer Theme & Centered Top Toast System

## Summary
Implements GitHub-inspired dark/light theme definitions with custom font bindings and a global top-centered toast notification system.

## Tasks
1. Create `lib/theme/github_theme.dart`:
   - GitHub Dark palette: Canvas `#0D1117`, Surface `#161B22`, Border `#30363D`, Accent Blue `#58A6FF`, Success Green `#238636`, Danger Red `#DA3633`, Text `#C9D1D9`.
   - Typography bindings: `Canela` for H1/Titles, `Google Sans` for Body/Labels, `Google Sans Code` for Logs/Metrics.
2. Create `lib/widgets/toast_overlay.dart`:
   - Positioned at top-center (`top: 48`).
   - Pill-shaped chip with subtle border, line icon, and message text.
   - Auto-dismiss with smooth spring/fade animation.
   - Helper `ToastService.show(context, message, type: ToastType.info | success | warning | error)`.

## Verification
- Unit test verifying toast queue and auto-dismiss timing.
