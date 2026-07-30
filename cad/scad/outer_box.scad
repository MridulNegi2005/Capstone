// outer_box v6.1 — Physical-reality fixes after PETG fit-test (Kobra Neo, 0.4mm nozzle)
shell_length      = 68;
shell_width       = 68;
shell_height      = 58;
// v6.2: total height stays 58 = 54mm walls + 4mm over-cap (top_plate) sitting on top.
// Only the OUTER shell extrusion is shortened to wall_top_h; every other feature
// (mag_z, chevron at shell_height-22, ledge, bosses, cavity) still references
// shell_height so nothing moves.
cap_recess        = 4;
wall_top_h        = shell_height - cap_recess;   // 54
wall_thickness    = 4;
floor_thickness   = 4;
internal_length   = 60;
internal_width    = 60;
elec_pocket_h     = 16;
// >>> BLOCKED ON MEASUREMENT (M2) — see docs/MEASUREMENTS_NEEDED.md <<<
// The "19" here is the 28BYJ-48 can height taken from a datasheet, never measured.
// It sets how high the base plate sits, which sets the cam height, which sets the
// linkage length. If the real motor is taller or shorter than 19mm, EVERY dot ends
// up proud or sunken by that difference. Nothing downstream is trustworthy until
// this is a measured number. Re-derive cam_flat_z in mech_layout.scad at the same time.
base_plate_z      = 41;    // 4(floor) + 16(elec) + 2(midplate) + 19(motor, ASSUMED)
boss_height       = 37;    // boss top = z41 = base_plate bottom

// Magnetic snap — NeFeB disc glue-in pockets
// v6.1: real magnets measured 8mm dia × 1mm thick (CAD previously assumed 3×2).
// 2 per face at y=±14 — the center magnet was dropped because an 8.4mm pocket at
// y=0 would collide with the pogo window. Teardrop tops so the horizontal pockets
// print without fusing closed (the 3.2mm round ones fused on the fit-test).
// -X face: N/S polarity; +X face: S/N → attract when docked
mag_dia           = 8.4;   // 8mm magnet + 0.4mm FDM clearance
mag_depth         = 1.2;   // 1mm magnet + glue gap (4mm wall keeps 2.8mm behind)
mag_z             = shell_height / 2;
mag_y_pos         = [-14, 14];

// Pogo carrier pocket params (behind each ±X window)
pogo_carrier_w    = 12;    // carrier board width (measure real part!)
pogo_carrier_h    = 10;    // carrier board height
pogo_carrier_d    = 2;     // pocket depth into wall interior
pogo_carrier_lip  = 0.5;   // retention lip overhang

// Muscle board mounting (34×44mm board in 36×46mm pocket)
//
// v7.5: DISABLED BY DEFAULT. The pocket was being designed for two different boards
// at once, and only one of them can physically be in there. What actually goes in
// now — for the demo AND for the first assembled cell — is the off-the-shelf
// ULN2003 module. That board is ~35x32mm, so these Ø4 bosses at x=±14 fall INSIDE
// its footprint: the board would sit on top of them, 4mm up, in a 16mm pocket that
// already needs ~12mm for the board itself. Zero margin, for a PCB that does not
// exist and that the docs say to order assembled or not build at all.
// Flip this to true if the muscle board is ever actually made.
use_muscle_board_bosses = false;
// Mounting-hole coords from KiCad (MEASURE from kicad_pcb; placeholder ±14,±19)
mb_boss_positions = [[-14, -19], [-14, 19], [14, -19], [14, 19]];
mb_boss_d         = 4;
mb_boss_h         = 4;     // board sits 4mm above pocket floor (floor_thickness=4)
mb_boss_tap       = 1.7;   // M2 self-tap pilot

// Wire hook params
wire_hook_h       = 4.0;   // hook height (along Z)

$fn = 60;

module rounded_box(l, w, h, r) {
    hull() {
        translate([-l/2 + r, -w/2 + r, 0]) cylinder(r=r, h=h);
        translate([ l/2 - r, -w/2 + r, 0]) cylinder(r=r, h=h);
        translate([-l/2 + r,  w/2 - r, 0]) cylinder(r=r, h=h);
        translate([ l/2 - r,  w/2 - r, 0]) cylinder(r=r, h=h);
    }
}

// --- WIRE MANAGEMENT MODULES ---

module pogo_carrier_pocket(side_x) {
    // Captured recess behind pogo window — extends 0.1mm past cavity wall to avoid coplanar
    offset_x = (side_x < 0) ? side_x + pogo_carrier_d/2 + 0.1 : side_x - pogo_carrier_d/2 - 0.1;
    translate([offset_x, -pogo_carrier_w/2, 31 - pogo_carrier_h/2])
        cube([pogo_carrier_d + 0.2, pogo_carrier_w, pogo_carrier_h]);
}

