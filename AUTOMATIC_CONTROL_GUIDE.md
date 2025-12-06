# TeraLux - Automatic Control System

## 🤖 Fitur Kontrol Otomatis

TeraLux kini dilengkapi dengan sistem kontrol otomatis yang dapat menyalakan pompa dan lampu secara otomatis berdasarkan kondisi sensor.

### ✨ Fitur Baru

1. **Penyiraman Otomatis (Auto Watering)**
   - Pompa akan menyala otomatis jika kelembaban tanah di bawah threshold
   - Durasi penyiraman dapat diatur
   - Cooldown 5 menit antara penyiraman otomatis
   - Dapat diaktifkan/nonaktifkan

2. **Pencahayaan Otomatis (Auto Lighting)**
   - Lampu akan menyala otomatis jika cahaya di bawah threshold
   - Lampu akan mati otomatis jika cahaya sudah cukup
   - Dapat diaktifkan/nonaktifkan

3. **Halaman Pengaturan**
   - Atur threshold kelembaban tanah minimum (%)
   - Atur threshold cahaya minimum (Lux)
   - Atur durasi penyiraman otomatis
   - Toggle on/off untuk setiap fitur otomatis

## 📱 Cara Menggunakan

### 1. Akses Halaman Pengaturan

Di Dashboard, klik icon **Settings** (⚙️) di pojok kanan atas.

### 2. Konfigurasi Penyiraman Otomatis

**a. Aktifkan Fitur:**
- Toggle **"Aktifkan Penyiraman Otomatis"** ke ON

**b. Atur Threshold Kelembaban:**
- Default: 30%
- Pompa akan menyala jika kelembaban < nilai ini
- Contoh: Jika set 30%, pompa menyala saat tanah < 30%

**c. Atur Durasi Penyiraman:**
- Default: 30 detik
- Lama pompa menyala saat trigger otomatis
- Sesuaikan dengan kebutuhan tanaman Anda

### 3. Konfigurasi Pencahayaan Otomatis

**a. Aktifkan Fitur:**
- Toggle **"Aktifkan Pencahayaan Otomatis"** ke ON

**b. Atur Threshold Cahaya:**
- Default: 1000 Lux
- Lampu akan menyala jika cahaya < nilai ini
- Contoh: Jika set 1000 Lux, lampu menyala saat < 1000 Lux

### 4. Simpan Pengaturan

Klik tombol **"SIMPAN PENGATURAN"** di bawah.

## 🔧 Cara Kerja Sistem Otomatis

### Algoritma Penyiraman Otomatis

```
SETIAP 10 DETIK:
  Baca sensor kelembaban tanah
  Terapkan kalibrasi untuk mendapat nilai %
  
  JIKA auto_watering_enabled = TRUE:
    JIKA kelembaban < threshold:
      JIKA cooldown sudah lewat (5 menit):
        JIKA pompa tidak sedang jalan:
          → Nyalakan pompa
          → Set timer sesuai durasi
          → Catat waktu watering
```

### Algoritma Pencahayaan Otomatis

```
SETIAP 10 DETIK:
  Baca sensor cahaya
  Terapkan kalibrasi untuk mendapat nilai Lux
  
  JIKA auto_lighting_enabled = TRUE:
    JIKA cahaya < threshold:
      JIKA lampu OFF:
        → Nyalakan lampu
    JIKA TIDAK (cahaya >= threshold):
      JIKA lampu ON:
        → Matikan lampu
```

## 📊 Rekomendasi Threshold

### Kelembaban Tanah

| Jenis Tanaman | Kelembaban Min | Durasi Siram |
|---------------|----------------|--------------|
| Sayuran Daun (Selada, Sawi) | 40-50% | 20-30 detik |
| Tomat, Cabai | 30-40% | 30-45 detik |
| Herbs (Basil, Mint) | 35-45% | 25-35 detik |
| Strawberry | 40-50% | 30-40 detik |
| Tanaman Hias | 25-35% | 20-30 detik |

### Cahaya (Lux)

| Kondisi | Lux | Rekomendasi |
|---------|-----|-------------|
| Siang Hari Terang | > 10,000 | Lampu OFF |
| Mendung | 1,000 - 10,000 | Tergantung tanaman |
| Pagi/Sore | 500 - 5,000 | Lampu ON jika < 1000 |
| Malam | < 500 | Lampu ON |

**Threshold yang Disarankan:**
- **Sayuran:** 5,000 - 10,000 Lux (set threshold 5000)
- **Herbs:** 3,000 - 8,000 Lux (set threshold 3000)
- **Tanaman Hias:** 1,000 - 5,000 Lux (set threshold 1000)

## ⚠️ Catatan Penting

### Kalibrasi Sensor Harus Dilakukan Dulu

**SANGAT PENTING:** Sebelum menggunakan kontrol otomatis, pastikan sensor sudah dikalibrasi dengan benar!

**Cara Kalibrasi:**
1. Pergi ke **Calibration Page** (icon tune di dashboard)
2. Kalibrasi **Lux Meter** dengan Lux Meter standar
3. Kalibrasi **Soil Moisture Meter** dengan kondisi kering & basah
4. Simpan kalibrasi

**Mengapa Kalibrasi Penting?**
- Sensor ADC menghasilkan nilai mentah (0-4095)
- Nilai mentah perlu dikonversi ke satuan nyata (Lux, %)
- Tanpa kalibrasi, threshold tidak akan akurat
- Bisa menyebabkan over/under watering

### Cooldown Penyiraman

- **Cooldown:** 5 menit antara penyiraman otomatis
- **Alasan:** Mencegah over-watering
- **Catatan:** Sensor kelembaban butuh waktu untuk bereaksi setelah disiram

