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
base_plate_z      = 41;    // 4(floor) + 16(elec) + 2(midplate) + 19(motor)
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
    translate([px - post_w/2, py - post_w/2, pz - 0.1]) {
        cube([post_w, post_w, post_h + 0.1]);
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

module pogo_window_bridges() {
    // Sacrificial bridge across the TOP of each ±X pogo slot for clean PETG printing of
    // the overhang. SNAP/CUT OUT after printing. (Not needed on resin.)
    // v6.1: 0.4→0.6mm (3 layers @ 0.2) — a single layer adheres poorly on the Kobra Neo.
    // Pogo slot = cube([6,10,8]) centered at (±34, 0, 31) → top face at z=35.
    for(sx = [-1, 1])
        translate([sx * shell_length/2, 0, 35 - 0.3])
            cube([6, 10, 0.6], center=true);
}

module wire_exit_bridge() {
    // v7.4: the +Y wire-exit hole is 15mm wide and its top edge was a completely
    // unsupported horizontal span — the ONLY hole in this part without a bridge.
    // On the first real print this is exactly the sort of overhang that either sags
    // into the opening or forces the slicer to generate interior support that then
    // cannot be reached with pliers.
    // Hole = cube([15, wall+2, 6]) centred at (0, shell_width/2, floor+3),
    // so its top face is at z = floor_thickness + 3 + 3 = 10.
    translate([0, shell_width/2, 10 - 0.3])
        cube([15, wall_thickness + 2, 0.6], center=true);
}

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

module vertical_wire_guides() {
    // Thin ribs on ±X inner walls channelling pogo wires from z31 down to pocket
    guide_w = 1.5;
    guide_depth = 2;
    for(sx = [-1, 1]) {
        translate([sx * (internal_length/2 - guide_depth/2), 0, floor_thickness - 0.1])
            cube([guide_depth, guide_w, 31 - floor_thickness + 0.1], center=false);
    }
}

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

    // Sacrificial bridges over every wall opening (PETG print aid).
    // SNAP/CUT THESE OUT after printing — they are meant to be removed.
    pogo_window_bridges();
    wire_exit_bridge();

    // Muscle board mounting bosses
    muscle_board_bosses();

    // Wire hooks (motor wire bundle + pogo bundles)
    cable_hook(-14, -20, floor_thickness);
    cable_hook(-14,  20, floor_thickness);
    cable_hook( 14, -20, floor_thickness);
    cable_hook( 14,  20, floor_thickness);

    // Vertical wire guides on ±X inner walls
    vertical_wire_guides();

    // Bottom-edge orientation ridge — v6.1 rebuilt.
    // The old r=0.8 sphere hull sat at y=-32.5, INSIDE the 4mm wall — it never
    // appeared on the print at all. New: 45°-diamond ridge ON the outer front face,
    // ~1.4mm proud × 20mm long. Self-supporting on a vertical wall (both faces 45°).
    translate([0, -shell_width/2, 5])
        rotate([45, 0, 0])
        cube([20, 2, 2], center=true);
}