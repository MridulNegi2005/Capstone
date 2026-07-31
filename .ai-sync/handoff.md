# Active Handoff
> Last updated by: Codex
> Timestamp: 2026-07-31T13:50:00+05:30

## 🔴 CURRENT BLOCKER: FOUR OWNED-PART CHECKS

The online pass has filled or bounded every M1-M28 item that public specifications can support.
See `docs/MEASUREMENT_RESEARCH.md` for sources and evidence labels, and
`docs/MEASUREMENTS_NEEDED.pdf` for the prefilled handout.

Only these fit-critical owned-part checks remain:

| Check | Why it still matters |
|---|---|
| M5 motor shaft across-flats | The common value is 3.0 mm, but the cam is a press fit. |
| M11b plus Hall package marking | 49E-family thickness is 1.6 mm nominal / 1.68 mm max; the current pocket is exactly 1.6 mm. |
| M21 ESP32 header-row centre spacing | 30-pin boards exist at 22.86, 25.4, and 27.94 mm. |
| Exact final power-jack identity | The owned yellow/black adapter is inline; the lid CAD assumes a panel-mount jack. |

M25 (ULN2003 installed height with its cable dressed) is a later assembly check, not a blocker for
the present CAD research pass. Motor measurements M2=19.0, M6=9.5 and derived M7b=2.0 now allow
the vertical stack to be re-derived, but that chain must be repaired in one coordinated CAD pass.
Do not patch its individual heights independently.

Recommended connector decision: use a specified panel-mount 5.5 x 2.1 mm centre-positive jack
with a retaining nut in the final pod; keep the inline adapter for breadboard testing.

---

## 🔴🔴 NEW AND MORE SERIOUS: THE CAM RAMP MAY BE UNCLIMBABLE (R-07)

Source: `docs/BRAILLIX_MECHANICAL_FINDINGS_REPORT.docx` (Codex, web session, rev 4788e44).
Claude Code independently re-verified every number in that report from source on 2026-07-31.

**Codex's arithmetic is correct throughout** — hub interference, spring solid-height shortfall,
dot proud error, `max(dh/dtheta) = 64 mm/rad`, ramp slopes, 6mm engagement. All reproduce exactly.

**But F-01 through F-03 are NOT new.** They are the same vertical-stack defects already in the
v7.3 audit and already documented in-source at `outer_box.scad:base_plate_z`. Re-derived, not
discovered.

**R-07 IS new, and it is the real problem:**

```
track   radius   ramp run   pressure angle      foot roll radius = 0.5mm
  0      12.8     0.251mm       78.7 deg        RAMP RUN SHORTER THAN THE FOOT
  5      21.3     0.418mm       71.6 deg        RAMP RUN SHORTER THAN THE FOOT
```

- Standard limit for a translating cam follower is a **30 degree** pressure angle. Every track
  here is **71-79 degrees**. Side load is **5x** the lift force at the inner track.
- The ramp run (0.25-0.42mm) is **shorter than the foot's own 0.5mm roll radius on every track**.
  The follower cannot trace the profile; it meets a step, not a ramp.
- **It cannot be tuned away.** `ramp_fraction` is stuck at 0.20 because the 1.0mm-wide foot needs
  1.0mm of flat dwell to rest on, which at r=12.8 consumes 4.5 of the 5.625 degree slice. Even at
  `ramp_fraction = 1.0` (no dwell at all) the inner track is still 45 degrees.
- Reaching 30 degrees needs inner track r >= 24mm at 0.5mm lift -> disc OD ~68mm, or a
  two-cam split (8 states x 3 tracks each, 8x8 = 64) which gives **9-12 degrees** on ~34mm discs
  at the cost of a second motor per cell.

**Where Codex UNDERSTATES it:** its own research derives M7b = 2.0mm shaft boss, Ø9. A Ø9 boss
cannot enter the Ø5.2 cam bore, so the hub sits on the boss, not the motor face. Interference is
**4.0mm, not 2.0mm**, and spring room goes to **-1.0mm** — the top plate cannot be fitted at all.

### DECISION TAKEN 2026-07-31 — DO NOT REDESIGN YET

The resin plate (`print_resin_1_all`: cam + 12 linkages + dot insert + 3 nav caps) was **already
ordered** and arrives ~4 Aug. That plate **is** the coupon.

