class PumpControl {
  final bool isRunning;
  final int remainingSeconds;
  final bool manual;

  PumpControl({
    required this.isRunning,
    this.remainingSeconds = 0,
    this.manual = false,
  });

  // Factory constructor untuk parsing dari ESP32 status
  factory PumpControl.fromJson(Map<String, dynamic> json) {
    return PumpControl(
      isRunning: json['isRunning'] ?? false,
      remainingSeconds: json['remainingSeconds'] ?? 0,
      manual: json['manual'] ?? false,
    );
  }

  // Convert ke JSON untuk mengirim control command ke ESP32
  // mode: "start" or "stop"
  // duration: seconds (only for start)
  // manual: true untuk manual mode, false untuk auto
  Map<String, dynamic> toControlJson({
    required String mode,
    int duration = 30,
    bool manual = false,
  }) {
    if (mode == "start") {
      return {
        'mode': 'start',
        'duration': duration,
        'manual': manual,
      };
    } else {
      return {
        'mode': 'stop',
      };
    }
  }

  // Convert status ke JSON (untuk internal use)
  Map<String, dynamic> toJson() {
    return {
      'isRunning': isRunning,
      'remainingSeconds': remainingSeconds,
      'manual': manual,
    };
  }

  // Copy with method untuk update state
  PumpControl copyWith({
    bool? isRunning,
    int? remainingSeconds,
    bool? manual,
  }) {
    return PumpControl(
      isRunning: isRunning ?? this.isRunning,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      manual: manual ?? this.manual,
    );
  }
}
