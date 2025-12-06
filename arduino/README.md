# TeraLux Arduino Controller

Program Arduino untuk sistem monitoring dan kontrol greenhouse TeraLux.

## 🔧 Hardware yang Dibutuhkan

### Komponen Utama
1. **ESP32 DevKit v1** (RECOMMENDED - lebih banyak ADC pins)
2. **DHT22** - Sensor suhu dan kelembaban
3. **BH1750** - Sensor cahaya digital I2C (lebih akurat dari LDR, tidak perlu kalibrasi!)
4. **Capacitive Soil Moisture Sensor** - Sensor kelembaban tanah (tahan korosi)
5. **2x Relay Module** (5V, 1 channel atau 2 channel)
6. **Water Pump** (12V DC atau sesuai kebutuhan)
7. **Lampu/Light** (220V AC atau 12V DC)

### Komponen Tambahan
- Breadboard dan kabel jumper
- Power supply untuk ESP32 (5V via USB atau VIN)
- Power supply untuk pump dan lampu (12V recommended)
- (Resistor 10kΩ TIDAK PERLU lagi karena BH1750 digital)

## 📌 Koneksi Pin

### ✅ ESP32 Pin Mapping (RECOMMENDED)

| Komponen | Pin ESP32 | Keterangan |
|----------|-----------|------------|
| DHT22 Data | GPIO 4 | Digital input |
| BH1750 SDA | GPIO 21 | I2C Data (built-in I2C) |
| BH1750 SCL | GPIO 22 | I2C Clock (built-in I2C) |
| Soil Moisture | GPIO 35 (ADC1_CH7) | Analog input (0-4095, 12-bit) |
| Pump Relay | GPIO 26 | Digital output (Active LOW) |
| Light Relay | GPIO 27 | Digital output (Active LOW) |
| Status LED | GPIO 2 (Built-in) | Digital output |

### ✅ Keunggulan ESP32 + BH1750
- ✅ BH1750 adalah sensor **digital I2C**, bukan analog
- ✅ Tidak perlu pin ADC untuk BH1750 (hanya butuh SDA + SCL)
- ✅ ESP32 punya banyak ADC pins untuk soil sensor
- ✅ BH1750 memberikan **nilai Lux langsung**, tidak perlu kalibrasi!
- ✅ Akurasi lebih tinggi (±20%) vs LDR (±30-50%)
- ✅ Stabil, tidak terpengaruh suhu

### ⚠️ Catatan Penting untuk ESP8266
- ESP8266 masih bisa digunakan karena BH1750 pakai I2C (bukan ADC)
- Tapi ESP32 lebih disarankan untuk performa lebih baik

### Diagram Koneksi DHT22
```
DHT22 VCC  → 3.3V
DHT22 GND  → GND
DHT22 DATA → GPIO 4
```

### Diagram Koneksi BH1750 (Digital I2C)
```
BH1750 VCC  → 3.3V
BH1750 GND  → GND
BH1750 SDA  → GPIO 21 (I2C SDA)
BH1750 SCL  → GPIO 22 (I2C SCL)
BH1750 ADDR → GND (I2C address 0x23)
```
**Note:** Tidak perlu resistor! BH1750 sudah digital.

### Diagram Koneksi Capacitive Soil Moisture Sensor
```
Sensor VCC  → 3.3V
Sensor GND  → GND
Sensor AOUT → GPIO 35 (ADC1_CH7)
```
**Note:** Gunakan sensor capacitive (tahan korosi), bukan resistive!

### Diagram Koneksi Relay Module
```
Relay VCC → 5V
Relay GND → GND
Relay IN1 → D7 (GPIO13) - Pump
Relay IN2 → D8 (GPIO15) - Light

Relay COM → Power source (+)
Relay NO  → Device (+)
Device (-) → Power source (-)
```

## 📚 Library yang Dibutuhkan

Install library berikut melalui Arduino IDE (Sketch → Include Library → Manage Libraries):

1. **WiFi** (Built-in untuk ESP32)
2. **PubSubClient** by Nick O'Leary (v2.8.0 atau lebih baru)
3. **DHT sensor library** by Adafruit (v1.4.4 atau lebih baru)
4. **Adafruit Unified Sensor** (dependency DHT)
5. **ArduinoJson** by Benoit Blanchon (v6.21.0 atau lebih baru)
6. **BH1750** by Christopher Laws (v1.3.0 atau lebih baru) - **NEW!**

### Cara Install Library:
1. Buka Arduino IDE
2. Tools → Manage Libraries
3. Search nama library
4. Klik Install

## ⚙️ Konfigurasi

Edit file `teralux_arduino.ino` dan sesuaikan konfigurasi berikut:

### 1. WiFi Configuration
```cpp
const char* ssid = "YOUR_WIFI_SSID";          // Nama WiFi Anda
const char* password = "YOUR_WIFI_PASSWORD";   // Password WiFi
```

### 2. MQTT Broker Configuration

**Opsi A: Menggunakan Public Broker (untuk testing)**
```cpp
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* mqtt_user = "";
const char* mqtt_password = "";
```

**Opsi B: Menggunakan Broker Lokal (Mosquitto)**
```cpp
const char* mqtt_server = "192.168.1.100";  // IP Raspberry Pi atau server
const int mqtt_port = 1883;
const char* mqtt_user = "teralux";
const char* mqtt_password = "password123";
```

**Opsi C: Menggunakan Cloud MQTT**
```cpp
const char* mqtt_server = "your-instance.cloudmqtt.com";
const int mqtt_port = 1883;
const char* mqtt_user = "your_username";
const char* mqtt_password = "your_password";
```

