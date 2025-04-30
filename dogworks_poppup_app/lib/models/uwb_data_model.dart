import 'dart:convert';

class UwbLink {
  final String anchorAddress;
  final double range;
  final double? rxPower;

  UwbLink({
    required this.anchorAddress,
    required this.range,
    this.rxPower,
  });

  factory UwbLink.fromJson(Map<String, dynamic> json) {
    // Handle both the old and new format
    if (json.containsKey('A') && json.containsKey('R')) {
      // New format from collar
      return UwbLink(
        anchorAddress: json['A'] as String,
        range: _parseDoubleFromString(json['R']),
        rxPower: json.containsKey('P') ? _parseDoubleFromString(json['P']) : null,
      );
    } else {
      // Older format
      return UwbLink(
        anchorAddress: json['anchorAddress'] as String? ?? '',
        range: (json['range'] as num?)?.toDouble() ?? 0.0,
        rxPower: (json['rxPower'] as num?)?.toDouble(),
      );
    }
  }

  // Helper method to safely parse doubles from strings
  static double _parseDoubleFromString(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double from string: $value');
      }
    }
    return 0.0; // Default value if parsing fails
  }

  Map<String, dynamic> toJson() {
    return {
      'anchorAddress': anchorAddress,
      'range': range,
      if (rxPower != null) 'rxPower': rxPower,
    };
  }
}

class UwbData {
  final List<UwbLink> links;
  final DateTime timestamp;

  UwbData({required this.links, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  factory UwbData.fromJson(Map<String, dynamic> json) {
    List<UwbLink> linksList = [];
    
    // Check for new collar format (direct single reading)
    if (json.containsKey('A') && json.containsKey('R')) {
      // Single link directly in the JSON (not in a list)
      linksList.add(UwbLink.fromJson(json));
    } 
    // Check for older format with links array
    else if (json.containsKey('links') && json['links'] is List) {
      linksList = (json['links'] as List)
          .map((linkJson) => UwbLink.fromJson(linkJson))
          .toList();
    }
    
    return UwbData(links: linksList);
  }

  factory UwbData.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return UwbData.fromJson(json);
    } catch (e) {
      print('Error parsing UWB data: $e');
      return UwbData(links: []);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'links': links.map((link) => link.toJson()).toList(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Find the closest link
  UwbLink? findClosestLink() {
    if (links.isEmpty) return null;
    
    return links.reduce((current, next) => 
      current.range < next.range ? current : next);
  }
  
  // Find all links with range below threshold
  List<UwbLink> findLinksWithinRange(double threshold) {
    return links.where((link) => link.range <= threshold).toList();
  }
  
  // Check if any link is within threshold
  bool hasLinkWithinRange(double threshold) {
    return links.any((link) => link.range <= threshold);
  }
}