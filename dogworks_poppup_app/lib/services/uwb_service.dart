import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import '../models/uwb_data_model.dart';
import '../config/app_config.dart';
import '../services/statistics_service.dart';

class UwbService with ChangeNotifier {
  static final UwbService _instance = UwbService._internal();
  
  factory UwbService() {
    return _instance;
  }
  
  // Data storage
  final Map<String, UwbData> _deviceUwbData = {}; // DeviceID -> UwbData
  final StatisticsService _statsService = StatisticsService();
  
  // Initialization
  UwbService._internal() {
    print("UwbService initialized");
  }
  
  // Getters
  Map<String, UwbData> get deviceUwbData => Map.unmodifiable(_deviceUwbData);
  
  // Process UWB data from a device
  void processUwbData(String deviceId, String jsonData) {
    try {
      print("Processing UWB data for device $deviceId: $jsonData");
      
      // Parse JSON data into UwbData object
      final uwbData = UwbData.fromJsonString(jsonData);
      
      // Store the data
      _deviceUwbData[deviceId] = uwbData;
      
      // Debug: Print the parsed links
      for (final link in uwbData.links) {
        print("Parsed link - Anchor: ${link.anchorAddress}, Range: ${link.range} m${link.rxPower != null ? ", Power: ${link.rxPower} dBm" : ""}");
      }
      
      // Update statistics
      _updateStatistics(deviceId, uwbData);
      
      // Notify listeners that new data is available
      notifyListeners();
    } catch (e) {
      print('Error processing UWB data: $e');
    }
  }
  
  // Automatically update statistics based on UWB data
  void _updateStatistics(String deviceId, UwbData uwbData) {
    // Find the closest node
    final closestLink = uwbData.findClosestLink();
    if (closestLink != null) {
      // Update movement speed if significant change from last data
      if (_deviceUwbData.containsKey(deviceId)) {
        final lastData = _deviceUwbData[deviceId]!;
        final lastClosestLink = lastData.findClosestLink();
        
        if (lastClosestLink != null && 
            lastClosestLink.anchorAddress == closestLink.anchorAddress) {
          // Calculate approximate speed (m/s) based on change in range
          final timeDiff = uwbData.timestamp.difference(lastData.timestamp).inMilliseconds / 1000.0;
          if (timeDiff > 0) {
            final rangeDiff = (closestLink.range - lastClosestLink.range).abs();
            final speed = rangeDiff / timeDiff;
            
            // Update top speed if it's significant (above noise threshold)
            if (speed > 0.1 && speed < 10.0) { // Filter out noise
              _statsService.updateTopSpeed(speed);
              // Add a small distance increment based on movement
              _statsService.addDistance(rangeDiff);
            }
          }
        }
      }
    }
  }
  
  // Check if a collar is close to a specific node
  bool isCollarCloseToNode(GameDevice collar, GameDevice node) {
    if (!_deviceUwbData.containsKey(collar.id)) {
      print("No UWB data found for collar ${collar.name}");
      return false;
    }
    
    final collarUwbData = _deviceUwbData[collar.id]!;
    final nodeAddr = _extractUwbAddressFromName(node.name);
    
    if (nodeAddr == null) {
      print("Could not extract UWB address from node name: ${node.name}");
      return false;
    }
    
    print("Looking for node address: $nodeAddr in collar UWB data");
    
    // Find the link that matches this node's address
    for (final link in collarUwbData.links) {
      print("Comparing link address: ${link.anchorAddress} with node address: $nodeAddr");
      
      if (link.anchorAddress.toUpperCase() == nodeAddr.toUpperCase()) {
        final isClose = link.range <= AppConfig.uwbProximityThreshold;
        print("Collar ${collar.name} ${isClose ? 'IS' : 'is NOT'} close to node ${node.name}. Distance: ${link.range}m");
        return isClose;
      }
    }
    
    // No matching link found
    print("No link found between collar ${collar.name} and node ${node.name}");
    return false;
  }
  
  // Get the closest node to a collar
  GameDevice? getClosestNodeToCollar(GameDevice collar, List<GameDevice> nodes) {
    if (!_deviceUwbData.containsKey(collar.id)) return null;
    
    final collarUwbData = _deviceUwbData[collar.id]!;
    final closestLink = collarUwbData.findClosestLink();
    
    if (closestLink == null) return null;
    
    // Find the node that matches the closest link's address
    for (final node in nodes) {
      final nodeAddr = _extractUwbAddressFromName(node.name);
      if (nodeAddr != null && nodeAddr.toUpperCase() == closestLink.anchorAddress.toUpperCase()) {
        return node;
      }
    }
    
    return null;
  }
  
  // Get all links from a collar that are within threshold distance
  List<UwbLink> getLinksWithinThreshold(GameDevice collar, double threshold) {
    if (!_deviceUwbData.containsKey(collar.id)) return [];
    
    final collarUwbData = _deviceUwbData[collar.id]!;
    return collarUwbData.links.where((link) => link.range <= threshold).toList();
  }
  
  // Helper to extract UWB address from device name
  String? _extractUwbAddressFromName(String deviceName) {
    // Extract 4-byte prefix from device names like "PopPup-Node-8217" or "PopPup-Collar-7D00"
    RegExp regexPrefix = RegExp(r'PopPup-(Node|Collar)-([0-9A-F]{4})', caseSensitive: false);
    final matchPrefix = regexPrefix.firstMatch(deviceName);
    if (matchPrefix != null) {
      return matchPrefix.group(2);
    }
    
    // Fallback for legacy or different name formats
    // First try to extract hex address in format: 1234 or 12:34
    RegExp regexHex = RegExp(r'([0-9A-F]{2}:?[0-9A-F]{2})', caseSensitive: false);
    final matchHex = regexHex.firstMatch(deviceName);
    if (matchHex != null) {
      return matchHex.group(1)?.replaceAll(':', '');
    }
    
    // For nodes that might have names like "Node-1", "Node-2"
    RegExp regexNum = RegExp(r'Node[^0-9]*([0-9]+)', caseSensitive: false);
    final matchNum = regexNum.firstMatch(deviceName);
    if (matchNum != null) {
      // Convert numeric ID to hex format expected by UWB code
      int? nodeId = int.tryParse(matchNum.group(1) ?? '');
      if (nodeId != null) {
        return nodeId.toRadixString(16).padLeft(4, '0');
      }
    }
    
    return null;
  }
  
  // Clear all data
  void clearData() {
    _deviceUwbData.clear();
    notifyListeners();
  }
}