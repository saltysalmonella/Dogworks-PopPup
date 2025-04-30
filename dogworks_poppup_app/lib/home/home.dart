import 'package:flutter/material.dart';
import '../screens/setup_screen.dart';
import '../screens/play_screen.dart';
import '../screens/statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Section
                const Text(
                  'DOGWORKS',
                  style: TextStyle(
                    fontSize: 56,
                    fontFamily: 'Luckiest-Guy',
                    color: Color(0xFF2B3674),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2B3674), width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Dog logo
                      Image.asset(
                        'lib/assets/images/dog_logo.png',
                        height: 100,
                        width: 300,
                      ),
                      const SizedBox(height: 8),
                      // POP-PUP Text
                      const Text(
                        'POP-PUP',
                        style: TextStyle(
                          fontSize: 48,
                          color: Color(0xFF5D9C59), // Green color
                          fontFamily: 'Luckiest-Guy',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavigationButton(
                      context,
                      'SETUP',
                      const Text('⚙️', style: TextStyle(fontSize: 30.0),),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SetupScreen()),
                      ),
                    ),
                    _buildNavigationButton(
                      context,
                      'PLAY',
                      const Text('🎮', style: TextStyle(fontSize: 30.0),),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlayScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Statistics Button
                SizedBox(
                  width: double.infinity,
                  child: _buildNavigationButton(
                    context,
                    'STATISTICS',
                    const Text('📊', style: TextStyle(fontSize: 30.0),),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
      BuildContext context, String label, Widget iconWidget, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2B3674),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2B3674), width: 3),
            ),
            elevation: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 22,
                child: iconWidget
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Luckiest-Guy',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}