# Setup MQTT Real Implementation - TeraLux Flutter App

## ✅ Status: MQTT Real Implementation COMPLETE

MQTT service sudah diubah dari dummy simulation ke real MQTT client implementation. Sekarang aplikasi Flutter dapat berkomunikasi langsung dengan ESP32 via MQTT broker.

## 📦 Package yang Digunakan

- **mqtt_client** v10.11.1 - Sudah terinstall ✅

## 🔧 Konfigurasi MQTT Broker

### File: `lib/services/mqtt_service.dart`

Buka file tersebut dan ubah konfigurasi broker sesuai kebutuhan:

```dart
// MQTT Configuration - GANTI SESUAI BROKER ANDA
static const String broker = 'broker.hivemq.com'; // Public broker untuk testing
// static const String broker = '192.168.1.100'; // Uncomment untuk broker lokal
static const int port = 1883;
static const String username = ''; // Kosongkan jika tidak pakai auth
static const String password = '';
```

### Pilihan Broker:

#### 1. **Public Broker (HiveMQ)** - Untuk Testing
```dart
static const String broker = 'broker.hivemq.com';
static const int port = 1883;
static const String username = '';
static const String password = '';
```
✅ **Kelebihan**: Langsung bisa digunakan, tidak perlu setup
⚠️ **Kekurangan**: Public (siapa saja bisa subscribe), tidak aman untuk produksi

#### 2. **Local Mosquitto Broker** - Untuk Produksi (Recommended)
```dart
static const String broker = '192.168.1.100'; // IP address PC/Raspberry Pi
static const int port = 1883;
static const String username = ''; // Opsional
static const String password = '';
```
✅ **Kelebihan**: Aman, cepat, private network
⚠️ **Kekurangan**: Butuh setup Mosquitto server

## 🖥️ Setup Mosquitto Broker (Lokal)

### Windows:

1. Download Mosquitto: https://mosquitto.org/download/
2. Install dengan default settings
3. Jalankan Mosquitto:
   ```powershell
   net start mosquitto
   ```
4. Cek IP address PC:
   ```powershell
   ipconfig
   ```
   Cari "IPv4 Address" (contoh: 192.168.1.100)
5. Update `mqtt_service.dart` dengan IP tersebut

### Linux/Raspberry Pi:

```bash
# Install
sudo apt update
sudo apt install mosquitto mosquitto-clients

# Start service
sudo systemctl start mosquitto
sudo systemctl enable mosquitto

# Cek IP address
hostname -I
```

### Test Broker:

```bash
# Subscribe (terminal 1)
mosquitto_sub -h localhost -t "teralux/#" -v

# Publish (terminal 2)
mosquitto_pub -h localhost -t "teralux/test" -m "Hello from MQTT"
```

## 📡 MQTT Topics Structure

Aplikasi Flutter menggunakan 6 topics untuk komunikasi dengan ESP32:

| Topic | Direction | QoS | Deskripsi |
|-------|-----------|-----|-----------|
| `teralux/sensors` | ESP32 → Flutter | 1 | Data sensor (light, moisture) |
| `teralux/pump/control` | Flutter → ESP32 | 1 | Kontrol pompa (ON/OFF) |
| `teralux/pump/status` | ESP32 → Flutter | 1 | Status pompa |
| `teralux/light/control` | Flutter → ESP32 | 1 | Kontrol lampu (ON/OFF) |
| `teralux/light/status` | ESP32 → Flutter | 1 | Status lampu |
| `teralux/settings/threshold` | Flutter → ESP32 | 1 | Settings threshold auto control |

### Format JSON:

**teralux/sensors** (ESP32 → Flutter):
```json
{
  "lightLevel": 1234.5,
  "moistureLevel": 45.6,
  "rawMoistureValue": 2500
}
```

**teralux/pump/control** (Flutter → ESP32):
```json
{
  "isPumpOn": true,
  "isAutoMode": false,
  "duration": 30
}
```

**teralux/light/control** (Flutter → ESP32):
```json
{
  "isLightOn": true
}
```

**teralux/settings/threshold** (Flutter → ESP32):
```json
{
  "soilMoistureMin": 30,
  "lightLevelMin": 1000,
  "wateringDuration": 30,
  "autoWateringEnabled": true,
  "autoLightingEnabled": true,
  "soilDryValue": 4095,
  "soilWetValue": 1500
}
```

## 🚀 Cara Menggunakan

### 1. **Setup ESP32**

Upload program Arduino ke ESP32:
- File: `arduino/teralux_esp32.ino`
- Ubah WiFi credentials:
  ```cpp
  const char* ssid = "YOUR_WIFI_SSID";
  const char* password = "YOUR_WIFI_PASSWORD";
  ```
- Ubah MQTT broker address (harus sama dengan Flutter):
  ```cpp
  const char* mqtt_server = "192.168.1.100"; // atau "broker.hivemq.com"
  ```
- Upload ke ESP32

### 2. **Setup Flutter App**

1. Pastikan mqtt_client sudah terinstall:
   ```bash
   flutter pub get
   ```

2. Update broker address di `lib/services/mqtt_service.dart`:
   ```dart
   static const String broker = 'broker.hivemq.com'; // atau IP lokal
   ```

3. Jalankan aplikasi:
   ```bash
   flutter run
   ```

### 3. **Test Koneksi**

