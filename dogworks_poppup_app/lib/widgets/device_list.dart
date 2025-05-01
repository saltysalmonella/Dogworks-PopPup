import 'package:flutter/material.dart';
import '../models/device_model.dart';

// This widget displays a list of game devices, allowing the user to connect or disconnect from them.
// It shows the device name, status (paired or available), and provides buttons for connection actions.

class DeviceListView extends StatelessWidget {
  final List<GameDevice> devices;
  final Function(GameDevice) onConnect;
  final Function(GameDevice) onDisconnect;

  const DeviceListView({
    Key? key,
    required this.devices,
    required this.onConnect,
    required this.onDisconnect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const Center(
        child: Text(
          'No devices found. Start scan to discover devices.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            title: Text(
              device.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              device.isPaired ? 'Paired' : 'Available',
              style: TextStyle(
                color: device.isPaired ? Colors.green : Colors.grey,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                if (device.isPaired) {
                  onDisconnect(device);
                } else {
                  onConnect(device);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: device.isPaired
                    ? Colors.red[400]
                    : const Color(0xFF2B3674),
                minimumSize: const Size(100, 36),
              ),
              child: Text(
                device.isPaired ? 'Disconnect' : 'Connect',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}