"""Incremental Shi Aduo refinement. Open the first Shi .blend before running.

Keeps the existing rig/actions and saves a separate refined source and GLB.
"""
import bpy
import bmesh
import contextlib
import io
import json
import math
import random
import struct
from pathlib import Path
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT/'character-source/shi_aduo'
body = bpy.data.objects['ShiAduo_CharacterMesh']
armature = bpy.data.objects['ShiAduo_Armature']
assert body.matrix_world == Matrix.Identity(4) and len(armature.data.bones)==25
armature.animation_data.action = bpy.data.actions['idle']
bpy.context.scene.frame_set(0)
collection = body.users_collection[0]
parts = []
rng = random.Random(2442)
cloth_image = next(i for i in bpy.data.images if 'Indigo_albedo' in i.name)

def p(point):
    x,h,f = point
    return Vector((x,-f,h))

def from_p(v): return (v.x,v.z,-v.y)

def linear(color):
    return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in color)

def multiply(mat,source,constant=None):
    nodes = mat.node_tree.nodes
    mix = nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'; mix.blend_type = 'MULTIPLY'; mix.inputs[0].default_value = 1
    a = next(s for s in mix.inputs if s.name=='A' and s.type=='RGBA')
    b = next(s for s in mix.inputs if s.name=='B' and s.type=='RGBA')
    if constant is not None: a.default_value = constant
    else: mat.node_tree.links.new(source,a)
    return mix,a,b,next(s for s in mix.outputs if s.type=='RGBA')

def material(name,color,cloth=False,metal=0):
    mat = bpy.data.materials.new('Aduo_'+name); mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*linear(color),1)
    shader.inputs['Roughness'].default_value = .90 if not metal else .72
    shader.inputs['Specular IOR Level'].default_value = .04
    shader.inputs['Metallic'].default_value = metal
    mat.diffuse_color = (*linear(color),1)
    if cloth:
        texture = mat.node_tree.nodes.new('ShaderNodeTexImage'); texture.image = cloth_image
        _,_,b,output = multiply(mat,None,(*linear(color),1))
        mat.node_tree.links.new(texture.outputs['Color'],b)
        mat.node_tree.links.new(output,shader.inputs['Base Color'])
    return mat

def set_skin(mat,color):
    shader = mat.node_tree.nodes.get('Principled BSDF')
    for node in list(mat.node_tree.nodes):
        if node.type not in {'OUTPUT_MATERIAL','BSDF_PRINCIPLED'}: mat.node_tree.nodes.remove(node)
    shader.inputs['Base Color'].default_value = (*linear(color),1)
    shader.inputs['Roughness'].default_value = .9
    shader.inputs['Specular IOR Level'].default_value = .04

skin = bpy.data.materials['Aduo_Skin']
face_skin = bpy.data.materials['Aduo_SoftSkin']
neck_skin = bpy.data.materials['Aduo_Neck']
ear_skin = bpy.data.materials['Aduo_EarAndLid']
for mat,color in [(skin,(.69,.55,.42)),(face_skin,(.71,.58,.45)),
                  (neck_skin,(.68,.54,.41)),(ear_skin,(.70,.55,.42))]: set_skin(mat,color)
mat = {
 'Wrap':material('RefinedWrap',(.26,.34,.40),True),
 'WrapLight':material('WrapFoldLight',(.29,.37,.43),True),
 'WrapDark':material('WrapFoldShadow',(.22,.29,.35),True),
 'Linen':material('RefinedLinen',(.81,.79,.72),True),
 'LinenRoll':material('RefinedRolledLinen',(.84,.82,.75),True),
 'Lining':material('SleeveInnerLining',(.43,.42,.35),True),
 'Thread':material('FineLinenThread',(.57,.55,.45)),
 'Hair':material('RefinedHair',(.105,.10,.083)),
 'HairLight':material('HairStrand',(.155,.145,.12)),
 'HairDark':material('HairPart',(.065,.063,.053)),
 'Lip':material('NaturalLip',(.57,.39,.30)),
 'Mouth':material('ClosedLipLine',(.29,.20,.15)),
 'Fold':material('GentleSkinCrease',(.50,.38,.28)),
 'Nail':material('NaturalNail',(.53,.40,.29)),
 'FlowerLight':material('SatinFlowerStitch',(.59,.29,.22)),
 'LeafLight':material('FineLeafStitch',(.46,.47,.31)),
 'Wood':material('RefinedMalletWood',(.38,.275,.17)),
 'WoodEnd':material('MalletEndGrainRefined',(.46,.35,.23)),
 'WoodDark':material('MalletGrain',(.27,.19,.115)),
 'WoodLight':material('MalletWornEdge',(.52,.41,.28)),
 'Steel':material('RefinedChiselSteel',(.26,.285,.29),metal=.55),
 'SteelEdge':material('ChiselCuttingBevel',(.48,.50,.48),metal=.65),
}

