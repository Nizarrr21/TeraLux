# 🚀 Quick Start Guide - TeraLux MQTT Setup

## ⚡ Fastest Way to Test (5 Minutes)

### Step 1: Configure Public Broker (Already Done!)
File `lib/services/mqtt_service.dart` sudah dikonfigurasi dengan public broker:
```dart
static const String broker = 'broker.hivemq.com';
```
✅ No setup needed!

### Step 2: Upload ESP32 Program
1. Open `arduino/teralux_esp32.ino` di Arduino IDE
2. Edit WiFi credentials (line 30-31):
   ```cpp
   const char* ssid = "YOUR_WIFI_NAME";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```
3. Verify broker is public (line 32):
   ```cpp
   const char* mqtt_server = "broker.hivemq.com";
   ```
4. Upload to ESP32 (Ctrl+U)
5. Open Serial Monitor (Ctrl+Shift+M, 115200 baud)

**Expected Output:**
```
Connecting to WiFi...
WiFi connected! IP: 192.168.1.101
Connecting to MQTT broker...
Connected to MQTT broker!
Publishing sensor data...
```

### Step 3: Run Flutter App
```bash
cd teralux
flutter run
```

**Expected Console Output:**
```
MQTT Service: Connecting to broker.hivemq.com:1883...
MQTT Service: Connected successfully!
MQTT Service: Subscribed to all topics
```

### Step 4: Test It!
1. Login ke app
2. Dashboard akan menampilkan data sensor real-time ✅
3. Test pump control: Pump Control page → Tap "Nyalakan Pompa" ✅
4. Test light control: Light Control page → Toggle switch ✅
5. Test auto control: Settings → Enable auto watering → Set threshold 50% → Save ✅

## 🎯 Expected Behavior

### On Dashboard:
- **Light Card**: Menampilkan nilai Lux dari BH1750 (update setiap 3 detik)
- **Soil Moisture Card**: Menampilkan % kelembaban tanah (update setiap 3 detik)

### On Pump Control Page:
- Tap "Nyalakan Pompa" → ESP32 relay GPIO 26 ON → Pompa menyala
- Set duration (detik) → Pompa mati otomatis setelah duration
- Check ESP32 Serial Monitor: "Pump: ON, Duration: 30s"

### On Light Control Page:
- Toggle switch ON → ESP32 relay GPIO 27 ON → Lampu menyala
- Toggle switch OFF → Lampu mati
- Check ESP32 Serial Monitor: "Light: ON"

### On Settings Page:
- Change "Kelembaban Tanah Minimum" → Save
- ESP32 Serial Monitor: "Received threshold settings: soilMin=30, lightMin=1000"
- Auto control akan trigger sesuai threshold baru

### Auto Watering:
```
Moisture drops below 30% 
  → App detects (check Auto Control)
  → Console: "Auto watering triggered! Moisture: 25.0% < 30%"
  → Pump activates for configured duration
  → 5 minute cooldown starts
```

### Auto Lighting:
```
Light drops below 1000 Lux
  → App detects
  → Console: "Auto lighting ON! Light: 800 Lux < 1000 Lux"
  → Light turns ON
  → Light turns OFF automatically when Lux >= 1000
```

## 🐛 Quick Troubleshooting

### Problem: Dashboard tidak menerima data
```bash
# Check ESP32 Serial Monitor
# Should see: "Publishing sensor data..."

# If not publishing:
# 1. Check WiFi connection
# 2. Check MQTT broker connection
# 3. Reset ESP32 (press EN button)
```

### Problem: Pump/Light control tidak bekerja
```bash
# Check ESP32 Serial Monitor
# Should see: "Received pump control: ON"

# If not receiving:
# 1. Pastikan ESP32 dan Flutter connect ke broker yang sama
# 2. Check topic name (case-sensitive!)
# 3. Test dengan MQTT client:
mosquitto_pub -h broker.hivemq.com -t "teralux/pump/control" -m '{"isPumpOn":true,"duration":5}'
```

### Problem: "Connection refused"
```
✅ Solution: Public broker mungkin down, coba lagi atau switch ke local broker
```

## 📊 Monitor MQTT Traffic (Optional)

### Using MQTT Explorer (Recommended):
1. Download: http://mqtt-explorer.com/
2. Connect to `broker.hivemq.com:1883`
3. See all `teralux/*` topics in real-time

### Using Mosquitto CLI:
```bash
# Subscribe to all teralux topics
mosquitto_sub -h broker.hivemq.com -t "teralux/#" -v

# You should see:
# teralux/sensors {"lightLevel":1234.5,"moistureLevel":45.6,...}
# teralux/pump/status {"isPumpOn":false,...}
# teralux/light/status {"isLightOn":false}
```

## 🔧 Next: Setup Local Broker (Production)

Public broker OK untuk testing, tapi untuk produksi gunakan local broker:

### Windows:
```powershell
# Install Mosquitto
# Download from: https://mosquitto.org/download/

# Start service
net start mosquitto

# Get your IP
ipconfig
# Example: 192.168.1.100
```

### Update Both ESP32 and Flutter:
```cpp
// arduino/teralux_esp32.ino (line 32)
const char* mqtt_server = "192.168.1.100";
```

```dart
// lib/services/mqtt_service.dart (line 21)
static const String broker = '192.168.1.100';
```

### Recompile and Upload:
1. Upload ESP32 program lagi
2. Stop Flutter app (Ctrl+C)
3. Run `flutter run` lagi

Done! 🎉

## 📚 Full Documentation

Untuk penjelasan lengkap, baca:
- **MQTT_FLUTTER_SETUP.md** - Complete setup guide dengan troubleshooting
- **MQTT_CHANGES_SUMMARY.md** - Technical summary apa yang diubah
- **arduino/MQTT_SETUP.md** - Arduino-specific MQTT guide
- **arduino/SENSORS_GUIDE.md** - Sensor specifications dan wiring

## ✅ Success Indicators

You know it's working when:
- ✅ Dashboard updates every 3 seconds dengan sensor data real
- ✅ Serial Monitor ESP32 shows "Publishing sensor data..." setiap 3 detik
- ✅ Pump control page dapat ON/OFF pompa
- ✅ Light control page dapat toggle lampu
- ✅ Settings page save threshold dan ESP32 terima settings
- ✅ Auto watering trigger saat moisture < threshold
- ✅ Auto lighting trigger saat light < threshold

## 🎯 What's Next?

1. ✅ Basic MQTT working - DONE
2. ⏳ Fine-tune sensor calibration (Calibration page)
3. ⏳ Test auto control dengan real plants
4. ⏳ Setup local Mosquitto untuk production
5. ⏳ Add data logging/history
6. ⏳ Add notifications

---

**Happy Testing!** 🌱💡💧

Need help? Check:
- Serial Monitor ESP32 untuk debug ESP32 side
- Flutter console untuk debug app side
- MQTT Explorer untuk monitor traffic
