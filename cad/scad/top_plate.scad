// =========================================================
// BRAILLE CELL TOP PLATE — v3.0
// Updated 2026-05-06
//
// Changes from v2.1 (Full Audit Redesign):
//   - plate_size 34x34mm -> plate_length=52mm x plate_width=60mm (rectangular)
//     Now fully covers outer_box internal cavity (52x60mm). No gaps. (Audit 3.2)
//   - Rectangular 1.2x3mm slots -> round 2mm holes (Audit Fix 5)
//     Round holes prevent dust funnelling into cam mechanism
//     Holes sized for braille_cap pin shaft (1.9mm dia + 0.1mm clearance)
//   - Spring pockets RE-INTRODUCED on underside (Audit 4.2)
//     3.5mm dia x 3mm deep concentric pockets around each braille hole
//     Retains 3mm compression springs that push linkages DOWN (gravity alone
//     is insufficient for 1mm sheet metal in tight slots)
//   - plate_thickness 3mm -> 4mm (need 3mm pocket + 1mm floor above)
//   - Slots replaced by round holes — slot chamfers removed
//   - Thumb ridge kept for blind user orientation
// =========================================================

// =========================================================
// v7.1 (2026-07-26) — RETURN SPRING IS COAXIAL WITH EACH DOT
//
// History, so nobody re-treads it:
//   pre-v7  4.5mm pockets concentric with each dot. Never worked — braille
//           rows are 2.6mm apart, so the three pockets in a column merged
//           into one slot. There were never six pockets, only two blobs.
//   v7.0    moved the spring OFF the dot onto a pad mid-arm. Geometrically
//           fine, but physically wrong: the return force belongs on the dot.
//   v7.1    back on the dot axis, and made to actually fit by shrinking the
//           spring to a 2mm OD micro spring and the nub to 1.0mm. The dot
//           drops to 1.5mm, which is the REAL braille standard (1.44-1.6mm).
//
// The spring sits in a counterbore here in the plate underside, wraps around
// the dot, and pushes down on a flange on the linkage's upper riser. The dot
// travels up and down through the middle of it.
// =========================================================

include <mech_layout.scad>   // dot positions, arm geometry, spring seat positions

// --- 1. PARAMETERS ---

// Braille dot positions and arm geometry now come from mech_layout.scad
// (col_spacing, row_spacing, dot_pos(), spring_seat_pos()).

// Braille dot holes and spring counterbores both come from mech_layout.scad
hole_dia            = plate_hole_dia;        // 1.7mm — passes the 1.5mm dome
spring_pocket_dia   = spring_od + 0.2;       // 2.2mm — 2mm spring + clearance
spring_pocket_depth = spring_recess_depth;   // 2.5mm into the 4mm plate

// Plate body — v6.2: now an OVER-CAP covering the full box footprint (was an inset plate).
// Underside at z=0, top at z=4. X flush with box outer (no overhang on ±X dock faces);
// Y 1mm overhang each side with a downward skirt (front/back only).
plate_length    = 68.0;   // X — flush with box outer (±34), NO overhang (dock faces)
plate_width     = 70.0;   // Y — 1mm overhang each side (±35) front/back
plate_thickness = 4.0;    // Z — cap thickness (3mm spring pocket + 1mm floor)
corner_radius   = 3.0;    // matches box outer fillet
finger_pad_depth = 0.8;   // Shallow recess on top face

// Over-cap skirt — ±Y faces only (front/back); hangs from z=0 down to z=-4.
// Outer flush with cap edge (y=±35); inner face y=±34.4 → 0.4mm clearance off the
// box wall outer (±34). MUST NOT appear on the ±X dock faces.
skirt_depth      = 4.0;
skirt_y_outer    = 35.0;
skirt_y_inner    = 34.4;
skirt_x_half     = 30.0;  // skirt spans x within ±30 (stays clear of the rounded corners)

// Mounting — 4 corner holes at ±26,±21 matching base_plate standoffs
standoff_x       = 26.0;
standoff_y       = 21.0;
screw_dia        = 3.2;   // v6.2: 2.8→3.2 M2.5 clearance for print tolerance
counterbore_dia  = 5.6;   // v6.2: 5.0→5.6 M2.5 button-head
counterbore_depth = 1.5;

$fn = 60;

// --- 2. MODULES ---

module rounded_rect(lx, ly, r, h) {
    hull() {
        translate([-lx/2 + r, -ly/2 + r, 0]) cylinder(r=r, h=h);
        translate([ lx/2 - r, -ly/2 + r, 0]) cylinder(r=r, h=h);
        translate([-lx/2 + r,  ly/2 - r, 0]) cylinder(r=r, h=h);
        translate([ lx/2 - r,  ly/2 - r, 0]) cylinder(r=r, h=h);
    }
}

