# MQTT Broker Setup Guide for TeraLux

Panduan lengkap untuk setup MQTT broker untuk sistem TeraLux.

## 📡 Opsi MQTT Broker

### Opsi 1: Public MQTT Broker (Untuk Testing)

**HiveMQ Public Broker** - Gratis, tanpa registrasi
```
Host: broker.hivemq.com
Port: 1883
Username: (tidak perlu)
Password: (tidak perlu)
```

**Eclipse Mosquitto Public Broker**
```
Host: test.mosquitto.org
Port: 1883
Username: (tidak perlu)
Password: (tidak perlu)
```

**⚠️ Perhatian:**
- Public broker tidak aman
- Data dapat dilihat siapa saja
- Hanya untuk testing/development
- Jangan gunakan untuk production

### Opsi 2: Install Mosquitto Broker Lokal (Recommended)

#### A. Install di Raspberry Pi (Linux)

1. **Update system:**
```bash
sudo apt update
sudo apt upgrade -y
```

2. **Install Mosquitto:**
```bash
sudo apt install mosquitto mosquitto-clients -y
```

3. **Enable autostart:**
```bash
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
```

4. **Check status:**
```bash
sudo systemctl status mosquitto
```

5. **Buat user dan password:**
```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd teralux
# Masukkan password: teralux123
```

6. **Edit config file:**
```bash
sudo nano /etc/mosquitto/mosquitto.conf
```

Tambahkan:
```conf
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
```

7. **Restart Mosquitto:**
```bash
sudo systemctl restart mosquitto
```

8. **Test connection:**
```bash
# Terminal 1 - Subscribe
mosquitto_sub -h localhost -t "test/topic" -u teralux -P teralux123

# Terminal 2 - Publish
mosquitto_pub -h localhost -t "test/topic" -m "Hello TeraLux" -u teralux -P teralux123
```

#### B. Install di Windows

1. **Download Mosquitto:**
   - https://mosquitto.org/download/
   - Install dengan default settings

2. **Edit config file:**
   - Location: `C:\Program Files\mosquitto\mosquitto.conf`
   - Add:
```conf
listener 1883
allow_anonymous false
password_file C:\Program Files\mosquitto\passwd
```

3. **Create password file:**
```cmd
cd "C:\Program Files\mosquitto"
mosquitto_passwd -c passwd teralux
```

4. **Start Mosquitto service:**
```cmd
net start mosquitto
```

5. **Test:**
```cmd
# Subscribe
mosquitto_sub -h localhost -t test/topic -u teralux -P teralux123

# Publish
mosquitto_pub -h localhost -t test/topic -m "Hello" -u teralux -P teralux123
```

#### C. Install di Mac

1. **Install via Homebrew:**
```bash
brew install mosquitto
```

2. **Start service:**
```bash
brew services start mosquitto
```

3. **Create password:**
```bash
mosquitto_passwd -c /usr/local/etc/mosquitto/passwd teralux
```

4. **Edit config:**
```bash
nano /usr/local/etc/mosquitto/mosquitto.conf
```

Add:
```conf
listener 1883
allow_anonymous false
password_file /usr/local/etc/mosquitto/passwd
```

5. **Restart:**
```bash
brew services restart mosquitto
```

### Opsi 3: Cloud MQTT (Production)

#### CloudMQTT (Paid, Reliable)
1. Sign up: https://www.cloudmqtt.com/
2. Create instance
3. Get connection details:
   - Server: xxx.cloudmqtt.com
   - Port: 1883 or 18883 (SSL)
   - User: provided
   - Password: provided

#### HiveMQ Cloud (Free tier available)
1. Sign up: https://www.hivemq.com/mqtt-cloud-broker/
2. Create cluster
3. Create credentials
4. Use connection string

## 🔧 Konfigurasi Arduino

Edit file Arduino (`teralux_arduino.ino` atau `teralux_esp32.ino`):

### Untuk Broker Lokal:
```cpp
const char* mqtt_server = "192.168.1.100";  // IP Raspberry Pi/Server
const int mqtt_port = 1883;
const char* mqtt_user = "teralux";
const char* mqtt_password = "teralux123";
```

### Untuk Public Broker:
```cpp
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* mqtt_user = "";
const char* mqtt_password = "";
```

### Untuk Cloud MQTT:
```cpp
const char* mqtt_server = "your-instance.cloudmqtt.com";
const int mqtt_port = 1883;
const char* mqtt_user = "your_username";
const char* mqtt_password = "your_password";
```

## 🔧 Konfigurasi Flutter App

Edit file `lib/services/mqtt_service.dart`:

### 1. Uncomment MQTT client code
Cari bagian:
```dart
// Uncomment for real MQTT implementation
// final client = mqtt.MqttServerClient(broker, clientId);
```

Ubah menjadi:
```dart
final client = mqtt.MqttServerClient(broker, clientId);
```

### 2. Set broker address
```dart
class MQTTService {
  // For local broker
  static const String broker = '192.168.1.100';  // IP Raspberry Pi
  
  // For public broker
  // static const String broker = 'broker.hivemq.com';
  
  // For cloud MQTT
  // static const String broker = 'your-instance.cloudmqtt.com';
  
  static const int port = 1883;
  static const String username = 'teralux';      // If required
  static const String password = 'teralux123';   // If required
```

### 3. Add MQTT package
Edit `pubspec.yaml`:
```yaml
dependencies:
  mqtt_client: ^10.0.0  # Add this line
```

