# TeraLux - Wiring Diagram & Connection Guide

## 📌 ESP32 Version (Recommended)

### Complete Pin Connections

```
ESP32 DevKit v1
┌────────────────────────────────────┐
│                                    │
│  3V3 ────────┬──── DHT22 VCC      │
│              ├──── LDR (Top)       │
│              └──── Soil VCC        │
│                                    │
│  GND ────────┬──── DHT22 GND      │
│              ├──── LDR (Bottom)*   │
│              ├──── Soil GND        │
│              ├──── Relay GND       │
│              └──── All GND         │
│                                    │
│  GPIO 4 ────────── DHT22 DATA     │
│  GPIO 34 ───────── LDR Middle*    │
│  GPIO 35 ───────── Soil A0        │
│  GPIO 26 ───────── Relay IN1      │
│  GPIO 27 ───────── Relay IN2      │
│  GPIO 2 ────────── Built-in LED   │
│                                    │
│  VIN (5V) ──────── Relay VCC      │
│                                    │
└────────────────────────────────────┘

* LDR needs 10kΩ pull-down resistor
```

### Detailed Component Connections

#### 1. DHT22 Temperature & Humidity Sensor
```
DHT22          ESP32
─────────────────────
VCC (+) ────── 3.3V
DATA ───────── GPIO 4
GND (-) ────── GND
```

#### 2. LDR Light Sensor (with voltage divider)
```
3.3V
 │
 └── LDR ──┬── GPIO 34 (ADC1_CH6)
           │
         10kΩ
           │
          GND
```
**Note:** LDR value: 5-10kΩ typical. Adjust resistor based on your LDR.

#### 3. Soil Moisture Sensor
```
Soil Sensor    ESP32
─────────────────────
VCC (+) ────── 3.3V
GND (-) ────── GND
A0 (Analog) ── GPIO 35 (ADC1_CH7)
```

#### 4. Relay Module (2 Channel)
```
Relay Module   ESP32
─────────────────────
VCC ────────── VIN (5V)
GND ────────── GND
IN1 ────────── GPIO 26 (Pump)
IN2 ────────── GPIO 27 (Light)
```

#### 5. Water Pump Connection (via Relay)
```
Power Supply     Relay CH1      Water Pump
────────────────────────────────────────
(+12V) ────────── COM ────────── NC (not used)
                  NO  ────────── Pump (+)
(-GND) ─────────────────────────── Pump (-)
```

#### 6. Light/Lamp Connection (via Relay)
```
Power Supply     Relay CH2      Light/Lamp
────────────────────────────────────────
(+12V) ────────── COM ────────── NC (not used)
                  NO  ────────── Light (+)
(-GND) ─────────────────────────── Light (-)
```

## 📊 ESP8266 Version (Alternative)

**⚠️ Warning:** ESP8266 only has 1 analog pin (A0), so you need to choose between LDR or Soil Moisture Sensor, or use a multiplexer.

### ESP8266 NodeMCU Pin Mapping
```
ESP8266 NodeMCU
┌────────────────────────────────────┐
│                                    │
│  3V3 ────────┬──── DHT22 VCC      │
│              └──── LDR/Soil VCC    │
│                                    │
│  GND ────────┬──── DHT22 GND      │
│              ├──── LDR/Soil GND    │
│              └──── Relay GND       │
│                                    │
│  D2 (GPIO4) ────── DHT22 DATA     │
│  A0 (ADC) ──────── LDR or Soil*   │
│  D7 (GPIO13) ───── Relay IN1      │
│  D8 (GPIO15) ───── Relay IN2      │
│                                    │
│  VIN (5V) ──────── Relay VCC      │
│                                    │
└────────────────────────────────────┘

* Choose one: LDR or Soil Moisture
  Or use CD4051 multiplexer for both
```

## 🔌 Power Supply Considerations

### Option 1: Separate Power Supplies (Safest)
- **ESP32/ESP8266:** USB 5V (500mA minimum)
- **Pump:** 12V DC power supply (2A recommended)
- **Light:** 12V DC or 220V AC (with appropriate relay rating)
- **Common Ground:** Connect all GND together

### Option 2: Single Power Supply
- Use 12V DC power supply with buck converter
- **12V → Buck Converter → 5V** for ESP32
- **12V Direct** to pump and light via relay
- **Total Current:** Calculate based on pump + light + ESP32

### Example Power Calculation:
```
ESP32:        200mA @ 5V
Relay Module: 70mA @ 5V
Water Pump:   500mA @ 12V
LED Light:    300mA @ 12V
─────────────────────────
Total 5V:     270mA
Total 12V:    800mA

Recommended: 12V 2A power supply
```

## 🛡️ Safety & Protection

### 1. Relay Protection
```
GPIO Pin ──┬── 1kΩ Resistor ── Relay IN
           │
           └── Flyback Diode (1N4007)
                     │
                    GND
```

