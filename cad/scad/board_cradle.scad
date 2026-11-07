// Two open opposing end brackets per PCB: [     ].
// PCB thickness 1.6 assumed, slot 2.0; bottom seating datum Z8.
module groove(a,b,cut_a,cut_b){
 difference(){translate(a)cube(b);translate(cut_a)cube(cut_b);}
}
module board_cradle(){
 // Driver: 4mm long end brackets; 30mm middle left open.
 for(y=[-19,15]) intersection(){
  groove([10.3,-19,3.8],[6,38,6.2],[12.3,-17.8,8],[2,35.6,3]);
  translate([10.3,y,3.8])cube([6,4,6.2]);
 }
 // MCP: 4mm long end brackets; 26mm middle left open.
 for(x=[-17,13]) intersection(){
  groove([-17,-26.76,3.8],[34,6,6.2],[-15.8,-24.76,8],[31.6,2,3]);
  translate([x,-26.76,3.8])cube([4,6,6.2]);
 }
}
