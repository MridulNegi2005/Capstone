// =========================================================
// ADVANCED PARAMETRIC BRAILLE CAM GENERATOR (Production Spec)
// Revision 3 — Track/Bit Reorder (v6.3, 2026-06-14)
// (Rev 2 — Hub Inverted, 2026-05-06)
//
// v6.3 FIX — INNER TRACK GEOMETRY WAS PHYSICALLY IMPOSSIBLE:
//   Each cam position is a 5.625deg slice. At the OLD bit order (bit t
//   drove track t, i.e. innermost track = LSB = toggles every single
//   state), the innermost track's single-slice flat "dwell" zone was
//   only ~0.88mm wide (0.7 * slice-arc-at-r12.8, with 0.7 = 1 -
//   angular_ramp_fraction). The linkage foot is 1.0mm thick (=
//   `thickness` in linkage.scad — the sheet extrudes to a 1mm-thick
//   tangential contact edge). A 1.0mm foot cannot rest inside a 0.88mm
//   dwell zone — it was ALWAYS straddling a ramp. Every dot on that
//   track would sit half-up, all the time.
//
//   FIX: reverse which bit drives which track. get_pattern_bit() below
//   now assigns the SLOWEST-changing bit (MSB, flips only twice per
//   revolution -> its flat zone is dozens of slices wide, radius
//   doesn't matter) to the INNERMOST track, and the FASTEST-changing
//   bit (LSB, toggles every single state -> needs the widest possible
//   single-slice dwell) to the OUTERMOST track, where the arc is
//   biggest. This is a pure logic change — no geometry/size/cost
//   change to the disc. Linkage.scad is UNAFFECTED (arm_span/asm_ang
//   depend only on physical track radius, never on which bit lights
//   a track — see the note in linkage.scad).
//
//   Worst-case (LSB) dwell after the fix, at the outermost track
//   (r=21.3mm, arc=2.09mm/slice): 0.7*2.09 = 1.46mm dwell vs 1.0mm
//   foot -> ~0.23mm clearance per side. Tight but workable on resin.
//   Also dropped angular_ramp_fraction 0.3->0.2 (free — pure curve
//   tuning, doesn't change disc size) for a bit more margin: dwell
//   becomes 0.8*2.09 = 1.67mm -> ~0.335mm clearance per side.
//
//   >>> SOFTWARE TEAM: this changes which bit sets which dot. See
//   >>> docs/SOFTWARE_TEAM_README.md Step 2 (cell_to_cam) — updated
//   >>> to match. <<<
//
// Older history (Rev 2, 2026-05-06):
//   - D-shaft hub now extends DOWNWARD from disc underside
//     (was protruding upward above tracks — blocked linkage feet)
//   - Hub height = 4mm below z=0 (drops over motor shaft from above)
//   - Top surface of disc is now completely flat/clear for linkage
//     contact across all 6 tracks
//   - Magnet pocket unchanged (still on underside, flush)
// =========================================================

// --- 1. CONFIGURATION PARAMETERS ---
states = 64;                // Total positions (6-bit binary)
dots = 6;                   // Number of tracks
disk_base_thickness = 2.0;  // Base thickness (mm)
pin_lift = 0.8;             // Height of the bump (mm)
track_width = 1.6;          // Width of each track (mm)
track_gap = 0.1;            // Gap between tracks (Drop to 0.1 for Resin/SLA)
inner_radius = 12.0;        // Was 8.0 — increased to reduce foot-span on inner tracks (v5.1)
angular_ramp_fraction = 0.2;// v6.3: 0.3->0.2 — more flat dwell per slice, free (no size/cost change)
subdivisions_per_slice = 4; // Smoothness (Higher = smoother, slower)
preview_mode = false;       // Set FALSE for final high-quality render!

// Homing magnet pocket (on disc underside, triggers Hall sensor on base plate)
magnet_dia    = 3.0;   // 3mm dia neodymium disc magnet
magnet_depth  = 2.0;   // 2mm deep (leaves 0mm floor — magnet flush with bottom)
magnet_radius = 17.35; // Radius from centre (centre of outermost track, just inside disc edge)
magnet_angle  = 90;    // Changed from 0° → 90° to match hall sensor repositioned at
                       // base_plate y=+20mm (+Y axis). Was x=+19mm (+X axis, now outside plate).

