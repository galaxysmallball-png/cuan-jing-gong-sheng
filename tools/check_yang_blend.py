import bpy
import json

armature = bpy.data.objects['YangSanniang_Armature']
mesh = bpy.data.objects['YangSanniang_CharacterMesh']
assert armature.type == 'ARMATURE' and len(armature.data.bones) == 27
assert {a.name for a in bpy.data.actions} == {'idle', 'walk', 'jump', 'push', 'carry', 'inspect'}
assert all(v.groups for v in mesh.data.vertices)
assert all(g.name in armature.data.bones for g in mesh.vertex_groups)
assert any(m.type == 'ARMATURE' and m.object == armature for m in mesh.modifiers)
assert mesh.data.uv_layers and mesh.data.color_attributes.get('Color')
images = [i for i in bpy.data.images if i.type == 'IMAGE' and i.source in {'FILE', 'TILED', 'GENERATED'}]
assert len(images) == 2 and all(i.packed_files for i in images)
for name in ['head', 'neck', 'eyes', 'veil', 'skirt.L', 'skirt.R', 'skirt.back', 'pouch', 'charms', 'yoke', 'cargo.L', 'cargo.R']:
    assert name in armature.data.bones
for name in ['cargo.L', 'cargo.R']:
    assert armature.data.bones[name].parent.name == 'yoke'
assert max(v.co.z for v in mesh.data.vertices) < 1.85
assert max(v.co.x for v in mesh.data.vertices) > .70
assert min(v.co.x for v in mesh.data.vertices) < -.70
assert len(mesh.data.vertices) > 50000
print('YANG_BLEND_REOPEN_OK', json.dumps({'bones': 27, 'actions': 6, 'packed_images': len(images), 'weighted_vertices': len(mesh.data.vertices)}))
