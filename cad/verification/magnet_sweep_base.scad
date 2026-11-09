module part(n){import(str("../stl/",n,".stl"));}
module shell(){part("outer_box");}
module base(){translate([0,0,41])part("base_plate");}
module cam(){translate([0,0,36.5])part("braille_cam");}
module comb(){translate([0,0,45])part("linkage_comb");}
module top(){translate([0,0,54])part("top_plate");}
module tile(){translate([0,0,54])part("dot_insert");}
module arms(h=0){for(i=[1:6])translate([0,0,45+h])import(str("../assets/assembled_arm_",i,".stl"));}
use <../scad/finger_sheet.scad>
module sheet(v="finger_sheet"){translate([0,0,54])mirror([0,0,1])part(v);}
module tongues_up(v,lift){translate([0,0,lift])intersection(){sheet(v);translate([0,0,40])linear_extrude(14.01)finger_relief2d(0);}}
module sheet_flat(v="finger_sheet"){intersection(){sheet(v);translate([-40,-40,54-1.04-0.001])cube([80,80,1.2]);}}
module heads(){for(x=[-19,19],y=[-19,19])translate([x,y,48.3]){cylinder(d=5,h=.5,$fn=48);translate([0,0,.5])cylinder(d=4,h=2,$fn=48);}}
use <../scad/electronics_envelopes.scad>
module others(){union(){shell();base();cam();translate([0,0,39.7])part("hall_retainer");}}
module magnet_sweep(){translate([0,0,42.8])difference(){cylinder(r=18.85,h=1.5,$fn=192);translate([0,0,-.01])cylinder(r=15.85,h=1.52,$fn=192);}}
intersection(){magnet_sweep();base();}