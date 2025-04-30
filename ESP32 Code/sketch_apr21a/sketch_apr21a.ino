#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLECharacteristic.h>
#include <BLE2902.h>

// Define UUIDs (same as in the Flutter app)
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914c"
#define LED_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define MESSAGE_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// Define GPIO pin for the LED
#define LED_PIN 26  // Built-in LED on many ESP32 development boards

BLEServer *pServer = NULL;
BLECharacteristic *pLedCharacteristic = NULL;
BLECharacteristic *pMessageCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
int messageCount = 0;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

class LedCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = String(pCharacteristic->getValue().c_str());

      if (rxValue.length() > 0) {
        Serial.print("Received Value: ");
        Serial.println(rxValue);  // Directly print String
        
        if (rxValue == "1") {
          digitalWrite(LED_PIN, HIGH);
          Serial.println("LED ON");
        } else if (rxValue == "0") {
          digitalWrite(LED_PIN, LOW);
          Serial.println("LED OFF");
        }
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Start");
  
  // Initialize LED pin
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);  // Initially OFF
  
  // Create the BLE Device
  BLEDevice::init("PopPup-Collar-0001");

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristics
  pLedCharacteristic = pService->createCharacteristic(
                         LED_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_WRITE
                       );
  pLedCharacteristic->setCallbacks(new LedCallbacks());

  pMessageCharacteristic = pService->createCharacteristic(
                             MESSAGE_CHARACTERISTIC_UUID,
                             BLECharacteristic::PROPERTY_READ |
                             BLECharacteristic::PROPERTY_NOTIFY
                           );
  pMessageCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE LED Controller ready to connect");
}

void loop() {
  // Send a message to the connected client every 5 seconds
  if (deviceConnected) {
    // Create message using char array and sprintf to avoid String class
    char message[50];
    sprintf(message, "Message from ESP32: %d", messageCount++);
    
    // Set the value as a C-string
    pMessageCharacteristic->setValue(message);
    pMessageCharacteristic->notify();
    
    // Print to serial
    Serial.print("Sent: ");
    Serial.println(message);
    
    delay(5000);  // Send a message every 5 seconds
  }
  
  // Handle connection state changes
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);  // Give the Bluetooth stack time to get ready
    pServer->startAdvertising();  // Restart advertising
    Serial.println("Started advertising again");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}