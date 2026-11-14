/*
 * Braillix — bare-motor letter test
 *
 * Type a letter (or a word) in the Serial Monitor and the cam turns to that
 * character's state. No linkages, no cell, no disc required: this proves the
 * ESP32, the ULN2003, the motor, the encoding and the homing path all work
 * before any of it is bolted to a mechanism.
 *
 * Board:     ESP32 Dev Module (30-pin, USB-C)
 * Library:   AccelStepper (Mike McCauley) — Library Manager
 * Serial:    115200 baud, "Newline" line ending
 *
 * Deliberately no WiFi and no OTA. secrets.h is not needed. The point of this
 * sketch is the shortest possible path to a turning motor.
 *
 * Wiring (identical to docs/BREADBOARD_STEP_BY_STEP.md):
 *   ULN2003 IN1 -> GPIO 18       ULN2003 (+) -> 5V rail (adapter)
 *   ULN2003 IN2 -> GPIO 19       ULN2003 (-) -> GND rail
 *   ULN2003 IN3 -> GPIO 21       A3144 OUT   -> GPIO 34, 10k pull-up to 3V3
 *   ULN2003 IN4 -> GPIO 22       A3144 VCC   -> 3V3, A3144 GND -> GND
 *   ESP32 GND   -> GND rail  <-- the one wire that must not be missed
 *
 * GPIO 34 is input-only and has NO internal pull-up. The A3144 is open
 * collector, so without the external 10k the pin floats and homing is noise.
 */

#include <AccelStepper.h>
#include <Preferences.h>
#include <WiFi.h>
#include <WebServer.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- BLUETOOTH LOW ENERGY -------------------------------------------------
// Nordic UART Service UUIDs. Not a standard, but the de-facto one every tool
// and library already knows, so a generic BLE terminal app can drive the cell
// too - useful for debugging without the simulator.
#define NUS_SERVICE "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define NUS_RX      "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"   // browser -> board
#define NUS_TX      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"   // board -> browser
const char* BLE_NAME = "Braillix-Cell";

BLECharacteristic* bleTx = nullptr;
volatile bool bleConnected = false;
String bleLine;                      // commands arrive whole, but never assume it

// --- WIRELESS -------------------------------------------------------------
// The board makes its OWN network. No router, no lab wifi, no credentials to
// beg for, and it works in a room with no internet at all. The laptop joins
// this AP and loses its internet for the duration - which is fine, because the
// simulator is served from localhost.
//
// NOT a personal secret: this is a throwaway AP password for a demo device on
// a network with one client. Change it if you like; nothing else depends on it.
const char* AP_SSID = "Braillix-Cell";
const char* AP_PASS = "braillix2026";     // >= 8 chars or softAP() opens it wide
// WiFi is now OFF by default. It cannot be reached from a GitHub Pages page at
// all: that page is https, the board is plain http, and browsers block mixed
// content. BLE has no such problem, and it does not take the laptop off its own
// network the way joining the AP does. Turn this back on only for a localhost demo.
const bool  USE_WIFI = false;
const bool  USE_BLE  = true;

WebServer server(80);

#define IN1 18
#define IN2 19
#define IN3 21          // NOTE: GPIO21/22 are the default I2C pins. Fine now;
#define IN4 22          // must move before the MCP23017 goes in (multi-cell).
#define HALL_PIN 34

AccelStepper stepper(AccelStepper::HALF4WIRE, IN1, IN3, IN2, IN4);

// --- from sim/3d/braillix_params.json — keep these in step with the simulator ---
// The gearbox is 63.68395:1, not 64:1. With 4096 the cam drifts ~20 half-steps
// per revolution and the error adds up, so slice targets come from the real
// ratio and are computed against an absolute step count that is never wrapped.
const double STEPS_PER_REV_REAL = 4075.7728;   // 64 half-steps * 63.68395
const int    CAM_SLICES = 64;
#define USE_GRAY_ORDER 1          // must match braille_cam.scad's use_gray_order

// bit = DOT_TO_BIT[dot]; dot 1->3, 2->2, 3->1, 4->4, 5->5, 6->0
const uint8_t DOT_TO_BIT[7] = {0, 3, 2, 1, 4, 5, 0};

