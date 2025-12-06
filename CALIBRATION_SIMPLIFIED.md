# Kalibrasi Sensor - Perubahan Sistem

## Ringkasan Perubahan
Sistem kalibrasi telah disederhanakan dari sistem multi-point yang kompleks menjadi input langsung nilai sensor (dry/wet).

## Sebelum vs Sesudah

### SEBELUM:
- **Sensor Cahaya**: Multi-point calibration (min 2 titik)
  - Input: Nilai ADC sensor + Nilai Lux Meter aktual
  - Proses: Linear regression untuk mapping
- **Sensor Kelembaban**: Multi-point calibration (min 2 titik)
  - Input: Nilai ADC sensor + Nilai Soil Meter aktual (%)
  - Proses: Linear regression untuk mapping
- **UI**: Add/Remove chip untuk kelola banyak titik kalibrasi
- **Controllers**: 4 text controllers + 2 list kalibration points

### SESUDAH:
- **Sensor Cahaya (BH1750)**: TIDAK PERLU KALIBRASI
  - Info: Sensor digital pre-calibrated dari pabrik
  - Output: Langsung dalam satuan Lux yang akurat
  - UI: Card informasi saja
  
- **Sensor Kelembaban**: Kalibrasi 2 nilai (Dry/Wet)
  - Input DRY: Nilai ADC saat sensor di udara (default: 4095)
  - Input WET: Nilai ADC saat sensor di air (default: 1500)
  - Proses: Mapping linear otomatis (dry=0%, wet=100%)
  - UI: 2 text fields sederhana
- **Controllers**: 2 text controllers saja (_soilDryController, _soilWetController)

## Detail Perubahan Code

### 1. State Variables (Lines ~100-115)
**DIHAPUS:**
```dart
final TextEditingController _lightSensorController;
final TextEditingController _lightActualController;
final TextEditingController _moistureSensorController;
final TextEditingController _moistureActualController;
List<CalibrationPoint> _lightPoints = [];
List<CalibrationPoint> _moisturePoints = [];
```

**DITAMBAH:**
```dart
final TextEditingController _soilDryController = TextEditingController(text: '4095');
final TextEditingController _soilWetController = TextEditingController(text: '1500');
```

### 2. Calibration Logic (Lines ~120-170)
**DIHAPUS:**
```dart
void _addLightCalibrationPoint() { ... }
void _addMoistureCalibrationPoint() { ... }
// Complex linear regression logic
```

**DITAMBAH:**
```dart
void _applyCalibration() {
  final dryValue = double.tryParse(_soilDryController.text);
  final wetValue = double.tryParse(_soilWetController.text);
  
  if (dryValue != null && wetValue != null) {
    if (dryValue <= wetValue) {
      // Show error: Dry must be > Wet
      return;
    }
    
    final calibrationData = CalibrationData(
      soilDryValue: dryValue,
      soilWetValue: wetValue,
    );
    
    widget.mqttService.updateCalibration(calibrationData);
    // Show success message
  }
}
```

### 3. UI - Light Sensor Section (Lines ~175-210)
**SEBELUM:** Input fields untuk sensor cahaya + actual lux + add button + chips

**SESUDAH:** Info card:
```dart
Container(
  // Green background with info icon
  child: Column(
    children: [
      "Sensor Cahaya BH1750",
      "Sensor digital pre-calibrated, tidak perlu kalibrasi manual",
      "Hasil sudah dalam satuan Lux yang akurat"
    ]
  )
)
```

### 4. UI - Moisture Sensor Section (Lines ~215-275)
**SEBELUM:** 
- 2 input fields (ADC sensor + Soil Meter %)
- Add button
- Chip list untuk multiple points

**SESUDAH:**
```dart
Column(
  children: [
    "Nilai Sensor DRY (di udara):",
    TextField(_soilDryController, hintText: '4095'),
    
    "Nilai Sensor WET (di dalam air):",
    TextField(_soilWetController, hintText: '1500'),
  ]
)
```

### 5. Panduan Kalibrasi (Lines ~240-250)
**SEBELUM:**
```
1. Minimal 2 titik pengukuran untuk setiap sensor
2. Gunakan kondisi yang berbeda (terang-gelap, basah-kering)
3. Sensor Cahaya: Ukur di tempat gelap dan terang dengan Lux Meter
4. Kelembaban Tanah: Ukur di udara (kering) dan dalam air (basah)
5. Lebih banyak titik = kalibrasi lebih akurat
```

