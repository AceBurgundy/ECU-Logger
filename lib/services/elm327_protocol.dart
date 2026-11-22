// CAN = Controller Area Network
// PID = Parameter Identification
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
// IAT = Intake Air Temperature
// DLC = Data Length Code
// VVA = Variable Valve Actuation

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
        .trim();
  }

  /// Parses Mode 01 PID 0C response to engine speed in RPM.
  /// Formula: ((A * 256) + B) / 4
  static double? parseMode01Rpm(String response) {
    final String clean = response.replaceAll(' ', '').toUpperCase();
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
    final String clean = response.replaceAll(' ', '').toUpperCase();
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
    final String clean = response.replaceAll(' ', '').toUpperCase();
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
    final String clean = response.replaceAll(' ', '').toUpperCase();
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
    final String clean = response.replaceAll(' ', '').toUpperCase();
    final int targetIndex = clean.indexOf('410F');
    if (targetIndex != -1 && clean.length >= targetIndex + 6) {
      final int? byteA = int.tryParse(clean.substring(targetIndex + 4, targetIndex + 6), radix: 16);
      if (byteA != null) {
        return (byteA - 40).toDouble();
      }
    }
    return null;
  }

  /// Parses Yamaha broadcast CAN frames (0x770 for RPM/TPS, 0x212 for VVA bit).
  // dynamic required here: polymorphic CAN frame data structure contains strings, doubles, and booleans
  static Map<String, dynamic>? parseRawCanFrame(String line) {
    final List<String> parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    final String header = parts[0].toUpperCase();
    
    // Check if second token is DLC (e.g. 08, 8, 04, 4, etc.)
    int dataStartIndex = 1;
    if (parts.length >= 3) {
      final int? dlc = int.tryParse(parts[1], radix: 16);
      if (dlc != null &&
          (dlc == parts.length - 2 ||
              (parts[1].length == 2 && parts[1].startsWith('0') && dlc <= 8))) {
        dataStartIndex = 2;
      }
    }

    final List<int> dataBytes = <int>[];
    for (int index = dataStartIndex; index < parts.length; index++) {
      final int? byteValue = int.tryParse(parts[index], radix: 16);
      if (byteValue != null) {
        dataBytes.add(byteValue);
      }
    }

    if (dataBytes.isEmpty) return null;

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

    return null;
  }
}
