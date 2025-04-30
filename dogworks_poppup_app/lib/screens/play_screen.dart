import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/game_service.dart';
import '../widgets/node_control_widget.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({Key? key}) : super(key: key);

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  // Services
  final BluetoothService _bluetoothService = BluetoothService();
  final GameService _gameService = GameService();
  
  @override
  void initState() {
    super.initState();
    
    // Listen for changes in bluetooth and game services
    _bluetoothService.addListener(_refreshState);
    _gameService.addListener(_refreshState);
  }

  @override
  void dispose() {
    // Remove listeners
    _bluetoothService.removeListener(_refreshState);
    _gameService.removeListener(_refreshState);
    
    // End play session
    _gameService.endPlaySession();
    
    super.dispose();
  }

  // UI refresh when underlying data changes
  void _refreshState() {
    if (mounted) {
      setState(() {});
    }
  }

  // Show error messages
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  // Get current mode text
  String _getModeText() {
    switch (_gameService.currentMode) {
      case PlayMode.none:
        return 'No Mode Active';
      case PlayMode.manual:
        return 'Manual Play';
      case PlayMode.auto:
        return 'Auto Play';
    }
  }
  
  // Get current mode color
  Color _getModeColor() {
    switch (_gameService.currentMode) {
      case PlayMode.none:
        return Colors.grey;
      case PlayMode.manual:
        return Colors.blue;
      case PlayMode.auto:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedCollars = _bluetoothService.connectedCollarsCount;
    final connectedNodes = _bluetoothService.connectedNodesCount;
    final currentMode = _gameService.currentMode;
    final isAutoPlay = currentMode == PlayMode.auto;
    final isManualPlay = currentMode == PlayMode.manual;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Play',
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected Collars: $connectedCollars',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Connected Nodes: $connectedNodes',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mode: ${_getModeText()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getModeColor(),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    connectedCollars > 0 && connectedNodes > 0
                        ? Icons.check_circle
                        : Icons.warning,
                    color: connectedCollars > 0 && connectedNodes > 0
                        ? Colors.green
                        : Colors.orange,
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Play Mode Selection
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _gameService.setPlayMode(
                      isAutoPlay ? PlayMode.none : PlayMode.auto
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAutoPlay
                          ? const Color(0xFF2B3674)
                          : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                    child: Text(
                      'Auto Play',
                      style: TextStyle(
                        color: isAutoPlay ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _gameService.setPlayMode(
                      isManualPlay ? PlayMode.none : PlayMode.manual
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isManualPlay
                          ? const Color(0xFF2B3674)
                          : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    child: Text(
                      'Manual Play',
                      style: TextStyle(
                        color: isManualPlay ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Node Controls Section
            const Text(
              'Node Controls',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B3674),
              ),
            ),
            const SizedBox(height: 16),
            
            // Node List
            Expanded(
              child: _bluetoothService.nodes.where((n) => n.isConnected).isEmpty
                  ? const Center(
                      child: Text(
                        'No connected nodes found.\nPlease connect nodes in the Setup screen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _bluetoothService.nodes.length,
                      itemBuilder: (context, index) {
                        final node = _bluetoothService.nodes[index];
                        
                        // Only show connected nodes
                        if (!node.isConnected) {
                          return const SizedBox.shrink();
                        }
                        
                        // Determine if controls should be enabled based on mode
                        // In none mode, both open and close are enabled
                        // In manual mode, only open is controllable (close is automatic)
                        // In auto mode, both open and close are disabled
                        final bool canOpen = currentMode != PlayMode.auto;
                        final bool canClose = currentMode == PlayMode.none;
                        
                        return NodeControlWidget(
                          node: node,
                          isAutoPlayMode: isAutoPlay,
                          isPlayModeActive: true,
                          canOpen: canOpen,
                          canClose: canClose,
                          onToggle: (isOpen) async {
                            try {
                              if (isOpen) {
                                await _gameService.openNode(node);
                              } else {
                                await _gameService.closeNode(node);
                              }
                            } catch (e) {
                              _showErrorSnackbar('Failed to control node: ${e.toString()}');
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}