# What I need you to measure

**Updated 2026-07-31. For Mridul.**

This began as a blank measurement list. It now combines your readings with datasheet values and published component envelopes. Values marked **VERIFY** are the only ones that still need the owned part.

An online/specification pass has now prefilled most of the original list. The evidence and source
links are in [`MEASUREMENT_RESEARCH.md`](MEASUREMENT_RESEARCH.md). Do not re-measure catalogue
dimensions unless the item is marked **VERIFY** below.

**Only four checks remain important now:** M5, M11b/marking, M21, and identifying the exact power
adapter body. M25 is checked later after the driver wires are installed.

**Motor identification:** `28BYJ-48`, 5 V. The red `2601213328` marking is a production/traceability code, not a different motor model.

Each one is written twice:

> 🟢 **In plain words** — what to actually do, no jargon
> 🔧 **Technical name** — the proper term, so you recognise it in datasheets, shops and my messages

The prefilled answer sheet at the bottom shows what is known, where it came from, and what remains.

---

# PART 0 — Words you'll keep seeing

Learn these six and everything below reads easily.

| Word | What it actually means |
|---|---|
| **Diameter** | The width straight across a circle, through the middle. Not around it. |
| **Bore** | A hole. "Bore diameter" = how wide the hole is. |
| **Pitch** | The gap from the centre of one thing to the centre of the next — holes, pins, teeth. Centre-to-centre, **never** edge-to-edge. |
| **Boss** | A raised bump or collar sticking out of a surface. |
| **Ear / lug / tab** | A flat sticking-out tab with a screw hole in it. |
| **Flat-to-flat** | The width across the two flat sides of a rod that isn't fully round. |

**Rule of thumb:** anything called "diameter" or "width" is measured with the **big jaws**.
Anything called "bore" or "hole" is measured with the **small pointy jaws** on top.

---

# PART 0.5 — Using the calipers (30 seconds)

```
        ┌── BIG jaws: measure the OUTSIDE of things
        ▼
   ═══╗ ╔═══════════════════════════════
      ║ ║   [ 12.47 ]  ← screen
   ═══╝ ╚═══════════════════════════════
        ▲
        └── small pointy jaws on TOP: measure the INSIDE of holes
```

- **mm/inch button** — make sure it says **mm**. If a big object reads 0.5 or 1.3, you're in inches.
- **ZERO button** — close the jaws fully, press ZERO, *every session*. Otherwise every reading is
  off by the same amount.
- **Close the jaws gently.** Plastic squashes and you'll read too small. Stop when it stops sliding.
- **Write 2 decimal places.** "12" is useless. "12.47" is what I need.

---

# PART 1 — THE MOTOR ⭐ MOST IMPORTANT

The silver can with the blue plastic base and 5 coloured wires.

**Why this one matters most:** the motor's height sets how high the base plate sits → which sets
how high the cam sits → which sets how long the linkages are. Get the height wrong by 2mm and
**all six braille dots stick up permanently** — every dot reads as "on" and the display is useless.

The CAD says 19mm tall. Nobody has ever checked.

```
                    shaft (the thin metal rod that spins)
                         │
                    ┌────┴────┐
              ┌─────┤  boss   ├─────┐   ← boss = raised collar round the shaft
   ear ───►  ╱      └─────────┘      ╲
            ○                         ○  ◄─── ear = flat tab with a hole
            ╲                         ╱
             └───────────────────────┘  ◄─── THIS flat face is the "mounting face"
             ╔═══════════════════════╗   ▲
             ║                       ║   │ can height
             ║      silver can       ║   │
             ║                       ║   ▼
             ╚═══════════════════════╝
```

### M1
> 🟢 **How wide is the round silver part?** Measure straight across it at its fattest point.
> 🔧 **Can outer diameter** *(guessed: 28mm)*

### M2 ⭐⭐ THE CRITICAL ONE
> 🟢 **How tall is the motor, from the table up to the flat face where the two tabs are?**
> Stand it silver-can-down on a table. Measure up to that flat face — **not** to the top of the
> spinning rod. Just the body.
> 🔧 **Can height, base to mounting face** *(guessed: 19mm)*

### M3
> 🟢 **The spinning rod is NOT in the middle of the can. How far off-centre is it?**
> Look down from above. Measure from the middle of the rod to the middle of the round can.
> 🔧 **Shaft-to-body-centre offset** *(guessed: 8mm)*
>
> *Too fiddly? Instead measure rod-centre to the left edge of the can, and rod-centre to the
> right edge. Give me both and I'll work it out.*

### M4
> 🟢 **How thick is the spinning rod at its widest?** It's not perfectly round — it has two flat
> sides shaved off. Measure the **round** way, the fat direction.
> 🔧 **Shaft diameter** *(guessed: 5.0mm)*

