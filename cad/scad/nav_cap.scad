// Captive navigation buttons, resin. Built along +z = outward, z = 0 at the inner
// wall face: flange inside (z < 0), D-shaped body through the 4 mm wall, raised
// symbol on the outer end. Fit each button from inside the pod, then drop the
// tactile switch into its cage behind it. No glue on the button.
include <esp32_pod_params.scad>

raise_h = 1.0;
$fn = 60;

module nav_d2d(d, flat) intersection() { circle(d = d, $fn = 48); translate([-d, -flat]) square([2 * d, 2 * d]); }

module cap_body() {
    len = pod_wall + nav_proud;
    translate([0, 0, -nav_flange_h]) cylinder(d = nav_flange_dia, h = nav_flange_h);
    hull() {
        linear_extrude(len - 0.6) nav_d2d(nav_body_dia, nav_body_flat);
        translate([0, 0, len - 0.61]) linear_extrude(0.61) offset(delta = -0.6) nav_d2d(nav_body_dia, nav_body_flat);
    }
}

module on_top() translate([0, 0.3, pod_wall + nav_proud]) linear_extrude(raise_h) children();

module nav_cap_prev()   { cap_body(); on_top() polygon([[-1.6, 0], [0.9, 1.3], [0.9, -1.3]]); }
module nav_cap_select() { cap_body(); on_top() difference() { circle(d = 3.0, $fn = 48); circle(d = 1.6, $fn = 48); } }
module nav_cap_next()   { cap_body(); on_top() polygon([[1.6, 0], [-0.9, 1.3], [-0.9, -1.3]]); }

// assembled position on the pod front wall (-Y), for checks and renders
module nav_caps_assembled() {
    y_in = -pod_width / 2 + pod_wall;
    for (i = [0:2]) translate([nav_x_positions[i], y_in, nav_z]) rotate([90, 0, 0])
        if (i == 0) nav_cap_prev(); else if (i == 1) nav_cap_select(); else nav_cap_next();
}

// print layout: flange down, symbol up
module nav_caps_print() for (i = [0:2]) translate([i * 14, 0, nav_flange_h])
    if (i == 0) nav_cap_prev(); else if (i == 1) nav_cap_select(); else nav_cap_next();

nav_caps_print();
