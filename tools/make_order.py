"""Copy the parts to order into order/resin and order/petg, one STL per part, and
write order/MANIFEST.json with sizes, volumes and SHA-256 sums. Run after
build_current_muscle.py and check_current_muscle.py both pass."""
from pathlib import Path
import hashlib, json, shutil, trimesh

R = Path(__file__).resolve().parents[1]
S, A, O = R / "cad/stl", R / "cad/assets", R / "order"

RESIN = [("cam.stl", S / "braille_cam.stl", 1),
         ("comb_light.stl", A / "linkage_comb_light_2026-10-24.stl", 1),
         ("dot_tile.stl", S / "dot_insert.stl", 1)] + \
        [(f"arm_{i}.stl", S / f"arm_{i}.stl", 1) for i in range(1, 7)]
PETG = [("box.stl", S / "outer_box.stl", 1),
        ("base_plate.stl", S / "base_plate.stl", 1),
        ("top_plate.stl", S / "top_plate.stl", 1),
        ("hall_retainer.stl", S / "hall_retainer.stl", 2),
        ("finger_sheet_072_soft.stl", S / "finger_sheet_t072.stl", 1),
        ("finger_sheet_088_normal.stl", S / "finger_sheet_t088.stl", 2),
        ("finger_sheet_104_stiff.stl", S / "finger_sheet_t104.stl", 1)]

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
print(json.dumps(manifest, indent=1))
