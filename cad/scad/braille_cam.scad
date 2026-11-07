// Current 3x1.5 magnet cam. Exact owned-resin track mesh is the reference.
// Pocket depth1.4 leaves0.6 roof. Magnet projects0.1 nominal,0.2 with0.1 glue.
module braille_cam(){difference(){
 union(){import("../assets/braille_cam.stl");
 translate([0,17.35,6.5])cylinder(d=8.24,h=1.22,$fn=30);}
 translate([0,17.35,6.49])cylinder(d=3.2,h=1.41,$fn=96);
}}
braille_cam();