**First physical test when it lands, before anything else:** rest one linkage foot on a cam track,
turn the cam slowly BY HAND, watch a ramp transition.
- Climbs smoothly -> the 30-degree rule is overstated here; keep the architecture, fix only the
  vertical stack.
- Jams / skates sideways / needs force -> R-07 is real; choose bigger disc vs two-cam split.

30 degrees is a design guideline, not a law. Resin-on-resin friction has never been measured.
**Do not spend an architecture redesign on an unverified rule of thumb** — that is the same
mistake this project has made repeatedly.

**`pin_lift` 0.8 -> 0.5 is DELIBERATELY NOT APPLIED YET.** It is correct (the standard is
0.46-0.50mm and `docs/BRAILLE_READABILITY.md` already flags 0.8 as 1.6x too tall), but changing
it now would make the source disagree with the physical cam about to be tested. Apply it in the
same pass as the vertical stack.

**Of the ordered plate:** linkages and dot insert stay usable (`link_total_h` derives from the
reading surface, not the lift). The cam will be reprinted. The nav caps are the known pre-fix version.

---
## Current State: CAD is CLEAN except for the above

v7.5 through v7.7 repaired the geometry defects that did not require owned-part measurements. Every part
re-rendered as one connected solid in those verified passes; this v7.8 research update changes documentation and parameter comments only.

| Fixed | Was |
|---|---|
| Hall pocket rebuilt on the plate **underside** at (0, 17.35) | Lay entirely inside the cam pocket at the same depth — **it did not exist on the printed part** |
| Homing magnet pocket now blind, 0.8mm floor left | A through-hole cratering cam tracks **2, 3 AND 4** (the audit said two). Needs a **3×1mm** magnet, NOT 3×2 |
| Spring cavity **deleted** | Swallowed the right motor screw hole at x=+9.5 → one-eared motor, rocks and loses steps |
| `base_length` 56→58 | Left ear screw had a **0.35mm** wall on a 0.4mm nozzle |
| Motor holes → Ø3.3 thread-forming pilots | Ø4.3 clearance holes need a nut, and there is nowhere to put one under the spinning cam |
| `pod_length` 64→68 | ESP32 overran the cavity by 1.75mm. Pod is now a 68×68×58 cube matching a cell |
| `usb_z` formula | Ignored `hdr_channel_depth`; hole sat ~2mm above the port |
| Muscle-board bosses default **off** | Sat inside the ULN2003 footprint, propping it 4mm up in a 16mm pocket |
| `vertical_wire_guides()` **deleted** | A lone 2×1.5×27mm blade (18:1 slender). A wire needs capture on 2+ sides; this captured none |

---

## ⚠️ TWO HARD-WON LESSONS — do not relearn these

**1. `Volumes: 2` proves geometry is CONNECTED, not ATTACHED.**
The -X wire guide passed every automated check while dangling off a **0.1mm sliver over 3mm²**.
Three of this session's defects were found by *opening the STL and looking*, not by any check.
The volume count catches floating geometry; it cannot catch fragile, pointless, or
arithmetically inconsistent geometry.

**2. OrcaSlicer's CLI SILENTLY FALLS BACK TO PLA.**
Anycubic ships **no PETG profile for the Kobra Neo**. The machine profile pins
`default_filament_profile = "Anycubic Generic PLA"`, and Anycubic's own Generic PETG omits the
Kobra Neo from `compatible_printers`. Passing either to `--load-filaments` produces **no error**
— it emits G-code at **200°C nozzle / 45°C bed**, which will not stick and will delaminate.
Always grep the emitted header for `filament_type = PETG`. `slice.sh` does this and refuses to
report OK otherwise. **Never remove that check.**

---

## In Progress
The M1-M28 online measurement fill is complete in the current change set. Public specifications,
owned-part readings, derived values, clone-dependent estimates, and remaining checks are separated
explicitly. No production geometry changed in this pass.

## Next Steps
1. Obtain only the four remaining owned-part checks: M5, M11b/marking, M21, and the exact final
   power-jack part or purchase link.
2. Re-derive the motor/base/cam/linkage vertical stack in one coordinated CAD pass using the now
   measured M2=19.0 mm, M6=9.5 mm, and derived M7b=2.0 mm.
3. Replace the guessed jack cradle with the chosen panel-mount jack dimensions.
4. Print `mid_plate` first to confirm PETG behavior before committing to the box.
5. Change the exposed WiFi password and build the Stage-1 breadboard circuit.
6. Verify M25 after final ULN2003 cable dressing during assembly.