def bind(obj,joint):
    group = obj.vertex_groups.new(name=joint); group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    parts.append(obj)
    return obj

def mesh(name,points,faces,material,joint='head',uv=None):
    data = bpy.data.meshes.new(name); data.from_pydata([p(v) for v in points],[],faces); data.update()
    obj = bpy.data.objects.new(name,data); collection.objects.link(obj); data.materials.append(material)
    for poly in data.polygons: poly.use_smooth = True
    colors = data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
    for value in colors.data: value.color = (1,1,1,1)
    uvs = data.uv_layers.new(name='UVMap')
    for loop in data.loops:
        v = data.vertices[loop.vertex_index].co
        uvs.data[loop.index].uv = uv[loop.vertex_index] if uv else (v.x*6,v.z*6)
    return bind(obj,joint)

def curve(name,points,radius,material,joint='head',taper=None):
    data = bpy.data.curves.new(name,'CURVE'); data.dimensions = '3D'
    data.resolution_u = 5; data.bevel_depth = radius; data.bevel_resolution = 1; data.use_fill_caps = True
    if len(points)>=8:
        spline = data.splines.new('POLY'); spline.points.add(len(points)-1)
        for i,(point,item) in enumerate(zip(points,spline.points)):
            item.co = (*p(point),1); item.radius = taper[i] if taper else 1
    else:
        spline = data.splines.new('BEZIER'); spline.bezier_points.add(len(points)-1)
        for i,(point,item) in enumerate(zip(points,spline.bezier_points)):
            item.co = p(point); item.handle_left_type = 'AUTO'; item.handle_right_type = 'AUTO'; item.radius = taper[i] if taper else 1
    obj = bpy.data.objects.new(name,data); collection.objects.link(obj); data.materials.append(material)
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target='MESH')
    for poly in obj.data.polygons: poly.use_smooth = True
    return bind(obj,joint)

def ellipsoid(name,center,scale,material,joint='head',segments=24,rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings)
    obj = bpy.context.object; obj.name = name
    for v in obj.data.vertices:
        original = v.co.copy(); v.co = p((center[0]+original.x*scale[0],center[1]+original.z*scale[1],center[2]+original.y*scale[2]))
    for old in list(obj.users_collection): old.objects.unlink(obj)
    collection.objects.link(obj); obj.data.materials.append(material)
    for poly in obj.data.polygons: poly.use_smooth = True
    return bind(obj,joint)

def dominant_groups(obj):
    names = {g.index:g.name for g in obj.vertex_groups}
    return {v.index:{names[g.group] for g in v.groups if g.weight>.5} for v in obj.data.vertices}

def remove_where(predicate):
    groups = dominant_groups(body)
    selected = set()
    for poly in body.data.polygons:
        if predicate(body.data.materials[poly.material_index].name,groups[poly.vertices[0]]): selected.update(poly.vertices)
    bm = bmesh.new(); bm.from_mesh(body.data); bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[bm.verts[i] for i in selected],context='VERTS'); bm.to_mesh(body.data); bm.free()

def extract_where(name,predicate):
    groups = dominant_groups(body)
    selected = {i for poly in body.data.polygons if predicate(body.data.materials[poly.material_index].name,groups[poly.vertices[0]]) for i in poly.vertices}
    assert selected,name
    obj = body.copy(); obj.data = body.data.copy(); obj.name = name; obj.parent = None; obj.matrix_world = Matrix.Identity(4); obj.modifiers.clear()
    collection.objects.link(obj)
    bm = bmesh.new(); bm.from_mesh(obj.data); bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in selected],context='VERTS'); bm.to_mesh(obj.data); bm.free()
    remove_where(predicate); parts.append(obj)
    return obj

def thicken(obj,thickness):
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active = obj
    solid = obj.modifiers.new('真实布料厚度','SOLIDIFY'); solid.thickness = thickness; solid.offset = -.3
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bevel = obj.modifiers.new('布边圆润','BEVEL'); bevel.width = .0007; bevel.segments = 2
    bpy.ops.object.modifier_apply(modifier=bevel.name)

# Remove the flat wrap, simple hair, sleeve tubes, old grips and hand tools.
remove_where(lambda m,g: ('head' in g and m in {'Aduo_BlueHeadWrap','Aduo_BlueGrayVest','Aduo_StoneDust','Aduo_BlackHair'})
             or (any(s in g for s in ['upper_arm.L','upper_arm.R']) and m in {'Aduo_IvoryLinen','Aduo_RolledLinen'})
             or (any(s in g for s in ['hand.L','hand.R']) and m=='Aduo_Skin')
             or any(s in g for s in ['tool.L','tool.R'])
             or ('spine' in g and m=='Aduo_RolledLinen')
             or ('head' in g and m in {'Aduo_Lip','Aduo_MouthLine'}))