### M5
> 🟢 **Now measure the rod the narrow way — across the two flat sides.** Smaller number.
> 🔧 **Shaft flat-to-flat / across-flats** *(guessed: 3.0mm)*
>
> *That shape is called a **double-D**. It's what stops the cam spinning loose on the rod. Both
> M4 and M5 must be right or the cam either won't go on, or will wobble.*

### M6
> 🟢 **How far does the rod stick up above that flat face?** From the flat face (same one as M2)
> to the very tip.
> 🔧 **Shaft length above the mounting face** *(guessed: 10mm)*

### M7
> 🟢 **Is there a small raised ring where the rod comes out of the body? How wide and how tall?**
> **If there's no raised ring, just write "none".**
> 🔧 **Shaft boss diameter and height** *(guessed: 9mm wide; height never guessed at all)*

### M8
> 🟢 **How far apart are the two screw holes in the tabs?** Measure from the middle of one hole
> to the middle of the other.
> 🔧 **Mounting-hole pitch (centre-to-centre)** *(guessed: 35mm)*
>
> *Middle-to-middle is awkward. Easier: measure from the **far outer edge** of one hole to the
> **far outer edge** of the other, tell me that, and I'll subtract the hole width.*

### M9
> 🟢 **How wide is one of those screw holes?** Use the small pointy jaws inside it.
> 🔧 **Mounting-hole bore diameter** *(guessed: 4.2mm)*

### M10
> 🟢 **How wide is the flat tab, and how thick is the metal?**
> 🔧 **Mounting ear width and thickness** *(never measured)*

---

# PART 2 — THE POSITION SENSOR

The small **blue board** with a tiny black 3-legged part on one edge, a blue adjustment screw,
and pins marked AO DO GND VCC.

### ⚠️ Bad news first

**The blue board will not fit inside the machine.** It's roughly 15×11mm plus tall pins. The space
inside the base plate is 5mm thick. There's no version where the whole board fits.

**What has to happen:** the little black 3-legged part on the edge *is* the actual sensor —
everything else on that board is supporting circuitry. You'll need to **unsolder that black part**
and mount just it, running three wires back.

Three solder joints. Fiddly, but genuinely the only option: it has to sit within a couple of
millimetres of a magnet on the spinning disc, and the motor body fills everything else nearby.

**You do NOT need to do this for the demo.** On a breadboard the blue board works fine as-is.

### M11 — the black 3-legged part

You can measure it while it's still soldered on.

```
        ┌─────────┐   ▲
        │  flat   │   │ HEIGHT (M11c)
        │  face   │   │
        └─┬──┬──┬─┘   ▼
          │  │  │     ← 3 legs
        ◄─────────►
          WIDTH (M11a)

     from the side:  ◄─►  THICKNESS (M11b)
```

> 🟢 **M11a — How wide is the black part across its flat face?**
> 🔧 Sensor body width *(guessed: 4.1mm)*

> 🟢 **M11b — How thick is it front-to-back?** One side is flat, the other bulges. ⚠️ **This is
> the one that can break the design** — I've allowed 1.6mm. If yours is fatter, the CAD will
> refuse to build and say so. Send me the number and I'll rework it.
> 🔧 Sensor body thickness *(guessed: 1.6mm)*

> 🟢 **M11c — How tall is just the black block?** Not counting the legs.
> 🔧 Sensor body height *(guessed: 3.1mm)*

> 🟢 **M11d — How far apart are the legs?** Middle of one leg to middle of the next.
> 🔧 Lead pitch *(guessed: 1.27mm)*

---

# PART 3 — THE POWER SOCKET

The small **yellow/black block** with a round socket at one end and two screw terminals at the
other. Where the 5V adapter plugs in.

**Every single dimension for this is a placeholder I invented.** The printed holder meant to
support it is entirely fictional until you measure this.

```
        screw terminals              round socket
              ║                          ║
        ┌─────╨──────────────────────────╨─────┐  ▲
        │              yellow body             │  │ HEIGHT (M13)
        └──────────────────────────────────────┘  ▼
        ◄────────────  LENGTH (M12)  ───────────►

        from the front:  ◄─ WIDTH (M14) ─►
```

> 🟢 **M12 — How long is the block end to end?** Terminals to socket face.
> 🔧 Jack body length *(placeholder: 12mm)*

> 🟢 **M13 — How tall is it?**
> 🔧 Jack body height *(placeholder: 11mm)*

> 🟢 **M14 — How wide is it?**
> 🔧 Jack body width *(placeholder: 9.5mm)*

