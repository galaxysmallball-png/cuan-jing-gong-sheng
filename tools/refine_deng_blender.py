"""Build the editable Blender character, bind a real armature, and export for Godot.

Uses the existing Steam Blender. The user's reference is packed unchanged.
All generated files stay inside this project. No user preferences are saved.
"""
import bpy
import bmesh
import contextlib
import io
import json
import math
import struct
from pathlib import Path
from mathutils import Matrix, Vector, Quaternion

PROJECT = Path(__file__).resolve().parents[1]
ASSETS = PROJECT / 'assets/characters/deng_shunian'
OUT = PROJECT / 'character-source/deng_shunian'
PREVIEWS = PROJECT / 'previews'
OUT.mkdir(parents=True, exist_ok=True)
PREVIEWS.mkdir(parents=True, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
source = ASSETS / '邓书年.glb'
with contextlib.redirect_stdout(io.StringIO()):
    bpy.ops.import_scene.gltf(filepath=str(source))

# Restore glTF node rest transforms: importers otherwise activate the first clip.
payload = source.read_bytes()
chunk_length = struct.unpack_from('<I', payload, 12)[0]
gltf = json.loads(payload[20:20+chunk_length].decode('utf-8'))
conversion = Matrix.Rotation(math.pi/2,4,'X')
for obj in list(bpy.data.objects):
    obj.animation_data_clear()
for node in gltf['nodes']:
    obj = bpy.data.objects.get(node.get('name',''))
    if not obj:
        continue
    if 'matrix' in node:
        values = node['matrix']
        local = Matrix([values[index::4] for index in range(4)])
    else:
        rotation = node.get('rotation',[0,0,0,1])
        local = Matrix.LocRotScale(Vector(node.get('translation',[0,0,0])),
                                  Quaternion((rotation[3],rotation[0],rotation[1],rotation[2])),
                                  Vector(node.get('scale',[1,1,1])))
    obj.matrix_basis = conversion @ local @ conversion.inverted()
bpy.context.view_layer.update()
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)

def find(name):
    obj = bpy.data.objects.get(name)
    assert obj is not None, f'Missing source joint: {name}'
    return obj

def point(name):
    return find(name).matrix_world.translation.copy()

positions = {name: point(name) for name in [
    'Head','LeftArm','RightArm','Forearm','Forearm2','Palm','Palm2',
    'LeftLeg','RightLeg','Knee','Knee2','ClothShoe','ClothShoe2',
    'WornToe','WornToe2','BookBag','WaistOrnaments','Skirt','Eyes',
    'HatRibbonLeft','HatRibbonRight','Brush']}
assert positions['Palm'].z > positions['Palm2'].z + 0.25, 'Source rest pose was not restored'

character_collection = bpy.data.collections.new('邓书年_可编辑角色')
bpy.context.scene.collection.children.link(character_collection)
armature_data = bpy.data.armatures.new('邓书年_骨架')
armature = bpy.data.objects.new('Deng_Armature',armature_data)
character_collection.objects.link(armature)
bpy.context.view_layer.objects.active = armature
armature.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')

def bone(name, head, tail, parent=None):
    item = armature_data.edit_bones.new(name)
    item.head = head
    item.tail = tail
    if (item.tail-item.head).length < 0.015:
        item.tail.z += 0.04
    if parent:
        item.parent = armature_data.edit_bones[parent]
    return item

bone('root',(0,0,0),(0,0,0.12))
bone('hips',(0,0,0.75),(0,0,0.87),'root')
bone('spine',(0,0,0.87),(0,0,1.14),'hips')
bone('neck',(0,0,1.14),positions['Head'],'spine')
bone('head',positions['Head'],(0,0,1.73),'neck')
bone('skirt',positions['Skirt'],(0,0,0.28),'hips')
bone('bag',positions['BookBag'],positions['BookBag']+Vector((0,0,0.12)),'spine')
bone('charms',positions['WaistOrnaments'],positions['WaistOrnaments']+Vector((0,0,-0.18)),'hips')
bone('eyes',positions['Eyes'],positions['Eyes']+Vector((0,0,0.04)),'head')
bone('ribbon.L',positions['HatRibbonLeft'],positions['HatRibbonLeft']+Vector((0,0,-0.20)),'head')
bone('ribbon.R',positions['HatRibbonRight'],positions['HatRibbonRight']+Vector((0,0,-0.20)),'head')
for suffix, side in [('L','Left'),('R','Right')]:
    extra = '' if suffix == 'L' else '2'
    bone('upper_arm.'+suffix,positions[side+'Arm'],positions['Forearm'+extra],'spine')
    bone('forearm.'+suffix,positions['Forearm'+extra],positions['Palm'+extra],'upper_arm.'+suffix)
    hand_direction = (positions['Palm'+extra]-positions['Forearm'+extra]).normalized()
    bone('hand.'+suffix,positions['Palm'+extra],positions['Palm'+extra]+hand_direction*0.07,'forearm.'+suffix)
    bone('thigh.'+suffix,positions[side+'Leg'],positions['Knee'+extra],'hips')
    bone('shin.'+suffix,positions['Knee'+extra],positions['ClothShoe'+extra],'thigh.'+suffix)
    bone('foot.'+suffix,positions['ClothShoe'+extra],positions['WornToe'+extra],'shin.'+suffix)
