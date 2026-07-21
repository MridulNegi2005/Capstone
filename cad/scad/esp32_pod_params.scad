// =========================================================
// ESP32 BRAIN POD — Shared Parameters & Base Modules
// Revision 3.0 — Matching Brick + Horizontal Socket Mount
// Updated 2026-05-31
//
// Pod now shares the cell's docking face (68 wide × 58 tall)
// so the chain looks like a uniform row of bricks.
//
// ESP32 DOIT DevKit V1 (30-pin, ~51.5×28mm) mounts HORIZONTALLY
// on two 1×15 female header strips — plug-and-play, no soldering.
//
// include <esp32_pod_params.scad>
// =========================================================

// --- POD SHELL DIMENSIONS ---
pod_length       = 64;     // X — depth (USB end to dock end); fits 51.5mm board + walls
pod_width        = 68;     // Y — matches cell shell_width for uniform chain look
pod_height       = 58;     // Z — matches cell shell_height
pod_wall         = 4;      // Wall thickness
pod_floor        = 3;      // Floor thickness
pod_fillet       = 3.0;    // Outer corner radius — matches cell (was 2.0)

lid_h            = pod_wall;   // 4mm lid

// Internal cavity
pod_int_length   = pod_length - 2 * pod_wall;  // 56mm
pod_int_width    = pod_width  - 2 * pod_wall;  // 60mm

// --- ESP32 DEVKIT V1 MOUNTING (horizontal on female header sockets) ---
// Board: ~51.5 × 28mm, 15 pins/side, pin-row pitch ~25.4mm (MEASURE AND CONFIRM)
// Two 1×15 female header strips sit in printed channels on the floor.
// DevKit's male pins plug straight down — zero soldering, fully removable.
devkit_length    = 51.5;   // Board X extent
devkit_width     = 28.0;   // Board Y extent
hdr_row_pitch    = 25.4;   // Pin-row centre-to-centre (measure your board!)
hdr_strip_w      = 2.7;    // Female header strip body width
hdr_strip_h      = 8.5;    // Female header strip body height (board sits at floor+8.5)
hdr_strip_len    = 40.0;   // 15-pin strip length (~15×2.54=38.1, round up)
hdr_channel_depth = 1.0;   // Floor recess to locate strips

// Board position: centred in Y, offset toward dock (+X) end for USB clearance
devkit_x_offset  = 4;      // +X shift from pod centre (USB at -X end wall)

// --- BARREL JACK (on the LID) ---
// v6.1b FIX: was centered at x=-30 — the Ø11.5 hole overflowed the lid edge (±32)
// and printed as an open NOTCH (confirmed on the fit-test print). A panel-mount
// jack can't clamp in a notch. Moved fully onto the lid, offset in Y away from
// the DevKit so the jack body hangs over open floor.
barrel_jack_dia  = 11.5;   // 5.5/2.1mm panel-mount jack
barrel_jack_x    = -22;    // near the -X/USB end, hole fully inside the lid
barrel_jack_y    = 18;     // off the DevKit (board spans y±14)

// --- USB CUTOUT (-X end wall) ---
usb_w            = 10;
usb_h            = 7;
usb_z            = pod_floor + hdr_strip_h + 1;  // At PCB USB port height

// --- POGO INTERFACE (+X dock wall) ---
// Matches cell ±X pogo window exactly
pogo_pad_w       = 10;
pogo_pad_h       = 8;
pogo_pad_recess  = 1;     // 1mm deep recess (anti-short)
pogo_z_from_bot  = 31;    // Matches cell pogo_z

// --- MAGNET POCKETS (+X dock wall) ---
// v6.1: real magnets are 8mm dia × 1mm thick (was 3×2). 2 per face at y=±14,
// matching the cell exactly so docked magnets align. Teardrop tops (FDM).
// Cell -X face = N/S; pod +X face = S/N → attract, repel reversed
mag_dia          = 8.4;   // 8mm magnet + 0.4mm FDM clearance
mag_depth        = 1.2;   // 1mm magnet + glue gap (4mm wall keeps 2.8mm)
mag_y_positions  = [-14, 14];
mag_z            = pod_height / 2;   // 29mm — matches cell

// --- WIFI ANTENNA GRILLE (+X end, near dock) ---
antenna_wall     = 1.5;
antenna_slot_w   = 3;      // v6.1: 2→3mm (2mm slots fused on the fit-test printer)
antenna_slot_h   = 8;
antenna_slot_count = 3;

// --- WIRE TIE POST ---
tie_post_dia     = 4;
tie_post_h       = 10;
tie_post_hole    = 2;

// --- NAVIGATION BUTTONS (front face, -Y wall) ---
// 3× PS-style flanged caps: Previous (<), Select (O), Next (>)
// 6×6×5mm tactile switches held in printed snap pockets behind wall
nav_shaft_dia    = 4.0;
nav_hole_dia     = 4.2;    // 0.2mm sliding clearance
nav_flange_dia   = 8.0;
nav_flange_h     = 1.5;
nav_cap_body_dia = 7.5;
nav_cap_body_h   = 3.5;
nav_shaft_len    = 4.5;    // 4mm through wall + 0.5mm inside
nav_z            = pod_height * 0.42;  // ~24.4mm — comfortable thumb height
nav_x_positions  = [-20, 0, 20];

// --- TACTILE SWITCH POCKET (behind each nav hole, inside front wall) ---
sw_body          = 6.4;    // 6mm switch + 0.4mm clearance
sw_depth         = 5.5;    // switch is 5mm + 0.5mm clearance behind
sw_snap_nib      = 0.8;    // retention nib overhang (v6.1: 0.4→0.8, was sub-layer thin)

// --- LID SCREW BOSSES ---
// v6.1b: 25→27.5. At x=25 the Ø5 bosses FLOATED 0.5mm off the inner wall (x=28) —
// disconnected bodies in the STL, printed as loose/spaghetti towers. At 27.5 the
// boss embeds 2mm into the wall. Lid holes follow automatically (same param).
lid_screw_x      = 27.5;   // ±27.5mm along X
lid_screw_d      = 2.8;    // v6.2: 2.4→2.8 M2 clearance in lid (print tolerance)
lid_boss_d       = 5.0;    // Boss OD in shell
lid_boss_tap     = 2.0;    // M2 self-tap pilot (v6.1: 1.7→2.0, FDM prints undersize; drill if tight)

$fn = 60;

// --- SHARED BASE MODULE ---

module teardrop_magnet_pocket() {
    // Horizontal-axis magnet pocket with a 45° "roof" — round side-wall holes fused
    // closed on the fit-test print; the teardrop top is self-supporting on FDM.
    // Drawn with axis along +Z, mouth at z=0; caller rotates it into the wall.
    r = mag_dia / 2;
    linear_extrude(mag_depth + 0.01) union() {
        circle(r=r, $fn=40);
        polygon([[-r * sin(45), r * cos(45)],
                 [0, r * sqrt(2)],
                 [ r * sin(45), r * cos(45)]]);
    }
}

module pod_rounded_box(l, w, h, r) {
    hull() {
        translate([-l/2 + r, -w/2 + r, 0]) cylinder(r=r, h=h);
        translate([ l/2 - r, -w/2 + r, 0]) cylinder(r=r, h=h);
        translate([-l/2 + r,  w/2 - r, 0]) cylinder(r=r, h=h);
        translate([ l/2 - r,  w/2 - r, 0]) cylinder(r=r, h=h);
    }
}