// Hub extends below disc; Double-D bore continues into disc floor
// Shaft is 10mm long — hub + bore must accommodate most of it
// Hub 4mm below disc + bore 4mm into disc floor = 8mm total engagement
// Remaining 2mm of shaft sits below hub (in base_plate shaft clearance hole)
hub_h = 4;
shaft_bore_depth = 8;  // total Double-D bore depth from hub bottom through disc floor

// Calculated Variables
slice_angle = 360 / states;
ramp_angle = slice_angle * angular_ramp_fraction;

// --- 2. LOGIC FUNCTIONS ---

// Binary Mapping (Index -> Binary Pattern) — v6.3 REORDERED
// Returns 1 if the dot is UP, 0 if DOWN
// track_idx 0 = innermost (smallest arc/slice -> gets the SLOWEST bit, MSB)
// track_idx dots-1 = outermost (biggest arc/slice -> gets the FASTEST bit, LSB)
// i.e. bit_for_track = (dots-1-track_idx). See the v6.3 header note above for why.
function get_pattern_bit(state_idx, track_idx) =
    floor(state_idx / pow(2, dots - 1 - track_idx)) % 2;

// Linear Interpolation (Lerp)
function lerp(start, end, bias) = (1 - bias) * start + bias * end;

// S-Curve Smoothing (Optional, for smoother ramps)
function s_curve(t) = (1 - cos(t * 180)) / 2;

// Height Calculation Logic (The Core Algorithm)
function get_height_at_angle(angle, track) = 
    let(
        // Identify which "Slice" (Letter) we are in
        k = floor(angle / slice_angle),
        angle_in_slice = angle - (k * slice_angle),
        
        // Identify Neighbors for blending
        prev_k = (k - 1 + states) % states,
        next_k = (k + 1) % states,
        
        // Get Binary States (0 or 1)
        val_curr = get_pattern_bit(k, track),
        val_prev = get_pattern_bit(prev_k, track),
        val_next = get_pattern_bit(next_k, track),
        
        // Ramp Logic
        half_ramp = ramp_angle / 2,
        is_left_ramp = (angle_in_slice < half_ramp),
        is_right_ramp = (angle_in_slice > (slice_angle - half_ramp)),
        
        // Calculate Height Factor (0.0 to 1.0)
        h_factor = 
            is_left_ramp ? 
                lerp(val_prev, val_curr, s_curve((angle_in_slice + half_ramp) / ramp_angle)) :
            is_right_ramp ? 
                lerp(val_curr, val_next, s_curve((angle_in_slice - (slice_angle - half_ramp)) / ramp_angle)) :
            val_curr // Stable Center Zone
    )
    disk_base_thickness + (h_factor * pin_lift);

// --- 3. GEOMETRY MODULES ---

// Optimized Polyhedron Builder (Much faster than linear_extrude loop)
module build_track_polyhedron(t_idx) {
    r_in = inner_radius + t_idx * (track_width + track_gap);
    r_out = r_in + track_width;
    
    // Resolution logic
    res = preview_mode ? 1 : subdivisions_per_slice;
    step = slice_angle / res;
    total_steps = states * res;
    
    // Generate Points
    points = [
        for(i = [0 : total_steps - 1]) 
        let(
            a = i * step,
            h = get_height_at_angle(a, t_idx)
        )
        each [
            [r_in * cos(a), r_in * sin(a), h],  // Inner Top
            [r_out * cos(a), r_out * sin(a), h], // Outer Top
            [r_in * cos(a), r_in * sin(a), 0],   // Inner Bottom
            [r_out * cos(a), r_out * sin(a), 0]  // Outer Bottom
        ]
    ];
    
    // Connect the dots (Faces)
    faces = [
        for(i = [0 : total_steps - 1]) 
        let(
            n = total_steps * 4,
            i0 = (i * 4),      i1 = (i * 4) + 1,
            i2 = (i * 4) + 2,  i3 = (i * 4) + 3,
            next_i0 = (i0 + 4) % n, next_i1 = (i1 + 4) % n,
            next_i2 = (i2 + 4) % n, next_i3 = (i3 + 4) % n
        )
        each [
            [i0, i1, next_i1, next_i0], // Top Surface
            [i2, next_i2, next_i3, i3], // Bottom Surface
            [i0, next_i0, next_i2, i2], // Inner Wall
            [i1, i3, next_i3, next_i1]  // Outer Wall
        ]
    ];

