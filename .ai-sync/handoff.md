# Active Handoff
> Last updated by: Claude Code
> Timestamp: 2026-07-26T20:30:00+05:30

## Current Task
**v7.0 "spread feet" — DONE, verified, committed. The mechanism is buildable now.**
Read `cad/scad/mech_layout.scad` FIRST — it is the single source of truth for track radii,
dot positions, the dot->track+angle assignment, the vertical stack and the spring seats.
Do NOT re-declare any of those numbers in individual part files.

### Why v7.0 exists (do not undo it)
v6.x could not be assembled: six feet on one radial line -> 14 overlapping arm pairs -> 6
stacked arm heights needed but only 3 fit; three arms sat inside the top plate; the linkage
was 1mm too short so the dot never cleared the surface; and return springs cannot fit at the
dot axis (0.4mm free at 2.6mm row pitch). Spreading the feet 60deg with a smart dot->foot
assignment makes all six arms non-overlapping at ONE height and frees ~9.6mm between spring
seats. Cam diameter, box size and print cost unchanged.

### v7.0 headline facts
- Feet are 60deg apart; `braille_cam.scad` carves each track pre-rotated by its own foot
  angle (`track_phase(t)`). Without that one line every foot reads a different letter.
- ALL SIX ARMS share `arm_y = 3.5`. `total_h` is 13.0 (was 12.0 — dot never emerged).
- Braille dot is a PRINTED DOME on the nub. No bearing balls, no glue, no machined cup.
- Return spring sits in a top-plate pocket over a PAD ON THE ARM, never at the dot.
- Software dot->bit is a lookup: `DOT_TO_BIT = {1:3, 2:2, 3:1, 4:4, 5:5, 6:0}`.

### Still open
1. **Not physically tested.** No springs in hand. Do the cheap PETG proving print
   (loose-gap cam + a couple of linkages) and make ONE dot go up and down before
   paying for resin.
2. Motor redesign + jack cradle still blocked on Mridul's caliper measurements.
3. print_batch/ + zip not yet rebuilt for v7.0.

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

## Next steps
1. **Get Mridul's measurements** (motor ×8 + bare jack) → finish motor redesign
   (base_plate/mid_plate/braille_cam) + size the jack cradle → rebuild print_batch + zip.
2. **Commit** — NOTHING committed since v6.0 (67258a8): all of v6.1 + v6.2 + docs are
   uncommitted (Mridul approves commits; no co-author line — standing instruction).
3. Mridul re-prints SMALL parts first (pod lid, end cap, mid_plate) to validate tactile
   ridges + magnet pocket + relief slot + over-cap fit, then pod shell + outer_box.
4. Buy springs + 2mm balls + 3×2mm homing magnets per docs/SOURCING.md; resin Batch4.
5. Software team: build production firmware from docs/SOFTWARE_TEAM_README.md (I²C master
   on pod, slave on cells). Firmware OTA still blocked by Windows firewall (allow Arduino
   IDE); USB COM14 works.

## New this session (v6.2 + docs) — see CHANGES.md v6.2 + context.md 2026-06-13
- top_plate + pod_lid → over-caps; box walls 58→54; corner bosses gusseted (+ slicer
  Wall Loops=5); jack cradle (placeholder); switch cages; floating lid bosses fixed.
- docs/SOFTWARE_TEAM_README.md (+ .pdf) — handoff for the software team.

## Firmware state (unchanged since 2026-06-04)
breadboard_test.ino: AccelStepper + WiFi dashboard + OTA, STEPS_PER_REV=4096.
Motor + hall validated on breadboard.
