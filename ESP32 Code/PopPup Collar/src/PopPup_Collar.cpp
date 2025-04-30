/*
  PopPup Collar ESP32 Code - Simplified (No link.cpp)

  This code is for the ESP32 collar (tag) device used in the PopPup game.
  It combines UWB ranging with Bluetooth connectivity to the mobile app.
  Sends JSON with Anchor Address (Short Hex), Filtered Range, and RX Power.

  Hardware:
  - ESP32 with UWB module
  - Battery management

  Libraries needed:
  - ESP32 BLE
  - DW1000Ranging
  - ArduinoJson
*/

#include <SPI.h>
#include <DW1000Ranging.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
// #include "link.h" // REMOVED

#ifdef POPPUP_COLLAR_1
#include "configs/config_collar1.h"
// #elif defined(PopPup_Collar2)
// #include "configs/config_node2.h"
#endif

// Function Declarations
void setupUWB();
void setupBLE();
void newRange();
void newDevice(DW1000Device *device);   // Kept for logging, but doesn't modify data structures
void inactiveDevice(DW1000Device *device); // Kept for logging
// void updateUwbData(); // REMOVED
// void updatePosition(); // REMOVED
void checkBattery(); // Keep stub if needed later
void handleBleConnections();
String getAddressPrefix(const char* address); 

// Game modes
#define MODE_NONE 0
#define MODE_MANUAL 1
#define MODE_AUTO 2

// UWB Variables
// struct MyLink *uwb_data; // REMOVED
// String all_json = ""; // REMOVED - JSON generated locally in newRange
// unsigned long lastUwbUpdate = 0; // REMOVED
// const int uwbUpdateInterval = 100; // REMOVED

// Range Filtering Variables
float lastValidRange = -1.0;         // Initialize to invalid state
const float MAX_RANGE_JUMP = 5.0;    // Max allowed jump in meters
const float MIN_VALID_RANGE = 0.0;   // Minimum plausible range
const float MAX_VALID_RANGE = 100.0; // Maximum plausible range (adjust as needed)

// BLE Variables
BLEServer *pServer = NULL;
BLECharacteristic *pControlCharacteristic = NULL;
// BLECharacteristic* pPositionCharacteristic = NULL; // REMOVED (or comment out if maybe needed later)
BLECharacteristic *pUwbDataCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
int gameMode = MODE_MANUAL;
uint8_t batteryLevel = 100; // Assuming 100% initially, update with checkBattery()

// Class for BLE server callbacks
class ServerCallbacks : public BLEServerCallbacks
{
    void onConnect(BLEServer *pServer)
    {
        deviceConnected = true;
        // Reset last valid range on new connection? Optional.
        // lastValidRange = -1.0;
    };

    void onDisconnect(BLEServer *pServer)
    {
        deviceConnected = false;
    }
};

// Class for control characteristic callbacks
class ControlCharCallbacks : public BLECharacteristicCallbacks
{
    void onWrite(BLECharacteristic *pCharacteristic)
    {
        std::string value = pCharacteristic->getValue();

        if (value.length() > 0)
        {
            uint8_t command = value[0];
            Serial.print("Received command: ");
            Serial.println(command);

            // Process commands
            switch (command)
            {
            case 10: // None mode
                gameMode = MODE_NONE;
                Serial.println("Set to NONE mode");
                break;
            case 11: // Auto mode
                gameMode = MODE_AUTO;
                Serial.println("Set to AUTO mode");
                break;
            case 12: // Manual mode
                gameMode = MODE_MANUAL;
                Serial.println("Set to MANUAL mode");
                break;
            default:
                Serial.println("Unknown command");
                break;
            }
            // Optionally update a status characteristic if needed
        }
    }
};

void setup()
{
    Serial.begin(115200);
    while (!Serial); // Wait for serial connection (optional)
    Serial.println("PopPup Collar starting...");

    // Initialize UWB
    setupUWB();

    // Initialize BLE
    setupBLE();

    // Setup battery monitoring
    // pinMode(BATT_PIN, INPUT);

    Serial.println("PopPup Collar ready");
}

void loop()
{
    // Handle UWB ranging (this will trigger newRange callback)
    DW1000Ranging.loop();

    // Check battery level periodically if implemented
    // checkBattery();

    // BLE connection management
    handleBleConnections();

    // No need to call updateUwbData here anymore

    delay(10); // Small delay to prevent CPU overload and allow ESP-IDF tasks
}

void setupUWB()
{
    Serial.println("Initializing UWB...");

    // Initialize SPI and DW1000
    SPI.begin(SPI_SCK, SPI_MISO, SPI_MOSI);
    DW1000Ranging.initCommunication(PIN_RST, DW_CS, PIN_IRQ);

    // Attach callbacks
    DW1000Ranging.attachNewRange(newRange);
    DW1000Ranging.attachNewDevice(newDevice);
    DW1000Ranging.attachInactiveDevice(inactiveDevice);

    // Start as tag (our collar is a UWB tag)
    DW1000Ranging.startAsTag(TAG_ADDR, DW1000.MODE_LONGDATA_RANGE_LOWPOWER, false);

    // Initialize data structure - REMOVED
    // uwb_data = init_link();

    Serial.println("UWB initialized");
}

