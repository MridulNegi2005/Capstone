# Braillix v5.0 — Wiring & Assembly Guide

## Pogo Daisy-Chain Pinout (4-pin, same everywhere)
```
Pin 1 = +5V    Pin 2 = GND    Pin 3 = SDA    Pin 4 = SCL
```
```
[5V/3A adapter]
      |
      v
+-----------+   pogo    +--------+   pogo    +--------+
| BRAIN POD |<--------->| CELL 1 |<--------->| CELL 2 |-->...-->[end cap]
| (ESP32)   | 4 wires   |        | 4 wires   |        |
| I2C master| 5V/GND/   | I2C    |           | I2C    |
| + buttons | SDA/SCL   | slave  |           | slave  |
+-----------+           | 0x20   |           | 0x21   |
                        +--------+           +--------+
```

## Per-Cell Wiring (Muscle Board Connectors)

| Connector | Pins | From | Color | Routing |
|---|---|---|---|---|
| J1 (pogo) | 4: 5V,GND,SDA,SCL | Both pogo connectors (bridged) | Red,Black,Blue,Yellow | Down wall guides -> mid-plate notches -> pocket |
| J2 (motor) | 5: coils A-D + COM | 28BYJ-48 (JST-XH plug) | White 5-pin | Motor slot (x=-8,y=20) -> pocket |
| J3 (hall) | 3: VCC,GND,SIG | SS49E hall sensor | Red,Black,Green | Base plate +Y channel -> mid-plate +Y notch -> pocket |
| J4 (ISP) | 6 | AVR programmer | 2x3 ribbon | Temporary - remove after flashing |

Wire count per cell: **12 permanent** (4 pogo + 5 motor + 3 hall)

### Pogo Bridge (inside each cell)
Each cell has -X springs and +X pads. Bridge both to J1 (3-way splice per net):
```
-X pogo spring --+-- J1 pin --+-- +X pogo pad
                 (same for all 4 nets)
```

## ESP32 Brain Pod Wiring

| Net | ESP32 Pin | Notes |
|---|---|---|
| I2C SDA | GPIO21 | -> dock pogo pin 3 |
| I2C SCL | GPIO22 | -> dock pogo pin 4 |
| 5V in | VIN | from barrel jack (+) |
| GND | GND | barrel(-), dock pin2, button common |
| BACK | GPIO32 | tactile switch, INPUT_PULLUP, active-LOW |
| SELECT | GPIO33 | tactile switch, INPUT_PULLUP, active-LOW |
| NEXT | GPIO25 | tactile switch, INPUT_PULLUP, active-LOW |
| Buzzer | GPIO26 | optional piezo |
| SDA pull-up | 3V3 -> 4.7k -> SDA | master end only |
| SCL pull-up | 3V3 -> 4.7k -> SCL | master end only |

Pod wire count: **10 wires** (2 barrel, 4 pogo, 3 buttons+GND, 1 buzzer)

No level shifter needed: ESP32 3.3V open-drain I2C works with 5V ATmega (reads >2.0V as HIGH).

## Power Budget
```
Per cell:  motor 240mA + ATmega 20mA + hall 5mA = ~265mA
5 cells:   1.325A
ESP32:     ~80mA
Total:     ~1.4A    5V/3A adapter = 2x headroom
```

## Assembly — Cell (repeat per cell)

1. Press-fit pogo connectors into both +-X wall windows
2. Route 8 pogo leads down wall guides, through mid-plate notches into pocket
3. Mount muscle board on 4 M2 bosses, screw down (M2x6 x4)
4. Solder pogo leads to J1 (bridge -X and +X: 3-way splice per net)
5. Tuck wires into floor gutters and hooks
6. Drop mid-plate onto z=20 ledge (collar up, notches aligned)
7. **Outside the box:** bolt motor to base plate (M4 x2), TRIM SHAFT TO 4mm, press cam onto D-shaft, seat hall sensor
8. Lower motor+baseplate module in (motor enters collar, plate on bosses)
9. Connect motor->J2, hall->J3 through mid-plate slots
10. Slide linkage comb onto standoffs, lock with M2 grub screw
11. Drop 6 linkages into comb slits (feet on cam, nubs up)
12. Glue 2mm bearing balls onto nub tips
13. Drop springs into top plate pockets
14. Lower top plate over standoffs (balls through 2.5mm holes)
15. 4x M2.5x25 corner bolts (top->standoff->base->boss)
16. Last cell: snap TPU end cap on +X pads

## Assembly — Pod

1. Snap 3 tactile switches into front wall pockets
2. Wire: switch pin1 -> GPIO32/33/25, pin2 -> common GND
3. Seat 2 female 1x15 headers in floor channels, wire 5V/GND/SDA/SCL to dock pogo
4. Wire barrel jack: (+)->VIN, (-)->GND
5. Solder 2x 4.7k pull-ups: 3V3->SDA, 3V3->SCL
6. Press 3 magnets into +X dock face (S/N/S polarity)
7. Plug ESP32 DevKit into female headers
8. Press 3 nav caps into front holes
9. Close lid (2x M2x6)
10. Dock pod -> cell 1 (magnets snap, pogos connect)

## Quick Reference
```
POGO:     1=5V  2=GND  3=SDA  4=SCL
CELL J1:  Red=5V  Black=GND  Blue=SDA  Yellow=SCL
CELL J2:  White 5-pin JST (plug in)
CELL J3:  Red=VCC  Black=GND  Green=SIG
BUTTONS:  GPIO32=BACK  GPIO33=SELECT  GPIO25=NEXT
I2C:      GPIO21=SDA  GPIO22=SCL  (4.7k to 3V3)
ADDRESSES: 0x20..0x27 (solder jumpers PB0-PB2)
BOLT:     M2.5x25 x4 per cell (top->standoff->base->boss)
```
