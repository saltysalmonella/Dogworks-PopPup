import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import '../services/bluetooth_service.dart';
import '../services/statistics_service.dart';
import '../services/uwb_service.dart';
import '../config/app_config.dart';

enum PlayMode {
  none,    // No automatic behavior, manual control only
  manual,  // Auto-close based on proximity, manual open
  auto     // Auto-close based on proximity, auto-open when another node closes
}

class GameService with ChangeNotifier {
  static final GameService _instance = GameService._internal();
  
  factory GameService() {
    return _instance;
  }
  
  // Services
  final BluetoothService _bluetoothService = BluetoothService();
  final UwbService _uwbService = UwbService();
  final StatisticsService _statsService = StatisticsService();
  
  // Game state
  PlayMode _currentMode = PlayMode.none;
  Timer? _autoPlayTimer;
  final List<GameDevice> _recentlyClosedNodes = [];
  DateTime? _sessionStartTime;
  bool _isSessionActive = false;
  final Map<String, DateTime> _nodeCloseTimestamps = {};
  Duration _nodeReopenDelay = const Duration(seconds: 1);
  
  // Initialize the service
  GameService._internal() {
    // Listen for UWB data updates to detect proximity
    _uwbService.addListener(_checkProximityAndTriggerNodes);
    
    // Start tracking play time
    _startPlaySession();
  }
  
  // Getters
  PlayMode get currentMode => _currentMode;
  
  // Set the play mode
  Future<void> setPlayMode(PlayMode mode) async {
    // If the mode is already active, do nothing
    if (_currentMode == mode) return;
    
    // Clean up before changing mode
    if (_currentMode == PlayMode.auto) {
      _stopAutoPlay();
    }
    
    // Update the mode
    _currentMode = mode;
    
    // Update device mode
    int modeCommand;
    switch (mode) {
      case PlayMode.none:
        modeCommand = AppConfig.cmdNonePlayMode;
        break;
      case PlayMode.manual:
        modeCommand = AppConfig.cmdManualPlayMode;
        break;
      case PlayMode.auto:
        modeCommand = AppConfig.cmdAutoPlayMode;
        _startAutoPlay();
        // Increment game counter when starting auto mode
        _statsService.incrementGamesPlayed();
        break;
    }
    
    // Send mode command to all connected devices
    await _bluetoothService.setGameMode(modeCommand);
    
    notifyListeners();
  }
  
  // Toggle between modes (none -> manual -> auto -> none)
  Future<void> toggleMode() async {
    switch (_currentMode) {
      case PlayMode.none:
        await setPlayMode(PlayMode.manual);
        break;
      case PlayMode.manual:
        await setPlayMode(PlayMode.auto);
        break;
      case PlayMode.auto:
        await setPlayMode(PlayMode.none);
        break;
    }
  }
  
  // Start auto play mode
  void _startAutoPlay() {
    // Start timer to periodically check if we need to open nodes
    _autoPlayTimer = Timer.periodic(
      const Duration(seconds: 1), 
      (_) => _checkAndOpenRandomNode()
    );
    
    // Clear recently closed nodes list
    _recentlyClosedNodes.clear();
  }
  
