// =========================================================
// COMPONENT: POGO END CAP — Short-Circuit Prevention Cover
// Revision 1.0
// Created 2026-05-06
//
// Snap-fit cover for the LAST cell in the daisy chain.
// Covers the exposed right-side spring pogo pins to prevent
// accidental short-circuits from metal objects (rings, keys, coins).
// (Audit 6.2)
//
// Print in TPU (flexible, soft — won't scratch, easy snap-on/off).
// Snaps into the right-wall pogo slot of the outer_box.
// =========================================================

// --- 1. PARAMETERS ---

// Must match outer_box.scad pogo slot dimensions
pogo_slot_w      = 10;     // Width of pogo slot in outer_box wall
pogo_slot_h      = 8;      // Height of pogo slot
wall_thickness   = 4;      // outer_box wall thickness

// Cap body
cap_w            = pogo_slot_w + 2;  // 12mm — slightly wider for grip
cap_h            = pogo_slot_h + 2;  // 10mm — slightly taller for grip
cap_depth        = 8;                // How deep the cap inserts into slot
cap_wall         = 1.5;             // Cap shell thickness

// Snap lip — catches on inner edge of pogo slot
// v6.1: 0.5→1.0mm — 0.5 was below FDM layer resolution and gave no real snap (TPU flexes)
snap_lip_h       = 1.0;   // Overhang height
snap_lip_depth   = 1.0;   // How far the lip extends inward

// Rounded edges for comfort
cap_fillet       = 1.0;

$fn = 40;

// --- 2. MODULES ---

module cap_outer() {
    // Main body — rounded rectangle
    hull() {
        for(sx = [-1, 1]) for(sy = [-1, 1]) {
            translate([sx * (cap_w/2 - cap_fillet),
                       sy * (cap_h/2 - cap_fillet), 0])
                cylinder(r=cap_fillet, h=cap_depth);
        }
    }
}

module cap_inner() {
    // Hollow out interior (leave cap_wall thickness on all sides)
    inner_w = cap_w - 2 * cap_wall;
    inner_h = cap_h - 2 * cap_wall;
    translate([-inner_w/2, -inner_h/2, cap_wall])
        cube([inner_w, inner_h, cap_depth]);
}

module snap_lips() {
    // Two snap lips on ±Y sides — catch on pogo slot edge
    for(sy = [-1, 1]) {
        // Lip is a thin ridge near the insertion end
        translate([0, sy * (pogo_slot_h/2 + snap_lip_h/2),
                   cap_depth - snap_lip_depth - 1])
            cube([pogo_slot_w - 2, snap_lip_h, snap_lip_depth], center=true);
    }
}

module end_marker() {
    // Raised ridge on the EXPOSED (outward, Z=0) face so a blind user feels "end of chain".
    // v6.1: 2.4→3.2mm wide, 1.2mm proud — anything narrower distorts on FDM/TPU.
    translate([0, 0, -0.4])
        hull() {
            translate([-3, 0, 0]) cylinder(d=3.2, h=1.6, $fn=20);
            translate([ 3, 0, 0]) cylinder(d=3.2, h=1.6, $fn=20);
        }
}

module pogo_end_cap() {
    union() {
        difference() {
            cap_outer();
            cap_inner();
        }
        snap_lips();
        end_marker();
    }
}

// --- 3. GENERATE ---

pogo_end_cap();

// --- 4. NOTES ---
// Material: TPU (Shore 95A) — flexible for easy snap-on/off
// Print: flat on build plate (cap_depth along Z)
// Usage: snap onto right-side pogo slot of last cell in chain
// Removal: squeeze sides gently, pull outward
