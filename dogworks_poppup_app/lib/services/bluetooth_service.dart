import 'dart:async';
// import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';
import '../config/app_config.dart';
import '../models/device_model.dart';
import 'uwb_service.dart';
import 'dart:convert';

class BluetoothService with ChangeNotifier {
  static final BluetoothService _instance = BluetoothService._internal();
  
  factory BluetoothService() {
    return _instance;
  }
  
  BluetoothService._internal() {
    _init();
  }
  
  final List<GameDevice> _collars = [];
  final List<GameDevice> _nodes = [];
  bool _isScanning = false;
  AvailabilityState? _bleState;
  
  // Getters
  List<GameDevice> get collars => List.unmodifiable(_collars);
  List<GameDevice> get nodes => List.unmodifiable(_nodes);
  bool get isScanning => _isScanning;
  AvailabilityState? get bleState => _bleState;
  
  // Initialize the BLE service
  void _init() {
    // Set timeout for BLE operations
    UniversalBle.timeout = const Duration(seconds: AppConfig.bleConnectionTimeout);
    
    // Listen for availability changes
    UniversalBle.onAvailabilityChange = (state) {
      _bleState = state;
      notifyListeners();
    };
    
    // Process scan results
    UniversalBle.onScanResult = (result) {
      _processScanResult(result);
    };
    
    // Listen for connection state changes
    UniversalBle.onConnectionChange = (deviceId, isConnected, error) {
      _handleConnectionChange(deviceId, isConnected, error);
    };
    
    // Listen for characteristic value changes
    UniversalBle.onValueChange = (deviceId, characteristicId, value) {
      _handleValueChange(deviceId, characteristicId, value);
    };
  }
  
  // Process scan results and organize into collars and nodes
  void _processScanResult(BleDevice device) {
    // Skip devices without a name or that don't have our required prefixes
    if (device.name == null) return;
    
    // Create a new game device
    final deviceType = GameDevice.determineType(device);
    final gameDevice = GameDevice(bleDevice: device, type: deviceType);
    
    // Check if already exists
    if (deviceType == DeviceType.collar) {
      _addOrUpdateDevice(_collars, gameDevice);
    } else {
      _addOrUpdateDevice(_nodes, gameDevice);
    }
    
    notifyListeners();
  }
  
  // Handle connection state changes
  void _handleConnectionChange(String deviceId, bool isConnected, String? error) {
    // Update connection state for device
    GameDevice? device = _findDeviceById(deviceId);
    
    if (device != null) {
      device.isConnected = isConnected;
      device.isPaired = isConnected;
      
      if (isConnected) {
        // When connected, discover services to find the appropriate characteristics
        _discoverDeviceServices(device);
      } else {
        // Clear service cache on disconnect
        device.clearServiceCache();
      }
      
      notifyListeners();
    }
  }
  
  // Handle characteristic value changes
  void _handleValueChange(String deviceId, String characteristicId, Uint8List value) {
    GameDevice? device = _findDeviceById(deviceId);
    
    if (device != null) {
      if (device.type == DeviceType.node) {
        // Handle node status updates
        if (characteristicId.toLowerCase().startsWith(AppConfig.nodeStatusCharacteristicUuidPrefix.toLowerCase())) {
          try {
            // Convert the binary data to a string
            final jsonString = String.fromCharCodes(value);
            print("Received node status update: $jsonString");
            
            try {
              // Parse the JSON data
              final Map<String, dynamic> jsonData = jsonDecode(jsonString);
              
              // Check if the 'open' field exists in the JSON
              if (jsonData.containsKey('open')) {
                final openValue = jsonData['open'];
                
                // Convert to bool if it's an integer (1 = true, 0 = false)
                bool isOpen = openValue is int ? openValue == 1 : openValue == true;
                
                print("Updating node status: isOpen = $isOpen");
                device.isOpen = isOpen;
                notifyListeners();
              }
            } catch (jsonError) {
              print("JSON parsing failed, falling back to first byte: $jsonError");
              
              // Fallback to checking the first byte
              if (value.isNotEmpty) {
                device.isOpen = value[0] == 1;
                notifyListeners();
              }
            }
          } catch (e) {
            // If we can't parse as a string, just use the first byte
            print("String conversion failed, checking first byte: $e");
            if (value.isNotEmpty) {
              device.isOpen = value[0] == 1;
              notifyListeners();
            }
          }
        }
        // Handle UWB data from nodes if they provide it
        else if (characteristicId.toLowerCase().startsWith(AppConfig.nodeUwbDataCharacteristicUuidPrefix.toLowerCase())) {
          try {
            final jsonString = String.fromCharCodes(value);
            print("Received node UWB data: $jsonString");
            
            // Forward to UWB service for processing
            final uwbService = UwbService();
            uwbService.processUwbData(device.id, jsonString);
          } catch (e) {
            print("Error forwarding node UWB data: $e");
          }
        }
      } else if (device.type == DeviceType.collar) {
        // Handle collar position updates
        if (characteristicId.toLowerCase().startsWith(AppConfig.collarPositionCharacteristicUuidPrefix.toLowerCase())) {
          // Handle position data from collar
          print("Received collar position data");
        }
        // Handle UWB data from collars
        else if (characteristicId.toLowerCase().startsWith(AppConfig.collarUwbDataCharacteristicUuidPrefix.toLowerCase())) {
          try {
            final jsonString = String.fromCharCodes(value);
            print("Received collar UWB data: $jsonString");
            
            // Forward to UWB service for processing
            final uwbService = UwbService();
            uwbService.processUwbData(device.id, jsonString);
          } catch (e) {
            print("Error forwarding collar UWB data: $e");
          }
        }
      }
    }
  }
  
