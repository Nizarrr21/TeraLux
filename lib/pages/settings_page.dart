import 'package:flutter/material.dart';
import '../models/threshold_settings.dart';
import '../services/mqtt_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final MqttService _mqttService = MqttService();
  late ThresholdSettings _settings;
  
  final TextEditingController _soilMoistureController = TextEditingController();
  final TextEditingController _lightLevelController = TextEditingController();
  final TextEditingController _wateringDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settings = _mqttService.thresholdSettings;
    _soilMoistureController.text = _settings.soilMoistureMin.toStringAsFixed(0);
    _lightLevelController.text = _settings.lightLevelMin.toStringAsFixed(0);
    _wateringDurationController.text = _settings.wateringDuration.toString();
  }

  @override
  void dispose() {
    _soilMoistureController.dispose();
    _lightLevelController.dispose();
    _wateringDurationController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final newSettings = ThresholdSettings(
      soilMoistureMin: double.tryParse(_soilMoistureController.text) ?? 30.0,
      lightLevelMin: double.tryParse(_lightLevelController.text) ?? 1000.0,
      autoWateringEnabled: _settings.autoWateringEnabled,
      autoLightingEnabled: _settings.autoLightingEnabled,
      wateringDuration: int.tryParse(_wateringDurationController.text) ?? 30,
    );

    _mqttService.updateThresholdSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan berhasil disimpan'),
        backgroundColor: Color(0xFF2D5F3F),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Otomatis'),
        backgroundColor: const Color(0xFF2D5F3F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5F3F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.settings_suggest, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Kontrol Otomatis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Atur threshold untuk kontrol otomatis pompa dan lampu',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Auto Watering Section
          _buildSectionTitle('🚿 Penyiraman Otomatis'),
          const SizedBox(height: 12),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Aktifkan Penyiraman Otomatis',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Pompa akan menyala otomatis jika tanah kering'),
                    value: _settings.autoWateringEnabled,
                    activeColor: const Color(0xFF2D5F3F),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(autoWateringEnabled: value);
                      });
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Soil Moisture Threshold
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Color(0xFF2D5F3F)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kelembaban Tanah Minimum',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pompa menyala jika < ${_soilMoistureController.text}%',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _soilMoistureController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixText: '%',
                      hintText: '30',
                      enabled: _settings.autoWateringEnabled,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Watering Duration
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Color(0xFF2D5F3F)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Durasi Penyiraman',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lama pompa menyala saat otomatis',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _wateringDurationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixText: 'detik',
                      hintText: '30',
                      enabled: _settings.autoWateringEnabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Auto Lighting Section
          _buildSectionTitle('💡 Pencahayaan Otomatis'),
          const SizedBox(height: 12),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Aktifkan Pencahayaan Otomatis',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Lampu akan menyala otomatis jika cahaya kurang'),
                    value: _settings.autoLightingEnabled,
                    activeColor: const Color(0xFF2D5F3F),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(autoLightingEnabled: value);
                      });
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Light Level Threshold
                  Row(
                    children: [
                      const Icon(Icons.light_mode, color: Color(0xFFFFA726)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cahaya Minimum',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lampu menyala jika < ${_lightLevelController.text} Lux',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lightLevelController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixText: 'Lux',
                      hintText: '1000',
                      enabled: _settings.autoLightingEnabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kontrol otomatis akan bekerja berdasarkan sensor yang sudah dikalibrasi. Pastikan kalibrasi sensor sudah dilakukan.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5F3F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SIMPAN PENGATURAN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D5F3F),
      ),
    );
  }
}
