class ThresholdSettings {
  final double soilMoistureMin; // Minimum soil moisture (%), pompa nyala jika dibawah ini
  final double lightLevelMin; // Minimum light level (Lux), lampu nyala jika dibawah ini
  final bool autoWateringEnabled; // Enable/disable auto watering
  final bool autoLightingEnabled; // Enable/disable auto lighting
  final int wateringDuration; // Durasi pompa otomatis (detik)

  ThresholdSettings({
    this.soilMoistureMin = 30.0, // Default 30%
    this.lightLevelMin = 1000.0, // Default 1000 Lux
    this.autoWateringEnabled = true,
    this.autoLightingEnabled = true,
    this.wateringDuration = 30, // Default 30 detik
  });

  ThresholdSettings copyWith({
    double? soilMoistureMin,
    double? lightLevelMin,
    bool? autoWateringEnabled,
    bool? autoLightingEnabled,
    int? wateringDuration,
  }) {
    return ThresholdSettings(
      soilMoistureMin: soilMoistureMin ?? this.soilMoistureMin,
      lightLevelMin: lightLevelMin ?? this.lightLevelMin,
      autoWateringEnabled: autoWateringEnabled ?? this.autoWateringEnabled,
      autoLightingEnabled: autoLightingEnabled ?? this.autoLightingEnabled,
      wateringDuration: wateringDuration ?? this.wateringDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soilMoistureMin': soilMoistureMin,
      'lightLevelMin': lightLevelMin,
      'autoWateringEnabled': autoWateringEnabled,
      'autoLightingEnabled': autoLightingEnabled,
      'wateringDuration': wateringDuration,
    };
  }

  factory ThresholdSettings.fromJson(Map<String, dynamic> json) {
    return ThresholdSettings(
      soilMoistureMin: json['soilMoistureMin']?.toDouble() ?? 30.0,
      lightLevelMin: json['lightLevelMin']?.toDouble() ?? 1000.0,
      autoWateringEnabled: json['autoWateringEnabled'] ?? true,
      autoLightingEnabled: json['autoLightingEnabled'] ?? true,
      wateringDuration: json['wateringDuration'] ?? 30,
    );
  }
}
