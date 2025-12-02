import 'package:flutter/material.dart';

class SoilMoistureCard extends StatelessWidget {
  final double moistureLevel;

  const SoilMoistureCard({
    super.key,
    required this.moistureLevel,
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
          Icon(Icons.water_drop, color: Colors.grey[700], size: 32),
          const SizedBox(height: 8),
          Text(
            'Kelembaban\nTanah',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            '${moistureLevel.toStringAsFixed(1)}%',
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
