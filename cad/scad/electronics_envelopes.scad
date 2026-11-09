// Space claims for the parts that are bought, not printed, in the tall-box frame.
// Used for fit checks and renders only. ASSUMED sizes are marked.
floor_z  = 4.0;
seat_z   = floor_z + 1.2;          // board bottom edge, = sled_t above the floor

// ULN2003 module, the common 35 x 32 board (ASSUMED, not measured).
// Stands on its 35 mm edge in the plane x = drv_x, chip side facing +X.
drv_l = 35; drv_h = 32; pcb = 1.6;
drv_slot = drv_l + 2.0;            // +-1 mm play on length
drv_x    = 13.3;
drv_front = 8.5;                   // chip, LEDs, JST socket
drv_back  = 2.0;                   // solder joints
bare_edge = 3.0;                   // bottom strip held by the grooves

// 7Semi MCP23017 breakout BO-10180: 31 x 20, 7.14 tall with the JST (published).
// Stands on its 31 mm edge in the plane y = mcp_y, parts facing -Y (to the wall).
mcp_l = 31; mcp_h = 20;
mcp_slot = mcp_l + 1.4;
mcp_y    = -23.26;
mcp_front = 7.14 - pcb;
mcp_back  = 2.0;

module driver_env() {
    translate([drv_x - pcb / 2, -drv_l / 2, seat_z]) cube([pcb, drv_l, drv_h]);
    translate([drv_x - pcb / 2 - drv_back, -drv_l / 2, seat_z + bare_edge]) cube([drv_back, drv_l, drv_h - bare_edge]);
    translate([drv_x + pcb / 2, -drv_l / 2 + 2, seat_z + 5]) cube([drv_front, drv_l - 4, drv_h - 5]);
    // motor plug in the JST, top middle, sticking out +X
    translate([drv_x + pcb / 2, -6, seat_z + drv_h - 11]) cube([14, 12, 9]);
}

module mcp_env() {
    translate([-mcp_l / 2, mcp_y - pcb / 2, seat_z]) cube([mcp_l, pcb, mcp_h]);
    translate([-mcp_l / 2 + 2, mcp_y - pcb / 2 - mcp_front, seat_z + bare_edge]) cube([mcp_l - 4, mcp_front, mcp_h - bare_edge]);
    translate([-mcp_l / 2 + 2, mcp_y + pcb / 2, seat_z + bare_edge]) cube([mcp_l - 4, mcp_back, mcp_h - bare_edge]);
}

// 28BYJ-48 in the tall-box frame (MEASURED sizes from motor_spec.scad)
module motor_env() {
    translate([-7.5, 0, 15.5]) cylinder(d = 28.1, h = 19, $fn = 100);
    translate([0, 0, 34.5]) cylinder(d = 9, h = 2, $fn = 60);
    translate([0, 0, 36.5]) intersection() { cylinder(d = 5, h = 7.5, $fn = 40); translate([-3, -1.5, 0]) cube([6, 3, 7.5]); }   // 3 mm flats, along Y like the cam bore
    for (y = [-17.35, 17.35]) translate([-7.5, y, 33.5]) cylinder(d = 7, h = 1, $fn = 40);
    hull() for (y = [-17.35, 17.35]) translate([-7.5, y, 33.5]) cylinder(d = 7, h = 1, $fn = 40);
    translate([-25, -8, 15.5]) cube([5, 16, 8]);
}
