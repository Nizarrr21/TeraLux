#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <BH1750.h>
#include <LiquidCrystal_I2C.h>

// ===== WiFi Configuration =====
const char* ssid = "vivo 1807";
const char* password = "limalimalimalimalimalima";

// ===== MQTT Configuration =====
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* mqtt_user = "";
const char* mqtt_password = "";

// MQTT Topics
const char* topic_sensors = "teralux_project/sensors";
const char* topic_pump_control = "teralux_project/pump/control";
const char* topic_pump_status = "teralux_project/pump/status";
const char* topic_light_control = "teralux_project/light/control";
const char* topic_light_status = "teralux_project/light/status";
const char* topic_threshold_settings = "teralux_project/settings/threshold";
const char* topic_calibration = "teralux_project/settings/calibration";

// ===== Pin Configuration (ESP32) =====
// I2C Bus 0 (Default Wire) - Untuk LCD 16x2
#define I2C0_SDA 21         // SDA untuk LCD (pin default ESP32)
#define I2C0_SCL 22         // SCL untuk LCD (pin default ESP32)

// I2C Bus 1 (Wire1) - Untuk BH1750 Light Sensor
#define I2C1_SDA 32         // SDA untuk BH1750
#define I2C1_SCL 33         // SCL untuk BH1750

// I2C Device Addresses
#define BH1750_ADDRESS 0x23 // Alamat I2C BH1750 (default: 0x23, atau 0x5C)
#define LCD_ADDRESS 0x27    // Alamat I2C LCD (default: 0x27, atau 0x3F)

// Sensor & Actuator Pins
#define SOIL_PIN 25         // Pin ADC untuk soil moisture sensor (ADC1_CH6)
#define PUMP_RELAY_PIN 26   // Pin relay pompa air
#define LIGHT_RELAY_PIN 27  // Pin relay lampu
#define STATUS_LED_PIN 2    // Pin LED status built-in

// ===== Sensor Objects =====
TwoWire I2C_BH1750 = TwoWire(1);  // I2C Bus 1 untuk BH1750
// Wire (default) akan digunakan untuk LCD

BH1750 lightMeter(BH1750_ADDRESS);
LiquidCrystal_I2C lcd(LCD_ADDRESS, 16, 2);  // LCD menggunakan Wire default
WiFiClient espClient;
PubSubClient client(espClient);

// ===== Global Variables =====
float lightLevel = 0.0;
int rawMoistureValue = 0;
float moisturePercent = 0.0;  // Tambahan untuk menyimpan kelembapan
bool bh1750_initialized = false;
bool lcd_initialized = false;

bool pumpIsRunning = false;
unsigned long pumpStartTime = 0;
unsigned long pumpDuration = 0;
bool pumpManualMode = false;

bool lightIsOn = false;
bool lightManualMode = false;

float soilMoistureMin = 30.0;
float lightLevelMin = 1000.0;
bool autoWateringEnabled = true;
bool autoLightingEnabled = true;
int wateringDuration = 30;

float moistureSlope = 1.0;
float moistureIntercept = 0.0;
int soilDryValue = 4095;
int soilWetValue = 1500;

unsigned long lastAutoCheck = 0;
const unsigned long autoCheckInterval = 10000;
unsigned long lastAutoWatering = 0;
const unsigned long wateringCooldown = 300000;

unsigned long lastSensorRead = 0;
unsigned long lastMqttPublish = 0;
const unsigned long sensorReadInterval = 2000;
const unsigned long mqttPublishInterval = 5000;

unsigned long lastMqttReconnectAttempt = 0;
const unsigned long mqttReconnectInterval = 5000;

unsigned long lastBH1750Retry = 0;
const unsigned long bh1750RetryInterval = 5000;

unsigned long lastLcdUpdate = 0;
const unsigned long lcdUpdateInterval = 1000;
int lcdPage = 0;

