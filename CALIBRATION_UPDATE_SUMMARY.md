# Summary: Fungsi Kalibrasi Sensor

## ✅ Yang Ditambahkan

### 🔧 ESP32 (arduino/teralux_esp32.ino):

1. **Topic MQTT baru untuk kalibrasi:**
   ```cpp
   const char* topic_calibration = "teralux_project/settings/calibration";
   ```

2. **Subscribe ke topic kalibrasi:**
   ```cpp
   client.subscribe(topic_calibration);
   ```

3. **Handler kalibrasi di callback():**
   - Terima data `soilDryValue` & `soilWetValue` dari Flutter
   - Validasi: dry > wet, dry ≤ 4095, wet ≥ 0
   - Update global variables
   - Log konfirmasi + test calculation
   - Error message jika invalid

### 📱 Flutter (lib/services/mqtt_service.dart):

1. **Topic MQTT baru:**
   ```dart
   static const String topicCalibration = 'teralux_project/settings/calibration';
   ```

2. **Fungsi publish kalibrasi:**
   ```dart
   void publishCalibration() {
     // Build JSON dengan soilDryValue & soilWetValue
     // Publish ke topic_calibration
     // Log detail untuk debugging
   }
   ```

3. **Update fungsi updateCalibration():**
   - Simpan data kalibrasi
   - Otomatis panggil `publishCalibration()`

## 🎯 Cara Kerja

### Flow Kalibrasi:
```
1. User input nilai di Calibration Page
   ↓
2. Tekan "Terapkan Kalibrasi"
   ↓
3. CalibrationPage.dart → mqttService.updateCalibration()
   ↓
4. mqttService.dart → publishCalibration()
   ↓
5. MQTT publish ke topic: teralux_project/settings/calibration
   ↓
6. ESP32 terima di callback()
   ↓
7. Validasi & update soilDryValue, soilWetValue
   ↓
8. Test calculation & log konfirmasi
   ↓
9. Sensor reading menggunakan kalibrasi baru
```

## 📊 Data Format

### MQTT Payload:
```json
{
  "soilDryValue": 4095,
  "soilWetValue": 1500
}
```

## 🔍 Debugging

### ESP32 Serial Monitor:
```
🔧 CALIBRATION UPDATED!
   📊 Soil Dry Value (0%): 4095
   📊 Soil Wet Value (100%): 1500
   ✓ Range: 1500 - 4095 (span: 2595)
   🧪 Test calculation - Raw: 2800 → Moisture: 49%
```

### Flutter Console:
```
========================================
📤 MQTT Service: Publishing Calibration
========================================
Calibration Data:
  - Soil Dry Value (0%): 4095.0
  - Soil Wet Value (100%): 1500.0
  - Range: 1500.0 - 4095.0
  - Span: 2595.0
Publishing to topic: teralux_project/settings/calibration
   ✓ Published successfully
========================================
```

## 📋 Quick Test Steps

1. ✅ Upload code ESP32 baru
2. ✅ Restart Flutter app
3. ✅ Buka Serial Monitor (115200 baud)
4. ✅ Buka Calibration Page di app
5. ✅ Input: Dry = 4095, Wet = 1500
6. ✅ Tekan "Terapkan Kalibrasi"
7. ✅ Cek Serial Monitor → ada log "CALIBRATION UPDATED"
8. ✅ Cek Flutter console → ada log "Published successfully"
9. ✅ Cek Dashboard → moisture % sesuai kalibrasi baru

## 📁 Files Modified

1. `arduino/teralux_esp32.ino`
2. `lib/services/mqtt_service.dart`
3. `CALIBRATION_FUNCTION_GUIDE.md` (panduan lengkap)

## ✨ Keuntungan

1. **Terpisah dari Threshold Settings**
   - Kalibrasi dan threshold tidak saling menimpa
   - Bisa update kalibrasi tanpa ubah threshold
   - Bisa update threshold tanpa ubah kalibrasi

2. **Validasi di ESP32**
   - Cegah kalibrasi invalid
   - Error message jelas
   - Test calculation otomatis

3. **Logging Lengkap**
   - Easy debugging
   - Track perubahan kalibrasi
   - Konfirmasi visual

## 🚀 Status
✅ **READY TO TEST** - Semua fitur sudah diimplementasikan!

