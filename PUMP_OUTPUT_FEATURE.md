# Fitur Output Keluaran Pompa

## 📊 Data Step Response

Berdasarkan tabel karakteristik pompa:

| Detik | Volume (ml) | Tingkat Kelembaban |
|-------|-------------|-------------------|
| 0.25s | 1.67ml | 6% |
| 0.49s | 3.33ml | 12% |
| 0.74s | 5.00ml | 18% |
| 0.98s | 6.67ml | 24% |
| 1.23s | 8.33ml | 30% |
| 1.48s | 10.00ml | 36% |
| 1.72s | 11.67ml | 42% |
| 1.97s | 13.33ml | 48% |
| 2.21s | 15.00ml | 54% |
| 2.46s | 16.67ml | 60% |
| 2.71s | 18.33ml | 66% |
| 2.95s | 20.00ml | 72% |
| 3.20s | 21.67ml | 78% |
| 3.44s | 23.33ml | 84% |
| 3.69s | 25.00ml | 90% (Steady State) |

## ✨ Fitur yang Ditambahkan

### 1. **Fungsi Perhitungan Volume Air**
```dart
double _calculateWaterVolume(double seconds)
```
- Menggunakan interpolasi linear untuk perhitungan akurat
- Untuk waktu < 3.69s: interpolasi dari data step response
- Untuk waktu ≥ 3.69s: menggunakan flow rate konstan (6.775 ml/s)

### 2. **Fungsi Perhitungan Peningkatan Kelembaban**
```dart
int _calculateMoistureIncrease(double seconds)
```
- Menghitung peningkatan kelembaban tanah
- Maksimal 90% setelah steady state (3.69s)
- Interpolasi linear untuk waktu diantara titik data

### 3. **Tampilan Estimasi Output**
- **Sebelum Pompa ON**: Menampilkan estimasi total volume & kelembaban berdasarkan durasi yang dipilih
- **Saat Pompa ON**: Menampilkan output real-time yang sudah keluar

## 🎯 Cara Kerja

### **Interpolasi Linear:**
Untuk waktu antara dua titik data (t1, t2):
```
V = V1 + (V2 - V1) × (t - t1) / (t2 - t1)
```

**Contoh:**
- User pilih durasi 2.5 detik
- Titik data terdekat: 2.46s (16.67ml) dan 2.71s (18.33ml)
- Interpolasi:
  ```
  V = 16.67 + (18.33 - 16.67) × (2.5 - 2.46) / (2.71 - 2.46)
    = 16.67 + 1.66 × 0.04 / 0.25
    = 16.67 + 0.27
    = 16.94 ml
  ```

### **Setelah Steady State (> 3.69s):**
Flow rate konstan = 25ml / 3.69s ≈ 6.775 ml/s

**Contoh:**
- Durasi 10 detik
- Volume = 25 + (10 - 3.69) × 6.775
         = 25 + 42.73
         = 67.73 ml

## 📱 UI/UX

### **1. Card Estimasi (Sebelum ON):**
```
┌─────────────────────────────────┐
│     🌊 Estimasi Output Air      │
├─────────────┬───────────────────┤
│   67.7 ml   │      +90%        │
│    Total    │   Kelembaban     │
└─────────────┴───────────────────┘
```

### **2. Status Card (Saat Pompa ON):**
```
┌─────────────────────────────────┐
│  💧 Pompa Sedang Menyiram       │
│                                 │
│           15                    │
│      detik tersisa              │
├─────────────────────────────────┤
│  💧 16.7 ml     │  📈 +60%     │
│  air keluar     │  kelembaban   │
└─────────────────────────────────┘
```

### **3. Update Real-time:**
- Volume air bertambah sesuai waktu
- Kelembaban meningkat sesuai durasi
- Countdown timer menunjukkan sisa waktu

## 🧮 Formula & Logika

### **Data Points:**
```dart
final List<Map<String, dynamic>> _stepResponseData = [
  {'time': 0.25, 'volume': 1.67, 'moisture': 6},
  {'time': 0.49, 'volume': 3.33, 'moisture': 12},
  // ... 15 data points total
  {'time': 3.69, 'volume': 25.00, 'moisture': 90},
];
```

