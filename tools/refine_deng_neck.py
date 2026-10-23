"""Revise the v2 Blender source: a shaped jaw, visible neck and vertex AO.

Open 邓书年_面部精修与转身.blend before running. The v2 file stays intact.
"""
import bpy
import bmesh
import contextlib
import io
import json
import math
import struct
from pathlib import Path
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT/'character-source/deng_shunian'
body = bpy.data.objects['Deng_CharacterMesh']
armature = bpy.data.objects['Deng_Armature']
assert len(armature.data.bones) == 24
assert body.matrix_world == Matrix.Identity(4)
armature.animation_data.action = bpy.data.actions['idle']
bpy.context.scene.frame_set(0)
skin = bpy.data.materials['Face_SoftSkin']
skin_index = list(body.data.materials).index(skin)
old_indices = {index for face in body.data.polygons if face.material_index == skin_index for index in face.vertices}
bm = bmesh.new()
bm.from_mesh(body.data)
bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[bm.verts[index] for index in old_indices],context='VERTS')
bm.to_mesh(body.data)
bm.free()
neck_skin = skin.copy()
neck_skin.name = 'Face_Neck'
color_name = body.data.color_attributes[0].name
SCALE = .86
ORIGIN = Vector((0,0,1.48*SCALE))
TILT = Matrix.Rotation(.02,3,'Y')

def world(point):
    x,h,f = point
    return ORIGIN+TILT@(Vector((x,-f,h))*SCALE)

PROFILE = [(.030,.047,.046,.018),(.039,.055,.055,.013),
           (.055,.071,.071,.003),(.075,.083,.079,0),
           (.105,.090,.087,0),(.15,.103,.092,0),(.21,.108,.095,0),
           (.27,.105,.092,0),(.32,.090,.080,0),(.35,.070,.065,0)]

def profile(h):
    for i in range(len(PROFILE)-1):
        if h <= PROFILE[i+1][0]:
            a,b = PROFILE[i],PROFILE[i+1]
            before,after = PROFILE[max(0,i-1)],PROFILE[min(len(PROFILE)-1,i+2)]
            t = max(0,(h-a[0])/(b[0]-a[0]))
            result = []
            for d in [1,2,3]:
                ma = (b[d]-before[d])/(b[0]-before[0])
                mb = (after[d]-a[d])/(after[0]-a[0])
                result.append((2*t**3-3*t*t+1)*a[d]+(t**3-2*t*t+t)*ma*(b[0]-a[0])+
                              (-2*t**3+3*t*t)*b[d]+(t**3-t*t)*mb*(b[0]-a[0]))
            return result
    return PROFILE[-1][1:]

def gaussian(x,h,cx,ch,sx,sh):
    return math.exp(-((x-cx)/sx)**2-((h-ch)/sh)**2)

def deformation(x,h):
    result = .015*gaussian(x,h,0,.191,.012,.056)+.022*gaussian(x,h,0,.146,.014,.025)
    for side in [-1,1]:
        result += .006*gaussian(x,h,side*.014,.135,.010,.016)
        result -= .009*gaussian(x,h,side*.047,.214,.035,.027)
        result += .004*gaussian(x,h,side*.052,.255,.034,.012)
        result += .003*gaussian(x,h,side*.064,.156,.030,.021)
    return result+.003*gaussian(x,h,0,.076,.040,.014)

