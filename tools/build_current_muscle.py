"""Export the sole current SCAD set; old candidate builders are superseded."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1];C=R/'cad';S=C/'scad';T=C/'stl';V=C/'verification'
exe='C:/Program Files/OpenSCAD (Nightly)/openscad.com'
for n in ['braille_cam','base_plate','top_plate','outer_box','hall_retainer','linkage_comb','dot_insert','finger_sheet']+[f'arm_{i}' for i in range(1,7)]+['print_resin_1_muscle_cell']:
 r=subprocess.run([exe,'--backend=Manifold','--export-format','binstl','-o',str(T/(n+'.stl')),str(S/(n+'.scad'))],capture_output=True,text=True)
 (V/(n+'.log')).write_text(r.stdout+r.stderr)
 if 'ERROR:' in r.stderr or 'WARNING:' in r.stderr:raise RuntimeError(n+r.stderr)
 print(n,flush=True)
for t in ['0.72','0.88','1.04']:
 n='finger_sheet_t'+t.replace('.','')
 r=subprocess.run([exe,'--backend=Manifold','--export-format','binstl','-D','finger_t='+t,'-o',str(T/(n+'.stl')),str(S/'finger_sheet.scad')],capture_output=True,text=True)
 if 'ERROR:' in r.stderr or 'WARNING:' in r.stderr:raise RuntimeError(n+r.stderr)
 print(n,flush=True)
