import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_record_model.dart';
import 'dart:convert';
import 'dart:async';

class StatisticsService with ChangeNotifier {
  static final StatisticsService _instance = StatisticsService._internal();
  
  factory StatisticsService() {
    return _instance;
  }
  
  StatisticsService._internal() {
    // Load saved data on initialization
    _loadPersistedData();
  }
  
  // Game statistics
  double _topSpeed = 0.0;
  double _distanceTraveled = 0.0;
  double _energyBurned = 0.0;
  int _playTime = 0;
  int _gamesPlayed = 0;
  int _nodesOpened = 0;
  List<GameRecord> _gameHistory = [];
  
  // Storage keys
  static const String _keyTopSpeed = 'topSpeed';
  static const String _keyDistanceTraveled = 'distanceTraveled';
  static const String _keyEnergyBurned = 'energyBurned';
  static const String _keyPlayTime = 'playTime';
  static const String _keyGamesPlayed = 'gamesPlayed';
  static const String _keyNodesOpened = 'nodesOpened';
  static const String _keyGameHistory = 'gameHistory';
  
  // Getters
  double get topSpeed => _topSpeed;
  double get distanceTraveled => _distanceTraveled;
  double get energyBurned => _energyBurned;
  int get playTime => _playTime;
  int get gamesPlayed => _gamesPlayed;
  int get nodesOpened => _nodesOpened;
  List<GameRecord> get gameHistory => List.unmodifiable(_gameHistory);

  
  // Load data from shared preferences
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _topSpeed = prefs.getDouble(_keyTopSpeed) ?? 0.0;
      _distanceTraveled = prefs.getDouble(_keyDistanceTraveled) ?? 0.0;
      _energyBurned = prefs.getDouble(_keyEnergyBurned) ?? 0.0;
      _playTime = prefs.getInt(_keyPlayTime) ?? 0;
      _gamesPlayed = prefs.getInt(_keyGamesPlayed) ?? 0;
      _nodesOpened = prefs.getInt(_keyNodesOpened) ?? 0;

            // Load game history
      final historyJson = prefs.getStringList(_keyGameHistory) ?? [];
      _gameHistory = historyJson.map((recordJson) {
        return GameRecord.fromJson(jsonDecode(recordJson));
      }).toList();
      
      notifyListeners();
      print('Statistics loaded from storage');
    } catch (e) {
      print('Error loading statistics data: $e');
    }
  }
  
  // Save data to shared preferences
  Future<void> _persistData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble(_keyTopSpeed, _topSpeed);
      await prefs.setDouble(_keyDistanceTraveled, _distanceTraveled);
      await prefs.setDouble(_keyEnergyBurned, _energyBurned);
      await prefs.setInt(_keyPlayTime, _playTime);
      await prefs.setInt(_keyGamesPlayed, _gamesPlayed);
      await prefs.setInt(_keyNodesOpened, _nodesOpened);

      final historyJson = _gameHistory.map((record) {
        return jsonEncode(record.toJson());
      }).toList();
      await prefs.setStringList(_keyGameHistory, historyJson);
      
      print('Statistics saved to storage');
    } catch (e) {
      print('Error saving statistics data: $e');
    }
  }

    // Add a new game record
  Future<void> addGameRecord(GameRecord record) async {
    _gameHistory.insert(0, record);
    
    // Update top statistics if new records are set
    if (record.topSpeed > _topSpeed) {
      _topSpeed = record.topSpeed;
    }
    
    _distanceTraveled += record.distance;
    _energyBurned += record.energyBurned;
    _playTime += record.duration;
    
    // Save updated data
    await _persistData();
    
    notifyListeners();
  }
  
  // Load statistics 
  Future<void> loadStatistics() async {
    // Load from storage
    await _loadPersistedData();
    notifyListeners();
  }
  
  // Update top speed if the new value is higher
  Future<void> updateTopSpeed(double speed) async {
    if (speed > _topSpeed) {
      _topSpeed = speed;
      await _persistData();
      notifyListeners();
    }
  }
  
  // Add to distance traveled
  Future<void> addDistance(double distance) async {
    if (distance > 0) {
      _distanceTraveled += distance;
      await _persistData();
      notifyListeners();
    }
  }
  
  // Add to energy burned
  Future<void> addEnergy(double energy) async {
    if (energy > 0) {
      _energyBurned += energy;
      await _persistData();
      notifyListeners();
    }
  }
  
  // Add to play time
  Future<void> addPlayTime(int minutes) async {
    if (minutes > 0) {
      _playTime += minutes;
      await _persistData();
      notifyListeners();
    }
  }
  
  // Increment games played
  Future<void> incrementGamesPlayed() async {
    _gamesPlayed++;
    await _persistData();
    notifyListeners();
  }
  
  // Increment nodes opened
  Future<void> incrementNodesOpened() async {
    _nodesOpened++;
    await _persistData();
    notifyListeners();
  }
  
  // Reset all statistics
  Future<void> resetStatistics() async {
    _topSpeed = 0.0;
    _distanceTraveled = 0.0;
    _energyBurned = 0.0;
    _playTime = 0;
    _gamesPlayed = 0;
    _nodesOpened = 0;
    _gameHistory = [];
    
    // Save the reset data
    await _persistData();
    
    notifyListeners();
  }
}