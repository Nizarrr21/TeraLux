import 'package:flutter/material.dart';
import '../models/pump_control.dart';
import '../services/mqtt_service.dart';
import '../widgets/pump_control_card.dart';

class PumpControlPage extends StatefulWidget {
  final MqttService mqttService;

  const PumpControlPage({
    super.key,
    required this.mqttService,
  });

  @override
  State<PumpControlPage> createState() => _PumpControlPageState();
}

class _PumpControlPageState extends State<PumpControlPage> {
  PumpControl _pumpControl = PumpControl(
    isPumpOn: false,
    isAutoMode: true,
    duration: 5,
  );

  @override
  void initState() {
    super.initState();
    widget.mqttService.onPumpStatusReceived = (status) {
      setState(() {
        _pumpControl = status;
      });
    };
  }

  void _updatePumpControl(PumpControl newControl) {
    setState(() {
      _pumpControl = newControl;
    });
    widget.mqttService.publishPumpControl(newControl);
  }

  void _handlePumpToggle(bool value) {
    _updatePumpControl(_pumpControl.copyWith(isPumpOn: value));
  }

  void _handleModeToggle(bool isAuto) {
    _updatePumpControl(_pumpControl.copyWith(isAutoMode: isAuto));
  }

  void _handleDurationChanged(int duration) {
    _updatePumpControl(_pumpControl.copyWith(duration: duration));
  }

  void _handleActivate() {
    // Kirim perintah aktivasi pompa
    widget.mqttService.publishPumpControl(_pumpControl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _pumpControl.isAutoMode
              ? 'Pompa diaktifkan dalam mode Otomatis'
              : 'Pompa diaktifkan selama ${_pumpControl.duration} detik',
        ),
        backgroundColor: const Color(0xFF2D5F3F),
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
                child: PumpControlCard(
                  isPumpOn: _pumpControl.isPumpOn,
                  isAutoMode: _pumpControl.isAutoMode,
                  duration: _pumpControl.duration,
                  onPumpToggle: _handlePumpToggle,
                  onModeToggle: _handleModeToggle,
                  onDurationChanged: _handleDurationChanged,
                  onActivate: _handleActivate,
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
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.power_settings_new, size: 32),
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
