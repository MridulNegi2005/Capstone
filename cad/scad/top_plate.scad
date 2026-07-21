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

// --- 1. PARAMETERS ---

// Braille dot positions (must match linkage.scad, braille_cam.scad)
col_spacing     = 4.8;    // Left col at x=-2.4, right at x=+2.4
row_spacing     = 2.6;    // Rows at y=+2.6, 0, -2.6

// Braille holes — round (replaces 1.2x3mm rectangular slots)
hole_dia        = 2.5;    // Fits 2.2mm linkage nub + 0.15mm/side clearance (was 2.0 for cap pin)

// Spring pockets — on underside, concentric around each braille hole
// Audit 2 fix: wider pocket, shallower depth for stronger annular wall
spring_pocket_dia   = 4.5;   // was 3.5 — wider for 2.5mm hole clearance (wall=1.0mm)
spring_pocket_depth = 2.0;   // was 3.0 — shallower: 4mm plate - 2mm pocket = 2mm floor

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

// One braille hole with spring pocket underneath
module braille_hole_with_spring(cx, cy) {
    // Round through hole — fits 2.2mm linkage nub with 0.15mm/side clearance
    translate([cx, cy, -1])
        cylinder(d=hole_dia, h=plate_thickness + 2);

    // Spring retaining pocket — from underside (z=0) upward
    translate([cx, cy, -0.01])
        cylinder(d=spring_pocket_dia, h=spring_pocket_depth + 0.01);
}

module braille_holes() {
    // 6 Braille dot positions: 2 columns x 3 rows
    // Left column: dots 0 (top), 1 (mid), 2 (bot)
    braille_hole_with_spring(-col_spacing/2,  row_spacing);
    braille_hole_with_spring(-col_spacing/2,  0);
    braille_hole_with_spring(-col_spacing/2, -row_spacing);
    // Right column: dots 3 (top), 4 (mid), 5 (bot)
    braille_hole_with_spring( col_spacing/2,  row_spacing);
    braille_hole_with_spring( col_spacing/2,  0);
    braille_hole_with_spring( col_spacing/2, -row_spacing);
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

    // C. 6 round braille holes + spring pockets on underside
    braille_holes();

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
// OD:  4.0-4.5mm (fits 4.5mm pocket)
// ID:  >= 2.5mm (clears 2.2mm linkage nub — was 2.0mm for cap pin)
// Free length: 5-6mm
// Spring constant: <= 0.1 N/mm (lowest available — avoid motor stall)
// Source: 4mm x 5mm or 4.5mm x 6mm micro compression spring
// NOTE: Spring now pushes directly on metal linkage nub (braille_cap deprecated)

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
        mounting_holes();
    }
    // Thumb ridge — bottom edge
    translate([0, -plate_width/2 + 1.5, plate_thickness])
        hull() {
            translate([-4, 0, 0]) sphere(r=0.6, $fn=20);
            translate([ 4, 0, 0]) sphere(r=0.6, $fn=20);
        }
}
