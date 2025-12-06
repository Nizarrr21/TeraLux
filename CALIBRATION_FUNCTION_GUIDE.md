# Panduan Kalibrasi Sensor - ESP32 & Flutter

## 📋 Ringkasan
Sistem kalibrasi sensor kelembaban tanah telah diperbaharui dengan topic MQTT terpisah untuk memudahkan update kalibrasi tanpa mengubah threshold settings.

## 🎯 Fitur Baru

### 1. **Topic MQTT Kalibrasi Terpisah**
- **Topic**: `teralux_project/settings/calibration`
- **Format JSON**:
```json
{
  "soilDryValue": 4095,
  "soilWetValue": 1500
}
```

### 2. **Validasi di ESP32**
ESP32 akan melakukan validasi otomatis:
- ✅ Dry value harus > Wet value
- ✅ Dry value ≤ 4095 (max ADC ESP32)
- ✅ Wet value ≥ 0 (min ADC ESP32)
- ❌ Jika tidak valid: Error message di Serial Monitor

### 3. **Test Calculation Otomatis**
Setelah kalibrasi diterima, ESP32 akan:
- Membaca nilai sensor saat ini
- Menghitung moisture % dengan kalibrasi baru
- Menampilkan hasil di Serial Monitor untuk verifikasi

## 🔧 Cara Kerja

### **Di Flutter App (calibration_page.dart):**

1. User input nilai DRY dan WET di UI
2. Tekan tombol "Terapkan Kalibrasi"
3. `_applyCalibration()` dipanggil:
   ```dart
   void _applyCalibration() {
     final dryValue = double.tryParse(_soilDryController.text);
     final wetValue = double.tryParse(_soilWetController.text);
     
     if (dryValue != null && wetValue != null) {
       if (dryValue <= wetValue) {
         // Show error
         return;
       }
       
       final calibrationData = CalibrationData(
         soilDryValue: dryValue,
         soilWetValue: wetValue,
       );
       
       widget.mqttService.updateCalibration(calibrationData);
     }
   }
   ```

### **Di MQTT Service (mqtt_service.dart):**

4. `updateCalibration()` dipanggil:
   ```dart
   void updateCalibration(CalibrationData newCalibration) {
     calibration = newCalibration;
     print('MQTT Service: Calibration updated');
     
     // Publish kalibrasi ke ESP32 via MQTT
     publishCalibration();
   }
   ```

5. `publishCalibration()` mengirim data ke ESP32:
   ```dart
   void publishCalibration() {
     final calibrationData = {
       'soilDryValue': calibration.soilDryValue,
       'soilWetValue': calibration.soilWetValue,
     };
     
     final builder = MqttClientPayloadBuilder();
     builder.addString(jsonEncode(calibrationData));
     
     client!.publishMessage(
       topicCalibration,
       MqttQos.atLeastOnce,
       builder.payload!,
     );
   }
   ```

### **Di ESP32 (teralux_esp32.ino):**

6. ESP32 menerima message di `callback()`:
   ```cpp
   if (strcmp(topic, topic_calibration) == 0) {
     int newDryValue = doc["soilDryValue"].as<int>();
     int newWetValue = doc["soilWetValue"].as<int>();
     
     // Validasi
     if (newDryValue > newWetValue && newDryValue <= 4095 && newWetValue >= 0) {
       soilDryValue = newDryValue;
       soilWetValue = newWetValue;
       
       // Print confirmation
       Serial.println("🔧 CALIBRATION UPDATED!");
       Serial.print("   📊 Soil Dry Value (0%): ");
       Serial.println(soilDryValue);
       Serial.print("   📊 Soil Wet Value (100%): ");
       Serial.println(soilWetValue);
       
       // Test calculation
       rawMoistureValue = analogRead(SOIL_PIN);
       float testMoisture = map(rawMoistureValue, soilWetValue, soilDryValue, 100, 0);
       testMoisture = constrain(testMoisture, 0, 100);
       Serial.print("   🧪 Test calculation - Raw: ");
       Serial.print(rawMoistureValue);
       Serial.print(" → Moisture: ");
       Serial.print(testMoisture);
       Serial.println("%");
     }
   }
   ```

