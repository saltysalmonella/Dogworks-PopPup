/*
  PopPup Node ESP32
  
  This code is for the ESP32 node (anchor) device used in the PopPup device.
  It combines UWB ranging with Bluetooth connectivity to the mobile app.
*/

#include <SPI.h>
#include <DW1000Ranging.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>

#ifdef POPPUP_NODE_1 // Check if POPUP_NODE_1 is defined
#include "configs/config_node1.h"
#elif defined(POPPUP_NODE_2) // Check if POPUP_NODE_2 is defined
#include "configs/config_node2.h"
#endif

// Motor state definitions
#define MOTOR_IDLE 0
#define MOTOR_OPENING 1
#define MOTOR_CLOSING 2
#define MOTOR_STALLED 3

// Game modes
#define MODE_NONE 0
#define MODE_MANUAL 1
#define MODE_AUTO 2

// Command values
#define CMD_OPEN 1
#define CMD_CLOSE 0
#define CMD_NONE_MODE 10
#define CMD_AUTO_MODE 11
#define CMD_MANUAL_MODE 12

// BLE Variables
BLEServer* pServer = NULL;
BLECharacteristic* pControlCharacteristic = NULL;
BLECharacteristic* pStatusCharacteristic = NULL;
BLECharacteristic* pUwbDataCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
bool nodeIsOpen = false;
int gameMode = MODE_NONE;
uint8_t batteryLevel = 100;

// Motor Variables
volatile long encoderCount = 0;
const float PULSES_PER_REV = 370.0;
int motorState = MOTOR_IDLE;

// Motor Stall Variables
volatile long motorStartTime = 0;
const int stallGracePeriod = 500; // ms - motor stall timeout
const int stallCheckInterval = 150; // ms - interval to check for stall
const int safetyTimeout = 2000; // ms - max time for motor operation
volatile int lastEncoderValue = 0;
volatile long lastCheckedEncoderCount = 0;
const int minEncoderChange = 20; // Minimum encoder counts required to be considered not stalled
long lastStallCheck = 0;


// UWB Variables
volatile float currentRange = 100;
const float distanceThreshold = 1.0; // m - auto closing dist

int serialCounter = 0;

float lastValidRange = -1.0;         // Initialize to invalid state
const float MAX_RANGE_JUMP = 4.0;    // Max allowed jump in meters
const float MIN_VALID_RANGE = 0.0;   // Minimum plausible range
const float MAX_VALID_RANGE = 100.0; // Maximum plausible range 

// Function declarations
void openNode();
void closeNode();
void stopMotor();
void updateStatus();
void handleMotor();
void checkClose();
void setupUWB();
void setupBLE();
void newRange();
void newBlink(DW1000Device *device);
void inactiveDevice(DW1000Device *device);
// void checkBattery();
void handleBleConnections();
void updateStatusIfChanged();
String getAddressPrefix(const char* address);

// Class for BLE server callbacks
class ServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  };
  
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
  }
};

// Class for control characteristic callbacks
class ControlCharCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    
    if (value.length() > 0) {
      uint8_t command = value[0];
      Serial.print("Received command: ");
      Serial.println(command);
      
      // Process commands
      switch (command) {
        case CMD_OPEN: // Open command
          openNode();
          break;
        case CMD_CLOSE: // Close command
          closeNode();
          break; 
        case CMD_NONE_MODE: // None mode
          gameMode = MODE_NONE;
          Serial.println("Set to NONE mode");
          break;
        case CMD_AUTO_MODE: // Auto mode
          gameMode = MODE_AUTO;
          Serial.println("Set to AUTO mode");
          break;
        case CMD_MANUAL_MODE: // Manual mode
          gameMode = MODE_MANUAL;
          Serial.println("Set to MANUAL mode");
          break;
        default:
          Serial.println("Unknown command");
          break;
      }
    }
  }
};

