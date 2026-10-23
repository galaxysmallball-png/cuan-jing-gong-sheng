import bpy
import json

armature = bpy.data.objects.get('Deng_Armature')
mesh = bpy.data.objects.get('Deng_CharacterMesh')
assert armature and armature.type == 'ARMATURE' and len(armature.data.bones) == 24
assert mesh and mesh.type == 'MESH' and len(mesh.vertex_groups) >= 20
assert {'idle','walk','jump','push','carry','inspect'} == {action.name for action in bpy.data.actions}
images = [image for image in bpy.data.images if image.type == 'IMAGE' and image.source in {'FILE','TILED','GENERATED'}]
# Packed images are lazily decoded after reopening, so has_data is not a storage check.
assert images and all(image.packed_files or image.source == 'GENERATED' for image in images), 'A source image depends on an external path'
assert any(modifier.type == 'ARMATURE' and modifier.object == armature for modifier in mesh.modifiers)
print('DENG_BLEND_REOPEN_OK', json.dumps({'bones':len(armature.data.bones),'actions':len(bpy.data.actions),'packed_images':len(images)}))
