# QUICK FIX: MQTT Tidak Bisa Subscribe

## Masalah
ESP32 sudah publish data, tapi Flutter tidak menerima.

## Perbaikan Yang Sudah Dilakukan

### 1. Menghapus `startClean()`
**Sebelum:**
```dart
final connMessage = MqttConnectMessage()
    .withClientIdentifier(clientId)
    .startClean()  // ← INI MASALAHNYA!
    .withWillQos(MqttQos.atLeastOnce);
```

**Sesudah:**
```dart
final connMessage = MqttConnectMessage()
    .withClientIdentifier(clientId)
    .keepAliveFor(60)  // ← Diganti dengan keepAlive
    .withWillQos(MqttQos.atLeastOnce);
```

### 2. Setup Listener SEBELUM Subscribe
**Sebelum:**
```dart
_subscribeToTopics();
_setupListeners();  // ← Terlambat!
```

**Sesudah:**
```dart
_setupListeners();  // ← Setup listener dulu
await Future.delayed(Duration(milliseconds: 500));  // Delay untuk stabilkan
_subscribeToTopics();
```

### 3. Menggunakan `MqttServerClient.withPort()`
**Sebelum:**
```dart
client = MqttServerClient(broker, clientId);
client!.port = port;
```

**Sesudah:**
```dart
client = MqttServerClient.withPort(broker, clientId, port);
```

### 4. Menggunakan QoS 0 (At Most Once)
**Sebelum:**
```dart
client!.subscribe(topicSensors, MqttQos.atLeastOnce);  // QoS 1
```

**Sesudah:**
```dart
client!.subscribe(topicSensors, MqttQos.atMostOnce);  // QoS 0 - lebih simple
```

### 5. Menambahkan Callback Handlers
```dart
client!.onSubscribed = (String topic) {
  print('✓ Successfully subscribed to $topic');
};

client!.onSubscribeFail = (String topic) {
  print('✗ Failed to subscribe to $topic');
};
```

## Cara Test

### Langkah 1: Jalankan ESP32
```
1. Upload teralux_esp32.ino ke ESP32
2. Buka Serial Monitor (115200 baud)
3. Cek ada output:
   ✓ WiFi connected!
   ✓ MQTT Connected!
   📤 Published to MQTT
```

### Langkah 2: Jalankan Flutter
```powershell
cd c:\Users\Nizarrr\Documents\teralux\teralux
flutter run
```

### Langkah 3: Buka MQTT Test Page
```
1. Login ke app (teralux / teralux123)
2. Di dashboard, klik icon BUG (🐛) di kanan atas
3. Lihat MQTT Test Page dengan:
   - Status koneksi (hijau = connected)
   - Log real-time
   - Tombol test
```

### Langkah 4: Cek Log
**Flutter Debug Console harus menampilkan:**
```
========================================
MQTT Service: Connecting to broker.hivemq.com:1883...
Client ID: TeraLux-Flutter-1733123456789
========================================
✓ MQTT Service: Connected successfully!
========================================
MQTT Service: Subscribing to topics...
  ➜ teralux/sensors (Subscription ID: ...)
  ➜ teralux/pump/status (Subscription ID: ...)
  ➜ teralux/light/status (Subscription ID: ...)
✓ MQTT Service: Subscribed to all topics
  Waiting for messages from ESP32...
========================================
✓ MQTT Service: Successfully subscribed to teralux/sensors
✓ MQTT Service: Successfully subscribed to teralux/pump/status
✓ MQTT Service: Successfully subscribed to teralux/light/status
📥 MQTT Received: teralux/sensors
   Payload: {"lightLevel":245,"rawMoistureValue":2456,"moistureLevel":65,"timestamp":123456}
   ➜ Sensor data parsed
```

### Langkah 5: Test Publish
```
1. Di MQTT Test Page, klik "Test Pump"
2. Cek Serial Monitor ESP32:
   [MQTT] teralux/pump/control: {"mode":"start","duration":10,"manual":true}
   💧 Pump ON (10s) - Mode: MANUAL
```

## Jika Masih Gagal

### Cek 1: Koneksi Internet
```powershell
ping broker.hivemq.com
```
Harus ada reply, tidak "Request timed out"

### Cek 2: Firewall
```
Matikan Windows Firewall sementara untuk test
Control Panel → Windows Defender Firewall → Turn off
```

### Cek 3: Ganti Broker
Edit kedua file (ESP32 dan Flutter):
```
broker.hivemq.com        → test.mosquitto.org
atau
broker.hivemq.com        → mqtt.eclipseprojects.io
```

### Cek 4: Pakai MQTT Explorer
```
1. Download: http://mqtt-explorer.com/
2. Connect ke broker.hivemq.com:1883
3. Subscribe ke teralux/#
4. Lihat apakah data dari ESP32 muncul
5. Publish manual ke teralux/pump/control
```

## Output Yang Benar

### ESP32 Serial Monitor:
```
💡 245 Lux | 💧 2456 (65%)
📤 Published to MQTT

[MQTT] teralux/pump/control: {"mode":"start","duration":10,"manual":true}
💧 Pump ON (10s) - Mode: MANUAL
```

### Flutter Debug Console:
```
📥 MQTT Received: teralux/sensors
   Payload: {"lightLevel":245,"rawMoistureValue":2456,"moistureLevel":65,"timestamp":123456}
   ➜ Sensor data parsed

📤 MQTT Publishing to: teralux/pump/control
   Payload: {"mode":"start","duration":10,"manual":true}
   ✓ Published successfully
```

### MQTT Test Page Log:
```
[12:34] Setting up MQTT callbacks...
[12:34] Connecting to MQTT broker...
[12:34] Connection attempt completed
[12:34] 📥 Sensor Data: L=245 M=65%
[12:35] Sending test pump command...
```

## Kesimpulan

Perbaikan utama adalah:
1. ✅ Hapus `startClean()` yang menghapus session
2. ✅ Setup listener sebelum subscribe
3. ✅ Gunakan QoS 0 untuk kesederhanaan
4. ✅ Tambahkan callback untuk monitoring
5. ✅ Tambahkan delay untuk stabilkan koneksi

Jika masih gagal, gunakan **MQTT Test Page** untuk debugging!
