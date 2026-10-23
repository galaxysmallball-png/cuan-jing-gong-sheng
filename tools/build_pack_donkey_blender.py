"""Build one of three villagers from a supplied reference sheet.

Open Deng's neck-v3 .blend as a read-only facial topology library before running.
This script never saves over the four playable characters' source files.
"""
import bpy
import bmesh
import contextlib
import io
import json
import math
import random
import struct
import sys
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
from mathutils.bvhtree import BVHTree

PROJECT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT / 'tools'))
import character_geometry as geo

key='pack_donkey'
CFG=dict(key=key,name='驮布毛驴',ethnicity='',prefix='PackDonkey')
OUT=PROJECT/'character-source/pack_donkey';ASSETS=PROJECT/'assets/characters/pack_donkey'
OUT.mkdir(parents=True,exist_ok=True);ASSETS.mkdir(parents=True,exist_ok=True)
(OUT.parent/'.gdignore').touch()
rng=random.Random(601017)
cloth_image=next(i for i in bpy.data.images if 'Indigo_albedo' in i.name)
if not cloth_image.has_data:cloth_image.pixels[0]
cloth_image.pack()
for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
for image in list(bpy.data.images):
    if image!=cloth_image and image.type=='IMAGE':bpy.data.images.remove(image)
collection=bpy.data.collections.new('驮布毛驴_可编辑模型');bpy.context.scene.collection.children.link(collection)
geo.collection,geo.parts,geo.rng=collection,[],rng
p,mesh,sphere,loft,tube,ribbon=geo.p,geo.mesh,geo.sphere,geo.loft,geo.tube,geo.ribbon
curve_batch=geo.CurveBatch();curve=curve_batch
def linear(color):
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in color)


def multiply(mat, source=None, constant=None):
    mix = mat.node_tree.nodes.new('ShaderNodeMix')
    mix.data_type = 'RGBA'
    mix.blend_type = 'MULTIPLY'
    mix.inputs[0].default_value = 1
    a = next(s for s in mix.inputs if s.name == 'A' and s.type == 'RGBA')
    b = next(s for s in mix.inputs if s.name == 'B' and s.type == 'RGBA')
    if source:
        mat.node_tree.links.new(source, a)
    else:
        a.default_value = constant
    return b, next(s for s in mix.outputs if s.type == 'RGBA')


def material(name, color, cloth=False, metal=0):
    mat = bpy.data.materials.new(CFG['prefix']+'_' + name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*linear(color), 1)
    shader.inputs['Roughness'].default_value = .91 if not metal else .66
    shader.inputs['Specular IOR Level'].default_value = .04
    shader.inputs['Metallic'].default_value = metal
    mat.diffuse_color = (*linear(color), 1)
    if cloth:
        texture = mat.node_tree.nodes.new('ShaderNodeTexImage')
        texture.image = cloth_image
        b, out = multiply(mat, constant=(*linear(color), 1))
        mat.node_tree.links.new(texture.outputs['Color'], b)
        mat.node_tree.links.new(out, shader.inputs['Base Color'])
    return mat


mats={
'Fur':material('GreyFur',(.52,.52,.47)),'Muzzle':material('PaleMuzzle',(.70,.69,.59)),
'Dark':material('DarkMane',(.15,.15,.13)),'Eye':material('Eyes',(.13,.10,.07)),
'Ear':material('InnerEar',(.39,.34,.29)),'Hoof':material('Hooves',(.22,.22,.19)),
'Linen':material('CreamGlint',(.90,.88,.77)),
'Blue':material('IndigoBrocade',(.22,.31,.38),True),'Red':material('RedBrocade',(.52,.26,.19),True),
'RedLight':material('ClothPatternRed',(.71,.39,.26)),'Gold':material('ClothPatternGold',(.67,.49,.24)),
'Bamboo':material('Wicker',(.48,.37,.23)),'BambooLight':material('WickerLight',(.61,.49,.32)),
'BambooDark':material('WickerDark',(.29,.23,.15)),'Rope':material('Hemp',(.48,.39,.25)),
'Leather':material('Leather',(.29,.22,.14)),
}
geo.mats=mats
def solidify(obj, thickness):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new('衣物真实厚度', 'SOLIDIFY')
    mod.thickness, mod.offset = thickness, -.4
    bpy.ops.object.modifier_apply(modifier=mod.name)

from pack_donkey_geometry import build as build_geometry
build_geometry(globals());curve_batch.flush()
face=geo.parts[0]
print('PACK_DONKEY_MESH_READY',len(geo.parts),flush=True)
# Consolidate and calculate the same soft skin occlusion used by the other models.
for obj in geo.parts:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
bpy.ops.object.select_all(action='DESELECT')
for obj in geo.parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = face
bpy.ops.object.join()
character = bpy.context.object
character.name = CFG['prefix']+'_CharacterMesh'
used = {f.material_index for f in character.data.polygons}
for i in reversed(range(len(character.data.materials))):
    if i not in used:
        character.data.materials.pop(index=i)
