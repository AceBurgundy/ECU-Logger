class Elm327Protocol {
  static const List<String> initCommands = [
    'ATZ',    // Reset
    'ATE0',   // Echo Off
    'ATL0',   // Linefeeds Off
    'ATH1',   // Headers On (to capture CAN IDs)
    'ATSP6',  // ISO 15765-4 CAN (11 bit ID, 500 kbaud)
  ];

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

  // Parse Mode 01 PID responses: e.g. "41 0C 1F 40" -> RPM = ((1F * 256) + 40) / 4
  static double? parseMode01Rpm(String response) {
    final clean = response.replaceAll(' ', '').toUpperCase();
    final idx = clean.indexOf('410C');
    if (idx != -1 && clean.length >= idx + 8) {
      final a = int.tryParse(clean.substring(idx + 4, idx + 6), radix: 16);
      final b = int.tryParse(clean.substring(idx + 6, idx + 8), radix: 16);
      if (a != null && b != null) {
        return ((a * 256.0) + b) / 4.0;
      }
    }
    return null;
  }

  // Mode 01 PID 11: TPS % = (A * 100) / 255
  static double? parseMode01Tps(String response) {
    final clean = response.replaceAll(' ', '').toUpperCase();
    final idx = clean.indexOf('4111');
    if (idx != -1 && clean.length >= idx + 6) {
      final a = int.tryParse(clean.substring(idx + 4, idx + 6), radix: 16);
      if (a != null) {
        return (a * 100.0) / 255.0;
      }
    }
    return null;
  }

  // Mode 01 PID 0B: MAP kPa = A
  static double? parseMode01Map(String response) {
    final clean = response.replaceAll(' ', '').toUpperCase();
    final idx = clean.indexOf('410B');
    if (idx != -1 && clean.length >= idx + 6) {
      final a = int.tryParse(clean.substring(idx + 4, idx + 6), radix: 16);
      if (a != null) {
        return a.toDouble();
      }
    }
    return null;
  }

  // Mode 01 PID 05: ECT °C = A - 40
  static double? parseMode01Ect(String response) {
    final clean = response.replaceAll(' ', '').toUpperCase();
    final idx = clean.indexOf('4105');
    if (idx != -1 && clean.length >= idx + 6) {
      final a = int.tryParse(clean.substring(idx + 4, idx + 6), radix: 16);
      if (a != null) {
        return (a - 40).toDouble();
      }
    }
    return null;
  }

  // Mode 01 PID 0F: IAT °C = A - 40
  static double? parseMode01Iat(String response) {
    final clean = response.replaceAll(' ', '').toUpperCase();
    final idx = clean.indexOf('410F');
    if (idx != -1 && clean.length >= idx + 6) {
      final a = int.tryParse(clean.substring(idx + 4, idx + 6), radix: 16);
      if (a != null) {
        return (a - 40).toDouble();
      }
    }
    return null;
  }

  // Yamaha CAN Frame 0x770 / 0x20A / 0x212 parsing:
  // Can be in format "770 08 1F 40 80 ..." (with DLC byte) or "770 1F 40 80 ..."
  static Map<String, dynamic>? parseRawCanFrame(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    final header = parts[0].toUpperCase();
    
    // Check if second token is DLC (e.g. 08, 8, 04, 4, etc.)
    int dataStartIndex = 1;
    if (parts.length >= 3) {
      final dlc = int.tryParse(parts[1], radix: 16);
      if (dlc != null && (dlc == parts.length - 2 || parts[1].length == 2 && parts[1].startsWith('0') && dlc <= 8)) {
        dataStartIndex = 2;
      }
    }

    final dataBytes = <int>[];
    for (int i = dataStartIndex; i < parts.length; i++) {
      final b = int.tryParse(parts[i], radix: 16);
      if (b != null) {
        dataBytes.add(b);
      }
    }

    if (dataBytes.isEmpty) return null;

    // 0x770 frame: RPM and TPS
    if (header == '770' || header == '0770') {
      if (dataBytes.length >= 2) {
        final d0 = dataBytes[0];
        final d1 = dataBytes[1];
        final rpm = ((d0 * 256.0) + d1) / 4.0;
        double? tps;
        if (dataBytes.length >= 3) {
          final d2 = dataBytes[2];
          tps = (d2 * 100.0) / 255.0;
        }
        return {'header': '770', 'rpm': rpm, 'tps': tps};
      }
    }

    // 0x212 frame: VVA bit
    if (header == '212' || header == '0212') {
      final d0 = dataBytes[0];
      final isVva = (d0 & 0x01) != 0;
      return {'header': '212', 'vva': isVva};
    }

    return null;
  }
}