// ===== Function Prototypes =====
void setup_wifi();
void reconnect_mqtt();
void callback(char* topic, byte* payload, unsigned int length);
void readSensors();
void publishSensorData();
void handlePumpControl();
void publishPumpStatus();
void publishLightStatus();
void checkAutoControl();
void initBH1750();
void initLCD();
void updateLCD();

// ===== Setup Function =====
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n=================================");
  Serial.println("  TeraLux ESP32 Controller");
  Serial.println("  SEPARATE I2C v3.1");
  Serial.println("=================================\n");
  
  // Initialize pins
  pinMode(PUMP_RELAY_PIN, OUTPUT);
  pinMode(LIGHT_RELAY_PIN, OUTPUT);
  pinMode(STATUS_LED_PIN, OUTPUT);
  pinMode(SOIL_PIN, INPUT);
  
  digitalWrite(PUMP_RELAY_PIN, HIGH);
  digitalWrite(LIGHT_RELAY_PIN, HIGH);
  digitalWrite(STATUS_LED_PIN, LOW);
  
  Serial.println("[1] Pins initialized");
  
  // Configure ADC
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
  analogSetWidth(12);
  
  Serial.println("[2] ADC configured (12-bit, 0-3.3V)");
  
  // Test soil sensor
  Serial.print("[2a] Testing soil sensor on GPIO");
  Serial.print(SOIL_PIN);
  Serial.print("... ");
  
  // Read multiple times untuk stabilitas
  long sum = 0;
  for (int i = 0; i < 20; i++) {
    sum += analogRead(SOIL_PIN);
    delay(10);
  }
  int testRead = sum / 20;
  
  Serial.print("ADC = ");
  Serial.print(testRead);
  
  // Hitung kelembapan langsung
  float testMoisture = map(testRead, soilWetValue, soilDryValue, 100, 0);
  testMoisture = constrain(testMoisture, 0, 100);
  
  Serial.print(" → Moisture: ");
  Serial.print(testMoisture, 1);
  Serial.print("%");
  
  if (testRead == 0) {
    Serial.println(" ⚠️  WARNING: Reading 0! Check wiring!");
  } else if (testMoisture <= 10) {
    Serial.println(" (Sangat Kering)");
  } else if (testMoisture <= 30) {
    Serial.println(" (Kering)");
  } else if (testMoisture <= 60) {
    Serial.println(" (Normal)");
  } else {
    Serial.println(" (Basah)");
  }
  
  // Initialize I2C Bus 0 (Default Wire) untuk LCD
  Wire.begin(I2C0_SDA, I2C0_SCL);
  Serial.print("[3] I2C Bus 0 (Wire) initialized (SDA:");
  Serial.print(I2C0_SDA);
  Serial.print(", SCL:");
  Serial.print(I2C0_SCL);
  Serial.println(") - FOR LCD");
  
  // Initialize I2C Bus 1 untuk BH1750
  I2C_BH1750.begin(I2C1_SDA, I2C1_SCL, 100000);
  Serial.print("[4] I2C Bus 1 (Wire1) initialized (SDA:");
  Serial.print(I2C1_SDA);
  Serial.print(", SCL:");
  Serial.print(I2C1_SCL);
  Serial.println(") - FOR BH1750");
  
  // Initialize LCD
  initLCD();
  
  // Initialize BH1750
  initBH1750();
  
  // Connect to WiFi
  setup_wifi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  client.setBufferSize(512);
  Serial.println("[7] MQTT client configured");
  
  Serial.println("\n=================================");
  Serial.println("Setup complete! Starting loop...");
  Serial.println("=================================\n");
  
  Serial.println("🤖 AUTO CONTROL SETTINGS:");
  Serial.print("   💧 Auto Watering: ");
  Serial.println(autoWateringEnabled ? "ENABLED" : "DISABLED");
  Serial.print("      └─ Trigger when soil < ");
  Serial.print(soilMoistureMin);
  Serial.println("%");
  Serial.print("   💡 Auto Lighting: ");
  Serial.println(autoLightingEnabled ? "ENABLED" : "DISABLED");
  Serial.print("      └─ Trigger when light < ");
  Serial.print(lightLevelMin);
  Serial.println(" Lux");
  Serial.println();
  
  Serial.println("📍 PIN MAPPING:");
  Serial.print("   LCD    - I2C0 (Wire): SDA=GPIO");
  Serial.print(I2C0_SDA);
  Serial.print(", SCL=GPIO");
  Serial.println(I2C0_SCL);
  Serial.print("   BH1750 - I2C1 (Wire1): SDA=GPIO");
  Serial.print(I2C1_SDA);
  Serial.print(", SCL=GPIO");
  Serial.println(I2C1_SCL);
  Serial.println();
}

