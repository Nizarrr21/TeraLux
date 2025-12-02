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
  final List<CalibrationPoint> _lightPoints = [];
  final List<CalibrationPoint> _moisturePoints = [];

  final TextEditingController _lightSensorController = TextEditingController();
  final TextEditingController _lightActualController = TextEditingController();
  final TextEditingController _moistureSensorController = TextEditingController();
  final TextEditingController _moistureActualController = TextEditingController();

  void _addLightCalibrationPoint() {
    if (_lightSensorController.text.isNotEmpty &&
        _lightActualController.text.isNotEmpty) {
      setState(() {
        _lightPoints.add(CalibrationPoint(
          sensorValue: double.parse(_lightSensorController.text),
          actualValue: double.parse(_lightActualController.text),
        ));
        _lightSensorController.clear();
        _lightActualController.clear();
      });
    }
  }

  void _addMoistureCalibrationPoint() {
    if (_moistureSensorController.text.isNotEmpty &&
        _moistureActualController.text.isNotEmpty) {
      setState(() {
        _moisturePoints.add(CalibrationPoint(
          sensorValue: double.parse(_moistureSensorController.text),
          actualValue: double.parse(_moistureActualController.text),
        ));
        _moistureSensorController.clear();
        _moistureActualController.clear();
      });
    }
  }

  void _applyCalibration() {
    if (_lightPoints.length < 2 || _moisturePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal 2 titik kalibrasi untuk setiap sensor!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final calibration = CalibrationData.fromMeasurements(
        lightPoints: _lightPoints,
        moisturePoints: _moisturePoints,
      );

      widget.mqttService.updateCalibration(calibration);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kalibrasi berhasil!\n'
            'Cahaya: y = ${calibration.lightSlopeA.toStringAsFixed(3)}x + ${calibration.lightInterceptB.toStringAsFixed(2)}\n'
            'Kelembaban: y = ${calibration.moistureSlopeA.toStringAsFixed(3)}x + ${calibration.moistureInterceptB.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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
            // Kalibrasi Sensor Cahaya
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
                        'Kalibrasi Sensor Cahaya',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gunakan Lux Meter untuk mendapatkan nilai aktual',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _lightSensorController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nilai ADC Sensor',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lightActualController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Lux Meter (Lux)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Colors.green,
                        onPressed: _addLightCalibrationPoint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _lightPoints
                        .asMap()
                        .entries
                        .map((entry) => Chip(
                              label: Text(
                                '${entry.value.sensorValue.toInt()} → ${entry.value.actualValue.toInt()} Lux',
                                style: const TextStyle(fontSize: 12),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _lightPoints.removeAt(entry.key);
                                });
                              },
                            ))
                        .toList(),
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
                  const SizedBox(height: 8),
                  const Text(
                    'Gunakan Soil Moisture Meter untuk nilai aktual',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _moistureSensorController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nilai ADC Sensor',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _moistureActualController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Soil Meter (%)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Colors.green,
                        onPressed: _addMoistureCalibrationPoint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _moisturePoints
                        .asMap()
                        .entries
                        .map((entry) => Chip(
                              label: Text(
                                '${entry.value.sensorValue.toInt()} → ${entry.value.actualValue.toInt()}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _moisturePoints.removeAt(entry.key);
                                });
                              },
                            ))
                        .toList(),
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
                    '1. Minimal 2 titik pengukuran untuk setiap sensor\n'
                    '2. Gunakan kondisi yang berbeda (terang-gelap, basah-kering)\n'
                    '3. Sensor Cahaya: Ukur di tempat gelap dan terang dengan Lux Meter\n'
                    '4. Kelembaban Tanah: Ukur di udara (kering) dan dalam air (basah)\n'
                    '5. Lebih banyak titik = kalibrasi lebih akurat',
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
    _lightSensorController.dispose();
    _lightActualController.dispose();
    _moistureSensorController.dispose();
    _moistureActualController.dispose();
    super.dispose();
  }
}
