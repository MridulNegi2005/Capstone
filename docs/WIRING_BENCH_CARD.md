# Braillix Cell Wiring - Bench Card

Revision 2026-10-18. This card covers one braille cell that uses the MCP23017
expander. It lists every connection between the ESP32, the expander, the driver,
the motor, the hall sensor and the dock connector.

Keep this card on the bench. Measure each connection with a multimeter after you
solder it.

## 1. Read this before you start

The firmware does not drive the expander yet. The current sketches drive the
motor from ESP32 GPIO 18, 19, 21 and 22 directly. The expander needs new
firmware before the wiring in this card can run.

Wire the cell from this card anyway. The wiring is correct and it does not
change when the firmware arrives.

The ESP32 and the expander both work at 3.3 V. The motor and the hall sensor
work at 5 V. Both voltages exist in the cell. Check the voltage on every wire
before you connect it.

## 2. How to find pin 1

Pin 1 starts every table in this card. Each part marks pin 1 in a different way.

### 2.1 The expander, MCP23017-E/SO

The package is a SOIC-28. Look for a round dimple in the plastic at one end.
The pin beside the dimple is pin 1. One long edge is also bevelled, and pin 1
sits on that edge.

Hold the part with the printed text upward. Pin 1 is then at the top left.
Count counterclockwise: down the left side to pin 14, then up the right side
from pin 15 to pin 28.

Caution. You glue this part with the pins upward, so the printed text faces the
board and you cannot see it. The pin order then appears reversed. Mark the
position of pin 1 on the board with a pen before you glue the part down.

### 2.2 The driver, ULN2003AN

The package is a DIP-16. One end has a half-circle notch. Hold the part with
the notch upward. Pin 1 is at the top left. Count counterclockwise.

### 2.3 The hall sensor, A3144

The package is a TO-92. Hold the part with the flat face toward you and the
three legs downward. The left leg is pin 1.

### 2.4 The dock connector, 5-pin pogo

The connector has no pin 1 mark. You choose which end is pin 1, and the choice
must be the same on every cell.

Use the chevron on the shell as the reference. Pin 1 is the pin closest to the
chevron. Write this rule on the inside of each shell.

Two facts make this safe:

1. Pin 3 carries 5 V, and pin 3 is the centre pin. The centre pin stays the
   centre pin whichever end you call pin 1.
2. Pin 1 and pin 5 both carry ground.

A reversed connector therefore exchanges only SCL and SDA. The bus stays silent
until you turn the cell around, and no part is damaged.

## 3. Power

| From | To | Wire |
|---|---|---|
| Adapter centre pin | 5 V rail | `RED` |
| Adapter barrel | Ground rail | `BLACK` |
| 5 V rail | ESP32 `VIN` | `RED` |
| Ground rail | ESP32 `GND` | `BLACK` |
| ESP32 `3V3` | 3.3 V rail | `ORANGE` |

Caution. Never connect the USB cable and the 5 V rail to `VIN` at the same
time. Use one source only.

Caution. Measure the adapter polarity before you connect the ESP32. A reversed
adapter destroys the board.

## 4. ESP32 to the expander

| ESP32 | Expander pin | Name | Wire |
|---|---|---|---|
| GPIO 21 | 13 | SDA | `BLUE` |
| GPIO 22 | 12 | SCL | `YELLOW` |
| `3V3` | 9 | VDD | `ORANGE` |
| `GND` | 10 | VSS | `BLACK` |

Add two 4.7 k resistors. Connect one from SDA to the 3.3 V rail. Connect the
other from SCL to the 3.3 V rail.

Caution. Fit these two resistors once, next to the ESP32 only. Do not fit them
in each cell. Eight cells with their own resistors give 590 ohms in parallel,
and no device on the bus can pull that low.

Add one 100 nF capacitor across expander pins 9 and 10. The two pins are next
to each other, so solder the capacitor directly onto the legs.

## 5. The expander address and reset

| Expander pin | Name | Connect to | Reason |
|---|---|---|---|
| 15 | A0 | Ground | Address bit |
| 16 | A1 | Ground | Address bit |
| 17 | A2 | Ground | Address bit |
| 18 | RESET | VDD, pin 9 | Hold the part out of reset |

All three address pins go to ground. The address is then 0x20. Cell 2 connects
A0 to VDD instead, which gives 0x21.

Caution. Pin 18 must connect to VDD. A floating RESET pin stops the expander
from answering on the bus. The part looks dead, and the fault looks like a bad
solder joint.

All three address pins go to ground for cell 1, so the order of pins 15, 16 and
17 does not matter yet. Confirm the order in the datasheet before you set a
different address on cell 2.

## 6. The expander to the driver

| Expander pin | Name | Driver pin | Name |
|---|---|---|---|
| 21 | GPA0 | 1 | IN1 |
| 22 | GPA1 | 2 | IN2 |
| 23 | GPA2 | 3 | IN3 |
| 24 | GPA3 | 4 | IN4 |

