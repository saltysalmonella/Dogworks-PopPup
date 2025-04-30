import 'package:universal_ble/universal_ble.dart';

enum DeviceType { collar, node }

class GameDevice {
  final BleDevice bleDevice;
  final DeviceType type;
  bool isConnected = false;
  bool isPaired = false;
  
  // For nodes specifically
  bool isOpen = false;

  // Service and characteristic caching - full UUIDs unique to each device
  String? discoveredServiceUuid;
  String? controlCharacteristicUuid;
  String? statusCharacteristicUuid;
  String? uwbDataCharacteristicUuid;

  GameDevice({required this.bleDevice, required this.type});

  String get name => bleDevice.name ?? 'Unknown Device';
  String get id => bleDevice.deviceId;
  
  // Helper method to determine device type based on name
  static DeviceType determineType(BleDevice device) {
    final name = device.name?.toLowerCase() ?? '';
    if (name.contains('collar') || name.contains('poppup-collar')) {
      return DeviceType.collar;
    } else {
      return DeviceType.node;
    }
  }
  
  // Clear cached service and characteristic information
  void clearServiceCache() {
    discoveredServiceUuid = null;
    controlCharacteristicUuid = null;
    statusCharacteristicUuid = null;
    uwbDataCharacteristicUuid = null;
  }
  
  // Check if we have all the necessary UUIDs to communicate with this device
  bool get hasRequiredServiceInfo {
    return discoveredServiceUuid != null; 
  }
  
  @override
  String toString() {
    return 'GameDevice{name: $name, type: $type, isConnected: $isConnected, isOpen: $isOpen}';
  }
}