// MQTT Service untuk TeraLux
// Real implementation dengan MQTT broker
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';
import '../models/pump_control.dart';
import '../models/light_control.dart';
import '../models/calibration_data.dart';
import '../models/threshold_settings.dart';
import 'dart:convert';

class MqttService {
  // Singleton pattern
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? client;

  // MQTT Configuration - GANTI SESUAI BROKER ANDA
  static const String broker =
      'broker.hivemq.com'; // Public broker (SAMA DENGAN ESP32!)
  // static const String broker = 'test.mosquitto.org'; // Alternative
  // static const String broker = '192.168.1.100'; // Uncomment untuk broker lokal
  static const int port = 1883;
  static const String username = ''; // Kosongkan jika tidak pakai auth
  static const String password = '';

  // MQTT Topics (HARUS SAMA PERSIS dengan ESP32!)
  static const String topicSensors = 'teralux_project/sensors';
  static const String topicPumpControl = 'teralux_project/pump/control';
  static const String topicPumpStatus = 'teralux_project/pump/status';
  static const String topicLightControl = 'teralux_project/light/control';
  static const String topicLightStatus = 'teralux_project/light/status';
  static const String topicThresholdSettings = 'teralux_project/settings/threshold';
  static const String topicCalibration = 'teralux_project/settings/calibration';
  
  // Callbacks
  Function(SensorData)? onSensorDataReceived;
  Function(PumpControl)? onPumpStatusReceived;
  Function(LightControl)? onLightStatusReceived;

  // Kalibrasi sensor (untuk soil moisture)
  CalibrationData calibration = CalibrationData.defaultCalibration();

  // Threshold settings untuk kontrol otomatis
  ThresholdSettings thresholdSettings = ThresholdSettings();

  // Status kontrol otomatis
  bool _autoWateringActive = false;
  bool _autoLightingActive = false;
  DateTime? _lastAutoWatering;

  Future<void> connect() async {
    final String clientId =
        'TeraLux-Flutter-${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient.withPort(broker, clientId, port);
    client!.keepAlivePeriod = 20;
    client!.logging(on: false); // Disable verbose logging
    client!.autoReconnect = true;
    client!.setProtocolV311(); // Use MQTT 3.1.1 protocol
    client!.onConnected = () {
      print('✓ MQTT: onConnected callback triggered');
    };
    client!.onDisconnected = () {
      print('⚠️  MQTT: onDisconnected callback triggered');
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('willtopic') // Required by broker
        .withWillMessage('Device Offline')
        .startClean() // Start with clean session
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMessage;

    try {
      print('========================================');
      print('MQTT Service: Connecting to $broker:$port...');
      print('Client ID: $clientId');
      print('========================================');
      await client!.connect(
        username.isEmpty ? null : username,
        password.isEmpty ? null : password,
      );

      if (client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('✓ MQTT Service: Connected successfully!');
        print('Connection status: ${client!.connectionStatus}');
        
        // Setup listener SEBELUM subscribe
        _setupListeners();
        
        // Delay singkat untuk stabilkan koneksi
        await Future.delayed(Duration(milliseconds: 500));
        
        // Subscribe ke topics
        _subscribeToTopics();
      } else {
        print('✗ MQTT Service: Connection failed - ${client!.connectionStatus}');
      }
    } catch (e) {
      print('✗ MQTT Service: Connection error - $e');
      client!.disconnect();
    }
  }

  void _subscribeToTopics() {
    print('========================================');
    print('MQTT Service: Subscribing to topics...');
    
    // Subscribe dengan callback untuk verifikasi
    final sub1 = client!.subscribe(topicSensors, MqttQos.atMostOnce);
    print('  ➜ $topicSensors (Subscription ID: $sub1)');
    
    final sub2 = client!.subscribe(topicPumpStatus, MqttQos.atMostOnce);
    print('  ➜ $topicPumpStatus (Subscription ID: $sub2)');
    
    final sub3 = client!.subscribe(topicLightStatus, MqttQos.atMostOnce);
    print('  ➜ $topicLightStatus (Subscription ID: $sub3)');
    
    print('✓ MQTT Service: Subscribed to all topics');
    print('  Waiting for messages from ESP32...');
    print('========================================');
  }

  void _setupListeners() {
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage recMess =
          messages[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final String topic = messages[0].topic;

      print('📥 MQTT Received: $topic');
      print('   Payload: $payload');

      try {
        final Map<String, dynamic> json = jsonDecode(payload);

        if (topic == topicSensors) {
          // Data sensor dari ESP32
          print('   ➜ Sensor data parsed');
          final sensorData = SensorData.fromJson(json);
          onSensorDataReceived?.call(sensorData);

          // Check untuk kontrol otomatis
          _checkAutoControl(sensorData);
        } else if (topic == topicPumpStatus) {
          // Status pompa dari ESP32
          print('   ➜ Pump status parsed: $json');
          final pumpStatus = PumpControl.fromJson(json);
          print('   ➜ isRunning=${pumpStatus.isRunning}, remaining=${pumpStatus.remainingSeconds}');
          onPumpStatusReceived?.call(pumpStatus);
        } else if (topic == topicLightStatus) {
          // Status lampu dari ESP32
          print('   ➜ Light status parsed');
          final lightStatus = LightControl.fromJson(json);
          onLightStatusReceived?.call(lightStatus);
        }
      } catch (e) {
        print('✗ MQTT Service: Error parsing message from $topic - $e');
        print('   Raw payload: $payload');
      }
    });

    // Handle subscription confirmation
    client!.onSubscribed = (String topic) {
      print('✓ MQTT Service: Successfully subscribed to $topic');
    };
    
    // Handle subscription failure
    client!.onSubscribeFail = (String topic) {
      print('✗ MQTT Service: Failed to subscribe to $topic');
    };
  }