void IRAM_ATTR encoderISR() {
  // Read encoder pins
  int A = digitalRead(ENCODER_A);
  int B = digitalRead(ENCODER_B);
  
  // Simple encoder processing
  if (A != lastEncoderValue) {
    lastEncoderValue = A;
    // Direction depends on the B value when A changes
    if (B != A) {
      encoderCount++;
    } else {
      encoderCount--;
    }
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("PopPup Node starting...");

  // Initialize motor control pins
  pinMode(RPWM_PIN, OUTPUT);
  pinMode(LPWM_PIN, OUTPUT);
  pinMode(R_EN_PIN, OUTPUT);
  pinMode(L_EN_PIN, OUTPUT);
  
  // Enable motor driver
  digitalWrite(R_EN_PIN, HIGH);
  digitalWrite(L_EN_PIN, HIGH);
  
  // Stop motor initially
  stopMotor();
  
  // Initialize encoder pins
  pinMode(ENCODER_A, INPUT_PULLUP);
  pinMode(ENCODER_B, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(ENCODER_A), encoderISR, CHANGE);
  
  // Initialize UWB
  setupUWB();
  
  // Initialize BLE
  setupBLE();
  
  Serial.println("PopPup Node ready");
}

void loop() {
  // Handle UWB ranging
  DW1000Ranging.loop();
  
  // Check motor state and handle motor control
  handleMotor();

  checkClose();
  
  // Check battery level
  // checkBattery();
  
  // BLE connection management
  handleBleConnections();
  
  // Update status if needed
  updateStatusIfChanged();

  delay(20); // Small delay to avoid busy loop
}

void setupUWB() {
  Serial.println("Initializing UWB...");
  
  // Initialize SPI and DW1000
  SPI.begin(SPI_SCK, SPI_MISO, SPI_MOSI);
  DW1000Ranging.initCommunication(PIN_RST, DW_CS, PIN_IRQ);
  
  // Attach callbacks
  DW1000Ranging.attachNewRange(newRange);
  DW1000Ranging.attachBlinkDevice(newBlink);
  DW1000Ranging.attachInactiveDevice(inactiveDevice);

  // Start as anchor (our node is a UWB anchor)
  DW1000Ranging.startAsAnchor(ANCHOR_ADDR, DW1000.MODE_LONGDATA_RANGE_LOWPOWER, false);
  
  Serial.println("UWB initialized");
}

void setupBLE() {
  Serial.println("Initializing BLE...");
  
  // Use the first 4 bytes of the address for the BLE name
  String addressPrefix = getAddressPrefix(ANCHOR_ADDR);
  
  // Create the BLE Device with address embedded in name
  String deviceName = "PopPup-Node-" + addressPrefix;
  BLEDevice::init(deviceName.c_str());

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristics
  pControlCharacteristic = pService->createCharacteristic(
    CONTROL_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE
  );
  pControlCharacteristic->setCallbacks(new ControlCharCallbacks());
  
  pStatusCharacteristic = pService->createCharacteristic(
    STATUS_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pStatusCharacteristic->addDescriptor(new BLE2902());

  pUwbDataCharacteristic = pService->createCharacteristic(
    UWB_DATA_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pUwbDataCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertisementData advData;
  advData.setName(deviceName.c_str());
  advData.setCompleteServices(BLEUUID(SERVICE_UUID));
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->setAdvertisementData(advData);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  // Update initial status
  updateStatus();
  
  Serial.println("BLE initialized, advertising started");
}

void newRange() {
  // Called when a new UWB range is measured
  DW1000Device *distantDevice = DW1000Ranging.getDistantDevice();
  currentRange = distantDevice->getRange();
  float rxPower = distantDevice->getRXPower();
  
  // Get the byte address of the device
  byte* deviceAddressBytes = distantDevice->getByteAddress();
  
  // Convert first 4 bytes to hex string for identification
  char addrStr[5]; // 8 hex chars + null terminator
  sprintf(addrStr, "%02X%02X", 
          deviceAddressBytes[0], deviceAddressBytes[1]);
  
  Serial.print("from: ");
  Serial.print(addrStr);
  Serial.print("\t Range: ");
  Serial.print(distantDevice->getRange());
  Serial.print(" m");
  Serial.print("\t RX power: ");
  Serial.print(distantDevice->getRXPower());
  Serial.println(" dBm");
  
    // --- Range Filtering ---
    // 1. Basic validity check
    if (currentRange < MIN_VALID_RANGE || currentRange > MAX_VALID_RANGE || !isfinite(currentRange)) {
      Serial.println("Range rejected: Outside valid bounds or NaN/Inf.");
      return; // Discard reading
  }

  // 2. Jump filter (only if we have a previous valid range)
  if (lastValidRange >= 0.0)
  { // Check if lastValidRange is valid
      if (abs(currentRange - lastValidRange) > MAX_RANGE_JUMP)
      {
          Serial.print("Range rejected: Jump too large. Current: ");
          Serial.print(currentRange);
          Serial.print(", Previous: ");
          Serial.println(lastValidRange);
          // Don't update lastValidRange, keep the old one
          return; // Discard reading
      }
       // If jump is acceptable, fall through to update lastValidRange
  }
   // If we reach here, the range is acceptable or it's the first valid reading
  lastValidRange = currentRange; // Update the last known valid range


  // --- JSON Creation ---
  StaticJsonDocument<100> doc; // Adjust size if needed

  doc["A"] = addrStr; // Anchor Address (Short Hex)
  // Use the filtered (accepted) range
  doc["R"] = serialized(String(lastValidRange, 2)); // Range, formatted to 2 decimal places
  doc["P"] = serialized(String(rxPower, 2));      // RX Power, formatted to 2 decimal places

  String jsonOutput;
  serializeJson(doc, jsonOutput);

  // Print JSON locally for debugging
  Serial.print("Filtered JSON: ");
  Serial.println(jsonOutput);

  // --- Send via BLE ---
  if (deviceConnected && pUwbDataCharacteristic != NULL)
  {
      pUwbDataCharacteristic->setValue(jsonOutput.c_str());
      pUwbDataCharacteristic->notify();
      Serial.println("Sent UWB data via BLE"); // Optional: Log BLE send
  }
}

void newBlink(DW1000Device *device) {
  // Get the byte address of the device
  byte* deviceAddressBytes = device->getByteAddress();
  
  // Convert first 4 bytes to hex string for identification
  char addrStr[5]; // 8 hex chars + null terminator
  sprintf(addrStr, "%02X%02X", 
          deviceAddressBytes[0], deviceAddressBytes[1]);
  
  Serial.print("New blink device: ");
  Serial.println(addrStr);
}

void inactiveDevice(DW1000Device *device) {
  // Get the byte address of the device
  byte* deviceAddressBytes = device->getByteAddress();
  
  // Convert first 4 bytes to hex string for identification
  char addrStr[5]; // 8 hex chars + null terminator
  sprintf(addrStr, "%02X%02X%02X%02X", 
          deviceAddressBytes[0], deviceAddressBytes[1]);
  
  Serial.print("Device inactive: ");
  Serial.println(addrStr);
}

void openNode() {
  if (motorState == MOTOR_OPENING) {
    Serial.println("Node already opening");
    return;
  } else if (motorState != MOTOR_OPENING) {
    Serial.println("Opening node");
    motorStartTime = millis();
    motorState = MOTOR_OPENING;
    encoderCount = 0;

    lastCheckedEncoderCount = 0;
    lastStallCheck = millis();
    
    // Start motor in opening direction
    // digitalWrite(R_EN_PIN, HIGH);
    // digitalWrite(L_EN_PIN, HIGH);
    analogWrite(LPWM_PIN, 0);
    analogWrite(RPWM_PIN, 255); // PWM value 0-255
    
    
    updateStatus();
    delay(200);
  }
}

void closeNode() {
  if (motorState == MOTOR_CLOSING) {
    Serial.println("Node already closing");
    return;
  } else if (motorState != MOTOR_CLOSING) {
    Serial.println("Closing node");
    motorStartTime = millis();
    motorState = MOTOR_CLOSING;
    encoderCount = 0;

    lastCheckedEncoderCount = 0;
    lastStallCheck = millis();
    
    // Start motor in closing direction
    // digitalWrite(R_EN_PIN, HIGH);
    // digitalWrite(L_EN_PIN, HIGH);
    analogWrite(RPWM_PIN, 0);
    analogWrite(LPWM_PIN, 255); // PWM value 0-255
    
    
    updateStatus();
    delay(200);
  }
}

void stopMotor() {
  // Stop both directions
  analogWrite(RPWM_PIN, 0);
  analogWrite(LPWM_PIN, 0);
  // digitalWrite(R_EN_PIN, LOW);
  // digitalWrite(L_EN_PIN, LOW);
  
  // Update state based on if opening or closing
  if (motorState == MOTOR_OPENING) {
    nodeIsOpen = true;
  } else if (motorState == MOTOR_CLOSING) {
    nodeIsOpen = false;
  }
  
  motorState = MOTOR_IDLE;
  updateStatus();
  delay(250);
  Serial.println("Motor stopped");
}

void handleMotor() {
  // Stall detection
  delay(20);
  if ((motorState == MOTOR_OPENING || motorState == MOTOR_CLOSING) && 
  (millis() - motorStartTime > stallGracePeriod)) {

    long encoderMovement = abs(encoderCount - lastCheckedEncoderCount);
    
    if (encoderMovement > 0) {
      Serial.print("Encoder movement: ");
      Serial.println(encoderMovement);
    }

    if (encoderMovement < minEncoderChange) {
      Serial.println("Motor stalled! Insufficient encoder movement.");
      stopMotor();
      delay(50);
      return;
    }
  }

  if ((millis() - lastStallCheck) > stallCheckInterval) {
    Serial.print("encoder stall diff:");
    Serial.println(encoderCount - lastCheckedEncoderCount);
    lastCheckedEncoderCount = encoderCount;
    lastStallCheck = millis();
  }

  Serial.print("encoder count: ");
  Serial.print(encoderCount);
  
  // Limit maximum time for motor operation
  if ((motorState == MOTOR_OPENING || motorState == MOTOR_CLOSING) && 
      (millis() - motorStartTime > safetyTimeout)) { // 5 second max operation time
    
    Serial.println("Motor timeout reached!");
    stopMotor();
    delay(200);
    return;
  }

  serialCounter++;

  if (serialCounter > 50000) {
    Serial.print("Encoder count: ");
    Serial.print(encoderCount);
    Serial.print("\tMotor state: ");
    Serial.print(motorState);
    Serial.print("\t Motor time: ");
    Serial.println(millis() - motorStartTime);
    serialCounter = 0;
  }

}

void checkClose() {
  if (gameMode == MODE_AUTO || gameMode == MODE_MANUAL) {
    // Check if the distance is gless than threshold
    if (lastValidRange < distanceThreshold) {
      Serial.println("Auto closing node");
      closeNode();
    }
  }
}

void updateStatus() {
  StaticJsonDocument<100> doc;
  
  doc["open"] = nodeIsOpen ? 1 : 0;
  doc["state"] = motorState;
  doc["batt"] = batteryLevel;
  doc["mode"] = gameMode;
  
  String json;
  serializeJson(doc, json);
  
  if (deviceConnected) {
    pStatusCharacteristic->setValue(json.c_str());
    pStatusCharacteristic->notify();
  }
  
  Serial.print("Status updated: ");
  Serial.println(json);
}
  
void updateStatusIfChanged() {
  static bool lastOpenState = nodeIsOpen;
  static int lastMotorState = motorState;
  static int lastGameMode = gameMode;
  
  if (lastOpenState != nodeIsOpen || lastMotorState != motorState || lastGameMode != gameMode) {
    updateStatus();
    
    lastOpenState = nodeIsOpen;
    lastMotorState = motorState;
    lastGameMode = gameMode;
  }
}

// void checkBattery() {
//   // Read battery voltage and calculate percentage
//   // This is just an example, adjust for your battery setup
//   int rawValue = analogRead(BATT_PIN);
//   float voltage = rawValue * (3.3 / 4095.0) * 2; // Assuming voltage divider
  
//   // Calculate approximate percentage (adjust for your battery)
//   batteryLevel = constrain(map(voltage, 3.3, 4.2, 0, 100), 0, 100);
  
//   // Low battery warning
//   static unsigned long lastBatteryWarning = 0;
//   if (batteryLevel < LOW_BATTERY_THRESHOLD && 
//       millis() - lastBatteryWarning > 60000) { // Warning every minute
//     Serial.println("WARNING: Low battery!");
//     lastBatteryWarning = millis();
//   }
// }

void handleBleConnections() {
  // Disconnection handling
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Give the Bluetooth stack time to get ready
    pServer->startAdvertising(); // Restart advertising
    Serial.println("BLE disconnected, advertising restarted");
    oldDeviceConnected = deviceConnected;
  }
  
  // Connection handling
  if (deviceConnected && !oldDeviceConnected) {
    // Connected
    Serial.println("BLE device connected");
    oldDeviceConnected = deviceConnected;
  }
}

String getAddressPrefix(const char* address) {
  // Extract first 4 bytes (8 characters) from the address string
  String prefix = "";
  int count = 0;
  for (int i = 0; address[i] != '\0' && count < 4; i++) {
    if (address[i] != ':') {
      prefix += address[i];
      count++;
    }
  }
  return prefix;
}