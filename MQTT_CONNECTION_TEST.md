# 🔗 MQTT Connection Test Guide

## ✅ Konfigurasi Sudah Disesuaikan!

### ESP32 Configuration:
```cpp
const char* mqtt_server = "test.mosquitto.org";
const int mqtt_port = 1883;
```

### Flutter Configuration:
```dart
static const String broker = 'test.mosquitto.org';
static const int port = 1883;
```

**Status:** ✅ **SYNCHRONIZED!** - Kedua aplikasi menggunakan broker yang sama.

---

## 🚀 Testing Steps

### 1️⃣ Upload ESP32 Program

```
1. Open Arduino IDE
2. File: arduino/teralux_esp32.ino
3. Board: ESP32 Dev Module
4. Port: COM3 (sesuaikan)
5. Upload!
6. Open Serial Monitor (115200 baud)
```

**Expected Output:**
```
=================================
  TeraLux ESP32 Controller
  FIXED VERSION v2.0
=================================

[1] Pins initialized
[2] ADC configured (12-bit, 0-3.3V)
[2a] Testing soil sensor on pin 34... 2567 ✓ OK
[3] I2C initialized
[4] Initializing BH1750... ✓ OK
    Test reading: 245.0 Lux
[5] Connecting to WiFi: vivo 1807
[5] WiFi connected!
    IP: 192.168.1.XXX
    RSSI: -45 dBm
[6] MQTT client configured

Setup complete! Starting loop...

MQTT connecting... ✓ Connected!
💡 245 Lux | 💧 2567 (45%)
📤 Published to MQTT
```

### 2️⃣ Run Flutter App

```powershell
flutter run -d windows
# atau
flutter run -d chrome
# atau untuk Android/iOS
flutter run
```

**Expected Console Output:**
```
MQTT Service: Connecting to test.mosquitto.org:1883...
MQTT Service: Connected successfully!
MQTT Service: Subscribing to topics...
MQTT Service: Subscribed to all topics
```

### 3️⃣ Verify Connection

**Dashboard should show:**
- ✅ Light Level updating (e.g., "245 Lux")
- ✅ Soil Moisture updating (e.g., "45%")
- ✅ Data updates every 5 seconds

**If data not showing:**
```dart
// Check console for incoming messages
// Should see something like:
// Received sensor data: {lightLevel: 245, moistureLevel: 45}
```

---

## 🧪 Test MQTT Communication

### Test 1: Sensor Data (ESP32 → Flutter)

**Expected Flow:**
```
ESP32 publishes → test.mosquitto.org → Flutter receives
Every 5 seconds: {"lightLevel": 245, "moistureLevel": 45, "rawMoistureValue": 2567}
```

**Verify:**
- Dashboard cards update automatically
- Light level shows real sensor value
- Moisture level shows real sensor value

### Test 2: Pump Control (Flutter → ESP32)

**Steps:**
```
1. Open Pump Control page
2. Set duration: 10 seconds
3. Tap "Mulai"
4. Watch Serial Monitor
```

**Expected ESP32 Output:**
```
[MQTT] teralux/pump/control: {"mode":"start","duration":10}
💧 Pump ON (10s)
📤 Published to MQTT

... after 10 seconds ...

💧 Pump timer finished
```

**Expected Flutter:**
- Button "Mulai" becomes disabled
- Button "Stop" becomes enabled
- Countdown shows: 10, 9, 8, 7...
- After 10s, pump stops automatically

### Test 3: Light Control (Flutter → ESP32)

**Steps:**
```
1. Open Light Control page
2. Toggle switch ON
3. Watch Serial Monitor
```

**Expected ESP32 Output:**
```
[MQTT] teralux/light/control: {"isLightOn":true}
💡 Light ON
```

**Expected Flutter:**
- Switch shows ON
- Light status card updates

### Test 4: Settings Update (Flutter → ESP32)

**Steps:**
```
1. Open Settings page
2. Enable "Penyiraman Otomatis"
3. Set "Kelembaban Tanah Minimum": 50%
4. Set "Watering Duration": 30s
5. Enable "Pencahayaan Otomatis"
6. Set "Light Level Minimum": 1000 Lux
7. Tap "Simpan Pengaturan"
8. Watch Serial Monitor
```

**Expected ESP32 Output:**
```
[MQTT] teralux/settings/threshold: {"soilMoistureMin":50,"lightLevelMin":1000,...}
⚙️  Settings updated
```

### Test 5: Auto Watering

**Trigger:**
```
- Cover soil sensor dengan tangan (make it dry)
- Wait for moisture to drop below threshold (50%)
- ESP32 should automatically start pump
```

**Expected ESP32 Output:**
```
💡 245 Lux | 💧 3800 (20%)  ← Moisture drops below 50%

🤖 AUTO WATERING!
💧 Pump ON (30s)
```

**Expected Flutter:**
- Dashboard shows low moisture
- Pump status updates to "running"
- Countdown appears

### Test 6: Auto Lighting

**Trigger:**
```
- Cover BH1750 sensor dengan tangan (make it dark)
- Wait for light to drop below threshold (1000 Lux)
- ESP32 should automatically turn on light
```

**Expected ESP32 Output:**
```
💡 50 Lux | 💧 2567 (45%)  ← Light drops below 1000 Lux

🤖 AUTO LIGHT ON!
💡 Light ON
```

**Expected Flutter:**
- Dashboard shows low light level
- Light status updates to "ON"

---

## 🛠️ Troubleshooting

### ❌ ESP32: "MQTT connecting... ✗ Failed (-2)"

**Penyebab:**
- WiFi not connected
- Broker address salah
- Internet connection issue

