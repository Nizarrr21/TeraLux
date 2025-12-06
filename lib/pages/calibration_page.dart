import 'package:flutter/material.dart';
import '../models/calibration_data.dart';
import '../services/mqtt_service.dart';

class CalibrationPage extends StatefulWidget {
  final MqttService mqttService;

  const CalibrationPage({
    super.key,
    required this.mqttService,
  });

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  // Soil Moisture Calibration Values
  final TextEditingController _soilDryController = TextEditingController(text: '4095');
  final TextEditingController _soilWetController = TextEditingController(text: '1500');

  void _applyCalibration() {
    if (_soilDryController.text.isEmpty || _soilWetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai Dry dan Wet untuk sensor kelembaban!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final soilDry = int.parse(_soilDryController.text);
      final soilWet = int.parse(_soilWetController.text);

      // Validasi
      if (soilDry <= soilWet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nilai Dry harus lebih besar dari Wet!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update calibration di MqttService
      final calibration = CalibrationData(
        lightSlopeA: 1.0, // BH1750 tidak perlu kalibrasi
        lightInterceptB: 0.0,
        moistureSlopeA: 1.0,
        moistureInterceptB: 0.0,
        soilDryValue: soilDry,
        soilWetValue: soilWet,
      );

      widget.mqttService.updateCalibration(calibration);

      // Publish threshold settings dengan nilai kalibrasi baru
      widget.mqttService.updateThresholdSettings(
        widget.mqttService.thresholdSettings,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kalibrasi berhasil disimpan!\n'
            'Dry: $soilDry | Wet: $soilWet\n'
            'Data dikirim ke ESP32',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Masukkan nilai yang valid'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D5F3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5F3F),
        foregroundColor: Colors.white,
        title: const Text('Kalibrasi Sensor'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info BH1750
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Sensor Cahaya BH1750',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '✓ Sensor digital dengan akurasi tinggi',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '✓ Sudah dikalibrasi pabrik',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '✓ Tidak perlu kalibrasi manual',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Kalibrasi Sensor Kelembaban Tanah
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Kalibrasi Sensor Kelembaban',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Masukkan nilai sensor saat kondisi DRY dan WET',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Soil DRY Value
                  const Text(
                    'Nilai Sensor DRY (di udara):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _soilDryController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nilai ADC saat kering (0-4095)',
                      hintText: '4095',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.air, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Soil WET Value
                  const Text(
                    'Nilai Sensor WET (di dalam air):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _soilWetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nilai ADC saat basah (0-4095)',
                      hintText: '1500',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.water, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Panduan Kalibrasi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[900]),
                      const SizedBox(width: 8),
                      const Text(
                        'Panduan Kalibrasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Sensor Cahaya BH1750 sudah dikalibrasi dari pabrik\n'
                    '2. Sensor Kelembaban Tanah perlu kalibrasi 2 nilai:\n'
                    '   • DRY: Angkat sensor di udara, catat nilai ADC\n'
                    '   • WET: Celupkan sensor di air, catat nilai ADC\n'
                    '3. Nilai DRY harus lebih besar dari nilai WET\n'
                    '4. Setelah input, tekan "Terapkan Kalibrasi"',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyCalibration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2D5F3F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Terapkan Kalibrasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _soilDryController.dispose();
    _soilWetController.dispose();
    super.dispose();
  }
}
