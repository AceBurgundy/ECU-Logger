// CAN = Controller Area Network
// PID = Parameter Identification
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
// IAT = Intake Air Temperature
// BARO = Barometric Pressure
// STFT = Short Term Fuel Trim
// LTFT = Long Term Fuel Trim
// DLC = Data Length Code
// VVA = Variable Valve Actuation
// UDS = Unified Diagnostic Services

/// Protocol parser for ELM327 AT commands, OBD-II standard PIDs, and Yamaha CAN frames.
class Elm327Protocol {
  /// Whitelisted ELM327 initialization command sequence.
  static const List<String> initCommands = [
    'ATZ',    // Reset microcontroller
    'ATE0',   // Disable echo
    'ATL0',   // Disable linefeeds
    'ATH1',   // Enable headers to capture CAN frame IDs
    'ATSP6',  // Lock protocol to ISO 15765-4 CAN (11 bit ID, 500 kbaud)
  ];

  /// Cleans noise, prompt artifacts, and status banners from the serial buffer.
  static String cleanBuffer(String raw) {
    return raw
        .replaceAll('\r', '\n')
        .replaceAll('>', '')
        .replaceAll('STOPPED', '')
        .replaceAll('SEARCHING...', '')
        .replaceAll('UNABLE TO CONNECT', '')
        .replaceAll('NO DATA', '')
        .replaceAll('BUS INIT: ...ERROR', '')
        .replaceAll('CAN ERROR', '')
        .trim();
  }

