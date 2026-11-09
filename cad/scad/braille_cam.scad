// Current 3x1.5 magnet cam. Exact owned-resin track mesh is the reference.
// Pocket 3.2 x 1.6 deep, 0.41 roof under the lowest track. A 3 x 1.5 magnet sits 0.1 below the face; glue makes it flush. Nothing projects.
module braille_cam(){difference(){
 union(){import("../assets/braille_cam.stl");
 translate([0,17.35,6.5])cylinder(d=8.24,h=1.22,$fn=30);}
 translate([0,17.35,6.49])cylinder(d=3.2,h=1.61,$fn=96);   // 1.6 deep: a 1.5 magnet sits 0.1 below the face, flush with glue
}}
braille_cam();
