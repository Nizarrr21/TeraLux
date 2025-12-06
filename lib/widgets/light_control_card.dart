import 'package:flutter/material.dart';

class LightControlCard extends StatelessWidget {
  final bool isLightOn;
  final Function(bool) onLightToggle;

  const LightControlCard({
    super.key,
    required this.isLightOn,
    required this.onLightToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Color(0xFF2D5F3F),
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Kontrol Lampu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status Display
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLightOn
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    border: Border.all(
                      color: isLightOn ? Colors.amber : Colors.grey,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    size: 60,
                    color: isLightOn ? Colors.amber : Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isLightOn ? 'MENYALA' : 'MATI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isLightOn
                        ? const Color(0xFF2D5F3F)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Toggle Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onLightToggle(!isLightOn),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLightOn ? Colors.red : const Color(0xFF2D5F3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isLightOn ? Icons.lightbulb_outline : Icons.lightbulb),
                  const SizedBox(width: 8),
                  Text(
                    isLightOn ? 'Matikan Lampu' : 'Nyalakan Lampu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
