import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';
import '../services/bluetooth_service.dart';
import '../widgets/device_list.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _bluetoothService.addListener(_refreshState);
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_refreshState);
    super.dispose();
  }

  void _refreshState() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleScan() async {
    setState(() {
      _loading = true;
    });

    try {
      if (_bluetoothService.isScanning) {
        await _bluetoothService.stopScan();
      } else {
        _bluetoothService.clearDevices();
        await _bluetoothService.startScan();
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Setup',
          style: TextStyle(
            fontSize: 30,
            fontFamily: 'Luckiest-Guy',
            color: Color(0xFF2B3674),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B3674)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BLE Status and Scan Control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Bluetooth Status: ${_bluetoothService.bleState?.name ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _bluetoothService.bleState != AvailabilityState.poweredOn
                    ? ElevatedButton(
                        onPressed: () async {
                          await _bluetoothService.enableBluetooth();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B3674),
                        ),
                        child: const Text('Enable BT'),
                      )
                    : const SizedBox(),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _toggleScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B3674),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : Text(
                      _bluetoothService.isScanning ? 'Stop Scan' : 'Start Scan',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),

            // Device Lists
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const TabBar(
                        tabs: [
                          Tab(text: 'Collars'),
                          Tab(text: 'Nodes'),
                        ],
                        labelColor: Color(0xFF2B3674),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF2B3674),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Collars List
                          DeviceListView(
                            devices: _bluetoothService.collars,
                            onConnect: (device) async {
                              try {
                                await _bluetoothService.connect(device);
                              } catch (e) {
                                _showErrorSnackbar('Failed to connect: ${e.toString()}');
                              }
                            },
                            onDisconnect: (device) async {
                              try {
                                await _bluetoothService.disconnect(device);
                              } catch (e) {
                                _showErrorSnackbar('Failed to disconnect: ${e.toString()}');
                              }
                            },
                          ),
                          
                          // Nodes List
                          DeviceListView(
                            devices: _bluetoothService.nodes,
                            onConnect: (device) async {
                              try {
                                await _bluetoothService.connect(device);
                              } catch (e) {
                                _showErrorSnackbar('Failed to connect: ${e.toString()}');
                              }
                            },
                            onDisconnect: (device) async {
                              try {
                                await _bluetoothService.disconnect(device);
                              } catch (e) {
                                _showErrorSnackbar('Failed to disconnect: ${e.toString()}');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}