# A little more cheek volume, a gentler lower jaw, and a modeled philtrum/lip bed.
skin_slot = list(body.data.materials).index(face_skin)
face_indices = {i for poly in body.data.polygons if poly.material_index==skin_slot for i in poly.vertices}
def gauss(x,h,cx,ch,sx,sh): return math.exp(-((x-cx)/sx)**2-((h-ch)/sh)**2)
for i in face_indices:
    v = body.data.vertices[i]; x,h,f = from_p(v.co)
    front_weight = max(0,min(1,f/.060))**5
    delta = sum(.0025*gauss(x,h,side*.052,1.434,.021,.025) for side in [-1,1])
    delta += .0011*gauss(x,h,0,1.378,.019,.005)-.0007*gauss(x,h,0,1.393,.004,.012)
    v.co.y -= delta*front_weight
    v.co.x *= 1-.024*gauss(abs(x),h,.058,1.391,.030,.027)
body.data.update()

def bvh_for_slots(slots):
    verts = [v.co.copy() for v in body.data.vertices]
    faces = [tuple(poly.vertices) for poly in body.data.polygons if poly.material_index in slots]
    return BVHTree.FromPolygons(verts,faces,all_triangles=False)
face_bvh = bvh_for_slots({skin_slot})
white_slot = next(i for i,m in enumerate(body.data.materials) if m.name=='Aduo_EyeIvory')
eye_bvh = bvh_for_slots({white_slot})

def front_at(x,h,bvh=face_bvh):
    hit,_,_,_ = bvh.ray_cast(Vector((x,-.5,h)),Vector((0,1,0)),1)
    return -hit.y if hit is not None else .06

# Seated eyelid creases and fine iris rings retain the wide, alert expression.
for side in [-1,1]:
    cx,cy = side*.03854,1.4786
    points = []
    for i in range(17):
        u = -1+i/8; x = cx+.025*u
        h = cy+.018*math.sqrt(max(0,1-u*u))+.003
        points.append((x,h,front_at(x,h)+.0011))
    curve('SoftUpperEyelidFold',points,.00048,mat['Fold'],taper=[.15]+[.7]*15+[.15])
    for radius,material in [(.0077,mat['HairDark']),(.0056,mat['Fold'])]:
        points = []
        for i in range(49):
            a = math.tau*i/48; x = cx+radius*math.cos(a); h = cy-.0007+radius*1.28*math.sin(a)
            points.append((x,h,front_at(x,h,eye_bvh)+.0010))
        curve('FineIrisRing',points,.00025,material,'eyes')
    for i in range(6):
        x = side*(.014+i*.007)
        h = 1.345+(.263+(abs(x)/.82-.014)*.20-.03)*.73+.0015
        curve('IndividualBrowHair',[(x,h,front_at(x,h)+.0018),(x+side*.002,h+.0021,front_at(x,h)+.0015)],.00020,mat['Hair'])
    for i in range(6):
        x = side*(.038+rng.random()*.025); h = 1.432+rng.random()*.013
        ellipsoid('SubtleCheekFreckle',(x,h,front_at(x,h)+.0002),(.00038,.00023,.00013),mat['Fold'],segments=12,rings=8)

# Natural lip surfaces and a thin closed mouth, rather than two thick lines.
lip_points,lip_faces = [],[]
for row in range(7):
    v = -1+row/3
    for col in range(41):
        u = -1+col/20; x = u*.020
        center = 1.378+.00075*math.cos(u*math.tau)-.0006*abs(u)
        h = center+v*.0028*math.sqrt(max(0,1-u*u))
        lip_points.append((x,h,front_at(x,h)+.0006+.0010*(1-u*u)*(1-v*v)))
for row in range(6):
    for col in range(40):
        a = row*41+col; lip_faces.append((a,a+1,a+42,a+41))
mesh('SculptedLipSurface',lip_points,lip_faces,mat['Lip'])
points = []
for i in range(25):
    u = -1+i/12; x = u*.021; h = 1.378+.00075*math.cos(u*math.tau)-.0006*abs(u)
    points.append((x,h,front_at(x,h)+.0018))
curve('FineClosedMouth',points,.00052,mat['Mouth'],taper=[.1]+[1]*23+[.1])

# A fitted scalp, asymmetrical coiled bun, swept locks and tapered loose wisps.
points,faces = [],[]
HC,HR = 96,28
for row in range(HR+1):
    t = row/HR
    for col in range(HC):
        theta = math.tau*col/HC; front = math.sin(theta)
        blend = max(0,min(1,(front+.05)/.6)); blend = blend*blend*(3-2*blend)
        low = 1.398+.147*blend+.004*math.sin(theta*7)
        h = low+(1.62-low)*t
        rx = (.086+.010*math.sin(t*math.pi))*(.88+.12*min(1,t*5))
        rz = .073+.007*math.sin(t*math.pi)
        points.append((rx*math.cos(theta),h,-.009+rz*front))