// ===== Initialize LCD =====
void initLCD() {
  Serial.print("[5] Initializing LCD at 0x");
  Serial.print(LCD_ADDRESS, HEX);
  Serial.print(" on I2C Bus 0 (Wire)... ");
  
  // Check if LCD is connected
  Wire.beginTransmission(LCD_ADDRESS);
  byte error = Wire.endTransmission();
  
  if (error != 0) {
    Serial.print("✗ NOT FOUND (I2C error: ");
    Serial.print(error);
    Serial.println(")");
    Serial.println("    Try changing LCD_ADDRESS to 0x3F");
    lcd_initialized = false;
    return;
  }
  
  lcd.init();
  lcd.backlight();
  
  lcd.setCursor(0, 0);
  lcd.print("  TeraLux v3.1  ");
  lcd.setCursor(0, 1);
  lcd.print(" Separate I2C  ");
  
  delay(2000);
  
  Serial.println("✓ OK");
  lcd_initialized = true;
}

// ===== Initialize BH1750 =====
void initBH1750() {
  Serial.print("[6] Initializing BH1750 at 0x");
  Serial.print(BH1750_ADDRESS, HEX);
  Serial.print(" on I2C Bus 1 (Wire1)... ");
  
  I2C_BH1750.beginTransmission(BH1750_ADDRESS);
  byte error = I2C_BH1750.endTransmission();
  
  if (error != 0) {
    Serial.print("✗ NOT FOUND (I2C error: ");
    Serial.print(error);
    Serial.println(")");
    Serial.println("    ⚠️  BH1750 tidak terpasang - sistem akan jalan tanpa sensor cahaya");
    bh1750_initialized = false;
    return;
  }
  
  delay(10);
  
  if (lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE, BH1750_ADDRESS, &I2C_BH1750)) {
    Serial.println("✓ OK");
    bh1750_initialized = true;
    
    delay(200);
    float testRead = lightMeter.readLightLevel();
    Serial.print("    Test reading: ");
    Serial.print(testRead);
    Serial.println(" Lux");
  } else {
    Serial.println("✗ FAILED!");
    Serial.println("    ⚠️  BH1750 gagal init - sistem akan jalan tanpa sensor cahaya");
    bh1750_initialized = false;
  }
}

// ===== Update LCD Display =====
void updateLCD() {
  if (!lcd_initialized) return;
  
  lcd.clear();
  
  if (lcdPage == 0) {
    // Page 0: Sensor readings - KELEMBAPAN SAJA
    lcd.setCursor(0, 0);
    lcd.print("Light: ");
    lcd.print((int)lightLevel);
    lcd.print(" lx");
    
    lcd.setCursor(0, 1);
    lcd.print("Moisture: ");
    lcd.print((int)moisturePercent);
    lcd.print("%");
    
  } else if (lcdPage == 1) {
    // Page 1: Status & Connection
    lcd.setCursor(0, 0);
    if (pumpIsRunning) {
      unsigned long remaining = (pumpDuration - (millis() - pumpStartTime)) / 1000;
      lcd.print("PUMP: ");
      lcd.print(remaining);
      lcd.print("s    ");
    } else {
      lcd.print("Pump: ");
      lcd.print(pumpIsRunning ? "ON " : "OFF");
      lcd.print(" Lt:");
      lcd.print(lightIsOn ? "ON" : "OFF");
    }
    
    lcd.setCursor(0, 1);
    lcd.print("WiFi:");
    lcd.print(WiFi.status() == WL_CONNECTED ? "OK" : "NO");
    lcd.print(" MQTT:");
    lcd.print(client.connected() ? "OK" : "NO");
    
  } else if (lcdPage == 2) {
    // Page 2: Auto Control Status
    lcd.setCursor(0, 0);
    lcd.print("Auto Control");
    
    lcd.setCursor(0, 1);
    lcd.print("Water:");
    lcd.print(autoWateringEnabled ? "ON" : "OFF");
    lcd.print(" Lt:");
    lcd.print(autoLightingEnabled ? "ON" : "OFF");
  }
}

