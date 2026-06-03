// =========================================================
// COMPONENT: ESP32 BRAIN POD — Top Lid
// Revision 3.0 — Matching Brick
// Updated 2026-05-31
//
// PRINTABLE PART 2 of 2. Pair with esp32_pod_shell.scad.
//
// Lid screws into shell bosses at x=±25 (F14 fix).
// Barrel jack hole on the lid near -X end.
//
// Print orientation: flat (face down).
// Material: PETG.
// =========================================================

include <esp32_pod_params.scad>

shell_h = pod_height - lid_h;

// --- MODULES ---

module barrel_jack_cutout() {
    translate([barrel_jack_x, 0, -1])
        cylinder(d=barrel_jack_dia, h=lid_h + 2);
}

module lid_inner_recess() {
    translate([0, 0, -0.01])
        pod_rounded_box(pod_int_length + 2 * 1.0 + 0.4,
                        pod_int_width  + 2 * 1.0 + 0.4, 1.2, pod_fillet - 1);
}

module lid_screw_holes() {
    // 2× M2 clearance holes — align with shell bosses at x=±25
    for(sx = [-1, 1]) {
        translate([sx * lid_screw_x, 0, -1])
            cylinder(d=lid_screw_d, h=lid_h + 2);
    }
}

// --- RAISED TACTILE FEATURES (v6.0) ---

module pod_id_marker() {
    // Raised braille ⠿ (all 6 dots) on the lid top so a blind user can tell the BRAIN POD apart
    // from the identical-looking cells by touch. Standard 2.5mm braille pitch, dome-topped dots.
    id_col = 2.5; id_row = 2.5;
    for(cx = [-id_col/2, id_col/2])
        for(cy = [id_row, 0, -id_row])
            translate([cx, cy, lid_h - 0.01])
                hull() {
                    cylinder(d=1.6, h=0.2, $fn=20);
                    translate([0, 0, 0.7]) sphere(d=1.4, $fn=20);
                }
}

module jack_guard_ring() {
    // Raised ring around the barrel jack so a finger finds the power inlet without probing the
    // live contact. Auto-trimmed to the lid footprint (the jack is near the edge → partial arc).
    intersection() {
        translate([barrel_jack_x, 0, lid_h - 0.01])
            difference() {
                cylinder(d=barrel_jack_dia + 5, h=1.4, $fn=40);
                translate([0, 0, -1]) cylinder(d=barrel_jack_dia + 0.6, h=3.4, $fn=40);
            }
        translate([0, 0, lid_h - 0.02])
            pod_rounded_box(pod_length, pod_width, 2, pod_fillet);
    }
}

// --- MAIN LID MODULE ---

module esp32_pod_lid() {
    union() {
        difference() {
            pod_rounded_box(pod_length, pod_width, lid_h, pod_fillet);
            barrel_jack_cutout();
            lid_inner_recess();
            lid_screw_holes();
        }
        pod_id_marker();
        jack_guard_ring();
    }
}

// --- RENDER ---
esp32_pod_lid();
