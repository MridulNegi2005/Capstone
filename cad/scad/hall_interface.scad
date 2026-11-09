// Candidate Hall interface: retained underside mount, explicit roof and gap.
include <mech_layout.scad>
assert(stack_repair_raise == 0, "Candidate only supports the default motor stack");
hall_body_w=4.1; hall_body_d=3.1; hall_body_t=1.6;
hall_fit=0.8; hall_floor_t=0.4; hall_air_gap=0.4;
hall_wire_w=4; hall_wire_d=0.8;
hall_pocket_x=homing_mag_r*cos(homing_mag_angle);
hall_pocket_y=homing_mag_r*sin(homing_mag_angle);
// 5 - 3.4 pocket - 0.4 roof = 1.2mm recess; body projects below base.
hall_underhang=0.5; // 0.4 body projection + 0.1 assembly allowance
function hall_island_height(repair_raise,plate_thickness)=0;
function hall_pocket_height(repair_raise,plate_thickness)=
    plate_thickness-cam_pocket_depth-hall_floor_t;
module hall_sensor_island(repair_raise,plate_thickness) {}
module hall_sensor_pocket(repair_raise,plate_thickness,plate_width) {
    depth=hall_pocket_height(repair_raise,plate_thickness);
    assert(depth>0 && plate_thickness-cam_pocket_depth-depth>=0.399);
    translate([hall_pocket_x-(hall_body_w+hall_fit)/2,
               hall_pocket_y-(hall_body_d+hall_fit)/2,-0.1])
        cube([hall_body_w+hall_fit,hall_body_d+hall_fit,depth+0.1]);
    translate([-hall_wire_w/2,hall_pocket_y,-0.1])
        cube([hall_wire_w,plate_width/2-hall_pocket_y+1,hall_wire_d+0.1]);
}