7. Sensor reading di `readSensors()` menggunakan nilai kalibrasi:
   ```cpp
   rawMoistureValue = analogRead(SOIL_PIN);
   float moisturePercent = map(rawMoistureValue, soilWetValue, soilDryValue, 100, 0);
   moisturePercent = constrain(moisturePercent, 0, 100);
   ```

## 📱 Langkah-langkah Kalibrasi

### **Persiapan:**
1. Pastikan ESP32 dan Flutter app terhubung ke MQTT broker
2. Buka Serial Monitor di Arduino IDE (115200 baud)
3. Buka halaman Calibration di Flutter app

### **Kalibrasi DRY (0% Moisture):**
1. Angkat sensor dari tanah (sensor di udara)
2. Tunggu 5-10 detik
3. Lihat nilai `rawMoistureValue` di dashboard Flutter atau Serial Monitor ESP32
4. Catat nilai tersebut (contoh: 4095)
5. Masukkan ke field "Nilai Sensor DRY"

### **Kalibrasi WET (100% Moisture):**
1. Celupkan sensor ke dalam air
2. Tunggu 5-10 detik sampai stabil
3. Lihat nilai `rawMoistureValue` di dashboard Flutter atau Serial Monitor ESP32
4. Catat nilai tersebut (contoh: 1500)
5. Masukkan ke field "Nilai Sensor WET"

### **Terapkan Kalibrasi:**
1. Tekan tombol "Terapkan Kalibrasi"
2. Flutter akan validasi: Dry > Wet?
3. Jika valid: Data dikirim ke ESP32 via MQTT
4. ESP32 menerima & validasi lagi
5. Serial Monitor menampilkan konfirmasi + test calculation

## 🔍 Monitoring & Debugging

### **Serial Monitor Output (ESP32):**

**Saat Kalibrasi Berhasil:**
```
[MQTT] teralux_project/settings/calibration: {"soilDryValue":4095,"soilWetValue":1500}

🔧 CALIBRATION UPDATED!
   📊 Soil Dry Value (0%): 4095
   📊 Soil Wet Value (100%): 1500
   ✓ Range: 1500 - 4095 (span: 2595)
   🧪 Test calculation - Raw: 2800 → Moisture: 49%
```

**Saat Kalibrasi Gagal (Invalid):**
```
[MQTT] teralux_project/settings/calibration: {"soilDryValue":1000,"soilWetValue":2000}

⚠️  CALIBRATION INVALID!
   Dry: 1000, Wet: 2000
   Requirements: Dry > Wet, Dry ≤ 4095, Wet ≥ 0
```

### **Flutter Console Output:**

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

## 🧮 Formula Kalibrasi

### **Mapping Linear:**
```cpp
moisturePercent = map(rawADC, wetValue, dryValue, 100, 0);
```

### **Penjelasan:**
- `rawADC`: Nilai ADC sensor saat ini (0-4095)
- `wetValue`: Nilai ADC saat sensor di air = 100% moisture
- `dryValue`: Nilai ADC saat sensor di udara = 0% moisture
- Output: Moisture percentage (0-100%)

### **Contoh Perhitungan:**
```
Kalibrasi:
- Dry Value (0%): 4095
- Wet Value (100%): 1500

Sensor membaca ADC: 2800
Moisture = map(2800, 1500, 4095, 100, 0)
         = (2800 - 1500) / (4095 - 1500) * (0 - 100) + 100
         = 1300 / 2595 * (-100) + 100
         = 0.501 * (-100) + 100
         = -50.1 + 100
         = 49.9%
         ≈ 50%
```

## 📊 Nilai Referensi

