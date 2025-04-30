class AppConfig {
  // BLE Configuration
  static const int bleConnectionTimeout = 10; // in seconds
  static const int bleScanDuration = 15; // in seconds
  
  // Service and Characteristic UUID Prefixes
  // Each device will have its own unique full UUID, but all will start with these prefixes
  static const String nodeServiceUuidPrefix = "4faf1001";
  static const String nodeControlCharacteristicUuidPrefix = "4faf1002";
  static const String nodeStatusCharacteristicUuidPrefix = "4faf1003";
  static const String nodeUwbDataCharacteristicUuidPrefix = "4faf1004";
  
  static const String collarServiceUuidPrefix = "4faf2001";
  static const String collarControlCharacteristicUuidPrefix = "4faf2002";
  static const String collarPositionCharacteristicUuidPrefix = "4faf2003";
  static const String collarUwbDataCharacteristicUuidPrefix = "4faf2004";
  
  // Command values
  static const int cmdNodeOpen = 1;
  static const int cmdNodeClose = 0;
  static const int cmdNonePlayMode = 10;
  static const int cmdAutoPlayMode = 11;
  static const int cmdManualPlayMode = 12;
  
  
  // UWB Configuration
  static const double uwbProximityThreshold = 3; // meters
  static const int uwbDataRefreshInterval = 50; // milliseconds
  
  // Motor Configuration
  static const int motorStopValue = 0;
  static const int motorOpenValue = 1;
  static const int motorCloseValue = 2;
  
  // Scan filter configuration
  static const List<String> deviceNamePrefixes = ["PopPup"];
  static const List<String> serviceUuids = ["4faf"];
}