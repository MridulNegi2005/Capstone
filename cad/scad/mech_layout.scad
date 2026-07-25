// =========================================================
// BRAILLIX MECHANISM LAYOUT — SHARED SINGLE SOURCE OF TRUTH
// Created 2026-07-26 (v7.0 "spread feet")
//
// INCLUDED BY: braille_cam.scad, linkage.scad, top_plate.scad
// Everything that has to agree between the cam disc, the linkages and
// the top plate lives HERE and nowhere else. Do not re-declare these
// numbers in the individual part files — that is exactly how the v6.x
// stale-comment/stale-STL bugs happened.
//
// ---------------------------------------------------------
// WHY THE FEET ARE SPREAD AROUND THE DISC (v7.0)
// ---------------------------------------------------------
// Until v6.3 all six linkage feet sat on ONE radial line. Because all
// six arms then had to run from the tiny braille cluster out to that
// same line, they overlapped each other in plan view (14 clashing
// pairs), so each arm needed its own height. Six stacked arm levels
// need ~11.5mm; only 6.5mm exists between the cam surface and the top
// plate. The mechanism was unbuildable.
//
// v7.0 spreads the six feet 60 degrees apart AND assigns each braille
// dot the foot that points the way that dot already sits (dot 4, upper
// right, gets the 60deg foot; dot 3, lower left, gets the 240deg foot;
// and so on). The arms then fan outwards and never cross:
//     closest pair of arms = 2.60mm apart  (need 1.0mm)
// so ALL SIX ARMS SIT AT ONE COMMON HEIGHT. That single change also
// frees ~8mm of space between neighbouring arms out at r=8mm, which is
// where the return springs now live (at the dot cluster there is only
// 0.4mm of room — a spring there is geometrically impossible).
//
// A happy side effect: pointing each dot at its nearest foot SHORTENED
// every arm (10.4-17.9mm, was 15.4-19.1mm) = stiffer, less fragile.
// ---------------------------------------------------------

// --- CAM TRACK GEOMETRY ---
inner_radius = 12.0;   // inner edge of track 0
track_width  = 1.6;    // radial width of one track
track_gap    = 0.1;    // gap between adjacent tracks

// Centre radius of track t (t = 0 innermost .. 5 outermost)
function track_r(t) = inner_radius + t * (track_width + track_gap) + track_width / 2;
//  t0=12.80  t1=14.50  t2=16.20  t3=17.90  t4=19.60  t5=21.30

// --- BRAILLE CELL GEOMETRY ---
// Standard dot numbering:   1 4
//                           2 5
//                           3 6
col_spacing = 4.8;     // left column x=-2.4, right column x=+2.4
row_spacing = 2.6;     // rows at y=+2.6, 0, -2.6

function dot_pos(d) = [ (d <= 3) ? -col_spacing/2 : col_spacing/2,
                        (d == 1 || d == 4) ?  row_spacing :
                        (d == 2 || d == 5) ?  0 : -row_spacing ];

// --- THE ASSIGNMENT (dot -> track, dot -> foot angle) ---
// Chosen so each dot's arm points outward the way the dot already sits,
// which is what makes the arms non-overlapping. Index = dot number - 1.
dot_track = [ 2,   3,   4,   1,   0,   5  ];   // which cam track drives this dot
dot_phase = [120, 180, 240,  60,   0, 300 ];   // where that dot's foot sits, degrees

function dot_track_of(d) = dot_track[d - 1];
function dot_phase_of(d) = dot_phase[d - 1];

// Foot landing point for dot d, in cam coordinates
function foot_pos(d) =
    let(r = track_r(dot_track_of(d)), a = dot_phase_of(d))
    [ r * cos(a), r * sin(a) ];

// Nub-to-foot geometry (used by linkage.scad AND top_plate.scad)
function arm_vec(d)  = foot_pos(d) - dot_pos(d);
function arm_span(d) = norm(arm_vec(d));
function arm_dir(d)  = arm_vec(d) / arm_span(d);
function asm_ang(d)  = atan2(arm_vec(d)[1], arm_vec(d)[0]);

// --- PER-TRACK CAM PHASE ---
// track_phase[t] = the angle at which track t's foot sits, so the cam
// generator can rotate that track's bump pattern to match. Derived from
// the assignment above so the two can never disagree.
function track_phase(t) =
    t == dot_track[0] ? dot_phase[0] :
    t == dot_track[1] ? dot_phase[1] :
    t == dot_track[2] ? dot_phase[2] :
    t == dot_track[3] ? dot_phase[3] :
    t == dot_track[4] ? dot_phase[4] :
                        dot_phase[5];
//  track 0->0deg  1->60  2->120  3->180  4->240  5->300

// --- SHARED VERTICAL STACK (world z, mm from outer-box floor) ---
cam_flat_z    = 45.0;  // cam surface, dot DOWN
pin_lift      = 0.8;   // cam bump height = how far a dot rises
plate_under_z = 54.0;  // top plate underside (sits on base-plate standoffs)
plate_top_z   = 58.0;  // top plate top surface = the reading surface

// Linkage foot bottom sits on cam_flat_z, nub top must reach plate_top_z
link_total_h  = plate_top_z - cam_flat_z;   // 13.0mm

// --- RETURN SPRING SEAT ---
// Spring pushes DOWN on a pad partway along each arm, out where there is
// room (NOT at the dot cluster — only 0.4mm free there).
spring_seat_dist = 7.0;   // distance along the arm from the nub
spring_od        = 4.0;   // ballpoint-pen spring outer diameter
spring_seat_d    = 5.0;   // pad diameter on the linkage arm

// Seat centre for dot d, in cam coordinates
function spring_seat_pos(d) = dot_pos(d) + arm_dir(d) * spring_seat_dist;
