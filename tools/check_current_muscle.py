from pathlib import Path
import subprocess,json,trimesh,hashlib
from concurrent.futures import ThreadPoolExecutor
R=Path.cwd();C=R/'cad';V=C/'verification';exe='C:/Program Files/OpenSCAD (Nightly)/openscad.com'
h='''module part(n){import(str("../stl/",n,".stl"));}
module shell(){part("outer_box");}
module base(){translate([0,0,41])part("base_plate");}
module cam(){translate([0,0,36.5])part("braille_cam");}
module comb(){translate([0,0,45])part("linkage_comb");}
module top(){translate([0,0,54])part("top_plate");}
module tile(){translate([0,0,54])part("dot_insert");}
module arms(h=0){for(i=[1:6])translate([0,0,45+h])import(str("../assets/assembled_arm_",i,".stl"));}
use <../scad/finger_sheet.scad>
module sheet(v="finger_sheet"){translate([0,0,54])mirror([0,0,1])part(v);}
module tongues_up(v,lift){translate([0,0,lift])intersection(){sheet(v);translate([0,0,40])linear_extrude(14.01)finger_relief2d(0);}}
module sheet_flat(v="finger_sheet"){intersection(){sheet(v);translate([-40,-40,54-1.04-0.001])cube([80,80,1.2]);}}
module heads(){for(x=[-19,19],y=[-19,19])translate([x,y,48.3]){cylinder(d=5,h=.5,$fn=48);translate([0,0,.5])cylinder(d=4,h=2,$fn=48);}}
use <../scad/electronics_envelopes.scad>
module sled(){part("electronics_sled");}
module others(){union(){shell();base();cam();translate([0,0,39.7])part("hall_retainer");}}
module magnet_sweep(){translate([0,0,42.8])difference(){cylinder(r=18.85,h=1.5,$fn=192);translate([0,0,-.01])cylinder(r=15.85,h=1.52,$fn=192);}}
'''
(C/'verification/assembly.scad').write_text(h)
probes={'cam_base':'cam();base();','cam_comb':'cam();comb();','tile_top':'tile();top();','base_shell':'base();shell();','comb_base':'comb();base();','heads_top':'heads();union(){top();tile();}','heads_base':'heads();base();','retainer_base':'translate([0,0,39.7])part("hall_retainer");base();','magnet_sweep_base':'magnet_sweep();base();','magnet_sweep_comb':'magnet_sweep();comb();'}
for z in [0,.25,.5]:
 for n,b in [('comb','comb();'),('top_tile','union(){top();tile();}'),('heads','heads();')]:probes[n+'_arms_'+str(z)]=b+f'arms({z});'
for v in ['finger_sheet_t072','finger_sheet_t088','finger_sheet_t104']:
 probes.update({f'{v}_top_tile':f'sheet("{v}");union(){{top();tile();}}',f'{v}_base':f'sheet("{v}");base();',f'{v}_comb':f'sheet("{v}");comb();',f'{v}_heads':f'sheet("{v}");heads();',f'{v}_tongues_up_0.95':f'tongues_up("{v}",0.95);union(){{top();tile();}}'})
 for z in [0,.25,.5]:probes[f'{v}_flat_arms_{z}']=f'sheet_flat("{v}");arms({z});'
probes.update({'sled_shell':'sled();shell();','sled_motor':'sled();motor_env();','driver_others':'driver_env();others();','driver_motor':'driver_env();motor_env();','driver_sled':'driver_env();sled();','mcp_others':'mcp_env();others();','mcp_motor':'mcp_env();motor_env();','mcp_sled':'mcp_env();sled();','mcp_driver':'mcp_env();driver_env();','motor_shell':'motor_env();shell();','motor_base':'motor_env();base();','motor_cam':'motor_env();cam();'})
def check(item):
 n,b=item;p=V/(n+'.scad');p.write_text(h+'intersection(){'+b+'}');o=V/(n+'.stl');r=subprocess.run([exe,'--backend=Manifold','-o',str(o),str(p)],capture_output=True,text=True);(V/(n+'.log')).write_text(r.stderr)
 if 'ERROR:' in r.stderr or 'WARNING:' in r.stderr:raise RuntimeError(r.stderr)
 vol=abs(trimesh.load(o).volume) if o.exists() else 0
 print(n,vol,flush=True);return n,float(vol)
with ThreadPoolExecutor(max_workers=3) as pool:results=dict(pool.map(check,probes.items()))
meshes={}
for p in (C/'stl').glob('*.stl'):
 m=trimesh.load(p);meshes[p.name]={'watertight':bool(m.is_watertight),'consistent_winding':bool(m.is_winding_consistent),'components':len(m.split()),'bounds':m.bounds.tolist(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(V/'results.json').write_text(json.dumps({'overlap_volumes_mm3':results,'meshes':meshes},indent=2))
assert all(v<.001 for v in results.values()),results
assert meshes['print_resin_1_muscle_cell.stl']['components']==9,meshes
assert all(v['watertight'] for v in meshes.values())
print('ALL PASS')
