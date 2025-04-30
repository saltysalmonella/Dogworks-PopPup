// UWB Pins
#define SPI_SCK 1
#define SPI_MISO 2
#define SPI_MOSI 3
#define DW_CS 4
#define PIN_RST 5
#define PIN_IRQ 6

// // Battery monitoring
// #define BATT_PIN 35
// #define LOW_BATTERY_THRESHOLD 20  // percentage

// Motor Control Pins - BTS7960
#define RPWM_PIN 19  // Right PWM - Forward
#define LPWM_PIN 21  // Left PWM - Backward
#define R_EN_PIN 18  // Right Enable
#define L_EN_PIN 23  // Left Enable

// Encoder Pins
#define ENCODER_A 34
#define ENCODER_B 35

// BLE UUIDs
#define SERVICE_UUID           "4faf1001-2222-1000-8000-00805f9b34fb"
#define CONTROL_CHAR_UUID      "4faf1002-2222-1000-8000-00805f9b34fb"
#define STATUS_CHAR_UUID     "4faf1003-2222-1000-8000-00805f9b34fb"
#define UWB_DATA_CHAR_UUID     "4faf1004-2222-1000-8000-00805f9b34fb"

#define ANCHOR_ADDR "B2:8F:3A:C1:74:29:6D:AE"

