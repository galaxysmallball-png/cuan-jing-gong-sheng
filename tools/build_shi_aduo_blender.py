"""Build Shi Aduo from the user's sheet, using the refined face as topology.

Open Deng's neck-v3 source as a read-only topology/material library first.
This saves a new Shi source and never saves over the library file.
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
from mathutils import Vector, Matrix, Quaternion
from mathutils.bvhtree import BVHTree

PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT/'character-source/shi_aduo'
ASSETS = PROJECT/'assets/characters/shi_aduo'
OUT.mkdir(parents=True,exist_ok=True)
ASSETS.mkdir(parents=True,exist_ok=True)
rng = random.Random(241016)

# Retain the refined facial topology, not the previous character's costume.
library = bpy.data.objects['Deng_CharacterMesh']
face = library.copy()
face.data = library.data.copy()
bpy.context.scene.collection.objects.link(face)
face.name = 'Aduo_FacialTopology'
face.parent = None
face.matrix_world = Matrix.Identity(4)
face.modifiers.clear()
keep_materials = {index for index,mat in enumerate(face.data.materials)
                  if mat and mat.name.startswith('Face_') and mat.name not in {'Face_Neck','Face_MatteHair'}}
keep_vertices = {index for poly in face.data.polygons if poly.material_index in keep_materials for index in poly.vertices}
bm = bmesh.new()
bm.from_mesh(face.data)
bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[vertex for vertex in bm.verts if vertex.index not in keep_vertices],context='VERTS')
bm.to_mesh(face.data)
bm.free()
for obj in list(bpy.data.objects):
    if obj != face: bpy.data.objects.remove(obj,do_unlink=True)
for action in list(bpy.data.actions): bpy.data.actions.remove(action)
for group in list(face.vertex_groups):
    if group.name not in {'head','eyes'}: face.vertex_groups.remove(group)
for attr in list(face.data.color_attributes)[1:]: face.data.color_attributes.remove(attr)
face.data.color_attributes[0].name = 'Color'
for value in face.data.color_attributes[0].data: value.color = (1,1,1,1)

cloth_image = next(image for image in bpy.data.images if 'Indigo_albedo' in image.name)
if not cloth_image.has_data: cloth_image.pixels[0]
cloth_image.pack()
for image in list(bpy.data.images):
    if image != cloth_image and image.type == 'IMAGE': bpy.data.images.remove(image)

collection = bpy.data.collections.new('石阿朵_可编辑角色')
bpy.context.scene.collection.children.link(collection)
for old_collection in list(face.users_collection): old_collection.objects.unlink(face)
collection.objects.link(face)
parts = [face]

def p(point):
    x,h,f = point
    return Vector((x,-f,h))

def linear(color):
    return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in color)

def material(name,color,cloth=False):
    mat = bpy.data.materials.new('Aduo_'+name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*linear(color),1)
    shader.inputs['Roughness'].default_value = .91
    shader.inputs['Specular IOR Level'].default_value = .07
    mat.diffuse_color = (*linear(color),1)
    if cloth:
        image = mat.node_tree.nodes.new('ShaderNodeTexImage')
        image.image = cloth_image
        mix = mat.node_tree.nodes.new('ShaderNodeMix')
        mix.data_type = 'RGBA'
        mix.blend_type = 'MULTIPLY'
        mix.inputs[0].default_value = 1
        a = next(s for s in mix.inputs if s.name=='A' and s.type=='RGBA')
        b = next(s for s in mix.inputs if s.name=='B' and s.type=='RGBA')
        a.default_value = (*linear(color),1)
        mat.node_tree.links.new(image.outputs['Color'],b)
        mat.node_tree.links.new(next(s for s in mix.outputs if s.type=='RGBA'),shader.inputs['Base Color'])
    return mat

mats = {
 'Skin':material('Skin',(.72,.55,.39)),
 'Neck':material('Neck',(.71,.54,.39)),
 'Ivory':material('IvoryLinen',(.72,.69,.58)),
 'LinenLight':material('RolledLinen',(.82,.78,.66)),
 'Seam':material('LinenSeam',(.52,.49,.40)),
 'Vest':material('BlueGrayVest',(.35,.42,.45),True),
 'Pants':material('IndigoTrousers',(.28,.34,.39),True),
 'Wrap':material('BlueHeadWrap',(.27,.35,.42),True),
 'Apron':material('IndigoApron',(.22,.27,.32),True),
 'Belt':material('GreenGrayBelt',(.25,.29,.24)),
 'Hair':material('BlackHair',(.10,.095,.080)),
 'Shoe':material('EmbroideredShoe',(.10,.13,.14)),
 'Sole':material('WornClothSole',(.47,.41,.31)),
 'Thread':material('IvoryThread',(.64,.61,.49)),
 'Red':material('RedFlowerThread',(.48,.21,.16)),
 'Leaf':material('LeafThread',(.40,.42,.28)),
 'Brass':material('BrassWhistle',(.57,.41,.18)),
 'Dark':material('DarkCrevice',(.13,.12,.10)),
 'Wood':material('MalletWood',(.34,.24,.14)),
 'WoodEnd':material('MalletEndGrain',(.46,.35,.23)),
 'Steel':material('ChiselSteel',(.28,.30,.28)),
 'Powder':material('StoneDust',(.53,.51,.43)),
}
mats['Steel'].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = .4
mats['Brass'].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = .3

# A shorter, firmer jaw and more determined brow distinguish her from Deng.
origin = Vector((0,0,1.48*.86))
inverse_tilt = Matrix.Rotation(.02,3,'Y').inverted()
face_palette = {}
for index,old in enumerate(face.data.materials):
    if index not in keep_materials: continue
    name = old.name
    mat = old.copy()
    mat.name = 'Aduo_'+name.removeprefix('Face_')
    shader = mat.node_tree.nodes.get('Principled BSDF')
    if name in {'Face_SoftSkin','Face_EarAndLid'}:
        for node in list(mat.node_tree.nodes):
            if node != shader and node.type != 'OUTPUT_MATERIAL': mat.node_tree.nodes.remove(node)
        shader.inputs['Base Color'].default_value = (*linear((.73,.57,.42)),1)
        shader.inputs['Roughness'].default_value = .88
        shader.inputs['Specular IOR Level'].default_value = .06
    face.data.materials[index] = mat
    face_palette[name] = mat
for vertex in face.data.vertices:
    local = inverse_tilt@(vertex.co-origin)/.86
    x,h,f = local.x,local.z,-local.y
    # Narrow chin, broad cheekbones, shorter face; preserve the modeled eyelids.
    lower = max(0,min(1,(h-.03)/.12))
    x *= .82*(.83+.17*lower)
    f *= .79
    h2 = 1.345+(h-.03)*.73
    vertex.co = p((x,h2,f))
# Move only brow components above the eyes, not the upper eyelash lines.
brow_index = next(index for index,mat in enumerate(face.data.materials) if mat == face_palette['Face_Brows'])
brow_vertices = {i for poly in face.data.polygons if poly.material_index==brow_index for i in poly.vertices}
for index in brow_vertices:
    v = face.data.vertices[index]
    h = (v.co.z-1.345)/.73+.03
    if h>.25:
        x = abs(v.co.x)/.82
        old_center = .278-(max(0,x-.031)/.054)*.023
        if x<.031: old_center = .274+(x-.014)/.017*.004
        desired = .263+(x-.014)*.20+.004*math.sin(min(1,max(0,(x-.014)/.071))*math.pi)
        v.co.z += (desired-old_center)*.73
face.data.update()

def bind(obj,joint):
    group = obj.vertex_groups.new(name=joint)
    group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    parts.append(obj)
    return obj

def mesh(name,points,faces,mat,joint='spine',uv=None,dust=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata([p(v) for v in points],[],faces)
    data.update()
    obj = bpy.data.objects.new(name,data)
    collection.objects.link(obj)
    data.materials.append(mat)
    if dust: data.materials.append(mats['Powder'])
    colors = data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
    for value in colors.data: value.color = (1,1,1,1)
    uvs = data.uv_layers.new(name='UVMap')
    for poly in data.polygons:
        poly.use_smooth = True
        for loop_index in poly.loop_indices:
            vertex = data.vertices[data.loops[loop_index].vertex_index]
            uvs.data[loop_index].uv = uv[data.loops[loop_index].vertex_index] if uv else (vertex.co.x*4,vertex.co.z*4)
    bind(obj,joint)
    if dust:
        dust_points,dust_faces = [],[]
        for poly in data.polygons:
            center = sum((data.vertices[i].co for i in poly.vertices),Vector())/len(poly.vertices)
            cloud = math.sin(center.x*83+center.z*67)+math.sin(center.z*153-center.y*71)+math.sin(center.x*237+center.z*117)
            if cloud<1.80: continue
            normal = poly.normal.normalized()
            if normal.dot(Vector((center.x,center.y,0)))<0: normal = -normal
            tangent = normal.cross(Vector((0,0,1)))
            if tangent.length<.01: continue
            tangent.normalize(); other = normal.cross(tangent).normalized()
            start = len(dust_points)
            for step in range(5):
                theta = math.tau*step/5
                r = .0013+rng.random()*.0026
                v = center+normal*.00045+tangent*math.cos(theta)*r+other*math.sin(theta)*r*.75
                dust_points.append((v.x,v.z,-v.y))
            dust_faces.append(tuple(start+i for i in range(5)))
        if dust_faces: mesh(name+'_StoneDust',dust_points,dust_faces,mats['Powder'],joint)
    return obj

def sphere(name,center,scale,mat,joint='spine',segments=24,rings=14):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=(0,0,0))
    obj = bpy.context.object
    obj.name = name
    for vertex in obj.data.vertices:
        v = vertex.co.copy()
        vertex.co = p((center[0]+v.x*scale[0],center[1]+v.z*scale[1],center[2]+v.y*scale[2]))
    obj.data.materials.append(mat)
    for poly in obj.data.polygons: poly.use_smooth = True
    for old in list(obj.users_collection): old.objects.unlink(obj)
    collection.objects.link(obj)
    return bind(obj,joint)

def curve(name,points,radius,mat,joint='spine',taper=None):
    data = bpy.data.curves.new(name,'CURVE')
    data.dimensions = '3D'
    data.resolution_u = 7
    data.bevel_depth = radius
    data.bevel_resolution = 1 if radius < .0025 else 2
    data.use_fill_caps = True
    if len(points)>=13:
        spline = data.splines.new('POLY')
        spline.points.add(len(points)-1)
        for i,(point,item) in enumerate(zip(points,spline.points)):
            item.co = (*p(point),1)
            item.radius = taper[i] if taper else 1
    else:
        spline = data.splines.new('BEZIER')
        spline.bezier_points.add(len(points)-1)
        for i,(point,item) in enumerate(zip(points,spline.bezier_points)):
            item.co = p(point)
            item.handle_left_type = 'AUTO'
            item.handle_right_type = 'AUTO'
            item.radius = taper[i] if taper else 1
    obj = bpy.data.objects.new(name,data)
    collection.objects.link(obj)
    data.materials.append(mat)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target='MESH')
    for poly in obj.data.polygons: poly.use_smooth = True
    return bind(obj,joint)

def loft(name,rows,mat,joint='spine',segments=48,folds=0,dust=False):
    # rows: height, x radius, front radius, x center, front center.
    points,faces,uv = [],[],[]
    for row,(h,rx,rz,cx,cf) in enumerate(rows):
        for col in range(segments):
            angle = math.tau*col/segments
            wrinkle = 1+folds*math.sin(angle*7+row*.8)+folds*.3*math.sin(angle*13-row*.6)
            points.append((cx+rx*math.cos(angle)*wrinkle,h,cf+rz*math.sin(angle)*wrinkle))
            uv.append((col/segments*1.5,h*2.5))
    for row in range(len(rows)-1):
        for col in range(segments):
            a = row*segments+col
            b = row*segments+(col+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces += [tuple(reversed(range(segments))),tuple((len(rows)-1)*segments+col for col in range(segments))]
    return mesh(name,points,faces,mat,joint,uv,dust)

def tube(name,start,end,r1,r2,mat,joint='spine',segments=24,folds=0):
    a,b = p(start),p(end)
    direction = (b-a).normalized()
    axis = direction.cross(Vector((0,1,0))).normalized()
    other = direction.cross(axis).normalized()
    points,faces,uv = [],[],[]
    for row in range(7):
        t = row/6
        center = a.lerp(b,t)
        radius = (r1*(1-t)+r2*t)*(1+.09*math.sin(t*math.pi))
        for col in range(segments):
            angle = math.tau*col/segments
            value = center+(axis*math.cos(angle)+other*math.sin(angle))*radius*(1+folds*math.sin(angle*6+row))
            points.append((value.x,value.z,-value.y))
            uv.append((col/segments, t))
    for row in range(6):
        for col in range(segments):
            a1 = row*segments+col
            b1 = row*segments+(col+1)%segments
            faces.append((a1,b1,b1+segments,a1+segments))
    faces += [tuple(reversed(range(segments))),tuple(6*segments+col for col in range(segments))]
    obj = mesh(name,points,faces,mat,joint,uv)
    for cap in list(obj.data.polygons)[-2:]: cap.use_smooth = False
    return obj

def ribbon(name,points,width,mat,joint='spine'):
    vertices,faces = [],[]
    for i,(x,h,f) in enumerate(points):
        w = width*(1-.2*i/max(1,len(points)-1))
        vertices += [(x-w/2,h,f),(x+w/2,h,f+.001)]
        if i: faces.append((2*i-2,2*i-1,2*i+1,2*i))
    obj = mesh(name,vertices,faces,mat,joint)
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new('布边厚度','SOLIDIFY')
    modifier.thickness = .0018
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj

# Visible neck, with a gentle flare into the linen neckline.
loft('VisibleNeck',[(1.245,.048,.039,0,-.008),(1.27,.035,.029,0,-.009),
     (1.315,.032,.029,0,-.006),(1.365,.038,.034,0,0)],mats['Neck'],'neck',64)

# Inner crossed linen shirt and sleeveless blue-gray vest.
torso_rows = [(.89,.145,.094,0,0),(.96,.133,.091,0,0),(1.05,.140,.091,0,0),
              (1.16,.150,.090,0,0),(1.23,.156,.080,0,0),(1.27,.103,.057,0,0),(1.292,.047,.041,0,-.004)]
loft('CrossedLinenShirt',torso_rows,mats['Ivory'],folds=.017)

def torso_profile(h):
    for a,b in zip(torso_rows,torso_rows[1:]):
        if h<=b[0]:
            t = (h-a[0])/(b[0]-a[0])
            return a[1]*(1-t)+b[1]*t,a[2]*(1-t)+b[2]*t
    return torso_rows[-1][1:3]

vest_points,vest_faces,vest_uv = [],[],[]
VR,VC = 30,72
for row in range(VR+1):
    h = .905+.375*row/VR
    rx,rz = torso_profile(h)
    rx+=.006; rz+=.006
    opening = .008+max(0,h-1.07)/.21*.055
    opening = min(opening,rx*.94)
    start = math.pi-math.acos(opening/rx)
    end = math.tau+math.acos(opening/rx)
    for col in range(VC+1):
        theta = start+(end-start)*col/VC
        wrinkle = .002*math.sin(theta*9+h*18)
        vest_points.append(((rx+wrinkle)*math.cos(theta),h,(rz+wrinkle)*math.sin(theta)))
        vest_uv.append((col/VC*2,h*2.5))
for row in range(VR):
    for col in range(VC):
        a = row*(VC+1)+col
        vest_faces.append((a,a+1,a+VC+2,a+VC+1))
mesh('OpenSleevelessVest',vest_points,vest_faces,mats['Vest'],uv=vest_uv,dust=True)
for side in [-1,1]:
    edge = []
    for row in range(VR+1):
        edge.append(vest_points[row*(VC+1)+(0 if side<0 else VC)])
    curve('VestBoundEdge',edge,.003,mats['Apron'])
# Cross collar lies on the inner shirt, fully visible in the V opening.
for side in [-1,1]:
    ribbon('InnerCrossCollar',[(side*.052,1.29,.043),(side*.045,1.245,.071),
           (side*.012,1.17,.097),(-side*.026,1.105,.100)],.022,mats['LinenLight'])

# Pants and exposed calves, with rolled knee cuffs and ankle cloth.
for side,suffix in [(-1,'L'),(1,'R')]:
    cx = side*.101
    loft('LooseKneeTrousers.'+suffix,[(.48,.066,.061,cx,.003),(.52,.085,.074,cx,.004),
         (.61,.098,.084,cx,.002),(.73,.104,.087,cx,0),(.84,.101,.083,cx,0),(.94,.088,.074,side*.082,0)],
         mats['Pants'],'thigh.'+suffix,48,.035,True)
    loft('RolledTrouserCuff.'+suffix,[(.475,.070,.065,cx,0),(.49,.080,.075,cx,0),
         (.515,.084,.077,cx,0),(.53,.074,.069,cx,0)],mats['Vest'],'thigh.'+suffix,48,.045,True)
    loft('ExposedCalf.'+suffix,[(.145,.030,.032,side*.109,0),(.23,.037,.037,side*.108,0),
         (.34,.046,.045,side*.106,0),(.455,.042,.040,side*.102,0),(.50,.045,.041,cx,0)],mats['Skin'],'shin.'+suffix,40)
    loft('AnkleCloth.'+suffix,[(.095,.037,.039,side*.109,.005),(.13,.039,.040,side*.109,.003),
         (.18,.037,.037,side*.109,0),(.205,.035,.035,side*.109,0)],mats['LinenLight'],'shin.'+suffix,40,.035)
    for band in range(5):
        points = []
        for step in range(25):
            angle = math.tau*step/24
            points.append((side*.109+.039*math.cos(angle),.113+band*.018+step*.00018,.003+.040*math.sin(angle)))
        curve('AnkleWrappingSeam',points,.0011,mats['Thread'],'shin.'+suffix)
    loft('LayeredClothSole.'+suffix,[(.009,.055,.104,side*.109,.026),(.018,.061,.113,side*.109,.026),
         (.032,.060,.110,side*.109,.026),(.038,.055,.103,side*.109,.026)],mats['Sole'],'foot.'+suffix,48)
    sphere('ClothShoe.'+suffix,(side*.109,.059,.029),(.054,.043,.105),mats['Shoe'],'foot.'+suffix)
    points = [(side*.109+.058*math.cos(a),.032,.026+.110*math.sin(a)) for a in [math.tau*i/48 for i in range(49)]]
    curve('StitchedSoleRim',points,.0014,mats['Thread'],'foot.'+suffix)

# Bare working forearms, rolled sleeves, protective wrist cloth and closed grips.
shoulders,elbows,wrists,hands = {},{},{},{}
for side,suffix in [(-1,'L'),(1,'R')]:
    shoulders[suffix] = (side*.155,1.235,.004)
    elbows[suffix] = (side*.218,1.005,.026)
    wrists[suffix] = (side*.242,.824,.070)
    hands[suffix] = (side*.247,.775,.092)
    tube('RolledWhiteSleeve.'+suffix,shoulders[suffix],(side*.219,.985,.030),.055,.063,mats['Ivory'],'upper_arm.'+suffix,32,.065)
    sphere('SoftShoulderSleeve.'+suffix,(side*.151,1.223,.008),(.061,.062,.057),mats['Ivory'],'upper_arm.'+suffix)
    tube('RolledSleeveCuff.'+suffix,(side*.209,1.045,.023),(side*.223,.985,.031),.064,.069,mats['LinenLight'],'upper_arm.'+suffix,32,.055)
    tube('BareForearm.'+suffix,elbows[suffix],wrists[suffix],.036,.027,mats['Skin'],'forearm.'+suffix,32)
    tube('BlueWristWrap.'+suffix,(side*.235,.874,.055),(side*.247,.814,.074),.033,.032,mats['Wrap'],'forearm.'+suffix,32,.04)
    for band in range(5):
        tube('WristClothFold.'+suffix,(side*(.236+band*.002),.868-band*.011,.058+band*.003),
             (side*(.237+band*.002),.864-band*.011,.059+band*.003),.034,.034,mats['Wrap'],'forearm.'+suffix,24)
    sphere('Palm.'+suffix,(side*.247,.783,.088),(.029,.040,.023),mats['Skin'],'hand.'+suffix)
    # Four rounded fingers curve around the tool shaft, with a separate thumb.
    for finger in range(4):
        h = .801-finger*.014
        curve('GrippingFinger.'+suffix,[(side*.270,h,.090),(side*.265,h-.004,.113),
              (side*.245,h-.007,.120),(side*.232,h-.007,.111)],.0055,mats['Skin'],'hand.'+suffix,taper=[.85,1,1,.7])
    curve('Thumb.'+suffix,[(side*.225,.807,.088),(side*.224,.790,.109),(side*.242,.781,.116)],.008,mats['Skin'],'hand.'+suffix,taper=[1,1,.65])

# Apron: actual curved cloth panels, pocket, border stitches and embroidered flowers.
def apron_point(x,h):
    return (x,h,.128+.014*(1-(h-.56)/.40)+.004*math.sin(x*36+h*21))
apron_points,apron_faces,apron_uv = [],[],[]
AR,AC = 22,32
for row in range(AR+1):
    t = row/AR
    width = .161*(1-t)+.136*t
    for col in range(AC+1):
        u = col/AC
        x = (u*2-1)*width
        h = .565+.39*t+.015*(1-t)*(u-.5)
        apron_points.append(apron_point(x,h))
        apron_uv.append((u,h*2.5))
for row in range(AR):
    for col in range(AC):
        a = row*(AC+1)+col
        apron_faces.append((a,a+1,a+AC+2,a+AC+1))
mesh('EmbroideredWorkApron',apron_points,apron_faces,mats['Apron'],'apron',apron_uv,True)
for offset,mat in [(.0,mats['Thread']),(.007,mats['Red'])]:
    points = [apron_point(-.151+.302*i/24,.581+offset+.014*(i/24-.5)) for i in range(25)]
    curve('ApronEmbroideredBorder',[(x,h,f+.002) for x,h,f in points],.0014,mat,'apron')
mesh('ApronPocket',[(x,h,f+.005) for x,h,f in [apron_point(x,h) for x,h in [(-.134,.65),(-.045,.65),(-.041,.768),(-.13,.78)]]],[(0,1,2,3)],mats['Vest'],'apron',dust=True)
curve('PocketTopSeam',[(-.129,.775,.149),(-.085,.770,.151),(-.043,.765,.149)],.0014,mats['Thread'],'apron')
# Back wrap panel leaves both trouser legs visible.
mesh('BackApronFlap',[(-.155,.62,-.116),(.045,.66,-.121),(.128,.947,-.095),(-.139,.95,-.103)],[(0,1,2,3)],mats['Vest'],'apron',dust=True)

def flower(name,cx,ch,size,joint='apron',shoe=False):
    def point(u,v):
        if shoe:
            surface = .059+.043*math.sqrt(max(0,1-(u/.054)**2-((ch+v-.029)/.105)**2))
            return (cx+u,surface+.0018,ch+v)
        x,h,f = apron_point(cx+u,ch+v)
        return (x,h,f+.003)
    for petal in range(5):
        theta = math.tau*petal/5
        points = []
        for step in range(9):
            a = math.tau*step/8
            along = size*(.55+.43*math.cos(a))
            cross = size*.32*math.sin(a)
            points.append(point(math.cos(theta)*along-math.sin(theta)*cross,math.sin(theta)*along+math.cos(theta)*cross))
        curve(name+'_Petal',points,.00125,mats['Red'],joint)
        mesh(name+'_SatinPetal',points[:-1],[tuple(range(len(points)-1))],mats['Red'],joint)
    sphere(name+'_Center',point(0,0),(.0028,.0020,.0018),mats['Thread'],joint,12,8)

stem = [(.015,.61),(.053,.66),(.070,.715),(.092,.78),(.112,.82)]
curve('FlowerBranch',[(*apron_point(x,h)[:2],apron_point(x,h)[2]+.003) for x,h in stem],.0014,mats['Leaf'],'apron')
for x,h,size in [(.048,.657,.021),(.083,.733,.026),(.108,.798,.018)]: flower('RedMountainFlower',x,h,size)
for x,h,side in [(.037,.637,-1),(.06,.688,1),(.079,.765,-1),(.105,.816,1)]:
    points = [apron_point(x,h),apron_point(x+side*.025,h+.013),apron_point(x+side*.010,h+.023),apron_point(x,h)]
    curve('EmbroideredLeaf',[(a,b,c+.003) for a,b,c in points],.00115,mats['Leaf'],'apron')
for side,suffix in [(-1,'L'),(1,'R')]: flower('ShoeFlower',side*.109,.102,.016,'foot.'+suffix,True)

# Waist sash, knot, hanging ties, brass whistle and rear tool pouch.
loft('WideWaistSash',[(.943,.146,.105,0,0),(.957,.151,.109,0,0),(.981,.147,.106,0,0),(.991,.140,.100,0,0)],mats['Belt'],'hips',64,.035)
curve('BlueSashCord',[(.15*math.cos(a),.97+.006*math.sin(a*3),.112*math.sin(a)) for a in [math.tau*i/64 for i in range(65)]],.006,mats['Wrap'],'hips')
sphere('SashKnot',(-.038,.968,.119),(.019,.015,.013),mats['Belt'],'hips')
for side in [-1,1]:
    curve('SashBow',[(-.038,.97,.122),(-.038+side*.033,.982,.126),(-.038+side*.030,.956,.129),(-.038,.965,.124)],.005,mats['Belt'],'hips')
    ribbon('SashEnd',[(-.038+side*.006,.96,.122),(-.035+side*.019,.91,.144),(-.027+side*.023,.866,.147)],.025,mats['Belt'],'hips')
curve('WhistleChain',[(.125,.975,.092),(.147,.941,.111),(.146,.900,.119)],.0017,mats['Brass'],'charms')
for i in range(4):
    points = [(.146+.005*math.cos(a),.938-i*.011+.007*math.sin(a),.119) for a in [math.tau*j/16 for j in range(17)]]
    curve('WhistleChainLink',points,.0011,mats['Brass'],'charms')
loft('BrassWhistle',[(.849,.010,.008,.146,.122),(.86,.014,.011,.146,.122),(.895,.013,.010,.146,.122),(.905,.008,.007,.146,.122)],mats['Brass'],'charms',24)
sphere('WhistleMouth',(.146,.878,.134),(.003,.007,.0012),mats['Dark'],'charms',16,10)
loft('RearToolPouch',[(.743,.044,.025,.142,-.110),(.76,.052,.034,.142,-.110),(.866,.049,.030,.142,-.110),(.883,.044,.025,.142,-.110)],mats['Vest'],'pouch',32,.03,True)
tube('SpareChiselHandle',(.143,.80,-.123),(.158,.985,-.130),.010,.012,mats['Wood'],'pouch',16)
tube('SpareChiselIronCap',(.158,.968,-.130),(.160,.991,-.131),.013,.013,mats['Steel'],'pouch',16)

# Hand-held mallet and chisel; separate tool bones stow them for carrying/pushing.
tube('MalletHandle',(-.330,.680,.103),(-.171,.848,.137),.012,.010,mats['Wood'],'tool.L',20)
tube('WoodenMalletHead',(-.218,.878,.137),(-.129,.807,.137),.048,.048,mats['Wood'],'tool.L',20)
for center,sign in [((-.218,.878,.137),-1),((-.129,.807,.137),1)]:
    end = (center[0]+sign*.0015,center[1]-sign*.0012,center[2])
    tube('WornMalletEnd',center,end,.047,.047,mats['WoodEnd'],'tool.L',20)
for line in range(4):
    curve('WoodGrain',[(-.218+line*.013,.872-line*.011,.186),(-.192+line*.010,.855-line*.008,.186),(-.16+line*.007,.827-line*.004,.186)],.0008,mats['WoodEnd'],'tool.L')
tube('ChiselGrip',(.245,.834,.105),(.254,.727,.119),.011,.011,mats['Wood'],'tool.R',20)
tube('ChiselShaft',(.253,.737,.119),(.269,.625,.131),.007,.006,mats['Steel'],'tool.R',16)
mesh('ChiselBlade',[(.263,.650,.130),(.275,.650,.130),(.290,.594,.135),(.262,.590,.135),
     (.263,.650,.136),(.275,.650,.136),(.290,.594,.141),(.262,.590,.141)],
     [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],mats['Steel'],'tool.R')

# Hair cap and top bun, surrounded by overlapping strips of blue head cloth.
hair_points,hair_faces = [],[]
HC,HR = 80,20
for row in range(HR+1):
    for col in range(HC):
        theta = math.tau*col/HC
        front = math.sin(theta)
        blend = max(0,min(1,(front+.05)/.65))
        blend = blend*blend*(3-2*blend)
        low = 1.405+.139*blend+.004*math.sin(theta*7)
        h = low+(1.615-low)*row/HR
        t = (h-1.42)/.21
        rx = .090+math.sin(t*math.pi)*.011-max(0,t-.75)*.05
        rz = .074+math.sin(t*math.pi)*.010-max(0,t-.80)*.04
        hair_points.append((rx*math.cos(theta),h,-.008+rz*front))
for row in range(HR):
    for col in range(HC):
        a = row*HC+col; b = row*HC+(col+1)%HC
        hair_faces.append((a,b,b+HC,a+HC))
mesh('TiedHairCap',hair_points,hair_faces,mats['Hair'],'head')
sphere('HairBun',(0,1.618,-.035),(.063,.057,.053),mats['Hair'],'head',32,20)
for i in range(5):
    theta = math.tau*i/5
    sphere('BunCoil',(.025*math.cos(theta),1.637+.009*math.sin(theta),-.035+.025*math.sin(theta)),(.030,.029,.027),mats['Hair'],'head')
for layer in range(5):
    points,faces,uv = [],[],[]
    for step in range(97):
        theta = math.tau*step/96
        middle = 1.558+layer*.014+.014*math.cos(theta+.65)+.009*math.sin(theta*2+layer*.7)
        for edge in [-1,1]:
            h = middle+edge*.014
            radius = .110+layer*.0015+.002*math.sin(theta*7+layer)
            points.append((radius*math.cos(theta),h,-.008+(.089+layer*.0006)*math.sin(theta)))
            uv.append((step/96*2,layer*.3+(edge+1)*.15))
        if step: faces.append((step*2-2,step*2-1,step*2+1,step*2))
    mesh('LayeredHeadWrap',points,faces,mats['Wrap'],'head',uv,True)
    if layer%2==0:
        curve('HeadClothFold',[points[i] for i in range(0,len(points),2)],.0015,mats['Vest'],'head')
# Two crossing swathes soften the regular wrap bands across the forehead.
for fold_index in range(2):
    points,faces,uv = [],[],[]
    for step in range(41):
        x = -.105+.21*step/40
        center = 1.579+fold_index*.025+(1 if fold_index==0 else -1)*x*.20
        front = -.008+.094*math.sqrt(max(0,1-(x/.116)**2))+.0025
        for edge in [-1,1]:
            points.append((x,center+edge*.014,front+.002*math.cos(step/40*math.pi)))
            uv.append((step/40,edge*.15+fold_index*.3))
        if step: faces.append((step*2-2,step*2-1,step*2+1,step*2))
    mesh('CrossingHeadClothFold',points,faces,mats['Wrap'],'head',uv)
for side in [-1,1]:
    for i in range(4):
        curve('CurvedTempleHair',[(side*(.077+i*.005),1.550,.047),
              (side*(.090+i*.004),1.52,.053-i*.004),
              (side*(.097+i*.003),1.474,.027-i*.006),
              (side*(.100+i*.004),1.442-i*.007,.012-i*.004)],
              .0028-i*.00035,mats['Hair'],'head',taper=[1,1,.65,.01])
    for i in range(3):
        curve('LooseHairWisp',[(side*.09,1.526-i*.022,-.018),
              (side*(.117+i*.004),1.504-i*.026,-.004),
              (side*(.11+i*.008),1.47-i*.033,-.012)],.00075,mats['Hair'],'head',taper=[1,.8,.01])
sphere('HeadWrapKnot',(-.088,1.553,-.081),(.029,.021,.022),mats['Wrap'],'head')
ribbon('BackHeadClothTail',[(-.087,1.55,-.09),(-.104,1.484,-.103),(-.092,1.403,-.114)],.050,mats['Wrap'],'ribbon')
for i in range(7):
    curve('FrayedHeadClothEnd',[(-.112+i*.006,1.41,-.113),(-.112+i*.006,1.395-rng.random()*.008,-.112)],.0007,mats['Thread'],'ribbon')
curve('TasselTyingCord',[(-.106,1.56,.045),(-.118,1.518,.026),(-.119,1.492,.026)],.0028,mats['Thread'],'tassel')
for loop in range(3):
    curve('TasselCordKnot',[(-.119,1.513+loop*.003,.026),(-.128,1.519+loop*.003,.029),(-.12,1.524+loop*.003,.032),(-.112,1.515+loop*.003,.027)],.0018,mats['Thread'],'tassel')
for strand in range(19):
    angle = strand*2.399963
    x = -.119+math.cos(angle)*.006
    f = .027+math.sin(angle)*.006
    length = .058+rng.random()*.012
    curve('WhiteWoolTassel',[(x,1.505,f),(x-.004,1.475,f+.003),(x+math.cos(angle)*.006,1.505-length,f+.006)],.0015,mats['LinenLight'],'tassel',taper=[.85,1,.3])

# Consolidate geometry while retaining materials, UVs, primary colors and weights.
for obj in parts:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
bpy.ops.object.select_all(action='DESELECT')
for obj in parts: obj.select_set(True)
bpy.context.view_layer.objects.active = face
bpy.ops.object.join()
character = bpy.context.object
character.name = 'ShiAduo_CharacterMesh'
used_slots = {poly.material_index for poly in character.data.polygons}
for index in reversed(range(len(character.data.materials))):
    if index not in used_slots: character.data.materials.pop(index=index)
for attr in list(character.data.color_attributes)[1:]: character.data.color_attributes.remove(attr)
primary = character.data.color_attributes['Color']

# Gentle geometric occlusion, especially under head cloth and the shaped jaw.
skin_materials = {mats['Skin'],mats['Neck'],face_palette['Face_SoftSkin'],face_palette['Face_EarAndLid']}
skin_slots = {i for i,mat in enumerate(character.data.materials) if mat in skin_materials}
skin_vertices = {i for poly in character.data.polygons if poly.material_index in skin_slots for i in poly.vertices}
bm = bmesh.new(); bm.from_mesh(character.data)
bvh = BVHTree.FromBMesh(bm); bm.free()
sample_directions = []
for i in range(48):
    radius = math.sqrt((i+.5)/48); angle = i*2.399963229728653
    sample_directions.append((radius*math.cos(angle),radius*math.sin(angle),math.sqrt(1-radius*radius)))
ao = {}
for index in skin_vertices:
    vertex = character.data.vertices[index]
    normal = vertex.normal.normalized()
    tangent = normal.cross(Vector((0,0,1)))
    if tangent.length<.01: tangent = normal.cross(Vector((1,0,0)))
    tangent.normalize(); bitangent = normal.cross(tangent).normalized()
    blocked = 0
    for x,y,z in sample_directions:
        hit,_,_,distance = bvh.ray_cast(vertex.co+normal*.0006,tangent*x+bitangent*y+normal*z,.09)
        if hit is not None: blocked += math.exp(-distance/.05)
    ao[index] = blocked/48
neighbors = {i:set() for i in skin_vertices}
for edge in character.data.edges:
    a,b = edge.vertices
    if a in neighbors and b in neighbors: neighbors[a].add(b); neighbors[b].add(a)
for _ in range(3):
    ao = {i:.6*value+.4*sum(ao[n] for n in neighbors[i])/max(1,len(neighbors[i])) for i,value in ao.items()}
for loop in character.data.loops:
    if loop.vertex_index in ao:
        shade = max(.69,1-.56*ao[loop.vertex_index]**.8)
        primary.data[loop.index].color = (shade,shade*.993,shade*.985,1)
for mat in skin_materials:
    shader = mat.node_tree.nodes.get('Principled BSDF')
    base = shader.inputs['Base Color'].default_value[:]
    attribute = mat.node_tree.nodes.new('ShaderNodeVertexColor'); attribute.layer_name = 'Color'
    mix = mat.node_tree.nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'; mix.blend_type = 'MULTIPLY'; mix.inputs[0].default_value = 1
    a = next(s for s in mix.inputs if s.name=='A' and s.type=='RGBA'); b = next(s for s in mix.inputs if s.name=='B' and s.type=='RGBA')
    a.default_value = base
    mat.node_tree.links.new(attribute.outputs['Color'],b)
    mat.node_tree.links.new(next(s for s in mix.outputs if s.type=='RGBA'),shader.inputs['Base Color'])

# Actual game skeleton, including cloth, charm and hand-tool bones.
arm_data = bpy.data.armatures.new('石阿朵_骨架')
armature = bpy.data.objects.new('ShiAduo_Armature',arm_data)
collection.objects.link(armature)
bpy.ops.object.select_all(action='DESELECT'); armature.select_set(True); bpy.context.view_layer.objects.active = armature
bpy.ops.object.mode_set(mode='EDIT')
def bone(name,head,tail,parent=None):
    item = arm_data.edit_bones.new(name); item.head = p(head); item.tail = p(tail)
    if parent: item.parent = arm_data.edit_bones[parent]
bone('root',(0,0,0),(0,.12,0))
bone('hips',(0,.88,0),(0,1.0,0),'root')
bone('spine',(0,1.0,0),(0,1.25,0),'hips')
bone('neck',(0,1.25,0),(0,1.345,0),'spine')
bone('head',(0,1.345,0),(0,1.61,0),'neck')
bone('eyes',(0,1.479,.07),(0,1.515,.07),'head')
bone('apron',(0,.955,.12),(0,.60,.14),'hips')
bone('pouch',(.14,.94,-.11),(.14,.77,-.11),'hips')
bone('charms',(.14,.97,.11),(.14,.85,.12),'hips')
bone('ribbon',(-.09,1.55,-.09),(-.09,1.40,-.11),'head')
bone('tassel',(-.119,1.52,.027),(-.119,1.44,.03),'head')
for side,suffix in [(-1,'L'),(1,'R')]:
    bone('upper_arm.'+suffix,shoulders[suffix],elbows[suffix],'spine')
    bone('forearm.'+suffix,elbows[suffix],wrists[suffix],'upper_arm.'+suffix)
    bone('hand.'+suffix,wrists[suffix],hands[suffix],'forearm.'+suffix)
    bone('tool.'+suffix,hands[suffix],(side*.25,.64,.12),'hand.'+suffix)
    bone('thigh.'+suffix,(side*.09,.90,0),(side*.102,.49,0),'hips')
    bone('shin.'+suffix,(side*.102,.49,0),(side*.109,.13,0),'thigh.'+suffix)
    bone('foot.'+suffix,(side*.109,.13,0),(side*.109,.05,.13),'shin.'+suffix)
bpy.ops.object.mode_set(mode='OBJECT')
armature.show_in_front = False; arm_data.display_type = 'STICK'
character.parent = armature; character.matrix_parent_inverse = Matrix.Identity(4)
modifier = character.modifiers.new('骨骼蒙皮','ARMATURE'); modifier.object = armature
assert all(v.groups for v in character.data.vertices),'Unweighted geometry'
assert all(group.name in arm_data.bones for group in character.vertex_groups),'Unknown joint'

def rotate(name,axis,angle):
    pose = armature.pose.bones[name]
    local_axis = pose.bone.matrix_local.to_3x3().inverted()@Vector(axis)
    pose.rotation_quaternion = Quaternion(local_axis.normalized(),angle)

armature.animation_data_create()
bpy.context.scene.render.fps = 30
actions = {}
for mode,frames in [('idle',141),('walk',20),('jump',24),('push',20),('carry',20),('inspect',90)]:
    action = bpy.data.actions.new(mode); action.use_fake_user = True; armature.animation_data.action = action
    for frame in range(frames+1):
        time = frame/30; phase = math.tau*frame/frames
        stride = math.sin(phase) if mode in {'walk','push','carry'} else 0
        for pose in armature.pose.bones:
            pose.rotation_mode = 'QUATERNION'; pose.rotation_quaternion = Quaternion(); pose.location = (0,0,0); pose.scale = (1,1,1)
        rotate('head',(0,1,0),math.sin(time*1.6)*.011)
        rotate('apron',(1,0,0),stride*.035); rotate('pouch',(1,0,0),stride*.055)
        rotate('charms',(0,1,0),stride*.14); rotate('ribbon',(1,0,0),stride*.11+math.sin(time*2.4)*.025)
        rotate('tassel',(1,0,0),stride*.10+math.sin(time*2.1)*.02)
        for suffix,sign in [('L',1),('R',-1)]:
            rotate('thigh.'+suffix,(1,0,0),stride*.38*sign)
            rotate('shin.'+suffix,(1,0,0),max(0,-stride*sign)*.42)
            if mode=='walk': rotate('upper_arm.'+suffix,(1,0,0),-stride*.18*sign)
        if mode=='jump':
            rotate('thigh.L',(1,0,0),-.32); rotate('thigh.R',(1,0,0),.30)
            rotate('shin.L',(1,0,0),.62); rotate('shin.R',(1,0,0),.65)
        if mode in {'push','carry'}:
            for suffix in ['L','R']:
                rotate('upper_arm.'+suffix,(1,0,0),-.92 if mode=='push' else -1.12)
                rotate('forearm.'+suffix,(1,0,0),-.18)
                armature.pose.bones['tool.'+suffix].scale = (.001,.001,.001)
        if mode=='inspect':
            rotate('head',(1,0,0),.08)
            rotate('upper_arm.R',(1,0,0),-.58); rotate('forearm.R',(1,0,0),-.92)
            rotate('upper_arm.L',(1,0,0),-.28); rotate('forearm.L',(1,0,0),-.38)
        if mode=='idle' and frame in range(135,140): armature.pose.bones['eyes'].scale.y = .08
        for pose in armature.pose.bones:
            pose.keyframe_insert(data_path='rotation_quaternion',frame=frame,group=pose.name)
            pose.keyframe_insert(data_path='location',frame=frame,group=pose.name)
            pose.keyframe_insert(data_path='scale',frame=frame,group=pose.name)
    actions[mode] = action
armature.animation_data.action = actions['idle']
scene = bpy.context.scene; scene.frame_start = 0; scene.frame_end = 141; scene.frame_set(0)

# Pack the new user's reference unchanged, separately from the export selection.
reference_collection = bpy.data.collections.new('REFERENCE_石阿朵用户三视图')
scene.collection.children.link(reference_collection)
image = bpy.data.images.load(str(PROJECT/'references/石阿朵_用户三视图.png')); image.pack()
reference = bpy.data.objects.new('石阿朵_用户原图',None); reference.empty_display_type = 'IMAGE'; reference.data = image
reference.empty_display_size = 3.5; reference.location = (-3.5,0,1.0); reference.rotation_euler = (math.pi/2,0,0); reference.hide_render = True
reference_collection.objects.link(reference)

export_path = ASSETS/'shi_aduo_rigged.glb'
bpy.ops.object.select_all(action='DESELECT'); character.select_set(True); armature.select_set(True); bpy.context.view_layer.objects.active = armature
with contextlib.redirect_stdout(io.StringIO()):
    bpy.ops.export_scene.gltf(filepath=str(export_path),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False)
raw = export_path.read_bytes(); size = struct.unpack_from('<I',raw,12)[0]; gltf = json.loads(raw[20:20+size].decode('utf8'))
names = [a['name'] for a in gltf['animations']]
assert set(names)==set(actions) and len(gltf['skins'])==1
assert gltf.get('images') and character.data.uv_layers
report = {'blender':bpy.app.version_string,'character':'石阿朵','bones':len(arm_data.bones),
          'vertices':len(character.data.vertices),'polygons':len(character.data.polygons),
          'animations':names,'skins':1,'packed_reference':bool(image.packed_file),
          'uv_layers':len(character.data.uv_layers),'vertex_ao_samples':48,'glb':str(export_path)}
(OUT/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
if hasattr(bpy.context.preferences.filepaths,'file_preview_type'): bpy.context.preferences.filepaths.file_preview_type = 'NONE'
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type = 'MATERIAL'
            area.spaces.active.region_3d.view_location = (0,0,.88)
            area.spaces.active.region_3d.view_distance = 2.8
bpy.ops.object.select_all(action='DESELECT'); character.select_set(True); bpy.context.view_layer.objects.active = character
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'石阿朵_角色工程.blend'))
print('SHI_ADUO_BLENDER_OK',json.dumps(report,ensure_ascii=False))