  // Cek dan jalankan kontrol otomatis berdasarkan threshold
  void _checkAutoControl(SensorData sensorData) {
    final now = DateTime.now();

    // Auto Watering - cek kelembaban tanah
    if (thresholdSettings.autoWateringEnabled) {
      // Cek apakah kelembaban dibawah threshold
      if (sensorData.moistureLevel < thresholdSettings.soilMoistureMin) {
        // Cek apakah sudah pernah watering dalam 5 menit terakhir (cooldown)
        final canWater =
            _lastAutoWatering == null ||
            now.difference(_lastAutoWatering!).inMinutes >= 5;

        if (canWater && !_autoWateringActive) {
          print(
            'MQTT Service: Auto watering triggered! Moisture: ${sensorData.moistureLevel.toStringAsFixed(1)}% < ${thresholdSettings.soilMoistureMin}%',
          );
          _autoWateringActive = true;
          _lastAutoWatering = now;

          // Aktifkan pompa dengan mode "start" (auto mode)
          publishPumpControl("start",
              duration: thresholdSettings.wateringDuration, manual: false);

          // Reset status setelah selesai
          Future.delayed(
            Duration(seconds: thresholdSettings.wateringDuration),
            () {
              _autoWateringActive = false;
            },
          );
        }
      }
    }

    // Auto Lighting - cek level cahaya
    if (thresholdSettings.autoLightingEnabled) {
      // Cek apakah cahaya dibawah threshold
      if (sensorData.lightLevel < thresholdSettings.lightLevelMin) {
        if (!_autoLightingActive) {
          print(
            'MQTT Service: Auto lighting ON! Light: ${sensorData.lightLevel.toStringAsFixed(0)} Lux < ${thresholdSettings.lightLevelMin} Lux',
          );
          _autoLightingActive = true;

          // Nyalakan lampu (auto mode)
          final lightControl = LightControl(isLightOn: true, manual: false);
          publishLightControl(lightControl);
        }
      } else {
        // Matikan lampu jika cahaya sudah cukup
        if (_autoLightingActive) {
          print(
            'MQTT Service: Auto lighting OFF! Light: ${sensorData.lightLevel.toStringAsFixed(0)} Lux >= ${thresholdSettings.lightLevelMin} Lux',
          );
          _autoLightingActive = false;

          final lightControl = LightControl(isLightOn: false, manual: false);
          publishLightControl(lightControl);
        }
      }
    } else {
      // Jika auto lighting disabled, reset status
      if (_autoLightingActive) {
        _autoLightingActive = false;
      }
    }
  }

