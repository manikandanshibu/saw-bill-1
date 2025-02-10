import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Main content centered vertically and horizontally
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40), // Added top spacing
                  Image.asset(
                    'assets/ic_launcher.png',
                    width: 430, // Increased from 120 to 180
                    height: 430, // Increased from 120 to 180
                  ),
                  const SizedBox(height: 24), // Increased from 16 to 24
                  Text(
                    'Plathottathil',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Timbers & Saw Mill',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.green.shade600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Powered by text at bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Column(
              children: [
                const Text(
                  'from',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ALPHA INTELLIGENCE',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  '&',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'ADSBEE',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
