import bpy
import json

armature = bpy.data.objects['ShiAduo_Armature']
mesh = bpy.data.objects['ShiAduo_CharacterMesh']
assert armature.type == 'ARMATURE' and len(armature.data.bones) == 25
assert {'idle','walk','jump','push','carry','inspect'} == {a.name for a in bpy.data.actions}
assert all(v.groups for v in mesh.data.vertices)
assert any(m.type=='ARMATURE' and m.object==armature for m in mesh.modifiers)
assert mesh.data.uv_layers and mesh.data.color_attributes
images = [i for i in bpy.data.images if i.type=='IMAGE' and i.source in {'FILE','TILED','GENERATED'}]
assert len(images)==2 and all(i.packed_files for i in images)
for bone_name in ['head','neck','eyes','tassel','ribbon','apron','tool.L','tool.R']:
    assert bone_name in armature.data.bones
print('SHI_BLEND_REOPEN_OK',json.dumps({'bones':25,'actions':6,'packed_images':len(images),'weighted_vertices':len(mesh.data.vertices)}))
