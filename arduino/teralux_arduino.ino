/*
 * TeraLux - Arduino IoT Greenhouse Controller
 * 
 * Features:
 * - Temperature Sensor (DHT22)
 * - Light Sensor (LDR/Photoresistor)
 * - Soil Moisture Sensor
 * - Water Pump Control with Timer
 * - Light/Relay Control
 * - MQTT Communication
 * 
 * Hardware Connections:
 * - DHT22 -> Pin 2
 * - LDR -> Analog Pin A0
 * - Soil Moisture Sensor -> Analog Pin A1
 * - Pump Relay -> Pin 7
 * - Light Relay -> Pin 8
 * - LED Status -> Pin 13
 */

#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// ===== WiFi Configuration =====
const char* ssid = "YOUR_WIFI_SSID";          // Ganti dengan SSID WiFi Anda
const char* password = "YOUR_WIFI_PASSWORD";   // Ganti dengan password WiFi Anda

// ===== MQTT Configuration =====
const char* mqtt_server = "broker.hivemq.com"; // Ganti dengan broker MQTT Anda
const int mqtt_port = 1883;
const char* mqtt_user = "";                    // Kosongkan jika tidak pakai autentikasi
const char* mqtt_password = "";

// MQTT Topics
const char* topic_sensors = "teralux/sensors";
const char* topic_pump_control = "teralux/pump/control";
const char* topic_pump_status = "teralux/pump/status";
const char* topic_light_control = "teralux/light/control";
const char* topic_light_status = "teralux/light/status";

// ===== Pin Configuration =====
#define DHT_PIN 2           // DHT22 Temperature & Humidity Sensor
#define DHT_TYPE DHT22
#define LDR_PIN A0          // Light Dependent Resistor (Analog)
#define SOIL_PIN A1         // Soil Moisture Sensor (Analog)
#define PUMP_RELAY_PIN 7    // Water Pump Relay
#define LIGHT_RELAY_PIN 8   // Light Relay
#define STATUS_LED_PIN 13   // Built-in LED for status

// ===== Sensor Objects =====
DHT dht(DHT_PIN, DHT_TYPE);
WiFiClient espClient;
PubSubClient client(espClient);

// ===== Global Variables =====
// Sensor readings
float temperature = 0.0;
float humidity = 0.0;
int rawLightValue = 0;
int rawMoistureValue = 0;

// Control states
bool pumpIsRunning = false;
unsigned long pumpStartTime = 0;
unsigned long pumpDuration = 0;

bool lightIsOn = false;

// Timing
unsigned long lastSensorRead = 0;
unsigned long lastMqttPublish = 0;
const unsigned long sensorReadInterval = 2000;   // Baca sensor setiap 2 detik
const unsigned long mqttPublishInterval = 5000;  // Kirim data setiap 5 detik

// ===== Function Prototypes =====
void setup_wifi();
void reconnect_mqtt();
void callback(char* topic, byte* payload, unsigned int length);
void readSensors();
void publishSensorData();
void handlePumpControl();
void publishPumpStatus();
void publishLightStatus();

// ===== Setup Function =====
void setup() {
  Serial.begin(115200);
  delay(10);
  
  Serial.println("\n\n=================================");
  Serial.println("   TeraLux Arduino Controller   ");
  Serial.println("=================================\n");
  
  // Initialize pins
  pinMode(PUMP_RELAY_PIN, OUTPUT);
  pinMode(LIGHT_RELAY_PIN, OUTPUT);
  pinMode(STATUS_LED_PIN, OUTPUT);
  
  // Set relays to OFF initially (active LOW for most relay modules)
  digitalWrite(PUMP_RELAY_PIN, HIGH);
  digitalWrite(LIGHT_RELAY_PIN, HIGH);
  digitalWrite(STATUS_LED_PIN, LOW);
  
  // Initialize DHT sensor
  dht.begin();
  Serial.println("DHT22 initialized");
  
  // Connect to WiFi
  setup_wifi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  
  Serial.println("Setup complete!\n");
}

// ===== Main Loop =====
void loop() {
  // Maintain MQTT connection
  if (!client.connected()) {
    reconnect_mqtt();
  }
  client.loop();
  
  unsigned long currentMillis = millis();
  
  // Read sensors periodically
  if (currentMillis - lastSensorRead >= sensorReadInterval) {
    lastSensorRead = currentMillis;
    readSensors();
  }
  
  // Publish sensor data periodically
  if (currentMillis - lastMqttPublish >= mqttPublishInterval) {
    lastMqttPublish = currentMillis;
    publishSensorData();
  }
  
  // Handle pump timer
  handlePumpControl();
  
  // Blink status LED when connected
  static unsigned long lastBlink = 0;
  if (currentMillis - lastBlink >= 1000) {
    lastBlink = currentMillis;
    digitalWrite(STATUS_LED_PIN, !digitalRead(STATUS_LED_PIN));
  }
}

