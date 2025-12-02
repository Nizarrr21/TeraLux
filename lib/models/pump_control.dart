class PumpControl {
  final bool isPumpOn;
  final bool isAutoMode;
  final int duration;

  PumpControl({
    required this.isPumpOn,
    required this.isAutoMode,
    required this.duration,
  });

  // Factory constructor untuk parsing dari MQTT JSON
  factory PumpControl.fromJson(Map<String, dynamic> json) {
    return PumpControl(
      isPumpOn: json['isPumpOn'] ?? false,
      isAutoMode: json['isAutoMode'] ?? true,
      duration: json['duration'] ?? 5,
    );
  }

  // Convert ke JSON untuk mengirim ke Arduino via MQTT
  Map<String, dynamic> toJson() {
    return {
      'isPumpOn': isPumpOn,
      'isAutoMode': isAutoMode,
      'duration': duration,
    };
  }

  // Copy with method untuk update state
  PumpControl copyWith({
    bool? isPumpOn,
    bool? isAutoMode,
    int? duration,
  }) {
    return PumpControl(
      isPumpOn: isPumpOn ?? this.isPumpOn,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      duration: duration ?? this.duration,
    );
  }
}