// Grade-1 braille a-z, as dot lists. Same table as sim/3d/app.js:23.
const uint8_t LETTER_DOTS[26][6] PROGMEM = {
  {1,0,0,0,0,0}, {1,2,0,0,0,0}, {1,4,0,0,0,0}, {1,4,5,0,0,0}, {1,5,0,0,0,0},
  {1,2,4,0,0,0}, {1,2,4,5,0,0}, {1,2,5,0,0,0}, {2,4,0,0,0,0}, {2,4,5,0,0,0},
  {1,3,0,0,0,0}, {1,2,3,0,0,0}, {1,3,4,0,0,0}, {1,3,4,5,0,0}, {1,3,5,0,0,0},
  {1,2,3,4,0,0}, {1,2,3,4,5,0}, {1,2,3,5,0,0}, {2,3,4,0,0,0}, {2,3,4,5,0,0},
  {1,3,6,0,0,0}, {1,2,3,6,0,0}, {2,4,5,6,0,0}, {1,3,4,6,0,0}, {1,3,4,5,6,0},
  {1,3,5,6,0,0}
};

// --- homing and backlash --------------------------------------------------
// Homing only ever runs FORWARD and stops on the first not-triggered ->
// triggered edge. A wide magnet triggers over a band of angles; the leading
// edge seen from one direction is the only point of that band that repeats.
const int    HALL_ACTIVE        = LOW;   // A3144 pulls low on a south pole
const int    HOME_SPEED         = 400;   // half-steps/s, slow so the edge is not overrun
const double HOME_TIMEOUT_REVS  = 1.5;
const int    HOME_CONFIRM       = 3;     // consecutive triggered steps to accept an edge

// Steps from the hall edge to the CENTRE of slice 0. Set on the bench:
// home, send !s 0, adjust with !homeoff N until the slice-0 pattern sits
// mid-dwell. !homeoff saves it to flash, so this default only applies once.
const int HOME_EDGE_TO_SLICE0 = 0;
const int BACKLASH_STEPS      = 40;      // overshoot past target on a reverse move
const int REHOME_EVERY        = 20;      // letters between automatic re-homes, 0 = off

int  homeEdgeToSlice0 = HOME_EDGE_TO_SLICE0;
int  backlashSteps    = BACKLASH_STEPS;
int  rehomeEvery      = REHOME_EVERY;
long homeEdge         = 0;               // absolute step count where the edge fired
int  lettersSinceHome = 0;
bool homed = false;

Preferences prefs;

// Tunable live over serial (!speed, !gap). A one-state move is only 64 steps, so
// it is ACCELERATION-limited, not speed-limited: at accel 500 the motor needs 490
// steps just to reach 700, and never gets past 179 steps/s on a single letter.
// Raising accel shortens short moves; raising vmax only helps long ones.
int  vmax  = 1000;   // half-steps/s. 28BYJ-48 torque falls off hard past ~1200.
int  accel = 2000;   // half-steps/s^2
int  gapMs = 250;    // hold time between characters of a typed word

// --- encoding -------------------------------------------------------------

int cellToState(char c) {
  if (c == ' ') return 0;
  if (c < 'a' || c > 'z') return -1;
  int state = 0;
  for (int i = 0; i < 6; i++) {
    uint8_t dot = pgm_read_byte(&LETTER_DOTS[c - 'a'][i]);
    if (dot == 0) break;
    state |= (1 << DOT_TO_BIT[dot]);
  }
  return state;
}

// v8.2 GRAY ORDER. The cam carries pattern gray(i) = i ^ (i>>1) at slice i, so
// to show pattern P we must rotate to the slice whose Gray value IS P — that is
// grayToBinary(P), not P. Get this wrong and every letter shows a different one.
// Must stay in step with use_gray_order in cad/scad/braille_cam.scad.
int grayToBinary(int g) {
  int b = g;
  while (g >>= 1) b ^= g;
  return b;
}

int stateToSlice(int state) {
  return USE_GRAY_ORDER ? grayToBinary(state) : state;
}

long sliceZero() { return homeEdge + homeEdgeToSlice0; }

// Absolute step of a slice centre, nearest to where we are (shortest path,
// matches the simulator's gotoIndex()). Each candidate is rounded from its own
// revolution number, so rounding error never carries from one turn to the next.
// sliceZero() already points at the slice-0 centre, so the +0.5 slice of
// round((slice + 0.5) * rev / 64) is folded into homeEdgeToSlice0.
long sliceTarget(long current, int slice) {
  long base = sliceZero();
  long rev  = (long)floor((current - base) / STEPS_PER_REV_REAL);
  long best = current, bestDist = LONG_MAX;
  for (long k = rev - 1; k <= rev + 1; k++) {
    long t = base + lround((k * CAM_SLICES + slice) * STEPS_PER_REV_REAL / CAM_SLICES);
    long d = labs(t - current);
    if (d < bestDist) { bestDist = d; best = t; }
  }
  return best;
}

