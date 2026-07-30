# Braillix — Electronics BOM (HAVE on top, BUY at bottom)
> Written 2026-07-30. Companion to `docs/MASTER_BOM.md` (which also covers mechanical parts).
> Scope: **one working single-cell demo.** Multi-cell/production parts are listed separately
> at the end so they are not confused with what you need now.

---

## ⚡ The headline: you need NO chips, NO resistors, NO capacitors

Every discrete component the circuit would normally need is **already built into the modules
you own**:

| What you'd normally add | Why you don't need it |
|---|---|
| Motor flyback diodes | **Built into the ULN2003A.** The chip has internal freewheeling diodes on its COM pin — that is what COM is for. |
| Motor driver transistors | **That IS the ULN2003.** Seven Darlington pairs, 500mA each. You need four. |
| Button pull-up resistors | ESP32 has **internal** pull-ups. Firmware uses `INPUT_PULLUP`. |
| Hall sensor pull-up / comparator | **On the blue MH module already** (that's the second IC and the trimmer pot). |
| Voltage regulator + decoupling caps | **On the ESP32 DevKit already** (AMS1117 + caps). |
| Reverse-polarity protection | ⚠️ **NOT present.** This is why the multimeter matters — see below. |

**Total passives to buy for the demo: zero.**

---

# PART 1 — WHAT YOU ALREADY HAVE
*Cross-check each of these physically. The "how to identify it" column is so you can confirm
you actually have the right thing.*

| # | Component | How to identify it | Qty | Status |
|---|---|---|---|---|
| 1 | **ESP32 DevKit (USB-C)** | Black PCB ~51×28mm, silver square shield, USB-C at one end, 15 pins per side, BOOT + EN buttons | 1 | ✅ HAVE (₹350) |
| 2 | **28BYJ-48 stepper motor** | Silver can ~28mm dia, blue plastic base, 5 coloured wires into a white plug | 1 | ✅ HAVE (₹160 w/ driver) |
| 3 | **ULN2003 driver board** | Small **blue** PCB, 4 red LEDs, white 5-pin socket, black 16-pin chip, IN1–IN4 + `+`/`-` pins | 1 | ✅ HAVE — **this is your motor driver, no chip to buy** |
| 4 | **Hall sensor module (MH-Sensor-Series)** | Small **blue** PCB, tiny black 3-pin sensor on one edge, blue trimmer pot, 1–2 LEDs, pins marked **AO DO GND VCC** | 1 | ✅ HAVE (₹50) — ⚠️ **must use AO (analog)**, and the pocket won't fit it (see note) |
| 5 | **5V / 3A power adapter** | Wall plug, barrel connector on the lead, "5V 3A" on the label | 1 | ✅ HAVE (₹160 w/ jack) |
| 6 | **Barrel jack (screw terminal)** | Small yellow/black block, barrel socket one end, two screw terminals the other | 1 | 🔴 HAVE but **polarity NEVER verified** — see below |
| 7 | **Connecting wire (2m)** | Loose hookup wire | 2m | ✅ HAVE (₹20) |
| 8 | **Dupont jumper wires** | Ribbon of coloured wires with plastic pin housings | some | ✅ HAVE — need ~8× M-F and ~5× M-M |
| 9 | **Neodymium magnets 8×1mm** | Small silver discs, strongly attract each other | 10 | ✅ HAVE (₹135) — for docking, **not** for cam homing |
| 10 | **Tactile switches 6×6×5mm** | Tiny square black buttons, 4 legs | 3 | ✅ HAVE — not needed for the demo |
| 11 | **Soldering iron** | — | 1 | ✅ HAVE |

### 🔴 Two warnings about things you already have

**#6 — the barrel jack polarity is still unverified.** There is no reverse-polarity protection
anywhere in this circuit. If the centre pin is negative and you wire it as positive, the ESP32
dies instantly and silently. **This is the single most likely way to lose ₹350 in this project.**
Check it with a multimeter before anything is powered. Procedure is in `ASSEMBLY_BIBLE.md` Step 1.

**#4 — your hall module does not fit its pocket.** The base plate pocket is 5.3 × 4.3 × 3mm,
designed for a *bare* TO-92 sensor, not a PCB module. (It also turns out that pocket is entirely
swallowed by the cam pocket, so it doesn't exist on the printed part at all — see
`CAD_FIT_CHECK.md`.) **For the demo this does not matter** — the module sits on the breadboard.
For assembly later you either desolder the bare 3-pin sensor off the module, or redesign the pocket.

---

# PART 2 — WHAT YOU NEED TO BUY

## 2A. For the demo (buy this week)

| # | Component | Spec | Why | Est. ₹ |
|---|---|---|---|---|
| 1 | **Digital multimeter** | Any basic DMM with DC volts | 🔴 **MANDATORY.** Verifies barrel jack polarity before power-up. Also your only way to debug a dead rail. | ~500 |
| 2 | **Breadboard** | Half-size or full-size, 400–830 tie points | The whole Tier-0 demo is breadboard-based, and it's the safe way to bring up wiring before soldering. | ~100 |
| 3 | **USB-C cable (DATA)** | Must carry data, not charge-only | To flash the ESP32. Charge-only cables look identical and fail silently. **Test the one you have first — you may already be fine.** | ~150 |
| 4 | **Solder wire** | **0.8mm, 60/40 rosin core** | For soldering wires flat to the ULN2003. Not plumbing solder. | ~150 |
| 5 | **Wire stripper / cutter** | Small, for 22–26 AWG | Prepping wire ends. | ~200 |

**Demo subtotal: ~₹1,100** (or ~₹950 if your existing USB-C cable does data)

## 2B. For the mechanism (buy when the resin parts arrive)

| # | Component | Spec | Qty | Est. ₹ |
|---|---|---|---|---|
| 6 | **Micro compression springs** | **2.0mm OD**, ~0.3mm stainless wire, ~4mm free length. Buy an assortment kit. 🔴 Pen springs (4mm) **cannot** work — braille rows are 2.6mm apart. | 6 + spares | ~500 |
| 7 | **Homing magnet** | **3mm dia × 2mm thick** neodymium. Your 8×1mm ones will **not** fit the cam pocket. | 1 (buy 10) | ~120 |
| 8 | **M2.5 × 25mm bolts** | Top plate → standoffs → box bosses | 4 | ~60 |
| 9 | **M4 × 10mm bolts + nuts** | Motor mounting ears | 2 | ~30 |
| 10 | **M2 × 8mm self-tap** | Pod lid. **NOT M2×6** — through a 4mm lid that leaves only 2mm of thread. | 2 | ~40 |
| 11 | **Superglue or 5-min epoxy** | Glues the resin dot insert into the PETG plate. Epoxy preferred — you get time to seat it square. | 1 | ~80 |
| 12 | **Digital calipers** | 150mm digital | 🔴 Both open project blockers are *measurements* (motor ×8, jack body). | 1 | ~600 |

**Mechanism subtotal: ~₹1,430**

## 2C. Optional / nice to have

| Component | Why | Est. ₹ |
|---|---|---|
| Flux paste | Makes soldering to ULN2003 pins much easier for a beginner | ~100 |
| Heat-shrink tubing | Insulating soldered joints | ~80 |
| Tweezers | Handling 2mm springs and 1mm linkages — genuinely hard without | ~80 |
| Desoldering pump/wick | Fixing bridges; also for lifting the TO-92 off the hall module | ~120 |
| Small drill bits 1.5/1.7/2.5mm | FDM holes print 0.2–0.3mm undersize | ~150 |
| Electrical tape | — | ~30 |

---

## 💰 Totals

| | ₹ |
|---|---|
| Already spent | 935 |
| Demo essentials (2A) | ~1,100 |
| Mechanism (2B) | ~1,430 |
| Optional (2C) | ~560 |
| **Everything** | **~4,025 spent, of ₹15,000** |

**If you buy only 2A (~₹1,100) you can run the full presentation demo.**

---

# PART 3 — NOT NEEDED (so you don't buy it by mistake)

| Item | Verdict |
|---|---|
| **Any motor driver IC** | ❌ You own it. The chip on the blue board **is** the ULN2003A. |
| **ATmega328P / custom muscle board** | ❌ Only for multi-cell I²C chains. The ESP32 drives one cell directly. Also TQFP-32 at 0.8mm pitch — beyond basic soldering; would need assembled (PCBA) ordering. |
| **Resistors** | ❌ None for a single cell. *(Only if you later build the multi-cell I²C bus: 2× 4.7kΩ pull-ups, master end only.)* |
| **Capacitors** | ❌ None. Both modules and the DevKit carry their own. |
| **Flyback diodes** | ❌ Built into the ULN2003A (that's what COM does). |
| **Level shifters** | ❌ Not needed — hall runs on 3V3, so GPIO34 never sees 5V. |
| **2mm bearing balls** | ❌ Obsolete since v7.1 — the dot is printed as a dome. |
| **Pogo pin connectors** | ⏸️ Deferred. Spec when needed: 4-pin, 2.54mm pitch, spring-loaded, ~0.5A. |
| **Crystal / oscillator** | ❌ ESP32 and the modules have their own. |

---

## 📌 If you ever DO build the custom muscle board

Not needed now, but for the record — it's `pcb/braillix_muscle_board.kicad_pcb`, 34×44mm:

| Part | Package | Note |
|---|---|---|
| ATmega328P-AU | **TQFP-32, 7×7mm square** | 0.8mm pitch — **not hand-solderable at your level** |
| ULN2003A | **SOIC-16 rectangle** | Same chip you already own, just SMD |
| 16MHz crystal | HC49 | |
| 2× 22pF, 2× 100nF | 0402 | Tiny — 1.0 × 0.5mm |
| 100µF/10V | SMD electrolytic | |
| 10kΩ ×2, 4.7kΩ ×2 | 0402 | |
| SS14 Schottky | SMA | ⬅️ *this* is the reverse-polarity protection the prototype lacks |

**Recommendation: order it fully assembled (PCBA) or don't build it.** 0402 passives and a
TQFP-32 are not a beginner job, and none of it is needed for a working demo.