// ===== Main Loop =====
void loop() {
  unsigned long currentMillis = millis();
  
  // Try to reinitialize BH1750 if failed
  static int bh1750RetryCount = 0;
  if (!bh1750_initialized && bh1750RetryCount < 3 && (currentMillis - lastBH1750Retry >= bh1750RetryInterval)) {
    lastBH1750Retry = currentMillis;
    bh1750RetryCount++;
    Serial.print("\n[!] Retrying BH1750 initialization (attempt ");
    Serial.print(bh1750RetryCount);
    Serial.println("/3)...");
    initBH1750();
    if (!bh1750_initialized && bh1750RetryCount >= 3) {
      Serial.println("    ℹ️  Giving up on BH1750 - continuing without light sensor");
    }
  }
  
  // Maintain MQTT connection
  if (!client.connected()) {
    reconnect_mqtt();
  } else {
    client.loop();
  }
  
  // Read sensors periodically
  if (currentMillis - lastSensorRead >= sensorReadInterval) {
    lastSensorRead = currentMillis;
    readSensors();
  }
  
  // Publish sensor data periodically
  if (currentMillis - lastMqttPublish >= mqttPublishInterval) {
    lastMqttPublish = currentMillis;
    if (client.connected()) {
      publishSensorData();
    }
  }
  
  // Update LCD display
  if (currentMillis - lastLcdUpdate >= lcdUpdateInterval) {
    lastLcdUpdate = currentMillis;
    updateLCD();
    
    // Toggle page every 5 seconds (3 pages)
    static int pageCounter = 0;
    pageCounter++;
    if (pageCounter >= 5) {
      pageCounter = 0;
      lcdPage = (lcdPage + 1) % 3;  // 3 pages: 0, 1, 2
    }
  }
  
  // Handle pump timer
  handlePumpControl();
  
  // Check auto control
  if (currentMillis - lastAutoCheck >= autoCheckInterval) {
    lastAutoCheck = currentMillis;
    checkAutoControl();
  }
  
  // Blink status LED
  static unsigned long lastBlink = 0;
  if (currentMillis - lastBlink >= 1000) {
    lastBlink = currentMillis;
    digitalWrite(STATUS_LED_PIN, !digitalRead(STATUS_LED_PIN));
  }
}

// ===== WiFi Connection =====
void setup_wifi() {
  Serial.print("[8] Connecting to WiFi: ");
  Serial.println(ssid);
  
  if (lcd_initialized) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Connecting WiFi");
  }
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    
    if (lcd_initialized) {
      lcd.setCursor(attempts % 16, 1);
      lcd.print(".");
    }
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[8] WiFi connected!");
    Serial.print("    IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("    RSSI: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    
    if (lcd_initialized) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("WiFi Connected!");
      lcd.setCursor(0, 1);
      lcd.print(WiFi.localIP());
      delay(2000);
    }
  } else {
    Serial.println("\n[8] WiFi FAILED!");
    
    if (lcd_initialized) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("WiFi Failed!");
      delay(2000);
    }
  }
}

