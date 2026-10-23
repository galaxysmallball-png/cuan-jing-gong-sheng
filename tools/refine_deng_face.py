"""Refine the existing Blender source without rebuilding its body or animation.

Run with the original character .blend already open in background Blender.
The first source and GLB are retained; this writes a second editable revision.
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

PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT / 'character-source/deng_shunian'
ASSETS = PROJECT / 'assets/characters/deng_shunian'
body = bpy.data.objects['Deng_CharacterMesh']
armature = bpy.data.objects['Deng_Armature']
assert len(armature.data.bones) == 24
assert body.matrix_world == Matrix.Identity(4)
scene = bpy.context.scene
armature.animation_data.action = bpy.data.actions['idle']
scene.frame_set(0)

# Remove the first head, projecting eyeballs and polygonal facial marks.
# Hats, ribbons, clothes, hands, skin weights and all six actions stay intact.
group_names = {group.index: group.name for group in body.vertex_groups}
remove = set()
for vertex in body.data.vertices:
    joints = {group_names[item.group] for item in vertex.groups if item.weight > 0.5}
    if 'eyes' in joints:
        remove.add(vertex.index)
for poly in body.data.polygons:
    material = body.data.materials[poly.material_index]
    facial = material and material.name.startswith(('Skin', 'Hair', 'EyeWhite', 'Iris', 'Pupil'))
    if not facial:
        continue
    for index in poly.vertices:
        vertex = body.data.vertices[index]
        joints = {group_names[item.group] for item in vertex.groups if item.weight > 0.5}
        if 'head' in joints or ('spine' in joints and vertex.co.z > 1.17 and abs(vertex.co.x) < 0.07):
            remove.add(index)
bm = bmesh.new()
bm.from_mesh(body.data)
bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm, geom=[bm.verts[index] for index in remove], context='VERTS')
bm.to_mesh(body.data)
bm.free()
print('OLD_FACE_REMOVED', len(remove), 'vertices')

parts = []
SCALE = 0.86
ORIGIN = Vector((0, 0, 1.48*SCALE))
TILT = Matrix.Rotation(0.02, 3, 'Y')

def world(point):
    x, height, front = point
    return ORIGIN + TILT @ (Vector((x, -front, height))*SCALE)

def material(name, color, roughness=0.88):
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    shader = result.node_tree.nodes.get('Principled BSDF')
    # Input palette is sRGB; Blender/glTF shader constants use linear RGB.
    linear = tuple(value/12.92 if value <= .04045 else ((value+.055)/1.055)**2.4 for value in color)
    shader.inputs['Base Color'].default_value = (*linear, 1)
    shader.inputs['Roughness'].default_value = roughness
    shader.inputs['Specular IOR Level'].default_value = 0.13
    result.diffuse_color = (*linear, 1)
    return result

skin = material('Face_SoftSkin', (0.72, 0.60, 0.47))
ear_skin = material('Face_EarAndLid', (0.72, 0.57, 0.44))
fold = material('Face_SoftFold', (0.25, 0.15, 0.105))
hair = material('Face_MatteHair', (0.13, 0.115, 0.10))
brow = material('Face_Brows', (0.20, 0.17, 0.14))
white = material('Face_EyeIvory', (0.88, 0.86, 0.80), 0.62)
iris = material('Face_IrisBrown', (0.20, 0.16, 0.12), 0.56)
pupil = material('Face_Pupil', (0.04, 0.05, 0.035), 0.45)
shine = material('Face_Catchlight', (0.96, 0.95, 0.86), 0.4)
lip = material('Face_Lip', (0.43, 0.28, 0.23))
mouth = material('Face_MouthLine', (0.27, 0.18, 0.13))

def bind(obj, joint='head'):
    group = obj.vertex_groups.new(name=joint)
    group.add(list(range(len(obj.data.vertices))), 1, 'REPLACE')
    parts.append(obj)
    return obj

def mesh(name, vertices, faces, mat, joint='head', colors=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata([world(point) for point in vertices], [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    body.users_collection[0].objects.link(obj)
    obj.data.materials.append(mat)
    for poly in data.polygons:
        poly.use_smooth = True
    if colors:
        attribute = data.color_attributes.new(name='FaceColor', type='FLOAT_COLOR', domain='CORNER')
        for loop in data.loops:
            attribute.data[loop.index].color = (*colors[loop.vertex_index], 1)
    return bind(obj, joint)

def curve(name, points, radius, mat, joint='head', taper=None):
    data = bpy.data.curves.new(name, 'CURVE')
    data.dimensions = '3D'
    data.resolution_u = 12
    data.bevel_depth = radius*SCALE
    data.bevel_resolution = 3
    data.use_fill_caps = True
    spline = data.splines.new('BEZIER')
    spline.bezier_points.add(len(points)-1)
    for index, (point, target) in enumerate(zip(points, spline.bezier_points)):
        target.co = world(point)
        target.handle_left_type = 'AUTO'
        target.handle_right_type = 'AUTO'
        target.radius = taper[index] if taper else 1
    obj = bpy.data.objects.new(name, data)
    body.users_collection[0].objects.link(obj)
    obj.data.materials.append(mat)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target='MESH')
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return bind(obj, joint)

def ellipsoid(name, center, dimensions, mat, joint='head'):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, location=(0,0,0))
    obj = bpy.context.object
    obj.name = name
    for vertex in obj.data.vertices:
        v = vertex.co.copy()
        vertex.co = world((center[0]+v.x*dimensions[0], center[1]+v.z*dimensions[1], center[2]+v.y*dimensions[2]))
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return bind(obj, joint)

PROFILE = [(-.11,.051,.048),(-.04,.050,.047),(0,.050,.051),
           (.027,.064,.065),(.065,.078,.079),(.105,.090,.087),
           (.15,.103,.092),(.21,.108,.095),(.27,.105,.092),
           (.32,.090,.080),(.35,.070,.065)]

def profile(height):
    for index in range(len(PROFILE)-1):
        if height <= PROFILE[index+1][0]:
            a, b = PROFILE[index], PROFILE[index+1]
            before = PROFILE[max(0,index-1)]
            after = PROFILE[min(len(PROFILE)-1,index+2)]
            t = max(0, (height-a[0])/(b[0]-a[0]))
            values = []
            for dim in [1,2]:
                ma = (b[dim]-before[dim])/(b[0]-before[0])
                mb = (after[dim]-a[dim])/(after[0]-a[0])
                span = b[0]-a[0]
                values.append((2*t**3-3*t*t+1)*a[dim]+(t**3-2*t*t+t)*ma*span+
                              (-2*t**3+3*t*t)*b[dim]+(t**3-t*t)*mb*span)
            return values
    return PROFILE[-1][1:]

def gaussian(x, h, cx, ch, sx, sh):
    return math.exp(-((x-cx)/sx)**2-((h-ch)/sh)**2)

def deformation(x, height):
    nose = .015*gaussian(x,height,0,.191,.012,.056)
    nose += .022*gaussian(x,height,0,.146,.014,.025)
    for side in [-1,1]:
        nose += .006*gaussian(x,height,side*.014,.135,.010,.016)
        nose -= .009*gaussian(x,height,side*.047,.214,.035,.027)
        nose += .004*gaussian(x,height,side*.052,.255,.034,.012)
        nose += .003*gaussian(x,height,side*.064,.156,.030,.021)
    nose += .003*gaussian(x,height,0,.076,.040,.014)
    return nose

def surface(x, height):
    rx, rz = profile(height)
    sine = math.sqrt(max(0,1-(x/rx)**2))
    return rz*sine+deformation(x,height)*sine**8

vertices, faces, colors = [], [], []
ROWS, COLS = 90, 128
for row in range(ROWS+1):
    height = -.11+.46*row/ROWS
    rx, rz = profile(height)
    for col in range(COLS):
        angle = math.tau*col/COLS
        sine = math.sin(angle)
        x = rx*math.cos(angle)
        front = rz*sine+deformation(x,height)*max(0,sine)**8
        vertices.append((x,height,front))
        warmth = sum(gaussian(x,height,side*.067,.162,.033,.027) for side in [-1,1])*max(0,sine)**8
        under_eye = sum(gaussian(x,height,side*.047,.188,.030,.012) for side in [-1,1])*max(0,sine)**8
        colors.append((1.0-.004*under_eye,
                       1.0-.025*warmth-.018*under_eye,
                       1.0-.030*warmth-.018*under_eye))
for row in range(ROWS):
    for col in range(COLS):
        a = row*COLS+col
        b = row*COLS+(col+1)%COLS
        faces.append((a,b,b+COLS,a+COLS))
faces += [tuple(reversed(range(COLS))),tuple(ROWS*COLS+col for col in range(COLS))]
head = mesh('Refined_ContinuousFaceAndNeck',vertices,faces,skin,colors=colors)
# glTF multiplies COLOR_0 by this material's constant skin tone. Keeping the
# color attribute near white avoids a second gamma conversion darkening skin.
# Blend the neck into the same head surface rather than leaving a detached jaw.
head.vertex_groups.remove(head.vertex_groups['head'])
head_group = head.vertex_groups.new(name='head')
spine_group = head.vertex_groups.new(name='spine')
for index, point in enumerate(vertices):
    amount = min(1,max(0,(point[1]+.075)/.09))
    amount = amount*amount*(3-2*amount)
    if amount: head_group.add([index],amount,'REPLACE')
    if amount < 1: spine_group.add([index],1-amount,'REPLACE')

# A seated almond-shaped eye, with rounded lids and a small dark pupil.
for side in [-1,1]:
    cx, cy, width, top, bottom = side*.047, .214, .0305, .0215, .017
    def eye_height(u,v):
        span = math.sqrt(max(0,1-u*u))
        return cy+span*(top*v if v>=0 else bottom*v)-side*u*.003
    def eye_depth(x,h,u,v):
        return surface(x,h)+.0028+.0055*(1-u*u)*(1-v*v)
    ev, ef = [], []
    NX, NY = 40, 20
    for row in range(NY+1):
        v = row*2/NY-1
        for col in range(NX+1):
            u = col*2/NX-1
            x = cx+width*u
            h = eye_height(u,v)
            ev.append((x,h,eye_depth(x,h,u,v)))
    for row in range(NY):
        for col in range(NX):
            a = row*(NX+1)+col
            ef.append((a,a+1,a+NX+2,a+NX+1))
    mesh('Refined_EyeWhite',ev,ef,white,'eyes')
    # Iris disks follow the eye surface, so they do not float in front of it.
    for name, rx, ry, mat, lift in [('Iris',.0098,.013,iris,.0007),('Pupil',.0057,.008,pupil,.0013)]:
        disk = [(cx,cy-.001,eye_depth(cx,cy-.001,0,-.001/bottom)+lift)]
        for index in range(65):
            angle = math.tau*index/64
            x, h = cx+rx*math.cos(angle), cy-.001+ry*math.sin(angle)
            u = (x-cx)/width
            span = math.sqrt(max(.001,1-u*u))
            v = (h-cy+side*u*.003)/(span*(top if h>=cy else bottom))
            disk.append((x,h,eye_depth(x,h,u,v)+lift))
        mesh('Refined_'+name,disk,[(0,i+1,i+2) for i in range(64)],mat,'eyes')
    x, h = cx-.003,cy+.004
    ellipsoid('Refined_EyeGlint',(x,h,surface(x,h)+.010),(.0018,.0022,.0008),shine,'eyes')
    for upper in [True,False]:
        points = []
        for index in range(13):
            u = -1+index/6
            x = cx+width*u
            h = eye_height(u,1 if upper else -1)
            points.append((x,h,surface(x,h)+.0034))
        curve('Refined_RoundedEyelid',points,.0025 if upper else .0020,ear_skin,
              taper=[.25,.6,.85,1,1,1,1,1,1,1,.85,.6,.25])
        if upper:
            curve('Refined_UpperLash',[(x,h-.0012,f+.0016) for x,h,f in points],.00065,brow,
                  taper=[.1,.4,.7,1,1,1,1,1,1,.8,.6,.3,.1])
    brow_points = [(side*x,h,surface(side*x,h)+.0026) for x,h in
                   [(.014,.274),(.031,.278),(.050,.274),(.069,.266),(.085,.255)]]
    curve('Refined_WorriedBrow',brow_points,.0032,brow,taper=[.45,1,1,.75,.12])
    # Subtle nostrils, rather than a separate angular nose block.
    x, h = side*.010,.130
    ellipsoid('Refined_Nostril',(x,h,surface(x,h)+.0007),(.0028,.0013,.0008),fold)
    ellipsoid('Refined_Ear',(side*.109,.170,-.001),(.017,.034,.014),ear_skin)
    points = [(side*x,h,f) for x,h,f in [(.110,.195,.009),(.122,.187,.012),(.123,.165,.014),(.115,.148,.010)]]
    curve('Refined_EarHelix',points,.0033,ear_skin,taper=[.4,1,1,.45])
    curve('Refined_EarInner',[(side*.114,.181,.013),(side*.117,.172,.015),(side*.112,.164,.013)],.0016,fold,taper=[.3,1,.3])

mouth_points = []
for index in range(13):
    x = -.025+.05*index/12
    h = .075-.0022*abs(x/.025)+.0009*math.cos(x/.025*math.tau)
    mouth_points.append((x,h,surface(x,h)+.0015))
curve('Refined_ClosedMouth',mouth_points,.0010,mouth,
      taper=[.12,.5,.8,1,1,1,1,1,1,1,.8,.5,.12])
curve('Refined_LowerLip',[(x,h-.003,f-.0002) for x,h,f in mouth_points[2:-2]],.0015,lip,
      taper=[.1,.45,.8,1,1,1,.8,.45,.1])

# A close-fitting scalp behind the ears and curved, tapered temple locks.
hv, hf = [], []
HC, HR = 80, 18
for row in range(HR+1):
    for col in range(HC):
        angle = math.tau*col/HC
        front = math.sin(angle)
        blend = max(0,min(1,(front+.02)/.5))
        blend = blend*blend*(3-2*blend)
        low = .115+.190*blend
        h = low+(.349-low)*row/HR
        rx, rz = profile(h)
        hv.append(((rx+.0035)*math.cos(angle),h,(rz+.0035)*front))
for row in range(HR):
    for col in range(HC):
        a = row*HC+col
        b = row*HC+(col+1)%HC
        hf.append((a,b,b+HC,a+HC))
mesh('Refined_Scalp',hv,hf,hair)
for side in [-1,1]:
    for index in range(5):
        spread = index*.0045
        points = [(side*(.078+spread),.312,.057-spread),
                  (side*(.089+spread),.284,.061-spread),
                  (side*(.100+spread),.237,.045-spread),
                  (side*(.105+spread*.6),.194-index*.008,.027-spread),
                  (side*(.106+spread*.8),.174-index*.008,.020-spread)]
        curve('Refined_TempleLock',points,.0040-index*.00038,hair,taper=[1,1,.85,.55,.02])
    for index in range(3):
        curve('Refined_Flyaway',[(side*.101,.274-index*.025,-.025),
              (side*(.131+index*.004),.252-index*.030,-.008),
              (side*(.128+index*.008),.220-index*.038,-.012)],.0008,hair,taper=[.8,.7,.01])

# Recalculate outward normals, then join into the original skinned mesh.
for obj in parts:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
for obj in parts: obj.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
# Godot uses glTF COLOR_0. Joining into the original mesh otherwise puts the
# new face attribute in COLOR_1, which glTF viewers can silently ignore.
face_colors = body.data.color_attributes['FaceColor']
primary_colors = body.data.color_attributes[0]
assert primary_colors.domain == 'CORNER'
if primary_colors != face_colors:
    for polygon in body.data.polygons:
        if body.data.materials[polygon.material_index] == skin:
            for index in polygon.loop_indices:
                primary_colors.data[index].color = face_colors.data[index].color
    body.data.color_attributes.remove(face_colors)
assert all(len(vertex.groups)>0 for vertex in body.data.vertices)
assert len(armature.data.bones) == 24

export_path = ASSETS/'deng_shunian_face_v2.glb'
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
armature.select_set(True)
bpy.context.view_layer.objects.active = armature
with contextlib.redirect_stdout(io.StringIO()):
    bpy.ops.export_scene.gltf(filepath=str(export_path),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,
        export_frame_range=False)
raw = export_path.read_bytes()
length = struct.unpack_from('<I',raw,12)[0]
document = json.loads(raw[20:20+length].decode('utf-8'))
names = [animation['name'] for animation in document['animations']]
assert set(names) == {'idle','walk','jump','push','carry','inspect'}
assert len(document['skins']) == 1
report = {'blender':bpy.app.version_string,'revision':'face-v2',
          'bones':len(armature.data.bones),'vertices':len(body.data.vertices),
          'polygons':len(body.data.polygons),'animations':names,'skins':1,
          'uv_layers':len(body.data.uv_layers),'glb':str(export_path),
          'refinement':'Continuous smooth face and neck, seated almond eyes, curved lids, integrated nose, soft mouth and curved hair'}
(OUT/'validation-face-v2.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
if hasattr(bpy.context.preferences.filepaths,'file_preview_type'):
    bpy.context.preferences.filepaths.file_preview_type = 'NONE'
scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'邓书年_面部精修与转身.blend'))
print('DENG_FACE_REFINED_OK',json.dumps(report,ensure_ascii=False))
