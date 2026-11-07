from pathlib import Path
import bpy
from mathutils import Vector
C=Path('D:/TIET/Capstone/cad');bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
s=bpy.context.scene;s.render.engine='BLENDER_WORKBENCH';s.display.shading.light='STUDIO';s.display.shading.color_type='OBJECT';s.display.shading.show_shadows=False;s.display.shading.show_cavity=True;s.world.color=(.13,.15,.18);s.render.resolution_x=1500;s.render.resolution_y=1100;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG'
def part(n,c,loc=(0,0,0)):
 bpy.ops.wm.stl_import(filepath=str(C/'stl'/(n+'.stl')));o=bpy.context.object;o.name=n;o.color=(*c,1);o.location=loc;return o
def render(n,loc,target,scale):
 bpy.ops.object.camera_add(location=loc);c=bpy.context.object;c.rotation_euler=(Vector(target)-c.location).to_track_quat('-Z','Y').to_euler();c.data.type='ORTHO';c.data.ortho_scale=scale;s.camera=c;s.render.filepath=str(C/'images'/(n+'.png'));bpy.ops.render.render(write_still=True)
batch=part('print_resin_1_muscle_cell',(.65,.75,.9));render('01_one_cell_resin_batch',(56,5.001,230),(56,5,0),190);batch.hide_render=True
cam=part('braille_cam',(.94,.57,.15));render('02_cam_underside',(25,45,-55),(0,0,5),65)
bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=1.5,depth=1.5,location=(0,17.35,7.05));mag=bpy.context.object;mag.name='Magnet 3x1.5 worst-case 0.1 glue';mag.color=(.85,.15,.12,1)
render('03_magnet_seated_underside',(14,35,-18),(0,17.35,6.8),15)
mag.hide_render=True;cam.location.z=36.5
base=part('base_plate',(.55,.65,.75),(0,0,41));comb=part('linkage_comb',(.3,.75,.6),(0,0,68));cam.location.z=51;top=part('top_plate',(.65,.7,.78),(0,0,92));render('04_exploded_mechanism',(110,-130,120),(0,0,62),165)
bpy.ops.wm.save_as_mainfile(filepath=str(C/'current_review.blend'))
