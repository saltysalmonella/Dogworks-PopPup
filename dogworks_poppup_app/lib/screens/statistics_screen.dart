import 'package:flutter/material.dart';
import '../services/statistics_service.dart';
import '../widgets/stat_card_widget.dart';
import '../screens/play_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statsService = StatisticsService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _statsService.addListener(_refreshUI);
  }
  
  @override
  void dispose() {
    _statsService.removeListener(_refreshUI);
    super.dispose();
  }
  
  void _refreshUI() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _statsService.loadStatistics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load statistics: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resetStatistics() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Statistics'),
        content: const Text('Are you sure you want to reset all statistics? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                _isLoading = true;
              });
              
              await _statsService.resetStatistics();
              
              setState(() {
                _isLoading = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics have been reset')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 32,
            fontFamily: 'Luckiest-Guy',
            color: Color(0xFF2B3674),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B3674)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _resetStatistics,
            tooltip: 'Reset Statistics',
          ),
        ],
      ),
      body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Performance',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Luckiest-Guy',
                color: Color(0xFF2B3674),
              ),
            ),
            const SizedBox(height: 12),
            
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // important!
              children: [
                StatCardWidget(
                  title: 'Top Speed',
                  value: '${_statsService.topSpeed.toStringAsFixed(1)} m/s',
                  icon: Icons.speed,
                  color: Colors.blue,
                ),
                StatCardWidget(
                  title: 'Distance Traveled',
                  value: '${_statsService.distanceTraveled.toStringAsFixed(1)} m',
                  icon: Icons.straighten,
                  color: Colors.orange,
                ),
                StatCardWidget(
                  title: 'Energy Burned',
                  value: '${_statsService.energyBurned.toStringAsFixed(1)} cal',
                  icon: Icons.local_fire_department,
                  color: Colors.red,
                ),
                StatCardWidget(
                  title: 'Play Time',
                  value: '${_statsService.playTime} min',
                  icon: Icons.timer,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Gameplay Summary Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gameplay Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Luckiest-Guy',
                        color: Color(0xFF2B3674),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('Games Played', _statsService.gamesPlayed.toString(), Icons.sports_esports),
                        _buildSummaryItem('Nodes Opened', _statsService.nodesOpened.toString(), Icons.door_sliding),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_statsService.gamesPlayed > 0 || _statsService.nodesOpened > 0)
              Card(
                color: Colors.blue[50],
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Game Tips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B3674),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildGameTip(),
                    ],
                  ),
                ),
              ),

            if (_statsService.gamesPlayed == 0 &&
                _statsService.nodesOpened == 0 &&
                _statsService.distanceTraveled == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_esports, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 24),
                      Text(
                        'No Play Statistics Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Statistics are automatically recorded as you play',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('START PLAYING'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B3674),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PlayScreen()),
                          );
                        },
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
  
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2B3674),
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B3674),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildGameTip() {
    // Provide different tips based on the player's statistics
    if (_statsService.gamesPlayed < 3) {
      return const Text(
        'Try playing in Auto mode to see how the game automatically responds to collar proximity!',
        style: TextStyle(fontSize: 14),
      );
    } else if (_statsService.nodesOpened < 10) {
      return const Text(
        'Opening more nodes leads to more exercise for your pet. Try a longer play session!',
        style: TextStyle(fontSize: 14),
      );
    } else {
      return const Text(
        'For optimal play, distribute nodes around your space to maximize movement distance.',
        style: TextStyle(fontSize: 14),
      );
    }
  }
}