for row in range(HR):
    for col in range(HC):
        a = row*HC+col; b = row*HC+(col+1)%HC; faces.append((a,b,b+HC,a+HC))
mesh('SculptedScalp',points,faces,mat['Hair'])
bun = ellipsoid('AsymmetricTiedBun',(.005,1.620,-.034),(.050,.047,.045),mat['Hair'],segments=40,rings=28)
for v in bun.data.vertices:
    c = p((.005,1.620,-.034)); d = v.co-c
    angle = math.atan2(d.y,d.x)
    v.co += d.normalized()*.0022*math.sin(angle*7+d.z*75)
for strand in range(18):
    theta = math.tau*strand/18
    points = []
    for step in range(19):
        a = -.7+step/18*2.1
        points.append((.005+.051*math.cos(a)*math.cos(theta+.4*a),1.620+.048*math.sin(a),-.034+.046*math.cos(a)*math.sin(theta+.4*a)))
    curve('BunHairGrain',points,.00045,mat['HairLight'])
for side in [-1,1]:
    for lock in range(3):
        # Curved, overlapping masses with fine tapered tips; avoid parallel wires.
        controls = [Vector((side*(.033+lock*.017),1.555+lock*.002,.065-lock*.006)),
                    Vector((side*(.078+lock*.008),1.537,.076-lock*.007)),
                    Vector((side*(.090+lock*.006),1.492,.043-lock*.008)),
                    Vector((side*(.082+lock*.011),1.451-lock*.012,.023-lock*.012))]
        points,faces,centers = [],[],[]
        for row in range(25):
            t = row/24
            center = (1-t)**3*controls[0]+3*t*(1-t)**2*controls[1]+3*t*t*(1-t)*controls[2]+t**3*controls[3]
            derivative = 3*(1-t)**2*(controls[1]-controls[0])+6*t*(1-t)*(controls[2]-controls[1])+3*t*t*(controls[3]-controls[2])
            across = Vector((-derivative.y,derivative.x,0)).normalized()
            width = (.022-lock*.003)*(1-t)**.65+.0003
            centers.append(tuple(center))
            for j in range(7):
                u = -1+j/3
                point = center+across*(u*width/2)
                point.z += .0022*(1-u*u)*(1-t)+.0003*math.sin(u*9+t*4)*(1-t)
                points.append(tuple(point))
            if row:
                for j in range(6):
                    a = (row-1)*7+j; faces.append((a,a+1,a+8,a+7))
        mesh('SweptTempleLock',points,faces,mat['Hair'])
        curve('TempleHairHighlight',[(x,h,f+.0020*(1-i/24)) for i,(x,h,f) in enumerate(centers)],.00024,mat['HairLight'],taper=[max(.015,(1-i/24)*.7) for i in range(25)])
    for i in range(5):
        curve('LooseTaperedHair',[(side*.083,1.515-i*.014,-.015),
              (side*(.112+i*.002),1.501-i*.021,.004),
              (side*(.109+i*.004),1.472-i*.025,-.009)],.00055,mat['HairDark'],taper=[1,.8,.01])

# Rounded fabric crown and thick, softly bulging wrapped strips.
points,faces,uv = [],[],[]
WC,WR = 96,20
for row in range(WR+1):
    t = row/WR
    for col in range(WC):
        a = math.tau*col/WC; h = 1.536+.097*t+.011*math.cos(a+.7)+.004*math.sin(a*3)
        radius = .102+.008*math.sin(math.pi*t)-.006*t+.0015*math.sin(a*7+t*8)
        points.append((radius*math.cos(a),h,-.008+(radius*.80)*math.sin(a)))
        uv.append((col/WC*2,t*.6))
for row in range(WR):
    for col in range(WC):
        a = row*WC+col; b = row*WC+(col+1)%WC; faces.append((a,b,b+WC,a+WC))
obj = mesh('RoundedHeadClothCrown',points,faces,mat['Wrap'],uv=uv); thicken(obj,.0025)
for layer in range(3):
    points,faces,uv = [],[],[]
    for step in range(129):
        a = math.tau*step/128
        center = [1.553,1.582,1.609][layer]+.014*math.cos(a+layer*.9)+.007*math.sin(2*a+.4)
        for j in range(7):
            v = -1+j/3; h = center+v*.018
            r = .109+layer*.0006+.0034*(1-v*v)+.0014*math.sin(a*8+layer+v)
            points.append((r*math.cos(a),h,-.008+r*.80*math.sin(a)))
            uv.append((step/128*2,layer*.27+j/6*.30))
        if step:
            for j in range(6):
                k = (step-1)*7+j; faces.append((k,k+1,k+8,k+7))
    obj = mesh('ThickDrapedHeadWrapFold',points,faces,mat['WrapLight'] if layer==1 else mat['Wrap'],uv=uv)
    thicken(obj,.0018)
    # A thin dark fold at the edge is subtler than a bright cord around every layer.
    curve('HeadClothSoftCrease',[points[i] for i in range(0,len(points),7)],.0006,mat['WrapDark'])