// ===== MQTT Connection =====
void reconnect_mqtt() {
  unsigned long currentMillis = millis();
  
  if (currentMillis - lastMqttReconnectAttempt < mqttReconnectInterval) {
    return;
  }
  
  lastMqttReconnectAttempt = currentMillis;
  
  Serial.print("MQTT connecting... ");
  
  String clientId = "TeraLux-";
  clientId += String(random(0xffff), HEX);
  
  if (client.connect(clientId.c_str(), mqtt_user, mqtt_password)) {
    Serial.println("✓ Connected!");
    
    client.subscribe(topic_pump_control);
    client.subscribe(topic_light_control);
    client.subscribe(topic_threshold_settings);
    client.subscribe(topic_calibration);
    
    publishPumpStatus();
    publishLightStatus();
    
  } else {
    Serial.print("✗ Failed (");
    Serial.print(client.state());
    Serial.println(")");
  }
}

// ===== MQTT Callback =====
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("\n[MQTT] ");
  Serial.print(topic);
  Serial.print(": ");
  
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);
  
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("JSON error: ");
    Serial.println(error.c_str());
    return;
  }
  
  // Handle Pump Control
  if (strcmp(topic, topic_pump_control) == 0) {
    String mode = doc["mode"].as<String>();
    
    if (mode == "start") {
      int duration = doc["duration"].as<int>();
      bool isManual = doc.containsKey("manual") ? doc["manual"].as<bool>() : false;
      
      pumpIsRunning = true;
      pumpManualMode = isManual;
      pumpStartTime = millis();
      pumpDuration = duration * 1000;
      
      digitalWrite(PUMP_RELAY_PIN, LOW);
      Serial.print("💧 Pump ON (");
      Serial.print(duration);
      Serial.print("s) - Mode: ");
      Serial.println(isManual ? "MANUAL" : "AUTO");
      
      publishPumpStatus();
      
    } else if (mode == "stop") {
      pumpIsRunning = false;
      pumpManualMode = false;
      digitalWrite(PUMP_RELAY_PIN, HIGH);
      Serial.println("💧 Pump OFF");
      
      publishPumpStatus();
    }
  }
  
  // Handle Light Control
  if (strcmp(topic, topic_light_control) == 0) {
    bool isOn = doc["isLightOn"].as<bool>();
    bool isManual = doc.containsKey("manual") ? doc["manual"].as<bool>() : false;
    
    lightIsOn = isOn;
    lightManualMode = isManual;
    digitalWrite(LIGHT_RELAY_PIN, isOn ? LOW : HIGH);
    
    Serial.print("💡 Light ");
    Serial.print(isOn ? "ON" : "OFF");
    Serial.print(" - Mode: ");
    Serial.println(isManual ? "MANUAL" : "AUTO");
    
    publishLightStatus();
  }
  
  // Handle Threshold Settings
  if (strcmp(topic, topic_threshold_settings) == 0) {
    soilMoistureMin = doc["soilMoistureMin"].as<float>();
    lightLevelMin = doc["lightLevelMin"].as<float>();
    autoWateringEnabled = doc["autoWateringEnabled"].as<bool>();
    autoLightingEnabled = doc["autoLightingEnabled"].as<bool>();
    wateringDuration = doc["wateringDuration"].as<int>();
    
    if (doc.containsKey("moistureSlope")) {
      moistureSlope = doc["moistureSlope"].as<float>();
      moistureIntercept = doc["moistureIntercept"].as<float>();
    }
    
    if (doc.containsKey("soilDryValue")) {
      soilDryValue = doc["soilDryValue"].as<int>();
      soilWetValue = doc["soilWetValue"].as<int>();
    }
    
    Serial.println("\n⚙️  THRESHOLD SETTINGS UPDATED!");
    Serial.print("   💧 Auto Watering: ");
    Serial.println(autoWateringEnabled ? "ENABLED" : "DISABLED");
    Serial.print("      └─ Soil threshold: < ");
    Serial.print(soilMoistureMin);
    Serial.print("% (duration: ");
    Serial.print(wateringDuration);
    Serial.println("s)");
    Serial.print("   💡 Auto Lighting: ");
    Serial.println(autoLightingEnabled ? "ENABLED" : "DISABLED");
    Serial.print("      └─ Light threshold: < ");
    Serial.print(lightLevelMin);
    Serial.println(" Lux");
    Serial.println();
  }
  
  // Handle Calibration Settings
  if (strcmp(topic, topic_calibration) == 0) {
    if (doc.containsKey("soilDryValue") && doc.containsKey("soilWetValue")) {
      int newDryValue = doc["soilDryValue"].as<int>();
      int newWetValue = doc["soilWetValue"].as<int>();
      
      if (newDryValue > newWetValue && newDryValue <= 4095 && newWetValue >= 0) {
        soilDryValue = newDryValue;
        soilWetValue = newWetValue;
        
        Serial.println("\n🔧 CALIBRATION UPDATED!");
        Serial.print("   📊 Soil Dry Value (0%): ");
        Serial.println(soilDryValue);
        Serial.print("   📊 Soil Wet Value (100%): ");
        Serial.println(soilWetValue);
        
        rawMoistureValue = analogRead(SOIL_PIN);
        float testMoisture = map(rawMoistureValue, soilWetValue, soilDryValue, 100, 0);
        testMoisture = constrain(testMoisture, 0, 100);
        Serial.print("   🧪 Test - Raw: ");
        Serial.print(rawMoistureValue);
        Serial.print(" → Moisture: ");
        Serial.print(testMoisture);
        Serial.println("%");
      }
    }
  }
}

