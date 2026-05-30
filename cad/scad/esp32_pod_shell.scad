// =========================================================
// COMPONENT: ESP32 BRAIN POD — Shell Body
// Revision 3.0 — Matching Brick + Horizontal Socket Mount
// Updated 2026-05-31
//
// PRINTABLE PART 1 of 2. Pair with esp32_pod_lid.scad.
//
// Pod is now 64×68×58mm — docking face (68×58) matches the cell
// so the chain looks like a uniform row of bricks.
//
// ESP32 DevKit V1 mounts horizontally on two 1×15 female header
// strips seated in floor channels. Plug-and-play, no soldering.
//
// Print orientation: upright (open top facing up).
// Material: PETG.
// =========================================================

include <esp32_pod_params.scad>

shell_h = pod_height - lid_h;

// --- CUTOUT MODULES ---

module shell_internal_cavity() {
    translate([0, 0, pod_floor])
        pod_rounded_box(pod_int_length, pod_int_width, shell_h, pod_fillet - 1);
}

module usb_cutout() {
    translate([-pod_length/2 - 1, -usb_w/2, usb_z])
        cube([pod_wall + 2, usb_w, usb_h]);
}

module nav_button_holes() {
    for(nx = nav_x_positions) {
        translate([nx, -pod_width/2 - 1, nav_z])
            rotate([-90, 0, 0])
            cylinder(d=nav_hole_dia, h=pod_wall + 2, $fn=30);
    }
}

module pogo_pad_recess_cutout() {
    translate([pod_length/2 - pogo_pad_recess, -pogo_pad_w/2,
               pogo_z_from_bot - pogo_pad_h/2])
        cube([pogo_pad_recess + 1, pogo_pad_w, pogo_pad_h]);
}

module magnet_pockets() {
    // Cell -X face = N/S/N; pod +X face = S/N/S → attract when docked
    for(my = mag_y_positions) {
        translate([pod_length/2 - mag_depth + 0.01, my, mag_z])
        rotate([0, 90, 0])
            cylinder(d=mag_dia, h=mag_depth + 1, $fn=30);
    }
}

module antenna_grille() {
    for(i = [0 : antenna_slot_count - 1]) {
        y_pos = -((antenna_slot_count - 1) * (antenna_slot_w + 2)) / 2
                + i * (antenna_slot_w + 2);
        translate([pod_length/2 - pod_wall - 1,
                   y_pos - antenna_slot_w/2,
                   shell_h/2 - antenna_slot_h/2])
            cube([pod_wall - antenna_wall + 1, antenna_slot_w, antenna_slot_h]);
    }
}

// --- INTERIOR FEATURE MODULES ---

module header_socket_channels() {
    // Two parallel floor channels to locate 1×15 female header strips
    // Strips sit in recesses; DevKit male pins plug down into them
    for(sy = [-1, 1]) {
        translate([devkit_x_offset, sy * hdr_row_pitch/2, 0]) {
            // Floor recess to locate strip
            translate([-hdr_strip_len/2, -hdr_strip_w/2, pod_floor - hdr_channel_depth])
                cube([hdr_strip_len, hdr_strip_w, hdr_channel_depth + 0.1]);
            // Retention walls (printed around strip, 1mm tall bumps at ends)
            // These are positive features added in the union, not cuts
        }
    }
}

module header_retention_walls() {
    // Small bumps at each end of the header channels to keep strips from sliding
    wall_h = 3;
    wall_t = 1.5;
    for(sy = [-1, 1]) {
        for(sx = [-1, 1]) {
            translate([devkit_x_offset + sx * (hdr_strip_len/2 + wall_t/2),
                       sy * hdr_row_pitch/2,
                       pod_floor])
                cube([wall_t, hdr_strip_w + 1, wall_h], center=true);
        }
    }
}

module switch_pockets() {
    // 3× snap-in pockets for 6×6×5mm tactile switches behind nav button holes
    for(nx = nav_x_positions) {
        translate([nx, -pod_width/2 + pod_wall, nav_z]) {
            rotate([-90, 0, 0]) {
                // Main pocket cavity
                translate([-sw_body/2, -sw_body/2, -0.01])
                    cube([sw_body, sw_body, sw_depth]);
            }
        }
    }
}

module switch_snap_nibs() {
    // Small retention nibs at pocket edges to hold switches in place
    for(nx = nav_x_positions) {
        for(sy = [-1, 1]) {
            translate([nx, -pod_width/2 + pod_wall + sw_depth - 0.5,
                       nav_z + sy * (sw_body/2)])
                cube([2, 0.8, sw_snap_nib], center=true);
        }
    }
}

module wire_tie_post() {
    translate([pod_length/2 - pod_wall - 8, pod_int_width/2 - 4, pod_floor]) {
        difference() {
            cylinder(d=tie_post_dia, h=tie_post_h, $fn=30);
            translate([-tie_post_dia/2 - 1, -tie_post_hole/2,
                       tie_post_h/2 - tie_post_hole/2])
                cube([tie_post_dia + 2, tie_post_hole, tie_post_hole]);
        }
    }
}

module lid_locating_lip() {
    translate([0, 0, shell_h])
        difference() {
            pod_rounded_box(pod_int_length + 2 * 1.0,
                            pod_int_width  + 2 * 1.0, 1.0, pod_fillet - 1);
            translate([0, 0, -0.01])
                pod_rounded_box(pod_int_length - 0.4,
                                pod_int_width  - 0.4, 1.1, pod_fillet - 1.5);
        }
}

module lid_screw_bosses() {
    // 2× bosses on shell top rim for M2 lid screws (F14 fix)
    for(sx = [-1, 1]) {
        translate([sx * lid_screw_x, 0, shell_h - 8])
            difference() {
                cylinder(d=lid_boss_d, h=8, $fn=30);
                translate([0, 0, -1])
                    cylinder(d=lid_boss_tap, h=10, $fn=20);
            }
    }
}

// --- MAIN SHELL MODULE ---

module esp32_pod_shell() {
    union() {
        difference() {
            pod_rounded_box(pod_length, pod_width, shell_h, pod_fillet);

            shell_internal_cavity();
            usb_cutout();
            nav_button_holes();
            pogo_pad_recess_cutout();
            magnet_pockets();
            antenna_grille();
            header_socket_channels();
            switch_pockets();
        }

        // Positive interior features
        header_retention_walls();
        switch_snap_nibs();
        wire_tie_post();
        lid_locating_lip();
        lid_screw_bosses();
    }
}

// --- RENDER ---
esp32_pod_shell();
