// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
// IAT = Intake Air Temperature
// BARO = Barometric Pressure
// STFT = Short Term Fuel Trim
// LTFT = Long Term Fuel Trim
// VE = Volumetric Efficiency
// VVA = Variable Valve Actuation
// PID = Parameter Identification
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../services/telemetry_engine.dart';

/// Defines metadata and value extraction logic for a telemetry channel.
class TelemetryMetric {
  /// Unique machine identifier for this metric (e.g. 'rpm', 'tps', 'map').
  final String id;

  /// Full descriptive title (e.g. 'Engine Speed', 'Manifold Absolute Pressure').
  final String name;

  /// Compact header label displayed on cards (e.g. 'ENGINE SPEED').
  final String shortLabel;

  /// Engineering unit badge text (e.g. 'RPM', 'kPa', '°C').
  final String unit;

  /// Associated OBD-II standard PID or CAN arbitration ID description.
  final String obdPid;

  /// Custom accent color for card highlights.
  final Color accentColor;

  /// Function extracting the formatted readout value string from [TelemetryData].
  final String Function(TelemetryData data, bool isConnected) valueFormatter;

  /// Function determining whether this card should be highlighted given [TelemetryData].
  final bool Function(TelemetryData data, bool isConnected) isHighlight;

  /// Creates a [TelemetryMetric] instance.
  const TelemetryMetric({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.unit,
    required this.obdPid,
    required this.accentColor,
    required this.valueFormatter,
    required this.isHighlight,
  });

