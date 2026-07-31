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
