// =========================================================
// PRINT LAYOUT: ALL SMALL PRINTABLE PARTS — One Build Plate
// Created 2026-05-08
//
// Parts included (10 bodies total):
//   Row 1 — Top plate (60×60mm)           ← RESIN (SLA/MSLA)
//   Row 2 — Cam disc (Ø37mm)              ← PETG
//   Row 3 — 3× Nav caps (◁ ○ ▷)          ← PETG
//   Row 4 — 6× Braille dot caps           ← PETG or RESIN
//
// Slicer instructions:
//   * Top plate   → assign to RESIN extruder / separate resin print
//                   Reason: Ø2.0mm braille holes have only 0.1mm clearance
//                   over 1.9mm cap pin — FDM undersizes to ~1.7mm (too tight)
//   * Everything else → PETG, 0.15mm layer height
//
// NOT included (too large for this plate):
//   Linkages  → laser-cut 1mm stainless steel (linkage.scad → DXF)
//   Pod shell → esp32_pod_shell.scad  (separate PETG print)
//   Pod lid   → esp32_pod_lid.scad    (separate PETG print)
//   Outer box → outer_box.scad        (separate PETG print)
//
// Supports:     NONE required for any part
// Bed footprint: ~85 mm × 150 mm
//
// Print orientations:
//   Top plate    — spring pockets DOWN on plate, finger-pad recess UP
//   Cam disc     — hub DOWN on plate, cam tracks UP  (lifted +4mm in module)
//   Nav caps     — shaft DOWN on plate, dome + raised symbol UP
//   Braille caps — pin tip DOWN on plate, bearing cup UP
// =========================================================

use <nav_cap.scad>       // nav_cap_prev(), nav_cap_select(), nav_cap_next()
use <braille_cap.scad>   // braille_cap()
use <braille_cam2.scad>  // braille_cam2()

$fn = 60;

// -------------------------------------------------------
// ROW 1 — Cam disc  (centred at origin)
// Ø≈37mm × 6.8mm tall (hub 4mm + disc+tracks 2.8mm)
// -------------------------------------------------------
translate([0, 0, 0])
    braille_cam2();

// -------------------------------------------------------
// ROW 2 — Nav caps  (y = -40, clear of cam disc edge at y≈-18.5)
// Each cap: Ø8mm base × 5.8mm tall, 12mm pitch
// -------------------------------------------------------
translate([0, -40, 0]) {
    translate([-12, 0, 0]) nav_cap_prev();
    translate([  0, 0, 0]) nav_cap_select();
    translate([ 12, 0, 0]) nav_cap_next();
}

// -------------------------------------------------------
// ROW 3 — Braille dot caps  (y = -60, clear of nav cap edge at y≈-44)
// 6 caps, 8mm pitch, centred on x=0 → start at x = -(5×8)/2 = -20
// Each cap: Ø3.5mm body × 7mm tall (pin 5.5mm + body 1.5mm)
// -------------------------------------------------------
translate([-20, -60, 0])
    for(i = [0:5])
        translate([i * 8, 0, 0])
            braille_cap();
