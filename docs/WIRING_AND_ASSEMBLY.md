# Braillix v6.1 — Wiring & Assembly Guide

## Prototype Cell Electronics (no muscle board yet) — ULN2003 module fit

The off-the-shelf ULN2003 driver module DOES fit the 36×46×16mm electronics pocket,
**but only with low-profile wiring** (measured: ~20mm tall with vertical Dupont jumpers
plugged in — too tall; ~12mm with wires soldered flat):

1. Cut the female Dupont housings off 6 jumper wires (IN1–IN4, +5V, GND); strip ~3mm.
2. Solder each wire **flat against its header pin, lying parallel to the board** (bend the
   wire 90° at the pin base, then solder). Beginner-level joint — tin pin, tin wire, touch.
3. Press the ULN2003 DIP chip fully down into its socket (it often sits raised).
4. Lay the board **flat on the pocket floor** (NOT on the 4mm muscle-board bosses), with the
   JST/header edge toward the **front-right (+X, −Y) corner** — the mid-plate has a relief
   slot there (v6.1) giving the JST plug extra headroom.
5. The white JST motor plug inserts before the mid-plate goes in.

When the custom muscle board is fabricated later, it mounts on the 4 M2 bosses as designed.


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
10. Place 6 resin-printed linkages: feet on their cam tracks, nubs up at the braille dot
    positions (the comb was scrapped in v6.0 — linkages are constrained by cam foot below
    + top-plate hole above)
11. Glue 2mm bearing balls onto nub tips
12. Drop springs into top plate pockets
13. Lower top plate over standoffs (balls through 2.5mm holes)
14. 4x M2.5x25 corner bolts (top->standoff->base->boss)
15. Glue 2× 8×1mm magnets into each ±X face teardrop pocket
    (-X face = N/S out, +X face = S/N out — test-dock before the glue sets!)
16. Last cell: snap TPU end cap on +X pads

## Assembly — Pod

1. Snap 3 tactile switches into front wall pockets
2. Wire: switch pin1 -> GPIO32/33/25, pin2 -> common GND
3. Seat 2 female 1x15 headers in floor channels, wire 5V/GND/SDA/SCL to dock pogo
4. Wire barrel jack: (+)->VIN, (-)->GND
5. Solder 2x 4.7k pull-ups: 3V3->SDA, 3V3->SCL
6. Glue 2× 8×1mm magnets into +X dock face teardrop pockets (S/N polarity — must
   attract a cell's -X face; test-dock before the glue sets)
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
