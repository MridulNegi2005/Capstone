/*
 * Braillix Breadboard Test — Motor + Hall Sensor
 *
 * Board: ESP32 Dev Module (USB-C, 30-pin)
 * Arduino IDE: install "esp32" by Espressif from Boards Manager
 *
 * Wiring:
 *   ULN2003 IN1 → GPIO 18
 *   ULN2003 IN2 → GPIO 19
 *   ULN2003 IN3 → GPIO 21
 *   ULN2003 IN4 → GPIO 22
 *   Hall AO     → GPIO 34 (analog read)
 *   Hall VCC    → 3V3
 *   Hall GND    → GND
 *   ULN2003 (+) → 5V rail (from adapter)
 *   ULN2003 (-) → GND rail (shared with ESP32)
 */

// Motor pins (28BYJ-48 via ULN2003)
// Half-step sequence needs: IN1, IN3, IN2, IN4
const int IN1 = 18;
const int IN2 = 19;
const int IN3 = 21;
const int IN4 = 22;

// Hall sensor (KY-024 module, analog output)
const int HALL_PIN = 34;

// 28BYJ-48: 2048 half-steps per revolution (with 64:1 gearbox)
const int STEPS_PER_REV = 2048;

// Half-step sequence (8 phases)
const int halfStep[8][4] = {
  {1,0,0,0},
  {1,1,0,0},
  {0,1,0,0},
  {0,1,1,0},
  {0,0,1,0},
  {0,0,1,1},
  {0,0,0,1},
  {1,0,0,1}
};

int stepIndex = 0;

void motorStep(bool clockwise) {
  if (clockwise) {
    stepIndex = (stepIndex + 1) % 8;
  } else {
    stepIndex = (stepIndex + 7) % 8;  // -1 mod 8
  }
  digitalWrite(IN1, halfStep[stepIndex][0]);
  digitalWrite(IN3, halfStep[stepIndex][1]);  // NOTE: IN3 before IN2 for 28BYJ-48
  digitalWrite(IN2, halfStep[stepIndex][2]);
  digitalWrite(IN4, halfStep[stepIndex][3]);
}

void motorOff() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println();
  Serial.println("=== Braillix Breadboard Test ===");

  // Motor pins
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  motorOff();

  // Hall sensor (GPIO34 is input-only, no pull-up)
  pinMode(HALL_PIN, INPUT);

  // --- TEST 1: Read hall baseline ---
  Serial.println();
  Serial.println("[TEST 1] Hall sensor baseline (no magnet):");
  for (int i = 0; i < 10; i++) {
    Serial.print("  hall = ");
    Serial.println(analogRead(HALL_PIN));
    delay(200);
  }

  // --- TEST 2: Spin motor CW quarter turn ---
  Serial.println();
  Serial.println("[TEST 2] Spinning CW (512 steps = quarter turn)...");
  for (int i = 0; i < 512; i++) {
    motorStep(true);
    delayMicroseconds(1500);  // ~10 RPM, smooth
  }
  motorOff();
  Serial.println("  Done. Motor should have turned ~90 degrees CW.");
  delay(1000);

  // --- TEST 3: Spin motor CCW quarter turn ---
  Serial.println();
  Serial.println("[TEST 3] Spinning CCW (512 steps = quarter turn)...");
  for (int i = 0; i < 512; i++) {
    motorStep(false);
    delayMicroseconds(1500);
  }
  motorOff();
  Serial.println("  Done. Motor should have returned to start.");
  delay(1000);

  // --- TEST 4: Full revolution with hall readings ---
  Serial.println();
  Serial.println("[TEST 4] Full CW revolution, printing hall every 64 steps:");
  Serial.println("  (Wave a magnet over the hall sensor to see the value change!)");
  for (int i = 0; i < STEPS_PER_REV; i++) {
    motorStep(true);
    delayMicroseconds(1500);
    if (i % 64 == 0) {
      int h = analogRead(HALL_PIN);
      Serial.print("  step=");
      Serial.print(i);
      Serial.print("  hall=");
      Serial.println(h);
    }
  }
  motorOff();

  Serial.println();
  Serial.println("=== ALL TESTS COMPLETE ===");
  Serial.println("If motor spun and hall values changed with magnet → you're ready!");
  Serial.println();
  Serial.println("Entering continuous hall monitor (wave magnet to see changes)...");
}

void loop() {
  // Continuous hall monitor
  int h = analogRead(HALL_PIN);
  Serial.print("hall=");
  Serial.println(h);
  delay(200);
}
