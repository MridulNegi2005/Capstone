# Active Handoff
> Last updated by: Claude Code
> Timestamp: 2026-07-26T23:59:00+05:30

## Current Task
**v7.1 — return spring is COAXIAL WITH THE DOT. Done, verified.**
Read `cad/scad/mech_layout.scad` FIRST — single source of truth for track radii, dot
positions, dot->track+angle assignment, the vertical stack, AND the spring/nub/dome/flange
sizes. Do NOT re-declare any of those in part files.

### The spring story (settled — do not relitigate)
- pre-v7: 4.5mm pockets on the dot axis. Never worked; at 2.6mm row pitch the three in a
  column merged into one slot. Never six pockets, only two blobs.
- v7.0: moved the spring to a pad mid-arm. Geometrically fine, physically wrong — Mridul
  rejected it; the return force belongs on the dot axis.
- **v7.1 (current): back on the dot axis and made to fit.** Spring is a **2mm OD micro
  spring** (0.3mm stainless, ~4mm free). Nub slimmed 2.2 -> 1.0mm, dome 2.2 -> **1.5mm =
  real braille standard**. Spring sits in a 2.2mm counterbore in the plate, wraps the dot,
  pushes down on a **2.2mm flange** on the linkage's upper riser.
- **BALLPOINT-PEN SPRINGS ARE PERMANENTLY RULED OUT** — ~4mm OD needs 4.2mm pitch, rows are
  2.6mm. No nub size fixes this. Do not re-suggest them.
- Assembly: thread the spring over the 1.5mm dome by twisting past the 1.4mm bore.
- Backup if springs can't be sourced: soft OPEN-CELL SPONGE disc (not EVA craft foam, ~20x
  too stiff). Printed parts are identical either way — no reprint needed to switch.

### v7.0 facts that still hold
- Six feet spread 60deg apart; `braille_cam.scad` carves each track pre-rotated by its own
  foot angle via `track_phase(t)`. Without that line every foot reads a different letter.
- ALL SIX ARMS share `arm_y = 3.5`. `total_h` = 13.0.
- Software dot->bit lookup: `DOT_TO_BIT = {1:3, 2:2, 3:1, 4:4, 5:5, 6:0}`.
- Bearing balls NO LONGER NEEDED — the dot is printed.

### Print plates for quoting (v7.1)
`print_resin_1_all` (cam+linkages+plate+buttons), `print_resin_2_no_buttons`,
`print_resin_3_cam_linkages`. The TOP PLATE dominates the cost in 1 and 2.

### Still open
1. **Nothing physically built yet.** Cheap PETG proving print, make ONE dot move, before
   any resin spend.
2. Motor redesign + pod jack cradle still blocked on caliper measurements.
3. print_batch/ + zip not rebuilt for v7.x.

## v6.1 headline facts (do not regress)
- Real magnets = **8×1mm** (not 3×2). 2 per dock face at y=±14, teardrop pockets.
- Raised features <2.5mm don't print on this machine → NO fine braille on PETG parts.
  PETG tactile = bold ridges/grooves; real braille on resin only.
- All sacrificial bridges 0.6mm; pilots M2→2.0 / M2.5→2.3; snap lips/nibs ≥0.8mm.
- **Linkages are RESIN-PRINTED now** (linkage.scad rev 3.1, Batch4_Resin, ×8).
- ULN2003 module fits the cell pocket ONLY with wires soldered flat (~12mm); mid-plate
  has a relief slot at (+X,−Y). Muscle-board PCB fab deferred.
- v5 box "orientation ridge" was buried inside the wall (never printed) — rebuilt.

## Files changed (all render `Simple: yes`)
outer_box, esp32_pod_shell, esp32_pod_lid, esp32_pod_params, pogo_end_cap (also had a
broken floating-interior bug fixed earlier today), base_plate, mid_plate, linkage (header
+ stale table), docs/WIRING_AND_ASSEMBLY.md, docs/SOURCING.md (new),
print_batch/* + zip rebuilt (includes new Batch4_Resin).

## Locked decisions (do not relitigate)
- Braille pitch stays jumbo 4.8mm. Resin = cam/top_plate/nav_cap (+now linkage); PETG rest.
- Magnet polarity scheme CORRECT (see audit §1 false alarms). Anti-reversal keying
  REVERTED; solve at connector level when real pogo part chosen.
- Patent doc deferred to end.

## History (superseded, kept for context)
- v6.1: 8x1mm magnets w/ teardrop pockets, bold PETG tactile, 0.6mm bridges, linkages->resin.
- v6.2: top_plate + pod_lid became over-caps; box walls 58->54; corner bosses gusseted
  (slicer note: Wall Loops = 5); jack cradle (PLACEHOLDER dims); pod switch cages; floating
  lid bosses fixed. docs/SOFTWARE_TEAM_README.md (+ .pdf) written for the software team.
- v6.3: cam bit->track order reversed (innermost track carries the slowest bit); linkage foot
  narrowed 2.0->1.4mm to stop it riding neighbouring tracks.
- Everything through v7.0 is COMMITTED (0788d57). v7.1 is the current working change.

## Firmware state (unchanged since 2026-06-04)
breadboard_test.ino: AccelStepper + WiFi dashboard + OTA, STEPS_PER_REV=4096.
Motor + hall validated on breadboard.
