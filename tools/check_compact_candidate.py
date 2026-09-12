"""Export/check the isolated compact candidate; record failures, never release G-code."""
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from tools.validate_print_assets import read_stl, mesh_stats

DEST=ROOT/'cad/candidates/compact_2026_09_09'
SCAD=Path('C:/Program Files/OpenSCAD (Nightly)/openscad.com')
PARTS=['outer_box','base_plate','top_plate','esp32_pod_shell','esp32_pod_lid',
       'braille_cam','linkage','linkage_comb','dot_insert','hall_retainer',
       'hall_coupon','guide_coupon','cam_linkage_test_fixture']


def export(name):
    source=name
    flags=[]
    if name.startswith('linkage_asm_'):
        source='export_linkage_assembly'
        flags=['-D',f'dot={int(name.rsplit("_",1)[1])}']
    output=DEST/'stl'/f'{name}.stl'
    backend='Manifold' if name=='braille_cam' else 'CGAL'
    run=subprocess.run([str(SCAD),f'--backend={backend}',*flags,'-o',str(output),
                        str(DEST/'scad'/f'{source}.scad')],capture_output=True,text=True,
                       timeout=240,encoding='utf-8',errors='replace')
    (DEST/'logs').mkdir(exist_ok=True)
    log=run.stdout+run.stderr
    (DEST/'logs'/f'{name}.txt').write_text(log,encoding='utf-8')
    if run.returncode or 'ERROR:' in log or 'WARNING:' in log:
        raise RuntimeError(f'{name}: {log[-1500:]}')
    stats=mesh_stats(read_stl(output))
    result={key:getattr(stats,key) for key in stats.__dataclass_fields__}
    result['size_mm']=[stats.bounds_max[i]-stats.bounds_min[i] for i in range(3)]
    result['sha256']=hashlib.sha256(output.read_bytes()).hexdigest()
    result['backend']=backend
    expected=6 if name=='linkage' else 2 if name=='cam_linkage_test_fixture' else 1
    if stats.boundary_edges or stats.nonmanifold_edges or stats.components!=expected:
        raise RuntimeError(f'{name}: unexpected topology {result}')
    print(f'{name}: {stats.components} bodies; {stats.volume_mm3:.2f} mm3; {result["size_mm"]}',flush=True)
    return name,result


def main():
    jobs=sys.argv[1:] or PARTS+[f'linkage_asm_{d}' for d in range(1,7)]
    previous=DEST/'mesh_checks.json'
    old=json.loads(previous.read_text(encoding='utf-8')) if sys.argv[1:] and previous.exists() else {}
    results={k:v for k,v in old.get('parts',{}).items() if k not in jobs}
    failures=[f for f in old.get('failures',[]) if not any(f.startswith(n+':') for n in jobs)]
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures={pool.submit(export,n):n for n in jobs}
        for future in as_completed(futures):
            try:
                name,result=future.result();results[name]=result
            except Exception as error:
                failure=f'{futures[future]}: {error}'
                failures.append(failure);print(failure,flush=True)
    report={'backend':'OpenSCAD nightly; per-part backend recorded','parts':results,'failures':failures,
            'physical_validation':'NOT PERFORMED','release':False}
    (DEST/'mesh_checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    return bool(failures)


if __name__=='__main__':
    raise SystemExit(main())
