# What I need you to measure — plain English

**Written 2026-07-30. For Mridul, with digital calipers arriving today.**

Everything here is a number the CAD is currently **guessing**. Each guess was typed from a
datasheet or a forum post, not taken off your actual parts. Where a guess is wrong, the printed
part will not fit the real one — and you will only find out after paying for the print.

There are **26 measurements**. Realistically this is about **45 minutes** of work.

> **Copy-paste answer sheet is at the very bottom.** Fill it in and send it back. You do not need
> to understand any of the CAD — just read numbers off the calipers.

---

## PART 0 — How to use calipers (30 seconds)

Your calipers have two jaws that slide.

```
        ┌── these BIG jaws measure the OUTSIDE of things
        │   (width of a board, diameter of a motor)
        ▼
   ═══╗ ╔═══════════════════════════════
      ║ ║   [ 12.47 ]  ← screen
   ═══╝ ╚═══════════════════════════════
        ▲
        └── the small pointy jaws on TOP measure the INSIDE of holes
```

Three buttons matter:
- **ON/OFF**
- **mm/inch** — make sure it says **mm**. If your numbers look like 0.5 or 1.3 for something
  obviously bigger, you're in inches.
- **ZERO** — close the jaws fully, press ZERO. Do this before *every* measurement session,
  otherwise every number is off by the same small amount.

**How to read it:** close the jaws gently on the object. Don't crush it — plastic squashes and
you'll read small. Just until it stops sliding.

**Write down 2 decimal places.** "12" is not useful. "12.47" is.

---

## PART 1 — THE MOTOR ⭐ MOST IMPORTANT

This is the silver can with the blue plastic base and 5 coloured wires.

**Why this matters more than everything else:** the motor's height decides how high the base
plate sits. The base plate decides how high the cam sits. The cam decides how long the linkages
are. So if the motor's height is wrong by 2mm, **all six braille dots stick up 2mm and the
display is unreadable** — every dot feels "on" all the time.

Right now the CAD says the motor is 19mm tall. Nobody has ever checked.

```
                    shaft (the thin metal rod that spins)
                         │
                    ┌────┴────┐
              ┌─────┤  boss   ├─────┐   ← "boss" = the small raised collar
   ear ───►  ╱      └─────────┘      ╲    around the base of the shaft
            ○                         ○  ◄─── ear (the flat tab with a hole)
            ╲                         ╱
             └───────────────────────┘
             ╔═══════════════════════╗   ▲
             ║                       ║   │ can height
             ║      silver can       ║   │
             ║                       ║   ▼
             ╚═══════════════════════╝
```

### M1 — Can diameter
Measure straight across the round silver can, at its widest.
*Guessed: 28mm*

### M2 — Can height ⭐⭐ THE CRITICAL ONE
Stand the motor on a table, can down. Measure from the table up to the **flat face where the
ears are** — the surface that will press against the printed plate. **Not** to the top of the
shaft. Just to that flat mounting face.
*Guessed: 19mm*

### M3 — Shaft offset (how far off-centre the shaft is)
The shaft is **not** in the middle of the can. Look down from above. Measure from the centre of
the shaft to the centre of the round can.
*Guessed: 8mm*

> Easier way if that's fiddly: measure from the shaft centre to the left edge of the can, then
> to the right edge. Give me both numbers and I'll work it out.

### M4 — Shaft diameter
The thin metal rod. Measure across it. Note that it's **not** perfectly round — it has two flat
sides. Measure across the **round** part (the widest way).
*Guessed: 5.0mm*

### M5 — Shaft flat-to-flat
Now measure across the **two flat sides** (the narrow way). This is the smaller number.
*Guessed: 3.0mm*

> This shape is called a "double-D". It stops the cam spinning loose on the shaft. Both M4 and
> M5 have to be right or the cam either won't go on, or will wobble.

### M6 — Shaft length
From the **flat mounting face** (the same face as M2) up to the **tip of the shaft**.
*Guessed: 10mm*

### M7 — Shaft boss diameter and height
There's usually a small raised collar where the shaft comes out of the motor body. Measure
across it (diameter) and how tall it stands.
*Guessed: 9mm across. Height never guessed at all.*
**If there is no raised collar, just write "none".**

### M8 — Distance between the two ear holes
The two flat tabs each have a hole. Measure **centre of one hole to centre of the other**.
*Guessed: 35mm*

> Tip: measuring hole-centre to hole-centre is awkward. Instead measure from the **far edge of
> one hole to the far edge of the other** and tell me that — I'll subtract the hole diameter.

### M9 — Ear hole diameter
Use the small pointy jaws on top of the calipers, inside one hole.
*Guessed: 4.2mm*

### M10 — Ear tab width and thickness
How wide the flat tab is, and how thick the metal is.
*Never measured.*

---

## PART 2 — THE HALL SENSOR (position detector)

This is the small **blue board** with a tiny black 3-legged component on one edge, a blue
adjustment screw, and pins labelled AO DO GND VCC.

### ⚠️ First, some bad news you need to know about

**The blue board will not fit inside the machine.** It's about 15×11mm plus tall pins. The space
available inside the base plate is 5mm thick. There is no version of this where the board fits.