### **Validasi:**
- Waktu ≤ 0: return 0
- Waktu < 0.25s: interpolasi dari 0
- 0.25s ≤ Waktu < 3.69s: interpolasi linear
- Waktu ≥ 3.69s: steady state + flow rate konstan

## 📊 Contoh Perhitungan

### **Durasi 5 detik:**
```dart
Volume:
- Waktu 0-3.69s: 25 ml (steady state)
- Waktu 3.69-5s: (5-3.69) × 6.775 = 8.88 ml
- Total: 25 + 8.88 = 33.88 ml

Kelembaban: 90% (sudah steady state)
```

### **Durasi 1.5 detik:**
```dart
Volume:
- Titik terdekat: 1.48s (10ml) dan 1.72s (11.67ml)
- Interpolasi: 10 + (11.67-10) × (1.5-1.48)/(1.72-1.48)
             = 10 + 1.67 × 0.02/0.24
             = 10.14 ml

Kelembaban:
- Titik terdekat: 1.48s (36%) dan 1.72s (42%)
- Interpolasi: 36 + (42-36) × 0.02/0.24
             = 36.5% ≈ 37%
```

### **Durasi 30 detik (default):**
```dart
Volume:
- Steady state: 25 ml
- Waktu tambahan: (30-3.69) × 6.775 = 178.5 ml
- Total: 203.5 ml

Kelembaban: 90% (max)
```

## 🎨 UI Elements

### **Card Estimasi:**
- Background: `Colors.blue.shade50`
- Border: `Colors.blue.shade200`
- Icon: `Icons.water` (biru)
- Font: Bold untuk angka, regular untuk label

### **Status Real-time:**
- Icon volume: `Icons.opacity` (biru)
- Icon kelembaban: `Icons.trending_up` (hijau)
- Divider pemisah data
- Update otomatis setiap detik

## 🔄 Flow Data

```
User Input Durasi
      ↓
Slider Changed
      ↓
_handleDurationChanged()
      ↓
setState() → rebuild widget
      ↓
_calculateWaterVolume()
_calculateMoistureIncrease()
      ↓
Tampil di UI Estimasi
      ↓
[User tekan Mulai]
      ↓
Pompa ON → countdown
      ↓
Update real-time setiap detik
      ↓
Tampil volume & kelembaban saat ini
      ↓
Pompa OFF → kembali ke estimasi
```

## 📁 File yang Diubah

1. **lib/pages/pump_control_page.dart**
   - Tambah `_stepResponseData` (15 data points)
   - Tambah `_calculateWaterVolume()` dengan interpolasi
   - Tambah `_calculateMoistureIncrease()` dengan interpolasi
   - Update UI: Card estimasi output
   - Update UI: Status real-time saat pompa ON

## 🧪 Testing Points

- [ ] Durasi 1s → volume ≈ 6.94 ml, kelembaban ≈ 25%
- [ ] Durasi 2s → volume ≈ 13.47 ml, kelembaban ≈ 49%
- [ ] Durasi 3s → volume ≈ 20.56 ml, kelembaban ≈ 76%
- [ ] Durasi 5s → volume ≈ 33.88 ml, kelembaban 90%
- [ ] Durasi 30s → volume ≈ 203.5 ml, kelembaban 90%
- [ ] Durasi 120s → volume ≈ 787.6 ml, kelembaban 90%
- [ ] Slider geser → estimasi berubah real-time
- [ ] Pompa ON → countdown berjalan, volume bertambah
- [ ] Pompa OFF → kembali ke estimasi

## ✅ Status
✅ **COMPLETE** - Fitur output keluaran pompa berhasil ditambahkan!

### Flow rate pompa:
- 0-3.69s: Transient response (mengikuti data tabel)
- > 3.69s: Steady state, 6.775 ml/s konstan
- Max kelembaban: 90% (steady state)

