# Braillix — independent electronics / firmware audit

Date: 2026-09-05. Auditor: independent electronics/firmware review.
Scope: `firmware/`, `docs/ELECTRONICS_*`, `docs/BUILD_PACK.md`, `docs/WIRING_AND_ASSEMBLY.md`,
`docs/MULTICELL_ARCHITECTURE.md`, `cad/scad/electronics_spec.scad`, `cad/scad/dock_interface.scad`,
`cad/scad/mech_layout.scad`, `cad/scad/braille_cam.scad`, `.ai-sync/handoff.md`.

**No project file was modified.** No hardware was available. Every claim below is tagged
**VERIFIED** (read directly from a file in this repo, or arithmetic on numbers read from files)
or **INFERRED** (component datasheet behaviour or engineering estimate that a bench measurement
must settle). Each INFERRED item names the measurement that would settle it.

---

## Summary

The single-cell breadboard path is buildable. The **docked multi-cell chain described in the brief
is not an electronics design yet** — it is a pinout plus a chip name, and three of its load-bearing
assumptions are wrong.

The five hardest problems, in order:

1. **The cam demands ±4 motor steps of positional accuracy. Nothing in the firmware delivers it.**
   The cam's own tolerance budget (`dwell_tol = 0.15 mm`, `braille_cam.scad:116`) works out to
   **±4.2 steps at the outermost track**. The firmware's step model is off by **20 steps per
   revolution** (4096 assumed vs ~4076 real), and its shortest-path moves re-inject the gearbox
   backlash on every direction reversal. Both individually exceed the budget.
2. **A bare A3144 cannot run at 3.3 V**, which is the only supply the docs permit it (datasheet
   minimum 4.5 V). And the current homing algorithm is not an edge latch — it is an argmin over
   an analog read of a digital, open-collector part on a pin (GPIO34) that has no internal pull-up.
   Missing pull-up produces a *silent* false home, not a failure.
3. **The MCP23017 plan has the voltage decision exactly backwards.** `ELECTRONICS_PLAN.md:171-173`
   prescribes powering the expander at 3.3 V. That is the one option that *cannot* drive a ULN2003
   input reliably. The correct answer (5 V expander + a real I2C level shifter) is explicitly
   ruled out by `ELECTRONICS_BOM.md:152` ("Level shifters ❌ Not needed").
4. **The pogo/ground analysis in `BUILD_PACK.md` §10 counts one joint, not the chain.** It reports
   100 mV of ground offset at 8 cells. The cumulative offset at the far cell is **450 mV**, and the
   I2C low-level margin runs out at **about 6 cells refreshing together**, not 11 (the power limit).
5. **The pin map is contradictory in three places at once** and the shipped firmware uses the pins
   the plan forbids.

Two structural observations that matter more than any single defect:

- `docs/MULTICELL_ARCHITECTURE.md` (the only doc that studies scaling on its merits) concludes the
  right architecture is **one travelling cam head over latching pins**, and that a chain of 68 mm
  cells is *not* a braille display (`:29`, `:41-42` — 8 cells = 544 mm, 11× the standard pitch).
  The dock/MCP23017 work audited here builds the architecture that document rejects. That conflict
  is unresolved anywhere in the repo and it is a project-level decision, not an electronics one.
- `docs/INDEPENDENT_PREPRINT_AUDIT_2026-09-04.md` already found several of these. Its findings have
  **not** been applied to firmware or docs; `handoff.md` records them as open.

---

# BLOCKER

## B-1 — The cam's positional budget is ±4 steps; the firmware cannot hold it
**VERIFIED (geometry and arithmetic) / INFERRED (backlash magnitude, gearbox ratio)**

Read from CAD:

| Value | Source |
|---|---|
| `dwell_tol = 0.15` — "arc left flat each side of a stop for step error/backlash" | `cad/scad/braille_cam.scad:116` |
| `foot_roll_r = 0.5`, follower is a point contact in travel | `cad/scad/mech_layout.scad:323` |
| `foot_flat_arc = 2*(foot_roll_r*tan15 + dwell_tol)` = 0.568 mm | `cad/scad/braille_cam.scad:119` |
| track radii 14.80 … 23.30 mm | `cad/scad/mech_layout.scad:50` |
| `STEPS_PER_REV = 4096`, `STEPS_PER_POS = 64`, `DWELL_OFFSET = 32` | `firmware/braille_cell/braille_cell.ino:73-75` |

At the outermost track (r = 23.30 mm) one half-step is `2π·23.30/4096 = 0.0357 mm` of arc.
The design's own allowance for step error and backlash is 0.15 mm each side of the stop:

```
positional budget = ±0.15 mm / 0.0357 mm-per-step = ±4.2 steps        (outer track)
                    ±0.15 mm / 0.0227 mm-per-step = ±6.6 steps        (inner track, r=14.80)
```

**±4.2 steps out of 64 per state, or ±0.37° of cam rotation.** That is the number every firmware
decision has to respect. Three things break it:

**(a) 4096 is the wrong steps-per-revolution.** *INFERRED.* The 28BYJ-48's gearbox is
63.68395:1, not 64:1 — 64 half-steps × 63.68395 = **4075.8** half-steps per output revolution.
The firmware hardcodes 4096 (`braille_cell.ino:73`, comment says "64:1 gearbox"), and `showState()`
wraps position modulo 4096 (`:166`). Error is **20.2 steps (1.78°, 0.32 of a state) per revolution
of accumulated wrap**, five times the budget, growing without bound because nothing re-homes.
`docs/MULTICELL_ARCHITECTURE.md:185` already flags "owned motor requires Hall-to-Hall calibration"
— that calibration was never fed back into the firmware, the simulator
(`sim/3d/braillix_params.json:109` = 4096) or the docs.
*Bench measurement:* home, then count steps between two successive leading Hall edges, ten times.
That number replaces 4096.

**(b) `shortestTarget()` reverses direction, so backlash is never taken out.**
`braille_cell.ino:134-138` deliberately takes the shorter arc, which means roughly half of all
moves reverse. *INFERRED:* a 28BYJ-48's plastic reduction train has 0.5–1.5° of output backlash;
1° = **11.4 steps**, 2.7× the budget. The cam only pushes; the six springs load the follower in one
sense, so a reversal parks the train against the far side of the lash.
*Bench measurement:* command +200/−200 steps repeatedly and read the cam's angular return with a
dial indicator on the disc rim, or count Hall-edge steps CW versus CCW.