// --- motion ---------------------------------------------------------------

void runToTarget() {
  while (stepper.distanceToGo() != 0) stepper.run();
}

// Every move ends travelling forward, the same way homing approaches the edge,
// so gear backlash is always taken up on the same flank.
void approach(long target) {
  if (target < stepper.currentPosition()) {
    stepper.moveTo(target - backlashSteps);
    runToTarget();
  }
  stepper.moveTo(target);
  runToTarget();
}

void releaseCoils() {                 // stop cooking the motor while idle
  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
}

// Move to one of the 64 cam states. Split out of showChar() so the browser can
// drive a state directly over Web Serial: the simulator already expands text into
// cells (including the capital/number indicators this table knows nothing about),
// so the encoding lives in ONE place and the firmware just follows.
void tryHome();

void showState(int state) {
  if (homed && rehomeEvery > 0 && lettersSinceHome >= rehomeEvery) {
    Serial.printf("\n  re-homing after %d letters\n", lettersSinceHome);
    tryHome();
  }

  int  slice  = stateToSlice(state);
  long from   = stepper.currentPosition();
  long target = sliceTarget(from, slice);
  long delta  = target - from;

  Serial.printf("state %2d  slice %2d  step %6ld  move %+5ld (%s)  %.1f deg",
                state, slice, target, delta,
                delta >= 0 ? "CW " : "CCW+bl", delta * 360.0 / STEPS_PER_REV_REAL);

  approach(target);
  releaseCoils();
  lettersSinceHome++;
}

void showChar(char c) {
  int state = cellToState(c);
  if (state < 0) { Serial.printf("  skip '%c' (a-z and space only)", c); return; }

  Serial.printf("  '%c'  dots ", c == ' ' ? '_' : c);
  if (c == ' ') Serial.print("(none)  ");
  else {
    for (int i = 0; i < 6; i++) {
      uint8_t d = pgm_read_byte(&LETTER_DOTS[c - 'a'][i]);
      if (d == 0) break;
      Serial.printf("%d", d);
    }
    Serial.print("  ");
  }
  showState(state);
}

bool hallTriggered() { return digitalRead(HALL_PIN) == HALL_ACTIVE; }

void loadTuning() {
  prefs.begin("braillix", false);      // read-write: a read-only open of a new namespace fails
  homeEdgeToSlice0 = prefs.getInt("homeoff",  HOME_EDGE_TO_SLICE0);
  backlashSteps    = prefs.getInt("backlash", BACKLASH_STEPS);
  rehomeEvery      = prefs.getInt("rehome",   REHOME_EVERY);
  prefs.end();
}

void saveTuning() {
  prefs.begin("braillix", false);
  prefs.putInt("homeoff",  homeEdgeToSlice0);
  prefs.putInt("backlash", backlashSteps);
  prefs.putInt("rehome",   rehomeEvery);
  prefs.end();
}

// Look for the homing magnet. There may be no cam disc yet, so this MUST NOT hang.
void tryHome() {
  Serial.printf("Homing: forward to the hall edge (%.1f rev max)...\n", HOME_TIMEOUT_REVS);
  long limit = stepper.currentPosition() + lround(HOME_TIMEOUT_REVS * STEPS_PER_REV_REAL);
  bool armed = !hallTriggered();       // starting inside the field is not an edge
  long edgeAt = 0;
  int  confirm = 0;
  bool found = false;

  stepper.setSpeed(HOME_SPEED);
  while (stepper.currentPosition() < limit) {
    if (!stepper.runSpeed()) continue;
    bool t = hallTriggered();
    if (!armed) { armed = !t; continue; }
    if (t) {
      if (confirm == 0) edgeAt = stepper.currentPosition();
      if (++confirm >= HOME_CONFIRM) { found = true; break; }
    } else confirm = 0;
  }
  // Same count, but clears the speed runSpeed() left behind so moveTo() ramps from rest.
  stepper.setCurrentPosition(stepper.currentPosition());
  releaseCoils();
  lettersSinceHome = 0;

  if (found) {
    homeEdge = edgeAt;
    homed = true;
    Serial.printf("  edge at step %ld, slice 0 at %ld (homeoff %d).\n",
                  homeEdge, sliceZero(), homeEdgeToSlice0);
  } else {
    homed = false;
    Serial.printf("  HOMING FAILED: no hall edge in %.1f rev (%s).\n", HOME_TIMEOUT_REVS,
                  armed ? "never triggered" : "triggered the whole time");
    Serial.println("  Expected if there is no disc on the shaft. Keeping the old zero; motion still works.");
  }
}