def add_mesh(name,points,faces,mat,neck=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata([world(point) for point in points],[],faces)
    data.update()
    obj = bpy.data.objects.new(name,data)
    body.users_collection[0].objects.link(obj)
    data.materials.append(mat)
    for face in data.polygons: face.use_smooth = True
    colors = data.color_attributes.new(name=color_name,type='FLOAT_COLOR',domain='CORNER')
    for item in colors.data: item.color = (1,1,1,1)
    if neck:
        neck_group = obj.vertex_groups.new(name='neck')
        head_group = obj.vertex_groups.new(name='head')
        for index,point in enumerate(points):
            amount = min(1,max(0,(point[1]-.005)/.055))*.65
            neck_group.add([index],1-amount,'REPLACE')
            if amount: head_group.add([index],amount,'REPLACE')
    else:
        group = obj.vertex_groups.new(name='head')
        group.add(list(range(len(points))),1,'REPLACE')
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    return obj

points,faces = [],[]
ROWS,COLS = 82,128
for row in range(ROWS+1):
    h = .030+.320*row/ROWS
    rx,rz,center = profile(h)
    for col in range(COLS):
        angle = math.tau*col/COLS
        sine = math.sin(angle)
        # The mandibular edge rises toward the ear; its front projects beyond
        # the neck, producing an actual underside beneath the chin.
        raised = .018*(1-sine)*max(0,1-(h-.030)/.070)**2
        x = rx*math.cos(angle)
        f = center+rz*sine+deformation(x,h)*max(0,sine)**8
        points.append((x,h+raised,f))
for row in range(ROWS):
    for col in range(COLS):
        a = row*COLS+col
        b = row*COLS+(col+1)%COLS
        faces.append((a,b,b+COLS,a+COLS))
center_index = len(points)
points.append((0,.053,-.006))
for col in range(COLS): faces.append((center_index,(col+1)%COLS,col))
faces.append(tuple(ROWS*COLS+col for col in range(COLS)))
head = add_mesh('Deng_v3_ShapedJaw',points,faces,skin)

neck_points,neck_faces = [],[]
NR,NC = 36,96
for row in range(NR+1):
    t = row/NR
    h = -.140+.206*t
    # Slim middle, slightly flared base; top disappears inside the jaw.
    rx = .036+.014*(1-t)**3+.006*t**4
    rz = .030+.011*(1-t)**3+.006*t**4
    center = -.013+.005*t
    for col in range(NC):
        angle = math.tau*col/NC
        x = rx*math.cos(angle)
        f = center+rz*math.sin(angle)
        # Very shallow neck tendons; not separate tubes on top of the skin.
        if math.sin(angle)>0:
            f += .0012*sum(gaussian(x,h,s*.022,-.035,.007,.065) for s in [-1,1])*math.sin(angle)**4
        neck_points.append((x,h,f))
for row in range(NR):
    for col in range(NC):
        a = row*NC+col
        b = row*NC+(col+1)%NC
        neck_faces.append((a,b,b+NC,a+NC))
neck_faces += [tuple(reversed(range(NC))),tuple(NR*NC+col for col in range(NC))]
neck = add_mesh('Deng_v3_VisibleNeck',neck_points,neck_faces,neck_skin,True)

bpy.ops.object.select_all(action='DESELECT')
for obj in [body,head,neck]: obj.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
body.data.update()

# Geometric ambient occlusion is stored in the primary glTF vertex colors.
# It follows the hat/jaw geometry and remains available in Blender and Godot.
bm = bmesh.new()
bm.from_mesh(body.data)
bvh = BVHTree.FromBMesh(bm)
bm.free()
skin_slots = {index for index,mat in enumerate(body.data.materials) if mat in [skin,neck_skin]}
skin_vertices = {index for face in body.data.polygons if face.material_index in skin_slots for index in face.vertices}
neck_slot = list(body.data.materials).index(neck_skin)
neck_vertices = {index for face in body.data.polygons if face.material_index == neck_slot for index in face.vertices}
SAMPLES = 64
directions = []
for index in range(SAMPLES):
    radius = math.sqrt((index+.5)/SAMPLES)
    angle = index*2.399963229728653
    directions.append((radius*math.cos(angle),radius*math.sin(angle),math.sqrt(1-radius*radius)))
occlusion = {}
for index in skin_vertices:
    vertex = body.data.vertices[index]
    normal = vertex.normal.normalized()
    tangent = normal.cross(Vector((0,0,1)))
    if tangent.length < .01: tangent = normal.cross(Vector((1,0,0)))
    tangent.normalize()
    bitangent = normal.cross(tangent).normalized()
    origin = vertex.co+normal*.0006
    blocked = 0
    for x,y,z in directions:
        hit,_,_,distance = bvh.ray_cast(origin,tangent*x+bitangent*y+normal*z,.100)
        if hit is not None:
            blocked += math.exp(-distance/.055)
    occlusion[index] = blocked/SAMPLES
# Smooth sample noise without flattening the jaw's occlusion boundary.
neighbors = {index:set() for index in skin_vertices}
for edge in body.data.edges:
    a,b = edge.vertices
    if a in neighbors and b in neighbors:
        neighbors[a].add(b)
        neighbors[b].add(a)
for _ in range(3):
    occlusion = {index:.55*value+.45*sum(occlusion[n] for n in neighbors[index])/max(1,len(neighbors[index]))
                 for index,value in occlusion.items()}
colors = body.data.color_attributes[color_name]
assert colors.domain == 'CORNER'
shadow_values = []
for loop in body.data.loops:
    index = loop.vertex_index
    if index in occlusion:
        shade = max(.66,1-.60*occlusion[index]**.80)
        if index in neck_vertices: shade *= .92
        colors.data[loop.index].color = (shade,shade*.99,shade*.975,1)
        shadow_values.append(shade)

# Make the same vertex AO visible when the editable source is opened in Blender.
for mat in [skin,neck_skin]:
    nodes = mat.node_tree.nodes
    shader = nodes.get('Principled BSDF')
    base = shader.inputs['Base Color'].default_value[:]
    attribute = nodes.new('ShaderNodeVertexColor')
    attribute.layer_name = color_name
    multiply = nodes.new('ShaderNodeMix')
    multiply.data_type = 'RGBA'
    multiply.blend_type = 'MULTIPLY'
    multiply.inputs[0].default_value = 1
    input_a = next(item for item in multiply.inputs if item.name=='A' and item.type=='RGBA')
    input_b = next(item for item in multiply.inputs if item.name=='B' and item.type=='RGBA')
    output = next(item for item in multiply.outputs if item.type=='RGBA')
    input_a.default_value = base
    mat.node_tree.links.new(attribute.outputs['Color'],input_b)
    mat.node_tree.links.new(output,shader.inputs['Base Color'])
    shader.inputs['Roughness'].default_value = .86
    shader.inputs['Specular IOR Level'].default_value = .06

assert all(vertex.groups for vertex in body.data.vertices)
export_path = PROJECT/'assets/characters/deng_shunian/deng_shunian_neck_v3.glb'
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
armature.select_set(True)
bpy.context.view_layer.objects.active = armature
with contextlib.redirect_stdout(io.StringIO()):
    bpy.ops.export_scene.gltf(filepath=str(export_path),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False)
raw = export_path.read_bytes()
length = struct.unpack_from('<I',raw,12)[0]
gltf = json.loads(raw[20:20+length].decode('utf-8'))
names = [action['name'] for action in gltf['animations']]
assert set(names) == {'idle','walk','jump','push','carry','inspect'}
assert len(gltf['skins']) == 1
export_skin = next(mat for mat in gltf['materials'] if mat['name']=='Face_SoftSkin')
assert .40 < export_skin['pbrMetallicRoughness']['baseColorFactor'][0] < .55, 'Skin factor lost during AO export'
report = {'blender':bpy.app.version_string,'revision':'neck-shadow-v3',
          'bones':len(armature.data.bones),'vertices':len(body.data.vertices),'polygons':len(body.data.polygons),
          'animations':names,'skins':1,'uv_layers':len(body.data.uv_layers),
          'neck_target_mid_width_m':.036*2*SCALE,'visible_neck_height_estimate_m':.085,
          'vertex_ao_samples':SAMPLES,'vertex_ao_range_m':.100,
          'skin_shadow_factor_min':min(shadow_values),'skin_shadow_factor_max':max(shadow_values),
          'glb':str(export_path)}
(OUT/'validation-neck-v3.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
if hasattr(bpy.context.preferences.filepaths,'file_preview_type'):
    bpy.context.preferences.filepaths.file_preview_type = 'NONE'
bpy.context.scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'邓书年_颈部与光影修订.blend'))
print('DENG_NECK_SHADOW_OK',json.dumps(report,ensure_ascii=False))
