import 'package:flutter/material.dart';
import '../models/light_control.dart';
import '../services/mqtt_service.dart';
import '../widgets/light_control_card.dart';
import 'pump_control_page.dart';

class LightControlPage extends StatefulWidget {
  final MqttService mqttService;

  const LightControlPage({
    super.key,
    required this.mqttService,
  });

  @override
  State<LightControlPage> createState() => _LightControlPageState();
}

class _LightControlPageState extends State<LightControlPage> {
  LightControl _lightControl = LightControl(
    isLightOn: false,
  );

  @override
  void initState() {
    super.initState();
    widget.mqttService.onLightStatusReceived = (status) {
      setState(() {
        _lightControl = status;
      });
    };
  }

  void _handleLightToggle(bool value) {
    setState(() {
      _lightControl = _lightControl.copyWith(isLightOn: value, manual: true);
    });
    widget.mqttService.publishLightControl(_lightControl);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Lampu dinyalakan (Mode Manual)' : 'Lampu dimatikan',
        ),
        backgroundColor: const Color(0xFF2D5F3F),
        duration: const Duration(seconds: 1),
      ),
    );
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
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: LightControlCard(
                  isLightOn: _lightControl.isLightOn,
                  onLightToggle: _handleLightToggle,
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PumpControlPage(
                            mqttService: widget.mqttService,
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
                      icon: const Icon(Icons.lightbulb, size: 32),
                      color: const Color(0xFF2D5F3F),
                      onPressed: () {},
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, size: 32),
                    color: Colors.white70,
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
