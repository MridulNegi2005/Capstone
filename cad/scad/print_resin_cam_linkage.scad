// =========================================================
// PRINT LAYOUT: CAM + LINKAGES — Single Resin Order
// Created 2026-06-14 (v6.3)
//
// Combines the cam disc and all 8 linkages (6 required + 2 spares) onto
// ONE small plate so they can be a SINGLE resin order/upload — one
// setup/shipping charge instead of two. Parts are packed close together,
// not spread across a huge bed.
//
// Contents (9 bodies total):
//   - 1x  cam disc            (braille_cam.scad)   ~44.4mm dia
//   - 8x  linkage             (linkage.scad)        dot 0,1,2,3,4,5 (the
//                                                    6 required) + dot 2
//                                                    and dot 5 REPEATED as
//                                                    spares (longest arm
//                                                    span = most fragile,
//                                                    so most likely to
//                                                    snap first)
//
// IMPORTANT — read before ordering:
//   v6.3 changed the cam's bit->track mapping (see braille_cam.scad
//   header). This file automatically uses whatever get_pattern_bit()
//   currently does — no action needed here, just don't print an OLD
//   cached cam STL alongside NEW linkages (or vice versa). Render this
//   file fresh right before ordering.
//
// Print orientation: flat as generated (cam hub-down, linkages flat panel
// down) — matches each part's own documented orientation. No supports
// needed for either part per their own file headers.
// Material: TOUGH or ABS-like resin (both parts — cam precision tracks,
// linkage fatigue strength).
// Bed footprint: ~90mm x 80mm (verify against your resin printer once
// rendered — this is comfortably inside every common small/mid MSLA bed).
// =========================================================

include <mech_layout.scad>   // arm_span() — used to space the grid correctly
use <braille_cam.scad>       // braille_cam()
use <linkage.scad>           // linkage_3d_v4(dot)

$fn = 60;

// --- CAM (left) ---
// braille_cam() is already built centred at origin, hub pointing down
// (correct print orientation) — see braille_cam.scad module wrapper.
braille_cam();

// --- LINKAGES (right, tight 2-col x 4-row grid) ---
// v7.0: dots use standard braille numbering 1..6. Print all six, plus two
// spares duplicating dots 6 and 3 — the two longest arms (17.9mm / 16.2mm)
// and so the most likely to snap in handling. Spares are exact duplicates.
linkage_dots = [1, 2, 3, 4, 5, 6, 6, 3];

// Cam outer radius ~22.2mm (inner_radius=12 + 6 tracks x 1.7mm pitch).
// Grid starts at x=26 — clears the cam edge with a small safety margin.
grid_x0 = 26;
// v6.3 FIX: col_w was 21 -> the two columns ended up only 0.12mm apart, which resin
// will fuse into a single blob (rule of thumb: keep >=0.5mm, prefer ~2mm, between
// separate parts on one plate). 23 gives a ~2.4mm gap. Verified by measuring actual
// part X-extents (nub at -1.1 .. foot at arm_span+foot_w/2), not by eyeballing.
col_w   = 23;   // grid cell width (widest arm 17.9mm + foot + ~4mm gap)
row_h   = 14;   // grid cell height (linkage total_h=12mm + 2mm gap)
cols    = 2;

for (i = [0 : len(linkage_dots) - 1]) {
    col = floor(i / 4);
    row = i % 4;
    translate([grid_x0 + col * col_w, row * row_h, 0])
        linkage_3d_v4(linkage_dots[i]);
}
