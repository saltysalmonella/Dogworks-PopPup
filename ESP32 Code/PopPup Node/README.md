# PopPup Node Firmware

This firmware is for the ESP32-based stationary node in the PopPup system. It uses UWB for ranging, BLE for communication, and controls a motor mechanism.

## Hardware Requirements (Example)
- ESP32 Development Board (specific model, e.g., ESP32-WROOM-32)
- UWB Module (specific model, e.g., DWM1000)
- Motor Driver (specific model, e.g., L298N)
- DC Motor with Encoder
- Power supply
- (Any other specific components like limit switches if used)

## Functionality
- Measures distance to UWB Collar tags.
- Transmits ranging data and status (e.g., open/closed state, motor status) via BLE.
- Receives control commands (e.g., open, close, set mode) via BLE.
- Operates a motor-driven mechanism with encoder feedback and stall detection.
- Can operate in an automatic mode based on collar proximity.

## Building and Flashing
- This project is built using PlatformIO.
- Connect the ESP32 board to your computer.
- Open this project folder in VSCode with the PlatformIO extension.
- Use the PlatformIO "Build" and "Upload" tasks.
- Configuration for UWB address and BLE names can be found in `src/configs/`. (Note: Verify this path is accurate or adjust as needed based on actual config file locations if different).

Refer to the main project [README.md](../../../README.md) for an overview of the entire PopPup system.
