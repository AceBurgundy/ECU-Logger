// VE = Volumetric Efficiency
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// VVA = Variable Valve Actuation
import 'dart:convert';

/// Represents a single accumulator cell within the volumetric efficiency remap matrix.
class MatrixCell {
  /// Total count of telemetry sample hits collected in this cell.
  int count;

  /// Running sum of volumetric efficiency percentages recorded in this cell.
  double sumVe;

  /// Creates a [MatrixCell] with optional initial [count] and [sumVe].
  MatrixCell({this.count = 0, this.sumVe = 0.0});

  /// Computes the arithmetic mean volumetric efficiency for collected samples.
  double get averageVe => count > 0 ? (sumVe / count) : 0.0;

  /// Accumulates a new volumetric efficiency sample into the cell.
  void add(double ve) {
    count++;
    sumVe += ve;
  }

  /// Serializes the cell to a JSON-compatible map.
  // dynamic required here: JSON serialization structure requires dynamic values
  Map<String, dynamic> toJson() => {
    'count': count,
    'average_ve': double.parse(averageVe.toStringAsFixed(2)),
  };
}

/// Accumulator holding 16x11 dual-cam volumetric efficiency lookup tables.
class RemapMatrix {
  /// Standard 16 RPM bins spanning idle to redline.
  static const List<int> rpmBins = [
    1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000,
    7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000
  ];

  /// Standard 11 throttle position percentage bins spanning 0% to 100%.
  static const List<double> tpsBins = [
    0.0, 5.0, 10.0, 15.0, 20.0, 30.0, 40.0, 60.0, 80.0, 90.0, 100.0
  ];

  /// 16 rows (RPM) x 11 cols (TPS) matrix for low-cam operation.
  final List<List<MatrixCell>> lowCam = List.generate(
    rpmBins.length,
    (_) => List.generate(tpsBins.length, (_) => MatrixCell()),
  );

  /// 16 rows (RPM) x 11 cols (TPS) matrix for high-cam (VVA) operation.
  final List<List<MatrixCell>> highCam = List.generate(
    rpmBins.length,
    (_) => List.generate(tpsBins.length, (_) => MatrixCell()),
  );

  int _findClosestBin(num value, List<num> bins) {
    int bestIndex = 0;
    num minDifference = (value - bins[0]).abs();
    for (int index = 1; index < bins.length; index++) {
      final num difference = (value - bins[index]).abs();
      if (difference < minDifference) {
        minDifference = difference;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  /// Records a telemetry data point into either the low-cam or high-cam matrix.
  void recordSample({
    required double rpm,
    required double tps,
    required double ve,
    required bool isVvaActive,
  }) {
    if (rpm <= 0.0 || ve <= 0.0) return;
    final int rpmIndex = _findClosestBin(rpm, rpmBins);
    final int tpsIndex = _findClosestBin(tps, tpsBins);

    if (isVvaActive) {
      highCam[rpmIndex][tpsIndex].add(ve);
    } else {
      lowCam[rpmIndex][tpsIndex].add(ve);
    }
  }

  /// Serializes the complete dual-cam remap matrix to a JSON map.
  // dynamic required here: JSON serialization structure requires dynamic values
  Map<String, dynamic> toJson() {
    return {
      'rpm_bins': rpmBins,
      'tps_bins': tpsBins,
      'low_cam_matrix': lowCam
          .map((List<MatrixCell> row) =>
              row.map((MatrixCell cell) => cell.toJson()).toList())
          .toList(),
      'high_cam_matrix': highCam
          .map((List<MatrixCell> row) =>
              row.map((MatrixCell cell) => cell.toJson()).toList())
          .toList(),
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Produces a formatted, indented JSON representation of the matrix.
  String toFormattedJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
