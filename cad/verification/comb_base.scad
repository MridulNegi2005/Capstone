module part(n){import(str("../stl/",n,".stl"));}
module shell(){part("outer_box");}
module base(){translate([0,0,41])part("base_plate");}
module cam(){translate([0,0,36.5])part("braille_cam");}
module comb(){translate([0,0,45])part("linkage_comb");}
module top(){translate([0,0,54])part("top_plate");}
module tile(){translate([0,0,54])part("dot_insert");}
module arms(h=0){for(i=[1:6])translate([0,0,45+h])import(str("../assets/assembled_arm_",i,".stl"));}
module heads(){for(x=[-19,19],y=[-19,19])translate([x,y,48.3]){cylinder(d=5,h=.5,$fn=48);translate([0,0,.5])cylinder(d=4,h=2,$fn=48);}}
module magnet_sweep(){translate([0,0,42.8])difference(){cylinder(r=18.85,h=1.5,$fn=192);translate([0,0,-.01])cylinder(r=15.85,h=1.52,$fn=192);}}
intersection(){comb();base();}