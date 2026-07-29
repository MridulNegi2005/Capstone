// =========================================================
// RESIN PRINT PLATE 3 of 3 — CAM + LINKAGES ONLY
// v7.1 — 2026-07-26
//
// The bare minimum to test the mechanism: the cam disc and all six
// linkages (+2 spares). Cheapest of the three quotes.
//
// Material: TOUGH or ABS-like resin (NOT standard brittle resin — the
// linkages are 1mm thin sections under repeated spring load).
// Orientation: as laid out (cam hub DOWN, linkages FLAT). A print service
// may re-orient; that is fine, geometry is what matters.
//
// Needs separately: 6x 2mm-OD micro compression springs (see SOURCING.md).
// =========================================================

use <braille_cam.scad>   // braille_cam()
use <linkage.scad>       // linkage_3d_v4(dot)

$fn = 60;

// 6 required + 2 spares. Spares duplicate dots 6 and 3 — the two longest
// arms (17.9 / 16.2mm) and therefore the likeliest to snap in handling.
linkage_dots = [1, 2, 3, 4, 5, 6, 6, 3];

col_pitch = 22;   // widest linkage is ~19.7mm across -> ~2.3mm gap
row_pitch = 14;   // linkage is 13mm tall -> 1mm gap
grid_x0   = 27;   // clears the cam's 22.2mm outer radius
grid_y0   = -22;

// --- CAM: centred at origin, hub already resting on z=0 ---
braille_cam();

// --- LINKAGES: 2 columns x 4 rows ---
// lifted 0.6mm so the spring flange (which hangs below the body) sits on z=0
for (i = [0 : len(linkage_dots) - 1])
    translate([grid_x0 + floor(i / 4) * col_pitch,
               grid_y0 + (i % 4) * row_pitch,
               0.6])
        linkage_3d_v4(linkage_dots[i]);
