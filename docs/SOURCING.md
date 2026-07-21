# Braillix — Hardware Sourcing Guide (India)
> Created 2026-06-12 (v6.1). What to buy, what to search for, what's already in hand.

## ✅ Already in hand (validated)
| Item | Status |
|---|---|
| 28BYJ-48 stepper + ULN2003 driver module | working on breadboard |
| ESP32 DevKit V1 | working, WiFi + OTA tested |
| NeFeB disc magnets **8mm dia × 1mm thick** | plenty — CAD v6.1 pockets sized for these |
| Hall sensor (SS49E-class) | validated (saturates 0/4095, fine for edge homing) |
| 6×6mm tactile switches ×3 | in hand |
| 5.5/2.1mm barrel jack + 5V/3A adapter | in hand |
| Jumper wires (Dupont) | in hand (housings get cut off for in-cell wiring) |

## 🛒 TO BUY

### 1. Return springs ×6 (+ spares) — the only fiddly item
**Spec the CAD assumes:** OD ≤ 4.5mm, free length 5–6mm, VERY soft (≤ 0.1 N/mm —
the 28BYJ-48 must compress all 6 at once without stalling).
- Search: **"micro compression spring 4mm OD"** / "small compression spring assorted kit"
  on robu.in, Amazon.in, or a local hardware market.
- **Free fallback that usually works:** springs from click-type ballpoint pens
  (Cello/Reynolds clicky pens) — typically ~4mm OD and very soft. Cut to ~6mm with
  side cutters. Buy 3–4 pens, that's 3–4 springs each... well, one each, so 6 pens. 😄
- Bench-test before final assembly: motor must complete a full cam revolution with all
  6 linkages + springs loaded. If it stalls → softer springs or trim coils.

### 2. Homing magnets 3×2mm ×1 per cell — small but specific
Your 8×1mm magnets are for DOCKING. The cam's homing pocket (`braille_cam.scad`) needs a
**3mm dia × 2mm thick** disc — an 8mm one won't fit the 2mm-thick cam base.
- Search: **"3x2mm neodymium magnet"** on robu.in / Amazon.in — ₹100–200 for 10–20 pcs.
- Glue flush into the cam underside pocket at r=17.35 (the 90° position).

### 3. Bearing balls 2mm ×6 (+ spares) — easy
- Search: **"2mm steel balls bearing"** on Amazon.in / robu.in — usually sold 100+ for
  ₹100–250. Stainless preferred (chrome steel is fine too, indoors).
- Glued (CA/superglue) onto the linkage nub tips. Buy once, lifetime supply.

### 4. Pogo connector (4-pin) — DEFERRED DECISION (per v6 audit)
Don't buy until the design is pinned. Two candidate styles:
- **Spring-loaded pogo pin strip, 4-pin, 2.54mm pitch** (search "pogo pin connector 4 pin
  2.54mm") — what the CAD windows roughly assume; needs a mating flat-pad part.
- **Magnetic pogo connector module** (search "magnetic pogo connector 4 pin") — combines
  the magnet + contacts in one part; would simplify the dock AND solve the upside-down
  anti-reversal problem at the connector level (these are polarized).
**When the part arrives → measure it → update `pogo_carrier_*` dims in outer_box.scad
before the final print.** Current pocket dims are placeholders.

### 5. Fasteners (one trip to a fastener shop / one Amazon order)
| Item | Qty (1 cell + pod) |
|---|---|
| M2.5 × 25mm bolts | 4 |
| M2 × 6mm self-tap screws | 6 (4 muscle-board*, 2 pod lid) |
| M4 × 10mm bolts + nuts | 2 (motor ears) |
*not needed while running the ULN2003-on-floor prototype

### 6. Consumables
CA glue (balls + magnets), silicone grease (cam tracks), heat-shrink, solder.

## 🏭 NOT bought — manufactured
| Item | How |
|---|---|
| Linkages ×8 (6+2 spares) | **Resin print** with the cam/top_plate/nav_cap batch — tough/ABS-like resin, flat on plate (v6.1 decision; was laser-cut metal) |
| Muscle board PCB | Deferred — prototype runs the off-the-shelf ULN2003 module on the pocket floor (see WIRING_AND_ASSEMBLY.md) |