ellipsoid('FabricWrapKnot',(-.089,1.547,-.083),(.025,.018,.019),mat['WrapDark'])

# A fitted crossed collar sits against the shirt instead of floating as straps.
shirt_slot = next(i for i,m in enumerate(body.data.materials) if m.name=='Aduo_IvoryLinen')
shirt_bvh = bvh_for_slots({shirt_slot})
for side in [-1,1]:
    points,faces,uv = [],[],[]
    top = Vector((side*.050,1.289,0)); bottom = Vector((-side*.003,1.150 if side==-1 else 1.164,0))
    direction = (bottom-top).normalized(); across = Vector((-direction.y,direction.x,0))
    for row in range(33):
        t = row/32; center = top.lerp(bottom,t)
        center.x += side*.009*math.sin(t*math.pi)
        for col in range(7):
            u = -1+col/3
            point = center+across*(u*.010)
            f = front_at(point.x,point.y,shirt_bvh)+.0025+.0008*(1-u*u)+(.001 if side==-1 else 0)
            points.append((point.x,point.y,f)); uv.append((col/6*.15,t*.8))
        if row:
            for col in range(6):
                k = (row-1)*7+col; faces.append((k,k+1,k+8,k+7))
    collar = mesh('FittedCrossedCollar',points,faces,mat['LinenRoll'],'spine',uv)
    thicken(collar,.0015)

# Round, wrinkled sleeve shells with a visible rolled edge and dark inner lining.
def frame(start,end):
    a,b = p(start),p(end); direction = (b-a).normalized()
    tangent = direction.cross(Vector((0,1,0))).normalized(); other = direction.cross(tangent).normalized()
    return a,b,direction,tangent,other

for side,suffix in [(-1,'L'),(1,'R')]:
    joint = 'upper_arm.'+suffix
    a,b,direction,tangent,other = frame((side*.150,1.237,.004),(side*.221,.988,.031))
    points,faces,uv = [],[],[]
    SR,SC = 26,48
    for row in range(SR+1):
        t = row/SR; center = a.lerp(b,t)
        radius = .047+.012*math.sin(min(1,t*1.8)*math.pi/2)+.005*t*t
        for col in range(SC):
            angle = math.tau*col/SC
            wrinkle = .0018*math.sin(angle*6+t*4)*math.sin(t*math.pi)+.0012*math.sin(angle*11-t*8)*t
            v = center+(tangent*math.cos(angle)+other*math.sin(angle))*(radius+wrinkle)
            points.append(from_p(v)); uv.append((col/SC,t*1.2))
    for row in range(SR):
        for col in range(SC):
            k = row*SC+col; n = row*SC+(col+1)%SC; faces.append((k,n,n+SC,k+SC))
    obj = mesh('WrinkledLinenSleeve.'+suffix,points,faces,mat['Linen'],joint,uv); thicken(obj,.0022)
    # A soft shoulder cap overlaps the shirt seam instead of ending as a flat tube.
    ellipsoid('RoundedShoulderSeam.'+suffix,(side*.152,1.225,.005),(.051,.046,.051),mat['Linen'],joint)
    for roll,shift in enumerate([-.020,.003]):
        center = b+direction*shift
        points,faces,uv = [],[],[]
        for col in range(65):
            angle = math.tau*col/64; radial = tangent*math.cos(angle)+other*math.sin(angle)
            for row in range(13):
                cross = math.tau*row/12
                v = center+radial*(.058+.008*math.cos(cross))+direction*(.009*math.sin(cross))
                points.append(from_p(v)); uv.append((col/64,row/12*.4))
        for col in range(64):
            for row in range(12):
                k = col*13+row; faces.append((k,k+1,k+14,k+13))
        mesh('TurnedCuffRoll.'+suffix,points,faces,mat['LinenRoll'],joint,uv)
    points,faces = [],[]
    for row,offset in enumerate([-.015,.009]):
        for col in range(49):
            angle = math.tau*col/48
            points.append(from_p(b+direction*offset+(tangent*math.cos(angle)+other*math.sin(angle))*.052))
    for col in range(48): faces.append((col,col+1,col+50,col+49))
    mesh('CuffInnerShadow.'+suffix,points,faces,mat['Lining'],joint)

# Give the vest and apron real fabric walls; deform the embroidery with its cloth.
vest = extract_where('ThickVestPanels',lambda m,g:m=='Aduo_BlueGrayVest' and 'spine' in g)
thicken(vest,.0025)
def drape(point):
    x,h,f = point
    if f<.06: return point
    t = max(0,min(1,(h-.56)/.40))
    return (x,h+.018*(x/.16)*(1-t)**3-.011*(1-t)**4,
            f+.006*math.sin(x*38+1.3)*(1-t)+.003*math.sin(x*71+.5)*t*(1-t))
