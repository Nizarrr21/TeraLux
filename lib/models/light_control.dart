class LightControl {
  final bool isLightOn;
  final bool manual;

  LightControl({
    required this.isLightOn,
    this.manual = false,
  });

  // Factory constructor untuk parsing dari MQTT JSON
  factory LightControl.fromJson(Map<String, dynamic> json) {
    return LightControl(
      isLightOn: json['isLightOn'] ?? false,
      manual: json['manual'] ?? false,
    );
  }

  // Convert ke JSON untuk mengirim ke Arduino via MQTT
  Map<String, dynamic> toJson() {
    return {
      'isLightOn': isLightOn,
      'manual': manual,
    };
  }

  // Copy with method untuk update state
  LightControl copyWith({
    bool? isLightOn,
    bool? manual,
  }) {
    return LightControl(
      isLightOn: isLightOn ?? this.isLightOn,
      manual: manual ?? this.manual,
    );
  }
}