## Print / slice pipeline (NEW)
```
bash printing/orca/slice.sh              # all six PETG parts
bash printing/orca/slice.sh outer_box    # just one
```
| part | time | volume |
|---|---|---|
| outer_box | 4h 30m | 55.59 cm³ |
| esp32_pod_shell | 4h 05m | 52.25 cm³ |
| esp32_pod_lid | 1h 09m | 12.87 cm³ |
| top_plate | 1h 01m | 11.47 cm³ |
| base_plate | 44m | 7.44 cm³ |
| mid_plate | 38m | 7.76 cm³ |

Profiles: `printing/orca/numakers_petg_hs.json` (230/80°C — label allows 220–250/70–90, started
low because stringing scales with temperature) and `braillix_0.20mm_petg.json` (top layers 3→5
and infill 15→25% for the pillowed top surface, walls 2→3 for the screw bosses, z-hop +
`reduce_crossing_wall` for stringing, `bridge_speed` 25 for the sagging wire-exit hole,
`seam_position=back` for the ghost patterns on the walls). **Supports deliberately OFF** — that
is a print-time decision, not a profile one.

## Do NOT regress these
- **`vertical_wire_guides()` is deleted on purpose.** A single blade cannot guide a wire. If pogo
  wiring ever needs managing, copy `cable_hook()` — an L with a 1.5mm overhang that actually
  traps a bundle. `floor_wire_gutters()` is DIFFERENT and is KEPT: a recess with two side walls
  and a base genuinely does retain a wire.
- **The homing magnet is 3×1mm, not 3×2mm.** 2mm removes the entire disc floor.
- **Feet are spread 60° apart.** `braille_cam.scad` pre-rotates each track by its own foot angle
  via `track_phase(t)`. Without that one line every foot reads a different letter.
- **All six arms share `arm_y = 3.5`.** The old per-arm stagger needed 6 height levels; only 3 fit.
- **`link_total_h` = 12.2, measured to the RECESSED reading surface (57.2), not `plate_top_z`
  (58.0).** The plate has a 0.8mm finger-pad recess.
- **Spring is coaxial with the dot**, 2mm OD, in a counterbore in the dot insert. NOT a mid-arm pad.
- **Braille dot is a printed 1.5mm dome.** No bearing balls.
- **Software dot→bit is a LOOKUP:** `DOT_TO_BIT = {1:3, 2:2, 3:1, 4:4, 5:5, 6:0}`. Not a formula.
- **In OpenSCAD, `use` imports modules ONLY; `include` imports modules AND variables.**
  Referencing a variable across a `use` boundary fails SILENTLY as `undef` and geometry vanishes.
- **`cube()` is NOT centred** — it grows in +X. That is exactly how the -X wire guide ended up
  floating. Mirror-symmetric features need an explicit per-side span.
- **Credentials live in `firmware/breadboard_test/secrets.h` (gitignored).** Never inline them.

## Key Files Modified (this session)
| File | What |
|---|---|
| `cad/scad/base_plate.scad` | hall pocket rebuilt underside; spring cavity deleted; pilots; 56→58 |
| `cad/scad/braille_cam.scad` | magnet pocket blind (1.2mm); z-stack failure documented |
| `cad/scad/mech_layout.scad` | **NEW** shared `homing_mag_*` block (was declared twice, had drifted) |
| `cad/scad/outer_box.scad` | wire guides deleted; muscle bosses off; both 2mm errors documented |
| `cad/scad/esp32_pod_params.scad` | pod 64→68; usb_z fix; `lid_screw_x` made a formula |
| `cad/scad/esp32_pod_lid.scad` | dims derived from pod; cradle assert |
| `cad/scad/mid_plate.scad` | comment only — collar ID tagged MEASURE (M1) |
| `printing/orca/*` | **NEW** — filament + process profiles, slice.sh |
| `printing/gcode/*` | **NEW** — six sliced parts |
| `docs/MEASUREMENTS_NEEDED.md/.pdf` | **NEW** — plain-English + technical, answer sheet |
| `docs/CAD_CHANGELOG_v7.5.md/.pdf` | **NEW** — side-by-side record of all changes |
| `docs/CAD_FIT_CHECK.md` | header table marking which findings are now fixed |
| `docs/ELECTRONICS_BOM.md` | magnet 3×2 → 3×1; motor screws no longer need nuts |