for attr in list(character.data.color_attributes):
    if attr.name != 'Color':
        character.data.color_attributes.remove(attr)
colors = character.data.color_attributes['Color']
skin_mats = {mats['Fur'],mats['Muzzle']}
slots = {i for i, m in enumerate(character.data.materials) if m in skin_mats}
indices = {i for poly in character.data.polygons if poly.material_index in slots for i in poly.vertices}
bm = bmesh.new()
bm.from_mesh(character.data)
bvh = BVHTree.FromBMesh(bm)
bm.free()
samples = []
for i in range(64):
    r = math.sqrt((i + .5) / 64)
    a = i * 2.399963229728653
    samples.append((r * math.cos(a), r * math.sin(a), math.sqrt(1 - r * r)))
ao = {}
for index in indices:
    v = character.data.vertices[index]
    n = v.normal.normalized()
    t = n.cross(Vector((0, 0, 1)))
    if t.length < .01:
        t = n.cross(Vector((1, 0, 0)))
    t.normalize()
    b = n.cross(t)
    value = 0
    for x, y, z in samples:
        hit, _, _, distance = bvh.ray_cast(v.co + n * .00055, t * x + b * y + n * z, .10)
        if hit is not None:
            value += math.exp(-distance / .048)
    ao[index] = value / 64
neighbors = {i: set() for i in indices}
for edge in character.data.edges:
    a, b = edge.vertices
    if a in neighbors and b in neighbors:
        neighbors[a].add(b)
        neighbors[b].add(a)
for _ in range(3):
    ao = {i: .6 * v + .4 * sum(ao[n] for n in neighbors[i]) / max(1, len(neighbors[i])) for i, v in ao.items()}
for poly in character.data.polygons:
    if character.data.materials[poly.material_index] not in skin_mats:
        continue
    for loop in poly.loop_indices:
        shade = max(.68, 1 - .58 * ao[character.data.loops[loop].vertex_index] ** .8)
        colors.data[loop].color = (shade, shade * .994, shade * .985, 1)
for mat in skin_mats:
    shader = mat.node_tree.nodes.get('Principled BSDF')
    base = shader.inputs['Base Color'].default_value[:]
    attr = mat.node_tree.nodes.new('ShaderNodeVertexColor')
    attr.layer_name = 'Color'
    b, out = multiply(mat, constant=base)
    mat.node_tree.links.new(attr.outputs['Color'], b)
    mat.node_tree.links.new(out, shader.inputs['Base Color'])

from pack_donkey_rig import build as build_rig
armature,actions=build_rig(globals())
scene = bpy.context.scene
scene.frame_start, scene.frame_end = 0, 141
scene.frame_set(0)
ref_collection = bpy.data.collections.new('REFERENCE_'+CFG['name']+'用户三视图')
scene.collection.children.link(ref_collection)
image = bpy.data.images.load(str(PROJECT/'references/玉喃_用户三视图.png'))
image.pack()
reference = bpy.data.objects.new(CFG['name']+'_用户原图', None)
reference.empty_display_type, reference.data = 'IMAGE', image
reference.empty_display_size = 3.5
reference.location = (-3.5, 0, 1)
reference.rotation_euler = (math.pi / 2, 0, 0)
reference.hide_render = True
ref_collection.objects.link(reference)
export_path = ASSETS / (key+'_rigged.glb')
bpy.ops.object.select_all(action='DESELECT')
character.select_set(True)
armature.select_set(True)
bpy.context.view_layer.objects.active = armature
with contextlib.redirect_stdout(io.StringIO()):
    bpy.ops.export_scene.gltf(filepath=str(export_path), export_format='GLB', use_selection=True, export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True, export_frame_range=False)
raw = export_path.read_bytes()
size = struct.unpack_from('<I', raw, 12)[0]
gltf = json.loads(raw[20:20 + size].decode('utf8'))
assert len(gltf['skins']) == 1 and {a['name'] for a in gltf['animations']} == set(actions)
report = {'blender': bpy.app.version_string, 'character': CFG['name'], 'ethnicity':CFG['ethnicity'], 'bones': len(armature.data.bones), 'vertices': len(character.data.vertices), 'polygons': len(character.data.polygons), 'animations': [a['name'] for a in gltf['animations']], 'skins': 1, 'uv_layers': len(character.data.uv_layers), 'vertex_ao_samples': 64, 'packed_images': 2, 'glb': str(export_path)}
(OUT / 'validation.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
if hasattr(bpy.context.preferences.filepaths, 'file_preview_type'):
    bpy.context.preferences.filepaths.file_preview_type = 'NONE'
bpy.ops.object.select_all(action='DESELECT')
character.select_set(True)
bpy.context.view_layer.objects.active = character
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            area.spaces.active.shading.type = 'MATERIAL'
            area.spaces.active.region_3d.view_location = (0, 0, .94)
            area.spaces.active.region_3d.view_distance = 2.8
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / (CFG['name']+'_角色工程.blend')))
print('VILLAGE_CHARACTER_BLENDER_OK', json.dumps(report, ensure_ascii=False))
