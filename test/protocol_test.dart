import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/services/elm327_protocol.dart';

void main() {
  group('Elm327Protocol Tests', () {
    test('Cleans ELM327 buffer correctly', () {
      const raw = 'SEARCHING...\r\n>41 0C 1F 40\r\nSTOPPED>';
      final cleaned = Elm327Protocol.cleanBuffer(raw);
      expect(cleaned, contains('41 0C 1F 40'));
      expect(cleaned, isNot(contains('SEARCHING...')));
      expect(cleaned, isNot(contains('>')));
      expect(cleaned, isNot(contains('STOPPED')));
    });

    test('Parses Mode 01 PID 0C (RPM) correctly', () {
      // 0x1F40 = 8000 -> 8000 / 4 = 2000 RPM
      const response = '41 0C 1F 40';
      final rpm = Elm327Protocol.parseMode01Rpm(response);
      expect(rpm, equals(2000.0));
    });

    test('Parses Mode 01 PID 11 (TPS) correctly', () {
      // 0x80 = 128 -> (128 * 100) / 255 = 50.196%
      const response = '41 11 80';
      final tps = Elm327Protocol.parseMode01Tps(response);
      expect(tps, isNotNull);
      expect(tps!, closeTo(50.2, 0.1));
    });

    test('Parses Mode 01 PID 0B (MAP) correctly', () {
      // 0x64 = 100 kPa
      const response = '41 0B 64';
      final mapKpa = Elm327Protocol.parseMode01Map(response);
      expect(mapKpa, equals(100.0));
    });

    test('Parses Mode 01 PID 05 (ECT) correctly', () {
      // 0x78 = 120 -> 120 - 40 = 80 °C
      const response = '41 05 78';
      final ect = Elm327Protocol.parseMode01Ect(response);
      expect(ect, equals(80.0));
    });

    test('Parses Yamaha raw CAN 0x770 frame (RPM & TPS)', () {
      // 770 08 1F 40 80 ... -> RPM = 2000, TPS = 50.19%
      const frame = '770 08 1F 40 80 00 00 00';
      final parsed = Elm327Protocol.parseRawCanFrame(frame);
      expect(parsed, isNotNull);
      expect(parsed!['rpm'], equals(2000.0));
      expect(parsed['tps'], closeTo(50.2, 0.1));
    });

    test('Parses Yamaha raw CAN 0x212 frame (VVA bit)', () {
      const vvaActiveFrame = '212 04 01 00 00 00';
      final parsedActive = Elm327Protocol.parseRawCanFrame(vvaActiveFrame);
      expect(parsedActive, isNotNull);
      expect(parsedActive!['vva'], isTrue);

      const vvaInactiveFrame = '212 04 00 00 00 00';
      final parsedInactive = Elm327Protocol.parseRawCanFrame(vvaInactiveFrame);
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
  });
}