// ===== Read All Sensors =====
void readSensors() {
  // Read BH1750
  if (bh1750_initialized) {
    lightLevel = lightMeter.readLightLevel();
    
    if (lightLevel < 0) {
      Serial.println("⚠️  BH1750 read error");
      bh1750_initialized = false;
      lightLevel = 0;
    }
  } else {
    lightLevel = 0;
  }
  
  // Read Soil Moisture with averaging (20 samples untuk stabilitas)
  long sum = 0;
  for (int i = 0; i < 20; i++) {
    sum += analogRead(SOIL_PIN);
    delay(10);
  }
  rawMoistureValue = sum / 20;
  
  // Hitung kelembapan dalam persen
  moisturePercent = map(rawMoistureValue, soilWetValue, soilDryValue, 100, 0);
  moisturePercent = constrain(moisturePercent, 0, 100);
  
  // Tampilkan KELEMBAPAN saja (bukan raw value)
  Serial.print("💡 Light: ");
  Serial.print(lightLevel, 0);
  Serial.print(" Lux | 💧 Moisture: ");
  Serial.print(moisturePercent, 1);
  Serial.print("% ");
  
  // Status kelembapan
  if (moisturePercent <= 10) {
    Serial.println("(Sangat Kering)");
  } else if (moisturePercent <= 30) {
    Serial.println("(Kering)");
  } else if (moisturePercent <= 60) {
    Serial.println("(Normal)");
  } else if (moisturePercent <= 80) {
    Serial.println("(Lembab)");
  } else {
    Serial.println("(Basah)");
  }
}

// ===== Publish Sensor Data =====
void publishSensorData() {
  StaticJsonDocument<256> doc;
  
  // Gunakan moisturePercent global yang sudah dihitung
  float finalMoisture = moisturePercent;
  
  // Override jika ada kalibrasi slope/intercept
  if (moistureSlope != 1.0 || moistureIntercept != 0.0) {
    finalMoisture = rawMoistureValue * moistureSlope + moistureIntercept;
    finalMoisture = constrain(finalMoisture, 0, 100);
  }
  
  doc["lightLevel"] = round(lightLevel);
  doc["rawMoistureValue"] = rawMoistureValue;
  doc["moistureLevel"] = round(finalMoisture);
  doc["timestamp"] = millis();
  
  char buffer[256];
  serializeJson(doc, buffer);
  
  if (client.publish(topic_sensors, buffer, true)) {
    Serial.println("📤 Published to MQTT");
  }
}

