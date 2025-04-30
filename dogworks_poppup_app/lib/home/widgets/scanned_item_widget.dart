import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

class ScannedItemWidget extends StatelessWidget {
  final BleDevice bleDevice;
  final Function onTap;

  const ScannedItemWidget({
    Key? key,
    required this.bleDevice,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        bleDevice.name ?? 'Unknown Device',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        'RSSI: ${bleDevice.rssi} | ID: ${bleDevice.deviceId.substring(0, 10)}...',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onTap(),
    );
  }
}