groups = dominant_groups(body)
for v in body.data.vertices:
    if 'apron' in groups[v.index]: v.co = p(drape(from_p(v.co)))
apron = extract_where('ThickDrapedApron',lambda m,g:m=='Aduo_IndigoApron' and 'apron' in g)
thicken(apron,.0028)
pocket = extract_where('PocketAndBackApron',lambda m,g:m=='Aduo_BlueGrayVest' and 'apron' in g)
bpy.ops.object.select_all(action='DESELECT'); pocket.select_set(True); bpy.context.view_layer.objects.active = pocket
sub = pocket.modifiers.new('布片分段','SUBSURF'); sub.subdivision_type = 'SIMPLE'; sub.levels = 2
bpy.ops.object.modifier_apply(modifier=sub.name)
for v in pocket.data.vertices:
    if v.co.y>.05: v.co.y += .003*math.sin(v.co.x*32+v.co.z*19)
thicken(pocket,.0020)

def apron_point(x,h,lift=.004):
    f = .128+.014*(1-(h-.56)/.40)+.004*math.sin(x*36+h*21)
    x,h,f = drape((x,h,f+lift)); return (x,h,f)
for cx,ch,size in [(.048,.657,.021),(.083,.733,.026),(.108,.798,.018)]:
    for petal in range(5):
        angle = math.tau*petal/5
        for stitch in range(5):
            along = size*(.22+stitch*.14); half = size*.29*math.sin((stitch+1)/6*math.pi)
            points = []
            for cross in [-1,0,1]:
                u = math.cos(angle)*along-math.sin(angle)*half*cross
                v = math.sin(angle)*along+math.cos(angle)*half*cross
                points.append(apron_point(cx+u,ch+v,.0042+(.0003 if cross==0 else 0)))
            curve('SatinEmbroideryThread',points,.00032,mat['FlowerLight'],'apron')
for x1,h1,x2,h2 in [(-.131,.65,-.132,.776),(-.045,.65,-.041,.765),(-.131,.65,-.045,.65)]:
    for i in range(9):
        t = i/9; t2 = (i+.45)/9
        a = apron_point(x1+(x2-x1)*t,h1+(h2-h1)*t,.007)
        b = apron_point(x1+(x2-x1)*t2,h1+(h2-h1)*t2,.007)
        curve('PocketHandStitch',[a,b],.00045,mat['Thread'],'apron')

# Articulated-looking finger segments, discreet nails and thumb pads.
for side,suffix in [(-1,'L'),(1,'R')]:
    joint = 'hand.'+suffix
    ellipsoid('ShapedPalm.'+suffix,(side*.247,.786,.087),(.027,.037,.021),skin,joint)
    for finger in range(4):
        h = .801-finger*.013
        points = [(side*.269,h,.088),(side*.265,h-.001,.105),(side*.249,h-.004,.119),(side*.232,h-.008,.112)]
        curve('CurvedGrippingFinger.'+suffix,points,.0062,skin,joint,taper=[1,1.06,.92,.67])
        ellipsoid('Knuckle.'+suffix,(side*.265,h-.001,.103),(.0065,.0063,.0050),skin,joint,16,12)
        ellipsoid('FingerNail.'+suffix,(side*.247,h-.004,.1246),(.0023,.0032,.00035),mat['Nail'],joint,16,10)
        curve('FingerJointFold.'+suffix,[(side*.255,h-.007,.121),(side*.249,h-.008,.122),(side*.244,h-.007,.121)],.00027,mat['Fold'],joint)
    curve('CurvedThumb.'+suffix,[(side*.227,.807,.087),(side*.225,.792,.106),(side*.241,.780,.117)],.0077,skin,joint,taper=[1,1,.68])
    ellipsoid('ThumbNail.'+suffix,(side*.239,.782,.122),(.0026,.0038,.00035),mat['Nail'],joint,16,10)

# Chamfered mallet, with rings on its ends and low contrast wood grain.
def axial_mesh(name,start,end,profile,material,joint,segments=48):
    a,b,direction,tangent,other = frame(start,end)
    points,faces,uv = [],[],[]
    for row,(t,radius) in enumerate(profile):
        center = a.lerp(b,t)
        for col in range(segments):
            angle = math.tau*col/segments
            wear = 1-.012*math.sin(angle*5+row*.7)
            points.append(from_p(center+(tangent*math.cos(angle)+other*math.sin(angle))*radius*wear))
            uv.append((col/segments,t))
    for row in range(len(profile)-1):
        for col in range(segments):
            k = row*segments+col; n = row*segments+(col+1)%segments; faces.append((k,n,n+segments,k+segments))
    faces += [tuple(reversed(range(segments))),tuple((len(profile)-1)*segments+i for i in range(segments))]
    obj = mesh(name,points,faces,material,joint,uv)
    for poly in list(obj.data.polygons)[-2:]: poly.use_smooth = False
    if material in [mat['Wood'],mat['WoodEnd']]:
        colors = obj.data.color_attributes['Color']
        for loop in obj.data.loops:
            index = loop.vertex_index; theta = math.tau*(index%segments)/segments
            grain = .84+.11*math.sin(theta*17+.8*math.sin(theta*3))+.035*math.sin(theta*39)
            colors.data[loop.index].color = (grain,grain*.99,grain*.97,1)
    return obj