module cable_hook(px, py, pz) {
    // Wire hook — L-shaped post with overhang to trap wire bundle
    post_w = 2;
    post_h = wire_hook_h;
    hook_overhang = 1.5;
    // v7.4: sink 0.4mm INTO the pocket floor. The hooks sit inside the electronics
    // pocket, whose cut removes the floor from z=3.9 up — so a hook starting at exactly
    // 3.9 only TOUCHED the floor and never merged, leaving 4 separate bodies in the STL.
    // Slicers usually cope, but a coplanar touch is fragile; a real overlap is not.
    translate([px - post_w/2, py - post_w/2, pz - 0.4]) {
        cube([post_w, post_w, post_h + 0.4]);
        translate([0, 0, post_h - 1])
            cube([post_w, post_w + hook_overhang, 1]);
    }
}

module floor_wire_gutters() {
    // Channels along pocket floor edges (v6.0: widened 4→7mm for real Dupont/JST bundles)
    // extend 0.1 below floor to avoid coplanar
    gutter_w = 7;
    gutter_d = 2.5;
    translate([-18, -20, floor_thickness - 0.1])
        cube([gutter_w, 40, gutter_d + 0.1]);
    translate([18 - gutter_w, -20, floor_thickness - 0.1])
        cube([gutter_w, 40, gutter_d + 0.1]);
}

// --- SACRIFICIAL BRIDGES REMOVED (v7.4, 2026-07-30) ---
// v6.0 through v7.3 modelled thin 0.6mm "sacrificial bridge" layers across the pogo
// windows and the wire-exit hole. They have been REMOVED deliberately. Do not add
// them back.
//
// Reason: every opening in this part is a 10-15mm span, and a well-cooled FDM printer
// bridges 20-30mm unsupported. The slicer spans these on its own, with no supports and
// no help from the CAD. The bridges were redundant, they made the STL not represent the
// finished part, and they carried a real failure mode: if they were not snapped out, the
// pogo pins and wires could not pass through. A slightly sagged hole edge is cosmetic;
// a blocked hole is a functional failure.
//
// KEPT, and do NOT remove: teardrop_magnet_pocket(). That is shape-based self-support
// (a 45 degree peak instead of a round top), which needs no post-processing and is the
// correct way to solve an overhang in CAD.

module teardrop_magnet_pocket() {
    // Horizontal-axis magnet pocket with a 45° "roof" — round side-wall holes fused
    // closed on the fit-test print; the teardrop top is self-supporting on FDM.
    // Drawn with axis along +Z, mouth at z=0; caller rotates it into the wall.
    r = mag_dia / 2;
    linear_extrude(mag_depth + 0.01) union() {
        circle(r=r, $fn=40);
        polygon([[-r * sin(45), r * cos(45)],
                 [0, r * sqrt(2)],
                 [ r * sin(45), r * cos(45)]]);
    }
}

// --- vertical_wire_guides() DELETED IN v7.6. DO NOT ADD IT BACK. ---
// It was a single flat blade, 2 x 1.5mm in section and 27mm tall, standing off
// each ±X inner wall. It was called a "wire guide", but a lone blade cannot guide
// anything: retaining a wire needs it captured on more than one side — a channel
// (two walls), a hook (an overhang), or a tie loop. This had none. A wire laid
// against it simply falls away.
//
// Two reasons it went rather than getting fixed:
//   1. 27mm tall at 1.5mm thick is 18:1 slenderness — precisely the geometry that
//      snaps or gets knocked over mid-print. Real parts have already been lost to
//      slender features on this box.
//   2. It aimed to guide wires from the pogo carrier, whose dimensions are all
//      still marked "measure real part!" and whose pogo pins are not even owned.
//      It was managing wires from a component that does not exist.
//
// If pogo wiring ever does need managing, copy cable_hook() below — that is the
// correct pattern, an L with a 1.5mm overhang that actually traps a bundle — and
// size it to the real connector.
//
// NOT the same thing as floor_wire_gutters() above, which is KEPT: those are
// recessed channels cut into the pocket floor, and a recess with two side walls
// and a base genuinely does retain a wire.

module front_chevron_groove() {
    // Bold ^ groove engraved into the front (-Y) wall, apex up = "this side front, this way up".
    // Polygon is a chevron band: bottom edge (-8,0)→(0,8)→(8,0), offset 4.2 vertically.
    // Extruded 1.3mm into the wall (1.2mm groove + 0.1mm past the outer surface).
    translate([0, -shell_width/2 + 1.2, shell_height - 22])
        rotate([90, 0, 0])
        linear_extrude(1.3)
        polygon([[-8, 0], [0, 8], [8, 0], [8, 4.2], [0, 12.2], [-8, 4.2]]);
}

module muscle_board_bosses() {
    // 4× M2 self-tap bosses on pocket floor for the muscle board PCB
    if (use_muscle_board_bosses)
    for(pos = mb_boss_positions) {
        translate([pos[0], pos[1], floor_thickness - 0.1])
            difference() {
                cylinder(d=mb_boss_d, h=mb_boss_h + 0.1, $fn=20);
                translate([0, 0, -1])
                    cylinder(d=mb_boss_tap, h=mb_boss_h + 2, $fn=15);
            }
    }
}