The expander drives these four inputs. ESP32 pins GPIO 18 and 19 become free.

## 7. The driver to the motor

| Driver pin | Name | To | Wire |
|---|---|---|---|
| 16 | OUT1 | Motor coil | `BLUE` |
| 15 | OUT2 | Motor coil | `PINK` |
| 14 | OUT3 | Motor coil | `YELLOW` |
| 13 | OUT4 | Motor coil | `ORANGE` |
| 9 | COM | 5 V rail | `RED` |
| 8 | GND | Ground rail | `BLACK` |
| - | Centre tap | 5 V rail | `RED` |

Caution. Pin 9 is the flyback diode common. It must connect to the 5 V rail.
The motor turns without this connection, and then the coil kickback destroys
the driver.

The motor `RED` wire is the centre tap. It is not a coil. Connect it to the
5 V rail with driver pin 9.

Check the motor wire colours with the multimeter. Measure between the `RED`
wire and each other wire. Each reading is about 50 ohms. Measure between two
coil wires. That reading is about 100 ohms.

## 8. The hall sensor

Read the part number on your sensor first. The two sensor types wire
differently.

### 8.1 A3144, a bare TO-92 part

| Sensor pin | Name | To |
|---|---|---|
| 1 | VCC | 5 V rail |
| 2 | GND | Ground rail |
| 3 | OUT | Expander pin 1, GPB0 |

Add one 10 k resistor from sensor pin 3 to the 3.3 V rail.

The output is open collector. The resistor sets the high level, so the expander
sees 3.3 V and never 5 V.

The A3144 is a unipolar switch. It answers to one magnet pole only. Turn the
magnet over if the sensor does not react.

### 8.2 MH sensor module, the blue board

This module gives an analog output. The expander has no analog input, so this
module cannot connect to the expander.

| Module pin | To |
|---|---|
| VCC | 3.3 V rail |
| GND | Ground rail |
| AO | ESP32 GPIO 34 |

The present firmware reads GPIO 34, so this module works today. It needs one
calibration pass for each cell.

Caution. Never solder to a magnet. A neodymium magnet loses its field above
about 80 degrees Celsius.

## 9. The dock connector

Each cell carries two pogo connectors, one on each dock face. Both connectors
join the same four points inside the cell. The bus passes through the cell.

| Pogo pin | Signal | Wire | Joins |
|---|---|---|---|
| 1 | Ground | `BLACK` | Ground rail |
| 2 | SCL | `YELLOW` | Expander pin 12 |
| 3 | 5 V | `RED` | 5 V rail |
| 4 | SDA | `BLUE` | Expander pin 13 |
| 5 | Ground | `BLACK` | Ground rail |

Pin 3 carries motor power. It does not carry expander power. The expander works
at 3.3 V, and the bus has no 3.3 V wire.

A cell that sits far from the ESP32 therefore needs one AMS1117-3.3 regulator.
The regulator makes 3.3 V from the 5 V on pin 3. Cell 1 can use the ESP32 `3V3`
pin instead, because it sits beside the ESP32.

Pin 1 and pin 5 both carry ground for two reasons. Ground carries the current of
every cell downstream, and ground is also the signal reference for the bus. See
`docs/BUILD_PACK.md` Part 10.

## 10. Checks before you apply power

Do every check in this order. Remove the driver from its socket first.

1. Measure continuity from driver pin 9 to the 5 V rail.
2. Measure continuity from driver pin 8 to the ground rail.
3. Measure continuity between each pair of neighbouring pins on the expander.
   Each pair must read open.
4. Measure continuity between each pair of neighbouring pins on the driver
   socket. Each pair must read open.
5. Measure the voltage on the 5 V rail. The reading is 4.8 V to 5.2 V.
6. Measure the voltage on the 3.3 V rail. The reading is 3.2 V to 3.4 V.
7. Fit the driver into its socket.
8. Apply power for ten seconds. Touch the driver and the expander. A warm part
   means a wiring fault. Remove power at once.

## 11. Mechanical cautions

Anchor every wire bundle to the board 5 mm to 10 mm from its solder joint. A
solder joint fails because the wire flexes at the edge of the joint. Adhesive
on the joint itself makes the joint more brittle, not stronger.

Use heat-shrink tube over each joint, then anchor the wire behind it.

Do not glue the dock connector. The cells must separate.

## 12. What is not yet resolved

| Item | State |
|---|---|
| Expander firmware | Not written |
| Motor pins after the expander arrives | IN3 moves to GPIO 23, IN4 moves to GPIO 27 |
| Hall sensor part number | Not confirmed |
| Pogo connector dimensions | Three values in `dock_interface.scad` are marked MEASURE |
| Return spring wire | The owned spring is 0.30 mm. The design needs 0.20 mm. |
| AMS1117-3.3 regulator | Not bought |
