// outer_box_v4.scad
shell_length      = 68;
shell_width       = 68;
shell_height      = 57;
wall_thickness    = 4;
floor_thickness   = 4;
internal_length   = 60;
internal_width    = 60;
elec_pocket_h     = 16;
base_plate_z      = 41; // 4(floor) + 16(elec) + 2(midplate) + 19(motor)
boss_height       = 37; // base_plate_z - floor_thickness

// Magnetic snap — NeFeB disc press-fit pockets (audit 6.3)
// Both ±X walls: 3 pockets each at y=-12, 0, +12 centred vertically
// Alternating polarity (N/S/N on tongue, S/N/S on slot) — snap together, repel backwards
mag_dia           = 3.2;   // press-fit for 3mm NeFeB disc
mag_depth         = 2.1;   // 2mm disc + 0.1mm
mag_z             = shell_height / 2;  // 28.5mm — vertically centred on wall face
mag_y_pos         = [-12, 0, 12];      // same ±12,0 spacing as esp32_pod

$fn = 60;

module rounded_box(l, w, h, r) {
    hull() {
        translate([-l/2 + r, -w/2 + r, 0]) cylinder(r=r, h=h);
        translate([ l/2 - r, -w/2 + r, 0]) cylinder(r=r, h=h);
        translate([-l/2 + r,  w/2 - r, 0]) cylinder(r=r, h=h);
        translate([ l/2 - r,  w/2 - r, 0]) cylinder(r=r, h=h);
    }
}

union() {
    difference() {
        // Main Shell
        rounded_box(shell_length, shell_width, shell_height, 2.0);

        // Internal Cavity
        translate([0, 0, floor_thickness])
            rounded_box(internal_length, internal_width, shell_height, 1.0);

        // 16mm Deep Electronics Pocket
        translate([0, 0, floor_thickness + elec_pocket_h/2])
            cube([36, 46, elec_pocket_h + 1], center=true);
            
        // Wire exit back wall
        translate([0, shell_width/2, floor_thickness + 3])
            cube([15, wall_thickness + 2, 6], center=true);
            
        // Pogo slots — ±X walls, centred at pogo_z=30.5mm
        translate([-shell_length/2, 0, 30.5]) cube([6, 10, 8], center=true);
        translate([ shell_length/2, 0, 30.5]) cube([6, 10, 8], center=true);

        // Magnet pockets — 3× per wall on ±X faces (blind holes, depth=2.1mm into 4mm wall)
        // Left wall (-X): docking face — N/S/N polarity
        for(my = mag_y_pos) {
            translate([-shell_length/2 - 0.01, my, mag_z])
                rotate([0, 90, 0])
                cylinder(d=mag_dia, h=mag_depth + 0.01, $fn=30);
        }
        // Right wall (+X): docking face — S/N/S polarity (attracts, repels reverse)
        for(my = mag_y_pos) {
            translate([shell_length/2 + 0.01, my, mag_z])
                rotate([0, -90, 0])
                cylinder(d=mag_dia, h=mag_depth + 0.01, $fn=30);
        }

        // Braille letter 'F' (Front) embossed into front wall (audit 5)
        // Dots 1, 2 (left col top+mid), Dot 4 (right col top)
        // Front wall: Y = -shell_width/2.  Positioned near top-centre for easy reach.
        translate([0, -shell_width/2, shell_height - 15]) {
            rotate([90, 0, 0]) {
                translate([-2.4,  2.6, 0]) cylinder(d=1.5, h=2, center=true, $fn=20); // Dot 1
                translate([-2.4,  0.0, 0]) cylinder(d=1.5, h=2, center=true, $fn=20); // Dot 2
                translate([ 2.4,  2.6, 0]) cylinder(d=1.5, h=2, center=true, $fn=20); // Dot 4
            }
        }
    }

    // NEW: 2mm Ledge at Z=20 for the Mid-Plate to rest on!
    translate([0, 0, floor_thickness + elec_pocket_h]) difference() {
        rounded_box(internal_length, internal_width, 2, 1.0);
        translate([0,0,-1]) rounded_box(internal_length - 4, internal_width - 4, 4, 1.0);
    }

    // Corner Bosses (Go from floor through mid-plate to top)
    for(sx = [-1, 1]) for(sy = [-1, 1]) {
        translate([sx * 15, sy * 15, floor_thickness]) difference() {
            cylinder(d=8, h=boss_height);
            translate([0, 0, 3]) cylinder(d=3.2, h=boss_height);
        }
    }
}