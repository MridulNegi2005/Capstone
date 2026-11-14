#!/usr/bin/env python
"""
export_glb.py — turn the Braillix STLs into one web-ready model for the 3D simulator.

    "C:\\Program Files\\Blender Foundation\\Blender 5.1\\blender.exe" ^
        --background --factory-startup --python renders/export_glb.py

Output: sim/3d/braillix.glb

WHY BLENDER IS ONLY THE ASSET PIPELINE HERE
The simulator needs orbit/pan/zoom, an X-ray toggle and a kinematics toggle. Blender
renders a fixed video and cannot do any of that, so the interactive part is a Three.js
app. Blender's job is just to assemble the STLs onto the real z-stack, name the parts,
and emit a single GLB the browser can load.

UNITS ARE MILLIMETRES. 1 Blender unit = 1 mm, deliberately: every number in
sim/braillix_params.json is in mm, so the web app can use them directly with no
conversion. Nothing is rendered here, so the usual "work in metres" advice does not
apply.

OBJECT NAMES ARE AN API. The web app looks parts up by name — outer_box, top_plate,
dot_insert, base_plate, cam, comb, linkage_1..6, hall_retainer, finger_sheet,
motor_body, motor_shaft, motor_ear_l, motor_ear_r. Renaming anything here breaks
sim/3d/app.js.
"""
import bpy
import json
import math
import os
import subprocess
import sys
import tempfile

ROOT = r"D:\TIET\Capstone"
STL = os.path.join(ROOT, "cad", "stl")
ASSETS = os.path.join(ROOT, "cad", "assets")
SCAD = os.path.join(ROOT, "cad", "scad")
OPENSCAD = r"C:\Program Files\OpenSCAD (Nightly)\openscad.com"
OUT_DIR = os.path.join(ROOT, "sim", "3d")
OUT = os.path.join(OUT_DIR, "braillix.glb")

# Placements are DERIVED from the same JSON the simulator reads, never typed.
# The tall box moved the whole tower up 11.5mm; a literal here would have been
# silently wrong, which is exactly the failure this project keeps hitting.
with open(os.path.join(ROOT, "sim", "braillix_params.json"), encoding="utf-8") as _f:
    _P = json.load(_f)
CAM_FLAT_Z = _P["stack"]["cam_flat_z"]          # 45.0  cam surface, dot DOWN
PLATE_UNDER_Z = _P["stack"]["plate_under_z"]    # 54.0  top plate underside
BASE_PLATE_Z = _P["stack"]["base_plate_z"]      # 41.0  outer_box.scad
TALL_RAISE = _P["stack"]["tall_raise"]          # 11.5  old 46.5 frame -> 58 box
PIN_LIFT = _P["cam"]["pin_lift"]                # 0.5

# The cam, the six arms and the light comb are exact meshes of the resin parts
# already printed (cad/assets), so the assembly uses those. cad/stl/arm_N.stl is
# the FLAT print layout - useless here - while assets/assembled_arm_N.stl keeps
# the old convention that Z=0 is the cam surface.
# name -> (source path, z rule, hex colour, alpha, metallic, roughness)
PARTS = {
    "outer_box":     (os.path.join(STL, "outer_box.stl"),   0.0,           "5A6B7C", 1.00, 0.05, 0.75),
    "base_plate":    (os.path.join(STL, "base_plate.stl"),  BASE_PLATE_Z,  "6E6E6E", 1.00, 0.10, 0.85),
    "top_plate":     (os.path.join(STL, "top_plate.stl"),   PLATE_UNDER_Z, "EDE6D6", 1.00, 0.05, 0.70),
    "dot_insert":    (os.path.join(STL, "dot_insert.stl"),  PLATE_UNDER_Z, "FAFAFA", 1.00, 0.05, 0.35),
    "comb":          (os.path.join(ASSETS, "linkage_comb_light_2026-10-24.stl"),
                      CAM_FLAT_Z, "9AA3B2", 1.00, 0.05, 0.60),
    # The resin cam's track tops are at cam_flat + lift, whatever origin the mesh
    # was exported with - the constant that used to locate it (disc thickness)
    # went with the parametric cam. So the cam is placed by its own top surface.
    "cam":           (os.path.join(STL, "braille_cam.stl"), "top_at_lift", "E94560", 1.00, 0.35, 0.35),
    # The Hall retainer screws up under the base plate.
    "hall_retainer": (os.path.join(STL, "hall_retainer.stl"), "top_at_base", "6E6E6E", 1.00, 0.05, 0.75),
}
LINKAGE_MAT = ("C8CDD4", 1.00, 0.90, 0.25)   # shiny metal, as specified