  /// Master catalog of all telemetry metrics decoded by the system.
  static final List<TelemetryMetric> allMetrics = <TelemetryMetric>[
    // 1. RPM
    TelemetryMetric(
      id: 'rpm',
      name: 'Engine Speed',
      shortLabel: 'ENGINE SPEED',
      unit: 'RPM',
      obdPid: '010C / CAN 0x20A / 0x770',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.rpm == null) return '--';
        return data.rpm!.toStringAsFixed(0);
      },
      isHighlight: (TelemetryData data, bool isConnected) {
        return isConnected && data.rpm != null && data.rpm! >= 7400.0;
      },
    ),

    // 2. TPS
    TelemetryMetric(
      id: 'tps',
      name: 'Throttle Position',
      shortLabel: 'THROTTLE (TPS)',
      unit: '%',
      obdPid: '0111 / CAN 0x20A / 0x770',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.tps == null) return '--';
        return data.tps!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 3. MAP
    TelemetryMetric(
      id: 'map',
      name: 'Manifold Absolute Pressure',
      shortLabel: 'MANIFOLD PRESSURE',
      unit: 'kPa',
      obdPid: '010B',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.mapKpa == null) return '--';
        return data.mapKpa!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 4. Volumetric Efficiency
    TelemetryMetric(
      id: 've',
      name: 'Volumetric Efficiency',
      shortLabel: 'VOLUMETRIC EFF.',
      unit: '%',
      obdPid: 'Speed-Density Calculation',
      accentColor: GitHubTheme.successFg,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || (data.veCorrected == null && data.veDensity == null)) {
          return '--';
        }
        final double? effectiveVe = data.veCorrected ?? data.veDensity;
        return effectiveVe!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => isConnected && data.veCorrected != null,
    ),

    // 5. Engine Coolant Temperature
    TelemetryMetric(
      id: 'ect',
      name: 'Engine Coolant Temp',
      shortLabel: 'COOLANT TEMP',
      unit: '°C',
      obdPid: '0105 / CAN 0x236',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.ectC == null) return '--';
        return data.ectC!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) {
        return isConnected && data.ectC != null && data.ectC! >= 100.0;
      },
    ),

    // 6. VVA Status
    TelemetryMetric(
      id: 'vva',
      name: 'VVA Cam Status',
      shortLabel: 'VVA CAM STATUS',
      unit: 'CAM',
      obdPid: 'CAN 0x212 / Hysteresis',
      accentColor: GitHubTheme.warningFg,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.isVvaActive == null) return '--';
        return data.isVvaActive! ? 'ACTIVE' : 'INACTIVE';
      },
      isHighlight: (TelemetryData data, bool isConnected) {
        return isConnected && data.isVvaActive != null && data.isVvaActive!;
      },
    ),

    // 7. Intake Air Temperature
    TelemetryMetric(
      id: 'iat',
      name: 'Intake Air Temp',
      shortLabel: 'INTAKE AIR TEMP',
      unit: '°C',
      obdPid: '010F',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.iatC == null) return '--';
        return data.iatC!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 8. Barometric Pressure
    TelemetryMetric(
      id: 'baro',
      name: 'Barometric Pressure',
      shortLabel: 'BAROMETRIC PRESS',
      unit: 'kPa',
      obdPid: '0133',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.baroKpa == null) return '--';
        return data.baroKpa!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 9. Short Term Fuel Trim
    TelemetryMetric(
      id: 'stft',
      name: 'Short Term Fuel Trim',
      shortLabel: 'STFT TRIM',
      unit: '%',
      obdPid: '0106 / CAN 0x240',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.stft == null) return '--';
        return data.stft!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 10. Long Term Fuel Trim
    TelemetryMetric(
      id: 'ltft',
      name: 'Long Term Fuel Trim',
      shortLabel: 'LTFT TRIM',
      unit: '%',
      obdPid: '0107 / CAN 0x240',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.ltft == null) return '--';
        return data.ltft!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 11. ECU Battery Voltage
    TelemetryMetric(
      id: 'volt',
      name: 'ECU Module Voltage',
      shortLabel: 'BATTERY VOLTAGE',
      unit: 'V',
      obdPid: '0142 / ATRV',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.batteryVoltage == null) return '--';
        return data.batteryVoltage!.toStringAsFixed(2);
      },
      isHighlight: (TelemetryData data, bool isConnected) {
        return isConnected && data.batteryVoltage != null && data.batteryVoltage! < 11.6;
      },
    ),

    // 12. Calculated Engine Load
    TelemetryMetric(
      id: 'load',
      name: 'Engine Calculated Load',
      shortLabel: 'ENGINE LOAD',
      unit: '%',
      obdPid: '0104',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.engineLoad == null) return '--';
        return data.engineLoad!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 13. Ignition Timing Advance
    TelemetryMetric(
      id: 'timing',
      name: 'Ignition Timing Advance',
      shortLabel: 'IGNITION TIMING',
      unit: '°BTDC',
      obdPid: '010E',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.timingAdvance == null) return '--';
        return data.timingAdvance!.toStringAsFixed(1);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 14. O2 Sensor Voltage
    TelemetryMetric(
      id: 'o2',
      name: 'O2 Sensor Voltage',
      shortLabel: 'O2 SENSOR',
      unit: 'V',
      obdPid: '0114 / CAN 0x240',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.o2Voltage == null) return '--';
        return data.o2Voltage!.toStringAsFixed(3);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),

    // 15. Vehicle Speed
    TelemetryMetric(
      id: 'speed',
      name: 'Vehicle Speed',
      shortLabel: 'VEHICLE SPEED',
      unit: 'km/h',
      obdPid: '010D',
      accentColor: GitHubTheme.accent,
      valueFormatter: (TelemetryData data, bool isConnected) {
        if (!isConnected || data.speedKmh == null) return '--';
        return data.speedKmh!.toStringAsFixed(0);
      },
      isHighlight: (TelemetryData data, bool isConnected) => false,
    ),
  ];

  /// Finds a metric by its unique [id], or null if not found.
  static TelemetryMetric? findById(String id) {
    for (final TelemetryMetric metric in allMetrics) {
      if (metric.id == id) {
        return metric;
      }
    }
    return null;
  }
}
