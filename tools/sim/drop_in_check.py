"""Drop every part straight down into place, in assembly order. Any overlap with
parts already in the box on the way down means it cannot go in that way."""
import subprocess, numpy as np, trimesh, manifold3d as mf, os
R = "D:/TIET/Capstone/"; OSC = "C:/Program Files/OpenSCAD (Nightly)/openscad.com"
S = os.getcwd().replace("\\", "/") + "/"
def scad(code, out):
    open(S + "_w.scad", "w").write(f'use <{R}cad/scad/electronics_envelopes.scad>\n' + code)
    r = subprocess.run([OSC, "--backend=Manifold", "-o", S + out, S + "_w.scad"], capture_output=True, text=True)
    assert "ERROR" not in r.stderr, r.stderr
    return trimesh.load(S + out)
def M(t, dz=0.0):
    t = t.copy(); t.apply_translation([0, 0, dz])
    return mf.Manifold(mf.Mesh(vert_properties=np.asarray(t.vertices, np.float32), tri_verts=np.asarray(t.faces, np.uint32)))
L = lambda p, dz=0, mir=False: (lambda m: (m.apply_transform(np.diag([1,1,-1,1])) if mir else None, M(m, dz))[1])(trimesh.load(p))
st = R + "cad/stl/"
parts = [
 ("box",            L(st + "outer_box.stl")),
 ("ULN2003 board",  M(scad("driver_env();", "drv.stl"))),
 ("MCP23017 board", M(scad("mcp_env();", "mcp.stl"))),
 ("motor",          M(scad("motor_env();", "mot.stl"))),
 ("base plate + Hall retainer", L(st + "base_plate.stl", 41) + L(st + "hall_retainer.stl", 39.7)),
 ("cam",            L(st + "braille_cam.stl", 36.5)),
 ("comb",           L(st + "linkage_comb.stl", 45)),
] + [(f"arm {i}", L(R + f"cad/assets/assembled_arm_{i}.stl", 45)) for i in range(1, 7)] + [
 ("finger sheet",   L(st + "finger_sheet_t104.stl", 54, mir=True)),
 ("top plate",      L(st + "top_plate.stl", 54)),
 ("dot tile",       L(st + "dot_insert.stl", 54)),
]
placed = []
for name, p in parts:
    worst, at, hit = 0.0, None, None
    for t in np.arange(0.0, 60.01, 0.2):
        q = p.translate([0, 0, t])
        for on, o in placed:
            v = (q ^ o).volume()
            if v > worst + 1e-6: worst, at, hit = v, t, on
    tag = "OK" if worst < 1e-3 else f"BLOCKED by {hit}: {worst:.3f} mm3 when {at:.1f} mm above its seat"
    print(f"{name:28} {tag}", flush=True)
    placed.append((name, p))