// One entry point for a command, whatever carried it here. Serial, HTTP and BLE
// all funnel through this, so the three transports can never drift apart.
void handleLine(String line, bool echo);

// --- wireless API ---------------------------------------------------------
// Every handler BLOCKS until the motor has arrived, so the HTTP response is the
// "done" signal - same contract the serial prompt gives, so the simulator syncs
// against either transport without knowing which it is talking to.
void cors() { server.sendHeader("Access-Control-Allow-Origin", "*"); }

void handleState() {
  cors();
  if (!server.hasArg("v")) { server.send(400, "text/plain", "need ?v=0-63"); return; }
  int st = server.arg("v").toInt();
  if (st < 0 || st > 63) { server.send(400, "text/plain", "state must be 0-63"); return; }
  showState(st);
  server.send(200, "text/plain", "ok");
}

void handleSpeed() {
  cors();
  int v = server.arg("v").toInt(), a = server.arg("a").toInt();
  if (v > 0 && a > 0) {
    vmax = v; accel = a;
    stepper.setMaxSpeed(vmax); stepper.setAcceleration(accel);
  }
  server.send(200, "text/plain", "ok");
}

void handlePing()  { cors(); server.send(200, "text/plain", homed ? "homed" : "not-homed"); }
void handleHome()  { cors(); tryHome(); server.send(200, "text/plain", "ok"); }

void startWifi() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);
  server.on("/s", handleState);
  server.on("/speed", handleSpeed);
  server.on("/ping", handlePing);
  server.on("/home", handleHome);
  // the browser preflights any cross-origin GET it considers non-simple
  server.onNotFound([]() { cors(); server.send(204); });
  server.begin();
  Serial.println();
  Serial.printf("WiFi AP up:  SSID \"%s\"  pass \"%s\"\n", AP_SSID, AP_PASS);
  Serial.printf("  join it, then point the simulator at  http://%s\n",
                WiFi.softAPIP().toString().c_str());
}

class BleServerCB : public BLEServerCallbacks {
  void onConnect(BLEServer* s) override { bleConnected = true;  Serial.println("\nBLE connected"); }
  void onDisconnect(BLEServer* s) override {
    bleConnected = false;
    Serial.println("\nBLE disconnected");
    BLEDevice::startAdvertising();      // otherwise it is invisible after one use
  }
};

class BleRxCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    String v = String(c->getValue().c_str());
    v.trim();
    if (!v.length()) return;
    handleLine(v, false);
    // showState() has already returned, so the motor has ARRIVED. That is what
    // the simulator waits on before advancing to the next cell.
    if (bleTx) { bleTx->setValue("ok"); bleTx->notify(); }
  }
};

