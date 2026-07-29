// =========================================================
// RESIN PRINT PLATE 1 of 3 — CAM + LINKAGES + TOP PLATE + NAV BUTTONS
// v7.1 — 2026-07-26
//
// The full resin batch: one complete braille cell mechanism plus the
// three nav button caps for the ESP32 brain pod.
//
// Material: TOUGH or ABS-like resin (NOT standard brittle resin).
// Orientation: as laid out (nav caps shaft-DOWN, dome + raised symbol UP,
// so the tactile symbols need no supports). A service may re-orient.
//
// NOTE: the top plate dominates the cost — roughly 4x the volume of the
// cam and all eight linkages together. The three nav caps add very little.
//
// Needs separately: 6x 2mm-OD micro compression springs (see SOURCING.md).
// =========================================================

use <braille_cam.scad>   // braille_cam()
use <linkage.scad>       // linkage_3d_v4(dot)
use <top_plate.scad>     // top_plate()
use <nav_cap.scad>       // nav_cap_prev() / _select() / _next()

$fn = 60;

linkage_dots = [1, 2, 3, 4, 5, 6, 6, 3];

col_pitch = 22;
row_pitch = 14;
grid_x0   = 38;
grid_y0   = -82;

cam_y     = -60;
nav_x     = -29;   // left of the cam's -22.2 edge, inside the plate's -34
nav_y0    = -74;
nav_pitch = 12;

// --- TOP PLATE: centred at origin, lifted so the skirt rests on z=0 ---
translate([0, 0, 4]) top_plate();

// --- CAM ---
translate([0, cam_y, 0]) braille_cam();

// --- LINKAGES: 2 columns x 4 rows ---
for (i = [0 : len(linkage_dots) - 1])
    translate([grid_x0 + floor(i / 4) * col_pitch,
               grid_y0 + (i % 4) * row_pitch,
               0.6])
        linkage_3d_v4(linkage_dots[i]);

// --- NAV BUTTON CAPS: column to the left of the cam ---
translate([nav_x, nav_y0 + 2 * nav_pitch, 0]) nav_cap_prev();
translate([nav_x, nav_y0 + 1 * nav_pitch, 0]) nav_cap_select();
translate([nav_x, nav_y0 + 0 * nav_pitch, 0]) nav_cap_next();
