# Monday print day — the whole plan

**Written 2026-08-01. For Mridul, printing PETG on his own Anycubic Kobra Neo.**

> **The short version: you do not open the slicer at all.**
> The G-code is already made. Copy files to the card, press print.
> The only decision you make in the lab is *which folder*, and only if the test piece strings.

---

# PART 1 — Before you leave the house

## Buy these (₹150 or so, any hardware/hobby shop or online)

| Item | Qty | For |
|---|---|---|
| **M2.5 brass heat-set inserts** | 4 + spares | The four corner posts in the cell box |
| **M2 brass heat-set inserts** | 2 + spares | The two posts in the ESP32 pod |

Ask for **"brass heat set threaded inserts for 3D printing"**. They look like tiny knurled brass
barrels. Buy 10 of each — they cost almost nothing and you *will* lose one.

> ⚠️ **Check the size when they arrive.** The CAD assumes the M2.5 needs a **Ø3.5mm** hole and the
> M2 needs **Ø3.2mm**. Brands vary. If yours are different, tell me the number and I change one
> line and re-slice — it takes two minutes. Do NOT print with the wrong hole size; the brass either
> falls straight through or splits the post.

## Dry the filament

**65 °C for 6 hours**, in a food dehydrator or an oven on its lowest setting. Do this the night
before.

PETG soaks up water from the air, and wet PETG strings no matter how good the settings are. Your
June print's cobweb problem was mostly this. **No slicer setting beats dry filament.**

## Copy these to the SD card

```
printing/gcode_kobra_neo_checked/            <- USE THIS (230 °C)
    mid_plate.gcode
    top_plate.gcode
    outer_box.gcode
    esp32_pod_shell.gcode
    esp32_pod_lid.gcode

printing/gcode_kobra_neo_checked/alt_240C/   <- BACKUP (240 °C)
    (the same files, hotter)
```

Copy **both folders**. That is the "one setting difference" — you switch folders, never the slicer.

> ### 🔴 The old `printing/gcode/` folder is UNSAFE. Delete it.
> Codex audited it on 2026-08-02 and found **23,372 G2/G3 arc commands** in `outer_box` alone.
> The stock Kobra Neo firmware is built with **ARC_SUPPORT disabled**, so it cannot run them
> reliably — and OrcaSlicer previews them perfectly, so nothing looks wrong until it prints.
> Those files were also sliced *before* the brass-insert and stack fixes.
> The folder is now gitignored. Delete your local copy so it cannot be picked up by mistake.

---

# PART 2 — At the printer

## Print in THIS order

| # | Part | Time | Why this order |
|---|---|---|---|
| 1 | **mid_plate** | **38 min** | 🔴 **THIS IS YOUR TEST PIECE.** Smallest part, ~₹15 of filament. Judge everything from it. |
| 2 | top_plate | 1h 01m | Small, and it is the braille reading surface |
| 3 | outer_box | 4h 29m | The big one. Only start it once the test looks right |
| 4 | esp32_pod_shell | 4h 05m | Pod — not needed for the demo |
| 5 | esp32_pod_lid | 1h 09m | Pod — not needed for the demo |

**Total ≈ 11 h 20 m.** If the lab closes before that, parts 1–3 are the ones that matter.
**4 and 5 are the ESP32 housing and the demo does not use them.**

## After part 1, stop and look at it

| What you see | What it means | What to do |
|---|---|---|
| Clean, no cobwebs | 230 °C is right | Carry on with the rest of the folder |
| **Fine hairs / cobwebs** | **Damp filament**, almost certainly | ⚠️ Do **not** drop the temperature — 230 is already the low end of the Numakers range (240 ±10). Stringing is a moisture problem. Dry it. |
| Layers splitting, corners lifting | Too **cold** | Switch to the **alt_240C** folder, and raise the **bed** to 85 °C on the printer menu |
| Weak, easily snapped part | Too cold / poor layer bonding | **alt_240C** |
| Rough, gritty top surface | Under-extruding | Tell me — a flow setting, not temperature |

Nothing else needs judging. Those cover it.

> **Why the backup is hotter, not cooler.** Numakers specifies **240 ± 10 °C**. The default set runs
> 230, already at the bottom of their range, so there is nothing useful below it — going cooler just
> buys weak layers. The only temperature move that helps is **upward**, and stringing is fixed by
> drying, not by chasing the dial.

---

# PART 3 — 🔴 DO NOT PRINT `base_plate`

It is the cheapest part (44 min) **and the only one whose size depends on the cam disc.**

The resin cam arrives this week, and one hand-turn test decides whether the disc has to grow from
44mm to ~54mm. **If it grows, the base plate is the part that has to be reprinted** — its pocket
holds the disc.

Every other part is independent of the disc, which is why they are safe to print now.

Holding back 44 minutes to avoid a possible reprint of 44 minutes is a free bet. Print it after the
disc test.

---

# PART 4 — Fitting the brass inserts (after printing)

You need: soldering iron, the inserts, a steady hand. **10 minutes for all six.**

```
        iron tip
           |
           v
        ___|___
       |  ___  |     1. sit the insert on the hole, knurled end down
       | |   | |     2. press the hot iron onto its top
       |_|___|_|     3. it sinks under its OWN weight - do not push
      /         \    4. stop FLUSH with the surface
     /  printed   \  5. let it cool ~30 s before touching
    /_____post_____\
```

- Iron at **~220 °C**, roughly PETG printing temperature. Hotter melts too much plastic.
- **Let gravity do it.** Pressing hard squeezes molten plastic up around the brass and the thread
  ends up crooked.
- Going in **tilted** is the usual failure. Look from two sides before it cools.
- If one sinks too deep or sits crooked, heat it, pull it out with the screw, let the post cool,
  and retry. The plastic re-melts fine.

Practise on a scrap first if you have one.

---

# PART 5 — What changed in the CAD since your last print

| Change | Why |
|---|---|
| **Electronics pocket 16 → 14mm** | Fixes a **2mm error in the whole tower**. The mid-plate rests *on top of* its ledge, not level with it, and the old arithmetic never counted the ledge. With the motor now measured at 19.0mm, taking 2mm out here puts everything back on datum — and leaves the already-ordered resin linkages valid. |
| **Corner posts: brass insert bore added** | They used to cut their own thread in PETG. That strips after a few assemblies, and this box gets opened a lot. |
| **Pod posts grew Ø5.0 → Ø6.5** | An M2 insert needs a Ø3.2 hole. Inside a Ø5.0 post that leaves 0.9mm of wall — the hot brass would split it. Ø6.5 gives 1.65mm. |
| *(earlier)* sacrificial bridges removed, wire guides deleted, muscle-board bosses off | Documented in `CAD_CHANGELOG_v7.5.md` |

---

# PART 6 — Still unresolved, and it affects the pod lid

**The power socket.** Your jack is an inline pigtail with no thread and no nut, so it cannot clamp
into the lid's round hole. The lid still carries a **support cradle built from invented
dimensions** — it may well not fit your part.

**Two ways to play it:**

- **Print the lid anyway.** It is 1h 09m and the pod is not needed for the demo. If the cradle is
  wrong, reprint later.
- **Send me two caliper readings** — the barrel body's **outer diameter** and its **length** — and
  I will replace the invented cradle with a clamp built to your actual part before Monday.

Sixty seconds of measuring removes the guesswork entirely.

---

## One-line summary

**Dry the filament, buy the inserts, print `mid_plate` first, look at it, then run the rest —
and leave `base_plate` until the resin disc has been tested.**
