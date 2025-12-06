# MQTT Implementation Update Summary

## ✅ Perubahan yang Sudah Dilakukan

### 1. **Package Installation**
- ✅ Installed `mqtt_client` v10.11.1 via `flutter pub add mqtt_client`

### 2. **File: `lib/services/mqtt_service.dart`**
Status: **✅ COMPLETE - Converted from Dummy to Real MQTT**

#### Perubahan Utama:
- ✅ Removed dummy simulation code
- ✅ Added real `MqttServerClient` implementation
- ✅ Implemented `connect()` method dengan auto-reconnect
- ✅ Implemented `_subscribeToTopics()` untuk subscribe ke:
  - `teralux/sensors` (sensor data dari ESP32)
  - `teralux/pump/status` (status pompa)
  - `teralux/light/status` (status lampu)
- ✅ Implemented `_setupListeners()` untuk parse incoming MQTT messages
- ✅ Implemented `publishPumpControl()` untuk kontrol pompa
- ✅ Implemented `publishLightControl()` untuk kontrol lampu
- ✅ Implemented `updateThresholdSettings()` untuk kirim settings ke ESP32
- ✅ Auto control logic tetap berfungsi (`_checkAutoControl()`)

#### MQTT Configuration (yang perlu diubah user):
```dart
static const String broker = 'broker.hivemq.com'; // Public broker untuk testing
// static const String broker = '192.168.1.100'; // Uncomment untuk broker lokal
static const int port = 1883;
static const String username = ''; // Kosongkan jika tidak pakai auth
static const String password = '';
```

### 3. **File: `lib/models/calibration_data.dart`**
Status: **✅ UPDATED - Added Raw ADC Fields**

#### Perubahan:
- ✅ Added `soilDryValue` field (int, default 4095)
- ✅ Added `soilWetValue` field (int, default 1500)
- ✅ Updated `toJson()` to include these fields
- ✅ Updated `fromJson()` to parse these fields

**Reason**: ESP32 needs raw ADC values (soilDryValue, soilWetValue) untuk kalibrasi soil moisture sensor. Flutter sekarang kirim values ini ke ESP32 via MQTT topic `teralux/settings/threshold`.

### 4. **File: `MQTT_FLUTTER_SETUP.md`**
Status: **✅ CREATED - Complete Setup Guide**

Comprehensive documentation mencakup:
- ✅ MQTT broker configuration (HiveMQ public vs Mosquitto local)
- ✅ Setup instructions untuk Windows/Linux/Raspberry Pi
- ✅ MQTT topics structure dan JSON format
- ✅ Testing procedures
- ✅ Troubleshooting guide
- ✅ Security recommendations
- ✅ MQTT monitoring tools

## 📋 Yang TIDAK Berubah (Masih Berfungsi Normal)

- ✅ All UI pages (Dashboard, Settings, Pump Control, Light Control, Calibration)
- ✅ All models (SensorData, PumpControl, LightControl, ThresholdSettings)
- ✅ All widgets (cards, buttons, etc.)
- ✅ Auto control logic (threshold-based watering dan lighting)
- ✅ Calibration system (soil moisture sensor)
- ✅ Singleton pattern untuk MqttService

## 🔄 Data Flow (Real MQTT)

### Sensor Data (ESP32 → Flutter):
```
ESP32 (Arduino)
  ↓ publish to "teralux/sensors"
MQTT Broker
  ↓ forward message
Flutter App (MqttService)
  ↓ parse JSON
Dashboard (Update UI)
  ↓ trigger if threshold met
Auto Control (_checkAutoControl)
```

### Pump Control (Flutter → ESP32):
```
Flutter UI (Pump Control Page)
  ↓ user tap button
MqttService.publishPumpControl()
  ↓ publish to "teralux/pump/control"
MQTT Broker
  ↓ forward message
ESP32 (Arduino)
  ↓ activate relay
Pump ON/OFF
  ↓ publish status
"teralux/pump/status"
  ↓ receive in Flutter
Dashboard (Update status)
```

### Settings (Flutter → ESP32):
```
Flutter UI (Settings Page)
  ↓ user save settings
MqttService.updateThresholdSettings()
  ↓ publish to "teralux/settings/threshold"
MQTT Broker
  ↓ forward message
ESP32 (Arduino)
  ↓ update variables (soilMoistureMin, lightLevelMin, etc.)
Auto Control (ESP32 side)
  ↓ use new threshold values
```

## 🎯 Testing Instructions

### Step 1: Setup MQTT Broker (Choose one)

#### Option A: Public Broker (Quick Test)
```dart
// lib/services/mqtt_service.dart
static const String broker = 'broker.hivemq.com';
```
No additional setup needed ✅

