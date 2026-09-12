"""Create an isolated, reproducible engineering candidate, never a print release.

The copied source is pinned by a SHA-256 manifest. Existing production exports
are not inputs for candidate geometry and are not overwritten.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'cad/candidates/compact_2026_09_09'
SRC = DEST / 'scad'


def replace(name, old, new):
    path = SRC / name
    text = path.read_text(encoding='utf-8')
    if old not in text:
        raise ValueError(f'{name}: source anchor missing: {old[:70]}')
    path.write_text(text.replace(old, new), encoding='utf-8')


def param(name, key, value):
    path = SRC / name
    text = path.read_text(encoding='utf-8')
    pattern = rf'(?m)^{key}\s*=\s*[^;]+;'
    text, count = re.subn(pattern, f'{key} = {value};', text)
    if count != 1:
        raise ValueError(f'{name}: expected one {key}, found {count}')
    path.write_text(text, encoding='utf-8')


def main():
    SRC.mkdir(parents=True, exist_ok=True)
    (DEST / 'stl').mkdir(exist_ok=True)
    hashes = {}
    for source in sorted((ROOT / 'cad/scad').glob('*.scad')):
        hashes[source.name] = hashlib.sha256(source.read_bytes()).hexdigest()
        shutil.copy2(source, SRC / source.name)

    # Compact footprint, unchanged motor, cam diameter and tactile geometry.
    # X walls remain 4 mm at the dock. Y walls become 3 mm.
    param('mech_layout.scad', 'base_length', '55')
    param('mech_layout.scad', 'standoff_x', '24')
    param('mech_layout.scad', 'cam_pocket_depth', '3.4')
    param('outer_box.scad', 'shell_length', '64')
    param('outer_box.scad', 'shell_width', '64')
    param('outer_box.scad', 'internal_length', '56')
    param('outer_box.scad', 'internal_width', '58')
    replace('outer_box.scad', '[sx * 26, sy * 21,', '[sx * 24, sy * 21,')
    replace('outer_box.scad',
            'translate([0, 0, floor_thickness - 0.1 + (elec_pocket_h + 0.1)/2])\n            cube([36, 46, elec_pocket_h + 0.1], center=true);',
            '// Floor-mounted motor: obsolete under-motor electronics recess removed.')
    # Gutter floors must not coincide with the corner-gusset start plane.
    # The former z=3.9 coincidence generated eight four-face STL edges.
    replace('outer_box.scad', '[-18, -20, floor_thickness - 0.1]',
            '[-18, -20, floor_thickness - 0.2]')
    replace('outer_box.scad', '[18 - gutter_w, -20, floor_thickness - 0.1]',
            '[18 - gutter_w, -20, floor_thickness - 0.2]')
    # Existing orientation ridge is recessed into the matching front-face footprint.
    replace('outer_box.scad', '[0, -shell_width/2, 5]', '[0, -shell_width/2 + 1.42, 5]')
    param('top_plate.scad', 'plate_length', '64')
    param('top_plate.scad', 'plate_width', '64')
    param('esp32_pod_params.scad', 'pod_length', '64')
    param('esp32_pod_params.scad', 'pod_width', '64')
    # A narrower body keeps dock wall thickness but must retain the existing 4mm lid.
    # Pod's front button hardware remains attached to its 4mm front wall initially;
    # its Y cavity is kept at 56mm to preserve switch support. Outer envelope matches.
    param('esp32_pod_params.scad', 'pod_int_width', 'pod_width - 2 * pod_wall')

    # Comb: open cuts and a sparse frame with the same six guide locations.
    replace('linkage_comb.scad',
            'cube([pocket_l, pocket_w, comb_h + 0.2]);',
            'cube([pocket_l, pocket_w, comb_top - (clear_z - 0.1) + 0.2]);')
    replace('linkage_comb.scad',
            'translate([0, 0, rest_z]) rounded_square(comb_side, corner_r, comb_h);',
            'skeleton_blank();')
    replace('linkage_comb.scad',
            'translate([0, 0, rest_z - 0.1])\n            cylinder(r = spigot_r, h = clear_z - rest_z + 0.1);',
            '// No negative-height relief: the blank starts above the 0.5mm bumps.')
    # The moved standoff scallop cuts through the old mark at (-22,22),
    # leaving its top floating. Put it on the continuous back rim instead.
    replace('linkage_comb.scad',
            '[-comb_side/2 + mark_pos, comb_side/2 - mark_pos, comb_top - 0.01]',
            '[-comb_side/2 + mark_pos, comb_side/2 - 1.5, comb_top - 0.01]')
    replace('linkage_comb.scad', 'module linkage_comb() {', '''
// Continuous perimeter, six radial guides, and diagonal locating-peg ribs.
// Guide fits are unchanged: try a coupon before selecting FDM for this part.
module skeleton_blank() {
    translate([0,0,rest_z]) union() {
        difference() {
            rounded_square(comb_side, corner_r, comb_h);
            translate([0,0,-0.1]) rounded_square(comb_side-6, 1, comb_h+0.2);
        }
        difference() {
            cylinder(r=bore_r+2.5,h=comb_h);
            translate([0,0,-0.1]) cylinder(r=bore_r,h=comb_h+0.2);
        }
        for(d=[1:6]) rotate([0,0,dot_phase_of(d)])
            translate([bore_r,-2,0]) cube([comb_side/2-bore_r,4,comb_h]);
        for(sx=[-1,1],sy=[-1,1]) hull() {
            translate([sx*peg_xy,sy*peg_xy,0]) cylinder(d=4.8,h=comb_h);
            translate([sx*24.2,sy*24.2,0]) cylinder(d=4.8,h=comb_h);
        }
        for(sx=[-1,1],sy=[-1,1]) hull() {
            translate([sx*peg_xy,sy*peg_xy,0]) cylinder(d=4.8,h=comb_h);
            translate([sx*12,sy*20,0]) cylinder(d=4.8,h=comb_h);
        }
    }
}

module linkage_comb() {''')

    # Base: obsolete motor seat/pilots no longer serve the floor-mounted motor.
    # Their removal preserves plate thickness after the new 0.4mm cam clearance.
    path = SRC / 'base_plate.scad'
    text = path.read_text(encoding='utf-8')
    start = text.index('module motor_features() {')
    end = text.index('\nmodule cam_features()', start)
    text = text[:start] + '''module motor_features() {
    cylinder(d=shaft_clearance, h=20, center=true);
}
''' + text[end:]
    text = text.replace('assert(hall_pocket_h >= hall_body_t,',
                        'assert(hall_pocket_h + hall_underhang >= hall_body_t + 0.09,')
    text = text.replace('motor_features();', '''motor_features();
            // The top-post hole alone does not cut the separate plate body.
            for(sx=[-1,1],sy=[-1,1]) translate([sx*standoff_x,sy*standoff_y,-0.1])
                cylinder(d=2.9,h=base_thickness+0.2,$fn=40);
            // Retainer pilots outside the cam pocket; M2 screws from underneath.
            for(sx=[-1,1]) translate([sx*6,25.5,-0.1])
                cylinder(d=1.6,h=3.2,$fn=24);''')
    path.write_text(text, encoding='utf-8')

    (SRC / 'hall_interface.scad').write_text('''// Candidate Hall interface: retained underside mount, explicit roof and gap.
include <mech_layout.scad>
assert(stack_repair_raise == 0, "Candidate only supports the default motor stack");
hall_body_w=4.1; hall_body_d=3.1; hall_body_t=1.6;
hall_fit=0.4; hall_floor_t=0.4; hall_air_gap=0.4;
hall_wire_w=4; hall_wire_d=0.8;
hall_pocket_x=homing_mag_r*cos(homing_mag_angle);
hall_pocket_y=homing_mag_r*sin(homing_mag_angle);
// 5 - 3.4 pocket - 0.4 roof = 1.2mm recess; body projects below base.
hall_underhang=0.5; // 0.4 body projection + 0.1 assembly allowance
function hall_island_height(repair_raise,plate_thickness)=0;
function hall_pocket_height(repair_raise,plate_thickness)=
    plate_thickness-cam_pocket_depth-hall_floor_t;
module hall_sensor_island(repair_raise,plate_thickness) {}
module hall_sensor_pocket(repair_raise,plate_thickness,plate_width) {
    depth=hall_pocket_height(repair_raise,plate_thickness);
    assert(depth>0 && plate_thickness-cam_pocket_depth-depth>=0.399);
    translate([hall_pocket_x-(hall_body_w+hall_fit)/2,
               hall_pocket_y-(hall_body_d+hall_fit)/2,-0.1])
        cube([hall_body_w+hall_fit,hall_body_d+hall_fit,depth+0.1]);
    translate([-hall_wire_w/2,hall_pocket_y,-0.1])
        cube([hall_wire_w,plate_width/2-hall_pocket_y+1,hall_wire_d+0.1]);
}
''', encoding='utf-8')
    (SRC / 'hall_retainer.scad').write_text('''// Separate FDM part. Export bed face down; installed z=-1.3 relative to base.
include <hall_interface.scad>
module hall_retainer() {
    difference() {
        union() {
            translate([-4,homing_mag_r-2.6,0]) cube([8,3.6,0.8]);
            for(sx=[-1,1]) hull() {
                translate([sx*3,homing_mag_r,0]) cylinder(d=2,h=0.8,$fn=32);
                translate([sx*6,25.5,0]) cylinder(d=4.5,h=0.8,$fn=32);
            }
            for(sx=[-1,1]) translate([sx*6,25.5,0]) cylinder(d=4.5,h=1.3,$fn=32);
        }
        for(sx=[-1,1]) translate([sx*6,25.5,-0.1]) cylinder(d=2.3,h=1.5,$fn=32);
    }
}
hall_retainer();
''', encoding='utf-8')
    # Fixture now derives cam and reading geometry; remains a manually driven rig.
    replace('cam_linkage_test_fixture.scad', '$fn = 60;', 'include <mech_layout.scad>\n$fn = 60;')
    param('cam_linkage_test_fixture.scad', 'cam_d', 'cam_disc_dia')
    param('cam_linkage_test_fixture.scad', 'cam_well_d', 'cam_d + 0.6')
    param('cam_linkage_test_fixture.scad', 'holder_under_z',
          'cam_seat_z + 2 + plate_under_z - cam_flat_z')
    # Cosine alternative: short acceleration blends with lower peak slope.
    param('braille_cam.scad', 'subdivisions_per_slice', '24')
    replace('braille_cam.scad', 'function s_curve(t) = (1 - cos(t * 180)) / 2;', '''
// Constant-slope middle with parabolic endpoint blends. Peak derivative 1/0.9
// versus PI/2 for cosine. This lowers pressure angle, not a proved speed increase.
blend_fraction=0.1;
function s_curve(t) =
    t < blend_fraction ? t*t/(2*blend_fraction*(1-blend_fraction)) :
    t > 1-blend_fraction ? 1-(1-t)*(1-t)/(2*blend_fraction*(1-blend_fraction)) :
    (t-blend_fraction/2)/(1-blend_fraction);
''')
    # Small FDM coupon is a cutout of the actual innermost guide, not a new fit.
    (SRC / 'guide_coupon.scad').write_text('''use <linkage_comb.scad>
intersection() {
    linkage_comb();
    translate([12,-4,0]) cube([15,8,5]);
}
''', encoding='utf-8')
    (SRC / 'hall_coupon.scad').write_text('''use <base_plate.scad>
intersection() { base_plate(); translate([-9,13,0]) cube([18,15,5]); }
''', encoding='utf-8')

    # Every input, including untouched dependencies, is pinned for review.
    (DEST / 'source_manifest.json').write_text(json.dumps({
        'status':'ENGINEERING CANDIDATE - NOT PRINT RELEASE',
        'source_sha256':hashes,
        'candidate_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in sorted(SRC.glob('*.scad'))},
        'outer_mm':[64,64,46.5],
        'spring_path':'0.20mm-wire baseline; owned 0.30mm springs NOT validated',
        'motor':'existing measured 28BYJ-48; no replacement purchased',
    }, indent=2), encoding='utf-8')
    print(DEST)


if __name__ == '__main__':
    main()