  /// Parses Mode 01 PID 0C response to engine speed in RPM.
  /// Formula: ((A * 256) + B) / 4
  static double? parseMode01Rpm(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('410C');
    if (targetIndex != -1 && clean.length >= targetIndex + 8) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      final int? byteB = int.tryParse(clean.substring(targetIndex + 6, targetIndex + 8), radix: 16);
      if (byteA != null && byteB != null) {
        return ((byteA * 256.0) + byteB) / 4.0;
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 11 response to throttle position in percentage.
  /// Formula: (A * 100) / 255
  static double? parseMode01Tps(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('4111');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return (byteA * 100.0) / 255.0;
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 0B response to manifold absolute pressure in kPa.
  /// Formula: A
  static double? parseMode01Map(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('410B');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return byteA.toDouble();
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 05 response to engine coolant temperature in degrees Celsius.
  /// Formula: A - 40
  static double? parseMode01Ect(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('4105');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return (byteA - 40).toDouble();
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 0F response to intake air temperature in degrees Celsius.
  /// Formula: A - 40
  static double? parseMode01Iat(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('410F');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return (byteA - 40).toDouble();
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 33 response to absolute barometric pressure in kPa.
  /// Formula: A
  static double? parseMode01Baro(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('4133');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return byteA.toDouble();
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 42 response to control module voltage in Volts.
  /// Formula: ((A * 256) + B) / 1000
  static double? parseMode01Voltage(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('4142');
    if (targetIndex != -1 && clean.length >= targetIndex + 8) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      final int? byteB = int.tryParse(clean.substring(targetIndex + 6, targetIndex + 8), radix: 16);
      if (byteA != null && byteB != null) {
        return ((byteA * 256.0) + byteB) / 1000.0;
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 06 response to short term fuel trim percentage.
  /// Formula: ((A - 128) * 100) / 128
  static double? parseMode01Stft(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('4106');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return ((byteA - 128.0) * 100.0) / 128.0;
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 07 response to long term fuel trim percentage.
  /// Formula: ((A - 128) * 100) / 128
  static double? parseMode01Ltft(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('4107');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return ((byteA - 128.0) * 100.0) / 128.0;
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 04 response to calculated engine load in percentage.
  /// Formula: (A * 100) / 255
  static double? parseMode01EngineLoad(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('4104');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return (byteA * 100.0) / 255.0;
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 0E response to ignition timing advance in degrees before top dead center.
  /// Formula: (A / 2) - 64
  static double? parseMode01TimingAdvance(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('410E');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return (byteA / 2.0) - 64.0;
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 14 response to O2 sensor bank 1 sensor 1 voltage.
  /// Formula: A / 200
  static double? parseMode01O2(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('4114');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return byteA / 200.0;
      }
    }
    return null;
  }

  /// Parses Mode 01 PID 0D response to vehicle speed in km/h.
  /// Formula: A
  static double? parseMode01Speed(String response) {
    final String clean = response.replaceAll(' ', '').replaceAll('>', '').toUpperCase();
    final int targetIndex = clean.indexOf('410D');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return byteA.toDouble();
      }
    }
    return null;
  }

  /// Parses ELM327 ATRV command response (e.g. '12.8V' -> 12.8).
  static double? parseAtVoltage(String response) {
    final RegExp regex = RegExp(r'([0-9]+\.[0-9]+)\s*V', caseSensitive: false);
    final Match? match = regex.firstMatch(response);
    if (match != null) {
      final String? matchedGroup = match.group(1);
      if (matchedGroup != null) {
        return double.tryParse(matchedGroup);
      }
    }
    return null;
  }

  /// Decodes 4-byte SAE J1979 supported PID bitmask for queries 0100, 0120, 0140.
  static List<int> decodeSupportedPidsBitmask(int basePid, String response) {
    final List<int> supportedList = <int>[];
    final String clean = response.replaceAll(' ', '').toUpperCase();
    final String hexHeader = '41${basePid.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    final int targetIndex = clean.indexOf(hexHeader);
    if (targetIndex == -1 || clean.length < targetIndex + hexHeader.length + 8) {
      return supportedList;
    }

    final String bytesHex = clean.substring(
      targetIndex + hexHeader.length,
      targetIndex + hexHeader.length + 8,
    );

    for (int byteIndex = 0; byteIndex < 4; byteIndex++) {
      final int? byteVal = int.tryParse(bytesHex.substring(byteIndex * 2, (byteIndex * 2) + 2), radix: 16);
      if (byteVal == null) continue;
      for (int bitIndex = 7; bitIndex >= 0; bitIndex--) {
        if ((byteVal & (1 << bitIndex)) != 0) {
          final int pidNumber = basePid + 1 + (byteIndex * 8) + (7 - bitIndex);
          supportedList.add(pidNumber);
        }
      }
    }
    return supportedList;
  }

  /// Parses Yamaha broadcast CAN frames (0x20A, 0x770 for RPM/TPS, 0x212 for VVA bit, 0x236, 0x240).
  // dynamic required here: polymorphic CAN frame data structure contains strings, doubles, and booleans
  static Map<String, dynamic>? parseRawCanFrame(String line) {
    final String clean = line.replaceAll('>', '').trim().toUpperCase();
    if (clean.isEmpty) return null;

    String header = '';
    final List<int> dataBytes = <int>[];

    if (clean.contains(' ')) {
      final List<String> parts = clean.split(RegExp(r'\s+'));
      if (parts.length < 2) return null;
      header = parts[0];

      // Check if second token is DLC (e.g. 08, 8, 04, 4, etc.)
      int dataStartIndex = 1;
      if (parts.length >= 3) {
        final int? dlc = int.tryParse(parts[1], radix: 16);
        final bool isExactDlcMatch = dlc != null && dlc > 0 && dlc == (parts.length - 2);
        final bool isExplicitDlcHeader = (parts[1] == '08' || parts[1] == '04') && parts.length != 9;
        if (isExactDlcMatch || isExplicitDlcHeader) {
          dataStartIndex = 2;
        }
      }

      for (int index = dataStartIndex; index < parts.length; index++) {
        final int? byteValue = int.tryParse(parts[index], radix: 16);
        if (byteValue != null) {
          dataBytes.add(byteValue);
        }
      }
    } else {
      // Unspaced format (e.g. 20A00000000000000 or 770081F40800000000000)
      if (clean.length < 5) return null;
      header = clean.substring(0, 3);
      String payloadHex = clean.substring(3);

      // Check for DLC prefix (e.g. 08 for 8 bytes, 04 for 4 bytes)
      if (payloadHex.length >= 18 && (payloadHex.startsWith('08') || payloadHex.startsWith('04'))) {
        final int? dlc = int.tryParse(payloadHex.substring(0, 2), radix: 16);
        if (dlc != null && dlc * 2 == payloadHex.length - 2) {
          payloadHex = payloadHex.substring(2);
        } else if (payloadHex.startsWith('08')) {
          payloadHex = payloadHex.substring(2);
        }
      } else if (payloadHex.length == 10 && payloadHex.startsWith('04')) {
        payloadHex = payloadHex.substring(2);
      }

      for (int i = 0; i < payloadHex.length - 1; i += 2) {
        final int? byteValue = int.tryParse(payloadHex.substring(i, i + 2), radix: 16);
        if (byteValue != null) {
          dataBytes.add(byteValue);
        }
      }
    }

    if (dataBytes.isEmpty) return null;

    // 0x20A frame: Powertrain broadcast (Bytes 0..1 = RPM, Byte 2 = TPS)
    if (header == '20A' || header == '020A') {
      if (dataBytes.length >= 2) {
        final int byte0 = dataBytes[0];
        final int byte1 = dataBytes[1];
        final double rpm = ((byte0 * 256.0) + byte1);
        double? tps;
        if (dataBytes.length >= 3) {
          final int byte2 = dataBytes[2];
          tps = (byte2 * 100.0) / 255.0;
        }
        return {'header': '20A', 'rpm': rpm, 'tps': tps};
      }
    }

    // 0x770 frame: RPM and TPS
    if (header == '770' || header == '0770') {
      if (dataBytes.length >= 2) {
        final int byte0 = dataBytes[0];
        final int byte1 = dataBytes[1];
        final double rpm = ((byte0 * 256.0) + byte1) / 4.0;
        double? tps;
        if (dataBytes.length >= 3) {
          final int byte2 = dataBytes[2];
          tps = (byte2 * 100.0) / 255.0;
        }
        return {'header': '770', 'rpm': rpm, 'tps': tps};
      }
    }

    // 0x212 frame: VVA bit
    if (header == '212' || header == '0212') {
      final int byte0 = dataBytes[0];
      final bool isVva = (byte0 & 0x01) != 0;
      return {'header': '212', 'vva': isVva};
    }

    // 0x236 frame: ECT temperature
    if (header == '236' || header == '0236') {
      final int byte0 = dataBytes[0];
      final double ect = (byte0 - 40).toDouble();
      return {'header': '236', 'ect': ect};
    }

    // 0x240 frame: STFT, LTFT, O2
    if (header == '240' || header == '0240') {
      double? stft;
      double? ltft;
      double? o2;
      if (dataBytes.isNotEmpty) {
        stft = ((dataBytes[0] - 128.0) * 100.0) / 128.0;
      }
      if (dataBytes.length >= 2) {
        ltft = ((dataBytes[1] - 128.0) * 100.0) / 128.0;
      }
      if (dataBytes.length >= 3) {
        o2 = dataBytes[2] / 200.0;
      }
      return {'header': '240', 'stft': stft, 'ltft': ltft, 'o2': o2};
    }

    return null;
  }
}
