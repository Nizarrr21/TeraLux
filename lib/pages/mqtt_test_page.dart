import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class MqttTestPage extends StatefulWidget {
  const MqttTestPage({super.key});

  @override
  State<MqttTestPage> createState() => _MqttTestPageState();
}

class _MqttTestPageState extends State<MqttTestPage> {
  final MqttService _mqttService = MqttService();
  final List<String> _logs = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _setupMqtt();
  }

  Future<void> _setupMqtt() async {
    _addLog('📡 Setting up MQTT callbacks...');
    _addLog('');
    _addLog('📋 Topics yang digunakan:');
    _addLog('  • teralux_project/sensors');
    _addLog('  • teralux_project/pump/status');
    _addLog('  • teralux_project/light/status');
    _addLog('');
    
    _mqttService.onSensorDataReceived = (data) {
      _addLog('📥 SENSOR: Light=${data.lightLevel.toStringAsFixed(0)} Lux, Soil=${data.moistureLevel.toStringAsFixed(0)}%');
      
      // Cek threshold
      final threshold = _mqttService.thresholdSettings;
      if (threshold.autoWateringEnabled && data.moistureLevel < threshold.soilMoistureMin) {
        _addLog('   ⚠️  Soil < ${threshold.soilMoistureMin}% → AUTO WATERING akan trigger!');
      }
      if (threshold.autoLightingEnabled && data.lightLevel < threshold.lightLevelMin) {
        _addLog('   ⚠️  Light < ${threshold.lightLevelMin} Lux → AUTO LIGHTING akan trigger!');
      }
    };

    _mqttService.onPumpStatusReceived = (status) {
      _addLog('📥 PUMP: ${status.isRunning ? "ON" : "OFF"} (${status.manual ? "MANUAL" : "AUTO"})');
    };

    _mqttService.onLightStatusReceived = (status) {
      _addLog('📥 LIGHT: ${status.isLightOn ? "ON" : "OFF"} (${status.manual ? "MANUAL" : "AUTO"})');
    };

    _addLog('🔄 Connecting to broker.hivemq.com:1883...');
    await _mqttService.connect();
    
    setState(() {
      _isConnected = true;
    });
    _addLog('✓ Connection completed');
    _addLog('');
    _addLog('💡 Tunggu data dari ESP32...');
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = TimeOfDay.now().format(context);
      _logs.insert(0, '[$timestamp] $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Test'),
        backgroundColor: const Color(0xFF2D5F3F),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isConnected ? Colors.green : Colors.red,
            child: Column(
              children: [
                Text(
                  _isConnected ? '✓ Connected to broker.hivemq.com' : '⚠️ Not Connected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isConnected) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Threshold: Soil < ${_mqttService.thresholdSettings.soilMoistureMin.toStringAsFixed(0)}%, Light < ${_mqttService.thresholdSettings.lightLevelMin.toStringAsFixed(0)} Lux',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _addLog('Sending test pump command...');
                      _mqttService.publishPumpControl('start', duration: 10, manual: true);
                    },
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Test Pump'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Logs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }
}
