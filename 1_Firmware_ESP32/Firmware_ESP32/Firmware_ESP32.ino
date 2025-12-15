#include <Arduino.h>
#include <HX711.h>
#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <math.h>
#include <BLE2902.h>

/* ======================= Pins ======================= */
#define HX_DT           32
#define HX_SCK          33
#define BATT_ADC_PIN    34
#define BATT_CHARGING   -1
#define BATT_CHG_ACTIVE_HIGH 1

/* ================== Calibration & Limits ================== */
static float CAL_A = 210.0f;
static float CAL_B = 210.0f;

static const float   MAX_G      = 10000.0f;
static const uint32_t SEND_MS   = 500;
static const float   QUIET_EPS  = 20.0f;
static const uint32_t QUIET_MS  = 2500;

/* ======================= Battery ======================= */
#define DIV_FACTOR      2.0f
#define SAMPLES         16
static float emaV = NAN;
static const float alpha = 0.20f;

static int lastBatPct      = -1;
static int lastChg         = -1;
static uint32_t lastBatSentMs = 0;

/* ========================= BLE ========================= */
static const char* BLE_NAME = "ProGearBag";
#define UUID_SVC  "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define UUID_RX   "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"   // write
#define UUID_TX   "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"   // notify

/* ====================== Globals ====================== */
HX711        scale;
Preferences  prefs;

BLECharacteristic* txCh = nullptr;
BLECharacteristic* rxCh = nullptr;
String rxBuf;

long  offsetA = 0;
long  offsetB = 0;

float expectedG = 0.0f;      // [NVS] expected weight
float lastG     = -1.0f;
uint32_t lastSend   = 0;
uint32_t quietStart = 0;
bool inQuiet = false, sessionFinalSent = false;


/* ==================== COOLDOWN ==================== */
static uint32_t lastOverCapMs  = 0;
static uint32_t lastNotReadyMs = 0;
static const uint32_t ERR_COOLDOWN_MS      = 2000;
static const uint32_t NOTREADY_COOLDOWN_MS = 2000;

/* ==================== Messaging ==================== */
/**
 * FINAL Protocol:
 * TAG:JSON\n
 * أمثلة:
 *  WEIGHT_DATA:{"g":123.4}
 *  SESSION_FINAL:{"g":123.4}
 *  STATUS_UPDATE:{"state":"tare_done"}
 *  BATTERY:{"percent":80,"chg":1}
 */
static void sendLine(const String& tag, const String& json) {
  String s = tag + ":" + json + "\n";
  Serial.print(s);
  if (txCh) {
    txCh->setValue((uint8_t*)s.c_str(), s.length());
    txCh->notify();
  }
}


static void sendStatus(const String& st) {
  sendLine("STATUS_UPDATE", String("{\"state\":\"") + st + "\"}");
}
static void sendStatusExpected(float g) {
  sendLine("STATUS_UPDATE", String("{\"expected_weight_g\":") + String(g,0) + "}");
}
static void sendError(const String& msg) {
  sendLine("ERROR", String("{\"msg\":\"") + msg + "\"}");
}
static void sendWeight(float g) {
  sendLine("WEIGHT_DATA", String("{\"g\":") + String(g,1) + "}");
}
static void sendSessionFinal(float g) {
  sendLine("SESSION_FINAL", String("{\"g\":") + String(g,1) + "}");
}
static void sendBatteryMsg(int pct, int ch) {
  sendLine("BATTERY", String("{\"percent\":") + pct + ",\"chg\":" + ch + "}");
}

/* ==================== NVS: expected ==================== */
static void saveExpected(float g){
  expectedG = g;
  prefs.putFloat("exp_g", expectedG);
  sendStatusExpected(expectedG);
}

/* ==================== Battery Read ==================== */
static int readBatteryPct() {
  if (BATT_ADC_PIN < 0) return -1;

  analogReadResolution(12);
  uint32_t acc = 0;
  for (int i = 0; i < SAMPLES; i++) {
    acc += analogRead(BATT_ADC_PIN);
    delay(2);
  }
  int raw = acc / SAMPLES;

  float vadc = (raw / 4095.0f) * 3.3f;
  float v    = vadc * DIV_FACTOR;

  // EMA تنعيم
  if (isnan(emaV)) emaV = v;
  else emaV = alpha * v + (1.0f - alpha) * emaV;

  // خريطة خطية 3.4..4.2V -> 0..100%
  float pctf = (emaV - 3.40f) / (4.20f - 3.40f) * 100.0f;
  return (int)round(constrain(pctf, 0.0f, 100.0f));
}

static int readCharging() {
  if (BATT_CHARGING < 0) return 0;
  pinMode(BATT_CHARGING, INPUT_PULLUP);
  int raw = digitalRead(BATT_CHARGING);
  return BATT_CHG_ACTIVE_HIGH ? (raw ? 1 : 0) : (raw ? 0 : 1);
}


// ==================== Battery (smart anti-spam) ====================
static void maybeSendBattery(uint32_t now, bool force=false){
  if (BATT_ADC_PIN < 0) return;

  int p = readBatteryPct();
  if (p < 0) return;

  int chg = readCharging();

  const uint32_t MIN_INTERVAL_MS  = 5000;

  bool timeOk = (now - lastBatSentMs >= MIN_INTERVAL_MS);

  if (force || timeOk) {
    sendBatteryMsg(p, chg);
    lastBatPct    = p;
    lastChg       = chg;
    lastBatSentMs = now;
  }
}

