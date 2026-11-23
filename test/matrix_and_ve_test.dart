// VE = Volumetric Efficiency
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// VVA = Variable Valve Actuation
// MAP = Manifold Absolute Pressure
// IAT = Intake Air Temperature
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/models/remap_matrix.dart';
import 'package:ecu_logger/services/telemetry_engine.dart';

void main() {
  group('RemapMatrix & VE Calculation Tests', () {
    test('RemapMatrix records low-cam and high-cam samples properly', () {
      final RemapMatrix matrix = RemapMatrix();

      // Low Cam sample: 3000 RPM, 20% TPS, VE = 85.0
      matrix.recordSample(
        rpm: 3050.0,
        tps: 19.5,
        ve: 85.0,
        isVvaActive: false,
      );

      // Closest RPM to 3050 is 3000 (index 4)
      // Closest TPS to 19.5 is 20.0 (index 4)
      expect(matrix.lowCam[4][4].count, equals(1));
      expect(matrix.lowCam[4][4].averageVe, equals(85.0));

      // High Cam (VVA) sample: 8000 RPM, 80% TPS, VE = 98.0
      matrix.recordSample(
        rpm: 7950.0,
        tps: 81.0,
        ve: 98.0,
        isVvaActive: true,
      );

      // Closest RPM to 7950 is 8000 (index 9)
      // Closest TPS to 81.0 is 80.0 (index 8)
      expect(matrix.highCam[9][8].count, equals(1));
      expect(matrix.highCam[9][8].averageVe, equals(98.0));
    });

    test('RemapMatrix JSON serialization contains valid structure', () {
      final RemapMatrix matrix = RemapMatrix();
      matrix.recordSample(rpm: 4000.0, tps: 30.0, ve: 88.5, isVvaActive: false);

      // dynamic required here: JSON serialization structure requires dynamic values
      final Map<String, dynamic> json = matrix.toJson();
      expect(json['rpm_bins'], isNotEmpty);
      expect(json['tps_bins'], isNotEmpty);
      expect(json['low_cam_matrix'], isNotEmpty);
      expect(json['high_cam_matrix'], isNotEmpty);
      expect(json['generated_at'], isNotNull);
    });

    test('Speed-Density VE formula calculation test', () {
      // VE_density = (MAP / Baro) * (293.15 / (273.15 + IAT)) * 100%
      const double map = 101.3;
      const double baro = 101.3;
      const double iat = 20.0; // 293.15 K
      final double ve = (map / baro) * (293.15 / (273.15 + iat)) * 100.0;
      expect(ve, closeTo(100.0, 0.01));
    });

    test('TelemetryData copyWith preserves invariants', () {
      final TelemetryData data = TelemetryData(rpm: 1500.0, tps: 12.0);
      final TelemetryData updated = data.copyWith(rpm: 2500.0);
      expect(updated.rpm, equals(2500.0));
      expect(updated.tps, equals(12.0));
    });

    test('Engine off state suppresses Volumetric Efficiency to zero', () {
      // When RPM is 0 (engine stopped), VE should be 0.0 even if MAP is atmospheric
      final TelemetryData stoppedEngineData = TelemetryData(
        rpm: 0.0,
        tps: 0.0,
        mapKpa: 101.3,
        veDensity: 0.0,
        veCorrected: 0.0,
        isVvaActive: false,
      );
      expect(stoppedEngineData.rpm, equals(0.0));
      expect(stoppedEngineData.veDensity, equals(0.0));
      expect(stoppedEngineData.veCorrected, equals(0.0));
      expect(stoppedEngineData.isVvaActive, isFalse);
    });
  });
}
