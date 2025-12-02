class SensorData {
  final double temperature;
  final double lightLevel; // Dalam Lux (setelah kalibrasi)
  final double moistureLevel; // Dalam % (setelah kalibrasi)
  
  // Nilai mentah dari sensor (sebelum kalibrasi)
  final double? rawLightValue;
  final double? rawMoistureValue;

  SensorData({
    required this.temperature,
    required this.lightLevel,
    required this.moistureLevel,
    this.rawLightValue,
    this.rawMoistureValue,
  });

  // Factory constructor untuk parsing dari MQTT JSON
  // Menerima nilai mentah dari Arduino
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      lightLevel: (json['light'] ?? 0.0).toDouble(),
      moistureLevel: (json['moisture'] ?? 0.0).toDouble(),
      rawLightValue: json['rawLight']?.toDouble(),
      rawMoistureValue: json['rawMoisture']?.toDouble(),
    );
  }

  // Convert ke JSON untuk mengirim data
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'light': lightLevel,
      'moisture': moistureLevel,
      if (rawLightValue != null) 'rawLight': rawLightValue,
      if (rawMoistureValue != null) 'rawMoisture': rawMoistureValue,
    };
  }
}
