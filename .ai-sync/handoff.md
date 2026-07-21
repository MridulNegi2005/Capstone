# Active Handoff
> Last updated by: Claude Code
> Timestamp: 2026-06-12T18:00:00+05:30

## Current Task
**v6.2 over-cap lids + boss reinforcement — DONE & supervisor-verified, NOT committed,
print_batch NOT rebuilt.** Built via builder/supervisor agent loop. See CHANGES.md v6.2.
Two things DEFERRED awaiting Mridul's caliper measurements:
  1. **Motor redesign** — the real motor differs (brass flatted/splined shaft). Need: body
     dia, can height, shaft→body-center offset, shaft dia, flat width, shaft height, mount
     hole spacing + dia. Feeds base_plate + mid_plate + braille_cam bore.
  2. **Jack cradle** in esp32_pod_lid.scad has PLACEHOLDER dims — need real bare-socket
     body W×L×H + barrel inner dia.
Also pending: rebuild print_batch + zip once the above land. Slicer note for workshop:
**Wall Loops/perimeters = 5** (makes small bosses solid).

**v6.1 (prior round) — DONE.** Read the v6.1 addendum (§6.5) in
`.ai-sync/artifacts/cad_audit_v6_2026-06-04.md` for the measured FDM limits + hardware
spec corrections.

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
