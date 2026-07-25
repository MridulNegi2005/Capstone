// =========================================================
// PRINT LAYOUT: NAV BUTTON CAPS — Separate Resin Order
// Created 2026-06-14 (v6.3)
//
// The 3 nav caps (Prev/Select/Next), packed tight for their own resin
// order — kept SEPARATE from print_resin_cam_linkage.scad so the two
// jobs can be timed/ordered independently (e.g. different resin color,
// or order this one later without re-touching the cam/linkage job).
//
// Contents (3 bodies): nav_cap_prev(), nav_cap_select(), nav_cap_next()
// from nav_cap.scad — reused as-is, already a tight 12mm-pitch layout.
//
// Print orientation: shaft DOWN on build plate, dome + raised symbol UP
// (per nav_cap.scad). No supports needed.
// Material: resin (tactile symbols need the precision; PETG mushed
// small raised features in fit-testing — see v6.1 addendum).
// Bed footprint: ~36mm x 8mm — tiny, cheap on its own.
// =========================================================

use <nav_cap.scad>   // nav_cap_prev(), nav_cap_select(), nav_cap_next()

$fn = 60;

translate([-12, 0, 0]) nav_cap_prev();
translate([  0, 0, 0]) nav_cap_select();
translate([ 12, 0, 0]) nav_cap_next();