axial_mesh('WornMalletHandle',(-.330,.680,.103),(-.171,.848,.137),[(0,.0085),(.02,.010),(.46,.011),(.78,.0095),(1,.009)],mat['Wood'],'tool.L',32)
start,end = (-.218,.878,.137),(-.129,.807,.137)
axial_mesh('ChamferedWoodenMallet',start,end,[(0,.044),(.025,.048),(.16,.048),(.48,.0478),(.83,.048),(.975,.048),(1,.044)],mat['Wood'],'tool.L',64)
a,b,direction,tangent,other = frame(start,end)
for center in [a-direction*.00025,b+direction*.00025]:
    for radius in [.008,.018,.029,.039]:
        points = []
        for i in range(49):
            angle = math.tau*i/48; r = radius*(1+.025*math.sin(angle*3))
            points.append(from_p(center+(tangent*math.cos(angle)+other*math.sin(angle))*r))
        curve('MalletEndGrowthRing',points,.00048,mat['WoodDark'],'tool.L')
for i in range(13):
    angle = math.tau*i/13
    radial = tangent*math.cos(angle)+other*math.sin(angle)
    points = [from_p(a.lerp(b,t)+radial*(.0483+.0002*math.sin(t*7+i))) for t in [.05,.25,.5,.75,.94]]
    curve('MalletLongWoodGrain',points,.00036,mat['WoodDark'] if i%3 else mat['WoodLight'],'tool.L')

# A metal ferrule, straight shaft and beveled wedge make the chisel readable.
axial_mesh('ChiselWoodGrip',(.245,.834,.105),(.254,.727,.119),[(0,.009),(.05,.011),(.7,.0105),(1,.010)],mat['Wood'],'tool.R',32)
axial_mesh('ChiselGripFerrule',(.2535,.735,.118),(.255,.723,.120),[(0,.012),(1,.012)],mat['Steel'],'tool.R',32)
axial_mesh('ChiselShaftRefined',(.254,.727,.119),(.269,.641,.130),[(0,.0065),(1,.006)],mat['Steel'],'tool.R',24)
blade_points = [(.263,.650,.130),(.275,.650,.130),(.290,.594,.137),(.262,.590,.137),
                (.263,.650,.136),(.275,.650,.136),(.290,.594,.138),(.262,.590,.138)]
mesh('ForgedChiselWedge',blade_points,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(3,7,4,0)],mat['Steel'],'tool.R')
mesh('ChiselSharpenedBevel',[(.289,.603,.135),(.263,.600,.135),(.262,.590,.138),(.290,.594,.138)],[(0,1,2,3)],mat['SteelEdge'],'tool.R')

# Use the same cream linen for shirt, cuffs, wool and ankle wraps.
for obj in [body,*parts]:
    for slot in obj.material_slots:
        if slot.material.name=='Aduo_IvoryLinen': slot.material = mat['Linen']
        elif slot.material.name=='Aduo_RolledLinen': slot.material = mat['LinenRoll']

# Recalculate normals and combine with the original skinned mesh.
for obj in parts:
    bm = bmesh.new(); bm.from_mesh(obj.data); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(obj.data); bm.free()
bpy.ops.object.select_all(action='DESELECT'); body.select_set(True)
for obj in parts: obj.select_set(True)
bpy.context.view_layer.objects.active = body; bpy.ops.object.join()
body.data.update()
used_slots = {poly.material_index for poly in body.data.polygons}
for i in reversed(range(len(body.data.materials))):
    if i not in used_slots: body.data.materials.pop(index=i)
colors = body.data.color_attributes['Color']
for attr in list(body.data.color_attributes):
    if attr.name!='Color': body.data.color_attributes.remove(attr)

# Recompute occlusion for the new forms and add soft, restrained cheek warmth.
skin_mats = {skin,face_skin,neck_skin,ear_skin,mat['Lip']}
ao_mats = skin_mats|{mat['Wrap'],mat['WrapLight'],mat['WrapDark'],mat['Linen'],mat['LinenRoll']}
slots = {i for i,m in enumerate(body.data.materials) if m in ao_mats}
ao_indices = {i for poly in body.data.polygons if poly.material_index in slots for i in poly.vertices}
bm = bmesh.new(); bm.from_mesh(body.data); bvh = BVHTree.FromBMesh(bm); bm.free()
directions = []
for i in range(64):
    r = math.sqrt((i+.5)/64); a = i*2.399963229728653
    directions.append((r*math.cos(a),r*math.sin(a),math.sqrt(1-r*r)))