**(c) `tryHome()` desynchronises the coil phase.** *VERIFIED, subtle.*
`braille_cell.ino:201-203` calls `setCurrentPosition((currentPosition − bestAt) mod 4096)`.
AccelStepper derives the coil pattern from `_currentPos & 0x07` and does not re-output on
`setCurrentPosition()`. Because `bestAt` is arbitrary, the new position's phase generally does not
match the phase actually energised, so the **first step after homing jumps up to 3 half-steps** or
loses sync. (The same call in `showState():166` is safe — 4096 is a multiple of 8 — which is why
this only bites at homing.)

**Fix**
1. Replace `STEPS_PER_REV` with a measured Hall-to-Hall constant; store it and re-home on a
   schedule (e.g. every 16 characters and after any fault), not once at boot.
2. Make every move **approach the target from one fixed direction**: if the shortest path is the
   backlash-loading direction, use it; otherwise overshoot by a measured takeup (start at 32 steps)
   and come back. Keep `shortestTarget()` only to pick which way to go the long way round.
3. After homing, round the new position down to a multiple of 8, or call `stepper.moveTo(pos)` and
   `run()` one step before trusting the phase.
4. Re-derive the CAD's `dwell_tol` from the *measured* backlash rather than assuming 0.15 mm is
   affordable. If backlash really is ~1°, `dwell_tol` must be ≈ 0.4 mm and the cam gets reprinted.

**Why it matters:** a dot half-way up a ramp is neither readable nor absent, and there is no
feedback anywhere in the system that would report it. The failure is silent and reads as "wrong
letter".

---

## B-2 — The bare A3144 is out of spec at 3.3 V, and the homing code is not an edge latch
**VERIFIED (code, docs) / INFERRED (A3144 datasheet limits)**

**(a) Supply voltage.** `docs/ELECTRONICS_BOM.md:18` retires the MH module and selects a **bare
A3144**. `docs/BUILD_PACK.md` §3.4 then states: "🔴 **3V3, NEVER 5V.**" *INFERRED:* the Allegro
A3144/A3144E operating supply range is **4.5–24 V**. At 3.3 V the part is below its datasheet
minimum: it may output nothing, or switch at an uncharacterised, temperature-dependent field.
The instruction and the part are incompatible.

The fix is easy and nobody has written it down: **an open-collector output does not care what its
supply is.** Power the A3144 from **5 V** and pull its output up to **3.3 V** through 10 kΩ. The
output only ever sinks, so GPIO34 never sees more than 3.3 V. `docs/ELECTRONICS_BOM.md:152`
("Level shifters ❌ Not needed — hall runs on 3V3, so GPIO34 never sees 5V") reaches the right
conclusion from the wrong premise, and the premise is what got written into the build pack.
*Bench measurement:* A3144 at 3.3 V, sweep the 8×1 magnet past at the design air gap; record the
output. Repeat at 5 V. If it does not switch cleanly at 3.3 V, the point is settled.

**(b) GPIO34 has no internal pull-up.** *VERIFIED.* `braille_cell.ino:68` `#define HALL_PIN 34`,
`:324` `pinMode(HALL_PIN, INPUT)`. GPIO34/35/36/39 on the ESP32 are input-only and have **no
internal pull-up or pull-down at all**. With an open-collector sensor and the external 10 kΩ
omitted or badly soldered, the pin **floats**. The homing loop
(`braille_cell.ino:193-197`) takes the *minimum* `analogRead` over a whole revolution — a floating
pin will produce a low sample somewhere, so homing **succeeds at a random angle**. There is no
detection of this. Silent wrong-position, every boot.

**(c) The homing algorithm is an argmin, not an edge latch, and the repo has three different
definitions of "home".** *VERIFIED.*

| File:line | Homing rule |
|---|---|
| `cad/scad/mech_layout.scad:179-182` | "Home by always rotating the SAME direction and latching the **FIRST edge** of the field" |
| `firmware/breadboard_test/breadboard_test.ino:275-340` | spins out of the field, latches leading **and** trailing edge, homes on the **midpoint** (`:337`) |
| `firmware/braille_cell/braille_cell.ino:188-211` | **argmin of `analogRead`** over one revolution |

The newer sketch is the regression. `braille_cell.ino` also never leaves the field before
searching: if the disc is powered up already over the magnet, `best` is set at step 0 and stays
there, so home lands wherever the disc happened to stop.

**Is edge homing good enough?** *Arithmetic, VERIFIED.* An 8 mm magnet at r = 17.35
(`mech_layout.scad:183,186`) subtends `2·asin(4/17.35) = 26.7°` = **303 steps = 4.74 states**.
One step at that radius is **0.0266 mm** of arc. So the switch point moves one step for every
26.6 µm of lateral field-threshold shift. A3144-class parts have built-in hysteresis
(Bop > Brp), which is exactly what makes a single edge repeatable — *provided the approach is
always from the same side and at a similar speed*. **Edge homing is good enough for the ±4-step
budget, but only if:**
- the sweep always enters the field from the same direction (a "back out first" phase);
- the air gap is fixed — `hall_air_gap = 0.5` plus `hall_floor_t = 0.4`
  (`cad/scad/hall_interface.scad:10-11`) means the sensor sits ~0.9 mm under the magnet face, and
  the switch angle is a strong function of that gap. Glue thickness under the magnet directly
  shifts home;
- the magnet is glued **south-face-down** (or whichever pole the part responds to). The A3144 is
  **unipolar**. Nothing in the repo states the homing magnet's polarity, and `handoff.md` shows the
  same 8×1 mm part is also used for dock polarity keying — where the two faces are deliberately
  opposite. A magnet fitted from the wrong pile never triggers.

The midpoint method in `breadboard_test.ino` is actually *more* repeatable than one edge (hysteresis
offsets partially cancel), at the cost of one extra half-revolution. Either is acceptable; **the
argmin is not.**

**Fix**
1. Power the A3144 at 5 V; 10 kΩ pull-up to 3.3 V; keep it on GPIO34 (or an MCP23017 input, §M-2).
2. Replace `tryHome()` with: back out until the field is absent → sweep in one fixed direction →
   latch the first assertion → optionally continue to the release edge and take the midpoint.
3. **Add a wire-fault check that cannot be silent:** before homing, assert the pin reads *deasserted*
   somewhere and *asserted* somewhere in one revolution, and that the asserted arc is
   250–400 steps wide (the expected 303 ± tolerance). Anything else is a fault → fault beep,
   `homed = false`, refuse to display characters.
4. Deboss or mark the magnet polarity on the cam pocket, and state it in the build pack.

---

## B-3 — MCP23017 at 3.3 V cannot reliably drive a ULN2003 input; the plan mandates 3.3 V
**VERIFIED (docs) / INFERRED (both datasheets)**

`docs/ELECTRONICS_PLAN.md:171-173`:

