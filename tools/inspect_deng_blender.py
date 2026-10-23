import bpy
import json
from pathlib import Path

project = Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(project / 'assets/characters/deng_shunian/邓书年.glb'))
for name in ['DengShunian','Rig','Head','LeftArm','RightArm','Forearm','Forearm2','LeftLeg','RightLeg','Knee','Knee2','Palm','Palm2','BookBag']:
    obj = bpy.data.objects.get(name)
    if obj:
        print('DENG_NODE', obj.name, obj.parent.name if obj.parent else None, tuple(round(v,4) for v in obj.matrix_world.translation))
print('DENG_OBJECTS', len(bpy.data.objects), 'MESHES', sum(obj.type == 'MESH' for obj in bpy.data.objects))
print('DENG_ACTIONS', [(action.name, len(action.slots)) for action in list(bpy.data.actions)[:8]])
print('DENG_ARM_DESC', [(obj.name, obj.type) for obj in bpy.data.objects if obj.parent and obj.parent.name == 'LeftArm'])
print('DENG_INSPECTION_COMPLETE')