  // Stop auto play mode
  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    _recentlyClosedNodes.clear();
  }
  
  // Open a node
  Future<void> openNode(GameDevice node) async {
    if (!node.isConnected || node.isOpen) return;
    
    try {
      await _bluetoothService.toggleNode(node, true);
    } catch (e) {
      print('Error opening node: $e');
    }
  }
  
  // Close a node
  Future<void> closeNode(GameDevice node) async {
    if (!node.isConnected || !node.isOpen) return;
    
    try {
      await _bluetoothService.toggleNode(node, false);

      // Record the time when this node was closed
      _nodeCloseTimestamps[node.id] = DateTime.now();
      
      // In auto mode, add to recently closed nodes to trigger opening another one
      if (_currentMode == PlayMode.auto) {
        _recentlyClosedNodes.add(node);
        _checkAndOpenRandomNode();
      }
    } catch (e) {
      print('Error closing node: $e');
    }
  }
  
  // Check and open a random node when in auto mode
  void _checkAndOpenRandomNode() {
    if (_currentMode != PlayMode.auto) return;
    
    final connectedNodes = _bluetoothService.nodes.where((n) => n.isConnected).toList();
    if (connectedNodes.isEmpty) return;

    if (connectedNodes.length == 1) {
      _nodeReopenDelay = const Duration(seconds: 3);
    } else {
      _nodeReopenDelay = const Duration(seconds: 1);
    }
    
    // Count open and closed nodes
    final openNodes = connectedNodes.where((n) => n.isOpen).toList();
    final closedNodes = connectedNodes.where((n) => !n.isOpen).toList();


    final currentTime = DateTime.now();

    final availableClosedNodes = closedNodes.where((node) {
      final lastCloseTime = _nodeCloseTimestamps[node.id];
      if (lastCloseTime == null) return true;

      return currentTime.difference(lastCloseTime) >= _nodeReopenDelay;
    }).toList();
    
    if (_recentlyClosedNodes.isNotEmpty) {
      // If we have recently closed nodes and we have closed nodes available, open one
      if (availableClosedNodes.isNotEmpty) {
        // Filter out the recently closed nodes from available nodes to open
        final availableNodes = availableClosedNodes.where(
          (node) => !_recentlyClosedNodes.any((closedNode) => closedNode.id == node.id)
        ).toList();
        
        // If there are no available nodes (all closed nodes were recently closed),
        // then just use all closed nodes
        final nodesToSelectFrom = availableNodes.isNotEmpty ? availableNodes : closedNodes;
        
        // Open a random node from the available ones
        if (nodesToSelectFrom.isNotEmpty) {
          final random = Random();
          final nodeToOpen = nodesToSelectFrom[random.nextInt(nodesToSelectFrom.length)];
          openNode(nodeToOpen);
          
          // Clear recently closed nodes
          _recentlyClosedNodes.clear();
        }
      }
    } 
    // If no nodes are open at all and we have nodes, open one to start the game
    else if (openNodes.isEmpty && availableClosedNodes.isNotEmpty) {
      final random = Random();
      final nodeToOpen = availableClosedNodes[random.nextInt(availableClosedNodes.length)];
      openNode(nodeToOpen);
    }
  }
  
  // Check proximity between collar and nodes and trigger actions based on mode
  void _checkProximityAndTriggerNodes() {
    // Don't check proximity in none mode
    if (_currentMode == PlayMode.none) return;
    
    // Get all connected collars
    final connectedCollars = _bluetoothService.collars
        .where((collar) => collar.isConnected)
        .toList();
    
    // Get all connected nodes that are open
    final openNodes = _bluetoothService.nodes
        .where((node) => node.isConnected && node.isOpen)
        .toList();
    
    if (connectedCollars.isEmpty || openNodes.isEmpty) return;
    
    // Check each collar's proximity to each node
    for (final collar in connectedCollars) {
      // Check each open node
      for (final node in openNodes) {
        // Check if collar is close to this node
        if (_uwbService.isCollarCloseToNode(collar, node)) {
          // Close the node when collar is in proximity
          print("Collar ${collar.name} is close to node ${node.name}. Closing node.");
          closeNode(node);
        }
      }
    }
  }
  
  // Start tracking play session time
  void _startPlaySession() {
    if (!_isSessionActive) {
      _sessionStartTime = DateTime.now();
      _isSessionActive = true;
    }
  }
  
  // End the play session and record time
  void endPlaySession() {
    if (_isSessionActive && _sessionStartTime != null) {
      final now = DateTime.now();
      final minutes = now.difference(_sessionStartTime!).inMinutes;
      
      if (minutes > 0) {
        _statsService.addPlayTime(minutes);
      }
      
      _isSessionActive = false;
      _sessionStartTime = null;
    }
    
    // Clean up
    _stopAutoPlay();
  }
  
  @override
  void dispose() {
    _uwbService.removeListener(_checkProximityAndTriggerNodes);
    endPlaySession();
    super.dispose();
  }
}