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

// --- MAIN LID MODULE ---

module esp32_pod_lid() {
    difference() {
        pod_rounded_box(pod_length, pod_width, lid_h, pod_fillet);
        barrel_jack_cutout();
        lid_inner_recess();
        lid_screw_holes();
    }
}

// --- RENDER ---
esp32_pod_lid();
