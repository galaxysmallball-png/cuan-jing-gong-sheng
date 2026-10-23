"""Reopen one new source; use -- key after Blender's -- separator."""
import bpy
import json
import sys
from pathlib import Path

project=Path(__file__).resolve().parents[1]
key=sys.argv[sys.argv.index('--')+1]
config={
    'a_qiang':('AQiang',22,{'beam':'spine','sheath':'hips','headtie':'head'}),
    'yu_nan':('YuNan',23,{'brocade':'forearm.L','belt':'hips'}),
    'pu_mo':('PuMo',28,{'firepan':'hand.R','teapot':'hand.L','cloak.back':'spine'}),
    'pack_donkey':('PackDonkey',22,{'ear.L':'head','ear.R':'head','cargo.L':'spine','cargo.R':'spine','tail':'spine'}),
}[key]
prefix,count,parents=config
mesh=bpy.data.objects[prefix+'_CharacterMesh'];rig=bpy.data.objects[prefix+'_Armature']
assert mesh.parent==rig and len(rig.data.bones)==count
assert all(v.groups for v in mesh.data.vertices)
assert all(g.name in rig.data.bones for g in mesh.vertex_groups)
assert mesh.data.uv_layers and mesh.data.color_attributes.get('Color')
assert {a.name for a in bpy.data.actions}=={'idle','walk','jump','push','carry','inspect'}
for bone,parent in parents.items():assert rig.data.bones[bone].parent.name==parent
images=[i for i in bpy.data.images if i.type=='IMAGE']
assert len(images)==2 and all(i.packed_file for i in images)
if key=='a_qiang':
    for action in bpy.data.actions:
        rig.animation_data.action=action;bpy.context.scene.frame_set(6)
        assert (rig.pose.bones['beam'].scale.length<.01)==(action.name in ['push','carry','jump'])
report={'source_reopened':True,'bones':count,'animations':6,'packed_images':2,'all_vertices_weighted':True,'accessory_parents_verified':parents,'vertices':len(mesh.data.vertices),'polygons':len(mesh.data.polygons)}
(project/'character-source'/key/'reopen-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('VILLAGE_SOURCE_REOPEN_OK',key,json.dumps(report,ensure_ascii=True))