Run:
```bash
flutter pub get
```

## 🧪 Testing MQTT Connection

### 1. Test dengan MQTT Explorer (GUI Tool)

**Download:** http://mqtt-explorer.com/

**Setup:**
1. Host: `broker.hivemq.com` atau IP broker Anda
2. Port: `1883`
3. Username: `teralux` (jika pakai autentikasi)
4. Password: `teralux123`
5. Click **Connect**

**Test Publishing:**
1. Topic: `teralux/pump/control`
2. Message: `{"mode":"start","duration":10}`
3. Click **Publish**

**Test Subscribing:**
1. Subscribe to: `teralux/#` (all topics)
2. Lihat data sensor masuk dari Arduino

### 2. Test dengan Command Line

**Subscribe (Listen to Arduino):**
```bash
# For local broker
mosquitto_sub -h 192.168.1.100 -t "teralux/#" -u teralux -P teralux123

# For public broker
mosquitto_sub -h broker.hivemq.com -t "teralux/#"
```

**Publish (Control Arduino):**
```bash
# Start pump for 30 seconds
mosquitto_pub -h 192.168.1.100 -t "teralux/pump/control" \
  -m '{"mode":"start","duration":30}' -u teralux -P teralux123

# Stop pump
mosquitto_pub -h 192.168.1.100 -t "teralux/pump/control" \
  -m '{"mode":"stop"}' -u teralux -P teralux123

# Turn light on
mosquitto_pub -h 192.168.1.100 -t "teralux/light/control" \
  -m '{"isOn":true}' -u teralux -P teralux123

# Turn light off
mosquitto_pub -h 192.168.1.100 -t "teralux/light/control" \
  -m '{"isOn":false}' -u teralux -P teralux123
```

### 3. Test dengan Python Script

```python
import paho.mqtt.client as mqtt
import json
import time

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")
    client.subscribe("teralux/#")

def on_message(client, userdata, msg):
    print(f"{msg.topic}: {msg.payload.decode()}")

# Setup client
client = mqtt.Client()
client.username_pw_set("teralux", "teralux123")
client.on_connect = on_connect
client.on_message = on_message

# Connect
client.connect("192.168.1.100", 1883, 60)

# Start loop in background
client.loop_start()

# Test publish
time.sleep(2)
client.publish("teralux/pump/control", 
               json.dumps({"mode": "start", "duration": 10}))

# Keep running
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("Stopping...")
    client.loop_stop()
```

## 📊 MQTT Topics Structure

### Published by Arduino (Sensor Data):
```
teralux/sensors
├── temperature: float
├── humidity: float
├── rawLightValue: int (0-4095)
├── rawMoistureValue: int (0-4095)
└── timestamp: unsigned long

teralux/pump/status
├── isRunning: bool
└── remainingSeconds: int

teralux/light/status
└── isOn: bool
```

### Subscribed by Arduino (Control Commands):
```
teralux/pump/control
├── mode: "start" | "stop"
└── duration: int (seconds, for start mode)

teralux/light/control
└── isOn: bool
```

## 🔒 Security Best Practices

### 1. Use Authentication
```conf
allow_anonymous false
password_file /etc/mosquitto/passwd
```

### 2. Use TLS/SSL (Production)
```conf
listener 8883
cafile /etc/mosquitto/ca_certificates/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
```

### 3. Use Access Control Lists (ACL)
```conf
acl_file /etc/mosquitto/acl
```

Example ACL file:
```
# Allow teralux user to publish/subscribe to teralux topics
user teralux
topic readwrite teralux/#

# Deny anonymous
user anonymous
topic read teralux/sensors
```

### 4. Network Security
- Use VPN for remote access
- Firewall rules:
  - Allow port 1883 only from trusted IPs
  - Block public access if not needed

## 🚨 Troubleshooting

### Arduino can't connect to MQTT
- Check WiFi connection first
- Verify broker IP/hostname
- Check username/password
- Test broker with MQTT Explorer
- Check firewall rules

### Flutter app can't receive data
- Verify broker address in code
- Check MQTT package installed
- Test with MQTT Explorer first
- Check network connectivity

### Data not updating
- Check Arduino Serial Monitor
- Verify topics match exactly
- Check JSON format
- Test publish/subscribe separately

## 📈 Monitoring MQTT Traffic

### View live traffic:
```bash
# Subscribe to all topics
mosquitto_sub -h localhost -t "#" -v -u teralux -P teralux123

# View specific topics
mosquitto_sub -h localhost -t "teralux/#" -v -u teralux -P teralux123
```

### Log to file:
```bash
mosquitto_sub -h localhost -t "teralux/#" -v -u teralux -P teralux123 > mqtt_log.txt
```

## 🎯 Next Steps

1. ✅ **Setup MQTT broker** (pilih salah satu opsi)
2. ✅ **Test broker** dengan MQTT Explorer
3. ✅ **Configure Arduino** dengan broker address
4. ✅ **Configure Flutter app** dengan broker address
5. ✅ **Test end-to-end** (Arduino → MQTT → Flutter)
6. ✅ **Deploy** to production

## 📚 Additional Resources

- Mosquitto Documentation: https://mosquitto.org/documentation/
- MQTT.org: https://mqtt.org/
- MQTT Explorer: http://mqtt-explorer.com/
- Paho MQTT Client: https://www.eclipse.org/paho/

**Good luck! 🚀**