> 🟢 **M15 — How wide is the round metal tube the plug pushes into?** Measure across the tube at
> the front face.
> 🔧 Barrel outer diameter *(placeholder: 11.5mm)*

> 🟢 **M16 — Does it have a screw thread and a ring nut** for clamping it to a panel? Yours
> probably doesn't. **Just answer YES or NO.** If yes, how wide is the threaded part?
> 🔧 Panel-mount thread present? Thread diameter?

### 🔴 M17 — POLARITY. Do this one FIRST. It is not a measurement.

**This is the single most likely way to destroy your ₹350 ESP32.** There is no protection against
getting it backwards anywhere in this circuit — plug it in wrong and the board dies instantly and
silently.

> 🟢 **Which of the two screw terminals is the positive one?**
> 🔧 Supply polarity

Multimeter on **DC volts**, adapter plugged into the wall, **nothing else connected**:

1. Black probe on one screw terminal, red probe on the other.
2. Screen shows **+5V** → the terminal under the **red** probe is **positive**.
3. Screen shows **−5V** (with a minus) → it's the other way round.
4. Mark the positive one with nail polish or a marker.

Use the terminal embossed `+`; standard adapters connect it to the centre pin. Before first power,
confirm that mapping with continuity mode because the owned adapter is an unidentified clone.

---

# PART 4 — THE ESP32 BOARD

The black board with the silver square shield and USB-C.

### M18 — RESOLVED: 15 pins per side / 30 total

> 🟢 **Count the metal pins along ONE long edge.** Just count them.
> 🔧 Pin count per row

- **15 per side** (30 total) → you have the "30-pin" board
- **19 per side** (38 total) → the "38-pin" board

**Why this matters:** the pod has two printed slots the board's pins drop into. M18 confirms a
30-pin board, but that does not determine the spacing: 30-pin clones are sold with 22.86, 25.4,
and 27.94mm between rows. **M21 still has to come from this exact board.**

> 🟢 **M19 — How long is the board?** The long way.
> 🔧 Board length *(guessed: 51.5mm)*

> 🟢 **M20 — How wide is the board?** The short way.
> 🔧 Board width *(guessed: 28.0mm)*

> 🟢 **M21 — How far apart are the two rows of pins?** Middle of the left row to middle of the
> right row.
> 🔧 Header row pitch *(guessed: 25.4mm)*
>
> *Easier: measure from the **outer edge** of the left pins to the **outer edge** of the right
> pins and tell me that instead.*

> 🟢 **M22 — The silver USB socket on the board:** how wide (a), how tall (b), and how far does it
> stand up off the board surface (c)?
> 🔧 USB connector width / height / height above PCB

> 🟢 **M23 — Your USB cable's plug:** not the metal bit — the **plastic body behind it**, the part
> your fingers hold. How wide (a) and how tall (b)?
> 🔧 Connector overmould width and height
>
> *Why: the socket sits ~2mm inside the pod, so the plug body has to pass through the hole in the
> wall too. The old hole was 10×7mm and would probably have blocked your cable. The service
> opening is now fixed at 14×9mm. M23 is optional unless your cable body is larger than that.*

---

# PART 5 — THE MOTOR DRIVER (blue board, 4 red LEDs)

> 🟢 **M24 — How long and how wide is the blue board?**
> 🔧 PCB length × width

> 🟢 **M25 — How tall is it once the wires are soldered flat against it?**
> 🔧 Assembled stack height
>
> *Measure **after** soldering, or press the wires flat and estimate. Do **not** measure it with
> the plug-in jumper wires standing upright — that makes it ~20mm and the space is 16mm. That's
> exactly why the wires must be soldered flat.*

> 🟢 **M26 — Which part on the board stands up tallest, and how tall is it** from the board surface?
> 🔧 Tallest component height

---

# PART 6 — Quick confirmations (10 seconds each)

> 🟢 **M27 — One of your silver disc magnets: how wide and how thick?**
> 🔧 Magnet diameter × thickness *(expect 8mm × 1mm)*

> 🟢 **M28 — One tiny black push-button: how wide is the square body, and how tall is it including
> the round nub on top?**
> 🔧 Tactile switch body and total height *(expect 6 × 6 × 5mm)*

---

## ⚠️ Shopping correction that came out of this work

Your BOM used to say buy a **3mm × 2mm** homing magnet.

### Buy 3mm × 1mm instead.

The disc it glues into is only 2mm thick. A 2mm-deep pocket cut clean through it, punching a
3.2mm hole across three of the six cam tracks — and a linkage foot crossing that hole would drop
in and jam the whole mechanism. A 1mm magnet leaves 0.8mm of material and works just as well,
because it still sits flush against the underside.