**Solusi:**
```cpp
1. Check WiFi credentials
2. Verify broker: "test.mosquitto.org" (typo? "mosqito" vs "mosquitto")
3. Test ping: ping test.mosquitto.org
4. Try alternative: "broker.hivemq.com"
```

### ❌ Flutter: "Connection failed - Connection refused"

**Penyebab:**
- Broker address salah
- Network firewall blocking port 1883

**Solusi:**
```dart
1. Check broker name matches ESP32
2. Disable Windows Firewall temporarily
3. Try alternative broker
```

### ❌ Dashboard tidak menampilkan data

**Penyebab:**
- ESP32 tidak publish
- Flutter tidak subscribe
- Different topics

**Debug:**
```bash
# Install mosquitto client tools
# Subscribe to all teralux topics
mosquitto_sub -h test.mosquitto.org -t "teralux/#" -v

# You should see:
teralux/sensors {"lightLevel":245,"moistureLevel":45,...}
teralux/pump/status {"isRunning":false,"remainingSeconds":0}
teralux/light/status {"isLightOn":false}
```

### ❌ Pump control tidak bekerja

**Debug ESP32:**
```cpp
// Add debug print in callback function
Serial.print("Received topic: ");
Serial.println(topic);
Serial.print("Payload: ");
Serial.println(message);
```

**Debug Flutter:**
```dart
// Add debug in publishPumpControl
print('Publishing to $topicPumpControl: $controlData');
```

### ❌ Auto control tidak trigger

**Check Threshold Values:**
```
ESP32 Serial Monitor:
💡 245 Lux | 💧 2567 (45%)

Settings:
- soilMoistureMin: 30% ✓ (45% > 30%, OK tidak trigger)
- lightLevelMin: 1000 Lux ✓ (245 < 1000, should trigger!)
```

**Check Auto Enable:**
```dart
// Settings page
autoWateringEnabled: true ✓
autoLightingEnabled: true ✓
```

---

## 📊 Monitor MQTT Traffic (Advanced)

### Option 1: MQTT Explorer (GUI)

```
1. Download: http://mqtt-explorer.com/
2. Install and open
3. Connection:
   - Protocol: mqtt://
   - Host: test.mosquitto.org
   - Port: 1883
4. Connect
5. Expand "teralux" topic
6. See all messages real-time with payload!
```

### Option 2: Mosquitto CLI

**Install:**
```bash
# Windows (via Chocolatey)
choco install mosquitto

# Or download from:
# https://mosquitto.org/download/
```

**Subscribe:**
```bash
# All teralux topics
mosquitto_sub -h test.mosquitto.org -t "teralux/#" -v

# Only sensor data
mosquitto_sub -h test.mosquitto.org -t "teralux/sensors"

# Only pump messages
mosquitto_sub -h test.mosquitto.org -t "teralux/pump/#" -v
```

**Publish (Manual Test):**
```bash
# Test pump control from command line
mosquitto_pub -h test.mosquitto.org -t "teralux/pump/control" -m '{"mode":"start","duration":5}'

# Test light control
mosquitto_pub -h test.mosquitto.org -t "teralux/light/control" -m '{"isLightOn":true}'

# Test settings
mosquitto_pub -h test.mosquitto.org -t "teralux/settings/threshold" -m '{"soilMoistureMin":40,"lightLevelMin":1500,"wateringDuration":25,"autoWateringEnabled":true,"autoLightingEnabled":true,"soilDryValue":4095,"soilWetValue":1500}'
```

---

## ✅ Connection Success Indicators

### ESP32:
```
✓ WiFi connected! IP: 192.168.1.XXX
✓ MQTT connecting... ✓ Connected!
✓ 📤 Published to MQTT (every 5 seconds)
✓ [MQTT] teralux/pump/control: ... (when command received)
```

### Flutter:
```
✓ MQTT Service: Connected successfully!
✓ MQTT Service: Subscribed to all topics
✓ Dashboard showing sensor data
✓ Data updating automatically
```

### MQTT Explorer:
```
✓ teralux/sensors - Last update: 2 seconds ago
✓ teralux/pump/status - Value: {"isRunning":false,...}
✓ teralux/light/status - Value: {"isLightOn":false}
```

---

## 🎯 Quick Verification Checklist

**Before Testing:**
- [ ] ESP32 code uploaded
- [ ] WiFi credentials correct
- [ ] Broker address: "test.mosquitto.org" (same in both)
- [ ] Flutter app compiled
- [ ] Serial Monitor open (115200 baud)

**Connection:**
- [ ] ESP32 WiFi connected
- [ ] ESP32 MQTT connected
- [ ] Flutter MQTT connected
- [ ] No errors in console

**Data Flow:**
- [ ] ESP32 publishing sensor data (Serial Monitor shows "📤")
- [ ] Flutter receiving data (Dashboard updates)
- [ ] Flutter publishing commands (Serial Monitor shows "[MQTT]")
- [ ] ESP32 receiving commands (Serial Monitor shows command details)

**Features:**
- [ ] Manual pump control works
- [ ] Manual light control works
- [ ] Settings save and send to ESP32
- [ ] Auto watering triggers correctly
- [ ] Auto lighting triggers correctly

---

## 🔧 Alternative Brokers (If test.mosquitto.org down)

```dart
// Flutter: lib/services/mqtt_service.dart
// ESP32: teralux_esp32.ino

// Option 1: HiveMQ Public
broker: 'broker.hivemq.com'

// Option 2: Eclipse IoT
broker: 'mqtt.eclipseprojects.io'

// Option 3: Local (Requires Mosquitto installed)
broker: '192.168.1.100' // Your PC IP
```

---

**Status:** ✅ Ready for testing!
**Last Updated:** December 4, 2025
