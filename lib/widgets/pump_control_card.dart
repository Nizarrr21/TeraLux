import 'package:flutter/material.dart';

class PumpControlCard extends StatelessWidget {
  final bool isPumpOn;
  final bool isAutoMode;
  final int duration;
  final bool isRunning;
  final Function(bool) onPumpToggle;
  final Function(bool) onModeToggle;
  final Function(int) onDurationChanged;
  final VoidCallback onActivate;

  const PumpControlCard({
    super.key,
    required this.isPumpOn,
    required this.isAutoMode,
    required this.duration,
    required this.isRunning,
    required this.onPumpToggle,
    required this.onModeToggle,
    required this.onDurationChanged,
    required this.onActivate,
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
          const Text(
            'Kontrol Pompa',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Toggle Pompa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktifkan Pompa',
                style: TextStyle(fontSize: 16),
              ),
              Switch(
                value: isPumpOn,
                activeColor: const Color(0xFF2D5F3F),
                onChanged: onPumpToggle,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mode Selection
          const Text(
            'Mode',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onModeToggle(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAutoMode
                        ? const Color(0xFF2D5F3F)
                        : Colors.grey[300],
                    foregroundColor: isAutoMode ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Otomatis'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onModeToggle(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isAutoMode
                        ? const Color(0xFFF5E6D3)
                        : Colors.grey[300],
                    foregroundColor: !isAutoMode ? Colors.black : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Manual'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Duration Input
          const Text(
            'Durasi Penyiraman (detik)',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6D3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF2D5F3F),
                  onPressed: () {
                    if (duration > 1) {
                      onDurationChanged(duration - 1);
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                    controller: TextEditingController(text: duration.toString())
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: duration.toString().length),
                      ),
                    onChanged: (value) {
                      final newValue = int.tryParse(value);
                      if (newValue != null && newValue > 0) {
                        onDurationChanged(newValue);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF2D5F3F),
                  onPressed: () {
                    onDurationChanged(duration + 1);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Activate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPumpOn ? onActivate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? Colors.red : const Color(0xFF2D5F3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                disabledBackgroundColor: Colors.grey[400],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isRunning ? Icons.stop : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(
                    isRunning ? 'Hentikan' : 'Aktifkan',
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
