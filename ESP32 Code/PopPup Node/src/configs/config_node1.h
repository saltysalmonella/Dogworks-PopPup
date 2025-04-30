// Node 1 Config (First Working Node)

// UWB Pins
#define SPI_SCK 18
#define SPI_MISO 19
#define SPI_MOSI 23
#define DW_CS 4
#define PIN_RST 27
#define PIN_IRQ 34

// // Battery monitoring
// #define BATT_PIN 35
// #define LOW_BATTERY_THRESHOLD 20  // percentage

// Motor Control Pins - BTS7960
#define RPWM_PIN 26  // Right PWM - Forward
#define LPWM_PIN 14  // Left PWM - Backward
#define R_EN_PIN 25  // Right Enable
#define L_EN_PIN 13  // Left Enable

// Encoder Pins
#define ENCODER_A 36
#define ENCODER_B 39

// BLE UUIDs
#define SERVICE_UUID           "4faf1001-1111-1000-8000-00805f9b34ff"
#define CONTROL_CHAR_UUID      "4faf1002-1111-1000-8000-00805f9b34ff"
#define STATUS_CHAR_UUID     "4faf1003-1111-1000-8000-00805f9b34ff"
#define UWB_DATA_CHAR_UUID     "4faf1004-1111-1000-8000-00805f9b34ff"

#define ANCHOR_ADDR "88:10:5B:D5:A9:9A:E2:9F"

