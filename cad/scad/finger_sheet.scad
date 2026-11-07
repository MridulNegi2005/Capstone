// Printed return-spring sheet. See the finger_* block in mech_layout.scad.
// Built in the assembled frame: the sheet top touches the top-plate underside.
// print_finger_sheet() lays it flat for the printer, ridges up.
include <mech_layout.scad>

ridge_len = 2.6;     // across the beam; the beam is link_thickness wide
ridge_w   = 1.2;     // along the beam
ridge_r   = 0.6;     // rounded contact edge

function tg_a(d) = (dot_pos(d) - foot_pos(d)) / norm(dot_pos(d) - foot_pos(d));

module strip2d(d, back, fwd, w) {
    t = finger_tip(d); u = finger_axis(d); n = [-u[1], u[0]] * w / 2;
    p0 = t - u * back; p1 = t + u * fwd;
    polygon([p0 + n, p1 + n, p1 - n, p0 - n]);
}
module tongue2d(d) strip2d(d, ridge_w, finger_len + 0.5, finger_w);   // root runs 0.5 into the frame
module slot2d(d)   strip2d(d, ridge_w + finger_slot, finger_len, finger_w + 2 * finger_slot);

module frame2d() {
    difference() {
        offset(r = 2) offset(delta = -2) square([base_length, base_width], center = true);
        circle(r = 5.0, $fn = 64);                                    // the dot cluster
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * standoff_x, sy * standoff_y]) circle(d = 2.9, $fn = 32);
        for (d = [1:6]) slot2d(d);
    }
}

module ridge(d) {
    t = finger_tip(d); a = tg_a(d);
    z_top = plate_under_z - finger_t;
    z_bot = beam_top_z - finger_preload;
    translate([t[0], t[1], 0])
        rotate([0, 0, atan2(a[1], a[0])])          // local x = along the beam
            hull() {
                translate([-ridge_w / 2, -ridge_len / 2, z_top - 0.01])
                    cube([ridge_w, ridge_len, 0.02]);
                translate([0, 0, z_bot + ridge_r])
                    rotate([90, 0, 0]) cylinder(r = ridge_r, h = ridge_len, center = true, $fn = 24);
            }
}

module finger_sheet() {
    translate([0, 0, plate_under_z - finger_frame_t])
        linear_extrude(finger_frame_t) frame2d();
    translate([0, 0, plate_under_z - finger_t])
        linear_extrude(finger_t) for (d = [1:6]) tongue2d(d);
    for (d = [1:6]) ridge(d);
}

// Footprint used by the top plate to cut the relief pockets.
module finger_relief2d(grow = 0.5) offset(r = grow) for (d = [1:6]) strip2d(d, ridge_w, finger_len, finger_w);

module print_finger_sheet() {
    translate([0, 0, plate_under_z]) mirror([0, 0, 1]) finger_sheet();
}

assert(beam_top_z - finger_preload + ridge_r * 2 < plate_under_z - finger_t,
       "ridge is shorter than its own rounded tip");

print_finger_sheet();
