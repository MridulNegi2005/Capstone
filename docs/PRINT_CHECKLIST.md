# Braillix v5.0 — Print Day Checklist

## STL Files (all in `cad/stl/`)

### PROTOTYPE ROUND — ALL PETG

| # | File | Part | Qty | Orientation | Supports | Est. Time | Notes |
|---|---|---|---|---|---|---|---|
| 1 | `outer_box.stl` | Motor cell shell | x1 per cell | Open-top UP | None | ~3h | Semi-hollow, 4mm walls |
| 2 | `mid_plate.stl` | Mid-plate + collar | x1 per cell | Flat | None | ~30min | Motor collar faces up |
| 3 | `base_plate.stl` | Base plate | x1 per cell | Flat (ribs down) | None | ~1h | Ribs print bridging - ok |
| 4 | `braille_cam2.stl` | Cam disc | x1 per cell | Hub DOWN, tracks UP | None | ~1.5h | Resin for final |
| 5 | `linkage_comb.stl` | Linkage guide | x1 per cell | Flat | None | ~20min | |
| 6 | `top_plate.stl` | Top plate | x1 per cell | Flat | None | ~1h | Resin for final |
| 7 | `esp32_pod_shell.stl` | Pod shell | x1 total | Open-top UP | None | ~3h | |
| 8 | `esp32_pod_lid.stl` | Pod lid | x1 total | Flat (jack up) | None | ~30min | |
| 9 | `nav_cap.stl` | Nav caps x3 | x1 set total | Shaft DOWN, dome UP | None | ~15min | Resin for final |
| 10 | `pogo_end_cap.stl` | End cap | x1 total | Flat | None | ~10min | TPU if available |

### DO NOT PRINT
| File | Why |
|---|---|
| `braille_cap.stl` | DEPRECATED — ball-on-nub replaces this |
| `print_small_parts.stl` | Composite plate (cam+caps) — print individually instead |
| `linkage.stl` | Laser-cut 1mm steel, not 3D printed (use cardboard for prototype fit test) |

## PETG Print Settings (recommended)
- Layer height: 0.2mm (0.16 for cam disc)
- Infill: 20% for shells, 40% for base plate + mid-plate
- Walls: 3 perimeters minimum
- Nozzle: 0.4mm
- Temp: 230-240C nozzle, 80C bed
- Speed: 50mm/s for outer walls
- No supports needed for any part!

## Print Order (suggested)
```
DAY 1 — Fit-test coupon:
  [ ] top_plate.stl
  [ ] braille_cam2.stl
  --> Test: does nub pass 2.5mm hole? Does cam sit in pocket?

DAY 1 — While testing coupon:
  [ ] outer_box.stl (longest print, start it)
  [ ] esp32_pod_shell.stl

DAY 2 — Internals:
  [ ] base_plate.stl
  [ ] mid_plate.stl
  [ ] linkage_comb.stl

DAY 2 — Small parts:
  [ ] esp32_pod_lid.stl
  [ ] nav_cap.stl (3 caps on one plate)
  [ ] pogo_end_cap.stl
```

## FINAL ROUND — Resin (after prototype validates fit)
| File | Why resin |
|---|---|
| `braille_cam2.stl` | 0.8mm bumps need SLA precision; FDM layer lines cause motor stall |
| `top_plate.stl` | 2.5mm holes need tight tolerance for bearing balls |
| `nav_cap.stl` | Raised symbols must be smooth for blind user's fingertips |

## Pre-Print Measurements Needed
- [ ] 28BYJ-48 shaft: usable length + D-flat profile (one-flat or double?)
- [ ] ESP32 DevKit V1 pin-row pitch: 22.9mm or 25.4mm? (update `hdr_row_pitch` in `esp32_pod_params.scad`)
- [ ] Chosen 4-pin pogo connector: L x W x H (update `pogo_carrier_*` in `outer_box.scad`)
- [ ] Muscle board mounting holes: read coords from KiCad (update `mb_boss_positions` in `outer_box.scad`)

## Hardware Shopping List (for assembly after printing)
- [ ] 28BYJ-48 stepper motor x N
- [ ] 5V/3A barrel jack adapter + panel-mount jack
- [ ] ESP32 DOIT DevKit V1 (30-pin)
- [ ] 2x 1x15 female header strips (for pod)
- [ ] 4-pin pogo connector pairs x (N+1)
- [ ] SS49E hall sensor x N
- [ ] 3x2mm NdFeB magnets (3 per docking face)
- [ ] 2mm SS bearing balls x 6 per cell
- [ ] Micro compression springs OD 4-4.5mm x 6 per cell
- [ ] 6x6x5mm tactile switches x 3 (pod buttons)
- [ ] M2.5x25 bolts x 4 per cell (corner through-bolts)
- [ ] M2x6 screws x 4 per cell (muscle board) + 2 (pod lid)
- [ ] M4 bolts x 2 per cell (motor mount)
- [ ] M2 grub screw x 1 per cell (comb lock)
- [ ] 4.7k resistors x 2 (I2C pull-ups, pod only)
- [ ] Hookup wire (22-26 AWG) + heat shrink
- [ ] Superglue (bearing balls onto nubs)
- [ ] Silicone grease (linkage feet on cam tracks)