### **Capacitive Soil Moisture Sensor (Typical Values):**
| Kondisi | ADC Value (12-bit) | Moisture % |
|---------|-------------------|------------|
| Di udara (Dry) | 4000-4095 | 0% |
| Tanah kering | 3000-3500 | 20-40% |
| Tanah lembab | 2000-3000 | 40-60% |
| Tanah basah | 1500-2000 | 60-80% |
| Di air (Wet) | 1200-1600 | 100% |

### **Catatan:**
- Nilai bisa berbeda tergantung sensor & kualitas
- Kalibrasi ulang jika ganti sensor
- Kalibrasi ulang setiap 3-6 bulan untuk akurasi optimal

## ⚙️ File yang Diubah

### **1. ESP32 (arduino/teralux_esp32.ino):**
- ✅ Tambah topic: `topic_calibration`
- ✅ Subscribe topic kalibrasi
- ✅ Handler kalibrasi di `callback()`
- ✅ Validasi dry > wet, range 0-4095
- ✅ Test calculation otomatis

### **2. Flutter (lib/services/mqtt_service.dart):**
- ✅ Tambah topic: `topicCalibration`
- ✅ Fungsi `publishCalibration()`
- ✅ Update `updateCalibration()` untuk auto-publish
- ✅ Logging detail untuk debugging

### **3. Flutter (lib/pages/calibration_page.dart):**
- ✅ Sudah simpel (2 input fields: dry/wet)
- ✅ Validasi dry > wet
- ✅ Call `updateCalibration()` saat apply

## 🐛 Troubleshooting

### **Problem 1: Kalibrasi tidak diterima ESP32**
**Gejala:** Flutter publish berhasil, tapi ESP32 tidak ada log
**Solusi:**
1. Cek topic sama persis: `teralux_project/settings/calibration`
2. Cek ESP32 subscribe topic kalibrasi
3. Cek MQTT broker connection di ESP32 & Flutter
4. Test dengan MQTT Test Page di Flutter

### **Problem 2: Nilai moisture tidak berubah**
**Gejala:** Kalibrasi diterima, tapi % moisture masih salah
**Solusi:**
1. Tunggu 10 detik (sensor read interval)
2. Cek Serial Monitor: apakah test calculation benar?
3. Cek dry > wet
4. Restart ESP32 jika perlu

### **Problem 3: Nilai ADC tidak stabil**
**Gejala:** Raw ADC berubah-ubah drastis
**Solusi:**
1. Cek koneksi sensor (kabel longgar?)
2. Tunggu sensor stabil 10-15 detik
3. Gunakan rata-rata beberapa pembacaan
4. Hindari sentuh sensor saat baca nilai

## 📝 Best Practices

1. **Kalibrasi di kondisi ekstrem:**
   - DRY: Sensor benar-benar di udara (tidak sentuh apapun)
   - WET: Sensor benar-benar di air (celupkan sampai garis batas)

2. **Tunggu stabilisasi:**
   - Minimal 10 detik setelah ganti kondisi
   - Baca nilai 3-5 kali, ambil yang paling stabil

3. **Dokumentasi:**
   - Catat nilai kalibrasi
   - Catat tanggal kalibrasi
   - Foto sensor saat kalibrasi (untuk referensi)

4. **Maintenance:**
   - Bersihkan sensor sebelum kalibrasi
   - Lap kering setelah celup ke air
   - Re-kalibrasi setiap 3-6 bulan

## ✅ Testing Checklist

- [ ] ESP32 compile sukses
- [ ] Flutter compile sukses
- [ ] MQTT connection OK
- [ ] Subscribe topic kalibrasi OK
- [ ] Input dry value di Flutter
- [ ] Input wet value di Flutter
- [ ] Tekan "Terapkan Kalibrasi"
- [ ] Flutter log publish OK
- [ ] ESP32 Serial Monitor log received OK
- [ ] Test calculation tampil di Serial Monitor
- [ ] Moisture % di dashboard update sesuai kalibrasi baru
- [ ] LCD di ESP32 tampil % yang benar

## 🎉 Status
✅ **COMPLETE** - Fitur kalibrasi sensor siap digunakan!