/* ==================== HX711 Helpers ==================== */
static long readChannelRaw(byte gain, uint8_t samples) {
  scale.set_gain(gain);
  delay(80);
  return scale.read_average(samples);
}

static void tareBoth() {
  offsetA = readChannelRaw(128, 20);
  offsetB = readChannelRaw(32,  20);
}

static float rawA_to_grams(long rawA) {
  long net = rawA - offsetA;
  return (float)net / CAL_A;
}

static float rawB_to_grams(long rawB) {
  long net = rawB - offsetB;
  return (float)net / CAL_B;
}

static float readWeightA_g() {
  long rawA = readChannelRaw(128, 10);
  return rawA_to_grams(rawA);
}

static float readWeightB_g() {
  long rawB = readChannelRaw(32, 10);
  return rawB_to_grams(rawB);
}

static float readTotalGrams() {
  float a_g = readWeightA_g();
  float b_g = readWeightB_g();
  float total = a_g + b_g;

  if (fabs(total) < 2.0f) total = 0.0f;

  return total;
}

/* ===================== BLE RX callbacks ================= */
class RxCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    String v = c->getValue();
    if (v.length() == 0) return;
    rxBuf += v;

    int idx;
    while ((idx = rxBuf.indexOf('\n')) >= 0) {
      String line = rxBuf.substring(0, idx);
      rxBuf.remove(0, idx+1);
      line.trim();
      if (line.length() == 0) continue;

      String U = line;
      U.toUpperCase();

      if (U == "PING") {
        sendStatus("pong");
      }
      else if (U == "RESET_WEIGHT") {
        tareBoth();
        lastG = -1.0f;
        inQuiet = false;
        sessionFinalSent = false;
        sendStatus("tare_done");
        sendStatus("baseline_reset");
      }
      else if (U.startsWith("SET_EXPECTED_WEIGHT:")) {
        int colon = line.indexOf(':');
        if (colon > 0) {
          float val = line.substring(colon+1).toFloat();
          saveExpected(val);
        }
      }
      else if (U == "GET_EXPECTED_WEIGHT") {
        sendStatusExpected(expectedG);
      }
      else if (U == "GET_BAT") {
        maybeSendBattery(millis(), /*force=*/true);
      }
      else if (U == "GET_WEIGHT") {
        float g = readTotalGrams();
        //if (g < 0) sendStatus("scale_not_ready");
        //else       sendWeight(g);
      }
    }
  }
};


/* ===================== BLE Server callbacks ================= */
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    sendStatus("ble_connected");

    lastBatPct      = -1;
    lastChg         = -1;
    lastBatSentMs   = 0;
  }

  void onDisconnect(BLEServer* pServer) override {
    sendStatus("ble_disconnected");
    BLEAdvertising *adv = BLEDevice::getAdvertising();
    adv->start();
  }
};

/* ========================== setup ======================= */
void setup() {
  Serial.begin(115200);
  delay(100);

  prefs.begin("progear", false);
  expectedG = prefs.getFloat("exp_g", 0.0f);

  scale.begin(HX_DT, HX_SCK);
  (void)scale.read();

  tareBoth();

  float g0 = 0.0f;
  for (int i = 0; i < 5; i++) {
    g0 = readTotalGrams();
    delay(200);
  }
  if (fabs(g0) > 5.0f) {
    tareBoth();
    g0 = readTotalGrams();
  }

  sendStatus("scale_ready");
  sendStatus("tare_done");
  sendWeight(0.0f);

  // BLE init
  BLEDevice::init(BLE_NAME);
  BLEServer* srv = BLEDevice::createServer();
  srv->setCallbacks(new MyServerCallbacks());

  BLEService* svc = srv->createService(UUID_SVC);

  txCh = svc->createCharacteristic(
      UUID_TX,
      BLECharacteristic::PROPERTY_NOTIFY
  );

  txCh->addDescriptor(new BLE2902());

  rxCh = svc->createCharacteristic(
      UUID_RX,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  rxCh->setCallbacks(new RxCB());

  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(UUID_SVC);
  adv->setScanResponse(true);
  adv->start();

  sendStatus("ble_advertising");

  if (expectedG > 0) {
    sendStatusExpected(expectedG);
  }

  maybeSendBattery(millis(), /*force=*/true);
}

/* =========================== loop ======================= */
void loop() {
  uint32_t now = millis();

  if (now - lastSend >= SEND_MS) {
    float g = readTotalGrams();
    if (isnan(g)) g = -1.0f;

    if (g < 0) {
      if (now - lastNotReadyMs > NOTREADY_COOLDOWN_MS) {
        sendStatus("scale_not_ready");
        lastNotReadyMs = now;
      }
    } else {
      if (g > MAX_G) {
        if (now - lastOverCapMs > ERR_COOLDOWN_MS) {
          sendError("over_capacity");
          lastOverCapMs = now;
        }
      } else {
        if (lastG < 0 || fabsf(g - lastG) >= 1.0f) {
          sendWeight(g);
        }

        bool stable = (lastG >= 0) && (fabsf(g - lastG) <= QUIET_EPS);
        if (stable) {
          if (!inQuiet) {
            inQuiet = true;
            quietStart = now;
            sessionFinalSent = false;
          } else if (!sessionFinalSent && (now - quietStart) >= QUIET_MS) {
            sendSessionFinal(g);
            sessionFinalSent = true;
          }
        } else {
          inQuiet = false;
          sessionFinalSent = false;
          quietStart = now;
        }
        lastG = g;
      }
    }

    lastSend = now;
  }

 if (now - lastBatSentMs >= 5000) {
  maybeSendBattery(now, /*force=*/true);
}
}