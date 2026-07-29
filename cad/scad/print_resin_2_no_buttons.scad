// =========================================================
// RESIN PRINT PLATE 2 of 3 — CAM + LINKAGES + TOP PLATE
// v7.1 — 2026-07-26
//
// Everything needed to actually assemble and test one working braille
// cell mechanism, minus the pod's nav buttons.
//
// Material: TOUGH or ABS-like resin (NOT standard brittle resin).
// Orientation: as laid out. A print service may re-orient; fine.
//
// NOTE: the top plate dominates the cost here — it is roughly 4x the
// volume of the cam and all eight linkages put together.
//
// Needs separately: 6x 2mm-OD micro compression springs (see SOURCING.md).
// =========================================================

use <braille_cam.scad>   // braille_cam()
use <linkage.scad>       // linkage_3d_v4(dot)
use <top_plate.scad>     // top_plate()

$fn = 60;

linkage_dots = [1, 2, 3, 4, 5, 6, 6, 3];

col_pitch = 22;
row_pitch = 14;
grid_x0   = 38;    // right of the top plate's +34 edge
grid_y0   = -82;

cam_y     = -60;   // below the top plate's -35 edge

// --- TOP PLATE: centred at origin (68 x 70). Lifted 4mm so the
//     downward ±Y skirt rests on z=0 instead of hanging below it. ---
translate([0, 0, 4]) top_plate();

// --- CAM: below the plate ---
translate([0, cam_y, 0]) braille_cam();

// --- LINKAGES: 2 columns x 4 rows, to the right of the cam ---
for (i = [0 : len(linkage_dots) - 1])
    translate([grid_x0 + floor(i / 4) * col_pitch,
               grid_y0 + (i % 4) * row_pitch,
               0.6])
        linkage_3d_v4(linkage_dots[i]);