bone('brush',positions['Brush'],positions['Brush']+Vector((0,0,-0.18)),'hand.R')
bpy.ops.object.mode_set(mode='OBJECT')
armature.show_in_front = True
armature.data.display_type = 'OCTAHEDRAL'

def ancestry(obj):
    names = []
    while obj:
        names.append(obj.name)
        obj = obj.parent
    return names

def binding(obj, chain):
    if 'Head' in chain:
        if 'Eyes' in chain: return 'eyes'
        if 'HatRibbonLeft' in chain: return 'ribbon.L'
        if 'HatRibbonRight' in chain: return 'ribbon.R'
        return 'head'
    if 'BookBag' in chain: return 'bag'
    if 'WaistOrnaments' in chain: return 'charms'
    for side,suffix in [('Left','L'),('Right','R')]:
        if side+'Arm' in chain:
            if 'Brush' in chain: return 'brush'
            if any(name.startswith(('Palm','Finger','Thumb')) for name in chain): return 'hand.'+suffix
            return ('forearm.' if any(name.startswith('Forearm') for name in chain) else 'upper_arm.')+suffix
        if side+'Leg' in chain:
            if obj.name.startswith(('ClothShoe','LayeredSole','WornToe')): return 'foot.'+suffix
            return ('shin.' if any(name.startswith('Knee') for name in chain) else 'thigh.')+suffix
    if 'Skirt' in chain: return 'skirt'
    return 'spine'

meshes = [obj for obj in bpy.data.objects if obj.type == 'MESH']
for obj in meshes:
    chain = ancestry(obj)
    joint = binding(obj,chain)
    world_matrix = obj.matrix_world.copy()
    obj.data.transform(world_matrix)
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.00001)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    for polygon in obj.data.polygons:
        polygon.use_smooth = not obj.name.startswith(('HatBand','FoldedHatCrown','RubbingFolio'))
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    character_collection.objects.link(obj)
    group = obj.vertex_groups.new(name=joint)
    group.add(list(range(len(obj.data.vertices))),1.0,'REPLACE')
    # A real cloth wall around the previously open cuff boundary.
    if obj.name.startswith(('WideSleeve','CuffBinding','Undersleeve','CuffLining')):
        modifier = obj.modifiers.new('袖口厚度','SOLIDIFY')
        modifier.thickness = 0.0018
        modifier.offset = -0.2
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)

# Join while retaining UVs, color attributes, material slots and bone weights.
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes: obj.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.join()
character = bpy.context.object
character.name = 'Deng_CharacterMesh'
character.parent = armature
character.matrix_parent_inverse = Matrix.Identity(4)
skin = character.modifiers.new('骨骼蒙皮','ARMATURE')
skin.object = armature
for obj in list(bpy.data.objects):
    if obj.type == 'EMPTY': bpy.data.objects.remove(obj,do_unlink=True)
for material in bpy.data.materials:
    if material.use_nodes:
        for node in material.node_tree.nodes:
            if node.type == 'BSDF_PRINCIPLED':
                node.inputs['Roughness'].default_value = 0.93
                node.inputs['Metallic'].default_value = 0.0
                node.inputs['Specular IOR Level'].default_value = 0.12

scene = bpy.context.scene
scene.render.fps = 30
armature.animation_data_create()
actions = {}

def rotate_world(name, axis, angle):
    pose = armature.pose.bones[name]
    local_axis = pose.bone.matrix_local.to_3x3().inverted() @ Vector(axis)
    pose.rotation_quaternion = Quaternion(local_axis.normalized(),angle)

