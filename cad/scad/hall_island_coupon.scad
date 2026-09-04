/*
  Exact Option-A Hall-island section coupon

  This is cut directly from the production base_plate() module so the underside
  sensor tunnel, 0.4 mm roof, 0.7 mm island, wire channel, and print orientation
  cannot drift. Print flat in PETG with no supports. Fit the bare Hall body, route
  its three leads, and verify switching with the intended 8x1 mm magnet before
  releasing the full base.

  MAGNET: 8x1mm, not the 3x1mm this file used to name. 3mm discs could not be
  sourced and the only 3mm stock is 3x3, which fails the cam's own assert
  (magnet_depth < disk_base_thickness - 0.5). See homing_mag_dia in
  mech_layout.scad, which is where the number actually lives.

  SENSOR: a bare A3144 unipolar digital switch in TO-92, NOT the analog MH
  module. This is forced, not preferred - a multi-cell chain reads the hall
  through the cell's own MCP23017 expander, and an expander has no ADC. The
  A3144 body is 4.1 x 3.0 x 1.5mm and the pocket is 4.5 x 3.5, so no CAD change
  was needed for the swap.

  WHAT THIS COUPON MUST NOW PROVE: that the 8mm magnet switches the A3144
  cleanly through the 0.4mm roof and 0.5mm air gap, and - because the magnet
  spans 4.7 cam states - that ONE EDGE of the field is repeatable when the cam
  always approaches from the same direction. Peak detection is meaningless at
  this magnet size.
*/

include <hall_interface.scad>

coupon_w = 20;
coupon_y0 = 9;
coupon_depth = 16;
plate_t = 5;

intersection() {
    difference() {
        union() {
            translate([-coupon_w/2, coupon_y0, 0])
                cube([coupon_w, coupon_depth, plate_t]);
            hall_sensor_island(4, plate_t);
        }
        hall_sensor_pocket(4, plate_t, 50);
    }
    translate([-coupon_w/2, coupon_y0, -0.01])
        cube([coupon_w, coupon_depth + 0.1, 6.01]);
}
