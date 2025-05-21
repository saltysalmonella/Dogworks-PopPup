# PopPup Collar Firmware

This firmware is for the ESP32-based wearable collar tag in the PopPup system. It uses UWB for ranging and BLE for communication with the mobile application.

## Hardware Requirements (Example)
- ESP32 Development Board (specific model, e.g., ESP32-WROOM-32)
- UWB Module (specific model, e.g., DWM1000)
- Battery and power management circuit
- (Any other specific components)

## Functionality
- Measures distance to UWB Nodes.
- Transmits ranging data and status via BLE.
- Receives game mode commands via BLE.

## Building and Flashing
- This project is built using PlatformIO.
- Connect the ESP32 board to your computer.
- Open this project folder in VSCode with the PlatformIO extension.
- Use the PlatformIO "Build" and "Upload" tasks.
- Configuration for UWB address and BLE names can be found in `src/configs/`. (Note: Verify this path is accurate or adjust as needed based on actual config file locations if different).

Refer to the main project [README.md](../../../README.md) for an overview of the entire PopPup system.
