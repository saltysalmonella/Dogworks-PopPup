class GameRecord {
  final String date;
  final int duration;
  final double distance;
  final double topSpeed;
  final double energyBurned;

  GameRecord({
    required this.date,
    required this.duration,
    required this.distance,
    required this.topSpeed,
    required this.energyBurned,
  });
  
  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'duration': duration,
      'distance': distance,
      'topSpeed': topSpeed,
      'energyBurned': energyBurned,
    };
  }
  
  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      date: json['date'] as String,
      duration: json['duration'] as int,
      distance: json['distance'] as double,
      topSpeed: json['topSpeed'] as double,
      energyBurned: json['energyBurned'] as double,
    );
  }
}