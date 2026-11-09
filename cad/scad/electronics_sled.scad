// Electronics sled: a separate part that holds the ULN2003 module and the
// 7Semi MCP23017 breakout on edge. It drops onto the box floor, two pegs locate
// it, and a dab of hot glue keeps it there. The pegs stand on the box floor,
// so this part prints flat with no supports. If a board does not fit, reprint
// this part only.
//
// Each board stands on its bottom edge in two short end grooves. The grooves
// touch only the corner mounting-hole areas, because the long edges of both
// boards carry the solder pads.
include <electronics_envelopes.scad>

sled_t      = 1.2;     // base plate under every groove
groove_w    = 2.0;     // PCB 1.6
groove_d    = 3.0;
bracket_len = 5.0;
wall        = 2.0;
peg_d       = 2.8;
peg_h       = 1.1;     // below the MCP edge at seat_z
sled_pegs   = [[-9, mcp_y], [9, mcp_y]];   // under the MCP strip, clear of the floor gutters

module bracket(x0, y0, sx, sy) translate([x0, y0, floor_z]) cube([sx, sy, sled_t + groove_d]);

module electronics_sled() {
    difference() {
        union() {
            // driver strip; wide enough to bridge the floor gutter at x 11..18
            translate([10.0, -drv_slot / 2 - 1.2, floor_z]) cube([9.0, drv_slot + 2.4, sled_t]);
            for (s = [-1, 1])
                bracket(drv_x - groove_w / 2 - wall, s > 0 ? drv_slot / 2 + 1.2 - bracket_len : -drv_slot / 2 - 1.2,
                        groove_w + 2 * wall, bracket_len);
            // MCP strip
            translate([-mcp_slot / 2 - 1.2, mcp_y - groove_w / 2 - wall, floor_z])
                cube([mcp_slot + 2.4, groove_w + 2 * wall, sled_t]);
            for (s = [-1, 1])
                bracket(s > 0 ? mcp_slot / 2 + 1.2 - bracket_len : -mcp_slot / 2 - 1.2, mcp_y - groove_w / 2 - wall,
                        bracket_len, groove_w + 2 * wall);
            // tie between the two strips
            translate([10.0, mcp_y, floor_z]) cube([mcp_slot / 2 + 1.2 - 10.0, -drv_slot / 2 - mcp_y, sled_t]);
        }
        for (p = sled_pegs) translate([p[0], p[1], floor_z - 0.1]) cylinder(d = peg_d + 0.4, h = sled_t + 0.2, $fn = 24);
        translate([drv_x - groove_w / 2, -drv_slot / 2, seat_z]) cube([groove_w, drv_slot, groove_d + 1]);
        translate([-mcp_slot / 2, mcp_y - groove_w / 2, seat_z]) cube([mcp_slot, groove_w, groove_d + 1]);
    }
}

// pegs on the box floor, added by outer_box.scad
module sled_floor_pegs() for (p = sled_pegs) translate([p[0], p[1], floor_z - 0.2]) cylinder(d = peg_d, h = peg_h + 0.2, $fn = 24);

electronics_sled();