  // Update kalibrasi dari pengukuran
  void updateCalibration(CalibrationData newCalibration) {
    calibration = newCalibration;
    print('MQTT Service: Calibration updated');
    
    // Publish kalibrasi ke ESP32 via MQTT
    publishCalibration();
  }
  
  // Publish calibration data ke ESP32
  void publishCalibration() {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('✗ MQTT Service: Cannot publish calibration - not connected');
      return;
    }
    
    print('========================================');
    print('📤 MQTT Service: Publishing Calibration');
    print('========================================');
    
    final calibrationData = {
      'soilDryValue': calibration.soilDryValue,
      'soilWetValue': calibration.soilWetValue,
    };
    
    print('Calibration Data:');
    print('  - Soil Dry Value (0%): ${calibration.soilDryValue}');
    print('  - Soil Wet Value (100%): ${calibration.soilWetValue}');
    print('  - Range: ${calibration.soilWetValue} - ${calibration.soilDryValue}');
    print('  - Span: ${calibration.soilDryValue - calibration.soilWetValue}');
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(calibrationData));
    
    print('Publishing to topic: $topicCalibration');
    client!.publishMessage(
      topicCalibration,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print('   ✓ Published successfully');
    print('========================================\n');
  }

  // Proses data mentah dari Arduino
  SensorData processSensorData(Map<String, dynamic> rawData) {
    double lightLevel = (rawData['lightLevel'] ?? 0)
        .toDouble(); // BH1750 direct Lux
    double moistureLevel = (rawData['moistureLevel'] ?? 0)
        .toDouble(); // Already converted to %
    double rawMoisture = (rawData['rawMoistureValue'] ?? 0).toDouble();

    return SensorData(
      lightLevel: lightLevel, // BH1750 no calibration needed
      moistureLevel: moistureLevel,
      rawMoistureValue: rawMoisture,
    );
  }

  void publishPumpControl(String mode, {int duration = 30, bool manual = false}) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('✗ MQTT Service: Cannot publish pump control - not connected');
      return;
    }

    final controlData = mode == "start"
        ? {'mode': 'start', 'duration': duration, 'manual': manual}
        : {'mode': 'stop'};

    print('📤 MQTT Publishing to: $topicPumpControl');
    print('   Payload: ${jsonEncode(controlData)}');
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(controlData));
    client!.publishMessage(
      topicPumpControl,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print('   ✓ Published successfully');
  }

  void publishLightControl(LightControl control) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('✗ MQTT Service: Cannot publish light control - not connected');
      return;
    }

    print('📤 MQTT Publishing to: $topicLightControl');
    print('   Payload: ${jsonEncode(control.toJson())}');
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(control.toJson()));
    client!.publishMessage(
      topicLightControl,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print('   ✓ Published successfully');
  }

  // Update threshold settings
  void updateThresholdSettings(ThresholdSettings newSettings) {
    thresholdSettings = newSettings;
    print('MQTT Service: Threshold settings updated');
    print('  - Soil moisture min: ${newSettings.soilMoistureMin}%');
    print('  - Light level min: ${newSettings.lightLevelMin} Lux');
    print('  - Auto watering: ${newSettings.autoWateringEnabled}');
    print('  - Auto lighting: ${newSettings.autoLightingEnabled}');
    print('  - Watering duration: ${newSettings.wateringDuration}s');

    // Publish settings ke ESP32 via MQTT
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('MQTT Service: Cannot publish threshold settings - not connected');
      return;
    }

    final settingsData = newSettings.toJson();
    // Sertakan kalibrasi soil moisture (ESP32 butuh dry/wet values)
    settingsData['soilDryValue'] = calibration.soilDryValue;
    settingsData['soilWetValue'] = calibration.soilWetValue;

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(settingsData));
    client!.publishMessage(
      topicThresholdSettings,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print('MQTT Service: Threshold settings published to ESP32');
  }

  void disconnect() {
    print('MQTT Service: Disconnected');
  }
}