// ===== WiFi Connection =====
void setup_wifi() {
  delay(10);
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal strength (RSSI): ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm\n");
  } else {
    Serial.println("\nWiFi connection failed!");
  }
}

// ===== MQTT Connection =====
void reconnect_mqtt() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT broker...");
    
    String clientId = "TeraLux-";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_password)) {
      Serial.println(" connected!");
      
      // Subscribe to control topics
      client.subscribe(topic_pump_control);
      client.subscribe(topic_light_control);
      
      Serial.println("Subscribed to control topics\n");
      
      // Publish initial status
      publishPumpStatus();
      publishLightStatus();
      
    } else {
      Serial.print(" failed, rc=");
      Serial.print(client.state());
      Serial.println(" retrying in 5 seconds...");
      delay(5000);
    }
  }
}

// ===== MQTT Callback =====
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  
  // Convert payload to string
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);
  
  // Parse JSON
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("JSON parse failed: ");
    Serial.println(error.c_str());
    return;
  }
  
  // Handle Pump Control
  if (strcmp(topic, topic_pump_control) == 0) {
    String mode = doc["mode"].as<String>();
    
    if (mode == "start") {
      int duration = doc["duration"].as<int>();
      pumpIsRunning = true;
      pumpStartTime = millis();
      pumpDuration = duration * 1000; // Convert to milliseconds
      
      digitalWrite(PUMP_RELAY_PIN, LOW); // Active LOW relay
      
      Serial.print("Pump started for ");
      Serial.print(duration);
      Serial.println(" seconds");
      
      publishPumpStatus();
      
    } else if (mode == "stop") {
      pumpIsRunning = false;
      digitalWrite(PUMP_RELAY_PIN, HIGH);
      
      Serial.println("Pump stopped manually");
      
      publishPumpStatus();
    }
  }
  
  // Handle Light Control
  if (strcmp(topic, topic_light_control) == 0) {
    bool isOn = doc["isOn"].as<bool>();
    
    lightIsOn = isOn;
    digitalWrite(LIGHT_RELAY_PIN, isOn ? LOW : HIGH); // Active LOW relay
    
    Serial.print("Light turned ");
    Serial.println(isOn ? "ON" : "OFF");
    
    publishLightStatus();
  }
}

// ===== Read All Sensors =====
void readSensors() {
  // Read DHT22 (Temperature & Humidity)
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  
  if (!isnan(temp) && !isnan(hum)) {
    temperature = temp;
    humidity = hum;
  } else {
    Serial.println("Failed to read DHT sensor!");
  }
  
  // Read Light Sensor (LDR)
  rawLightValue = analogRead(LDR_PIN);
  
  // Read Soil Moisture Sensor
  rawMoistureValue = analogRead(SOIL_PIN);
  
  // Debug output
  Serial.print("Temp: ");
  Serial.print(temperature);
  Serial.print("°C | Humidity: ");
  Serial.print(humidity);
  Serial.print("% | Light: ");
  Serial.print(rawLightValue);
  Serial.print(" | Moisture: ");
  Serial.println(rawMoistureValue);
}

// ===== Publish Sensor Data via MQTT =====
void publishSensorData() {
  StaticJsonDocument<256> doc;
  
  doc["temperature"] = round(temperature * 10) / 10.0; // Round to 1 decimal
  doc["humidity"] = round(humidity * 10) / 10.0;
  doc["rawLightValue"] = rawLightValue;
  doc["rawMoistureValue"] = rawMoistureValue;
  doc["timestamp"] = millis();
  
  char buffer[256];
  serializeJson(doc, buffer);
  
  if (client.publish(topic_sensors, buffer)) {
    Serial.println("Sensor data published");
  } else {
    Serial.println("Failed to publish sensor data");
  }
}

// ===== Handle Pump Timer Control =====
void handlePumpControl() {
  if (pumpIsRunning) {
    unsigned long elapsed = millis() - pumpStartTime;
    
    if (elapsed >= pumpDuration) {
      // Timer finished
      pumpIsRunning = false;
      digitalWrite(PUMP_RELAY_PIN, HIGH);
      
      Serial.println("Pump timer finished");
      
      publishPumpStatus();
    }
  }
}

// ===== Publish Pump Status =====
void publishPumpStatus() {
  StaticJsonDocument<128> doc;
  
  doc["isRunning"] = pumpIsRunning;
  
  if (pumpIsRunning) {
    unsigned long elapsed = millis() - pumpStartTime;
    unsigned long remaining = (pumpDuration > elapsed) ? (pumpDuration - elapsed) / 1000 : 0;
    doc["remainingSeconds"] = remaining;
  } else {
    doc["remainingSeconds"] = 0;
  }
  
  char buffer[128];
  serializeJson(doc, buffer);
  
  client.publish(topic_pump_status, buffer);
}

// ===== Publish Light Status =====
void publishLightStatus() {
  StaticJsonDocument<64> doc;
  
  doc["isOn"] = lightIsOn;
  
  char buffer[64];
  serializeJson(doc, buffer);
  
  client.publish(topic_light_status, buffer);
}
