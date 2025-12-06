import 'package:flutter/material.dart';
import '../models/pump_control.dart';
import '../services/mqtt_service.dart';
import 'light_control_page.dart';

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
  PumpControl _pumpStatus = PumpControl(
    isRunning: false,
    remainingSeconds: 0,
  );

  final TextEditingController _durationController = TextEditingController(text: '30');
  int _selectedDuration = 30; // Default 30 seconds
  
  // Local tracking untuk countdown
  bool _localPumpRunning = false;
  int _localRemainingSeconds = 0;

  // Data Step Response dari tabel (Detik, Volume ml)
  final List<Map<String, dynamic>> _stepResponseData = [
    {'time': 0.25, 'volume': 1.67},
    {'time': 0.49, 'volume': 3.33},
    {'time': 0.74, 'volume': 5.00},
    {'time': 0.98, 'volume': 6.67},
    {'time': 1.23, 'volume': 8.33},
    {'time': 1.48, 'volume': 10.00},
    {'time': 1.72, 'volume': 11.67},
    {'time': 1.97, 'volume': 13.33},
    {'time': 2.21, 'volume': 15.00},
    {'time': 2.46, 'volume': 16.67},
    {'time': 2.71, 'volume': 18.33},
    {'time': 2.95, 'volume': 20.00},
    {'time': 3.20, 'volume': 21.67},
    {'time': 3.44, 'volume': 23.33},
    {'time': 3.69, 'volume': 25.00},
  ];

  @override
  void initState() {
    super.initState();
    widget.mqttService.onPumpStatusReceived = (status) {
      print('📊 Pump Status Update: isRunning=${status.isRunning}, remaining=${status.remainingSeconds}');
      setState(() {
        _pumpStatus = status;
        // Sync local status dengan ESP32
        if (status.isRunning) {
          _localPumpRunning = true;
          _localRemainingSeconds = status.remainingSeconds;
        } else {
          _localPumpRunning = false;
          _localRemainingSeconds = 0;
        }
      });
    };
  }
  
  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }
  
  // Hitung volume air berdasarkan durasi menggunakan interpolasi linear
  double _calculateWaterVolume(double seconds) {
    // Jika waktu 0 atau negatif
    if (seconds <= 0) return 0;
    
    // Jika waktu melebihi steady state (3.69s = 25ml)
    if (seconds >= 3.69) {
      // Setelah steady state, flow rate konstan: 25ml / 3.69s ≈ 6.775 ml/s
      return 25.0 + ((seconds - 3.69) * 6.775);
    }
    
    // Cari dua titik data terdekat untuk interpolasi
    for (int i = 0; i < _stepResponseData.length - 1; i++) {
      double t1 = _stepResponseData[i]['time'];
      double t2 = _stepResponseData[i + 1]['time'];
      
      if (seconds >= t1 && seconds <= t2) {
        double v1 = _stepResponseData[i]['volume'];
        double v2 = _stepResponseData[i + 1]['volume'];
        
        // Interpolasi linear: V = V1 + (V2-V1) * (t-t1) / (t2-t1)
        double volume = v1 + (v2 - v1) * (seconds - t1) / (t2 - t1);
        return volume;
      }
    }
    
    // Jika waktu kurang dari titik data pertama, gunakan interpolasi dari 0
    if (seconds < _stepResponseData[0]['time']) {
      double v1 = _stepResponseData[0]['volume'];
      double t1 = _stepResponseData[0]['time'];
      return (v1 / t1) * seconds;
    }
    
    return 0;
  }
  

  
  void _handleDurationChanged(String value) {
    final duration = int.tryParse(value);
    if (duration != null && duration > 0 && duration <= 300) {
      setState(() {
        _selectedDuration = duration;
      });
    } else if (value.isEmpty) {
      setState(() {
        _selectedDuration = 0;
      });
    }
  }

  void _handleStartPump() {
    // Validasi durasi
    if (_selectedDuration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan durasi yang valid (1-300 detik)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Set local pump status langsung untuk UI responsif
    setState(() {
      _localPumpRunning = true;
      _localRemainingSeconds = _selectedDuration;
    });
    
    // Start local countdown timer
    _startLocalCountdown();
    
    // Send start command to ESP32 with MANUAL mode
    widget.mqttService.publishPumpControl("start",
        duration: _selectedDuration, manual: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Pompa diaktifkan selama $_selectedDuration detik (Mode Manual)'),
        backgroundColor: const Color(0xFF2D5F3F),
      ),
    );
  }
  
  void _startLocalCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      
      if (!_localPumpRunning) return false;
      
      setState(() {
        _localRemainingSeconds--;
        if (_localRemainingSeconds <= 0) {
          _localPumpRunning = false;
          _localRemainingSeconds = 0;
        }
      });
      
      return _localPumpRunning;
    });
  }

  void _handleStopPump() {
    // Stop local countdown
    setState(() {
      _localPumpRunning = false;
      _localRemainingSeconds = 0;
    });
    
    // Send stop command to ESP32
    widget.mqttService.publishPumpControl("stop");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pompa dihentikan'),
        backgroundColor: Colors.orange,
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
                child: Column(
                  children: [
                    // Debug Info (hapus setelah testing)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ESP: isRunning=${_pumpStatus.isRunning}, remaining=${_pumpStatus.remainingSeconds}\n'
                        'Local: running=$_localPumpRunning, remaining=$_localRemainingSeconds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Status Display - gunakan local status atau ESP32 status
                    if (_localPumpRunning || _pumpStatus.isRunning)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: Color(0xFF2D5F3F),
                                  size: 28,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Pompa Sedang Menyiram',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D5F3F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Progress Indicator
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: CircularProgressIndicator(
                                    value: _selectedDuration > 0 
                                        ? (_pumpStatus.isRunning 
                                            ? _pumpStatus.remainingSeconds / _selectedDuration 
                                            : _localRemainingSeconds / _selectedDuration)
                                        : 0,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF2D5F3F),
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${_pumpStatus.isRunning ? _pumpStatus.remainingSeconds : _localRemainingSeconds}',
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D5F3F),
                                      ),
                                    ),
                                    const Text(
                                      'detik',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Waktu info
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_pumpStatus.isRunning 
                                        ? (_selectedDuration - _pumpStatus.remainingSeconds) 
                                        : (_selectedDuration - _localRemainingSeconds)} / $_selectedDuration detik',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            
                            // Real-time Water Output
                            Column(
                              children: [
                                Icon(
                                  Icons.opacity,
                                  color: Colors.blue.shade400,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _calculateWaterVolume(
                                    _pumpStatus.isRunning
                                        ? (_selectedDuration - _pumpStatus.remainingSeconds).toDouble()
                                        : (_selectedDuration - _localRemainingSeconds).toDouble()
                                  ).toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                Text(
                                  'ml air sudah keluar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Control Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Kontrol Pompa',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Duration Input
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Color(0xFF2D5F3F)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Durasi Penyiraman (detik)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _durationController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan durasi (1-300 detik)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2D5F3F),
                                            width: 2,
                                          ),
                                        ),
                                        suffixText: 'detik',
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      onChanged: _handleDurationChanged,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          
                          // Water Output Estimation
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.water,
                                      color: Colors.blue.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Estimasi Volume Air',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  children: [
                                    Text(
                                      _pumpStatus.isRunning
                                          ? _calculateWaterVolume(
                                              (_selectedDuration - _pumpStatus.remainingSeconds).toDouble()
                                            ).toStringAsFixed(1)
                                          : _calculateWaterVolume(_selectedDuration.toDouble()).toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const Text(
                                      'ml',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _pumpStatus.isRunning ? 'Air sudah keluar' : 'Total air yang akan keluar',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Control Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: (_localPumpRunning || _pumpStatus.isRunning || _selectedDuration <= 0)
                                      ? null
                                      : _handleStartPump,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D5F3F),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Mulai',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: (!_localPumpRunning && !_pumpStatus.isRunning)
                                      ? null
                                      : _handleStopPump,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.stop, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Stop',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                    icon: const Icon(Icons.lightbulb_outline, size: 32),
                    color: Colors.white70,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LightControlPage(
                            mqttService: widget.mqttService,
                          ),
                        ),
                      );
                    },
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