> "An MCP23017 powered at 5V does not guarantee a logic-high from ESP32 3.3V I2C. A real cell must
> power the expander at 3.3V from a local regulator … or use explicit level shifting."

The first sentence is correct. The conclusion drawn from it is the worse of the two options.

*INFERRED, from datasheets:*
- **ULN2003A input threshold.** The A-grade part is specified `V_I(on) = 2.7 V max` for
  `I_C = 200 mA`. Each input is a 2.7 kΩ series resistor into a Darlington base pair (≈1.4 V of
  Vbe), so at 3.3 V in the base drive is `(3.3 − 1.4)/2.7 k ≈ 0.70 mA`.
- **MCP23017 output high.** `V_OH` is specified as `Vdd − 0.7 V` at `I_OH = −3 mA`. At Vdd = 3.3 V
  and ~0.7 mA the realistic output is ≈ 3.0–3.2 V typical, **2.6 V worst case over the spec**.

So the drive sits at 2.6–3.2 V against a 2.7 V requirement — **0 to 0.5 V of margin, worst case
negative**, across temperature, four channels at once, and 200 mA coils. This is the exact failure
mode the same document warns about for the PCF8574 (`ELECTRONICS_PLAN.md:206-208`: "it will
half-work — the worst possible failure mode"). The MCP23017 at 3.3 V lands in the same place, one
notch better.

Half-driven Darlingtons do not fail cleanly. They come out of saturation, Vce rises from ~1.0 V to
several volts, coil current and torque collapse, and the ULN2003 package heats — inside a sealed
box, with no airflow, standing on edge (`cad/scad/electronics_spec.scad:85-91`).

**Fix — power the expander at 5 V and level-shift I2C properly.**
```
ESP32 3.3V  --[2.2k]--+                    +--[2.2k]-- 5V
                      |    BSS138 x2       |
   SDA/SCL  ----------+---||---------------+---------- SDA/SCL to every MCP23017
                      (gate to 3.3V, source=3.3V side, drain=5V side)
```
- MCP23017 at 5 V: `V_OH ≈ 4.3 V` into the ULN2003 — 1.6 V of margin instead of zero.
- The A3144 (5 V, §B-2) can then feed an MCP23017 input directly with no third rail.
- The shifter is **two BSS138 + four resistors, once, at the brain end** — about ₹40 total.

**Why 3.3 V-on-both-sides does not work, precisely:** the MCP23017 is CMOS, so its input
threshold is `V_IH = 0.8·Vdd`. At Vdd = 5 V that is **4.0 V**, and a 3.3 V pull-up cannot reach it.
This is also why `docs/WIRING_AND_ASSEMBLY.md:79` is wrong for this design:

> "No level shifter needed: ESP32 3.3V open-drain I2C works with 5V ATmega (reads >2.0V as HIGH)."

That is true of an **ATmega** (`V_IH = 0.6·Vcc = 3.0 V`, TTL-ish) and **false of an MCP23017**
(`0.8·Vdd = 4.0 V`). The sentence survived a part substitution. `docs/ELECTRONICS_BOM.md:152`
("Level shifters ❌ Not needed") must be reversed for the docked architecture.

*Bench measurement that settles it:* MCP23017 at 3.3 V driving one ULN2003 channel into a real coil;
measure the ULN output's `Vce` with a scope while all four channels switch. Above ~1.3 V it is not
saturating.

---

## B-4 — The chain's ground/voltage analysis counts one joint, not the chain
**VERIFIED (arithmetic on the repo's own numbers)**

`docs/BUILD_PACK.md:534-538` presents:

| Cells refreshing together | Current at the first joint | Drop on 1 pin | Drop on 2 pins |
|---|---|---|---|
| 8 | 2.0 A | 200 mV | 100 mV |

That is the drop **across the single joint nearest the brain**. The far cell's ground sits above the
brain's by the sum of the drops on **every joint between them**. With N cells each drawing I, joint
*j* (from the brain) carries `(N−j+1)·I`, so the total offset is `R·I·N(N+1)/2`.

Using the document's own constants (`R = 100 mΩ` per contact, doubled ground = 50 mΩ,
`I = 250 mA` per cell from `ELECTRONICS_PLAN.md:228`):

| Cells all moving | 5 V cumulative drop | GND offset at far cell | Far-cell rail | SDA as seen by ESP32 |
|---|---|---|---|---|
| 2 | 0.075 V | 0.038 V | 4.89 V | 0.44 V |
| 4 | 0.250 V | 0.125 V | 4.62 V | 0.53 V |
| 6 | 0.525 V | 0.263 V | 4.21 V | 0.66 V |
| **8** | **0.900 V** | **0.450 V** | **3.65 V** | **0.85 V** ⚠ |

(SDA figure = the far slave's `V_OL` of 0.4 V, plus its ground offset. ESP32 `V_IL = 0.25·Vdd = 0.825 V`.)

**Consequences the docs do not state:**

1. **The I2C bus fails at ~6 cells refreshing together, not at the 11-cell power limit.**
   Solving `0.4 + 0.0125·N(N+1) = 0.825` gives **N ≈ 5.4**. The document's headline
   ("What breaks first at scale? Power, ~11 cells", `ELECTRONICS_PLAN.md:22`) is wrong by 2×, and
   the thing that breaks first is the bus, which fails intermittently and silently rather than
   drooping visibly.
2. **The 5 V rail is worse off than the ground rail**, because it was deliberately left single-pin
   (`BUILD_PACK.md:200`). At 8 cells the far cell sees **3.65 V** at the connector, then loses a
   further ~1.0–1.3 V across the ULN2003 Darlington (*INFERRED*), leaving **~2.4 V on a 5 V coil —
   roughly half rated current and half rated torque.** On a mechanism the preprint audit already
   describes as short of torque by 3× (`docs/INDEPENDENT_PREPRINT_AUDIT_2026-09-04.md:56`,
   87 mN·m of friction against ~30 mN·m of motor), that is fatal.
3. **Sequential refresh really does fix it, and by a wide margin.** One cell moving at 250 mA,
   eight joints deep: 0.20 V on 5 V, 0.10 V on ground. The architecture is sound *only* under a
   strict one-motor-at-a-time rule.

**Fix**
1. Correct the table in `BUILD_PACK.md` §10 to the cumulative form and re-state the bus limit as
   **~6 simultaneous cells**, not 11.
2. **Make sequential refresh a firmware invariant, not a recommendation.** Today nothing enforces
   it: `showState()` is a blocking call with no global arbitration, and the brief's own goal is
   "8 cells refresh at once". Add a refresh queue in the brain with a hard mutex of one moving
   motor (two, at most, if the bench allows). Never expose an API that can start two.
3. Add a **per-cell 470 µF bulk capacitor across 5 V/GND**. It converts the 250 mA motor pulse into
   a local charge draw instead of a chain-wide one, and it is the cheapest half of the fix.
   `ELECTRONICS_BOM.md:22` ("Total passives to buy for the demo: zero") is true for one cell on a
   breadboard and false for a docked chain.
4. If the design must ever move more than two cells at once, the answer is not more pogo pins — it
   is **injecting 5 V/GND at both ends of the chain** (halves the worst-case path) or a second
   power feed at the mid-point.

*Bench measurement:* two cells through one real dock joint, DMM on the far cell's 5 V and a scope
between the far cell's ground and the brain's ground while both motors run. Measure the actual
contact resistance of the purchased pogo pair first — 100 mΩ is an assumption, and a magnetic
connector's resistance changes with wear and with the seating force the docking magnets provide.

---

# MAJOR

## M-1 — The shipped firmware still uses GPIO21/22 for the motor
**VERIFIED**

```
firmware/braille_cell/braille_cell.ino:66   #define IN3 21   // NOTE: GPIO21/22 are the default I2C pins.
firmware/braille_cell/braille_cell.ino:67   #define IN4 22   //   must move before the MCP23017 goes in (multi-cell).
firmware/breadboard_test/breadboard_test.ino:46-47   same
```
against
```
docs/BUILD_PACK.md:240-241   GPIO23 -> IN3 (was 21, frees SDA);  GPIO27 -> IN4 (was 22, frees SCL)
docs/ELECTRONICS_PLAN.md:104-116, :455   the same corrected map
```

The conflict is documented in three places and fixed in none. The code comment even names the
condition ("must move before the MCP23017 goes in") — but `dock_interface.scad:6` records the pogo
connector as **bought**, so the multi-cell build has already started while the firmware has not moved.

**Strapping pins:** *VERIFIED clean.* No GPIO 0, 2, 5, 12 or 15 appears in either sketch or in the
Part 10 map. That warning has been honoured.

**Two adjacent hazards the docs do not cover:**
- `docs/ELECTRONICS_PLAN.md:456` puts Cell 2's IN2 on **GPIO14**. GPIO14 is not a strapping pin, but
  it is one of the pins the ESP32 ROM **toggles at boot** (bootloader clock output). A motor coil on
  GPIO14 twitches on every reset. Use GPIO4 or GPIO16 instead.
- `docs/BUILD_PACK.md:278` puts a button on **GPIO17**. GPIO16/17 are consumed by PSRAM on
  **WROVER** modules. Fine on the WROOM-32 DevKit named in the docs; a silent failure if anyone
  substitutes a WROVER. State the module part number in the pin map.

**Fix:** apply the 23/27 change to both sketches now, before any solder goes near an ESP32 header,
and delete the conflicting tables rather than annotating them.

---

## M-2 — The MCP23017 migration is presented as "one ₹80 chip and nothing else". It is a firmware rewrite plus five components per cell.
**VERIFIED (docs) / INFERRED (AccelStepper internals, I2C timing)**

`docs/ELECTRONICS_PLAN.md:146`: "the honest answer is that it costs one ₹80 chip per brick and
nothing else." That is not the cost.

**(a) AccelStepper cannot drive an I2C expander.** *VERIFIED by inspection of the usage.*
`braille_cell.ino:70` constructs `AccelStepper(HALF4WIRE, IN1, IN3, IN2, IN4)`, which calls
`digitalWrite()` on four MCU pins from `setOutputPins()`. To step over I2C you must subclass
AccelStepper and override `setOutputPins()`, or abandon it for a hand-written half-step engine.
Nothing in the plan, BOM, or build pack mentions this. It is the largest single item in the
migration and it is costed at zero.

**(b) Step rate over I2C.** *Arithmetic, INFERRED constants.* One 1-byte register write is
`START + addr + reg + data ≈ 29 bit-times`:

| Bus speed | Per step | Ceiling (ignoring library overhead) |
|---|---|---|
| 100 kHz | ~290 µs | ~3.4 k steps/s |
| 400 kHz | ~72 µs | ~13.8 k steps/s |

The target is `vmax = 1000` steps/s (`braille_cell.ino:98`). At 100 kHz that is 29 % of the bus
consumed by one moving cell, plus ESP32 `Wire` per-transaction overhead of order 50–100 µs, which
is the same magnitude again. **It works, but only for one cell at a time** — which is already
required by §B-4, so the constraints agree. Say so explicitly rather than leaving it to be found.

**(c) Pull-up value forces 100 kHz, which the plan treats as a fallback.**
`ELECTRONICS_PLAN.md:240` and `WIRING_AND_ASSEMBLY.md:74-75` specify **4.7 kΩ**. Estimating bus
capacitance for an 8-cell chain (8 × 68 mm of wiring at ~1 pF/cm ≈ 55 pF, plus 8 × ~10 pF of pin
capacitance, plus the pogo joints) gives ~150–200 pF:

| C_bus | 4.7 kΩ rise time | 2.2 kΩ rise time |
|---|---|---|
| 100 pF | 398 ns | 186 ns |
| 180 pF | **717 ns** | 336 ns |
| 300 pF | **1195 ns** ✗ | 559 ns |

Standard mode (100 kHz) allows 1000 ns; fast mode (400 kHz) allows 300 ns. **4.7 kΩ cannot do
400 kHz on this chain at any realistic capacitance.** `ELECTRONICS_PLAN.md:247-248` presents
100 kHz as a debugging fallback; it is the design point. Either accept 100 kHz permanently and say
so, or specify **2.2 kΩ** (sink current 3.3 V / 2.2 k = 1.5 mA, well inside the 3 mA I2C minimum).

**(d) Per-cell components the BOM does not list.** *INFERRED, standard MCP23017 practice.*
`ELECTRONICS_BOM.md:114` lists "MCP23017 expander (DIP-28) + 3 address jumpers". Each cell also
needs:
- **RESET (pin 18) tied to Vdd** — the MCP23017 has no internal pull-up on RESET and stays held in
  reset if the pin floats. This is the single most common MCP23017 bring-up failure and it appears
  nowhere in the repo.
- **0.1 µF decoupling at Vdd/Vss**, required by the datasheet.
- **470 µF bulk** on the 5 V rail (see §B-4).
- **A0/A1/A2 tied hard high or low** — "3 jumpers" implies floating when open. Floating address pins
  give an intermittent, position-dependent address. They need pull-downs (or pull-ups) so an open
  jumper is a defined state.
- **10 kΩ Hall pull-up**, unless the MCP23017's internal ~100 kΩ (GPPU register) is used — which is
  acceptable with an open-collector sensor and would remove a part.

`ELECTRONICS_BOM.md:22` ("Total passives to buy for the demo: zero") and `:149` ("Resistors: none")
are correct for one breadboard cell and wrong for the docked cell. Split the BOM accordingly.

**(e) Package.** *VERIFIED contradiction with the stated reality.* Every document specifies
**DIP-28**: `ELECTRONICS_PLAN.md:203` ("DIP-28, hand-solderable"), `ELECTRONICS_BOM.md:114, :148`,
`BUILD_PACK.md:332`. The part actually owned is **MCP23017-E/SO, SOIC-28**. This is not a
downgrade — a DIP-28 (0.6", ~35.6 mm body) **cannot physically go in the cell**:
`cad/scad/electronics_spec.scad:41` sets `pcb_len = 28.0` and `:98` asserts
`pcb_len <= 34.0` ("board is longer than the clear band between the bosses"). The DIP-28 body alone
exceeds both. The SOIC-28 (≈17.9 × 7.5 mm body) does fit the board footprint. **The owned part is
the correct one and all four documents specify a part that would not fit.**

But: 1.27 mm pitch does not land on 2.54 mm perfboard, so it needs an **SOP28→DIP28 adapter**, and
that reopens the height budget. `electronics_spec.scad:55-60` computes
`elec_overall_h = 11.0 mm` in a `12.35 mm` gap (`:83, :96`) — **1.35 mm of spare**. A SOIC-28
(~2.35 mm tall) plus an adapter board on the reverse face of the same perfboard **does not fit**.
The expander needs its own space, and the CAD does not have any.

**Fix**
1. Rewrite `ELECTRONICS_BOM.md:114/148`, `ELECTRONICS_PLAN.md:203`, `BUILD_PACK.md:332` to SOIC-28
   and add the adapter to the BOM.
2. Re-run the `electronics_spec.scad` height budget with a real stacked board, or move the expander
   to a second perfboard elsewhere in the cell — and add both asserts.
3. Budget the AccelStepper subclass explicitly in the plan.
4. Add RESET, decoupling, address pull-downs and bulk cap to the per-cell BOM.

---

## M-3 — "Address = position" is false, and pin 5's justification depends on it
**VERIFIED**

`docs/ELECTRONICS_PLAN.md:192-194`: "**Address = position.** … Firmware scans the bus at boot and
**discovers how many cells are attached**."
`docs/BUILD_PACK.md:579`: "Detect which cells are attached → Scan I2C 0x20-0x27. The bus reports
presence and position."

An I2C scan reports **which addresses answer**. It cannot report **which physical socket** each one
is in. If a user docks cells whose jumpers read 0x22, 0x20, 0x25, the display renders the word in
the wrong order and nothing detects it. The whole selling point in `:186` — "adding a cell means
plug in, set 3 jumpers" — becomes "plug in, and re-set the jumpers on every cell downstream of the
insertion point," which is exactly the "rewire your neighbours" failure the shared-expander option
was rejected for (`:185`).

Two identical jumper settings on one bus is worse: two slaves ACK the same address, both act on
every write, and a scan sees one device. There is no detection for that either.

`BUILD_PACK.md:576-584` uses this false claim to justify never reassigning pin 5. The reasoning is
circular: pin 5 is a second ground *for good electrical reasons* (§B-4 agrees), but "the bus reports
position" is not one of the reasons and should be struck.

**Fix — pick one and write it down:**
- **Accept manual ordering.** The brain asks at boot: "press SELECT on the leftmost cell." Costs
  one button per cell, but the MCP23017 has 11 free pins (`BUILD_PACK.md:584` says so itself).
- **Or** enumerate over the existing pins: each cell drives a "downstream present" MCP output to the
  next cell's MCP input. This needs one extra dock conductor and therefore a 6-pin connector — the
  5-pin part is already bought, so this is now expensive.
- **Or** make order irrelevant: address = content. Every cell shows what it is told by address, and
  the *user* is told to arrange them by address. Print the address on the shell.

Whichever is chosen, add a boot check that the discovered address **set** is contiguous from 0x20,
and beep the fault pattern (§O-2) if it is not.

---

## M-4 — Blocking motion inside a BLE callback and inside `loop()`
**VERIFIED**

`braille_cell.ino:143` `void runToTarget() { while (stepper.distanceToGo() != 0) stepper.run(); }`

- **Called from a BLE write callback.** `BleRxCB::onWrite` (`:271-279`) → `handleLine()` →
  `showChar()`/`showState()` → `runToTarget()`. A 180° move is 2048 steps; at the acceleration-
  limited rates the header itself describes (`:96-97`, "never gets past 179 steps/s on a single
  letter"), a multi-character word blocks the BLE stack callback for **many seconds**. A typed word
  additionally runs `delay(gapMs)` per character (`:374`). *INFERRED:* blocking the ESP32 BLE host
  callback for seconds causes link supervision timeouts, dropped connections, and in some
  IDF/Arduino combinations a stack assert. This is very likely the first thing that misbehaves on
  a real demo.
- **No yield anywhere in the loop.** `AccelStepper::run()` returns immediately when it is not time
  to step, so this is a tight spin. *INFERRED:* with the loop task pinned to core 1 and no
  `delay(0)`/`yield()`, the core-1 idle task is starved, which is the classic
  `Task watchdog got triggered (CPU 1): IDLE1` panic. `breadboard_test.ino` calls
  `server.handleClient()` inside the same loop (`:291, :336`) — the older sketch was better behaved.
- **HTTP handlers block too** (`handleState`, `:228`), deliberately, as the "done" signal. That is a
  defensible protocol choice for HTTP; it is not defensible inside a BLE callback.

**Fix**
1. Make `runToTarget()` call `delay(0)` (or `vTaskDelay(1)`) whenever `distanceToGo() != 0` and no
   step is due.
2. Do not move inside the BLE callback. Push the command into a queue
   (`xQueueSendFromISR`-style or a simple volatile buffer), return immediately, and run motion from
   `loop()`. Notify "ok" on the TX characteristic **after** arrival — the contract in the comment
   at `:277` is preserved, and the callback stops blocking.
3. This is also the structure §B-4's one-motor-at-a-time rule needs.

---

## M-5 — De-energising the coils is an architectural rule with an unstated mechanical dependency
**VERIFIED (code, CAD) / INFERRED (back-drive behaviour)**

`braille_cell.ino:146-149` `releaseCoils()` is called after every move (`:167`), and
`ELECTRONICS_PLAN.md:234` calls it "an architectural rule, not a nicety." Electrically that is
correct and important: 250 mA × 5 V is ~1.25 W per idle cell, and 20 cells held energised is a 60 W
supply for static text.

What no document says is **what holds the dots up once the coils are off.** In the current cell the
cam *is* the hold: the raised dots' springs press down through the followers onto the cam surface.
A 28BYJ-48's spur/planetary train is **not** self-locking — it back-drives. It is safe only while
every follower sits on a **flat dwell**, which is precisely why `DWELL_OFFSET = 32` exists
(`braille_cell.ino:75`).

That couples directly to §B-1: **any position error large enough to put one follower on a ramp means
the cam self-rotates when the coils are released**, moving all six dots. The tolerance is the same
±4.2 steps, and the two known error sources (20 steps/rev of ratio error, ~11 steps of backlash)
both exceed it. So the release-when-idle rule and the position-accuracy problem are one problem,
not two.

Note also that `docs/MULTICELL_ARCHITECTURE.md:94` ("Once set, the line holds with **zero power**")
is a property of the **travelling-cam + latching pin** architecture in that document, not of the
cell being built. It should not be quoted as a property of the current design.

*Bench measurement:* home, move to a state, release coils, read the Hall/step count and photograph
the dots; wait 60 s; re-read. Repeat with a deliberate ±8-step offset from mid-dwell. Repeat with
the cell held vertically and upside down.

**Fix**
- Keep `releaseCoils()`. Add a **verify-after-release** step: re-read position on the next command
  and re-home if the Hall phase disagrees.
- If back-drive is measured, the answer is a detent, not holding current. A small friction washer or
  an O-ring on the cam hub costs no power. Holding current does not scale past ~2 cells.

---

## M-6 — ULN2003 saturation loss is nowhere in the torque or thermal budget
**INFERRED (datasheet) / VERIFIED (the torque deficit it compounds)**

*INFERRED:* a ULN2003A Darlington sinking 200 mA has `V_CE(sat) ≈ 1.0–1.3 V`. The coil therefore
sees ~3.8 V of a 5 V supply — a **~22 % current and torque loss** before any wiring drop.

`docs/INDEPENDENT_PREPRINT_AUDIT_2026-09-04.md:56` already estimates ~87 mN·m of spring-induced cam
friction against a ~30 mN·m motor. A further 22 % off the motor makes a 3× deficit a 3.7× deficit.
None of the plan's power tables (`ELECTRONICS_PLAN.md:225-229`, `:466-475`,
`WIRING_AND_ASSEMBLY.md:82-87`) subtract it, and the chain drop in §B-4 stacks on top:
**far cell, 8 moving = 3.65 V rail − 1.1 V saturation ≈ 2.5 V across a 5 V coil.**

Thermal, in a sealed box: in half-step mode two phases are energised on alternate steps, so
`2 × 200 mA × 1.1 V ≈ 0.44 W` continuous while moving, in a DIP-16 standing on edge against a wall
(`electronics_spec.scad:85-91`) with a warm motor beside it and no vent modelled anywhere.
*INFERRED:* θ_JA for a socketed DIP-16 with no airflow is ~70–90 °C/W → a 30–40 °C rise on top of an
enclosed ambient. Survivable while moving; not survivable if a firmware bug ever leaves coils on.

**Fix**
1. Put the saturation drop into every power/torque table, or state the measured coil voltage instead.
2. `electronics_spec.scad:34` already specifies a DIP socket "because a ULN2003 dies shorted when a
   coil kicks back" — good call, keep it.
3. Add a firmware watchdog: if coils have been energised for more than N seconds with no commanded
   move, force `releaseCoils()` and beep the fault pattern.
4. *Bench measurement:* scope one ULN output while the motor runs; read `V_CE`. Thermocouple or IR
   on the package after 5 minutes of continuous stepping with the lid on.

---

## M-7 — ULN2003 COM (pin 9) is never explicitly instructed anywhere
**VERIFIED (absence)**

The BOM's headline claim rests on it:
`ELECTRONICS_BOM.md:15` — "Motor flyback diodes: **Built into the ULN2003A.** The chip has internal
freewheeling diodes on its COM pin — that is what COM is for."
`ELECTRONICS_BOM.md:151` — "Flyback diodes ❌ Built into the ULN2003A (that's what COM does)."

Those diodes only exist as a circuit if **COM (pin 9) is wired to the coil supply**. On the blue
breakout module it is done for you. `cad/scad/electronics_spec.scad:8-9` drops the module for a
**bare ULN2003AN on perfboard**, and the only reference to COM after that is an oblique mention of
"the flyback commons" among the pad list (`:40`). Searching every `.md` in `docs/` returns no
instruction to connect pin 9 (the matches for "COM" are all serial port names).

If pin 9 is left open, the first coil de-energisation puts an unclamped inductive spike on the
output. The same file already warns the part "dies shorted when a coil kicks back" (`:31`).

**Fix:** add one line to the build pack, in bold: *"ULN2003AN pin 9 (COM) → motor RED wire / +5 V.
Without this wire the chip has no flyback diodes and will fail on the first move."* Add a continuity
check for it to the pre-power checklist.

---

# MINOR

## N-1 — Hardcoded AP password, and an unauthenticated motor-control API
**VERIFIED**

`firmware/braille_cell/braille_cell.ino:54`
```c
const char* AP_PASS = "braillix2026";     // >= 8 chars or softAP() opens it wide
```

Confirmed present. The comment at `:51-52` argues it is not a personal secret, and
`USE_WIFI = false` at `:59` means it is dead code today. As a *credential* the risk is low.

The more interesting exposure, if WiFi is ever switched on, is the **API itself**:
- `cors()` (`:221`) sets `Access-Control-Allow-Origin: *` on every response, and
  `server.onNotFound` (`:253`) answers preflight for everything.
- `/s?v=0-63`, `/home`, `/speed` have **no authentication of any kind** (`:223-243`).

So while the laptop is joined to the AP, **any web page it has open** can `fetch('http://192.168.4.1/s?v=63')`
and drive the motor. `:55-58` notes the mixed-content block stops the GitHub Pages simulator; it does
not stop a plain-http page or a fetch with `mode: 'no-cors'` (which still sends the request).
BLE is likewise open — the NUS characteristic accepts writes with no pairing or bonding.

For a demo device this is acceptable. It should be a stated decision, not an accident.

**Fix**
- Move `AP_PASS` to `secrets.h` (gitignored) with a `secrets.h.example` committed, matching the
  project's own secrets convention. The sketch header at `:13` claims "secrets.h is not needed",
  which is what let the literal in.
- Replace `Allow-Origin: *` with the actual simulator origin, or require a shared token query
  parameter on the mutating endpoints.
- Add one line to the README stating the demo transport is unauthenticated by design.

## N-2 — Button and buzzer pins conflict three ways
**VERIFIED**

| Signal | `WIRING_AND_ASSEMBLY.md` | `BUILD_PACK.md` | `ELECTRONICS_PLAN.md` Part 10 | `SOFTWARE_TEAM_README.md` |
|---|---|---|---|---|
| Prev/Back | GPIO32 (`:70`) | GPIO32 (`:276`) | GPIO32 (`:459`) | GPIO32 (`:152`) |
| Select | **GPIO33** (`:71`) | GPIO25 (`:277`) | GPIO25 (`:459`) | **GPIO33** (`:152`) |
| Next | GPIO25 (`:72`) | **GPIO17** (`:278`) | **GPIO17** (`:459`) | GPIO25 (`:152`) |
| Buzzer | **GPIO26** (`:73`) | — | — | — |
| Cell 2 IN3 | — | — | **GPIO26** (`:456`) | — |
| Cell 2 IN4 | — | — | **GPIO33** (`:456`) | — |

GPIO26 is both the buzzer and a motor coil. GPIO33 is both Select and a motor coil. Neither sketch
implements buttons or a buzzer at all, so nothing has failed yet — which is exactly why it will be
wired from whichever table is open at the time.

**Fix:** delete three of the four tables. One frozen pin map, in one file, referenced everywhere
else by link. Given §M-1's move to 23/27 and §M-2's expander, that map has to be rewritten anyway.

## N-3 — Dock pinout: 4 pins in one doc, 5 in another
**VERIFIED**

`docs/WIRING_AND_ASSEMBLY.md:27-30` — "Pogo Daisy-Chain Pinout (**4-pin**, same everywhere):
1 = +5V, 2 = GND, 3 = SDA, 4 = SCL", repeated in the quick reference at `:118`.
`docs/BUILD_PACK.md:517-523` — five pins, `GND SCL 5V SDA GND`.
`cad/scad/dock_interface.scad:65` — `pogo_pins = 5` (the bought part).

The 4-pin doc also still describes an **ATmega** muscle board (`:51` "J4 (ISP) … AVR programmer",
`:79`, `:124` "solder jumpers PB0-PB2" — AVR port names), a part killed in
`ELECTRONICS_PLAN.md:33`. Its 3-wire hall connector `J3` names an **SS49E** (`:50`), a part
superseded by the A3144 in `ELECTRONICS_BOM.md:18`. Its power budget (`:83`) counts "ATmega 20mA".

This whole file is a v6.1 artefact. `ELECTRONICS_PLAN.md:42-45` already lists it as stale, and the
preprint audit asks for it to be labelled historical
(`INDEPENDENT_PREPRINT_AUDIT_2026-09-04.md:145`). It still reads as current, with no banner on the
pinout sections.

**Fix:** put a `HISTORICAL — v6.1` banner at the top of every superseded section, or move the file
to `_archive/`. A wiring table that is wrong is worse than no wiring table.

## N-4 — I2C has no hot-plug story on a magnetic connector
**INFERRED**

The dock is magnetic and explicitly designed to come apart
(`ELECTRONICS_PLAN.md:258` "Never glue the inter-brick connection"). But:

- **Hot-plugging an I2C slave** while a transfer is in flight can leave SDA held low by a slave that
  saw a partial byte. The ESP32 master then sees a permanently busy bus. There is **no bus-recovery
  routine** anywhere (the standard fix is nine SCL pulses followed by a STOP).
- **Contact bounce.** A spring pogo pin makes and breaks several times as a magnet pulls the cells
  together. Every bounce is a glitch on SDA/SCL.
- **Inrush.** Docking connects a cold cell's decoupling and (per §B-4) 470 µF bulk to a live 5 V rail
  through ~100 mΩ. That is a large, fast current step on the rail every cell that is added.

**Fix**
- Add an I2C bus-recovery routine and call it on any transaction timeout.
- Rescan the bus after any recovery and re-home cells that report as new.
- Either state "power off before docking" as a build rule, or add a small series resistor
  (10–47 Ω) in each cell's 5 V feed to soften inrush and accept the extra drop.
- *Bench measurement:* scope SDA while docking a live cell 20 times; count how often the bus hangs.

## N-5 — Brownout
**INFERRED**

*INFERRED:* the ESP32's brownout detector trips at ~2.7 V on the 3.3 V rail; the AMS1117 on the
DevKit needs ~1.1 V of headroom, so a dip below ~4.4 V on 5 V starts to matter.
`ELECTRONICS_BOM.md:150` and `BUILD_PACK.md` §3.2 already flag this for the VIN-powered case and
recommend a 470–1000 µF cap "to have on hand". In a docked chain it stops being optional (§B-4).

`ELECTRONICS_PLAN.md:228` budgets the ESP32 at 250 mA. *INFERRED:* the ESP32 WiFi TX peak is
~500 mA for ~2 ms bursts, and BLE advertising adds smaller bursts. With `USE_BLE = true` by default
(`braille_cell.ino:60`) that burst coincides with motor stepping on the same rail.

**Fix:** 470 µF at the ESP32's 5 V input **and** in each cell; do not rely on the DevKit's own caps.
Log `esp_reset_reason()` at boot and beep the fault pattern on `ESP_RST_BROWNOUT` so a marginal
supply is diagnosable rather than mysterious.

## N-6 — `firmware/main.py` is not firmware
**VERIFIED**

`firmware/main.py:1-8` is a pure-Python demo runner for `braille_converter.py`. It contains no
hardware, no serial, no I2C. It is named and located as if it were the device's main program, and
the preprint audit lists "python firmware/main.py passed" among its hardware-adjacent checks
(`INDEPENDENT_PREPRINT_AUDIT_2026-09-04.md:37`). It proves the braille encoding tables and nothing
about the electronics. Move it to `tools/` or `tests/`, or rename it `braille_converter_demo.py`.

---

# OBSERVATION

## O-1 — The scaling architecture and the dock architecture disagree
**VERIFIED**

`docs/MULTICELL_ARCHITECTURE.md` is the most rigorous document in the repo, and it concludes:

- a 68 mm cell is **11× the standard 6.1–6.5 mm braille pitch** (`:29`);
- "**Eight motors for eight cells.** … 8 × 68 mm of box is 544 mm. Geometry kills it, not cost."
  (`:41-42`);
- the architecture that escapes the wall is **one travelling cam head over latching pins** (`:73`),
  where "the number of motors stops scaling with the number of cells" (`:77`);
- and the recommendation is "build four cells, not eight" of the *travelling* kind (`:165`).

The MCP23017-per-brick, pogo-dock, address-jumper architecture audited above builds
**exactly the thing that document rejects**: eight motors in eight 68 mm boxes. It is a good
*demonstration* of modularity and a poor braille display, and nothing in `ELECTRONICS_PLAN.md`,
`BUILD_PACK.md` or `handoff.md` acknowledges the disagreement.

This is not an electronics defect and it is not mine to resolve. But every hour spent on §B-3 and
§M-2 is spent on the rejected branch, and someone should say so out loud before the expanders are
soldered. If the dock exists to prove modularity to a panel, two cells prove it as well as eight —
and two cells need no expander at all (`ELECTRONICS_PLAN.md:441-448`).

## O-2 — The buzzer: a concrete vocabulary, and what it actually costs
**VERIFIED (the gap) / design proposal**

Present state: `docs/SHOPPING_LIST.md:27` lists a 12 mm piezo at ₹15 (optional);
`docs/WIRING_AND_ASSEMBLY.md:73` assigns GPIO26 (which collides, §N-2);
`docs/Project Braillix - AI Context & Hardware Spec.md:68` states the UX intent
("device beeps, user lifts finger, motor spins, beeps again"). **No behaviour is defined and no
firmware exists.** The prior audit proposed four cues
(`INDEPENDENT_PREPRINT_AUDIT_2026-09-04.md:114-122`); this refines them with the parts and the
timing constraints.

**One correction to that proposal first.** "Low beep" / "high beep" does not survive contact with a
housed piezo transducer: those parts have a sharp Helmholtz resonance near **3–4 kHz** and are
30–40 dB quieter an octave below it. A 400 Hz "low beep" will be inaudible in a classroom.
Keep both tones **inside the resonance**, and carry the meaning in the **count and rhythm**, which
also serves anyone with high-frequency hearing loss.

**Proposed vocabulary** (passive piezo, `ledcWriteTone`):

| Event | Tone | Pattern | Meaning to the reader |
|---|---|---|---|
| Button press accepted | 2200 Hz | 1 × 40 ms | "Heard you — lift your finger." Fires **before** motion. |
| Motion complete | 3000 Hz | 1 × 80 ms | "Safe to read." Fires **after** arrival. |
| Ready / homed | 2200 → 3000 Hz | 2 × 60 ms rising | Boot complete, position trusted. |
| Fault | 1800 Hz | 3 × 150 ms, 100 ms gaps | Home failed, cell missing from the bus, brownout reset, or coil-timeout. **Do not trust the dots.** |
| End of text / no next cell | 3000 → 2200 Hz | 2 × 60 ms falling | Boundary reached; nothing moved. |

Rules: **never beep while the motor is moving** (the whole point is that the finger is off), and
never distinguish two states by pitch alone.

**What it costs**

| Item | Cost |
|---|---|
| Pins | **1 GPIO.** Recommend **GPIO4** — free in every table, not a strapping pin, no boot glitch, not ADC2. Not GPIO26 (§N-2). |
| Parts | 1 × 12 mm passive piezo transducer, ₹15. Already in `SHOPPING_LIST.md:27`. |
| Drive | Direct from the GPIO. A **passive piezo** is capacitive and draws <5 mA — safe on a 40 mA-rated pin. ⚠️ A **5 V active/magnetic buzzer** draws 20–30 mA and must not be driven directly; it needs a transistor and a flyback diode. Specify the passive type explicitly in the BOM, because the two look identical. |
| Code | ~45 lines: `ledcAttach(BUZZ, 2200, 8)`, a 5-entry pattern table, and a non-blocking `{tone, ms}` sequencer stepped from `loop()`. |
| Blocking | **Zero, if the sequencer is non-blocking.** A `delay()`-based beep inside `runToTarget()` would stall the stepper (§M-4). Because every cue brackets a move rather than overlapping it, a blocking beep is *tolerable* today — but it stops being tolerable the moment §M-4's queue lands. Write it non-blocking the first time. |
| Multi-cell | The buzzer lives in the **brain pod only**, one per device, not per cell. It costs nothing at the dock. |

## O-3 — Things that are right, and should not be "fixed"
**VERIFIED**

Stated because an adversarial review that lists only defects is misleading about where the risk is:

- **Pin 5 as a second ground** (`BUILD_PACK.md:517-541`) is the correct call for the correct reason:
  ground carries both the return current and the I2C reference. The arithmetic in §B-4 makes it more
  necessary, not less. (Only the "bus reports position" justification at `:579` should be struck.)
- **Symmetric pinout about pin 3** (`BUILD_PACK.md:552-560`) — a reversed connector swaps only
  SDA/SCL and damages nothing. Good, cheap defence.
- **`releaseCoils()` after every move** (`braille_cell.ino:167`) — correct, and the reason the power
  budget closes at all. (Its mechanical dependency is §M-5.)
- **The DIP socket for the ULN2003** (`electronics_spec.scad:31-35`) — correct, for exactly the
  reason given.
- **MCP23017 over PCF8574** (`ELECTRONICS_PLAN.md:196-208`) — the reasoning about weak high-side
  drive is right. It just needs applying to the MCP23017's own supply voltage (§B-3).
- **Strapping pins avoided** — verified clean in both sketches and in the Part 10 map.
- **`shortestTarget()`'s wrap arithmetic** (`braille_cell.ino:134-138`) and the Gray→binary
  conversion (`:120-129`) are both correct; the state→step mapping is sound. The problem is the
  *direction reversal* it permits (§B-1b), not the maths.
- **MCP23017 outputs default to inputs after reset**, so a hot-dock or brownout leaves the ULN2003
  inputs floating — and a floating ULN2003 input is pulled low through its own base network, so the
  coils stay **off**. That is a safe default and it is worth knowing it is safe.

---

# What a bench session should measure, in order

Nothing above needs a redesign to test. Six measurements settle most of it.

| # | Measurement | Settles |
|---|---|---|
| 1 | Steps between successive Hall leading edges, ×10 | §B-1a — the real steps/rev, replacing 4096 |
| 2 | Cam angle after +200/−200 steps, dial indicator on the rim | §B-1b — actual backlash vs the ±4.2-step budget |
| 3 | A3144 output while sweeping the 8×1 magnet, at 3.3 V then 5 V | §B-2a — whether the chosen sensor works at all on the chosen rail |
| 4 | ULN2003 `V_CE` on a scope with the coil running | §M-6 — the real saturation loss, feeding the torque budget |
| 5 | MCP23017 at 3.3 V driving one ULN channel; same scope | §B-3 — whether the marginal drive actually saturates |
| 6 | Two cells through one real dock joint: far-cell 5 V, and a scope between the two grounds, both motors moving | §B-4 — the real contact resistance and ground offset, which is the only number the chain limit depends on |

Measurements 1, 2 and 3 are an evening and they gate everything mechanical.
Measurement 6 needs the pogo carrier printed and is the gate on the whole docked architecture.
