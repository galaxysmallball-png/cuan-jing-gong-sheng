"""Build an independent Yang Sanniang source and GLB from the supplied sheet.

Open Deng's neck-v3 .blend as a read-only facial topology library before running.
This script never saves over the other three characters' source files.
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

OUT = PROJECT / 'character-source/yang_sanniang'
ASSETS = PROJECT / 'assets/characters/yang_sanniang'
OUT.mkdir(parents=True, exist_ok=True)
ASSETS.mkdir(parents=True, exist_ok=True)
(OUT.parent / '.gdignore').touch()
rng = random.Random(501017)
library = bpy.data.objects['Deng_CharacterMesh']
face = library.copy()
face.data = library.data.copy()
bpy.context.scene.collection.objects.link(face)
face.name = 'Yang_FacialTopology'
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
collection = bpy.data.collections.new('杨三娘_可编辑角色')
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
    mat = bpy.data.materials.new('Yang_' + name)
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
    'Skin': material('Skin', (.73, .54, .37)), 'Neck': material('Neck', (.69, .49, .33)),
    'Robe': material('IndigoLongRobe', (.24, .30, .35), True),
    'Apron': material('FadedBlueApron', (.36, .42, .45), True),
    'Fold': material('IndigoFold', (.29, .34, .37), True),
    'Vest': material('BrownWaistcoat', (.35, .29, .22), True),
    'VestEdge': material('WaistcoatSeams', (.44, .37, .28)),
    'Veil': material('CharcoalHeadscarf', (.125, .13, .12), True),
    'VeilEdge': material('ScarfFoldEdges', (.18, .18, .16), True),
    'UnderCap': material('IndigoUndercap', (.21, .25, .27), True),
    'Linen': material('RolledCreamCuffs', (.69, .66, .56), True),
    'Pants': material('LooseCharcoalPants', (.18, .21, .23), True),
    'Sash': material('BlueGraySash', (.35, .39, .39), True),
    'Shoe': material('DarkClothShoes', (.16, .18, .18), True),
    'Sole': material('ClothSole', (.37, .34, .27)),
    'Thread': material('OchreStitching', (.56, .45, .27)),
    'Bamboo': material('WovenBamboo', (.49, .38, .23)),
    'BambooLight': material('BambooHighlights', (.61, .49, .31)),
    'BambooDark': material('BambooRecess', (.32, .25, .15)),
    'Wood': material('WornShoulderPole', (.48, .35, .20)),
    'Grain': material('PoleGrain', (.32, .24, .14)),
    'Rope': material('SuspensionHemp', (.40, .32, .21)),
    'Brass': material('AgedBrass', (.56, .43, .23), metal=.45),
    'BrassDark': material('EngravedBrass', (.29, .22, .12), metal=.3),
    'Silver': material('SilverEarPick', (.59, .59, .53), metal=.65),
    'Bag': material('WaistPurse', (.30, .28, .22), True),
    'Lip': material('WarmLip', (.56, .32, .22)),
    'Crease': material('SoftExpressionCrease', (.54, .36, .24)),
    'Hair': material('Brows', (.10, .095, .075)),
    'Powder': material('FadedClothWear', (.43, .44, .39)),
    'RedGoods': material('TerracottaGoods', (.51, .28, .20), True),
    'BlueGoods': material('IndigoGoods', (.28, .36, .40), True),
    'CreamGoods': material('LinenGoods', (.67, .59, .43), True),
    'Fruit': material('DriedFruit', (.43, .27, .15)),
}
geo.mats = mats
face_palette = {}
for i, old in enumerate(face.data.materials):
    if i not in keep_slots:
        continue
    mat = old.copy()
    mat.name = 'Yang_' + old.name.removeprefix('Face_')
    shader = mat.node_tree.nodes.get('Principled BSDF')
    if old.name in {'Face_SoftSkin', 'Face_EarAndLid'}:
        for node in list(mat.node_tree.nodes):
            if node.type not in {'OUTPUT_MATERIAL', 'BSDF_PRINCIPLED'}:
                mat.node_tree.nodes.remove(node)
        shader.inputs['Base Color'].default_value = (*linear((.76, .57, .40)), 1)
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
    # Fine smile corners and restrained crow's-feet suggest the middle-aged sheet.
    for pts in [[(side * .026, 1.438), (side * .034, 1.442), (side * .038, 1.447)], [(side * .067, 1.533), (side * .077, 1.530), (side * .081, 1.526)]]:
        curve('GentleSmileCrease', [(x, h, skin_front(x, h) + .0005) for x, h in pts], .0006, mats['Crease'], 'head', [.1, .75, .1])
loft('VisibleNeck', [(1.28, .046, .037, 0, -.005), (1.34, .035, .031, 0, -.007), (1.39, .033, .029, 0, -.004), (1.412, .035, .031, 0, 0)], mats['Neck'], 'neck', 56)


def solidify(obj, thickness):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new('衣物真实厚度', 'SOLIDIFY')
    mod.thickness, mod.offset = thickness, -.4
    bpy.ops.object.modifier_apply(modifier=mod.name)


# Full indigo garment, split lower sections weighted independently of the torso.
robe_rows = [(.39, .170, .110, 0, 0), (.48, .174, .113, 0, 0), (.66, .167, .106, 0, 0), (.83, .148, .095, 0, 0), (.98, .137, .089, 0, 0), (1.14, .154, .093, 0, -.002), (1.28, .165, .083, 0, -.003), (1.34, .121, .065, 0, -.006), (1.365, .045, .036, 0, -.006)]
robe = loft('FullLengthBlueRobe', robe_rows, mats['Robe'], segments=80, folds=.025, dust=True)
for group in list(robe.vertex_groups):
    robe.vertex_groups.remove(group)
groups = {name: robe.vertex_groups.new(name=name) for name in ['spine', 'skirt.L', 'skirt.R', 'skirt.back']}
for v in robe.data.vertices:
    x, h, f = v.co.x, v.co.z, -v.co.y
    top = max(0, min(1, (h - .73) / .28))
    joint = 'skirt.back' if f < -.01 else ('skirt.L' if x < 0 else 'skirt.R')
    if top:
        groups['spine'].add([v.index], top, 'REPLACE')
    if top < 1:
        groups[joint].add([v.index], 1 - top, 'REPLACE')

# A fitted open-front brown waistcoat, with separate fronts and continuous back.
def vest_point(t, a, extra=0):
    h = .92 + .415 * t
    rx = .149 + .027 * math.sin(t * math.pi * .83)
    rz = .099 + .004 * math.sin(t * math.pi)
    if t > .83:
        q = (t - .83) / .17
        rx = rx * (1 - q) + .118 * q
        rz = rz * (1 - q) + .073 * q
    return ((rx + extra) * math.cos(a), h, -.005 + (rz + extra) * math.sin(a))


points, faces, uv = [], [], []
for row in range(27):
    t = row / 26
    opening = .25 + .18 * t
    for col in range(81):
        a = math.pi / 2 + opening + (math.tau - 2 * opening) * col / 80
        points.append(vest_point(t, a))
        uv.append((col / 80 * 2, t))
        if row and col:
            k = (row - 1) * 81 + col - 1
            faces.append((k, k + 1, k + 82, k + 81))
vest = mesh('OpenBrownWaistcoat', points, faces, mats['Vest'], uv=uv)
solidify(vest, .004)
for edge in [-1, 1]:
    path = []
    for i in range(27):
        t = i / 26
        a = math.pi / 2 + edge * (.25 + .18 * t)
        path.append(vest_point(t, a, .002))
    curve('WaistcoatFrontSeam', path, .0022, mats['VestEdge'])
    for i in range(18):
        t = .05 + i / 19 * .87
        a = math.pi / 2 + edge * (.29 + .18 * t)
        x, h, f = vest_point(t, a, .003)
        curve('HandSewnVestStitch', [(x, h, f), (x, h + .005, f)], .0006, mats['Thread'])
for side, suffix in [(-1, 'L'), (1, 'R')]:
    loft('LooseTrousers.' + suffix, [(.17, .041, .040, side * .079, 0), (.22, .054, .051, side * .079, 0), (.31, .068, .061, side * .080, 0), (.47, .074, .069, side * .079, 0), (.71, .076, .073, side * .075, 0), (.90, .064, .063, side * .067, 0)], mats['Pants'], 'thigh.' + suffix, 48, .06)
    loft('Ankle.' + suffix, [(.084, .026, .027, side * .08, 0), (.17, .030, .030, side * .08, 0)], mats['Skin'], 'shin.' + suffix, 32)
    sphere('LayeredClothSole.' + suffix, (side * .080, .032, .038), (.053, .020, .099), mats['Sole'], 'foot.' + suffix, 32, 16)
    sphere('EmbroideredClothShoe.' + suffix, (side * .080, .064, .040), (.051, .036, .094), mats['Shoe'], 'foot.' + suffix, 40, 20)
    for offset in [-.010, .010]:
        curve('ShoeEmbroideredSprig', [(side * .080 + offset, .096, .090), (side * .080 + offset + .006, .101, .069), (side * .080 + offset + .003, .099, .045)], .001, mats['Thread'], 'foot.' + suffix)
        for i in range(4):
            x, f = side * .080 + offset, .050 + i * .010
            curve('ShoeLeafStitch', [(x, .101, f), (x + .007, .099, f + .003)], .0008, mats['Thread'], 'foot.' + suffix)

# Faded front apron sits on the robe, with hand-stitched hem and separate belt.
for side in [-1, 1]:
    pts, fs, uv = [], [], []
    for row in range(27):
        t = row / 26
        h = .425 + .51 * t
        for col in range(21):
            x = side * (.004 + (.135 - .022 * t) * col / 20)
            f = (.119 - .025 * t) * math.sqrt(max(.1, 1 - (x / (.181 - .03 * t)) ** 2)) + .006
            pts.append((x, h, f + .002 * math.sin(col * .7 + t * 9)))
            uv.append((col / 20, t * 1.5))
            if row and col:
                k = (row - 1) * 21 + col - 1
                fs.append((k, k + 1, k + 22, k + 21))
    apron = mesh('FadedApronPanel', pts, fs, mats['Apron'], 'skirt.L' if side < 0 else 'skirt.R', uv, dust=True)
    solidify(apron, .002)
loft('WrappedWaistSash', [(.927, .151, .102, 0, 0), (.946, .153, .103, 0, 0), (.982, .149, .100, 0, 0)], mats['Sash'], 'hips', 64, .02)
for i in range(4):
    curve('SashSoftFold', [(.153 * math.cos(math.pi * j / 32), .936 + i * .011 + .003 * math.cos(j * .2), .106 * math.sin(math.pi * j / 32)) for j in range(33)], .0021, mats['Fold'], 'hips')
sphere('SashKnot', (-.103, .953, .085), (.022, .022, .017), mats['Sash'], 'hips')
ribbon('TiedSashTail', [(-.109, .95, .10), (-.119, .83, .11), (-.112, .69, .135)], .040, mats['Sash'], 'hips')

# Raised left hand holds the shoulder pole; right hand hangs beside the purse.
shoulders = {'L': (-.158, 1.286, -.012), 'R': (.158, 1.286, 0)}
elbows = {'L': (-.293, 1.102, .025), 'R': (.235, 1.046, .016)}
wrists = {'L': (-.311, 1.278, .016), 'R': (.252, .855, .036)}
hands = {'L': (-.311, 1.324, -.012), 'R': (.254, .817, .042)}
for side, suffix in [(-1, 'L'), (1, 'R')]:
    a, b, w = shoulders[suffix], elbows[suffix], wrists[suffix]
    tube('IndigoSleeve.' + suffix, a, b, .063, .070, mats['Robe'], 'upper_arm.' + suffix, 40, .06)
    end = tuple(Vector(b).lerp(Vector(w), .28))
    tube('RolledLinenCuff.' + suffix, b, end, .073, .072, mats['Linen'], 'forearm.' + suffix, 40, .045)
    tube('ExposedForearm.' + suffix, end, w, .035, .023, mats['Skin'], 'forearm.' + suffix, 32)
    cx, h, f = hands[suffix]
    tube('ConnectedWrist.' + suffix, w, (cx, h + (-.014 if suffix == 'L' else .014), f), .024, .023, mats['Skin'], 'hand.' + suffix, 32)
    sphere('Palm.' + suffix, (cx, h, f), (.025, .035, .021), mats['Skin'], 'hand.' + suffix)
    for finger in range(4):
        xx = cx - .018 + finger * .011
        if suffix == 'L':
            path = [(xx, h + .008, f + .016), (xx, h + .029, f + .012), (xx, h + .033, f - .013), (xx, h + .016, f - .028)]
        else:
            path = [(xx, h - .012, f + .012), (xx, h - .043, f + .014), (xx - .001, h - .050, f + .004)]
        curve('CurvedFinger.' + suffix, path, .0058, mats['Skin'], 'hand.' + suffix, [1] * (len(path) - 1) + [.55])
    curve('Thumb.' + suffix, [(cx - side * .020, h + .014, f), (cx - side * .030, h, f + .021), (cx - side * .010, h - .009, f + .027)], .0076, mats['Skin'], 'hand.' + suffix, [1, 1, .5])

# Thick hood: an open elliptical forehead edge, domed crown and long rear veil.
points, faces, uv = [], [], []
N, R = 112, 32
for row in range(R + 1):
    t = row / R
    for col in range(N):
        a = math.tau * col / N
        front = max(0, math.sin(a))
        low = 1.226 + .435 * front ** 1.2
        if t < .58:
            q = t / .58
            h = low * (1 - q) + 1.649 * q
            rx = (.173 - .063 * front) * (1 - q) + .105 * q
            rf = (.123 - .018 * front) * (1 - q) + .090 * q
        else:
            phi = (t - .58) / .42 * math.pi / 2
            h = 1.649 + .095 * math.sin(phi)
            rx = .105 * math.cos(phi) + .001
            rf = .090 * math.cos(phi) + .001
        wave = .0025 * math.sin(a * 15 + t * 9) * math.sin(t * math.pi)
        points.append(((rx + wave) * math.cos(a), h, -.026 + (rf + wave) * math.sin(a)))
        uv.append((col / N * 2, t * 2))
for row in range(R):
    for col in range(N):
        k, n = row * N + col, row * N + (col + 1) % N
        faces.append((k, n, n + N, k + N))
hood = mesh('DrapedCharcoalHood', points, faces, mats['Veil'], 'head', uv)
solidify(hood, .003)
for group in list(hood.vertex_groups):
    hood.vertex_groups.remove(group)
hg = {n: hood.vertex_groups.new(name=n) for n in ['head', 'veil']}
for v in hood.data.vertices:
    blend = max(0, min(1, (v.co.z - 1.30) / .21))
    if blend:
        hg['head'].add([v.index], blend, 'REPLACE')
    if blend < 1:
        hg['veil'].add([v.index], 1 - blend, 'REPLACE')
# Visible indigo cap hugs the forehead and temples inside the black drape.
pts, fs, uv = [], [], []
for i in range(81):
    a = -.12 + (math.pi + .24) * i / 80
    for edge in [-1, 1]:
        h = 1.515 + .115 * max(0, math.sin(a)) + edge * .018
        pts.append((.098 * math.cos(a), h, -.008 + .081 * math.sin(a)))
        uv.append((i / 80 * 2, (edge + 1) / 2 * .3))
    if i:
        fs.append((i * 2 - 2, i * 2 - 1, i * 2 + 1, i * 2))
cap = mesh('FittedIndigoUndercap', pts, fs, mats['UnderCap'], 'head', uv)
solidify(cap, .002)
def scarf_point(t, a, extra=0):
    ripple = .0016 * math.sin(t * 38 + a * .5)
    rx = .169 * (1 - t) + .078 * t
    rf = .115 * (1 - t) + .073 * t + ripple
    h = 1.295 + .130 * t - .025 * math.sin(a) * t * t - .018 * math.sin(a) * (1 - t)
    return (rx * math.cos(a), h, (rf + extra) * math.sin(a) + .014)


# Continuous cloth behind every fold: no floating cords across the throat.
pts, fs = [], []
for row in range(24):
    t = row / 23
    for col in range(49):
        a = .10 + (math.pi - .20) * col / 48
        pts.append(scarf_point(t, a))
        if row and col:
            k = (row - 1) * 49 + col - 1
            fs.append((k, k + 1, k + 50, k + 49))
bib = mesh('WrappedScarfBib', pts, fs, mats['Veil'], 'veil')
solidify(bib, .003)
for fold in range(6):
    t = .10 + fold * .145
    pts = [scarf_point(t, .13 + (math.pi - .26) * i / 48, .0007) for i in range(49)]
    curve('LayeredScarfFrontFold', pts, .0019, mats['VeilEdge'], 'veil', [.15] + [.70] * 47 + [.15])
for i in range(6):
    x = -.075 + i * .030
    curve('RearVeilVerticalFold', [(x * 1.5, 1.25, -.144), (x * 1.25, 1.38, -.148), (x, 1.53, -.125), (x * .60, 1.65, -.100)], .0023, mats['VeilEdge'], 'veil', [.1, .6, 1, .1])

# Shoulder/temple pins and the long silver ear-pick from the sheet.
def medallion(name, center, radius, mat, joint):
    x, h, f = center
    sphere(name, center, (radius, radius, .004), mat, joint, 32, 16)
    curve(name + 'Rim', [(x + radius * .82 * math.cos(math.tau * i / 40), h + radius * .82 * math.sin(math.tau * i / 40), f + .004) for i in range(41)], .0011, mats['BrassDark'], joint)
    sphere(name + 'Boss', (x, h, f + .005), (radius * .24, radius * .24, .002), mats['BrassDark'], joint, 16, 10)


medallion('ShoulderScarfBrooch', (-.129, 1.294, .119), .016, mats['Brass'], 'spine')
medallion('TemplePin', (-.094, 1.571, .043), .009, mats['Brass'], 'head')
curve('SilverEarPickChain', [(-.095, 1.563, .047), (-.098, 1.49, .058), (-.114, 1.413, .078), (-.121, 1.336, .117)], .0012, mats['Silver'], 'veil')
curve('LongSilverEarPick', [(-.121, 1.344, .12), (-.125, 1.288, .127), (-.127, 1.252, .126)], .0018, mats['Silver'], 'veil', [.8, .75, .4])
sphere('EarPickSpoon', (-.127, 1.25, .126), (.003, .005, .0017), mats['Silver'], 'veil', 16, 10)

# Waist purse, key rings, small scale and circular compass (fictional game props).
sphere('WaistClothPurse', (.121, .833, .102), (.049, .104, .030), mats['Bag'], 'pouch', 32, 24)
curve('PurseDrawstring', [(.08, .918, .114), (.118, .928, .127), (.158, .917, .113)], .0028, mats['Rope'], 'pouch')
for i in range(5):
    x = .070 + i * .018
    curve('HangingTradeCord', [(x, .967, .110), (x + .004, .914 - i * .014, .127), (x + .001, .893 - i * .014, .129)], .0017, mats['Rope'], 'charms')
    medallion('TradeCoin', (x + .001, .884 - i * .014, .132), .008, mats['Brass'], 'charms')
medallion('BrassCompass', (.137, .698, .129), .026, mats['Brass'], 'charms')
curve('CompassHangingCord', [(.139, .923, .128), (.150, .814, .129), (.137, .726, .129)], .0017, mats['Rope'], 'charms')
curve('CompassNeedle', [(.124, .688, .137), (.147, .710, .137)], .0011, mats['BrassDark'], 'charms')
curve('SmallSteelyardBeam', [(-.141, .891, .108), (-.125, .796, .127)], .0038, mats['Wood'], 'charms')
for i in range(5):
    h = .817 + i * .013
    curve('ScaleGraduation', [(-.13, h, .132), (-.122, h, .132)], .0006, mats['Brass'], 'charms')

# The loaded shoulder pole and baskets form a separate stowable hierarchy.
pole_path = [(-.675, 1.333, -.025), (-.43, 1.351, -.029), (-.18, 1.348, -.037), (0, 1.334, -.045), (.23, 1.344, -.037), (.45, 1.350, -.03), (.675, 1.331, -.025)]
curve('CurvedWoodShoulderPole', pole_path, .014, mats['Wood'], 'yoke')
for grain in range(6):
    a = math.tau * grain / 6
    curve('PoleLongGrain', [(x, h + .0136 * math.cos(a), f + .0136 * math.sin(a)) for x, h, f in pole_path], .0007, mats['Grain'], 'yoke')


def basket(side, suffix):
    cx, cf, bottom, top = side * .555, -.025, .405, .777
    joint = 'cargo.' + suffix
    # Dark inner wall behind actual alternating wicker strips.
    shell = loft('BasketInnerWall.' + suffix, [(bottom, .128, .101, cx, cf), (.44, .142, .113, cx, cf), (.64, .169, .137, cx, cf), (top, .173, .140, cx, cf)], mats['BambooDark'], joint, 64)
    # Remove cap at top so the rim reads as an open container full of goods.
    bm = bmesh.new()
    bm.from_mesh(shell.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[-1]], context='FACES_ONLY')
    bm.to_mesh(shell.data)
    bm.free()
    for row in range(22):
        t = row / 21
        h = bottom + .010 + t * (top - bottom - .018)
        rx, rf = .132 + .043 * math.sin(t * math.pi / 2), .105 + .037 * math.sin(t * math.pi / 2)
        path = []
        for step in range(97):
            a = math.tau * step / 96
            weave = .0022 * math.sin(a * 32 + (row % 2) * math.pi)
            path.append((cx + (rx + weave) * math.cos(a), h, cf + (rf + weave) * math.sin(a)))
        curve('BasketHorizontalWeave', path, .0029, mats['BambooLight'] if row % 3 == 0 else mats['Bamboo'], joint)
    for rib in range(48):
        a = math.tau * rib / 48
        path = []
        for step in range(31):
            t = step / 30
            wobble = .0017 * math.sin(t * math.tau * 11 + rib * math.pi)
            path.append((cx + (.132 + .043 * math.sin(t * math.pi / 2) + wobble) * math.cos(a), bottom + .010 + t * (top - bottom - .018), cf + (.105 + .037 * math.sin(t * math.pi / 2) + wobble) * math.sin(a)))
        curve('BasketVerticalWeave', path, .0022, mats['BambooLight'], joint)
    for h, rx, rf in [(bottom + .007, .132, .105), (top, .176, .143)]:
        curve('BasketBoundRim', [(cx + rx * math.cos(math.tau * j / 80), h, cf + rf * math.sin(math.tau * j / 80)) for j in range(81)], .0065, mats['Bamboo'], joint)
    for ix in [-1, 1]:
        for front in [-1, 1]:
            path = [(side * .624, 1.337, -.025), (cx + ix * .073, 1.038, cf + front * .070), (cx + ix * .130, top + .006, cf + front * .095)]
            curve('BasketSuspension', path, .0045, mats['Rope'], joint)
    # Knots around the pole are attached to the yoke, not to a moving arm.
    for ring in range(5):
        x = side * .624 + (ring - 2) * .005
        curve('PoleLashing', [(x, 1.337 + .021 * math.cos(math.tau * j / 24), -.025 + .021 * math.sin(math.tau * j / 24)) for j in range(25)], .0028, mats['Rope'], 'yoke')
    goods = [mats['RedGoods'], mats['BlueGoods'], mats['CreamGoods']]
    for i in range(17):
        a = i * 2.399963
        rad = math.sqrt((i + .5) / 17)
        x = cx + .139 * rad * math.cos(a)
        f = cf + .104 * rad * math.sin(a)
        h = .777 + rng.uniform(-.010, .046)
        mat = goods[i % 3]
        if suffix == 'L':
            # Upright rolled cloth and spools; concentric rings read at close range.
            hh = .043 + rng.random() * .039
            roll = loft('RolledClothGoods', [(h - hh / 2, .018, .018, x, f), (h + hh / 2, .019, .019, x, f)], mat, joint, 24)
            for ring in range(3):
                r = .005 + ring * .0048
                curve('ClothRollSpiral', [(x + r * math.cos(math.tau * j / 24), h + hh / 2 + .001, f + r * math.sin(math.tau * j / 24)) for j in range(25)], .00085, mats['Thread'], joint)
        else:
            sphere('BundledDryGoods', (x, h, f), (.025, .030 + rng.random() * .012, .024), mat, joint, 18, 12)
            curve('ParcelTwine', [(x - .02, h, f), (x, h + .034, f), (x + .02, h, f)], .0014, mats['Rope'], joint)
    for i in range(23):
        a = i * 2.399963
        rad = .11 * math.sqrt((i + .5) / 23)
        sphere('SmallDriedFruit', (cx + rad * math.cos(a), .778 + rng.random() * .03, cf + rad * .75 * math.sin(a)), (.011, .013, .010), mats['Fruit'], joint, 12, 8)
    if suffix == 'L':
        # Draped indigo sample and small cream label, both below the goods line.
        ribbon('HangingClothSample', [(cx + .040, .813, cf + .052), (cx + .038, .773, cf + .145), (cx + .033, .64, cf + .155), (cx + .050, .49, cf + .151)], .075, mats['BlueGoods'], joint)
        ribbon('BasketCreamTradeLabel', [(cx - .055, .784, cf + .146), (cx - .052, .709, cf + .151)], .049, mats['CreamGoods'], joint)
        for i in range(4):
            curve('SampleBorderStitch', [(cx + .013, .51 + i * .055, cf + .157), (cx + .023, .516 + i * .055, cf + .158)], .001, mats['Thread'], joint)


basket(-1, 'L')
basket(1, 'R')
curve_batch.flush()
print('YANG_MESH_PARTS_READY', len(geo.parts), flush=True)

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
character.name = 'YangSanniang_CharacterMesh'
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

# Independent skirt, veil and cargo bones. The entire yoke can be stowed atomically.
arm_data = bpy.data.armatures.new('杨三娘_骨架')
armature = bpy.data.objects.new('YangSanniang_Armature', arm_data)
collection.objects.link(armature)
bpy.ops.object.select_all(action='DESELECT')
armature.select_set(True)
bpy.context.view_layer.objects.active = armature
bpy.ops.object.mode_set(mode='EDIT')


def bone(name, head, tail, parent=None):
    item = arm_data.edit_bones.new(name)
    item.head, item.tail = p(head), p(tail)
    if parent:
        item.parent = arm_data.edit_bones[parent]


bone('root', (0, 0, 0), (0, .12, 0))
bone('hips', (0, .88, 0), (0, 1.02, 0), 'root')
bone('spine', (0, 1.02, 0), (0, 1.29, 0), 'hips')
bone('neck', (0, 1.29, 0), (0, 1.38, 0), 'spine')
bone('head', (0, 1.38, 0), (0, 1.72, 0), 'neck')
bone('eyes', (0, 1.528, .07), (0, 1.56, .07), 'head')
bone('skirt.L', (-.09, .92, .06), (-.10, .43, .08), 'hips')
bone('skirt.R', (.09, .92, .06), (.10, .43, .08), 'hips')
bone('skirt.back', (0, .92, -.07), (0, .43, -.10), 'hips')
bone('pouch', (.12, .93, .11), (.12, .75, .12), 'hips')
bone('charms', (.09, .96, .12), (.12, .70, .13), 'hips')
bone('veil', (0, 1.51, -.05), (0, 1.24, -.10), 'head')
bone('yoke', (0, 1.33, -.04), (0, 1.43, -.04), 'spine')
for side, suffix in [(-1, 'L'), (1, 'R')]:
    bone('cargo.' + suffix, (side * .624, 1.337, -.025), (side * .555, .60, -.025), 'yoke')
    bone('upper_arm.' + suffix, shoulders[suffix], elbows[suffix], 'spine')
    bone('forearm.' + suffix, elbows[suffix], wrists[suffix], 'upper_arm.' + suffix)
    bone('hand.' + suffix, wrists[suffix], hands[suffix], 'forearm.' + suffix)
    bone('thigh.' + suffix, (side * .079, .88, 0), (side * .079, .40, 0), 'hips')
    bone('shin.' + suffix, (side * .079, .40, 0), (side * .079, .10, 0), 'thigh.' + suffix)
    bone('foot.' + suffix, (side * .079, .10, 0), (side * .079, .04, .13), 'shin.' + suffix)
bpy.ops.object.mode_set(mode='OBJECT')
arm_data.display_type = 'STICK'
assert len(arm_data.bones) == 27
character.parent = armature
character.matrix_parent_inverse = Matrix.Identity(4)
modifier = character.modifiers.new('骨骼蒙皮', 'ARMATURE')
modifier.object = armature
assert all(v.groups for v in character.data.vertices)
assert all(g.name in arm_data.bones for g in character.vertex_groups)


def rotate(name, axis, angle):
    pose = armature.pose.bones[name]
    local = pose.bone.matrix_local.to_3x3().inverted() @ Vector(axis)
    pose.rotation_quaternion = Quaternion(local.normalized(), angle)


armature.animation_data_create()
bpy.context.scene.render.fps = 30
actions = {}
for mode, frames in [('idle', 141), ('walk', 24), ('jump', 24), ('push', 24), ('carry', 24), ('inspect', 90)]:
    action = bpy.data.actions.new(mode)
    action.use_fake_user = True
    armature.animation_data.action = action
    for frame in range(frames + 1):
        time, phase = frame / 30, math.tau * frame / frames
        stride = math.sin(phase) if mode in {'walk', 'push', 'carry'} else 0
        for pose in armature.pose.bones:
            pose.rotation_mode = 'QUATERNION'
            pose.rotation_quaternion = Quaternion()
            pose.location = (0, 0, 0)
            pose.scale = (1, 1, 1)
        rotate('head', (0, 1, 0), math.sin(time * 1.4) * .009)
        rotate('veil', (1, 0, 0), stride * .018)
        rotate('skirt.L', (1, 0, 0), stride * .09)
        rotate('skirt.R', (1, 0, 0), -stride * .09)
        rotate('skirt.back', (1, 0, 0), stride * .025)
        rotate('pouch', (1, 0, 0), stride * .025)
        rotate('charms', (0, 1, 0), stride * .07)
        rotate('yoke', (0, 1, 0), stride * .009)
        rotate('cargo.L', (1, 0, 0), stride * .023)
        rotate('cargo.R', (1, 0, 0), -stride * .023)
        for suffix, sign in [('L', 1), ('R', -1)]:
            rotate('thigh.' + suffix, (1, 0, 0), stride * .27 * sign)
            rotate('shin.' + suffix, (1, 0, 0), max(0, -stride * sign) * .32)
            if mode == 'walk' and suffix == 'R':
                rotate('upper_arm.R', (1, 0, 0), stride * .14)
        if mode == 'jump':
            rotate('thigh.L', (1, 0, 0), -.28)
            rotate('thigh.R', (1, 0, 0), .24)
            rotate('shin.L', (1, 0, 0), .48)
            rotate('shin.R', (1, 0, 0), .50)
            # Lower the raised hand while the cargo is stowed.
            rotate('forearm.L', (1, 0, 0), 1.7)
            armature.pose.bones['yoke'].scale = (.001, .001, .001)
        if mode in {'push', 'carry'}:
            for suffix in ['L', 'R']:
                rotate('upper_arm.' + suffix, (1, 0, 0), -.85 if mode == 'push' else -1.05)
                rotate('forearm.' + suffix, (1, 0, 0), 1.85 if suffix == 'L' else -.20)
            armature.pose.bones['yoke'].scale = (.001, .001, .001)
        if mode == 'inspect':
            rotate('head', (1, 0, 0), .07)
            rotate('upper_arm.R', (1, 0, 0), -.43)
            rotate('forearm.R', (1, 0, 0), -.70)
        if mode == 'idle' and frame in range(135, 140):
            armature.pose.bones['eyes'].scale.y = .08
        for pose in armature.pose.bones:
            for prop in ['rotation_quaternion', 'location', 'scale']:
                pose.keyframe_insert(data_path=prop, frame=frame, group=pose.name)
    actions[mode] = action
armature.animation_data.action = actions['idle']
scene = bpy.context.scene
scene.frame_start, scene.frame_end = 0, 141
scene.frame_set(0)
ref_collection = bpy.data.collections.new('REFERENCE_杨三娘用户三视图')
scene.collection.children.link(ref_collection)
image = bpy.data.images.load(str(PROJECT / 'references/杨三娘_用户三视图.png'))
image.pack()
reference = bpy.data.objects.new('杨三娘_用户原图', None)
reference.empty_display_type, reference.data = 'IMAGE', image
reference.empty_display_size = 3.5
reference.location = (-3.5, 0, 1)
reference.rotation_euler = (math.pi / 2, 0, 0)
reference.hide_render = True
ref_collection.objects.link(reference)
export_path = ASSETS / 'yang_sanniang_rigged.glb'
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
hood_mat = next(m for m in gltf['materials'] if m['name'] == 'Yang_CharcoalHeadscarf')
assert hood_mat['pbrMetallicRoughness'].get('baseColorTexture') and hood_mat['pbrMetallicRoughness']['baseColorFactor'][0] < .05
report = {'blender': bpy.app.version_string, 'character': '杨三娘', 'bones': 27, 'vertices': len(character.data.vertices), 'polygons': len(character.data.polygons), 'animations': [a['name'] for a in gltf['animations']], 'skins': 1, 'uv_layers': len(character.data.uv_layers), 'vertex_ao_samples': 64, 'packed_images': 2, 'glb': str(export_path)}
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
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / '杨三娘_角色工程.blend'))
print('YANG_SANNIANG_BLENDER_OK', json.dumps(report, ensure_ascii=False))
