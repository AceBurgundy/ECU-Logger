---
id: adr-001-logging-data-schema
title: ADR-001 Dual-Stream File Logging Architecture
type: architecture
status: ready
revision: 1
depends_on: []
touches:
  - lib/services/logger_service.dart
  - lib/models/telemetry_record.dart
---

# ADR-001: Dual-Stream File Logging Architecture

## Context
The motorcycle telemetry crawler must capture both raw, unfiltered CAN frames for reverse-engineering and byte correlation, as well as calculated engineering values (RPM, TPS, MAP, VE%, Coolant Temp, Timing Advance, Fuel Trims, and VVA status) structured across a 16x11 Alpha-N / Speed-Density matrix for fuel remapping analysis.

## Decision
`ecu_logger` will write three synchronized files per session to the app's external documents directory:
1. `raw_can_<timestamp>.log`: Raw CSV of timestamp, arbitration ID, and payload hex.
2. `telemetry_<timestamp>.csv`: High-rate time-series table containing all decoded powertrain variables, Speed-Density VE%, Fuel-Corrected VE%, and total fuel trim.
3. `remap_matrix_<timestamp>.json`: Real-time 16x11 matrix accumulator (RPM vs TPS) tracking sample counts, average MAP load, VE%, and ignition timing advance for Low-Cam and High-Cam VVA.

## Consequences
- Guaranteed compatibility with existing Python analysis pipelines.
- Zero loss of raw bus frames.
- Streamlined post-processing for AI-assisted fuel map optimization.