Already ordered 3×2mm? They'll be useful elsewhere. Just buy 3×1mm too. ~₹120 for ten.

---

# 📋 COPY-PASTE ANSWER SHEET

Copy all of this, fill in the numbers, send it back. `?` is fine and useful.

```
=== MOTOR (owned 28BYJ-48, 5V; red number is a lot/traceability code) ===
M1  can diameter                              = 28.1 mm   [MEASURED]
M2  mounting-face height                     = 19.0 mm   [MEASURED]
M3  shaft offset from can centre             = 7.5 mm    [MEASURED]
M4  shaft diameter                           = 5.0 mm    [MEASURED + SPEC]
M5  shaft across flats                       = 3.0 mm    [SPEC — VERIFY PRESS FIT]
M6  mounting face to shaft tip               = 9.5 mm    [MEASURED]
M7a raised collar diameter                   = ~9.0 mm   [SPEC]
M7b raised collar height                     = 2.0 mm    [DERIVED: 9.5 - 7.5]
M8  mounting-hole pitch                      = 34.7 mm   [MEASURED]
M9  mounting-hole bore                       = 4.0 mm    [MEASURED]
M10a mounting-ear width                      = ~7.0 mm   [SPEC]
M10b mounting-ear metal thickness            = ~0.8 mm   [SPEC]

=== POSITION SENSOR (KY-024 family, bare 49E/SS49E package) ===
M11a body width                              = 4.1 nominal / 4.2 max mm [SPEC]
M11b body thickness                          = 1.6 nominal / 1.68 max mm [VERIFY CLONE]
M11c body height                             = 3.1-3.2 mm [SPEC]
M11d straight-lead pitch                     = 1.27-1.30 mm [VERIFY LEAD FORM]

=== POWER SOCKET (likely inline 5.5x2.1 screw-terminal adapter) ===
M12 body length                              = likely 35-37.3 mm [VARIANT — IDENTIFY]
M13 body height                              = likely 12-13.5 mm [VARIANT — IDENTIFY]
M14 body width                               = likely 14-14.2 mm [VARIANT — IDENTIFY]
M15 mating barrel                            = 5.5 OD / 2.1 centre mm [SPEC]
M16 panel thread + ring nut                  = NO for the inline adapter [LIKELY]
M17 polarity                                 = terminal marked + -> centre pin [VERIFY CONTINUITY]

=== ESP32 BOARD (USB-C, CH340C-family, 15 pins per row) ===
M18 pin count                                = 15 per row / 30 total [MEASURED]
M19 board length                             = likely 51.5-52.0 mm [MATCHING LISTINGS]
M20 board width                              = likely 28.0-28.5 mm [MATCHING LISTINGS]
M21 header-row centre spacing                = ____ mm [REQUIRED: 22.86/25.4/27.94 all exist]
M22 USB-C interface / shell                  = ~8.3x2.5 / ~9x3.2 mm [SPEC/LIKELY]
M23 cable body                               = NOT NEEDED unless larger than 14x9 mm

=== MOTOR DRIVER (common blue four-LED ULN2003 board) ===
M24 PCB size                                 = likely 35x32 mm [COMMON VARIANT]
M25 installed height, cable bent flat        = likely ~12 mm [VERIFY AFTER WIRING]
M26 tallest item                             = JST-XH motor plug, ~10-12 mm installed [LIKELY]

=== QUICK CONFIRMATIONS ===
M27 docking magnets                          = 8x1 mm [OWNED / ALREADY IN CAD]
M28 tactile switches                         = 6x6x5 mm [PURCHASE SPEC / ALREADY IN CAD]
```

---

## What happens when you send these back

I re-derive the **whole vertical stack in one pass** — motor height → base plate → cam → linkage
length — rather than patching one number at a time. That's deliberate: these all depend on each
other, so fixing them individually just moves the error somewhere else.

**The remaining blockers after the online pass are:**

| Waiting on | Why online data is not enough |
|---|---|
| M5 | The cam is a press fit; the owned shaft across-flats controls whether it grips or cracks. |
| M11b / sensor marking | 49E-family thickness reaches 1.68mm while the current pocket is exactly 1.6mm. |
| Exact power-adapter identity | Similar inline adapters vary by several millimetres, and the current CAD incorrectly assumes a panel-mount jack. A purchase link or clear top/side photo is more useful than five separate readings. |
| M21 | 30-pin ESP32 boards are sold at 22.86, 25.4, and 27.94mm row spacing. Only the owned board decides the socket-channel position. |
| M25 later | Final height depends on how the motor cable and soldered wires are dressed during assembly. |

Everything else is now measured, derived, standardized, safely enveloped, or non-critical.