// ===== Handle Pump Timer =====
void handlePumpControl() {
  if (pumpIsRunning) {
    unsigned long elapsed = millis() - pumpStartTime;
    
    static unsigned long lastStatusUpdate = 0;
    if (millis() - lastStatusUpdate >= 1000) {
      lastStatusUpdate = millis();
      publishPumpStatus();
    }
    
    if (elapsed >= pumpDuration) {
      pumpIsRunning = false;
      pumpManualMode = false;
      digitalWrite(PUMP_RELAY_PIN, HIGH);
      
      Serial.println("💧 Pump timer finished");
      publishPumpStatus();
    }
  }
}

// ===== Publish Pump Status =====
void publishPumpStatus() {
  StaticJsonDocument<128> doc;
  
  doc["isRunning"] = pumpIsRunning;
  doc["manual"] = pumpManualMode;
  
  if (pumpIsRunning) {
    unsigned long elapsed = millis() - pumpStartTime;
    unsigned long remaining = (pumpDuration > elapsed) ? (pumpDuration - elapsed) / 1000 : 0;
    doc["remainingSeconds"] = remaining;
  } else {
    doc["remainingSeconds"] = 0;
  }
  
  char buffer[128];
  serializeJson(doc, buffer);
  client.publish(topic_pump_status, buffer, true);
}

// ===== Publish Light Status =====
void publishLightStatus() {
  StaticJsonDocument<64> doc;
  
  doc["isLightOn"] = lightIsOn;
  doc["manual"] = lightManualMode;
  
  char buffer[64];
  serializeJson(doc, buffer);
  client.publish(topic_light_status, buffer, true);
}

// ===== Check Auto Control =====
void checkAutoControl() {
  float currentLight = lightLevel;
  
  // Gunakan moisturePercent global yang sudah dihitung
  float currentMoisture = moisturePercent;
  
  // Override jika ada kalibrasi slope/intercept
  if (moistureSlope != 1.0 || moistureIntercept != 0.0) {
    currentMoisture = rawMoistureValue * moistureSlope + moistureIntercept;
    currentMoisture = constrain(currentMoisture, 0, 100);
  }
  
  unsigned long currentTime = millis();
  
  // Auto Watering
  if (autoWateringEnabled && !pumpIsRunning && !pumpManualMode) {
    bool canWater = (currentTime - lastAutoWatering) > wateringCooldown;
    
    if (canWater && currentMoisture < soilMoistureMin) {
      Serial.println("\n🤖 AUTO WATERING!");
      Serial.print("   Current moisture: ");
      Serial.print(currentMoisture, 1);
      Serial.print("% < ");
      Serial.print(soilMoistureMin);
      Serial.println("%");
      
      pumpIsRunning = true;
      pumpManualMode = false;
      pumpStartTime = currentTime;
      pumpDuration = wateringDuration * 1000;
      lastAutoWatering = currentTime;
      
      digitalWrite(PUMP_RELAY_PIN, LOW);
      publishPumpStatus();
    }
  }
  
  // Auto Lighting
  if (autoLightingEnabled && !lightManualMode) {
    if (currentLight < lightLevelMin) {
      if (!lightIsOn) {
        Serial.println("\n🤖 AUTO LIGHT ON!");
        Serial.print("   Current light: ");
        Serial.print(currentLight, 0);
        Serial.print(" lux < ");
        Serial.print(lightLevelMin);
        Serial.println(" lux");
        
        lightIsOn = true;
        lightManualMode = false;
        digitalWrite(LIGHT_RELAY_PIN, LOW);
        publishLightStatus();
      }
    } else {
      if (lightIsOn) {
        Serial.println("\n🤖 AUTO LIGHT OFF!");
        Serial.print("   Current light: ");
        Serial.print(currentLight, 0);
        Serial.print(" lux >= ");
        Serial.print(lightLevelMin);
        Serial.println(" lux");
        
        lightIsOn = false;
        lightManualMode = false;
        digitalWrite(LIGHT_RELAY_PIN, HIGH);
        publishLightStatus();
      }
    }
  }
}