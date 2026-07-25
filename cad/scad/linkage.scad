// =========================================================
// BRAILLIX LINKAGE SET — Resin-Printed Cranks
// Revision 4.0 — Spread feet + shape overhaul (v7.0, 2026-07-26)
//
// Print 8 (6 required + 2 spares) in TOUGH or ABS-like resin, flat on
// the plate. Post-process: nothing. No bearing balls, no glue, no
// machined cup — the braille dot is printed as part of the linkage.
//
// ---------------------------------------------------------
// WHAT CHANGED IN v4.0 AND WHY
// ---------------------------------------------------------
// 1. FEET SPREAD 60deg APART (see mech_layout.scad for the full
//    reasoning). Consequence here: arm_y is now ONE CONSTANT shared by
//    all six linkages instead of six different heights. The old stagger
//    (3.5/4.0/7.8/9.5) existed only to stop overlapping arms colliding,
//    and it pushed three arms straight through the top plate.
//
// 2. total_h 12.0 -> 13.0. The top plate was thickened 3->4mm long ago
//    but this file was never updated, so the linkage was 1mm too SHORT:
//    the dot topped out 0.2mm BELOW the reading surface even when fully
//    raised. It literally could not be felt. (This does NOT make the
//    device taller — 13mm is the gap that already exists between the cam
//    surface and the top plate.)
//
// 3. FOOT REBUILT. Was a hull of two circles + two slivers, which came
//    out as an ugly teardrop wedge tapering to a 0.2mm point. Now a
//    proper 0.5mm-radius roll lying across the track: rounded in the
//    direction of travel so it rides cam ramps instead of stubbing into
//    them, flat across the track width so it sits stable.
//
// 4. FOOT WIDTH 2.0 -> 1.4mm (radial). At 2.0mm on a 1.6mm track at
//    1.7mm pitch the foot hung 0.1mm onto BOTH neighbouring tracks. A
//    rigid foot rests on its highest contact, so any time a neighbour
//    was UP and this track DOWN, the foot rode the neighbour's 0.8mm
//    bump and lifted the WRONG dot.
//
// 5. BRAILLE DOT IS NOW A PRINTED DOME on the nub top. Previously the
//    file contradicted itself: the stack maths treated the flat nub top
//    as the dot, while a comment said to glue a 2mm bearing ball on top
//    (which would have held the dot ~1.2mm proud permanently, even when
//    down). Dome removes the ball, the glue, the cup and the sourcing.
//
// 6. SPRING SEAT PAD added partway along the arm. Return springs cannot
//    live at the dot: braille rows are 2.6mm apart and the nub is 2.2mm,
//    leaving 0.4mm — a 4mm pen spring would eat 1.4mm into its
//    neighbour. Out at 7mm along the arm the seats are 7.5mm apart.
//
// 7. FILLETS on every internal corner + softened outer corners. Sharp
//    internal corners are where resin parts crack, so this is strength,
//    not just looks.
// =========================================================

include <mech_layout.scad>

// --- 1. PARAMETERS ---

thickness   = 1.0;   // sheet thickness. Once assembled this is the foot's
                     // TANGENTIAL contact width — it must fit inside the cam's
                     // flat dwell zone (see braille_cam.scad v6.3 header).
foot_w      = 1.4;   // foot RADIAL width: 1.6mm track - 0.1mm clearance/side
foot_len    = 2.5;   // foot height, contact face up to the riser
foot_roll_r = 0.5;   // radius of the rolled contact face (= thickness/2)

arm_h       = 1.0;   // horizontal arm thickness
arm_y       = 3.5;   // COMMON to all six (v7.0). Arm top when a dot is raised =
                     // 3.5+1.0+0.8 = 5.3mm, vs plate underside at 9.0mm -> 3.7mm clear.

nub_w       = 2.2;   // nub width where it passes the 2.5mm top-plate hole
nub_h       = 1.5;   // nub height below the dome
dot_r       = 1.1;   // printed braille dot radius (2.2mm dome)

total_h     = link_total_h;   // 13.0 from mech_layout.scad

seat_d      = spring_seat_d;      // 5.0 spring pad diameter
seat_h      = 1.0;                // pad thickness above the arm
seat_x      = spring_seat_dist;   // 7.0 along the arm from the nub

fillet_in   = 0.6;   // internal corner fillets (strength)
fillet_out  = 0.25;  // outer corner softening (feel/looks)

$fn = 48;

// --- 2. 2D BODY PROFILE ---
// Local frame: X = arm direction (0 = nub end, span = foot end), Y = vertical.
// Foot and nub are built in 3D below, so this profile covers only the
// risers + arm and overlaps them slightly.

module body_profile_raw(dot) {
    span = arm_span(dot);
    union() {
        // lower riser: foot top up to arm bottom, at the foot end
        translate([span - thickness/2, foot_len - 0.1])
            square([thickness, arm_y - foot_len + 0.1]);
        // horizontal arm
        translate([0, arm_y])
            square([span, arm_h]);
        // upper riser: arm top up into the nub, at the nub end
        translate([-thickness/2, arm_y + arm_h])
            square([thickness, total_h - nub_h - (arm_y + arm_h) + 0.1]);
    }
}

