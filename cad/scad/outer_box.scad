// outer_box v5.0 — Pre-print audit fixes + wire management
shell_length      = 68;
shell_width       = 68;
shell_height      = 58;
wall_thickness    = 4;
floor_thickness   = 4;
internal_length   = 60;
internal_width    = 60;
elec_pocket_h     = 16;
base_plate_z      = 41;    // 4(floor) + 16(elec) + 2(midplate) + 19(motor)
boss_height       = 37;    // boss top = z41 = base_plate bottom

// Magnetic snap — NeFeB disc press-fit pockets
// -X face: N/S/N polarity; +X face: S/N/S → attract when docked
mag_dia           = 3.2;
mag_depth         = 2.1;
mag_z             = shell_height / 2;
mag_y_pos         = [-12, 0, 12];

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
    // Channels along pocket floor edges — extend 0.1 below floor to avoid coplanar
    gutter_w = 4;
    gutter_d = 2;
    translate([-18, -20, floor_thickness - 0.1])
        cube([gutter_w, 40, gutter_d + 0.1]);
    translate([18 - gutter_w, -20, floor_thickness - 0.1])
        cube([gutter_w, 40, gutter_d + 0.1]);
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
        // Main Shell
        rounded_box(shell_length, shell_width, shell_height, 3.0);

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

        // Magnet pockets — -X face N/S/N, +X face S/N/S
        for(my = mag_y_pos) {
            translate([-shell_length/2 - 0.01, my, mag_z])
                rotate([0, 90, 0])
                cylinder(d=mag_dia, h=mag_depth + 0.01, $fn=30);
        }
        for(my = mag_y_pos) {
            translate([shell_length/2 + 0.01, my, mag_z])
                rotate([0, -90, 0])
                cylinder(d=mag_dia, h=mag_depth + 0.01, $fn=30);
        }

        // Braille letter 'F' (Front) embossed into front wall
        translate([0, -shell_width/2, shell_height - 15]) {
            rotate([90, 0, 0]) {
                translate([-2.4,  2.6, 0]) cylinder(d=1.5, h=2, center=true, $fn=20);
                translate([-2.4,  0.0, 0]) cylinder(d=1.5, h=2, center=true, $fn=20);
                translate([ 2.4,  2.6, 0]) cylinder(d=1.5, h=2, center=true, $fn=20);
            }
        }
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
    for(sx = [-1, 1]) for(sy = [-1, 1]) {
        translate([sx * 26, sy * 21, floor_thickness - 0.1]) difference() {
            cylinder(d=7.8, h=boss_height + 0.1);
            translate([0, 0, 3]) cylinder(d=2.1, h=boss_height + 0.1);
        }
    }

    // Muscle board mounting bosses
    muscle_board_bosses();

    // Wire hooks (motor wire bundle + pogo bundles)
    cable_hook(-14, -20, floor_thickness);
    cable_hook(-14,  20, floor_thickness);
    cable_hook( 14, -20, floor_thickness);
    cable_hook( 14,  20, floor_thickness);

    // Vertical wire guides on ±X inner walls
    vertical_wire_guides();

    // Bottom-edge orientation ridge
    translate([0, -shell_width/2 + 1.5, 2])
        hull() {
            translate([-10, 0, 0]) sphere(r=0.8, $fn=20);
            translate([ 10, 0, 0]) sphere(r=0.8, $fn=20);
        }
}