### 2. Sensor Protection
- **DHT22:** Add 4.7kΩ pull-up resistor between DATA and VCC
- **LDR:** Add 0.1µF capacitor between ADC pin and GND for noise filtering
- **Soil:** Add 100Ω resistor in series to prevent corrosion

### 3. Power Protection
- Add 1000µF capacitor near VIN for power stability
- Use separate power rails for sensors and relays if possible

## 🧪 Testing Checklist

### Before Powering On:
- [ ] Double-check all connections
- [ ] Verify VCC and GND not swapped
- [ ] Ensure relay is NOT connected to mains power yet
- [ ] Check GPIO pins match code

### Power On Sequence:
1. **Connect ESP32** to USB (no relays powered)
2. **Upload code** and check Serial Monitor
3. **Verify WiFi** connection
4. **Test MQTT** connection
5. **Check sensor readings** (should show values)
6. **Connect relay power** (5V)
7. **Test relay clicking** (should hear click on control)
8. **Finally connect** pump and light

### Serial Monitor Output Should Show:
```
=================================
  TeraLux ESP32 Controller   
=================================

DHT22 initialized
Connecting to WiFi: YourWiFi
......
WiFi connected!
IP address: 192.168.1.105
Signal strength (RSSI): -45 dBm

Connecting to MQTT broker... connected!
Subscribed to control topics

Temp: 25.5°C | Humidity: 60.0% | Light: 1024 | Moisture: 512
✓ Sensor data published
```

## 🔧 Troubleshooting Wiring Issues

### Sensor Not Reading
| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| Temperature = NaN | DHT22 wiring wrong | Check VCC, GND, DATA pins |
| Light = 0 or 4095 | LDR disconnected | Check resistor divider circuit |
| Soil = constant | Sensor not in soil | Test with water |

### Relay Not Switching
| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| No click sound | No power to relay | Check VIN 5V connection |
| Always on | Wrong trigger level | Change LOW to HIGH in code |
| Intermittent | Loose connection | Check IN1/IN2 wires |

### WiFi Won't Connect
| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| Keeps retrying | Wrong credentials | Double-check SSID/password |
| No antenna | Built-in antenna | ESP32 has built-in antenna |
| Too far | Weak signal | Move closer to router |

## 📷 Visual References

### LDR Resistor Divider Circuit
```
    VCC (3.3V)
       │
       │
    ╔═════╗
    ║ LDR ║  (Light Dependent Resistor)
    ╚═════╝
       │
       ├──────── To GPIO 34 (ESP32)
       │
    ┌─────┐
    │10kΩ │  (Pull-down resistor)
    └─────┘
       │
      GND
```

### Relay Wiring for AC Load (220V)
```
⚠️ DANGER: HIGH VOLTAGE!

AC 220V                Relay         Lamp/Light
─────────────────────────────────────────────
Live (L) ─────────── COM ───── NC (not used)
                           NO ───── Light
Neutral (N) ────────────────────── Light
                                    
⚠️ Use proper insulation and enclosure!
⚠️ Have an electrician check AC connections!
```

## 📋 Bill of Materials (BOM)

| Component | Quantity | Price (Est.) | Notes |
|-----------|----------|--------------|-------|
| ESP32 DevKit v1 | 1 | $5-10 | Or NodeMCU ESP8266 |
| DHT22 Sensor | 1 | $3-5 | With pull-up resistor |
| LDR 5-10kΩ | 1 | $0.50 | With 10kΩ resistor |
| Soil Moisture Sensor | 1 | $2-3 | Capacitive type better |
| 2-Channel Relay 5V | 1 | $2-4 | Optocoupler isolated |
| 12V Water Pump | 1 | $5-10 | Small submersible |
| 12V LED Strip | 1 | $3-5 | Or any 12V light |
| 12V 2A Power Supply | 1 | $5-8 | With DC jack |
| Buck Converter (12V→5V) | 1 | $1-2 | If using single PSU |
| Jumper Wires | 20+ | $2-3 | Male-Female mix |
| Breadboard | 1 | $2-3 | Or PCB for permanent |
| Resistors (1kΩ, 10kΩ) | Set | $1-2 | Various values |
| **Total** | - | **$30-50** | Approximate |

## 🎯 Next Steps

1. ✅ **Assemble hardware** following this guide
2. ✅ **Upload Arduino code** (ESP32 or ESP8266 version)
3. ✅ **Test sensors** via Serial Monitor
4. ✅ **Configure MQTT broker** (see README.md)
5. ✅ **Connect Flutter app** to same MQTT broker
6. ✅ **Calibrate sensors** using Calibration Page
7. ✅ **Test controls** (pump and light)
8. ✅ **Deploy** to greenhouse!

## 📞 Support

For wiring questions:
- Check component datasheets
- Use multimeter to verify connections
- Test components individually first
- Join Arduino forums for help

**Happy Building! 🚀🌱**
