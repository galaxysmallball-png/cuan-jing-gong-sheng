"""Build an independent A Cai source and GLB from the supplied sheet.

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

OUT = PROJECT / 'character-source/a_cai'
ASSETS = PROJECT / 'assets/characters/a_cai'
OUT.mkdir(parents=True, exist_ok=True)
ASSETS.mkdir(parents=True, exist_ok=True)
(OUT.parent / '.gdignore').touch()
rng = random.Random(501017)
library = bpy.data.objects['Deng_CharacterMesh']
face = library.copy()
face.data = library.data.copy()
bpy.context.scene.collection.objects.link(face)
face.name = 'ACai_FacialTopology'
face.parent = None
face.matrix_world = Matrix.Identity(4)
face.modifiers.clear()
keep_slots = {i for i, m in enumerate(face.data.materials) if m and m.name.startswith('Face_') and m.name not in {'Face_Neck', 'Face_MatteHair'}}
keep = {i for poly in face.data.polygons if poly.material_index in keep_slots for i in poly.vertices}
bm = bmesh.new()
bm.from_mesh(face.data)
bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.index not in keep], context='VERTS')
bm.to_mesh(face.data)
bm.free()
for obj in list(bpy.data.objects):
    if obj != face:
        bpy.data.objects.remove(obj, do_unlink=True)
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
for group in list(face.vertex_groups):
    if group.name not in {'head', 'eyes'}:
        face.vertex_groups.remove(group)
for attr in list(face.data.color_attributes)[1:]:
    face.data.color_attributes.remove(attr)
face.data.color_attributes[0].name = 'Color'
for color in face.data.color_attributes[0].data:
    color.color = (1, 1, 1, 1)
cloth_image = next(i for i in bpy.data.images if 'Indigo_albedo' in i.name)
if not cloth_image.has_data:
    cloth_image.pixels[0]
cloth_image.pack()
for image in list(bpy.data.images):
    if image != cloth_image and image.type == 'IMAGE':
        bpy.data.images.remove(image)
collection = bpy.data.collections.new('阿彩_可编辑角色')
bpy.context.scene.collection.children.link(collection)
for old in list(face.users_collection):
    old.objects.unlink(face)
collection.objects.link(face)
geo.collection, geo.parts, geo.rng = collection, [face], rng
p, mesh, sphere, loft, tube, ribbon = geo.p, geo.mesh, geo.sphere, geo.loft, geo.tube, geo.ribbon
curve_batch = geo.CurveBatch()
curve = curve_batch


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
    mat = bpy.data.materials.new('ACai_' + name)
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


mats = {
'Skin':material('Skin',(.72,.51,.34)), 'Neck':material('Neck',(.69,.47,.30)),
'Robe':material('IndigoBlouseSkirt',(.21,.27,.31),True),
'Vest':material('BlackSleevelessVest',(.15,.15,.13),True),
'VestEdge':material('VestSeam',(.26,.25,.20)),
'Veil':material('WrappedBlackTurban',(.12,.125,.115),True),
'VeilEdge':material('TurbanFold',(.17,.175,.16),True),
'UnderCap':material('BatikBlue',(.23,.29,.32),True),
'Linen':material('IvoryWaxDye',(.77,.74,.63)),
'Pants':material('UnderSkirt',(.14,.18,.20),True),
'Sash':material('RedSash',(.51,.22,.17),True),
'RedLight':material('RedEmbroidery',(.68,.35,.27)),
'BlueThread':material('BlueEmbroidery',(.30,.42,.48)),
'Bamboo':material('Bamboo',(.49,.38,.24)),
'BambooLight':material('BambooLight',(.61,.49,.33)),
'BambooDark':material('BambooDark',(.30,.24,.16)),
'Wood':material('HoeShaft',(.46,.34,.21)),
'Grain':material('WoodGrain',(.31,.23,.14)),
'Rope':material('HempLacing',(.47,.38,.24)),
'Iron':material('ForgedIron',(.27,.28,.27),metal=.35),
'Silver':material('WornSilver',(.62,.60,.52),metal=.5),
'Bag':material('CarrierStrap',(.19,.22,.22),True),
'Lip':material('WarmLip',(.48,.26,.17)),
'Crease':material('SmileCrease',(.53,.34,.22)),
'Hair':material('Hair',(.09,.085,.07)),
'Powder':material('ClothWear',(.34,.36,.32)),
'Teeth':material('IvoryTeeth',(.91,.86,.71)),
'Mouth':material('SmileInside',(.22,.10,.075)),
}
geo.mats = mats
face_palette = {}
for i, old in enumerate(face.data.materials):
    if i not in keep_slots:
        continue
    mat = old.copy()
    mat.name = 'ACai_' + old.name.removeprefix('Face_')
    shader = mat.node_tree.nodes.get('Principled BSDF')
    if old.name in {'Face_SoftSkin', 'Face_EarAndLid'}:
        for node in list(mat.node_tree.nodes):
            if node.type not in {'OUTPUT_MATERIAL', 'BSDF_PRINCIPLED'}:
                mat.node_tree.nodes.remove(node)
        shader.inputs['Base Color'].default_value = (*linear((.74, .53, .36)), 1)
        shader.inputs['Specular IOR Level'].default_value = .04
        shader.inputs['Roughness'].default_value = .92
    face.data.materials[i] = mat
    face_palette[old.name] = mat


def gauss(x, h, cx, ch, sx, sh):
    return math.exp(-((x - cx) / sx) ** 2 - ((h - ch) / sh) ** 2)


# Rounded cheeks, soft jaw and smaller nose; the topology remains a real 3D face.
origin = Vector((0, 0, 1.48 * .86))
untilt = Matrix.Rotation(.02, 3, 'Y').inverted()
for v in face.data.vertices:
    local = untilt @ (v.co - origin) / .86
    x, h, f = local.x, local.z, -local.y
    x *= .92 * (1 - .17 * math.exp(-((h - .045) / .05) ** 2))
    front = max(0, min(1, f / .06)) ** 5
    f = f * .86 + front * (.006 * gauss(abs(x), h, .052, .14, .030, .041) - .005 * gauss(x, h, 0, .16, .021, .035))
    v.co = p((x, 1.381 + (h - .030) * .80, f))
# Lift mouth corners and the adjoining cheek surface together for a restrained smile.
for v in face.data.vertices:
    x, h, f = v.co.x, v.co.z, -v.co.y
    corner = math.exp(-((abs(x) - .025) / .018) ** 2 - ((h - 1.432) / .020) ** 2)
    v.co.z += .0055 * corner * max(0, min(1, f / .060)) ** 3
# Remove existing brows, then draw a softer raised arch against the actual skin.
brow_slot = next(i for i, m in enumerate(face.data.materials) if m == face_palette['Face_Brows'])
remove = {i for poly in face.data.polygons if poly.material_index == brow_slot for i in poly.vertices if face.data.vertices[i].co.z > 1.54}
bm = bmesh.new()
bm.from_mesh(face.data)
bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm, geom=[bm.verts[i] for i in remove], context='VERTS')
bm.to_mesh(face.data)
bm.free()
face.data.update()
skin_slot = next(i for i, m in enumerate(face.data.materials) if m == face_palette['Face_SoftSkin'])
skin_bvh = BVHTree.FromPolygons([v.co.copy() for v in face.data.vertices], [tuple(f.vertices) for f in face.data.polygons if f.material_index == skin_slot])


def skin_front(x, h):
    hit, _, _, _ = skin_bvh.ray_cast(Vector((x, -.5, h)), Vector((0, 1, 0)), 1)
    return -hit.y if hit is not None else .065


for side in [-1, 1]:
    pts = [(side * .014, 1.570), (side * .032, 1.582), (side * .054, 1.580), (side * .072, 1.568)]
    curve('SoftArchedBrow', [(x, h, skin_front(x, h) + .002) for x, h in pts], .0028, mats['Hair'], 'head', [.55, 1, .8, .05])
    
loft('VisibleNeck', [(1.28,.043,.036,0,-.005),(1.34,.033,.029,0,-.007),(1.39,.032,.028,0,-.004),(1.412,.034,.03,0,0)], mats['Neck'], 'neck',56)

# Replace the older narrow mouth with a small, cheerful open smile.
old_mouth={i for i,m in enumerate(face.data.materials) if m and any(key in m.name for key in ['Lip','Mouth'])}
remove={i for poly in face.data.polygons if poly.material_index in old_mouth for i in poly.vertices}
bm=bmesh.new();bm.from_mesh(face.data);bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[bm.verts[i] for i in remove],context='VERTS');bm.to_mesh(face.data);bm.free()
for name,width,depth,mat in [('OpenFriendlySmile',.031,.017,mats['Mouth']),('UpperSmileTeeth',.025,.006,mats['Teeth'])]:
    pts=[]
    for row in range(2):
        for j in range(33):
            x=-width+2*width*j/32;t=x/width
            top=1.433+.007*t*t
            h=top if row==0 else top-depth*(1-t*t)**.65
            pts.append((x,h,skin_front(x,h)+.0028+(name=='UpperSmileTeeth')*.0007))
    mesh(name,pts,[(j,j+1,33+j+1,33+j) for j in range(32)],mat,'head')
for side in [-1,1]:
    pts=[(side*.027,1.437),(side*.035,1.442),(side*.038,1.448)]
    curve('SmileCorner',[(x,h,skin_front(x,h)+.001) for x,h in pts],.0009,mats['Lip'],'head')

def solidify(obj, thickness):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new('衣物真实厚度', 'SOLIDIFY')
    mod.thickness, mod.offset = thickness, -.4
    bpy.ops.object.modifier_apply(modifier=mod.name)

from a_cai_geometry import build as build_geometry
shoulders,elbows,wrists,hands=build_geometry(globals())
curve_batch.flush()
print('A_CAI_MESH_READY',len(geo.parts),flush=True)
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
character.name = 'ACai_CharacterMesh'
used = {f.material_index for f in character.data.polygons}
for i in reversed(range(len(character.data.materials))):
    if i not in used:
        character.data.materials.pop(index=i)
for attr in list(character.data.color_attributes):
    if attr.name != 'Color':
        character.data.color_attributes.remove(attr)
colors = character.data.color_attributes['Color']
skin_mats = {mats['Skin'], mats['Neck'], face_palette['Face_SoftSkin'], face_palette['Face_EarAndLid']}
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

from a_cai_rig import build as build_rig
armature,actions=build_rig(globals())
scene = bpy.context.scene
scene.frame_start, scene.frame_end = 0, 141
scene.frame_set(0)
ref_collection = bpy.data.collections.new('REFERENCE_阿彩用户三视图')
scene.collection.children.link(ref_collection)
image = bpy.data.images.load(str(PROJECT / 'references/阿彩_用户三视图.png'))
image.pack()
reference = bpy.data.objects.new('阿彩_用户原图', None)
reference.empty_display_type, reference.data = 'IMAGE', image
reference.empty_display_size = 3.5
reference.location = (-3.5, 0, 1)
reference.rotation_euler = (math.pi / 2, 0, 0)
reference.hide_render = True
ref_collection.objects.link(reference)
export_path = ASSETS / 'a_cai_rigged.glb'
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
hood_mat = next(m for m in gltf['materials'] if m['name'] == 'ACai_WrappedBlackTurban')
assert hood_mat['pbrMetallicRoughness'].get('baseColorTexture') and hood_mat['pbrMetallicRoughness']['baseColorFactor'][0] < .05
report = {'blender': bpy.app.version_string, 'character': '阿彩', 'bones': 26, 'vertices': len(character.data.vertices), 'polygons': len(character.data.polygons), 'animations': [a['name'] for a in gltf['animations']], 'skins': 1, 'uv_layers': len(character.data.uv_layers), 'vertex_ao_samples': 64, 'packed_images': 2, 'glb': str(export_path)}
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
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / '阿彩_角色工程.blend'))
print('A_CAI_BLENDER_OK', json.dumps(report, ensure_ascii=False))