1. Buka aplikasi Flutter
2. Login → Dashboard
3. Cek console log untuk message:
   ```
   MQTT Service: Connecting to broker.hivemq.com:1883...
   MQTT Service: Connected successfully!
   MQTT Service: Subscribing to topics...
   MQTT Service: Subscribed to all topics
   ```

4. Jika berhasil connect, dashboard akan mulai menerima data sensor dari ESP32

## 🔍 Troubleshooting

### Problem: "Connection failed - Connection refused"

**Solusi**:
1. Pastikan broker address benar
2. Pastikan ESP32 dan Flutter terhubung ke WiFi yang sama
3. Ping broker dari PC:
   ```powershell
   ping 192.168.1.100
   ```
4. Cek firewall (Windows Defender bisa block port 1883)

### Problem: "No sensor data received"

**Solusi**:
1. Cek Serial Monitor ESP32 untuk memastikan ESP32 publish data
2. Pastikan ESP32 connected ke broker
3. Test dengan MQTT client:
   ```bash
   mosquitto_sub -h YOUR_BROKER_IP -t "teralux/#" -v
   ```

### Problem: "Pump/Light control not working"

**Solusi**:
1. Cek Serial Monitor ESP32 untuk melihat apakah message diterima
2. Pastikan topic name sama persis (case-sensitive)
3. Test manual publish:
   ```bash
   mosquitto_pub -h YOUR_BROKER_IP -t "teralux/pump/control" -m '{"isPumpOn":true,"duration":5}'
   ```

### Problem: "Auto control not triggering"

**Solusi**:
1. Pastikan auto control enabled di Settings page
2. Cek threshold values (jangan terlalu tinggi/rendah)
3. Cek console log untuk message "Auto watering triggered" atau "Auto lighting ON"
4. Auto watering ada cooldown 5 menit (cegah overwatering)

## 📊 Monitoring MQTT Traffic

### Menggunakan MQTT Explorer (Recommended)

1. Download: http://mqtt-explorer.com/
2. Install dan buka
3. Connection settings:
   - Protocol: mqtt://
   - Host: YOUR_BROKER_IP
   - Port: 1883
4. Connect
5. Expand topic `teralux` untuk melihat semua messages real-time

### Menggunakan Mosquitto CLI

```bash
# Subscribe ke semua topic teralux
mosquitto_sub -h YOUR_BROKER_IP -t "teralux/#" -v

# Subscribe hanya sensor data
mosquitto_sub -h YOUR_BROKER_IP -t "teralux/sensors"

# Test publish pump control
mosquitto_pub -h YOUR_BROKER_IP -t "teralux/pump/control" -m '{"isPumpOn":true,"duration":10}'

# Test publish light control
mosquitto_pub -h YOUR_BROKER_IP -t "teralux/light/control" -m '{"isLightOn":true}'
```

## 🔐 Security (Production)

Untuk produksi, enable authentication di Mosquitto:

1. Buat password file:
   ```bash
   sudo mosquitto_passwd -c /etc/mosquitto/passwd teralux_user
   ```

2. Edit `/etc/mosquitto/mosquitto.conf`:
   ```conf
   allow_anonymous false
   password_file /etc/mosquitto/passwd
   ```

3. Restart Mosquitto:
   ```bash
   sudo systemctl restart mosquitto
   ```

4. Update Flutter `mqtt_service.dart`:
   ```dart
   static const String username = 'teralux_user';
   static const String password = 'your_password';
   ```

## 📝 Catatan Penting

1. **WiFi Network**: ESP32 dan smartphone/PC harus di network yang sama untuk broker lokal
2. **Public Broker**: Jangan gunakan untuk produksi (tidak aman, siapa saja bisa akses)
3. **QoS Level**: Semua topic menggunakan QoS 1 (at least once delivery)
4. **Auto Reconnect**: MQTT client otomatis reconnect jika koneksi terputus
5. **Keep Alive**: 60 detik (client ping broker setiap 60 detik)
6. **Clean Session**: true (tidak menyimpan subscriptions setelah disconnect)

## ✅ Testing Checklist

- [ ] ESP32 connect ke WiFi dan MQTT broker
- [ ] Flutter app connect ke MQTT broker
- [ ] Dashboard menerima data sensor real-time
- [ ] Manual pump control working (Pump Control page)
- [ ] Manual light control working (Light Control page)
- [ ] Settings page save threshold settings
- [ ] Auto watering triggered when moisture < threshold
- [ ] Auto lighting triggered when light < threshold
- [ ] Calibration page update soil sensor calibration
- [ ] All controls work bidirectional (Flutter ↔ ESP32)

## 📚 Reference

- MQTT Protocol: https://mqtt.org/
- mqtt_client package: https://pub.dev/packages/mqtt_client
- Mosquitto: https://mosquitto.org/
- HiveMQ Public Broker: https://www.hivemq.com/public-mqtt-broker/
- Arduino MQTT Tutorial: `arduino/MQTT_SETUP.md`

## 🎯 Next Steps

1. ✅ MQTT real implementation - DONE
2. ⏳ Test dengan ESP32 hardware
3. ⏳ Fine-tune auto control parameters
4. ⏳ Add data logging/history
5. ⏳ Deploy ke production dengan secure broker

---

**Status Update**: Real MQTT implementation sudah lengkap! 🎉
Sekarang aplikasi siap untuk testing dengan ESP32 hardware.