void startBle() {
  BLEDevice::init(BLE_NAME);
  BLEServer* srv = BLEDevice::createServer();
  srv->setCallbacks(new BleServerCB());
  BLEService* svc = srv->createService(NUS_SERVICE);

  bleTx = svc->createCharacteristic(NUS_TX, BLECharacteristic::PROPERTY_NOTIFY);
  bleTx->addDescriptor(new BLE2902());

  BLECharacteristic* rx = svc->createCharacteristic(
      NUS_RX, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  rx->setCallbacks(new BleRxCB());

  svc->start();
  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(NUS_SERVICE);      // the browser filters on this; without
  adv->setScanResponse(true);            // it the device never appears in the picker
  BLEDevice::startAdvertising();
  Serial.printf("\nBLE up: look for \"%s\" in the simulator\n", BLE_NAME);
}

void help() {
  Serial.println();
  Serial.println("Type a letter or a word, then Enter.  Examples:  a    hello    cab");
  Serial.println("Commands:  !s N    go to cam state N (0-63) - the web simulator uses this");
  Serial.println("           !home   re-run homing");
  Serial.println("           !zero   call this position the centre of slice 0");
  Serial.println("           !hall   print the hall switch and step counts");
  Serial.println("           !homeoff N   steps from hall edge to slice-0 centre (saved)");
  Serial.println("           !backlash N  overshoot on reverse moves (saved)");
  Serial.println("           !rehome N    re-home every N letters, 0 = off (saved)");
  Serial.println("           !spin   one full revolution, to eyeball direction");
  Serial.println("           !speed V A   set max speed and acceleration");
  Serial.println("           !gap MS      pause between letters of a word");
  Serial.println("           !help   this list");
  Serial.println();
}

void setup() {
  Serial.begin(115200);
  delay(600);
  Serial.println("\n=== Braillix bare-motor letter test ===");
  loadTuning();
  Serial.printf("%.4f steps/rev, %d slices, homeoff %d, backlash %d, rehome every %d\n",
                STEPS_PER_REV_REAL, CAM_SLICES, homeEdgeToSlice0, backlashSteps, rehomeEvery);

  pinMode(HALL_PIN, INPUT);
  stepper.setMaxSpeed(vmax);     // must ramp; commanding full speed cold = stall
  stepper.setAcceleration(accel);

  tryHome();
  if (USE_WIFI) startWifi();
  if (USE_BLE)  startBle();
  help();
  Serial.print("> ");
}

void handleLine(String line, bool echo) {
  line.trim();
  line.toLowerCase();
  if (line.length() == 0) return;

  if (line.startsWith("!")) {
    if      (line == "!home") tryHome();
    else if (line == "!zero") {
      homeEdge = stepper.currentPosition() - homeEdgeToSlice0;
      Serial.println("  zero set.");
    }
    else if (line == "!hall")
      Serial.printf("  hall %s  step %ld  from edge %ld  homed %d\n",
                    hallTriggered() ? "TRIGGERED" : "clear", stepper.currentPosition(),
                    stepper.currentPosition() - homeEdge, homed);
    else if (line.startsWith("!homeoff")) {
      int n;
      if (sscanf(line.c_str(), "!homeoff %d", &n) == 1) {
        homeEdgeToSlice0 = n; saveTuning();
        Serial.printf("  homeoff %d saved (send !s 0 to check)\n", homeEdgeToSlice0);
      } else Serial.printf("  usage: !homeoff <steps>   now %d\n", homeEdgeToSlice0);
    }
    else if (line.startsWith("!backlash")) {
      int n;
      if (sscanf(line.c_str(), "!backlash %d", &n) == 1 && n >= 0) {
        backlashSteps = n; saveTuning();
        Serial.printf("  backlash %d saved\n", backlashSteps);
      } else Serial.printf("  usage: !backlash <steps>   now %d\n", backlashSteps);
    }
    else if (line.startsWith("!rehome")) {
      int n;
      if (sscanf(line.c_str(), "!rehome %d", &n) == 1 && n >= 0) {
        rehomeEvery = n; saveTuning();
        Serial.printf("  re-home every %d letters saved\n", rehomeEvery);
      } else Serial.printf("  usage: !rehome <letters>   now %d (0 = off)\n", rehomeEvery);
    }
    else if (line.startsWith("!speed")) {
      int v, a;
      if (sscanf(line.c_str(), "!speed %d %d", &v, &a) == 2 && v > 0 && a > 0) {
        vmax = v; accel = a;
        stepper.setMaxSpeed(vmax); stepper.setAcceleration(accel);
        Serial.printf("  vmax %d (%.1f RPM), accel %d\n", vmax, vmax * 60.0 / STEPS_PER_REV_REAL, accel);
        if (vmax > 1200) Serial.println("  WARNING: past ~1200 the 28BYJ-48 will start skipping steps.");
      } else Serial.println("  usage: !speed <maxspeed> <accel>   e.g. !speed 1000 2000");
    }
    else if (line.startsWith("!gap")) {
      int g;
      if (sscanf(line.c_str(), "!gap %d", &g) == 1 && g >= 0) { gapMs = g; Serial.printf("  gap %d ms\n", gapMs); }
      else Serial.println("  usage: !gap <milliseconds>");
    }
    else if (line.startsWith("!s ")) {
      int st;
      if (sscanf(line.c_str(), "!s %d", &st) == 1 && st >= 0 && st < 64) showState(st);
      else Serial.println("  usage: !s <0-63>   (cam state, used by the web simulator)");
    }
    else if (line == "!spin") {
      Serial.println("  one revolution...");
      stepper.moveTo(stepper.currentPosition() + lround(STEPS_PER_REV_REAL));
      runToTarget(); releaseCoils();
      Serial.println("  done.");
    }
    else help();
  } else {
    for (unsigned i = 0; i < line.length(); i++) {
      showChar(line[i]);
      delay(gapMs);               // hold each letter long enough to see it
    }
  }
}

void loop() {
  if (USE_WIFI) server.handleClient();
  if (!Serial.available()) return;
  String line = Serial.readStringUntil('\n');
  handleLine(line, true);
  Serial.print("> ");
}
