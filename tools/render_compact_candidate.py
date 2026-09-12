"""Run with Blender --background --factory-startup --python this_file.

Views use actual candidate STL geometry in millimetres. Motor can is a labelled
envelope only; wiring and populated electronics are deliberately not inferred.
"""
from pathlib import Path
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'cad/candidates/compact_2026_09_09'
OUT=DEST/'blender'
OUT.mkdir(exist_ok=True)
COLORS={'shell':(0.14,0.28,0.34,1),'lid':(0.34,0.57,0.62,1),
        'base':(0.44,0.49,0.53,1),'cam':(0.95,0.54,0.16,1),
        'guide':(0.30,0.65,0.51,1),'arm':(0.87,0.88,0.84,1)}

def part(name,xyz,color,label=None):
    bpy.ops.wm.stl_import(filepath=str(DEST/'stl'/f'{name}.stl'))
    obj=bpy.context.object
    obj.name=label or name
    obj.location=xyz
    obj.color=COLORS[color]
    return obj

def setup():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    scene=bpy.context.scene
    scene.unit_settings.system='METRIC'
    scene.unit_settings.scale_length=0.001
    scene.unit_settings.length_unit='MILLIMETERS'
    scene.render.engine='BLENDER_WORKBENCH'
    scene.display.shading.light='STUDIO'
    scene.display.shading.color_type='OBJECT'
    scene.display.shading.show_shadows=True
    scene.display.shading.show_cavity=True
    scene.display.shading.cavity_type='BOTH'
    scene.display.shading.background_type='WORLD'
    scene.world.color=(0.055,0.065,0.075)
    scene.render.resolution_x=1400
    scene.render.resolution_y=1000
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    scene.view_settings.view_transform='Standard'
    return scene

def camera(scene,target,location,scale):
    bpy.ops.object.camera_add(location=location)
    cam=bpy.context.object
    cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO'
    cam.data.ortho_scale=scale
    cam.data.clip_end=2000
    scene.camera=cam

def save(scene,name):
    scene['status']='ENGINEERING CANDIDATE; physical fit and electronics not validated'
    scene['geometry']='Candidate OpenSCAD exports; numeric coordinates mm, scene scale 0.001'
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'{name}.blend'))
    scene.render.filepath=str(OUT/f'{name}.png')
    bpy.ops.render.render(write_still=True)

scene=setup()
part('esp32_pod_shell',(-36,0,0),'shell','Brain shell - candidate 64 mm')
part('esp32_pod_lid',(-36,0,42.5),'lid')
part('outer_box',(36,0,0),'shell','Muscle shell - candidate 64 mm')
part('top_plate',(36,0,42.5),'lid')
part('dot_insert',(36,0,42.5),'arm')
for d in range(1,7):part(f'linkage_asm_{d}',(36,0,33.5),'arm')
camera(scene,(0,0,22),(145,-200,175),190)
save(scene,'matching_enclosures')

scene=setup()
part('outer_box',(0,0,0),'shell')
part('base_plate',(0,0,51),'base')
part('braille_cam',(0,0,81),'cam')
part('linkage_comb',(0,0,108),'guide')
for d in range(1,7):part(f'linkage_asm_{d}',(0,0,124),'arm')
part('top_plate',(0,0,154),'lid')
part('dot_insert',(0,0,166),'arm')
part('hall_retainer',(42,0,51),'cam','Underside Hall retainer - separated for visibility')
camera(scene,(0,0,85),(165,-220,200),305)
scene['view_note']='Exploded Z spacing is illustrative, not assembly datums. See assembly_checks.json.'
save(scene,'exploded_mechanism')
