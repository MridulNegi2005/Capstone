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

### 1. Return springs x6 (+ spares) — 2mm OD MICRO springs
**Spec: 2.0mm OD, ~0.3mm stainless wire, ~4mm free length.** One per braille dot.

> ⚠️ **Ballpoint-pen springs CANNOT be used.** They are ~4mm OD and need ~4.2mm of
> spacing; braille rows are only **2.6mm** apart, so a pen spring would overlap the
> spring of the dot above it by 1.4mm. This is geometry, not preference — no nub size
> fixes it. 2mm OD is the largest that fits (0.6mm to spare).

- Search **"micro compression spring 2mm OD"** or **"compression spring assortment kit"**
  on Amazon.in. 2mm/3mm/4mm/5mm/6mm OD in 0.3mm stainless is a standard catalogue range.
- **Buy an assortment kit** (200-400pcs, 15-30 sizes, roughly Rs 400-700) rather than one
  size — it covers us if the free length needs adjusting after the first assembly.
- If a seller offers **0.2mm wire**, prefer it: same OD but a wider bore, which gives more
  clearance around the 1.0mm nub.
- Working range in the design: 3.5mm when the dot is down, 2.7mm when raised. A ~4mm free
  length with ~5 coils is ideal (1.5mm solid height, so it never bottoms out).

**Fitting them:** thread each spring over the 1.5mm dome by TWISTING it on (the coil acts
like a thread against the 1.4mm bore — 0.1mm interference, trivial for steel). Then it sits
on the linkage flange and drops into the counterbore in the top plate. Glue optional.

**Backup if springs cannot be sourced:** a small disc of **soft open-cell sponge** in place
of each spring. Must be squishy sponge/upholstery/packing foam — **NOT stiff EVA craft
foam**, which is roughly 20x too stiff and risks stalling the motor. Free from packaging.
The printed parts are identical either way, so this can be tested without a reprint.

### 2. Homing magnets 3×2mm ×1 per cell — small but specific
Your 8×1mm magnets are for DOCKING. The cam's homing pocket (`braille_cam.scad`) needs a
**3mm dia × 2mm thick** disc — an 8mm one won't fit the 2mm-thick cam base.
- Search: **"3x2mm neodymium magnet"** on robu.in / Amazon.in — ₹100–200 for 10–20 pcs.
- Glue flush into the cam underside pocket at r=17.35 (the 90° position).

### 3. ~~Bearing balls 2mm~~ — NO LONGER NEEDED (v7.1)
The braille dot is now **printed as a dome on the linkage itself**. No steel balls, no
glue, no machined cup. If you already bought balls, keep them for something else.

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
