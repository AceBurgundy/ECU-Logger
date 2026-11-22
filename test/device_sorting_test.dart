// BLE = Bluetooth Low Energy
// OBD = On-Board Diagnostics
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ecu_logger/services/ble_service.dart';

void main() {
  group('BLE Device Discovery & Sorting Tests', () {
    test('checkIsObd identifies NexLink MAC address', () {
      final bool isObd = BleService.checkIsObd('8c:de:52:df:42:c3', 'Unknown', <Guid>[]);
      expect(isObd, isTrue);
    });

    test('checkIsObd identifies OBD keyword names', () {
      expect(BleService.checkIsObd('AA:BB:CC:DD:EE:FF', 'NEXAS25011921', <Guid>[]), isTrue);
      expect(BleService.checkIsObd('AA:BB:CC:DD:EE:FF', 'NexLink OBD', <Guid>[]), isTrue);
      expect(BleService.checkIsObd('AA:BB:CC:DD:EE:FF', 'VLINK-IOS', <Guid>[]), isTrue);
      expect(BleService.checkIsObd('AA:BB:CC:DD:EE:FF', 'Samsung Smart TV', <Guid>[]), isFalse);
    });

    test('checkIsObd identifies FFF0 OBD service UUID', () {
      final Guid fff0Guid = Guid('0000fff0-0000-1000-8000-00805f9b34fb');
      expect(BleService.checkIsObd('AA:BB:CC:DD:EE:FF', 'Unknown BLE Device', <Guid>[fff0Guid]), isTrue);
    });

    test('BleDiscoveredDevice sorting puts NexLink and OBD devices first', () {
      final List<BleDiscoveredDevice> devices = <BleDiscoveredDevice>[
        BleDiscoveredDevice(id: '11:22:33:44:55:66', name: 'Unknown BLE Device', rssi: -40, isObd: false),
        BleDiscoveredDevice(id: '22:33:44:55:66:77', name: 'Smart TV', rssi: -30, isObd: false),
        BleDiscoveredDevice(id: '8C:DE:52:DF:42:C3', name: 'NEXAS25011921', rssi: -60, isObd: true),
        BleDiscoveredDevice(id: '33:44:55:66:77:88', name: 'OBDII Scanner', rssi: -70, isObd: true),
      ];

      devices.sort((BleDiscoveredDevice a, BleDiscoveredDevice b) {
        final bool aTarget = a.id.toUpperCase().contains('8C:DE:52:DF:42:C3') ||
            a.name.toUpperCase().contains('NEXAS') ||
            a.name.toUpperCase().contains('NEXLINK');
        final bool bTarget = b.id.toUpperCase().contains('8C:DE:52:DF:42:C3') ||
            b.name.toUpperCase().contains('NEXAS') ||
            b.name.toUpperCase().contains('NEXLINK');
        if (aTarget && !bTarget) return -1;
        if (!aTarget && bTarget) return 1;

        if (a.isObd && !b.isObd) return -1;
        if (!a.isObd && b.isObd) return 1;

        final bool aNamed = a.name.isNotEmpty && a.name != 'Unknown BLE Device';
        final bool bNamed = b.name.isNotEmpty && b.name != 'Unknown BLE Device';
        if (aNamed && !bNamed) return -1;
        if (!aNamed && bNamed) return 1;

        return b.rssi.compareTo(a.rssi);
      });

      expect(devices[0].id, equals('8C:DE:52:DF:42:C3'));
      expect(devices[1].name, equals('OBDII Scanner'));
      expect(devices[2].name, equals('Smart TV'));
      expect(devices[3].name, equals('Unknown BLE Device'));
    });
  });
}
