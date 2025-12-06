class SensorData {
  final double lightLevel; // Dalam Lux (dari BH1750, tidak perlu kalibrasi)
  final double moistureLevel; // Dalam % (setelah konversi)
  
  // Nilai mentah dari sensor (untuk soil moisture)
  final double? rawMoistureValue;

  SensorData({
    required this.lightLevel,
    required this.moistureLevel,
    this.rawMoistureValue,
  });

  // Factory constructor untuk parsing dari MQTT JSON
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      lightLevel: (json['lightLevel'] ?? 0.0).toDouble(),
      moistureLevel: (json['moistureLevel'] ?? 0.0).toDouble(),
      rawMoistureValue: json['rawMoistureValue']?.toDouble(),
    );
  }

  // Convert ke JSON untuk mengirim data
  Map<String, dynamic> toJson() {
    return {
      'lightLevel': lightLevel,
      'moistureLevel': moistureLevel,
      if (rawMoistureValue != null) 'rawMoistureValue': rawMoistureValue,
    };
  }
}
