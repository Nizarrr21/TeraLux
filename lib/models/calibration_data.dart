class CalibrationData {
  // Kalibrasi Sensor Cahaya (LDR/Photodiode to Lux)
  // Menggunakan regresi linear: Lux = a * sensorValue + b
  final double lightSlopeA;
  final double lightInterceptB;

  // Kalibrasi Sensor Kelembaban Tanah
  // Menggunakan regresi linear: Moisture% = a * sensorValue + b
  final double moistureSlopeA;
  final double moistureInterceptB;

  // Data mentah untuk referensi (opsional)
  final List<CalibrationPoint>? lightCalibrationPoints;
  final List<CalibrationPoint>? moistureCalibrationPoints;

  CalibrationData({
    required this.lightSlopeA,
    required this.lightInterceptB,
    required this.moistureSlopeA,
    required this.moistureInterceptB,
    this.lightCalibrationPoints,
    this.moistureCalibrationPoints,
  });

  // Default calibration (harus diganti dengan hasil kalibrasi aktual)
  factory CalibrationData.defaultCalibration() {
    return CalibrationData(
      // Contoh kalibrasi LDR ke Lux
      // Berdasarkan pengukuran dengan Lux Meter:
      // ADC 0 -> 10000 Lux (terang)
      // ADC 1023 -> 0 Lux (gelap)
      lightSlopeA: -9.775,
      lightInterceptB: 10000,

      // Contoh kalibrasi Soil Moisture Sensor
      // Berdasarkan pengukuran dengan Soil Moisture Meter:
      // ADC 300 -> 0% (udara/kering)
      // ADC 800 -> 100% (dalam air/basah)
      moistureSlopeA: 0.2,
      moistureInterceptB: -60,
    );
  }

  // Kalibrasi dari data pengukuran
  factory CalibrationData.fromMeasurements({
    required List<CalibrationPoint> lightPoints,
    required List<CalibrationPoint> moisturePoints,
  }) {
    final lightRegression = _linearRegression(lightPoints);
    final moistureRegression = _linearRegression(moisturePoints);

    return CalibrationData(
      lightSlopeA: lightRegression['slope']!,
      lightInterceptB: lightRegression['intercept']!,
      moistureSlopeA: moistureRegression['slope']!,
      moistureInterceptB: moistureRegression['intercept']!,
      lightCalibrationPoints: lightPoints,
      moistureCalibrationPoints: moisturePoints,
    );
  }

  // Hitung regresi linear menggunakan metode least squares
  static Map<String, double> _linearRegression(List<CalibrationPoint> points) {
    if (points.length < 2) {
      throw Exception('Need at least 2 calibration points');
    }

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = points.length;

    for (var point in points) {
      sumX += point.sensorValue;
      sumY += point.actualValue;
      sumXY += point.sensorValue * point.actualValue;
      sumX2 += point.sensorValue * point.sensorValue;
    }

    // y = ax + b
    // a = (n*sumXY - sumX*sumY) / (n*sumX2 - sumX*sumX)
    // b = (sumY - a*sumX) / n
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    return {
      'slope': slope,
      'intercept': intercept,
    };
  }

  // Kalibrasikan nilai sensor cahaya ke Lux
  double calibrateLightToLux(double sensorValue) {
    double lux = lightSlopeA * sensorValue + lightInterceptB;
    return lux < 0 ? 0 : lux; // Lux tidak bisa negatif
  }

  // Kalibrasikan nilai sensor kelembaban ke persentase
  double calibrateMoistureToPercent(double sensorValue) {
    double moisture = moistureSlopeA * sensorValue + moistureInterceptB;
    // Batasi antara 0-100%
    if (moisture < 0) return 0;
    if (moisture > 100) return 100;
    return moisture;
  }

  // Convert to JSON untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'lightSlopeA': lightSlopeA,
      'lightInterceptB': lightInterceptB,
      'moistureSlopeA': moistureSlopeA,
      'moistureInterceptB': moistureInterceptB,
    };
  }

  // Load from JSON
  factory CalibrationData.fromJson(Map<String, dynamic> json) {
    return CalibrationData(
      lightSlopeA: json['lightSlopeA']?.toDouble() ?? -9.775,
      lightInterceptB: json['lightInterceptB']?.toDouble() ?? 10000,
      moistureSlopeA: json['moistureSlopeA']?.toDouble() ?? 0.2,
      moistureInterceptB: json['moistureInterceptB']?.toDouble() ?? -60,
    );
  }
}

// Data point untuk kalibrasi
class CalibrationPoint {
  final double sensorValue; // Nilai ADC dari sensor
  final double actualValue; // Nilai aktual dari alat ukur (Lux Meter/Soil Meter)

  CalibrationPoint({
    required this.sensorValue,
    required this.actualValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'sensorValue': sensorValue,
      'actualValue': actualValue,
    };
  }

  factory CalibrationPoint.fromJson(Map<String, dynamic> json) {
    return CalibrationPoint(
      sensorValue: json['sensorValue']?.toDouble() ?? 0,
      actualValue: json['actualValue']?.toDouble() ?? 0,
    );
  }
}