**What has to happen:** the little black 3-legged part on the edge of the blue board *is* the
actual sensor. Everything else on that board is support circuitry. You need to **unsolder that
black part** and mount just it, running three wires back.

That's three solder joints to remove. It's fiddly but it is genuinely the only option — I checked
whether the sensor could go anywhere else, and it can't: it has to sit within a couple of
millimetres of a magnet on the spinning disc, and the motor body occupies everything else nearby.

**For the demo you do NOT need to do this.** On the breadboard the blue board works fine as-is.
This is only for when you assemble a real cell.

### M11 — The black sensor part
Once you can see it clearly (you can measure it while still soldered on):

```
        ┌─────────┐   ▲
        │  flat   │   │ HEIGHT (M11c)
        │  face   │   │
        └─┬──┬──┬─┘   ▼
          │  │  │     ← 3 legs
        ◄─────────►
          WIDTH (M11a)

     seen from the side:  ◄─►  THICKNESS (M11b)
```

- **M11a — width** across the flat face
- **M11b — thickness** (front to back — it's flat on one side, curved on the other)
- **M11c — height** of the black body only, not counting the legs
- **M11d — leg spacing**, centre of one leg to centre of the next

*Guessed: 4.1 wide, 1.6 thick, 3.1 tall, 1.27 leg spacing*

> **M11b (thickness) is the one that can break the design.** I've allowed 1.6mm. If your sensor
> is fatter than that, the CAD will refuse to build and tell you so — send me the number and
> I'll rework it.

---

## PART 3 — THE POWER SOCKET (barrel jack)

The small **yellow/black block** with a round socket at one end and two screw terminals at the
other. This is where the 5V adapter plugs in.

**Every single dimension for this part is a placeholder I invented.** The holder that's meant to
support it is entirely fictional until you measure this.

```
        screw terminals              round socket
              ║                          ║
        ┌─────╨──────────────────────────╨─────┐  ▲
        │                                      │  │ HEIGHT (M13)
        │            yellow body               │  │
        └──────────────────────────────────────┘  ▼
        ◄────────────  LENGTH (M12)  ───────────►

        seen from the front:  ◄─ WIDTH (M14) ─►
```

- **M12 — length** end to end, terminals to socket face
- **M13 — height** (how tall the block is)
- **M14 — width** (how wide the block is)
- **M15 — diameter of the round barrel** — just the round metal/plastic tube that a plug goes
  into, at the front face
- **M16 — is there a screw thread and a nut?** Many panel jacks have a threaded neck and a ring
  nut that clamps it to a panel. Yours probably doesn't. **Just answer YES or NO.** If yes,
  measure the thread diameter.

### 🔴 M17 — POLARITY (do this one FIRST, it's not a measurement)

**This is the single most likely way to destroy your ₹350 ESP32.** There is no protection against
getting it backwards in this circuit — plug it in wrong and the board dies instantly and silently.

With a multimeter set to **DC volts**, adapter plugged into the wall but **nothing else connected**:

1. Touch the **black** probe to one screw terminal, **red** to the other.
2. If the screen shows **+5V** (positive), the terminal touching the RED probe is **positive**.
3. If it shows **−5V** (negative, with a minus sign), it's the other way round.
4. Mark the positive terminal with a dot of nail polish or a marker.

**Answer: which terminal is positive — the one nearer the barrel, or the one further away?**

Do not skip this and do not guess from wire colours.

---

## PART 4 — THE ESP32 BOARD

The black board with the silver square shield and USB-C.

### M18 — ⭐⭐ COUNT THE PINS. This one is free and it's the most important.

**Count the metal pins along ONE long edge.** Just count them.

- **15 pins** on one side (30 total) → your board is the "30-pin" version
- **19 pins** on one side (38 total) → the "38-pin" version

**Why this matters:** the pod has two printed slots that the board's pins drop into. The two
versions have their pin rows **2.5mm further apart**. Every document in this project says you have
the 30-pin board, but the CAD was built for the 38-pin one. **One of them is wrong, and if it's
the CAD, your ESP32 will not go into the pod at all.**

Just count them. Takes ten seconds.

### M19 — Board length (the long way)
### M20 — Board width (the short way)

### M21 — Distance between the two pin rows
Measure from the **centre of the pin row on one side** to the **centre of the pin row on the
other side**.

> Easier: measure from the **outer edge of the left pins to the outer edge of the right pins**,
> and tell me that instead. I'll do the maths.

*Guessed: 25.4mm*

### M22 — The USB socket on the board
- **M22a — width** of the metal USB socket
- **M22b — height** of it
- **M22c — how far it sticks up** above the surface of the board

### M23 — Your USB cable's plug
Not the metal bit — the **plastic moulded body** behind it, the part your fingers hold.
- **M23a — width**
- **M23b — height**

> This is why: the socket sits ~6mm inside the pod, so the plug body has to pass through the
> hole in the wall too. The old hole was 10×7mm and would probably have blocked your cable.
> I've opened it to 13×9mm but that's still a guess.

---

## PART 5 — THE MOTOR DRIVER (blue ULN2003 board)

Small blue board, 4 red LEDs, white 5-pin socket.

### M24 — Board length and width
### M25 — Board height **with the wires soldered on flat**

Measure this **after** you solder, or estimate with the wires pressed flat against the board.
Do **not** measure it with the plug-in jumper wires standing upright — those make it ~20mm tall
and the space available is 16mm. That's why the wires have to be soldered flat.

### M26 — Tallest thing on the board
Which component stands highest, and how tall, measured from the board surface.

---

## PART 6 — Quick re-checks (10 seconds each)

- **M27 — docking magnets.** You have 10 silver discs. Measure diameter and thickness of one.
  *Should be 8mm × 1mm. Just confirming the new batch matches.*

- **M28 — tactile switches.** The tiny square black buttons. Measure the square body
  (width × width), and the total height including the round plunger on top.
  *Guessed: 6 × 6 × 5mm*

---

## ⚠️ One shopping correction that came out of this work

Your BOM says to buy a **3mm × 2mm** homing magnet.

**Buy 3mm × 1mm instead.**

The disc it glues into is only 2mm thick. A 2mm-deep pocket cut clean through it, leaving a
3.2mm hole punched through three of the six cam tracks — and a linkage foot crossing that hole
would drop in and jam the whole mechanism. A 1mm magnet leaves 0.8mm of material and works
exactly as well, because it still sits flush against the underside.

If you already ordered 3×2mm, they'll still work for other things — just buy 3×1mm as well.
They cost about ₹120 for ten.

---

# 📋 COPY-PASTE ANSWER SHEET

Copy everything below, fill in the numbers, send it back. Write `?` for anything you can't
measure or aren't sure about — a `?` is much more useful to me than a guess.

```
=== MOTOR (28BYJ-48) ===
M1  can diameter                      = ____ mm
M2  can height to mounting face       = ____ mm   *** most important ***
M3  shaft centre to can centre        = ____ mm
M4  shaft diameter (round way)        = ____ mm
M5  shaft flat-to-flat (narrow way)   = ____ mm
M6  shaft length above mounting face  = ____ mm
M7a shaft boss diameter               = ____ mm   (or "none")
M7b shaft boss height                 = ____ mm   (or "none")
M8  ear hole centre-to-centre         = ____ mm
M9  ear hole diameter                 = ____ mm
M10a ear tab width                    = ____ mm
M10b ear tab thickness                = ____ mm

=== HALL SENSOR (the black 3-legged part) ===
M11a width across flat face           = ____ mm
M11b thickness                        = ____ mm   *** can break the design ***
M11c body height (no legs)            = ____ mm
M11d leg spacing                      = ____ mm

=== BARREL JACK (yellow block) ===
M12 body length                       = ____ mm
M13 body height                       = ____ mm
M14 body width                        = ____ mm
M15 barrel outer diameter             = ____ mm
M16 threaded neck + nut?              = YES / NO   (thread dia if yes: ____ mm)
M17 POLARITY: positive terminal is    = NEAR the barrel / FAR from the barrel
                                        *** do this before powering anything ***

=== ESP32 DEVKIT ===
M18 pins on ONE long edge             = ____ pins   *** just count them ***
M19 board length                      = ____ mm
M20 board width                       = ____ mm
M21 pin row to pin row (centres)      = ____ mm
    (or outer-edge to outer-edge:       ____ mm)
M22a USB socket width                 = ____ mm
M22b USB socket height                = ____ mm
M22c USB socket height above board    = ____ mm
M23a USB cable plug body width        = ____ mm
M23b USB cable plug body height       = ____ mm

=== ULN2003 DRIVER (blue board) ===
M24a board length                     = ____ mm
M24b board width                      = ____ mm
M25  height with wires soldered FLAT  = ____ mm
M26a tallest component is             = ____________
M26b its height above the board       = ____ mm

=== QUICK CONFIRMATIONS ===
M27a docking magnet diameter          = ____ mm   (expect 8)
M27b docking magnet thickness         = ____ mm   (expect 1)
M28a tactile switch body (square)     = ____ mm   (expect 6)
M28b tactile switch total height      = ____ mm   (expect 5)
```

## What happens when you send these back

I re-derive the whole vertical stack in **one pass** — motor height → base plate height → cam
height → linkage length — instead of patching one number at a time. That's deliberate: these
dimensions all depend on each other, so fixing them individually just moves the error somewhere
else.

**The four things still broken can only be fixed with these numbers:**

| Waiting on | Fixes |
|---|---|
| M2, M6, M7 | The cam sits 2mm too high, which makes every dot permanently readable |
| M2 | A second, separate 2mm error: the mid-plate rests on top of its ledge, not level with it, so the motor face lands 2mm higher than the box expects |
| M11b | Whether the hall sensor pocket I just built is deep enough |
| M12–M16 | The barrel jack holder, which is currently 100% invented |
| M18, M21 | Whether your ESP32 can physically plug into the pod |

**Priority if you're short on time:** M18 (free, ten seconds), M17 (protects your ESP32),
then M2, M6, M7.
