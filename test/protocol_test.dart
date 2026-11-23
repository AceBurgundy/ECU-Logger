// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
// CAN = Controller Area Network
// VVA = Variable Valve Actuation
// PID = Parameter Identification
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/services/elm327_protocol.dart';

void main() {
  group('Elm327Protocol Tests', () {
    test('Cleans ELM327 buffer correctly', () {
      const String raw = 'SEARCHING...\r\n>41 0C 1F 40\r\nSTOPPED>';
      final String cleaned = Elm327Protocol.cleanBuffer(raw);
      expect(cleaned, contains('41 0C 1F 40'));
      expect(cleaned, isNot(contains('SEARCHING...')));
      expect(cleaned, isNot(contains('>')));
      expect(cleaned, isNot(contains('STOPPED')));
    });

    test('Parses Mode 01 PID 0C (RPM) correctly', () {
      // 0x1F40 = 8000 -> 8000 / 4 = 2000 RPM
      const String response = '41 0C 1F 40';
      final double? rpm = Elm327Protocol.parseMode01Rpm(response);
      expect(rpm, equals(2000.0));
    });

    test('Parses Mode 01 PID 11 (TPS) correctly', () {
      // 0x80 = 128 -> (128 * 100) / 255 = 50.196%
      const String response = '41 11 80';
      final double? tps = Elm327Protocol.parseMode01Tps(response);
      expect(tps, isNotNull);
      expect(tps!, closeTo(50.2, 0.1));
    });

    test('Parses Mode 01 PID 0B (MAP) correctly', () {
      // 0x64 = 100 kPa
      const String response = '41 0B 64';
      final double? mapKpa = Elm327Protocol.parseMode01Map(response);
      expect(mapKpa, equals(100.0));
    });

    test('Parses Mode 01 PID 05 (ECT) correctly', () {
      // 0x78 = 120 -> 120 - 40 = 80 °C
      const String response = '41 05 78';
      final double? ect = Elm327Protocol.parseMode01Ect(response);
      expect(ect, equals(80.0));
    });

    test('Parses Yamaha raw CAN 0x770 frame (RPM & TPS)', () {
      // 770 08 1F 40 80 ... -> RPM = 2000, TPS = 50.19%
      const String frame = '770 08 1F 40 80 00 00 00';
      // dynamic required here: polymorphic CAN frame data structure contains strings, doubles, and booleans
      final Map<String, dynamic>? parsed = Elm327Protocol.parseRawCanFrame(frame);
      expect(parsed, isNotNull);
      expect(parsed!['rpm'], equals(2000.0));
      expect(parsed['tps'], closeTo(50.2, 0.1));
    });

    test('Parses Yamaha raw CAN 0x212 frame (VVA bit)', () {
      const String vvaActiveFrame = '212 04 01 00 00 00';
      // dynamic required here: polymorphic CAN frame data structure contains strings, doubles, and booleans
      final Map<String, dynamic>? parsedActive = Elm327Protocol.parseRawCanFrame(vvaActiveFrame);
      expect(parsedActive, isNotNull);
      expect(parsedActive!['vva'], isTrue);

      const String vvaInactiveFrame = '212 04 00 00 00 00';
      // dynamic required here: polymorphic CAN frame data structure contains strings, doubles, and booleans
      final Map<String, dynamic>? parsedInactive = Elm327Protocol.parseRawCanFrame(vvaInactiveFrame);
      expect(parsedInactive, isNotNull);
      expect(parsedInactive!['vva'], isFalse);
    });

    test('Verifies ELM327 initialization command sequence', () {
      expect(Elm327Protocol.initCommands, contains('ATZ'));
      expect(Elm327Protocol.initCommands, contains('ATE0'));
      expect(Elm327Protocol.initCommands, contains('ATL0'));
      expect(Elm327Protocol.initCommands, contains('ATH1'));
      expect(Elm327Protocol.initCommands, contains('ATSP6'));
      expect(Elm327Protocol.initCommands.length, equals(5));
    });

    test('Handles malformed or empty CAN frame gracefully', () {
      expect(Elm327Protocol.parseRawCanFrame(''), isNull);
      expect(Elm327Protocol.parseRawCanFrame('INVALID_HEX_DATA'), isNull);
      expect(Elm327Protocol.parseRawCanFrame('770'), isNull);
      expect(Elm327Protocol.parseMode01Rpm('NO DATA'), isNull);
      expect(Elm327Protocol.parseMode01Tps('41'), isNull);
    });

    test('Parses unspaced Yamaha CAN frames', () {
      // 770081F40800000000000 (Header: 770, DLC: 08, Payload: 1F 40 80 00 00 00 00 00 -> RPM = 2000, TPS = 50.2)
      const String unspaced770 = '770081F40800000000000';
      final Map<String, dynamic>? parsed770 = Elm327Protocol.parseRawCanFrame(unspaced770);
      expect(parsed770, isNotNull);
      expect(parsed770!['rpm'], equals(2000.0));
      expect(parsed770['tps'], closeTo(50.2, 0.1));

      // 2120401000000 (Header: 212, DLC: 04, Payload: 01 00 00 00 -> VVA active)
      const String unspaced212 = '2120401000000';
      final Map<String, dynamic>? parsed212 = Elm327Protocol.parseRawCanFrame(unspaced212);
      expect(parsed212, isNotNull);
      expect(parsed212!['vva'], isTrue);
    });

    test('Parses Mode 01 PID with CAN 7E8 header and prompt artifacts', () {
      const String responseWithHeader = '7E8 04 41 0C 1F 40\r>';
      expect(Elm327Protocol.parseMode01Rpm(responseWithHeader), equals(2000.0));

      const String compactWithHeader = '7E804410C1F40>';
      expect(Elm327Protocol.parseMode01Rpm(compactWithHeader), equals(2000.0));
    });

    test('Parses engine-off CAN frames and PID responses accurately without byte shifts', () {
      // Real recorded Yamaha XSR155 broadcast with Key ON, Engine OFF:
      // 770 00 00 00 0F 00 20 F0 0C (byte0=00, byte1=00 -> 0 RPM; byte2=00 -> 0.0% TPS)
      const String engineOff770 = '770 00 00 00 0F 00 20 F0 0C';
      final Map<String, dynamic>? parsedOff770 = Elm327Protocol.parseRawCanFrame(engineOff770);
      expect(parsedOff770, isNotNull);
      expect(parsedOff770!['rpm'], equals(0.0));
      expect(parsedOff770['tps'], equals(0.0));

      // 20A frame with engine off
      const String engineOff20A = '20A 00 00 00 00 00 00 00 00';
      final Map<String, dynamic>? parsedOff20A = Elm327Protocol.parseRawCanFrame(engineOff20A);
      expect(parsedOff20A, isNotNull);
      expect(parsedOff20A!['rpm'], equals(0.0));
      expect(parsedOff20A['tps'], equals(0.0));

      // Diagnostic Mode 01 responses with engine off
      expect(Elm327Protocol.parseMode01Rpm('7E8 04 41 0C 00 00'), equals(0.0));
      expect(Elm327Protocol.parseMode01Tps('7E8 03 41 11 00'), equals(0.0));
      expect(Elm327Protocol.parseMode01Ect('7E8 03 41 05 48'), equals(32.0)); // 0x48 = 72 - 40 = 32 C
    });
  });
}
