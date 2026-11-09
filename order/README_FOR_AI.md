# Print order: one Braillix muscle cell

This folder is the complete print order for one muscle cell of the Braillix braille display.
The reader of this file is an AI agent that gets quotes and places the order with an online print service.
The human owner is a student. The owner chooses the service and approves every payment.

## Rules for the agent

1. Do not pay, accept terms or submit an order. Collect the quotes. Give them to the owner for approval.
2. Upload every STL at 100% scale. The unit is millimetres. Do not scale, repair, hollow, simplify or merge any file.
3. Do not ask the service to change a hole, a gap or a wall thickness. The fits are designed into the files.
4. Order the quantities in the tables. One file is one part.
5. If the service cannot meet a requirement that is marked **MUST**, stop. Report the conflict to the owner.
6. Check every file against `MANIFEST.json` (size and SHA-256) before upload. If a value does not match, stop.
7. Ask for delivery before the end of the current week if the price difference is small. Report the delivery dates.

## Part list

### Resin parts (folder `resin/`, SLA, MSLA or DLP)

| File | Qty | Size (mm) | What it is |
|---|---|---|---|
| `cam.stl` | 1 | 48.4 x 48.4 x 9.0 | Disc with six tracks. It turns and lifts the arms. |
| `comb_light.stl` | 1 | 54.0 x 54.0 x 2.8 | Plate with slots that guide the six arms. |
| `dot_tile.stl` | 1 | 15.0 x 15.0 x 3.2 | Small plate. The six braille dots come up through its holes. |
| `arm_1.stl` to `arm_6.stl` | 1 each | about 20 x 12 x 2.2 | Six different arms. Each arm lifts one dot. |

Resin requirements:

- **MUST**: tough or ABS-like resin. Standard (brittle) resin is not acceptable. The arms bend in use.
- **MUST**: solid parts. Do not hollow.
- **MUST**: keep the small features: 1 mm walls on the arms, 0.1 mm gaps, 1.7 mm holes.
- The service chooses the orientation and the supports. Ask for no support marks on these surfaces:
  - the cam: the top face with the six tracks;
  - the arms: the small round dot tip and the foot that touches the cam.
- Ask for normal wash and post-cure. Any colour is acceptable.

### PETG parts (folder `petg/`, FDM)

| File | Qty | Size (mm) | What it is |
|---|---|---|---|
| `box.stl` | 1 | 68 x 68 x 54 | Outer box. Holds the motor and the two circuit boards. |
| `base_plate.stl` | 1 | 58 x 56 x 12 | Plate that holds the cam and the Hall sensor. |
| `top_plate.stl` | 1 | 68 x 68 x 4.6 | Lid. The reading surface. |
| `hall_retainer.stl` | 2 | 16.5 x 13 x 1.3 | Small clip for the Hall sensor (one spare). |
| `finger_sheet_072_soft.stl` | 1 | 58 x 56 x 2.8 | Flat spring sheet, soft. |
| `finger_sheet_088_normal.stl` | 2 | 58 x 56 x 2.8 | Flat spring sheet, normal (one spare). |
| `finger_sheet_104_stiff.stl` | 1 | 58 x 56 x 2.8 | Flat spring sheet, stiff. |

PETG requirements:

- **MUST**: PETG. Not PLA. Not ABS.
- **MUST**: print each part in the orientation of the file. The flat face at z = 0 goes on the bed. No supports.
- **MUST** for the three finger sheet files: layer heights that put these heights exactly on a layer top:
  0.72, 0.88 and 1.04 mm. Accept one of these two layer settings:
  - first layer 0.24 mm, all other layers 0.16 mm (preferred);
  - all layers 0.08 mm.

  A 0.20 mm layer setting is not acceptable for the finger sheets. The spring force changes with the
  thickness cubed, so a rounded thickness gives the wrong force.
- **MUST** for the finger sheets: 5 walls (perimeters) or more. The 3 mm wide tongues must be all wall lines.
- Other parts: 0.16 to 0.20 mm layers, 5 walls, 40% infill.
- Ask the service to remove the finger sheets from the bed only when the bed is cold. Hot PETG bends and stays bent.
- Any colour is acceptable. Use one colour for all PETG parts if that is cheaper.

## Quote form for the owner

Give the owner one table per service with these columns:
service name, material and grade, layer setting for the finger sheets, price per part, shipping, total price, delivery date.

## Parts that are not in this order

The owner buys or has these parts. They are not printed:
the 28BYJ-48 motor, the ULN2003 driver module, the 7Semi MCP23017 breakout, the A3144 Hall sensor,
3 x 1.5 mm magnets, M2.5 screws and brass heat-set inserts, M2 screws.

## Source and checks

The source CAD is in `cad/scad/`. `tools/make_order.py` makes this folder from `cad/stl/` and `cad/assets/`.
Before this folder was made, `tools/check_current_muscle.py` passed all collision checks for the assembled cell.
