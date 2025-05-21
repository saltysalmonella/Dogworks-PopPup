# PopPup

## Overview

PopPup is an interactive pet game system that uses Ultra-Wideband (UWB) for precise ranging and Bluetooth Low Energy (BLE) for communication. The system includes a wearable collar tag for pets and stationary nodes that can dispense treats or activate a mechanism, providing engaging experiences for pets and their owners.

## System Components

- **PopPup Collar:** An ESP32-based wearable tag for pets, equipped with UWB for precise distance measurement and BLE for communication with the mobile app.
- **PopPup Node:** An ESP32-based stationary device with UWB and BLE. It features a motor-controlled mechanism (e.g., for dispensing treats or opening/closing a compartment) that can be triggered manually via the app or automatically based on the collar's proximity.
- **PopPup Mobile App:** A Flutter-based application for iOS and Android that allows users to monitor distances, manually control Nodes, configure game modes, and view device statuses.

## Features

- Accurate distance tracking between Collar and Nodes using UWB technology.
- BLE communication for data transfer and control between ESP32 devices and the mobile app.
- Remote control of Node mechanisms (e.g., open/close) via the mobile app.
- Multiple game modes (e.g., Manual, Auto) for different interaction styles.
- Automatic Node activation based on the detected proximity of the Collar in 'Auto' mode.
- Real-time status updates from Collar and Nodes (e.g., battery level, Node open/closed state) in the mobile app.

## Repository Structure

- `/ESP32 Code`: Contains the firmware for the PopPup Collar and PopPup Node devices (PlatformIO projects).
    - `/ESP32 Code/PopPup Collar`: Source code for the wearable collar tag.
    - `/ESP32 Code/PopPup Node`: Source code for the stationary interactive node.
- `/dogworks_poppup_app`: Contains the source code for the Flutter-based mobile application.

## Getting Started (High-Level)

Setting up the PopPup system involves programming the ESP32 devices (Collar and Node) and building/installing the Flutter mobile application. Detailed instructions for each component can be found in their respective README files within the subdirectories.

## License

This project is currently not licensed. Please add a license file if you intend to distribute it.
