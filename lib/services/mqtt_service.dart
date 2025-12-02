// Template untuk MQTT Service
// Uncomment dan install package mqtt_client untuk implementasi penuh
// flutter pub add mqtt_client

/*
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';
import '../models/pump_control.dart';
import 'dart:convert';

class MqttService {
  MqttServerClient? client;
  
  // MQTT Configuration
  final String broker = 'broker.hivemq.com'; // Ganti dengan broker Anda
  final int port = 1883;
  final String clientId = 'teralux_app_${DateTime.now().millisecondsSinceEpoch}';
  
  // Topics
  final String sensorTopic = 'teralux/sensors';
  final String pumpControlTopic = 'teralux/pump/control';
  final String pumpStatusTopic = 'teralux/pump/status';
  
  // Callbacks
  Function(SensorData)? onSensorDataReceived;
  Function(PumpControl)? onPumpStatusReceived;
  
  Future<void> connect() async {
    client = MqttServerClient(broker, clientId);
    client!.port = port;
    client!.keepAlivePeriod = 60;
    client!.logging(on: false);
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    
    client!.connectionMessage = connMessage;
    
    try {
      await client!.connect();
      
      if (client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('MQTT Connected');
        _subscribeToTopics();
      }
    } catch (e) {
      print('MQTT Connection Error: $e');
      client!.disconnect();
    }
    
    client!.updates!.listen(_onMessage);
  }
  
  void _subscribeToTopics() {
    client!.subscribe(sensorTopic, MqttQos.atLeastOnce);
    client!.subscribe(pumpStatusTopic, MqttQos.atLeastOnce);
  }
  
  void _onMessage(List<MqttReceivedMessage> messages) {
    final recMessage = messages[0].payload as MqttPublishMessage;
    final payload = MqttPublishPayload.bytesToStringAsString(
        recMessage.payload.message);
    
    try {
      final json = jsonDecode(payload);
      
      if (messages[0].topic == sensorTopic) {
        final sensorData = SensorData.fromJson(json);
        onSensorDataReceived?.call(sensorData);
      } else if (messages[0].topic == pumpStatusTopic) {
        final pumpStatus = PumpControl.fromJson(json);
        onPumpStatusReceived?.call(pumpStatus);
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }
  
  void publishPumpControl(PumpControl control) {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(control.toJson()));
      client!.publishMessage(
        pumpControlTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    }
  }
  
  void disconnect() {
    client?.disconnect();
  }
}
*/

// Dummy implementation untuk development tanpa MQTT
import '../models/sensor_data.dart';
import '../models/pump_control.dart';
import '../models/calibration_data.dart';
import 'dart:math';

class MqttService {
  Function(SensorData)? onSensorDataReceived;
  Function(PumpControl)? onPumpStatusReceived;
  
  // Kalibrasi sensor
  CalibrationData calibration = CalibrationData.defaultCalibration();

  Future<void> connect() async {
    print('MQTT Service: Connected (Dummy Mode)');
    // Simulasi data sensor
    _simulateSensorData();
  }

  void _simulateSensorData() {
    // Simulasi update data sensor setiap 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (onSensorDataReceived != null) {
        // Simulasi nilai mentah dari sensor ADC
        final random = Random();
        double rawLight = 100 + (random.nextDouble() * 800); // ADC 100-900
        double rawMoisture = 300 + (random.nextDouble() * 500); // ADC 300-800
        
        // Kalibrasikan nilai mentah
        double calibratedLight = calibration.calibrateLightToLux(rawLight);
        double calibratedMoisture = calibration.calibrateMoistureToPercent(rawMoisture);
        
        // Data dummy untuk testing dengan kalibrasi
        onSensorDataReceived!(SensorData(
          temperature: 25.5 + (random.nextDouble() * 5), // 25.5-30.5°C
          lightLevel: calibratedLight,
          moistureLevel: calibratedMoisture,
          rawLightValue: rawLight,
          rawMoistureValue: rawMoisture,
        ));
      }
      _simulateSensorData();
    });
  }

  // Update kalibrasi dari pengukuran
  void updateCalibration(CalibrationData newCalibration) {
    calibration = newCalibration;
    print('MQTT Service: Calibration updated');
  }

  // Proses data mentah dari Arduino dengan kalibrasi
  SensorData processSensorData(Map<String, dynamic> rawData) {
    double rawLight = (rawData['rawLight'] ?? 0).toDouble();
    double rawMoisture = (rawData['rawMoisture'] ?? 0).toDouble();
    
    return SensorData(
      temperature: (rawData['temperature'] ?? 0.0).toDouble(),
      lightLevel: calibration.calibrateLightToLux(rawLight),
      moistureLevel: calibration.calibrateMoistureToPercent(rawMoisture),
      rawLightValue: rawLight,
      rawMoistureValue: rawMoisture,
    );
  }

  void publishPumpControl(PumpControl control) {
    print('MQTT Service: Publishing pump control - ${control.toJson()}');
    // Simulasi response dari Arduino
    Future.delayed(const Duration(milliseconds: 500), () {
      onPumpStatusReceived?.call(control);
    });
  }

  void disconnect() {
    print('MQTT Service: Disconnected');
  }
}
