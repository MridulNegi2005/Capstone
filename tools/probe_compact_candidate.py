"""Independent assembly-intersection probes and 64-state profile checks."""
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import json
import math
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from tools.validate_print_assets import mesh_stats,read_stl
DEST=ROOT/'cad/candidates/compact_2026_09_09'
CHECKS=DEST/'checks'
EXE='C:/Program Files/OpenSCAD (Nightly)/openscad.com'

HEADER='''module part(n) { import(str("../stl/",n,".stl")); }
module base() { translate([0,0,29.5]) part("base_plate"); }
module comb() { translate([0,0,33.5]) part("linkage_comb"); }
module arms(h=0) { for(d=[1:6]) translate([0,0,33.5+h]) part(str("linkage_asm_",d)); }
module cam() { translate([0,0,31.5]) part("braille_cam"); }
module tile() { translate([0,0,42.5]) part("dot_insert"); }
module top() { translate([0,0,42.5]) part("top_plate"); }
module sensor() { translate([-2.05,17.35-1.55,29.0]) cube([4.1,3.1,1.6]); }
'''
PROBES={
 'cam_base':'intersection(){cam();base();}',
 'comb_base':'intersection(){comb();base();}',
 'comb_arms_down':'intersection(){comb();arms();}',
 'comb_arms_up':'intersection(){comb();arms(0.5);}',
 'arms_top_down':'intersection(){union(){top();tile();}arms();}',
 'arms_top_up':'intersection(){union(){top();tile();}arms(0.5);}',
 'base_shell':'intersection(){base();part("outer_box");}',
 'sensor_base':'intersection(){sensor();base();}',
 'retainer_base':'intersection(){translate([0,0,28.2])part("hall_retainer");base();}',
 'motor_shell':'intersection(){part("outer_box");translate([-7.5,0,4.001])cylinder(d=28.1,h=19,$fn=100);}',
 'pod_board_shell':'intersection(){part("esp32_pod_shell");translate([-27.75,-14,16.5])cube([51.5,28,1.6]);}',
 'hall_roof':'intersection(){base();translate([-0.5,16.85,30.8])cube([1,1,0.2]);}',
 'base_bolt_passages':'intersection(){base();for(x=[-24,24],y=[-21,21])translate([x,y,29.49])cylinder(d=2.8,h=5.02,$fn=32);}',
}


def probe(item):
    name,body=item
    source=CHECKS/f'{name}.scad'
    source.write_text(HEADER+body,encoding='utf-8')
    output=CHECKS/f'{name}.stl'
    if output.exists():
        output.unlink() # Only this script's disposable probe output, not any design file.
    run=subprocess.run([EXE,'--backend=Manifold','-o',str(output),str(source)],
                       capture_output=True,text=True,timeout=180)
    log=run.stdout+run.stderr
    (CHECKS/f'{name}.log').write_text(log,encoding='utf-8')
    empty='Current top level object is empty.' in log
    if not empty and (run.returncode or 'ERROR:' in log or not output.exists()):
        raise RuntimeError(name+': '+log[-1200:])
    volume=0.0 if empty else mesh_stats(read_stl(output)).volume_mm3
    passed=abs(volume-0.2)<0.0001 if name=='hall_roof' else abs(volume)<0.0001
    result={'intersection_mm3':volume,'pass':passed,
            'expected':'0.2mm3 roof material' if name=='hall_roof' else 'no solid overlap'}
    print(name,result,flush=True)
    return name,result


def main():
    CHECKS.mkdir(exist_ok=True)
    results={}
    failures=[]
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures=[pool.submit(probe,item) for item in PROBES.items()]
        for future in as_completed(futures):
            try:
                key,value=future.result();results[key]=value
            except Exception as error:
                failures.append(str(error));print(error,flush=True)
    source=CHECKS/'states.scad'
    source.write_text('''use <../scad/braille_cam.scad>
include <../scad/mech_layout.scad>
echo([for(i=[0:63]) [for(t=[0:5]) get_height_at_angle((i+0.5)*360/64+track_phase(t),t)-2]]);
''',encoding='utf-8')
    output=CHECKS/'states.echo'
    run=subprocess.run([EXE,'-o',str(output),str(source)],capture_output=True,text=True,timeout=30)
    if run.returncode:
        raise RuntimeError(run.stderr)
    rows=json.loads(output.read_text().strip().removeprefix('ECHO: '))
    expected=[[0.5*((i^(i>>1))>>(5-t)&1) for t in range(6)] for i in range(64)]
    state_pass=rows==expected
    radii=[14.8+1.7*t for t in range(6)]
    runs=[2*math.pi*r/64-(math.tan(math.radians(15))+0.3) for r in radii]
    slope_angles=[math.degrees(math.atan(0.5/(0.9*run))) for run in runs]
    report={'backend':'Manifold intersections of exported meshes','intersections':results,'errors':failures,
            'all_64_nominal_states_pass':state_pass,
            'calculated_peak_ramp_degrees':slope_angles,
            'limitations':['Endpoint insertion/motion checks do not prove loaded operation.',
                          'No actual springs, wiring, driver/expander carrier or docking connector solids tested.',
                          'No production release; physical tests outstanding.']}
    (DEST/'assembly_checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('64-state profile:',state_pass,flush=True)
    return bool(failures or not state_pass or any(not r['pass'] for r in results.values()))


if __name__=='__main__':
    raise SystemExit(main())