void setupBLE()
{
    Serial.println("Initializing BLE...");

    String addressPrefix = getAddressPrefix(TAG_ADDR);
    String deviceName = "PopPup-Collar-" + addressPrefix;
    BLEDevice::init(deviceName.c_str());

    // Create the BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    // Create the BLE Service
    BLEService *pService = pServer->createService(SERVICE_UUID);

    // Create BLE Characteristics
    pControlCharacteristic = pService->createCharacteristic(
        CONTROL_CHAR_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
    pControlCharacteristic->setCallbacks(new ControlCharCallbacks());
    // Initialize control characteristic if needed (e.g., with current mode)
    pControlCharacteristic->setValue((uint8_t *)&gameMode, 1);

    // REMOVED Position Characteristic
    /*
    pPositionCharacteristic = pService->createCharacteristic(
      POSITION_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_NOTIFY
    );
    pPositionCharacteristic->addDescriptor(new BLE2902());
    */

    pUwbDataCharacteristic = pService->createCharacteristic(
        UWB_DATA_CHAR_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
    pUwbDataCharacteristic->addDescriptor(new BLE2902()); // Add descriptor for notifications

    // Start the service
    pService->start();

    // Start advertising
    BLEAdvertisementData advData;
    advData.setName(deviceName.c_str());
    advData.setCompleteServices(BLEUUID(SERVICE_UUID));

    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->setAdvertisementData(advData);
    pAdvertising->setScanResponse(true); // Allow scanning for name/services
    pAdvertising->setMinPreferred(0x06); // Values for faster connection iOS
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("BLE initialized, advertising started");
}

void newRange()
{
    // Called when a new UWB range is measured
    DW1000Device *distantDevice = DW1000Ranging.getDistantDevice();
    float currentRange = distantDevice->getRange();
    float rxPower = distantDevice->getRXPower();
    
    // Get the byte address of the device
    byte* deviceAddressBytes = distantDevice->getByteAddress();
    
    char addrStr[5]; //
    sprintf(addrStr, "%02X%02X", 
            deviceAddressBytes[8], deviceAddressBytes[9]);
    
    Serial.print("Raw data from: ");
    Serial.print(addrStr);
    Serial.print("\t Range: ");
    Serial.print(currentRange);
    Serial.print(" m");
    Serial.print("\t RX power: ");
    Serial.print(rxPower);
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

    // No need to call fresh_link or update other structures
}

void newDevice(DW1000Device *device)
{
    // We don't need to manage a list anymore, just log it.
    Serial.print("New device detected (logging only): ");
    Serial.println(device->getShortAddress(), HEX);
    // add_link(uwb_data, device->getShortAddress()); // REMOVED
}

void inactiveDevice(DW1000Device *device)
{
    // We don't need to manage a list anymore, just log it.
    Serial.print("Device inactive (logging only): ");
    Serial.println(device->getShortAddress(), HEX);
    // delete_link(uwb_data, device->getShortAddress()); // REMOVED

    // Optional: Consider resetting lastValidRange if the only active anchor goes inactive?
    // This depends on whether you expect to range with multiple anchors concurrently.
    // If only ever one anchor, maybe reset lastValidRange here:
    // lastValidRange = -1.0;
}

/*
// REMOVED - No longer needed
void updateUwbData() {
  // ...
}

// REMOVED - No longer needed
void updatePosition() {
  // ...
}
*/

// void checkBattery() {
//   // Implement battery check logic here if needed
//   // Read battery voltage and calculate percentage
//   // int rawValue = analogRead(BATT_PIN);
//   // ... calculate voltage ...
//   // batteryLevel = calculated_percentage;
// }

void handleBleConnections()
{
    // Disconnection handling
    if (!deviceConnected && oldDeviceConnected)
    {
        delay(500);                  // Give the Bluetooth stack time to settle before restarting advertising
        pServer->startAdvertising(); // Restart advertising
        Serial.println("BLE disconnected, advertising restarted");
        oldDeviceConnected = deviceConnected; // Update state
    }

    // Connection handling
    if (deviceConnected && !oldDeviceConnected)
    {
        // Actions to take on new connection
        Serial.println("BLE device connected");
        oldDeviceConnected = deviceConnected; // Update state
        // Consider resetting lastValidRange here too if desired on new connection
        // lastValidRange = -1.0;
    }
}

String getAddressPrefix(const char* address) {
  // Extract first 4 bytes (8 characters) from the address string
  // For example "82:17:5B:D5:A9:9A:E2:9C" -> "8217"
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