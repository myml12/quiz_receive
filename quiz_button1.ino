/*
 * 早押しクイズ用 BLE ボタン (1台目)
 * XIAO ESP32S3 用 / デバイス名: button1
 * タクトスイッチ押下で Notify 送信 → iPad が受信順で検知
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define BUTTON_PIN D4

static const char* BLE_DEVICE_NAME = "button1";
static const char* UUID_SERVICE = "e3b01001-8a0f-4a3b-9c8a-1b2c3d4e5f01";
static const char* UUID_CHAR_NOTIFY = "e3b01002-8a0f-4a3b-9c8a-1b2c3d4e5f01";

BLEServer* bleServer = nullptr;
BLECharacteristic* notifyChar = nullptr;
bool deviceConnected = false;
bool oldDeviceConnected = false;

int buttonStatus = 1; // PULLUP: 通常 HIGH
unsigned long lastPressMs = 0;
const unsigned long DEBOUNCE_MS = 200;

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("クライアント接続");
  }
  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("クライアント切断");
  }
};

void setup() {
  Serial.begin(115200);
  delay(200);
  Serial.println("=== 早押しクイズ ボタン1 (button1) ===");

  pinMode(BUTTON_PIN, INPUT_PULLUP);
  buttonStatus = digitalRead(BUTTON_PIN);

  BLEDevice::init(BLE_DEVICE_NAME);
  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new ServerCallbacks());

  BLEService* service = bleServer->createService(UUID_SERVICE);
  notifyChar = service->createCharacteristic(
    UUID_CHAR_NOTIFY,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  notifyChar->addDescriptor(new BLE2902());
  uint8_t initv[1] = {0x00};
  notifyChar->setValue(initv, 1);
  service->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(UUID_SERVICE);
  adv->setScanResponse(true);
  adv->setMinPreferred(0x06);
  adv->setMaxPreferred(0x12);

  BLEAdvertisementData ad;
  ad.setName(BLE_DEVICE_NAME);
  ad.setCompleteServices(BLEUUID(UUID_SERVICE));
  adv->setAdvertisementData(ad);

  BLEDevice::startAdvertising();
  Serial.println("BLE advertising start (button1)");
}

void loop() {
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    bleServer->startAdvertising();
    Serial.println("再広告開始");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  int current = digitalRead(BUTTON_PIN);
  unsigned long now = millis();
  if (current != buttonStatus && current == LOW && (now - lastPressMs) >= DEBOUNCE_MS) {
    lastPressMs = now;
    if (deviceConnected && notifyChar) {
      uint8_t payload[1] = {0x01};
      notifyChar->setValue(payload, 1);
      notifyChar->notify();
      Serial.println("Notify sent (pressed)");
    }
  }
  buttonStatus = current;

  delay(20);
}