// Fillet pass.
//   CLOSING (dilate then erode) fills concave corners = the strength fillets.
//   OPENING (erode then dilate) softens convex corners = the "less blocky" look.
// Both restore the original 1.0mm member thickness exactly.
//
// CAREFUL — OpenSCAD applies offset() INSIDE-OUT: the innermost offset runs
// first. Writing the pair the natural-reading way round erodes by fillet_in
// FIRST, which deletes every 1.0mm-thick member (1.0 - 2*0.6 < 0) and leaves
// a hollow shell. Keep this nesting order.
module body_profile(dot) {
    offset(r = fillet_out) offset(r = -fillet_out)      // ...then opening
        offset(r = -fillet_in) offset(r = fillet_in)    // closing runs first...
            body_profile_raw(dot);
}

// --- 3. 3D FEATURES ---

// Rounded cam-follower foot: a roll lying ACROSS the track, so it is
// curved in the direction of travel and flat across the track width.
module foot_3d(dot) {
    span = arm_span(dot);
    hull() {
        translate([span - foot_w/2, foot_roll_r, thickness/2])
            rotate([0, 90, 0])
                cylinder(r = foot_roll_r, h = foot_w);
        translate([span - thickness/2, foot_len, 0])
            cube([thickness, 0.01, thickness]);
    }
}

// Braille dot: printed dome on the nub top. Hulled down to the nub base
// so there is no undercut and no step for a finger to catch.
module nub_dome_3d() {
    hull() {
        translate([-nub_w/2, total_h - nub_h, 0])
            cube([nub_w, 0.01, thickness]);
        translate([0, total_h - dot_r, thickness/2])
            sphere(r = dot_r);
    }
}

// Return-spring seat: a pad on top of the arm for the spring to push down on.
// Chamfered underside so it prints without a sharp overhang shelf.
module spring_seat_3d() {
    translate([seat_x, arm_y + arm_h - 0.4, thickness/2])
        rotate([-90, 0, 0])
            cylinder(d1 = seat_d - 0.8, d2 = seat_d, h = seat_h + 0.4);
}

// --- 4. COUNT-DOTS: which linkage is which ---
// Raised dots on the arm, 1..6 = braille dot number. Assembly is otherwise
// self-aligning (nub in its hole + rigid arm puts the foot on its own track
// automatically), so this is purely to tell the six parts apart in the hand.
module count_dots_3d(dot) {
    // Bumps around the RIM of the spring pad, one per braille dot number.
    // Not on the arm: the pad (5mm) covers 4.5-9.5mm along the arm and simply
    // swallowed them there, and the shortest linkage has no clear arm left
    // beyond the pad. The rim also keeps them off the pad's top face, which
    // has to stay flat for the spring to seat.
    // Placed on the +Z side of the rim (a~90deg), clear of the 1mm-thick arm.
    r  = seat_d / 2;
    yc = arm_y + arm_h + 0.5;              // inside the pad's height
    for (i = [0 : dot - 1]) {
        a = 90 + (i - (dot - 1) / 2) * 22;
        translate([seat_x + r * cos(a), yc, thickness/2 + r * sin(a)])
            sphere(d = 1.0, $fn = 16);
    }
}

// --- 5. COMPLETE LINKAGE ---

module linkage_3d_v4(dot) {
    union() {
        linear_extrude(height = thickness) body_profile(dot);
        foot_3d(dot);
        nub_dome_3d();
        spring_seat_3d();
        count_dots_3d(dot);
    }
}

// Backwards-compatible alias (older files call linkage_3d_v3)
module linkage_3d_v3(dot) { linkage_3d_v4(dot); }

// --- 6. FLAT LAYOUT FOR PRINTING ---
// Six linkages laid flat side by side. Print files use linkage_3d_v4()
// directly — see print_resin_cam_linkage.scad.

spacing = 22;
for (d = [1 : 6])
    translate([(d - 1) * spacing, 0, 0])
        linkage_3d_v4(d);

// --- 7. REFERENCE (computed live by mech_layout.scad — documentation only) ---
// dot | track |  r    | foot@ | arm span | nub at
//  1  |   2   | 16.20 | 120deg|  12.77   | (-2.4, +2.6)
//  2  |   3   | 17.90 | 180deg|  15.50   | (-2.4,  0.0)
//  3  |   4   | 19.60 | 240deg|  16.17   | (-2.4, -2.6)
//  4  |   1   | 14.50 |  60deg|  11.08   | (+2.4, +2.6)
//  5  |   0   | 12.80 |   0deg|  10.40   | (+2.4,  0.0)
//  6  |   5   | 21.30 | 300deg|  17.87   | (+2.4, -2.6)
//
// Closest approach between any two arms: 2.60mm (dots 1 & 2) vs 1.0mm
// arm thickness -> all six share arm_y = 3.5mm with margin to spare.
