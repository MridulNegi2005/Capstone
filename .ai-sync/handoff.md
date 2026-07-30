# Active Handoff
> Last updated by: Claude Code (verifying Codex)
> Timestamp: 2026-07-30T01:30:00+05:30

## Current Task
**Nav-button CAD repaired (Codex) and VERIFIED (Claude). But the v7.3 audit found FIVE
blocking CAD defects — the mechanism is NOT ready for assembly. See `docs/CAD_FIT_CHECK.md`.**

Blocking, all verified from source:
1. **Hall pocket does not exist** — corner r=22.31 sits inside the r=23.00 cam pocket, same
   z-range. Also sized for a bare TO-92, not the owned blue module.
2. **Motor right ear hole (x=+9.5) is over the spring-cavity void** — nothing to screw into.
3. **Nav buttons** — FIXED by Codex, verified: stem now 4.5mm behind the flange, reaches
   0.5mm past the 4mm wall.
4. **ESP32 overruns the pod cavity by 1.75mm**; USB cutout at the wrong height.
5. **Cam homing-magnet pocket craters tracks 2, 3 AND 4** on the linkage running surface.

None of these block the PPT demo, which is breadboard-only (Tier 0).

The braille cell mechanism is now geometrically sound and split sensibly between resin and
PETG. The project is blocked on PHYSICAL work, not CAD.

**READ `cad/scad/mech_layout.scad` FIRST.** It is the single source of truth for track radii,
dot positions, the dot->track+angle assignment, the vertical stack, the spring/nub/dome/flange
sizes and the dot-insert dimensions. Do NOT re-declare any of those numbers in part files —
duplicated constants drifting out of sync is what caused most of the v6.x bugs.

## In Progress
No CAD edit is mid-flight. The nav caps are now printable: a Ø3.8 mm rear-facing stem projects 4.5 mm behind the flange, through the Ø4.2 mm pod hole. The combined resin plate and standalone nav-cap STL were regenerated and checked as closed manifold shells.

Two other items are DEFERRED, both waiting on Mridul, not on code:

1. **Motor redesign** — his real 28BYJ-48 has a different shaft/body than the CAD assumes.
   Needs 8 caliper measurements (body dia, can height, shaft->body-centre offset, shaft dia,
   flat-to-flat width, shaft height, mount-hole spacing, mount-hole dia). Feeds base_plate,
   mid_plate and the cam bore.
2. **Pod jack cradle** — `esp32_pod_lid.scad` has PLACEHOLDER dims. Needs the bare jack's
   body W x L x H plus the barrel bore.

## Next Steps
1. Bench-test one printed nav cap against the actual 6x6 tactile switch before ordering the final resin batch. The switch body is located forward by the pod's inner front wall; the back cage wall takes press load.
1. 🔴 **Mridul must change his actual WiFi password.** History was scrubbed with
   git-filter-repo and force-pushed, and GitHub is clean, but the password was public —
   GitHub caches by SHA and any fork retains it. Treat it as burned.
2. **Order the resin print.** Recommended: `print_resin_3_cam_linkages.stl` (4.03 cm3) at
   0.1mm layer height. Layer height only affects Z resolution; the tight XY fits are set by
   the printer's LCD pixel and do not improve with finer layers. 0.05mm is worth it only for
   the final version (smoother cam ramps + dot).
3. **Print `top_plate.stl` on PETG locally** — it is no longer a resin part.
4. **Buy 6x 2mm-OD micro compression springs** (0.3mm stainless, ~4mm free). See
   `docs/SOURCING.md`. Pen springs are PERMANENTLY ruled out (4mm OD needs 4.2mm pitch,
   braille rows are 2.6mm). Backup: soft open-cell sponge, NOT stiff EVA craft foam.
5. ⚠️ **THE REAL PRIORITY: nothing has ever been physically built.** No dot has gone up and
   come back down. Do the cheap PETG proving print (loose-gap cam + a couple of linkages) and
   make ONE dot move before spending on resin. Every CAD decision downstream rests on an
   unproven mechanism.

## Do NOT regress these
- **Feet are spread 60deg apart.** `braille_cam.scad` carves each track pre-rotated by its own
  foot angle via `track_phase(t)`. Without that one line every foot reads a different letter.
- **All six arms share `arm_y = 3.5`.** The old per-arm height stagger made the mechanism
  unbuildable (needed 6 levels, only 3 fit).
- **`link_total_h` = 12.2, measured to the RECESSED reading surface (57.2), not `plate_top_z`
  (58.0).** The plate has a 0.8mm finger-pad recess. Measuring to the rim put every dot 0.8mm
  proud even when down — all six permanently readable, which is not braille.
- **Spring is coaxial with the dot**, 2mm OD, in a counterbore in the dot insert, pushing on a
  2.2mm flange on the linkage riser. NOT on a mid-arm pad (tried in v7.0, rejected).
- **Braille dot is a printed 1.5mm dome.** No bearing balls, no glue, no machined cup.
- **Software dot->bit is a LOOKUP:** `DOT_TO_BIT = {1:3, 2:2, 3:1, 4:4, 5:5, 6:0}`. Not a
  formula. Authority is `dot_track` in mech_layout.scad with `bit = 5 - track`.
- **Credentials live in `firmware/breadboard_test/secrets.h` (gitignored).** Never inline them.

## Key Files Modified (this session)
| File | What |
|---|---|
| `cad/scad/mech_layout.scad` | spring/dome/flange sizes, dot-insert dims, `link_total_h` fix |
| `cad/scad/dot_insert.scad` | **NEW** — 15x15x3.2mm resin tile, 0.45 cm3, top-hat + glue shelf |
| `cad/scad/top_plate.scad` | dot holes + spring bores removed; now plain PETG with insert pocket |
| `cad/scad/linkage.scad` | rev 4.1 — spring flange on riser; count-dots moved underside + shrunk |
| `cad/scad/print_resin_{1_all,2_no_buttons,3_cam_linkages}.scad` | rebuilt, 12 linkages, 3x4 grid |
| `firmware/breadboard_test/{breadboard_test.ino,secrets.example.h}` | credentials extracted |
| `.gitignore` | secrets.h, blend backups, __pycache__ fix |
| `docs/SOURCING.md`, `CHANGES.md` | 2mm springs, insert glue notes, v7.1/v7.2 entries |
| Deleted | `print_resin_cam_linkage.*`, `print_resin_nav_buttons.*` (superseded) |

## Print files (v7.2)
| file | contents | resin |
|---|---|---|
| print_resin_3_cam_linkages | cam + 12 linkages | 4.03 cm3 |
| print_resin_2_no_buttons | + dot insert | 4.48 cm3 |
| print_resin_1_all | + 3 nav buttons | 5.05 cm3 |
| top_plate.stl | **PETG, print locally** | 15.46 cm3 |

## Firmware state
`breadboard_test.ino`: AccelStepper + WiFi dashboard + OTA, STEPS_PER_REV=4096. Motor and
hall validated on breadboard. Credentials now via gitignored `secrets.h`. OTA was blocked by
Windows Firewall (allow Arduino IDE); USB COM14 works.
Production I2C firmware not started — see `docs/SOFTWARE_TEAM_README.md` (+ .pdf).
