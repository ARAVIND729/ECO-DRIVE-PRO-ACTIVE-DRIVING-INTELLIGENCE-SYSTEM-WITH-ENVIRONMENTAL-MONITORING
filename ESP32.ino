#include <WiFi.h>
#include "ThingSpeak.h"
#include "DHT.h"

// ---------------- WIFI ----------------
const char* ssid = "";
const char* password = "";

WiFiClient client;

// ---------------- THINGSPEAK ----------------
unsigned long myChannelNumber = 32522;
const char* myWriteAPIKey = "W228MHJ3D5GKZ";

// ---------------- TIMER ----------------
unsigned long lastTime = 0;
unsigned long timerDelay = 30000;

// ---------------- PINS ----------------
const int memsPin = 34;
const int gasPin = 35;
const int voltagePin = 32;
const int currentPin = 33;
const int irPin = 27;
#define RF_D0 23

#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// ---------------- VARIABLES ----------------
int memsValue = 0;
int gasValue = 0;
float voltageValue = 0;
float currentValue = 0;
float temperature = 0;
float humidity = 0;
int irStatus = 0;

// -------- ADC AVERAGING --------
int readADC(int pin) {
  long sum = 0;
  for (int i = 0; i < 20; i++) {
    sum += analogRead(pin);
    delay(2);
  }
  return sum / 20;
}

// -------- WIFI RECONNECT --------
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;

  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected");
  } else {
    Serial.println("\nWiFi failed");
  }
}

void setup() {

  Serial.begin(115200);

  pinMode(irPin, INPUT_PULLUP);
  pinMode(RF_D0, OUTPUT);

  analogSetAttenuation(ADC_11db);  // 0–3.3V

  dht.begin();

  WiFi.mode(WIFI_STA);
  connectWiFi();

  ThingSpeak.begin(client);
}

void loop() {

  // -------- WIFI CHECK --------
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  // -------- IR + RF --------
  irStatus = digitalRead(irPin);

  if (irStatus == LOW) {
    digitalWrite(RF_D0, HIGH);
  } else {
    digitalWrite(RF_D0, LOW);
  }

  if ((millis() - lastTime) > timerDelay) {

    // -------- MEMS --------
    memsValue = readADC(memsPin);

    // -------- GAS --------
    gasValue = readADC(gasPin);

    // -------- VOLTAGE --------
    int rawVoltage = readADC(voltagePin);
    float Vout = (rawVoltage / 4095.0) * 3.3;
    voltageValue = Vout * 5.0;   // 5:1 divider

    // -------- CURRENT (same logic, but stabilized) --------
    int rawCurrent = readADC(currentPin);
    currentValue = (rawCurrent / 4095.0) * 3.3;

    // -------- DHT --------
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();

    if (!isnan(temp)) temperature = temp;
    if (!isnan(hum)) humidity = hum;

    if (isnan(temp) || isnan(hum)) {
      Serial.println("DHT read failed (using last valid values)");
    }

    // -------- DEBUG --------
    Serial.println("----- Sensor Readings -----");
    Serial.print("MEMS: "); Serial.println(memsValue);
    Serial.print("GAS: "); Serial.println(gasValue);
    Serial.print("Temperature: "); Serial.println(temperature);
    Serial.print("Humidity: "); Serial.println(humidity);
    Serial.print("Voltage: "); Serial.println(voltageValue);
    Serial.print("Current: "); Serial.println(currentValue);
    Serial.print("IR: "); Serial.println(irStatus);
    Serial.println("---------------------------");

    // -------- THINGSPEAK --------
    ThingSpeak.setField(1, memsValue);
    ThingSpeak.setField(2, gasValue);
    ThingSpeak.setField(3, temperature);
    ThingSpeak.setField(4, humidity);
    ThingSpeak.setField(5, voltageValue);
    ThingSpeak.setField(6, currentValue);
    ThingSpeak.setField(7, irStatus);

    int x = ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);

    if (x == 200) {
      Serial.println("ThingSpeak update OK");
    } else {
      Serial.println("ThingSpeak error: " + String(x));
    }

    lastTime = millis();
  }
}