for mode,frames in [('idle',141),('walk',18),('jump',24),('push',18),('carry',18),('inspect',90)]:
    action = bpy.data.actions.new(mode)
    action.use_fake_user = True
    armature.animation_data.action = action
    for frame in range(frames+1):
        time = frame/30
        phase = math.tau*frame/frames
        moving = mode in {'walk','push','carry'}
        stride = math.sin(phase) if moving else 0
        for pose in armature.pose.bones:
            pose.rotation_mode = 'QUATERNION'
            pose.rotation_quaternion = Quaternion()
            pose.location = (0,0,0)
            pose.scale = (1,1,1)
        rotate_world('head',(0,1,0),math.sin(time*1.6)*0.012)
        rotate_world('skirt',(0,1,0),stride*0.025)
        rotate_world('bag',(0,1,0),stride*0.055)
        rotate_world('charms',(0,1,0),stride*0.12)
        for suffix,sign in [('L',1),('R',-1)]:
            rotate_world('thigh.'+suffix,(1,0,0),stride*0.40*sign)
            rotate_world('shin.'+suffix,(1,0,0),max(0,-stride*sign)*0.48)
            rotate_world('ribbon.'+suffix,(1,0,0),stride*0.12+math.sin(time*2.3)*0.025)
        if mode == 'walk':
            rotate_world('upper_arm.R',(1,0,0),-stride*0.23)
        if mode == 'jump':
            rotate_world('thigh.L',(1,0,0),-0.28)
            rotate_world('thigh.R',(1,0,0),0.34)
            rotate_world('shin.L',(1,0,0),0.60)
            rotate_world('shin.R',(1,0,0),0.65)
        if mode in {'push','carry'}:
            for suffix in ['L','R']: rotate_world('upper_arm.'+suffix,(1,0,0),-0.85)
            rotate_world('forearm.L',(1,0,0),2.2)
            rotate_world('forearm.R',(1,0,0),-0.45)
            armature.pose.bones['brush'].scale = (0.001,0.001,0.001)
        if mode == 'inspect':
            rotate_world('head',(1,0,0),0.10)
            rotate_world('upper_arm.R',(1,0,0),-0.50)
            rotate_world('forearm.R',(1,0,0),-1.55)
        if mode == 'idle' and frame in range(135,140):
            armature.pose.bones['eyes'].scale.y = 0.08
        for pose in armature.pose.bones:
            pose.keyframe_insert(data_path='rotation_quaternion',frame=frame,group=pose.name)
            pose.keyframe_insert(data_path='location',frame=frame,group=pose.name)
            pose.keyframe_insert(data_path='scale',frame=frame,group=pose.name)
    actions[mode] = action
armature.animation_data.action = actions['idle']
scene.frame_start = 0
scene.frame_end = 141
scene.frame_set(0)

# Pack an untouched copy of the supplied sheet for later manual modeling/painting.
reference_collection = bpy.data.collections.new('REFERENCE_用户三视图')
scene.collection.children.link(reference_collection)
image = bpy.data.images.load(str(PROJECT/'references/邓书年_用户三视图.png'))
image.pack()
reference = bpy.data.objects.new('用户三视图_原图',None)
reference.empty_display_type = 'IMAGE'
reference.data = image
reference.empty_display_size = 3.6
reference.location = (-3.5,0,1.0)
reference.rotation_euler = (math.pi/2,0,0)
reference.hide_render = True
reference_collection.objects.link(reference)

export_path = ASSETS/'deng_shunian_rigged.glb'
bpy.ops.object.select_all(action='DESELECT')
armature.select_set(True)
character.select_set(True)
bpy.context.view_layer.objects.active = armature
with contextlib.redirect_stdout(io.StringIO()):
    bpy.ops.export_scene.gltf(filepath=str(export_path),export_format='GLB',use_selection=True,
                              export_animations=True,export_animation_mode='ACTIONS',
                              export_force_sampling=True,export_frame_range=False)
exported = export_path.read_bytes()
length = struct.unpack_from('<I',exported,12)[0]
document = json.loads(exported[20:20+length].decode('utf-8'))
names = [animation.get('name') for animation in document.get('animations',[])]
assert set(names) == set(actions), f'Lost animation clips: {names}'
assert len(document.get('skins',[])) == 1, 'Export lost the actual armature skin'
assert character.data.uv_layers, 'Export source lost UV coordinates'
assert all(len(vertex.groups)>0 for vertex in character.data.vertices), 'Some vertices have no bone weights'

report = {'blender':bpy.app.version_string,'bones':len(armature_data.bones),
          'vertices':len(character.data.vertices),'polygons':len(character.data.polygons),
          'animations':names,'skins':len(document['skins']),'uv_layers':len(character.data.uv_layers),
          'reference_packed':bool(image.packed_file),'glb':str(export_path)}
(OUT/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
if hasattr(bpy.context.preferences.filepaths,'file_preview_type'):
    bpy.context.preferences.filepaths.file_preview_type = 'NONE'
for packed_image in bpy.data.images:
    if packed_image.type == 'IMAGE' and packed_image.has_data:
        packed_image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'邓书年_角色工程.blend'))
print('DENG_BLENDER_OK',json.dumps(report,ensure_ascii=False))
