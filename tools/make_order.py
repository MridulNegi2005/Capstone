"""Copy the parts to order into order/resin and order/petg, one STL per part, and
write order/MANIFEST.json with sizes, volumes and SHA-256 sums. Run after
build_current_muscle.py and check_current_muscle.py both pass."""
from pathlib import Path
import hashlib, json, shutil, trimesh

R = Path(__file__).resolve().parents[1]
S, A, O = R / "cad/stl", R / "cad/assets", R / "order"
T = Path(__import__("tempfile").mkdtemp())
for b, n in zip(sorted(trimesh.load(S / "nav_cap.stl").split(), key=lambda m: m.bounds[0][0]), ("prev", "select", "next")):
    b.export(T / f"nav_button_{n}.stl")

RESIN = [("cam.stl", S / "braille_cam.stl", 2),
         ("comb_light.stl", A / "linkage_comb_light_2026-10-24.stl", 2),
         ("dot_tile.stl", S / "dot_insert.stl", 2)] + \
        [(f"arm_{i}.stl", S / f"arm_{i}.stl", 2) for i in range(1, 7)] + \
        [(f"nav_button_{n}.stl", T / f"nav_button_{n}.stl", 2) for n in ("prev", "select", "next")]
PETG = [("box.stl", S / "outer_box.stl", 1),
        ("base_plate.stl", S / "base_plate.stl", 1),
        ("top_plate.stl", S / "top_plate.stl", 1),
        ("hall_retainer.stl", S / "hall_retainer.stl", 2),
        ("finger_sheet_080_normal.stl", S / "finger_sheet_t080.stl", 2),
        ("finger_sheet_100_stiff.stl", S / "finger_sheet_t100.stl", 2),
        ("brain_pod_shell.stl", S / "esp32_pod_shell.stl", 1),
        ("brain_pod_lid.stl", S / "esp32_pod_lid.stl", 1)]

manifest = {}
for group, items in (("resin", RESIN), ("petg", PETG)):
    d = O / group
    if d.exists():
        shutil.rmtree(d)
    d.mkdir(parents=True)
    for name, src, qty in items:
        shutil.copyfile(src, d / name)
        m = trimesh.load(d / name)
        assert m.is_watertight and len(m.split()) == 1, name
        manifest[f"{group}/{name}"] = {
            "quantity": qty,
            "size_mm": [round(float(v), 2) for v in m.extents],
            "volume_cm3": round(float(m.volume) / 1000, 2),
            "sha256": hashlib.sha256((d / name).read_bytes()).hexdigest(),
        }
(O / "MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
# One upload file for the resin service: every resin body at its order quantity, flat, 4 mm apart.
parts = []
for name, src, qty in RESIN:
    m = trimesh.load(src); m.apply_translation(-m.bounds[0])
    parts += [(name, m.copy()) for _ in range(qty)]
parts.sort(key=lambda p: -p[1].extents[1])
x = y = row_h = 0.0; placed = []
for name, m in parts:
    if x + m.extents[0] > 118:
        x, y, row_h = 0.0, y + row_h + 4.0, 0.0
    m.apply_translation([x, y, 0]); placed.append(m)
    x += m.extents[0] + 4.0; row_h = max(row_h, m.extents[1])
allin = trimesh.util.concatenate(placed)
allin.export(O / "resin_all_in_one.stl")
bodies = allin.split(only_watertight=True)
assert len(bodies) == len(parts), (len(bodies), len(parts))
manifest["resin_all_in_one.stl"] = {"bodies": len(parts), "size_mm": [round(float(v), 2) for v in allin.extents],
    "volume_cm3": round(float(allin.volume) / 1000, 2), "sha256": hashlib.sha256((O / "resin_all_in_one.stl").read_bytes()).hexdigest()}
(O / "MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest, indent=1))
