import 'package:flutter/material.dart';

class LightCard extends StatelessWidget {
  final double lightLevel;

  const LightCard({
    super.key,
    required this.lightLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.wb_sunny, color: Colors.grey[700], size: 32),
          const SizedBox(height: 8),
          Text(
            'Cahaya',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            '${lightLevel.toStringAsFixed(0)} Lux',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
