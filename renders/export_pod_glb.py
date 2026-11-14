"""Export the ESP32 brain pod's REAL printed geometry to sim/3d/pod.glb.

The simulator used to draw the pod as five slabs, which was close enough for a
silhouette but showed none of the features that matter: the USB service opening,
the pogo recess, the antenna grille, the magnet pockets, the screw bosses. Those
are the parts a viewer actually wants to look at, and they already exist in the
CAD, so approximating them was pointless.

Object names shipped: pod_shell, pod_lid. sim/3d/app.js depends on both.
Placement matches esp32_pod_assembly.scad — the lid sits at pod_height - lid_h.

    blender --background --factory-startup --python renders/export_pod_glb.py
"""
import bpy
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STL = os.path.join(ROOT, "cad", "stl")
SCAD = os.path.join(ROOT, "cad", "scad")
OPENSCAD = r"C:\Program Files\OpenSCAD (Nightly)\openscad.com"
OUT = os.path.join(ROOT, "sim", "3d", "pod.glb")

# The lid sits on the shell's wall top, so it is placed by the shell's own
# height rather than a copied pod_height - that literal was 46.5 here while the
# CAD moved underneath it.
PARTS = {                      # name: (z rule, hex colour, metal, rough)
    "esp32_pod_shell": (0.0, "5A6B7C", 0.05, 0.75),
    "esp32_pod_lid": ("on_shell", "6E7A88", 0.05, 0.72),
}
RENAME = {"esp32_pod_shell": "pod_shell", "esp32_pod_lid": "pod_lid"}


def rgba(hx, a=1.0):
    return (*(int(hx[i:i + 2], 16) / 255 for i in (0, 2, 4)), a)


def material(name, hx, metal, rough):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = rgba(hx)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    return m


def source(name):
    """cad/stl holds only the current muscle cell, so the pod meshes are rendered
    from their SCAD. The brain was not re-released with the tall cell; this is
    whatever its CAD currently says."""
    path = os.path.join(STL, name + ".stl")
    if os.path.exists(path):
        return path
    if not os.path.exists(OPENSCAD):
        sys.exit(f"missing {path} and OpenSCAD is not at {OPENSCAD}")
    out = os.path.join(tempfile.mkdtemp(), name + ".stl")
    run = subprocess.run([OPENSCAD, "--backend=Manifold", "--export-format", "binstl",
                          "-o", out, os.path.join(SCAD, name + ".scad")],
                         capture_output=True, text=True)
    if not os.path.exists(out):
        sys.exit(f"{name} render failed:\n{run.stderr[-1500:]}")
    return out


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)

    built, shell_top = [], None
    for name, (z, hx, metal, rough) in PARTS.items():
        path = source(name)
        bpy.ops.wm.stl_import(filepath=path, global_scale=1.0)   # millimetres
        o = bpy.context.selected_objects[0]
        o.name = RENAME[name]
        if z == "on_shell":
            z = shell_top
        o.location.z += z
        if name == "esp32_pod_shell":
            shell_top = max(v.co.z for v in o.data.vertices)
        o.data.materials.clear()
        o.data.materials.append(material("mat_" + o.name, hx, metal, rough))
        # left flat-shaded on purpose: this is a printed box, and smoothing the
        # normals smears the 3mm corner fillets into the walls so it stops reading
        # as plastic. (Blender 4.1 removed use_auto_smooth, so there is no cheap
        # angle-based middle ground here anyway.)
        built.append(o.name)

    bpy.ops.export_scene.gltf(
        filepath=OUT, export_format='GLB',
        export_apply=True, export_yup=False,      # keep Z-up, matching the CAD
    )

    tris = sum(len(bpy.data.objects[n].data.loop_triangles) or
               len(bpy.data.objects[n].data.polygons) for n in built)
    print(f"\nwrote {OUT}")
    print(f"  shell top {shell_top:.2f}, lid on it")
    print(f"  objects: {built}")
    print(f"  size   : {os.path.getsize(OUT) / 1024:.0f} KB")


main()
