use <braille_cam.scad>
use <linkage_comb.scad>
translate([0,0,0])braille_cam();
translate([55,0,0])linkage_comb();
translate([30,35,0])import("../assets/dot_insert.stl");
translate([90,-25,0.6])import("../assets/arm_1_set_1.stl");
translate([118,-25,0.6])import("../assets/arm_2_set_1.stl");
translate([90,-9,0.6])import("../assets/arm_3_set_1.stl");
translate([118,-9,0.6])import("../assets/arm_4_set_1.stl");
translate([90,7,0.6])import("../assets/arm_5_set_1.stl");
translate([118,7,0.6])import("../assets/arm_6_set_1.stl");