// --- MAIN ASSEMBLY ---

union() {
    difference() {
        // Main Shell — outer extrusion shortened to wall_top_h (54) to seat the
        // 4mm over-cap; cavity/pocket cuts below still use shell_height (harmless air above 54).
        rounded_box(shell_length, shell_width, wall_top_h, 3.0);

        // Internal Cavity
        translate([0, 0, floor_thickness])
            rounded_box(internal_length, internal_width, shell_height, 1.0);

        // 16mm Deep Electronics Pocket (extends 0.1 below floor to avoid coplanar)
        translate([0, 0, floor_thickness - 0.1 + (elec_pocket_h + 0.1)/2])
            cube([36, 46, elec_pocket_h + 0.1], center=true);

        // Floor wire gutters (subtracted from pocket floor)
        floor_wire_gutters();

        // Wire exit back wall
        translate([0, shell_width/2, floor_thickness + 3])
            cube([15, wall_thickness + 2, 6], center=true);

        // Pogo slots — ±X walls at z=31
        translate([-shell_length/2, 0, 31]) cube([6, 10, 8], center=true);
        translate([ shell_length/2, 0, 31]) cube([6, 10, 8], center=true);

        // Pogo carrier pockets behind each window
        pogo_carrier_pocket(-internal_length/2);
        pogo_carrier_pocket( internal_length/2);

        // Magnet pockets — -X face N/S, +X face S/N (teardrop tops, v6.1)
        for(my = mag_y_pos) {
            translate([-shell_length/2 - 0.01, my, mag_z])
                rotate([0, 90, 0])
                teardrop_magnet_pocket();
        }
        for(my = mag_y_pos) {
            translate([shell_length/2 + 0.01, my, mag_z])
                rotate([0, -90, 0])
                teardrop_magnet_pocket();
        }

        // Front tactile marker — bold chevron (^) groove, v6.1.
        // Replaces the braille 'F' (1.5mm dots — FDM-unprintable, came out as mush).
        // Band ~3mm perpendicular width, 1.2mm deep, 16mm wide: unmissable by touch.
        front_chevron_groove();
    }

    // 2mm Ledge at Z=20 for Mid-Plate
    // Outer 0.2mm wider than cavity to extend into walls (avoids CGAL coplanar face)
    // Inner cutout 57×57 to clear Ø8 bosses at (±26,±21)
    translate([0, 0, floor_thickness + elec_pocket_h]) difference() {
        rounded_box(internal_length + 0.2, internal_width + 0.2, 2, 1.0);
        translate([0,0,-1]) rounded_box(internal_length - 3, internal_width - 3, 4, 1.0);
    }

    // Corner Bosses — M2.5 tap pilot for through-bolt
    // Ø7.8 so edge (26+3.9=29.9) doesn't touch cavity wall (x=30)
    // v6.1: pilot 2.1→2.3 (FDM prints holes ~0.2-0.3 undersize; drill if still tight)
    // v6.2: add a base GUSSET CONE under each boss — these Ø7.8 bosses SNAPPED on the
    // real print. Cone widens d=13→7.8 over h=8 (z = floor-0.1 .. floor+7.9), merging
    // into the cavity wall (base r=6.5 at x=26 spans x=19.5..32.5; cavity wall starts
    // at x=30 → the outer flank fuses to the wall = the gusset). Inner flank reaches
    // x=19.5, clearing the 36-wide pocket edge at x=18. Cone stays below the mid-plate
    // ledge (z=20) and base plate (z=41) so it blocks nothing. Pilot drilled through it too.
    for(sx = [-1, 1]) for(sy = [-1, 1]) {
        translate([sx * 26, sy * 21, floor_thickness - 0.1]) difference() {
            union() {
                cylinder(d=7.8, h=boss_height + 0.1);
                cylinder(d1=13, d2=7.8, h=8);   // gusset cone at base
            }
            translate([0, 0, 3]) cylinder(d=2.3, h=boss_height + 0.1);
        }
    }

    // Muscle board mounting bosses
    muscle_board_bosses();

    // Wire hooks (motor wire bundle + pogo bundles)
    cable_hook(-14, -20, floor_thickness);
    cable_hook(-14,  20, floor_thickness);
    cable_hook( 14, -20, floor_thickness);
    cable_hook( 14,  20, floor_thickness);

    // Bottom-edge orientation ridge — v6.1 rebuilt.
    // The old r=0.8 sphere hull sat at y=-32.5, INSIDE the 4mm wall — it never
    // appeared on the print at all. New: 45°-diamond ridge ON the outer front face,
    // ~1.4mm proud × 20mm long. Self-supporting on a vertical wall (both faces 45°).
    translate([0, -shell_width/2, 5])
        rotate([45, 0, 0])
        cube([20, 2, 2], center=true);
}