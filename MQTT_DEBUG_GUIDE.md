# Panduan Debugging MQTT TeraLux

## Status Saat Ini
- ✅ ESP32 bisa publish data sensor ke MQTT
- ❌ Flutter belum menerima data dari ESP32

## Konfigurasi Yang Sudah Disesuaikan

### ESP32 (teralux_esp32.ino)
```cpp
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

// Topics
const char* topic_sensors = "teralux/sensors";
const char* topic_pump_control = "teralux/pump/control";
const char* topic_pump_status = "teralux/pump/status";
const char* topic_light_control = "teralux/light/control";
const char* topic_light_status = "teralux/light/status";
const char* topic_threshold_settings = "teralux/settings/threshold";
```

### Flutter (mqtt_service.dart)
```dart
static const String broker = 'broker.hivemq.com';
static const int port = 1883;

static const String topicSensors = 'teralux/sensors';
static const String topicPumpControl = 'teralux/pump/control';
static const String topicPumpStatus = 'teralux/pump/status';
static const String topicLightControl = 'teralux/light/control';
static const String topicLightStatus = 'teralux/light/status';
static const String topicThresholdSettings = 'teralux/settings/threshold';
```

## Langkah Debugging

### 1. Cek ESP32 Serial Monitor
```
=================================
  TeraLux ESP32 Controller
  WITH LCD v2.1
=================================

[1] Pins initialized
[2] ADC configured (12-bit, 0-3.3V)
[2a] Testing soil sensor on pin 34... 2456 ✓ OK
[3] I2C initialized
[4] Initializing LCD at 0x27... ✓ OK
[5] Initializing BH1750 at 0x23... ✓ OK
    Test reading: 245.83 Lux
[6] Connecting to WiFi: vivo 1807
[6] WiFi connected!
    IP: 192.168.x.x
    RSSI: -45 dBm
[7] MQTT client configured

=================================
Setup complete! Starting loop...
=================================

MQTT connecting... ✓ Connected!
💡 245 Lux | 💧 2456 (65%)
📤 Published to MQTT
```

**Yang harus dicek:**
- ✅ WiFi connected dengan IP address
- ✅ MQTT connected (bukan failed)
- ✅ Published to MQTT (bukan "Publish failed")

### 2. Jalankan Flutter App

Buka Debug Console di VS Code dan cari output seperti ini:

```
========================================
MQTT Service: Connecting to broker.hivemq.com:1883...
Client ID: TeraLux-Flutter-1733123456789
========================================
✓ MQTT Service: Connected successfully!
Connection status: ...
========================================
MQTT Service: Subscribing to topics...
  ➜ teralux/sensors
  ➜ teralux/pump/status
  ➜ teralux/light/status
✓ MQTT Service: Subscribed to all topics
========================================
```

**Jika berhasil subscribe, Anda akan melihat:**
```
📥 MQTT Received: teralux/sensors
   Payload: {"lightLevel":245,"rawMoistureValue":2456,"moistureLevel":65,"timestamp":123456}
   ➜ Sensor data parsed
```

### 3. Test Publish dari Flutter

Ketika Anda klik tombol di Flutter (misalnya Pump atau Light):

```
📤 MQTT Publishing to: teralux/pump/control
   Payload: {"mode":"start","duration":30,"manual":true}
   ✓ Published successfully
```

**ESP32 akan menerima:**
```
[MQTT] teralux/pump/control: {"mode":"start","duration":30,"manual":true}
💧 Pump ON (30s) - Mode: MANUAL
```

## Troubleshooting

### Masalah 1: Flutter tidak connect ke MQTT
**Gejala:** "MQTT Service: Connection failed"

**Solusi:**
1. Cek internet connection di PC/HP
2. Coba ganti broker di kedua file:
   ```
   // Alternatif 1
   broker.hivemq.com
   
   // Alternatif 2
   test.mosquitto.org
   
   // Alternatif 3
   mqtt.eclipseprojects.io
   ```
3. Restart Flutter app

### Masalah 2: ESP32 connect tapi Flutter tidak terima data
**Gejala:** ESP32 "Published to MQTT" tapi Flutter tidak ada "MQTT Received"

**Solusi:**
1. Pastikan TOPIC NAME **PERSIS SAMA** (case sensitive!)
   - ❌ `Teralux/sensors` vs `teralux/sensors`
   - ❌ `teralux/sensor` vs `teralux/sensors`
   - ✅ `teralux/sensors` (keduanya sama)

2. Cek apakah Flutter sudah subscribe:
   - Lihat log "✓ MQTT Service: Subscribed to all topics"
   
3. Test dengan MQTT Explorer:
   - Download: http://mqtt-explorer.com/
   - Connect ke `broker.hivemq.com:1883`
   - Subscribe ke `teralux/#`
   - Lihat apakah data dari ESP32 muncul

### Masalah 3: Data muncul tapi parsing error
**Gejala:** "Error parsing message from teralux/sensors"

**Solusi:**
1. Cek format JSON di Serial Monitor ESP32
2. Pastikan model Flutter bisa parse field yang dikirim
3. Lihat "Raw payload" di error message

### Masalah 4: Publish dari Flutter tidak sampai ESP32
**Gejala:** Flutter "Published successfully" tapi ESP32 tidak terima

**Solusi:**
1. Pastikan ESP32 sudah subscribe ke topic:
   ```cpp
   client.subscribe(topic_pump_control);
   client.subscribe(topic_light_control);
   client.subscribe(topic_threshold_settings);
   ```

2. Cek MQTT state di ESP32:
   ```cpp
   Serial.print("MQTT State: ");
   Serial.println(client.state());
   // 0 = connected
   // -4 = timeout
   // -2 = connect failed
   ```

## Format JSON Yang Benar

### Sensor Data (ESP32 → Flutter)
```json
{
  "lightLevel": 245,
  "rawMoistureValue": 2456,
  "moistureLevel": 65,
  "timestamp": 123456
}
```

### Pump Control (Flutter → ESP32)
```json
{
  "mode": "start",
  "duration": 30,
  "manual": true
}
```

### Pump Status (ESP32 → Flutter)
```json
{
  "isRunning": true,
  "remainingSeconds": 25,
  "manual": true
}
```

### Light Control (Flutter → ESP32)
```json
{
  "isLightOn": true,
  "manual": true
}
```

### Light Status (ESP32 → Flutter)
```json
{
  "isLightOn": true,
  "manual": false
}
```

## Logging Yang Sudah Ditambahkan

Sekarang kode Flutter dan ESP32 sudah punya logging lengkap:

### ESP32
- `💡` = Data sensor
- `📤` = Publish ke MQTT
- `💧` = Pump control
- `💡` = Light control
- `⚙️` = Settings update
- `🤖` = Auto control trigger

### Flutter
- `📥` = Menerima data dari MQTT
- `📤` = Mengirim data ke MQTT
- `✓` = Sukses
- `✗` = Gagal
- `➜` = Detail operasi

## Kesimpulan

Jika semuanya benar, Anda akan melihat alur seperti ini:

**ESP32 Serial Monitor:**
```
💡 245 Lux | 💧 2456 (65%)
📤 Published to MQTT
```

**Flutter Debug Console:**
```
📥 MQTT Received: teralux/sensors
   Payload: {"lightLevel":245,"rawMoistureValue":2456,"moistureLevel":65,"timestamp":123456}
   ➜ Sensor data parsed
```

**Flutter UI:**
```
Dashboard menampilkan:
- Light: 245 Lux
- Soil: 65%
```

Silakan jalankan ulang ESP32 dan Flutter app, lalu perhatikan log di kedua sisi!
