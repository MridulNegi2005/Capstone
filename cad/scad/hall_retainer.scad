// Separate FDM part. Export bed face down; installed z=-1.3 relative to base.
include <hall_interface.scad>
module hall_retainer() {
    difference() {
        union() {
            translate([-4,homing_mag_r-2.6,0]) cube([8,3.6,0.8]);
            for(sx=[-1,1]) hull() {
                translate([sx*3,homing_mag_r,0]) cylinder(d=2,h=0.8,$fn=32);
                translate([sx*6,25.5,0]) cylinder(d=4.5,h=0.8,$fn=32);
            }
            for(sx=[-1,1]) translate([sx*6,25.5,0]) cylinder(d=4.5,h=1.3,$fn=32);
        }
        for(sx=[-1,1]) translate([sx*6,25.5,-0.1]) cylinder(d=2.6,h=1.5,$fn=32);   // M2 clearance; still passes M2 if printed 0.3 small
    }
}
hall_retainer();