## 🚀 Cara Upload Program

1. **Install ESP8266 Board Manager:**
   - File → Preferences
   - Additional Board Manager URLs: `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
   - Tools → Board → Boards Manager
   - Search "ESP8266" → Install

2. **Pilih Board:**
   - Tools → Board → ESP8266 Boards → NodeMCU 1.0 (ESP-12E Module)

3. **Konfigurasi Upload:**
   - Tools → Upload Speed → 115200
   - Tools → CPU Frequency → 80 MHz
   - Tools → Flash Size → 4MB (FS:2MB OTA:~1019KB)
   - Tools → Port → (Pilih COM port ESP8266 Anda)

4. **Upload:**
   - Tekan tombol Upload (→)
   - Tunggu hingga "Done uploading"

5. **Monitor Serial:**
   - Tools → Serial Monitor
   - Set baud rate: 115200

## 📡 MQTT Topics

Program ini menggunakan topik MQTT berikut:

### Published Topics (Arduino → Flutter)
| Topic | Payload | Keterangan |
|-------|---------|------------|
| `teralux/sensors` | `{"temperature": 25.5, "humidity": 60.0, "rawLightValue": 512, "rawMoistureValue": 300}` | Data sensor setiap 5 detik |
| `teralux/pump/status` | `{"isRunning": true, "remainingSeconds": 45}` | Status pompa |
| `teralux/light/status` | `{"isOn": true}` | Status lampu |

### Subscribed Topics (Flutter → Arduino)
| Topic | Payload | Keterangan |
|-------|---------|------------|
| `teralux/pump/control` | `{"mode": "start", "duration": 60}` | Kontrol pompa |
| `teralux/pump/control` | `{"mode": "stop"}` | Hentikan pompa |
| `teralux/light/control` | `{"isOn": true}` | Kontrol lampu |

## 🔍 Testing dan Debugging

### 1. Test Serial Monitor
```
=================================
   TeraLux Arduino Controller   
=================================

DHT22 initialized
Connecting to WiFi: MyWiFi
......
WiFi connected!
IP address: 192.168.1.105
Signal strength (RSSI): -45 dBm

Connecting to MQTT broker... connected!
Subscribed to control topics

Temp: 25.5°C | Humidity: 60.0% | Light: 512 | Moisture: 300
Sensor data published
```

### 2. Test MQTT dengan MQTT Explorer
1. Download MQTT Explorer: http://mqtt-explorer.com/
2. Connect ke broker yang sama
3. Subscribe ke `teralux/#`
4. Lihat data sensor yang masuk
5. Publish ke `teralux/pump/control` untuk test kontrol

### 3. Test Publish Manual
Gunakan mosquitto_pub (Linux/Mac) atau MQTT.fx (Windows):
```bash
# Test Pump Control
mosquitto_pub -h broker.hivemq.com -t "teralux/pump/control" -m '{"mode":"start","duration":10}'

# Test Light Control
mosquitto_pub -h broker.hivemq.com -t "teralux/light/control" -m '{"isOn":true}'
```

## 🔧 Troubleshooting

### WiFi tidak connect
- Pastikan SSID dan password benar
- Pastikan ESP8266 dalam jangkauan WiFi
- Coba restart ESP8266

### MQTT tidak connect
- Pastikan broker address benar
- Cek port (default 1883)
- Untuk cloud broker, cek username/password
- Cek firewall

### Sensor tidak terbaca
- Cek koneksi kabel
- Cek power supply (3.3V/5V)
- Test sensor dengan example code library

### Relay tidak kerja
- Cek jenis relay (Active HIGH atau LOW)
- Jika Active HIGH, ganti `LOW` jadi `HIGH` dan sebaliknya
- Cek power supply relay (biasanya 5V)

### Analog pin conflict (ESP8266)
- ESP8266 hanya punya 1 ADC pin
- **Solusi terbaik:** Gunakan ESP32
- Alternative: Gunakan multiplexer

## 📊 Kalibrasi Sensor

Untuk hasil yang akurat, lakukan kalibrasi sensor:

1. **Light Sensor (LDR):**
   - Ukur dengan Lux Meter standar
   - Catat nilai ADC dan Lux di beberapa kondisi cahaya
   - Input di aplikasi Flutter (Calibration Page)

2. **Soil Moisture Sensor:**
   - Test di udara (kering) dan di air (basah)
   - Catat nilai ADC untuk 0% dan 100%
   - Input di aplikasi Flutter

## 🔒 Keamanan

### Untuk Production:
1. **Ganti password WiFi** yang kuat
2. **Gunakan MQTT broker dengan autentikasi**
3. **Gunakan TLS/SSL** untuk koneksi MQTT
4. **Jangan hardcode password** di code (gunakan EEPROM)

## 📝 Modifikasi untuk ESP32

Jika menggunakan ESP32, ubah beberapa baris:

```cpp
// Ganti library WiFi
#include <WiFi.h>  // Bukan ESP8266WiFi.h

// Pin analog bisa menggunakan ADC1 atau ADC2
#define LDR_PIN 34      // ADC1_CH6 (GPIO34)
#define SOIL_PIN 35     // ADC1_CH7 (GPIO35)

// Pin lainnya sama
```

## 📞 Support

Jika ada masalah:
1. Cek Serial Monitor untuk error messages
2. Test satu-satu komponen
3. Gunakan example code dari library untuk test sensor
4. Cek wiring dengan multimeter

## 📄 License

Program ini dibuat untuk TeraLux Greenhouse Monitoring System.
Free to use and modify.