ao = {}
for index in ao_indices:
    v = body.data.vertices[index]; n = v.normal.normalized(); t = n.cross(Vector((0,0,1)))
    if t.length<.01: t = n.cross(Vector((1,0,0)))
    t.normalize(); b = n.cross(t).normalized(); blocked = 0
    for x,y,z in directions:
        hit,_,_,distance = bvh.ray_cast(v.co+n*.00055,t*x+b*y+n*z,.095)
        if hit is not None: blocked += math.exp(-distance/.048)
    ao[index] = blocked/64
neighbors = {i:set() for i in ao_indices}
for edge in body.data.edges:
    a,b = edge.vertices
    if a in neighbors and b in neighbors: neighbors[a].add(b); neighbors[b].add(a)
for _ in range(3):
    ao = {i:.6*v+.4*sum(ao[n] for n in neighbors[i])/max(1,len(neighbors[i])) for i,v in ao.items()}
for poly in body.data.polygons:
    material = body.data.materials[poly.material_index]
    if material not in ao_mats: continue
    for loop_index in poly.loop_indices:
        index = body.data.loops[loop_index].vertex_index; x,h,f = from_p(body.data.vertices[index].co)
        shade = max(.68,1-.59*ao[index]**.8) if material in skin_mats else max(.82,1-.33*ao[index]**.8)
        warmth = sum(gauss(x,h,s*.051,1.432,.024,.022) for s in [-1,1]) if material==face_skin and f>.025 else 0
        colors.data[loop_index].color = (shade,shade*(.996-.018*warmth),shade*(.989-.023*warmth),1)

# Both Blender and glTF see the same vertex tint, with PBR base factors retained.
for material in ao_mats|{mat['Wood'],mat['WoodEnd']}:
    shader = material.node_tree.nodes.get('Principled BSDF'); socket = shader.inputs['Base Color']
    previous = socket.links[0].from_socket if socket.is_linked else None
    constant = None if previous else socket.default_value[:]
    attr = material.node_tree.nodes.new('ShaderNodeVertexColor'); attr.layer_name = 'Color'
    _,a,b,out = multiply(material,previous,constant)
    material.node_tree.links.new(attr.outputs['Color'],b)
    material.node_tree.links.new(out,socket)

assert all(v.groups for v in body.data.vertices)
assert set(a.name for a in bpy.data.actions)=={'idle','walk','jump','push','carry','inspect'}
assert all(g.name in armature.data.bones for g in body.vertex_groups)
export_path = PROJECT/'assets/characters/shi_aduo/shi_aduo_refined.glb'
bpy.ops.object.select_all(action='DESELECT'); body.select_set(True); armature.select_set(True); bpy.context.view_layer.objects.active = armature
with contextlib.redirect_stdout(io.StringIO()):
    bpy.ops.export_scene.gltf(filepath=str(export_path),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False)
raw = export_path.read_bytes(); size = struct.unpack_from('<I',raw,12)[0]; gltf = json.loads(raw[20:20+size].decode('utf8'))
assert len(gltf['skins'])==1 and len(gltf['animations'])==6
wrap = next(m for m in gltf['materials'] if m['name']=='Aduo_RefinedWrap')
assert wrap['pbrMetallicRoughness'].get('baseColorTexture')
assert .03 < wrap['pbrMetallicRoughness'].get('baseColorFactor',[1])[0] < .10,'Wrap tint lost during export'
report = {'blender':bpy.app.version_string,'character':'石阿朵','revision':'refined-v2',
          'bones':len(armature.data.bones),'vertices':len(body.data.vertices),'polygons':len(body.data.polygons),
          'animations':[a['name'] for a in gltf['animations']],'skins':1,'uv_layers':len(body.data.uv_layers),
          'vertex_ao_samples':64,'glb':str(export_path),
          'details':['shaped cheeks and lips','iris and lid detail','swept hair and coiled bun','thick draped head cloth',
                     'rolled cuffs and lining','thick draped apron and pocket','satin stitches','gripping fingers and nails',
                     'chamfered mallet and grain','beveled chisel']}
(OUT/'validation-refined.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
if hasattr(bpy.context.preferences.filepaths,'file_preview_type'): bpy.context.preferences.filepaths.file_preview_type = 'NONE'
bpy.context.scene.frame_set(0)
bpy.ops.object.select_all(action='DESELECT'); body.select_set(True); bpy.context.view_layer.objects.active = body
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'石阿朵_精修工程.blend'))
print('SHI_REFINED_OK',json.dumps(report,ensure_ascii=False))