    polyhedron(points=points, faces=faces, convexity=10);
}

// --- 4. MAIN ASSEMBLY ---

difference() {
union() {
    // 0. THE SOLID FLOOR (Fuses all tracks together!)
    outermost_r = inner_radius + (dots * (track_width + track_gap));
    color("darkgray") 
        cylinder(h=disk_base_thickness, r=outermost_r, $fn=100);

    // 1. Central Hub — INVERTED (drops BELOW disc, clears top surface for linkage feet)
    //    Hub extends hub_h=4mm below disc bottom (z=0 → z=−4)
    //    28BYJ-48 Double-D Shaft: 5mm dia with two opposite flats
    //    Shaft length: 10mm above motor body
    //    Bore: Ø5.2 clearance cylinder intersected with 3.2mm-wide slab
    //          on BOTH sides (double-D, not single-D)
    color("gray")
    translate([0, 0, -hub_h])
    difference() {
        // Hub body cylinder (below disc underside)
        cylinder(h=hub_h, r=4.5, $fn=50);

        // Double-D shaft hole — through entire hub height
        // Two opposite flats: cylinder clipped to 3.2mm across flats
        translate([0, 0, -1])
        intersection() {
            cylinder(h=hub_h + 2, r=2.6, $fn=50);     // 5.2mm clearance hole
            cube([10, 3.2, hub_h + 2], center=true);   // Clip to 3.2mm across Y flats
        }
    }

    // 2. Generate Tracks
    for(t = [0 : dots-1]) {
        color( (t%2==0) ? [0.2, 0.6, 1] : [0.3, 0.7, 1] )
        build_track_polyhedron(t);
    }
    
    // 3. Debug: Visual Markers for Pin Alignment (Preview Only)
    if(preview_mode) {
        color("red")
        for(t = [0 : dots-1]) {
            translate([inner_radius + t*(track_width+track_gap) + track_width/2, 0, 5])
            cube([0.5, 0.5, 5], center=true);
        }
    }
} // end union

// Double-D shaft bore through hub AND disc floor (4mm total from hub bottom)
translate([0, 0, -hub_h - 1])
intersection() {
    cylinder(h=shaft_bore_depth + 1, r=2.6, $fn=50);
    cube([10, 3.2, shaft_bore_depth + 1], center=true);  // Double-D: clip Y axis
}

// Homing magnet pocket (subtracted from disc underside)
translate([magnet_radius * cos(magnet_angle),
           magnet_radius * sin(magnet_angle),
           -1])
    cylinder(d=magnet_dia + 0.2, h=magnet_depth + 1, $fn=30);

} // end difference

// --- MODULE WRAPPER (used by print_small_parts.scad) ---
// Print orientation: hub DOWN on build plate, cam tracks face UP — no supports needed.
// Entire assembly shifted up by hub_h=4mm so hub bottom sits at z=0.
module braille_cam() {
    translate([0, 0, hub_h])
    difference() {
        union() {
            // Disc floor
            cylinder(h=disk_base_thickness,
                     r=inner_radius + (dots*(track_width+track_gap)), $fn=100);
            // Hub — hangs below disc, now resting on build plate
            translate([0, 0, -hub_h])
            difference() {
                cylinder(h=hub_h, r=4.5, $fn=50);
                translate([0, 0, -1])
                intersection() {
                    cylinder(h=hub_h+2, r=2.6, $fn=50);
                    cube([10, 3.2, hub_h+2], center=true);  // Double-D
                }
            }
            // All 6 cam tracks
            for(t=[0:dots-1]) build_track_polyhedron(t);
        }
        // Double-D shaft bore through hub + disc floor (4mm total engagement)
        translate([0, 0, -hub_h - 1])
        intersection() {
            cylinder(h=shaft_bore_depth + 1, r=2.6, $fn=50);
            cube([10, 3.2, shaft_bore_depth + 1], center=true);  // Double-D
        }
        // Homing magnet pocket
        translate([magnet_radius*cos(magnet_angle),
                   magnet_radius*sin(magnet_angle), -1])
            cylinder(d=magnet_dia+0.2, h=magnet_depth+1, $fn=30);
    }
}