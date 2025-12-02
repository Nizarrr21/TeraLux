import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';
import '../widgets/greeting_card.dart';
import '../widgets/temperature_card.dart';
import '../widgets/light_card.dart';
import '../widgets/soil_moisture_card.dart';
import 'pump_control_page.dart';
import 'calibration_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final MqttService _mqttService = MqttService();
  SensorData _sensorData = SensorData(
    temperature: 0.0,
    lightLevel: 0,
    moistureLevel: 0,
  );

  @override
  void initState() {
    super.initState();
    _initMqtt();
  }

  Future<void> _initMqtt() async {
    _mqttService.onSensorDataReceived = (data) {
      setState(() {
        _sensorData = data;
      });
    };

    await _mqttService.connect();
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D5F3F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'TeraLux',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '✨',
                    style: TextStyle(fontSize: 24),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalibrationPage(
                            mqttService: _mqttService,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Greeting Card
                    GreetingCard(
                      username: 'Teman',
                      time: _getCurrentTime(),
                      date: _getCurrentDate(),
                    ),

                    const SizedBox(height: 24),

                    // Temperature Card
                    TemperatureCard(
                      temperature: _sensorData.temperature,
                    ),

                    const SizedBox(height: 16),

                    // Light and Soil Moisture Cards
                    Row(
                      children: [
                        Expanded(
                          child: LightCard(
                            lightLevel: _sensorData.lightLevel,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SoilMoistureCard(
                            moistureLevel: _sensorData.moistureLevel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              color: const Color(0xFF8BC34A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, size: 32),
                    color: Colors.white70,
                    onPressed: () {
                      // Navigate to pump control
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PumpControlPage(
                            mqttService: _mqttService,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.home, size: 32),
                      color: const Color(0xFF2D5F3F),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