  // Find device by ID across both collars and nodes
  GameDevice? _findDeviceById(String deviceId) {
    for (var device in _collars) {
      if (device.id == deviceId) return device;
    }
    
    for (var device in _nodes) {
      if (device.id == deviceId) return device;
    }
    
    return null;
  }
  
  // Helper to add or update a device in the list
  void _addOrUpdateDevice(List<GameDevice> list, GameDevice newDevice) {
    int index = list.indexWhere((e) => e.id == newDevice.id);
    if (index == -1) {
      list.add(newDevice);
    } else {
      // Preserve connection state and service cache if updating
      newDevice.isConnected = list[index].isConnected;
      newDevice.isPaired = list[index].isPaired;
      newDevice.discoveredServiceUuid = list[index].discoveredServiceUuid;
      newDevice.controlCharacteristicUuid = list[index].controlCharacteristicUuid;
      newDevice.statusCharacteristicUuid = list[index].statusCharacteristicUuid;
      newDevice.uwbDataCharacteristicUuid = list[index].uwbDataCharacteristicUuid;
      
      if (newDevice.type == DeviceType.node) {
        newDevice.isOpen = list[index].isOpen;
      }
      list[index] = newDevice;
    }
  }
  
  // Start scanning for devices
  Future<void> startScan() async {
    if (_isScanning) return;
    
    _isScanning = true;
    notifyListeners();
    
    try {
      await UniversalBle.startScan(
        scanFilter: ScanFilter(
          withNamePrefix: AppConfig.deviceNamePrefixes,
        ),
      );
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Stop scanning
  Future<void> stopScan() async {
    if (!_isScanning) return;
    
    await UniversalBle.stopScan();
    _isScanning = false;
    notifyListeners();
  }
  
  // Connect to a device
  Future<void> connect(GameDevice device) async {
    try {
      await UniversalBle.connect(device.id);
      // Connection state will be updated in the _handleConnectionChange callback
    } catch (e) {
      rethrow;
    }
  }
  
  // Disconnect from a device
  Future<void> disconnect(GameDevice device) async {
    try {
      await UniversalBle.disconnect(device.id);
      // Connection state will be updated in the _handleConnectionChange callback
    } catch (e) {
      rethrow;
    }
  }
  
  // Discover services for a device and identify characteristics with matching prefixes
  Future<void> _discoverDeviceServices(GameDevice device) async {
    try {
      final services = await UniversalBle.discoverServices(device.id);
      
      // For nodes, look for the node service and control/status characteristics by prefix
      if (device.type == DeviceType.node) {
        _findAndCacheServiceCharacteristics(
          device, 
          services, 
          AppConfig.nodeServiceUuidPrefix,
          AppConfig.nodeControlCharacteristicUuidPrefix,
          AppConfig.nodeStatusCharacteristicUuidPrefix,
          AppConfig.nodeUwbDataCharacteristicUuidPrefix
        );
      } 
      // For collars, look for the collar service and control/position characteristics by prefix
      else if (device.type == DeviceType.collar) {
        _findAndCacheServiceCharacteristics(
          device, 
          services, 
          AppConfig.collarServiceUuidPrefix,
          AppConfig.collarControlCharacteristicUuidPrefix,
          AppConfig.collarPositionCharacteristicUuidPrefix,
          AppConfig.collarUwbDataCharacteristicUuidPrefix
        );
      }
    } catch (e) {
      print('Error discovering services: $e');
    }
  }
  
  // Find and cache service and characteristic UUIDs that match the given prefixes
  void _findAndCacheServiceCharacteristics(
    GameDevice device,
    List<BleService> services,
    String servicePrefix,
    String controlCharPrefix,
    String statusCharPrefix,
    String uwbCharPrefix,
  ) {
    // Look for service with matching prefix
    for (final service in services) {
      final serviceUuid = service.uuid.toLowerCase();
      
      // Check if service UUID starts with our prefix
      if (serviceUuid.startsWith(servicePrefix.toLowerCase())) {
        // Cache the full service UUID
        device.discoveredServiceUuid = service.uuid;
        
        // Look for characteristic UUIDs with matching prefixes
        for (final characteristic in service.characteristics) {
          final charUuid = characteristic.uuid.toLowerCase();
          
          // Check for control characteristic
          if (charUuid.startsWith(controlCharPrefix.toLowerCase())) {
            device.controlCharacteristicUuid = characteristic.uuid;
          } 
          // Check for status/position characteristic
          else if (charUuid.startsWith(statusCharPrefix.toLowerCase())) {
            device.statusCharacteristicUuid = characteristic.uuid;
            
            // Subscribe to notifications for status
            if (characteristic.properties.contains(CharacteristicProperty.notify) ||
                characteristic.properties.contains(CharacteristicProperty.indicate)) {
              _subscribeToNotifications(device.id, service.uuid, characteristic.uuid);
            }
          }

          else if (charUuid.startsWith(uwbCharPrefix.toLowerCase())) {
            device.uwbDataCharacteristicUuid = characteristic.uuid;
            
            // Subscribe to notifications for UWB data
            if (characteristic.properties.contains(CharacteristicProperty.notify) ||
                characteristic.properties.contains(CharacteristicProperty.indicate)) {
              _subscribeToNotifications(device.id, service.uuid, characteristic.uuid);
            }
          }
        }
        
        // If we found and cached the service, no need to continue
        if (device.discoveredServiceUuid != null) {
          break;
        }
      }
    }
  }
  
  // Subscribe to notifications for a characteristic
  Future<void> _subscribeToNotifications(String deviceId, String serviceUuid, String characteristicUuid) async {
    try {
      await UniversalBle.setNotifiable(
        deviceId,
        serviceUuid,
        characteristicUuid,
        BleInputProperty.notification,
      );
      print('Subscribed to notifications for $deviceId - $characteristicUuid');
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }
  
  // Toggle node (open/close)
  Future<void> toggleNode(GameDevice node, bool open) async {
    if (node.type != DeviceType.node || !node.isConnected) return;

    print('Toggling node ${node.id} to ${open ? "open" : "close"}');
    
    // Verify that we have discovered the necessary UUIDs
    if (node.discoveredServiceUuid == null || node.controlCharacteristicUuid == null) {
      // Attempt to discover services if not already cached
      await _discoverDeviceServices(node);
      
      // Check again after discovery
      if (node.discoveredServiceUuid == null || node.controlCharacteristicUuid == null) {
        throw 'Control characteristics not found for this node';
      }
    }
    
    try {
      // Send command to open or close
      final command = open ? AppConfig.cmdNodeOpen : AppConfig.cmdNodeClose;
      
      await UniversalBle.writeValue(
        node.id,
        node.discoveredServiceUuid!,
        node.controlCharacteristicUuid!,
        Uint8List.fromList([command]),
        BleOutputProperty.withResponse,
      );

      print('Node ${node.id} toggled to ${open ? "open" : "close"} with command $command');
      
      // Update node state (the actual confirmation will come from notifications)
      int index = _nodes.indexWhere((e) => e.id == node.id);
      if (index != -1) {
        _nodes[index].isOpen = open;
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling node: $e');
      rethrow;
    }
  }
  
  // Set game mode for devices
  Future<void> setGameMode(int modeCommand) async {
    // Update all connected devices
    final List<GameDevice> allDevices = [..._collars.where((c) => c.isConnected), ..._nodes.where((n) => n.isConnected)];
    
    for (final device in allDevices) {
      await _setDeviceGameMode(device, modeCommand);
    }
  }
  
  // Helper to set game mode for a specific device
  Future<void> _setDeviceGameMode(GameDevice device, int modeCommand) async {
    // Verify that we have discovered the necessary UUIDs
    if (device.discoveredServiceUuid == null || device.controlCharacteristicUuid == null) {
      // Attempt to discover services if not already cached
      await _discoverDeviceServices(device);
      
      // Check again after discovery
      if (device.discoveredServiceUuid == null || device.controlCharacteristicUuid == null) {
        print('Control characteristics not found for ${device.name}');
        return;
      }
    }
    
    try {
      await UniversalBle.writeValue(
        device.id,
        device.discoveredServiceUuid!,
        device.controlCharacteristicUuid!,
        Uint8List.fromList([modeCommand]),
        BleOutputProperty.withResponse,
      );
    } catch (e) {
      print('Error setting game mode for ${device.name}: $e');
    }
  }
  
  // Enable Bluetooth
  Future<bool> enableBluetooth() async {
    try {
      return await UniversalBle.enableBluetooth();
    } catch (e) {
      return false;
    }
  }
  
  // Clear all devices
  void clearDevices() {
    _collars.clear();
    _nodes.clear();
    notifyListeners();
  }
  
  // Get connected counts
  int get connectedCollarsCount => _collars.where((c) => c.isConnected).length;
  int get connectedNodesCount => _nodes.where((n) => n.isConnected).length;
}