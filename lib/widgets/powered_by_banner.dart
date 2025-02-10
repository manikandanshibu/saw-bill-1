import 'package:flutter/material.dart';

class PoweredByBanner extends StatelessWidget {
  const PoweredByBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Powered by ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'Alpha Intelligence',
            style: TextStyle(
              color: Colors.blue.shade300,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Text(
            ' & ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            'Adsbee',
            style: TextStyle(
              color: Colors.purple.shade300,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
