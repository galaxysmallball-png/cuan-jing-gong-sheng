import bpy
import math
from mathutils import Euler

for image in bpy.data.images:
    if image.type == 'IMAGE' and image.has_data:
        image.pack()
armature = bpy.data.objects['Deng_Armature']
armature.show_in_front = False
armature.data.display_type = 'STICK'
bpy.ops.object.select_all(action='DESELECT')
mesh = bpy.data.objects['Deng_CharacterMesh']
mesh.select_set(True)
bpy.context.view_layer.objects.active = mesh
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            space = area.spaces.active
            space.shading.type = 'MATERIAL'
            space.region_3d.view_location = (0,0,0.9)
            space.region_3d.view_distance = 3.1
            space.region_3d.view_rotation = Euler((math.radians(82),0,math.radians(12))).to_quaternion()
if hasattr(bpy.context.preferences.filepaths,'file_preview_type'):
    bpy.context.preferences.filepaths.file_preview_type = 'NONE'
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print('DENG_BLEND_PACKED_AND_FRAMED')