# 28BYJ-48, in the tall-box frame (electronics_envelopes.scad motor_env). The
# web app swaps these for motor.glb; they stay correct in case it is missing.
MOTOR = dict(dia=28.1, height=19.0, x_offset=-7.5, boss_h=2.0,
             shaft_dia=5.0, shaft_len=7.5, ear_span=34.7, ear_w=7.0, ear_t=1.0)


def rgba(hx, a=1.0):
    return (*(int(hx[i:i + 2], 16) / 255 for i in (0, 2, 4)), a)


def material(name, hx, alpha=1.0, metal=0.0, rough=0.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = rgba(hx)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
        m.blend_method = 'BLEND'
    return m


def import_stl(path, name):
    """Import and FAIL LOUDLY if missing.

    renders/build_assembly_scene.py silently skipped absent STLs, which is how it kept
    'working' long after braille_cam2.stl and linkage_comb.stl ceased to exist.
    """
    if not os.path.exists(path):
        sys.exit(f"MISSING STL: {path}\n  Rebuild with: python tools/build_current_muscle.py")
    before = set(bpy.data.objects)
    bpy.ops.wm.stl_import(filepath=path, global_scale=1.0)   # keep millimetres
    new = set(bpy.data.objects) - before
    if len(new) != 1:
        sys.exit(f"expected 1 object from {path}, got {len(new)}")
    obj = new.pop()
    obj.name = name
    obj.data.name = name + "_mesh"
    return obj


def z_extent(o):
    zs = [(o.matrix_world @ v.co).z for v in o.data.vertices]
    return min(zs), max(zs)


def finger_sheet():
    """The printed return-spring sheet that replaced the six coil springs.

    cad/stl/finger_sheet.stl is its flat PRINT layout, ridges up, so it cannot be
    placed. finger_sheet() builds it in the assembled frame - but the 46.5mm one,
    since mech_layout.scad still describes that stack - so render the module and
    lift it by the tall-box raise, exactly as tools/make_viewer.py does.
    """
    if not os.path.exists(OPENSCAD):
        sys.exit(f"MISSING OpenSCAD: {OPENSCAD} (needed to render the finger sheet)")
    tmp = tempfile.mkdtemp()
    src, out = os.path.join(tmp, "sheet.scad"), os.path.join(tmp, "sheet.stl")
    sc = SCAD.replace("\\", "/")
    with open(src, "w", encoding="utf-8") as f:
        f.write(f"use <{sc}/finger_sheet.scad>\ninclude <{sc}/mech_layout.scad>\nfinger_sheet();\n")
    run = subprocess.run([OPENSCAD, "--backend=Manifold", "--export-format", "binstl",
                          "-o", out, src], capture_output=True, text=True)
    if not os.path.exists(out):
        sys.exit(f"finger sheet render failed:\n{run.stderr[-1500:]}")
    o = import_stl(out, "finger_sheet")
    o.location = (0, 0, TALL_RAISE)
    return o


def add_motor(z_top):
    """Indicative 28BYJ-48 so the X-ray view shows what drives the cam.

    There is no motor STL in the repo. renders/add_hardware_models.py builds one, but
    against the stale v5 z-stack, so the geometry idea is reused and the heights are
    re-derived from BASE_PLATE_Z here.
    """
    made = []
    body_mat = material("mat_motor", "9BA3AA", 1.0, 0.85, 0.30)
    shaft_mat = material("mat_shaft", "D8DDE2", 1.0, 0.95, 0.15)
    cx = MOTOR["x_offset"]

    bpy.ops.mesh.primitive_cylinder_add(
        radius=MOTOR["dia"] / 2, depth=MOTOR["height"], vertices=48,
        location=(cx, 0, z_top - MOTOR["height"] / 2))
    b = bpy.context.object
    b.name = "motor_body"
    b.data.materials.append(body_mat)
    made.append(b)

    # shaft rises from the motor face into the cam bore (x=0 — NOT the body centre;
    # the 28BYJ-48 shaft is offset ~8mm, which is why the body sits at x=-8)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=MOTOR["shaft_dia"] / 2, depth=MOTOR["shaft_len"], vertices=24,
        location=(0, 0, z_top + MOTOR["boss_h"] + MOTOR["shaft_len"] / 2))
    s = bpy.context.object
    s.name = "motor_shaft"
    s.data.materials.append(shaft_mat)
    made.append(s)

    for sign, nm in ((-1, "motor_ear_l"), (1, "motor_ear_r")):
        bpy.ops.mesh.primitive_cube_add(
            size=1, location=(cx + sign * MOTOR["ear_span"] / 2, 0,
                              z_top - MOTOR["ear_t"] / 2))
        e = bpy.context.object
        e.name = nm
        e.scale = (MOTOR["ear_w"], MOTOR["ear_w"], MOTOR["ear_t"])
        e.data.materials.append(body_mat)
        made.append(e)
    return made


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    built = []

    for name, (path, rule, hx, alpha, metal, rough) in PARTS.items():
        o = import_stl(path, name)
        if rule == "top_at_lift":
            o.location = (0, 0, CAM_FLAT_Z + PIN_LIFT - z_extent(o)[1])
        elif rule == "top_at_base":
            o.location = (0, 0, BASE_PLATE_Z - z_extent(o)[1])
        else:
            o.location = (0, 0, rule)
        bpy.context.view_layer.update()
        o.data.materials.append(material(f"mat_{o.name}", hx, alpha, metal, rough))
        built.append(o)

    sheet = finger_sheet()
    sheet.data.materials.append(material("mat_finger_sheet", "F07A2A", 1.0, 0.0, 0.7))
    built.append(sheet)

    hx, alpha, metal, rough = LINKAGE_MAT
    link_mat = material("mat_linkage", hx, alpha, metal, rough)
    for d in range(1, 7):
        o = import_stl(os.path.join(ASSETS, f"assembled_arm_{d}.stl"), f"linkage_{d}")
        # the mesh already carries its assembly XY; Z=0 in it is the cam surface,
        # so parking it at cam_flat_z puts every dot in its DOWN state
        o.location = (0, 0, CAM_FLAT_Z)
        o.data.materials.append(link_mat)
        built.append(o)

    # the motor's shaft boss seats on the bottom of the cam hub
    bpy.context.view_layer.update()
    cam = next(o for o in built if o.name == "cam")
    built += add_motor(z_extent(cam)[0] - MOTOR["boss_h"])

    for o in built:
        o.select_set(True)
    bpy.context.view_layer.objects.active = built[0]

    os.makedirs(OUT_DIR, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=OUT, export_format='GLB', use_selection=True,
        export_apply=True, export_yup=False,   # keep Z-up; the app matches the CAD
        export_materials='EXPORT', export_cameras=False, export_lights=False)

    names = sorted(o.name for o in built)
    tris = sum(len(o.data.polygons) for o in built if o.type == 'MESH')
    print("\n=== GLB export ===")
    print(f"  objects  {len(built)}")
    print(f"  names    {names}")
    print(f"  polys    {tris}")
    print(f"  size     {os.path.getsize(OUT)/1e6:.2f} MB")
    print(f"  output   {OUT}\n")

    required = {"outer_box", "top_plate", "dot_insert", "base_plate", "comb",
                "cam", "hall_retainer", "finger_sheet", "motor_body", "motor_shaft"
                } | {f"linkage_{d}" for d in range(1, 7)}
    missing = required - set(names)
    if missing:
        sys.exit(f"FAIL: GLB is missing required objects: {sorted(missing)}")
    print("  all required object names present   OK")


if __name__ == "__main__":
    main()
