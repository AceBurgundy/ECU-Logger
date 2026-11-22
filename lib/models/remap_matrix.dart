import 'dart:convert';

class MatrixCell {
  int count;
  double sumVe;

  MatrixCell({this.count = 0, this.sumVe = 0.0});

  double get averageVe => count > 0 ? (sumVe / count) : 0.0;

  void add(double ve) {
    count++;
    sumVe += ve;
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'average_ve': double.parse(averageVe.toStringAsFixed(2)),
  };
}

class RemapMatrix {
  static const List<int> rpmBins = [
    1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000,
    7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000
  ];

  static const List<double> tpsBins = [
    0.0, 5.0, 10.0, 15.0, 20.0, 30.0, 40.0, 60.0, 80.0, 90.0, 100.0
  ];

  // 16 rows (RPM) x 11 cols (TPS) for Low-Cam
  final List<List<MatrixCell>> lowCam = List.generate(
    rpmBins.length,
    (_) => List.generate(tpsBins.length, (_) => MatrixCell()),
  );

  // 16 rows (RPM) x 11 cols (TPS) for High-Cam (VVA)
  final List<List<MatrixCell>> highCam = List.generate(
    rpmBins.length,
    (_) => List.generate(tpsBins.length, (_) => MatrixCell()),
  );

  int _findClosestBin(num value, List<num> bins) {
    int bestIdx = 0;
    num minDiff = (value - bins[0]).abs();
    for (int i = 1; i < bins.length; i++) {
      num diff = (value - bins[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  void recordSample({
    required double rpm,
    required double tps,
    required double ve,
    required bool isVvaActive,
  }) {
    if (rpm <= 0 || ve <= 0) return;
    int rIdx = _findClosestBin(rpm, rpmBins);
    int tIdx = _findClosestBin(tps, tpsBins);

    if (isVvaActive) {
      highCam[rIdx][tIdx].add(ve);
    } else {
      lowCam[rIdx][tIdx].add(ve);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'rpm_bins': rpmBins,
      'tps_bins': tpsBins,
      'low_cam_matrix': lowCam.map((row) => row.map((c) => c.toJson()).toList()).toList(),
      'high_cam_matrix': highCam.map((row) => row.map((c) => c.toJson()).toList()).toList(),
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  String toFormattedJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
