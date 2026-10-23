"""Reopen the delivered .blend in background Blender before packaging."""
import bpy
import json
from pathlib import Path

project=Path(__file__).resolve().parents[1]
mesh=bpy.data.objects['ACai_CharacterMesh']
rig=bpy.data.objects['ACai_Armature']
assert mesh.parent==rig
assert len(rig.data.bones)==26
assert {'idle','walk','jump','push','carry','inspect'}=={a.name for a in bpy.data.actions}
assert all(v.groups for v in mesh.data.vertices)
assert all(g.name in rig.data.bones for g in mesh.vertex_groups)
assert mesh.data.uv_layers and mesh.data.color_attributes.get('Color')
assert rig.data.bones['baby'].parent.name=='carrier'
images=[i for i in bpy.data.images if i.type=='IMAGE']
assert len(images)==2 and all(i.packed_file for i in images)
assert 'REFERENCE_阿彩用户三视图' in bpy.data.collections
for state in ['carry','push','jump','idle','walk','inspect']:
    rig.animation_data.action=bpy.data.actions[state]
    bpy.context.scene.frame_set(6)
    stowed=rig.pose.bones['hoe'].scale.length<.01
    assert stowed==(state in ['carry','push','jump'])
    assert rig.pose.bones['baby'].scale.length>1
report={'reopened':True,'bones':26,'actions':6,'packed_images':2,'all_vertices_weighted':True,'carrier_parent_verified':True,'hoe_states_verified':True,'vertices':len(mesh.data.vertices),'polygons':len(mesh.data.polygons)}
(project/'character-source/a_cai/reopen-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('A_CAI_SOURCE_REOPEN_OK',json.dumps(report))