#### Option B: Local Broker (Production)
```bash
# Windows
net start mosquitto

# Linux/Raspberry Pi
sudo systemctl start mosquitto
```

Get IP address and update:
```dart
// lib/services/mqtt_service.dart
static const String broker = '192.168.1.100'; // Your PC IP
```

### Step 2: Upload ESP32 Program
```
1. Open arduino/teralux_esp32.ino
2. Update WiFi credentials
3. Update MQTT broker address (same as Flutter)
4. Upload to ESP32
5. Open Serial Monitor (115200 baud)
```

### Step 3: Run Flutter App
```bash
flutter run
```

### Step 4: Check Logs

**Expected ESP32 Serial Output:**
```
Connecting to WiFi...
WiFi connected! IP: 192.168.1.101
Connecting to MQTT broker...
Connected to MQTT broker!
Subscribed to teralux/pump/control
Subscribed to teralux/light/control
Subscribed to teralux/settings/threshold
Publishing sensor data...
  Light Level: 1234.5 Lux
  Moisture Level: 45.6%
```

**Expected Flutter Console Output:**
```
MQTT Service: Connecting to broker.hivemq.com:1883...
MQTT Service: Connected successfully!
MQTT Service: Subscribing to topics...
MQTT Service: Subscribed to all topics
```

### Step 5: Test Controls

1. **Manual Pump Control**:
   - Navigate to Pump Control page
   - Tap "Nyalakan Pompa"
   - Check ESP32 relay activates
   - Check Serial Monitor shows "Pump: ON"

2. **Manual Light Control**:
   - Navigate to Light Control page
   - Toggle switch
   - Check ESP32 relay activates
   - Check Serial Monitor shows "Light: ON"

3. **Auto Control**:
   - Navigate to Settings page
   - Enable "Aktifkan Penyiraman Otomatis"
   - Set "Kelembaban Tanah Minimum" to 50%
   - Save settings
   - Cover soil sensor (make it dry)
   - Wait for moisture to drop below 50%
   - Pump should activate automatically ✅

4. **Threshold Update**:
   - Change threshold in Settings
   - Check ESP32 Serial Monitor shows: "Received threshold settings"
   - Verify new values applied

## 🐛 Known Issues

### Lint Warning:
```
_lastAutoLighting field unused
```
**Status**: Harmless lint warning, tidak affect functionality. Field ini di-set tapi tidak di-read karena auto lighting tidak perlu cooldown (berbeda dengan auto watering yang butuh 5 menit cooldown).

**Fix (Optional)**: Remove field atau add comment `// ignore: unused_field`

## 📊 MQTT Topics Reference

| Topic | Publisher | Subscriber | Format |
|-------|-----------|------------|--------|
| teralux/sensors | ESP32 | Flutter | `{"lightLevel": double, "moistureLevel": double, "rawMoistureValue": double}` |
| teralux/pump/control | Flutter | ESP32 | `{"isPumpOn": bool, "isAutoMode": bool, "duration": int}` |
| teralux/pump/status | ESP32 | Flutter | `{"isPumpOn": bool, "isAutoMode": bool, "duration": int}` |
| teralux/light/control | Flutter | ESP32 | `{"isLightOn": bool}` |
| teralux/light/status | ESP32 | Flutter | `{"isLightOn": bool}` |
| teralux/settings/threshold | Flutter | ESP32 | `{"soilMoistureMin": int, "lightLevelMin": int, "wateringDuration": int, "autoWateringEnabled": bool, "autoLightingEnabled": bool, "soilDryValue": int, "soilWetValue": int}` |

## ✅ Completion Checklist

- [x] Remove dummy MQTT implementation
- [x] Add mqtt_client package
- [x] Implement MqttServerClient connection
- [x] Implement topic subscriptions
- [x] Implement message parsing (sensors, pump status, light status)
- [x] Implement publish methods (pump control, light control, threshold settings)
- [x] Update CalibrationData model with raw ADC fields
- [x] Test code formatting
- [x] Create setup documentation
- [x] Create testing guide
- [ ] Hardware testing dengan ESP32 (pending, butuh hardware)

## 🚀 Next Steps

1. **Hardware Testing**: Test dengan ESP32 fisik + sensors
2. **Broker Configuration**: Setup local Mosquitto untuk production
3. **Security**: Enable MQTT authentication untuk production
4. **Data Logging**: Add persistent storage untuk sensor history
5. **Notifications**: Add push notifications untuk alerts (low moisture, etc.)
6. **UI Polish**: Add connection status indicator di dashboard

---

**Status**: ✅ MQTT Real Implementation COMPLETE
**Ready for**: Hardware testing dengan ESP32

Last updated: ${DateTime.now().toString().split('.')[0]}