// Downward skirt on the ±Y (front/back) faces only — locates the cap over the box
// wall. Two cuboid lips, outer flush y=±35, inner y=±34.4 (0.4mm clearance), spanning
// x within ±30 (clear of corners and the ±X dock faces). Hangs z=0 down to z=-4.
module yy_skirt() {
    for(sy = [-1, 1]) {
        // y-span runs from inner (±34.4) to outer (±35) edge
        y_lo = (sy < 0) ? -skirt_y_outer : skirt_y_inner;
        translate([-skirt_x_half, y_lo, -skirt_depth])
            cube([2 * skirt_x_half, skirt_y_outer - skirt_y_inner, skirt_depth]);
    }
}

// 6 braille dot through-holes — the printed dome on each linkage nub
// rises through these. Positions from the shared layout file.
module braille_holes() {
    for (d = [1 : 6]) {
        p = dot_pos(d);
        translate([p[0], p[1], -1])
            cylinder(d = hole_dia, h = plate_thickness + 2);
    }
}

// 6 return-spring counterbores on the underside, COAXIAL with each dot hole.
// The 2mm spring drops in here and is glued; the dot travels up and down
// through the middle of it, and it pushes down on the flange on the linkage's
// upper riser.
//
// NOTE ON WALL THICKNESS: braille rows are 2.6mm apart and this bore is
// 2.2mm, so only 0.4mm of plate is left between the three bores in a column.
// That is thin but printable in resin, and it is the direct consequence of
// putting a spring on the dot axis at braille pitch — there is no way to have
// both. If it proves too fragile in practice, let the three merge into one
// slot per column: the spring is glued, so the bore only has to clear it.
module spring_pockets() {
    for (d = [1 : 6]) {
        p = dot_pos(d);
        translate([p[0], p[1], -0.01])
            cylinder(d = spring_pocket_dia, h = spring_pocket_depth + 0.01);
    }
}

module mounting_holes() {
    for(sx = [-1,1]) for(sy = [-1,1]) {
        translate([sx * standoff_x, sy * standoff_y, 0]) {
            // Through hole
            translate([0, 0, -1])
                cylinder(d=screw_dia, h=plate_thickness + 5);
            // Counterbore on top face
            translate([0, 0, plate_thickness - counterbore_depth])
                cylinder(d=counterbore_dia, h=counterbore_depth + 1);
        }
    }
}

// --- 3. MAIN ASSEMBLY ---

difference() {
    union() {
        // A. Over-cap body — full box footprint (68×70), underside z=0, top z=4
        rounded_rect(plate_length, plate_width, corner_radius, plate_thickness);
        // A2. Downward skirt on ±Y faces only
        yy_skirt();
    }

    // B. Finger pad recess (ergonomic boundary on top face)
    translate([0, 0, plate_thickness - finger_pad_depth])
        rounded_rect(plate_length - 6, plate_width - 6, corner_radius, finger_pad_depth + 1);

    // C. 6 braille dot holes + 6 coaxial spring counterbores
    braille_holes();
    spring_pockets();

    // D. Mounting holes (4 corners, M2.5)
    mounting_holes();
}

// --- 4. TACTILE FEATURES ---

// Thumb ridge — bottom edge (closest to user's body, audit 5)
// Relocated from left edge: ergonomic resting position for standard orientation
translate([0, -plate_width/2 + 1.5, plate_thickness])
    hull() {
        translate([-4, 0, 0]) sphere(r=0.6, $fn=20);
        translate([ 4, 0, 0]) sphere(r=0.6, $fn=20);
    }

// --- 5. SPRING SPEC (for BOM / sourcing) ---
// OD:  2.0mm micro compression spring, 0.3mm stainless wire (STOCK SIZE)
// Free length: ~4mm (~5 coils; 1.5mm solid height, so it never bottoms out)
// A 4mm ballpoint-pen spring CANNOT be used — it needs ~4.2mm of row pitch
// and braille rows are 2.6mm apart. Buy an assortment kit so several sizes
// are on hand. See docs/SOURCING.md.
// OLD SPEC (do not use): 4.0mm pen spring on a mid-arm pad
// Spring constant: as soft as possible (<= 0.1 N/mm) — the 28BYJ-48 has to
//   compress all six at once, so stiff springs risk stalling the motor
// Travel: pad top sits 3.5mm below the plate underside with the dot DOWN,
//   2.7mm with it UP, so the spring must be shorter than 2.7mm when fully
//   compressed (4 coils of 0.3mm wire = 1.2mm solid — fine)
// Fitting: glue the spring into the plate pocket. The linkage's arm pad then
//   pushes up against it — no threading it over anything, the nub+dome never
//   passes through the spring.

// --- 6. MODULE WRAPPER (used by print_small_parts.scad) ---
module top_plate() {
    difference() {
        union() {
            rounded_rect(plate_length, plate_width, corner_radius, plate_thickness);
            yy_skirt();
        }
        translate([0, 0, plate_thickness - finger_pad_depth])
            rounded_rect(plate_length - 6, plate_width - 6, corner_radius, finger_pad_depth + 1);
        braille_holes();
        spring_pockets();
        mounting_holes();
    }
    // Thumb ridge — bottom edge
    translate([0, -plate_width/2 + 1.5, plate_thickness])
        hull() {
            translate([-4, 0, 0]) sphere(r=0.6, $fn=20);
            translate([ 4, 0, 0]) sphere(r=0.6, $fn=20);
        }
}