**SESUDAH:**
```
1. Sensor Cahaya BH1750 sudah dikalibrasi dari pabrik
2. Sensor Kelembaban Tanah perlu kalibrasi 2 nilai:
   • DRY: Angkat sensor di udara, catat nilai ADC
   • WET: Celupkan sensor di air, catat nilai ADC
3. Nilai DRY harus lebih besar dari nilai WET
4. Setelah input, tekan "Terapkan Kalibrasi"
```

### 6. Dispose Method (Lines ~288-293)
**SEBELUM:**
```dart
_lightSensorController.dispose();
_lightActualController.dispose();
_moistureSensorController.dispose();
_moistureActualController.dispose();
```

**SESUDAH:**
```dart
_soilDryController.dispose();
_soilWetController.dispose();
```

## Cara Menggunakan Kalibrasi Baru

### Langkah-langkah:
1. **Buka halaman Calibration di aplikasi**
2. **Sensor Cahaya**: Tidak perlu action (sudah pre-calibrated)
3. **Sensor Kelembaban**:
   - Lihat nilai ADC di dashboard saat sensor di udara
   - Masukkan nilai tersebut ke field "Nilai Sensor DRY"
   - Celupkan sensor ke dalam air
   - Lihat nilai ADC di dashboard saat sensor di air
   - Masukkan nilai tersebut ke field "Nilai Sensor WET"
4. **Tekan tombol "Terapkan Kalibrasi"**
5. **Data kalibrasi dikirim ke ESP32 via MQTT**

### Contoh Nilai:
- **DRY**: 4095 (ADC maksimal saat di udara = 0% moisture)
- **WET**: 1500 (ADC rendah saat di air = 100% moisture)

### Validasi:
- Sistem akan check: DRY value > WET value
- Jika tidak valid: Error message ditampilkan
- Jika valid: Success message + data dikirim ke ESP32

## Keuntungan Sistem Baru

### 1. **Lebih Sederhana**
   - User tidak perlu Lux Meter eksternal
   - User tidak perlu Soil Moisture Meter eksternal
   - Cukup lihat nilai di dashboard & input langsung

### 2. **Lebih Akurat**
   - BH1750 memang sudah akurat dari pabrik
   - Soil sensor: mapping linear dry-wet sesuai karakteristik sensor asli

### 3. **Lebih Cepat**
   - Tidak perlu input banyak titik
   - Hanya 2 nilai untuk soil sensor
   - Proses kalibrasi < 2 menit

### 4. **Lebih Intuitif**
   - UI lebih clean & straightforward
   - Panduan lebih jelas & step-by-step
   - Tidak ada konsep "points" yang membingungkan

## File yang Diubah
1. **lib/pages/calibration_page.dart**
   - State variables: 4 controllers → 2 controllers
   - Methods: 3 methods → 1 method (_applyCalibration)
   - UI: Complex multi-point → Simple dry/wet input
   - Guide: Updated instructions

## Catatan Teknis

### BH1750 (Light Sensor)
- **Type**: Digital I2C sensor
- **Output**: Langsung dalam Lux (0-65535)
- **Factory calibrated**: Ya
- **Need calibration**: Tidak
- **Accuracy**: ±20% typ. (sudah cukup untuk greenhouse)

### Capacitive Soil Moisture Sensor
- **Type**: Analog ADC sensor
- **Output**: Raw ADC value (0-4095 untuk ESP32 12-bit ADC)
- **Factory calibrated**: Tidak
- **Need calibration**: Ya (dry/wet points)
- **Calculation**: `moisture% = map(adc, dryValue, wetValue, 0, 100)`

### ESP32 Handling
- Menerima MQTT payload: `{"soilDryValue": 4095, "soilWetValue": 1500}`
- Update global variables: `soilDryValue`, `soilWetValue`
- Recalculate moisture: `currentMoisture = map(adcValue, soilDryValue, soilWetValue, 0, 100)`
- Persist di EEPROM (future enhancement)

## Testing Checklist
- [ ] Compile sukses (no errors)
- [ ] UI tampil dengan benar
- [ ] Input dry value → tersimpan
- [ ] Input wet value → tersimpan
- [ ] Validasi: dry > wet → error message
- [ ] Valid input → success message
- [ ] MQTT publish calibration data
- [ ] ESP32 menerima & apply calibration
- [ ] Moisture calculation updated
- [ ] Dashboard menampilkan % yang benar

## Status
✅ **COMPLETE** - All compilation errors fixed, ready for testing