### Priority Kontrol Manual vs Otomatis

- **Manual SELALU prioritas utama**
- Jika Anda menyalakan pompa manual, otomatis akan menunggu
- Cooldown tetap berlaku setelah kontrol manual

## 🖥️ Monitoring & Debugging

### Arduino Serial Monitor

Saat fitur otomatis berjalan, Anda akan melihat log seperti ini:

```
========================================
AUTO WATERING TRIGGERED!
Soil moisture: 25.5% < 30.0%
========================================
Pump started for 30 seconds
```

```
========================================
AUTO LIGHTING ON!
Light level: 850 Lux < 1000 Lux
========================================
Light turned ON
```

### Flutter Console

Di console Flutter, akan ada log:

```
MQTT Service: Auto watering triggered! Moisture: 25.5% < 30.0%
MQTT Service: Auto lighting ON! Light: 850 Lux < 1000 Lux
```

## 🔄 Update dari Versi Sebelumnya

### Perubahan di Arduino (ESP32)

**File:** `teralux_esp32.ino`

**Fitur Baru:**
- ✅ Subscribe ke topic `teralux/settings/threshold`
- ✅ Variabel threshold settings
- ✅ Fungsi `checkAutoControl()` untuk logika otomatis
- ✅ Kalibrasi terintegrasi di Arduino
- ✅ Cooldown timer untuk watering
- ✅ Auto lighting on/off otomatis

**Cara Update:**
1. Backup file lama
2. Upload program baru ke ESP32
3. Reset ESP32
4. Test manual control dulu
5. Kemudian test auto control

### Perubahan di Flutter App

**File Baru:**
- `lib/models/threshold_settings.dart` - Model untuk settings
- `lib/pages/settings_page.dart` - Halaman pengaturan

**File Dimodifikasi:**
- `lib/services/mqtt_service.dart` - Tambah logika auto control
- `lib/pages/dashboard_page.dart` - Tambah tombol Settings

**Cara Update:**
1. Pull code terbaru dari Git
2. Run `flutter pub get`
3. Restart aplikasi
4. Konfigurasi threshold di Settings page

## 🧪 Testing

### Test Sequence Recommended

**1. Test Threshold Settings**
```
☑ Buka Settings page
☑ Ubah nilai threshold
☑ Simpan settings
☑ Cek Serial Monitor Arduino (harus ada log "Threshold settings updated")
```

**2. Test Auto Watering**
```
☑ Set threshold soil moisture = 50% (tinggi)
☑ Tunggu 10 detik
☑ Pompa harus menyala otomatis (jika soil < 50%)
☑ Tunggu sampai selesai
☑ Cek cooldown (pompa tidak boleh nyala lagi dalam 5 menit)
```

**3. Test Auto Lighting**
```
☑ Set threshold light = 5000 Lux (tinggi)
☑ Tunggu 10 detik
☑ Lampu harus menyala otomatis (jika light < 5000)
☑ Tutup sensor dengan tangan → lampu ON
☑ Buka sensor → lampu OFF
```

**4. Test Toggle On/Off**
```
☑ Disable auto watering → pompa tidak menyala otomatis
☑ Enable kembali → pompa menyala sesuai threshold
☑ Disable auto lighting → lampu tidak menyala otomatis
☑ Enable kembali → lampu menyala sesuai threshold
```

## 📞 Troubleshooting

### Pompa Tidak Menyala Otomatis

**Cek:**
1. ✅ Auto watering enabled?
2. ✅ Kelembaban < threshold?
3. ✅ Sudah lewat 5 menit sejak watering terakhir?
4. ✅ Pompa tidak sedang jalan manual?
5. ✅ Sensor sudah dikalibrasi?
6. ✅ MQTT connected?

**Debug:**
```
Serial Monitor → Cari "AUTO WATERING TRIGGERED"
Jika tidak ada → Cek sensor readings
Jika ada tapi pompa tidak nyala → Cek relay connection
```

### Lampu Tidak Menyala Otomatis

**Cek:**
1. ✅ Auto lighting enabled?
2. ✅ Cahaya < threshold?
3. ✅ Sensor cahaya bekerja?
4. ✅ Sensor sudah dikalibrasi?
5. ✅ MQTT connected?

**Debug:**
```
Serial Monitor → Cari "AUTO LIGHTING ON"
Jika tidak ada → Cek light sensor readings
Jika ada tapi lampu tidak nyala → Cek relay connection
```

### Settings Tidak Tersimpan

**Solusi:**
1. Cek koneksi MQTT
2. Restart aplikasi Flutter
3. Upload ulang Arduino code
4. Cek Serial Monitor untuk konfirmasi

## 🚀 Future Improvements

Fitur yang bisa ditambahkan di masa depan:

- [ ] Scheduling (timer penyiraman otomatis per jam)
- [ ] Multiple threshold profiles (siang/malam)
- [ ] Notifikasi push saat watering/lighting triggered
- [ ] Historical data & analytics
- [ ] Weather API integration
- [ ] Machine learning untuk optimal threshold

## 📄 Changelog

### Version 2.0 - Automatic Control System

**Added:**
- Automatic watering based on soil moisture threshold
- Automatic lighting based on light level threshold
- Settings page for threshold configuration
- Cooldown mechanism for auto watering
- Calibration integration in Arduino
- Real-time monitoring of auto control status

**Changed:**
- MQTT service now includes auto control logic
- ESP32 code includes threshold checking every 10 seconds
- Dashboard includes Settings button

**Fixed:**
- Light sensor calibration now properly applied in auto mode
- Pump control conflict between manual and auto resolved

---

**Happy Gardening with TeraLux! 🌱✨**
