// Board holders on the box floor for the ULN2003 module and the 7Semi MCP23017
// breakout. outer_box.scad unions them into the box; this file only keeps the
// numbers in one place.
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

sink = 0.2;   // into the box floor, so the union is solid
module bracket(x0, y0, sx, sy) translate([x0, y0, floor_z - sink]) cube([sx, sy, sled_t + groove_d + sink]);

module board_holders() {
    difference() {
        union() {
            // driver strip; wide enough to bridge the floor gutter at x 11..18
            translate([10.0, -drv_slot / 2 - 1.2, floor_z - sink]) cube([9.0, drv_slot + 2.4, sled_t + sink]);
            for (s = [-1, 1])
                bracket(drv_x - groove_w / 2 - wall, s > 0 ? drv_slot / 2 + 1.2 - bracket_len : -drv_slot / 2 - 1.2,
                        groove_w + 2 * wall, bracket_len);
            // MCP strip
            translate([-mcp_slot / 2 - 1.2, mcp_y - groove_w / 2 - wall, floor_z - sink])
                cube([mcp_slot + 2.4, groove_w + 2 * wall, sled_t + sink]);
            for (s = [-1, 1])
                bracket(s > 0 ? mcp_slot / 2 + 1.2 - bracket_len : -mcp_slot / 2 - 1.2, mcp_y - groove_w / 2 - wall,
                        bracket_len, groove_w + 2 * wall);
            // tie between the two strips
            translate([10.0, mcp_y, floor_z - sink]) cube([mcp_slot / 2 + 1.2 - 10.0, -drv_slot / 2 - mcp_y, sled_t + sink]);
        }
        translate([drv_x - groove_w / 2, -drv_slot / 2, seat_z]) cube([groove_w, drv_slot, groove_d + 1]);
        translate([-mcp_slot / 2, mcp_y - groove_w / 2, seat_z]) cube([mcp_slot, groove_w, groove_d + 1]);
    }
}

board_holders();
