"""Build renders/assembly_viewer.html: one standalone page that shows the assembled
muscle cell from the current STLs. Every part can be shown, hidden or made
transparent; sliders step through the assembly, explode it, cut it open and turn
the cam (the arms and tongues follow the real cam profile)."""
from pathlib import Path
import base64, json, subprocess, tempfile, numpy as np, trimesh

R = Path(__file__).resolve().parents[1]
C, S, A = R / "cad", R / "cad/stl", R / "cad/assets"
OSC = "C:/Program Files/OpenSCAD (Nightly)/openscad.com"
T = Path(tempfile.mkdtemp())

def scad(code, name):
    f = T / (name + ".scad"); f.write_text(code); o = T / (name + ".stl")
    r = subprocess.run([OSC, "--backend=Manifold", "--export-format", "binstl", "-o", str(o), str(f)], capture_output=True, text=True)
    assert o.exists(), r.stderr
    return o

sc = (C / "scad").as_posix()
env = f"use <{sc}/electronics_envelopes.scad>\n"
sheet = f"""use <{sc}/finger_sheet.scad>
include <{sc}/mech_layout.scad>
dz = 54 - plate_under_z;
module cutter(d) {{ t = finger_tip(d); u = finger_axis(d); n = [-u[1], u[0]] * (finger_w + 0.4) / 2;
  p0 = t - u * 1.5; p1 = t + u * finger_len;
  translate([0,0,-50]) linear_extrude(200) polygon([p0 + n, p1 + n, p1 - n, p0 - n]); }}
"""
pf = T / "pivots.scad"
pf.write_text(sheet + "".join(f'echo(str("P,",finger_tip({d})[0],",",finger_tip({d})[1],",",finger_axis({d})[0],",",finger_axis({d})[1],",",finger_len));\n' for d in range(1, 7)) + "cube(1);")
out = subprocess.run([OSC, "-o", str(T / "pivots.echo"), str(pf)], capture_output=True, text=True)
echo = (T / "pivots.echo").read_text() if (T / "pivots.echo").exists() else ""
pivots = [[float(v) for v in l.split('"')[1].split(",")[1:]] for l in (echo + out.stdout + out.stderr).splitlines() if '"P,' in l]
assert len(pivots) == 6, out.stderr

# name, file, z, colour, group, default opacity
parts = [
    ("Box", S / "outer_box.stl", 0, "#d8c27a", "PETG", 0.35),
    ("Motor 28BYJ-48 (bought)", scad(env + "motor_env();", "motor"), 0, "#9aa0a8", "Bought", 1),
    ("ULN2003 driver (bought, 35x32 assumed)", scad(env + "driver_env();", "drv"), 0, "#2e9e5b", "Bought", 1),
    ("MCP23017 board (bought)", scad(env + "mcp_env();", "mcp"), 0, "#3b6fd6", "Bought", 1),
    ("Hall sensor A3144 (bought)", scad("translate([-2.05,17.35-1.55,40.6]) cube([4.1,3.1,1.6]);", "hall"), 0, "#222222", "Bought", 1),
    ("Hall retainer", S / "hall_retainer.stl", 39.7, "#8a4fd0", "PETG", 1),
    ("Base plate", S / "base_plate.stl", 41, "#e3cf8c", "PETG", 1),
    ("Cam", S / "braille_cam.stl", 36.5, "#2a2d33", "Resin", 1),
    ("Comb (light)", A / "linkage_comb_light_2026-10-24.stl", 45, "#a7adb6", "Resin", 0.6),
] + [(f"Arm {i} (dot {i})", A / f"assembled_arm_{i}.stl", 45, "#2f6fd0", "Resin", 1) for i in range(1, 7)] + [
    ("Finger sheet frame (0.8)", scad(sheet + "translate([0,0,dz]) difference(){ finger_sheet(); for(d=[1:6]) cutter(d); }", "frame"), 0, "#f07a2a", "PETG", 0.7),
] + [(f"Finger tongue {d}", scad(sheet + f"translate([0,0,dz]) intersection(){{ finger_sheet(); cutter({d}); }}", f"tongue{d}"), 0, "#f06a10", "PETG", 1) for d in range(1, 7)] + [
    ("Top plate", S / "top_plate.stl", 54, "#eef0f3", "PETG", 0.35),
    ("Dot tile", S / "dot_insert.stl", 54, "#c9ccd2", "Resin", 1),
]

prof = np.load(R / "tools/sim/cam_profile.npy")
n = prof.shape[1]; step = max(1, n // 720)
data = {
    "parts": [{"name": p[0], "stl": base64.b64encode(Path(p[1]).read_bytes()).decode(), "z": p[2], "color": p[3],
               "group": p[4], "opacity": p[5]} for p in parts],
    "profile": np.round(prof[:, ::step], 4).tolist(),
    "track": [2, 3, 4, 1, 0, 5], "phase": [120, 180, 240, 60, 0, 300], "pivots": pivots,
}
html = (Path(__file__).parent / "viewer_template.html").read_text(encoding="utf-8").replace("/*DATA*/null", json.dumps(data))
out = R / "renders/assembly_viewer.html"; out.write_text(html, encoding="utf-8")
print("wrote", out, round(out.stat().st_size / 1e6, 1), "MB,", len(parts), "parts")
