"""Build Lao Qing from the supplied sheet, opening Deng v3 as a topology library.

Writes a separate Lao source/GLB; never saves over Deng or Shi source files.
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
sys.path.insert(0,str(PROJECT/'tools'))
import character_geometry as geo

OUT = PROJECT/'character-source/lao_qing'
ASSETS = PROJECT/'assets/characters/lao_qing'
OUT.mkdir(parents=True,exist_ok=True)
ASSETS.mkdir(parents=True,exist_ok=True)
rng = random.Random(501016)
library = bpy.data.objects['Deng_CharacterMesh']
face = library.copy(); face.data = library.data.copy()
bpy.context.scene.collection.objects.link(face)
face.name = 'Lao_FacialTopology'; face.parent = None
face.matrix_world = Matrix.Identity(4); face.modifiers.clear()
keep_slots = {i for i,m in enumerate(face.data.materials) if m and m.name.startswith('Face_') and m.name not in {'Face_Neck','Face_MatteHair'}}
keep = {i for poly in face.data.polygons if poly.material_index in keep_slots for i in poly.vertices}
bm = bmesh.new(); bm.from_mesh(face.data); bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in keep],context='VERTS')
bm.to_mesh(face.data); bm.free()
for obj in list(bpy.data.objects):
    if obj != face: bpy.data.objects.remove(obj,do_unlink=True)
for action in list(bpy.data.actions): bpy.data.actions.remove(action)
for group in list(face.vertex_groups):
    if group.name not in {'head','eyes'}: face.vertex_groups.remove(group)
for attr in list(face.data.color_attributes)[1:]: face.data.color_attributes.remove(attr)
face.data.color_attributes[0].name = 'Color'
for color in face.data.color_attributes[0].data: color.color = (1,1,1,1)
cloth_image = next(i for i in bpy.data.images if 'Indigo_albedo' in i.name)
if not cloth_image.has_data: cloth_image.pixels[0]
cloth_image.pack()
for image in list(bpy.data.images):
    if image!=cloth_image and image.type=='IMAGE': bpy.data.images.remove(image)
collection = bpy.data.collections.new('老箐_可编辑角色')
bpy.context.scene.collection.children.link(collection)
for old in list(face.users_collection): old.objects.unlink(face)
collection.objects.link(face)
geo.collection = collection; geo.parts = [face]; geo.rng = rng
p,mesh,sphere,curve,loft,tube,ribbon = geo.p,geo.mesh,geo.sphere,geo.curve,geo.loft,geo.tube,geo.ribbon
curve_batch = geo.CurveBatch()
curve = curve_batch

def linear(color):
    return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in color)

def multiply(mat,source,constant=None):
    mix = mat.node_tree.nodes.new('ShaderNodeMix'); mix.data_type='RGBA'; mix.blend_type='MULTIPLY'; mix.inputs[0].default_value=1
    a = next(s for s in mix.inputs if s.name=='A' and s.type=='RGBA')
    b = next(s for s in mix.inputs if s.name=='B' and s.type=='RGBA')
    if source: mat.node_tree.links.new(source,a)
    else: a.default_value=constant
    return b,next(s for s in mix.outputs if s.type=='RGBA')

def material(name,color,cloth=False,metal=0):
    mat = bpy.data.materials.new('Lao_'+name); mat.use_nodes=True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*linear(color),1)
    shader.inputs['Roughness'].default_value=.93 if not metal else .72
    shader.inputs['Specular IOR Level'].default_value=.04
    shader.inputs['Metallic'].default_value=metal
    mat.diffuse_color=(*linear(color),1)
    if cloth:
        texture = mat.node_tree.nodes.new('ShaderNodeTexImage'); texture.image=cloth_image
        b,out = multiply(mat,None,(*linear(color),1))
        mat.node_tree.links.new(texture.outputs['Color'],b)
        mat.node_tree.links.new(out,shader.inputs['Base Color'])
    return mat

mats = {
 'Skin':material('Skin',(.60,.45,.32)), 'Neck':material('Neck',(.59,.44,.32)),
 'Robe':material('WornBlueRobe',(.25,.29,.32),True), 'RobeEdge':material('RobeFoldEdge',(.31,.34,.35),True),
 'Pants':material('CharcoalTrousers',(.19,.22,.24),True),
 'Cloak':material('DarkFeltCloak',(.16,.15,.13),True), 'Tuft':material('FeltWoolTufts',(.165,.155,.135),True),
 'TuftLight':material('WornFeltTips',(.19,.18,.15)), 'CloakInner':material('FeltInner',(.13,.125,.11)),
 'Headband':material('IndigoHeadband',(.19,.22,.25),True),
 'Linen':material('CreamSashAndWraps',(.72,.68,.57),True), 'LinenEdge':material('LinenEdge',(.66,.62,.52)),
 'Rope':material('HempRope',(.49,.42,.30)), 'RopeLight':material('HempFibers',(.60,.53,.40)),
 'Bag':material('CoarseClothBag',(.55,.48,.36),True), 'BagStripe':material('BagWovenStripe',(.35,.32,.25),True),
 'Hair':material('DarkHair',(.11,.105,.09)), 'HairGray':material('GrayHair',(.31,.295,.25)),
 'Wrinkle':material('AgeCrease',(.40,.29,.20)), 'Lip':material('DryLip',(.45,.30,.22)),
 'Wood':material('VineStaff',(.34,.275,.18)), 'WoodLight':material('StaffWornGrain',(.48,.40,.28)),
 'Straw':material('StrawSandal',(.38,.32,.19)), 'StrawLight':material('StrawWeave',(.51,.44,.28)),
 'Sole':material('StrawSole',(.29,.25,.16)),
 'Brass':material('HorseBell',(.52,.40,.19),metal=.45), 'BellDark':material('BellInterior',(.16,.125,.07)),
 'Powder':material('ClothWear',(.36,.35,.30)),
}
geo.mats = mats
face_palette = {}
for i,old in enumerate(face.data.materials):
    if i not in keep_slots: continue
    mat = old.copy(); mat.name = 'Lao_'+old.name.removeprefix('Face_')
    shader = mat.node_tree.nodes.get('Principled BSDF')
    if old.name in {'Face_SoftSkin','Face_EarAndLid'}:
        for node in list(mat.node_tree.nodes):
            if node.type not in {'OUTPUT_MATERIAL','BSDF_PRINCIPLED'}: mat.node_tree.nodes.remove(node)
        shader.inputs['Base Color'].default_value=(*linear((.63,.49,.36)),1)
        shader.inputs['Specular IOR Level'].default_value=.04
        shader.inputs['Roughness'].default_value=.92
    face.data.materials[i]=mat; face_palette[old.name]=mat

def gauss(x,h,cx,ch,sx,sh): return math.exp(-((x-cx)/sx)**2-((h-ch)/sh)**2)

# Long, lean older face, prominent nose and hollow cheeks rather than a recolor.
origin = Vector((0,0,1.48*.86)); untilt=Matrix.Rotation(.02,3,'Y').inverted()
for v in face.data.vertices:
    local=untilt@(v.co-origin)/.86
    x,h,f=local.x,local.z,-local.y
    x *= .88*(1+.07*gauss(abs(x),h,.065,.07,.035,.04))
    f *= .84
    front = max(0,min(1,f/.060))**5
    f += front*(.012*gauss(x,h,0,.148,.018,.039)-sum(.005*gauss(x,h,s*.060,.151,.030,.030) for s in [-1,1]))
    v.co=p((x,1.405+(h-.030)*.85,f))
# Replace the arched young brows with a lower, stronger inner edge.
brow_slot = next(i for i,m in enumerate(face.data.materials) if m==face_palette['Face_Brows'])
remove_brows=set()
for poly in face.data.polygons:
    if poly.material_index!=brow_slot: continue
    for index in poly.vertices:
        v=face.data.vertices[index]
        if v.co.z>1.586: remove_brows.add(index)
bm=bmesh.new(); bm.from_mesh(face.data); bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[bm.verts[i] for i in remove_brows],context='VERTS'); bm.to_mesh(face.data); bm.free()
face.data.update()
skin_slot = next(i for i,m in enumerate(face.data.materials) if m==face_palette['Face_SoftSkin'])
bvh=BVHTree.FromPolygons([v.co.copy() for v in face.data.vertices],[tuple(f.vertices) for f in face.data.polygons if f.material_index==skin_slot])
def skin_front(x,h):
    hit,_,_,_=bvh.ray_cast(Vector((x,-.5,h)),Vector((0,1,0)),1)
    return -hit.y if hit is not None else .065

def wrinkle(name,points,r=.00055):
    curve(name,[(x,h,skin_front(x,h)+.00035) for x,h in points],r,mats['Wrinkle'],'head',taper=[.1]+[.65]*(len(points)-2)+[.1])

for side in [-1,1]:
    brow=[(side*.013,1.604),(side*.036,1.612),(side*.061,1.612),(side*.081,1.607)]
    curve('StrongOlderBrow',[(x,h,skin_front(x,h)+.0020) for x,h in brow],.0027,mats['Hair'],'head',taper=[.5,1,.85,.03])

for row in range(3):
    wrinkle('ForeheadAgeFold',[(x,1.634+row*.011+.0015*math.sin(x*70+row)) for x in [-.058,-.038,-.02,0,.021,.04,.057]],.00048)
for side in [-1,1]:
    wrinkle('NasolabialFold',[(side*.023,1.510),(side*.032,1.491),(side*.038,1.465),(side*.039,1.452)],.00062)
    wrinkle('UnderEyeFold',[(side*.017,1.542),(side*.032,1.532),(side*.051,1.533),(side*.068,1.542)],.00048)
    wrinkle('CheekWeathering',[(side*.073,1.526),(side*.077,1.504),(side*.072,1.483)],.00043)
    for crow in range(3):
        wrinkle('CrowFoot',[(side*.068,1.557-crow*.002),(side*.079,1.556-crow*.006),(side*.085,1.554-crow*.009)],.00043)
    wrinkle('FrownLine',[(side*.009,1.626),(side*.012,1.614),(side*.016,1.602)],.0005)
    for i in range(9):
        x=side*(.043+rng.random()*.033); h=1.488+rng.random()*.040
        sphere('WeatheredSkinMark',(x,h,skin_front(x,h)+.0002),(.0006,.0009,.00015),mats['Wrinkle'],'head',12,8)
    # Two tapered masses and fine strands form the moustache.
    for i in range(14):
        x=side*(.004+i*.0018); h=1.468-i*.00044
        curve('MoustacheStrand',[(x,h,skin_front(x,h)+.0014),(x+side*.004,h-.005,skin_front(x+side*.004,h-.005)+.0017),(x+side*.005,h-.009,skin_front(x+side*.005,h-.009)+.001)],.00063,mats['HairGray'] if i%7==0 else mats['Hair'],'head',taper=[.8,1,.05])
    for i in range(20):
        x=side*(.010+i*.0025); h=1.411+abs(x)*.26
        curve('JawStubble',[(x,h,skin_front(x,h)+.001),(x+side*.001,h-.005,skin_front(x,h)+.0015)],.00052,mats['HairGray'] if i%6==0 else mats['Hair'],'head',taper=[.8,.03])
for i in range(30):
    x=(i-14.5)*.00135; h=1.422-abs(x)*.15
    curve('PointedGoatee',[(x,h,skin_front(x,h)+.0018),(x*.68,h-.018,.063),(x*.24,1.383+rng.random()*.009,.044)],.0009,mats['HairGray'] if i%8==0 else mats['Hair'],'head',taper=[.8,1,.02])

loft('VisibleNeck',[(1.306,.050,.039,0,-.007),(1.35,.037,.030,0,-.007),(1.395,.033,.030,0,-.004),(1.431,.038,.034,0,0)],mats['Neck'],'neck',64)
for side in [-1,1]:
    curve('NeckTendon',[(side*.028,1.404,.018),(side*.024,1.365,.022),(side*.015,1.325,.036)],.0012,mats['Skin'],'neck',taper=[.2,1,.2])

# Layered robe with an open V at the neck, and loose breeches below.
robe_rows=[(.55,.154,.093,0,0),(.62,.161,.096,0,0),(.83,.153,.094,0,0),(.97,.141,.091,0,0),(1.12,.154,.093,0,0),(1.27,.174,.091,0,-.004),(1.34,.146,.071,0,-.009),(1.377,.053,.044,0,-.009)]
robe=loft('LongWornInnerRobe',robe_rows,mats['Robe'],segments=64,folds=.025,dust=True)
# Open the collar at the throat and expose a real neck, rather than a blue yoke.
for v in robe.data.vertices:
    if v.co.z<1.32: continue
    x,h,f=v.co.x,v.co.z,-v.co.y
    front=max(0,min(1,(f+.009)/.044))
    v.co.z-=.055*front**1.5*max(0,min(1,(h-1.32)/.057))
bm=bmesh.new(); bm.from_mesh(robe.data); bm.faces.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[bm.faces[-1]],context='FACES_ONLY'); bm.to_mesh(robe.data); bm.free()
robe_bvh=BVHTree.FromPolygons([v.co.copy() for v in robe.data.vertices],[tuple(poly.vertices) for poly in robe.data.polygons])
for side in [-1,1]:
    path=[(side*.052,1.372,.023),(side*.040,1.345,.040),(side*.020,1.325,.052),(-side*.012,1.301,.067)]
    points,faces,uv=[],[],[]
    for seg in range(3):
        a,b=Vector(path[seg]),Vector(path[seg+1]); direction=(b-a).normalized(); across=Vector((-direction.y,direction.x,0)).normalized()
        for j in range(9):
            t=j/8; center=a.lerp(b,t)
            for edge in [-1,1]:
                v=center+across*(edge*.010)
                hit,_,_,_=robe_bvh.ray_cast(Vector((v.x,-.5,v.y)),Vector((0,1,0)),1)
                f=-hit.y if hit is not None else center.z
                points.append((v.x,v.y,f+.002)); uv.append(((edge+1)/2*.2,(seg+t)*.2))
            row=seg*9+j
            if row: faces.append((row*2-2,row*2-1,row*2+1,row*2))
    mesh('FittedCrossedBlueCollar',points,faces,mats['RobeEdge'])
    curve('CreamCollarLining',[(x,h,f+.003) for x,h,f in path],.0026,mats['Linen'])
    suffix='L' if side<0 else 'R'
    loft('LooseBreeches.'+suffix,[(.305,.057,.058,side*.083,0),(.34,.065,.064,side*.087,0),(.48,.077,.075,side*.087,0),(.66,.077,.079,side*.079,0),(.86,.073,.073,side*.074,0),(.96,.065,.066,side*.069,0)],mats['Pants'],'thigh.'+suffix,48,.05,dust=True)
    loft('CalfLinenWrap.'+suffix,[(.105,.034,.036,side*.084,0),(.18,.035,.037,side*.084,0),(.26,.038,.040,side*.084,0),(.335,.042,.043,side*.084,0)],mats['Linen'],'shin.'+suffix,40,.045)
    for band in range(9):
        points=[]
        for step in range(33):
            a=math.tau*step/32
            points.append((side*.084+(.036+band*.0005)*math.cos(a),.116+band*.024+.008*math.sin(a),(.039+band*.0004)*math.sin(a)))
        curve('CrossedCalfBinding',points,.0018,mats['LinenEdge'],'shin.'+suffix)
    sphere('StrawSandalSole.'+suffix,(side*.086,.036,.041),(.057,.022,.108),mats['Sole'],'foot.'+suffix,32,14)
    sphere('WovenStrawToe.'+suffix,(side*.086,.061,.067),(.053,.035,.075),mats['Straw'],'foot.'+suffix,32,18)
    for loop in range(9):
        h=.050+loop*.0035; rx=.056-loop*.0004; rz=.108-loop*.0015
        curve('BraidedSandalEdge',[(side*.086+rx*math.cos(math.tau*j/49),h,.041+rz*math.sin(math.tau*j/49)) for j in range(50)],.00145,mats['StrawLight'],'foot.'+suffix)
    for i in range(13):
        x=side*.086+(i-6)*.007
        curve('StrawToeWeave',[(x,.053,.131),(x,.077,.112),(x,.092,.072),(x,.084,.026)],.0017,mats['StrawLight'],'foot.'+suffix,taper=[.5,1,1,.4])
    for i in range(7):
        f=.032+i*.014
        curve('CrossStrawWeave',[(side*.086-.042,.071,f),(side*.086,.096,f+.002),(side*.086+.042,.071,f)],.0016,mats['Straw'],'foot.'+suffix)

shoulders={'L':(-.163,1.31,.0),'R':(.163,1.31,0)}
elbows={'L':(-.252,1.084,.036),'R':(.238,1.063,.015)}
wrists={'L':(-.285,.971,.113),'R':(.260,.885,.045)}
hands={'L':(-.292,.940,.141),'R':(.264,.846,.051)}
for side,suffix in [(-1,'L'),(1,'R')]:
    tube('InnerRobeSleeve.'+suffix,shoulders[suffix],elbows[suffix],.067,.071,mats['Robe'],'upper_arm.'+suffix,40,.05)
    end=Vector(elbows[suffix]).lerp(Vector(wrists[suffix]),.18)
    tube('PaleTurnedCuff.'+suffix,elbows[suffix],tuple(end),.074,.075,mats['RobeEdge'],'upper_arm.'+suffix,40,.07)
    tube('WeatheredForearm.'+suffix,elbows[suffix],wrists[suffix],.035,.026,mats['Skin'],'forearm.'+suffix,32)
    cx,h,f=hands[suffix]
    tube('ConnectedWrist.'+suffix,wrists[suffix],(cx,h+.012,f),.025,.024,mats['Skin'],'hand.'+suffix,32)
    sphere('LeanPalm.'+suffix,(cx,h,f),(.026,.038,.021),mats['Skin'],'hand.'+suffix)
    for finger in range(4):
        if suffix=='L':
            hh=h+.019-finger*.013
            points=[(cx-.020,hh,f-.004),(cx-.014,hh-.002,f+.020),(cx+.002,hh-.004,f+.026),(cx+.013,hh-.006,f+.012)]
        else:
            xx=cx-.017+finger*.011
            points=[(xx,h-.011,f+.012),(xx,h-.039,f+.018),(xx-.002,h-.048,f+.008)]
        curve('GrippingFinger.'+suffix,points,.0063,mats['Skin'],'hand.'+suffix,taper=[1,1,.9,.65] if suffix=='L' else [1,1,.6])
    curve('Thumb.'+suffix,[(cx-side*.021,h+.024,f),(cx-side*.027,h+.005,f+.025),(cx-side*.008,h-.005,f+.027)],.008,mats['Skin'],'hand.'+suffix,taper=[1,1,.5])

# A soft thick felt cloak; separate skirt panels let the walk silhouette breathe.
def robe_profile(h):
    for a,b in zip(robe_rows,robe_rows[1:]):
        if h<=b[0]:
            t=max(0,(h-a[0])/(b[0]-a[0])); return a[1]*(1-t)+b[1]*t,a[2]*(1-t)+b[2]*t
    return robe_rows[-1][1:3]

def felt_position(t,a,extra=0):
    h=.565+.803*t
    rx=.204+.057*math.sin(t*math.pi*.91)
    rz=.120+.026*math.sin(t*math.pi)
    if t>.88:
        q=(t-.88)/.12; rx=rx*(1-q)+.094*q; rz=rz*(1-q)+.063*q
    wave=.0035*math.sin(a*13+h*35)+.002*math.sin(a*21-h*19)
    hem=(1-t)**7*(.010*math.sin(a*11)+.007*math.cos(a*17))
    return ((rx+extra+wave)*math.cos(a),h+hem,-.012+(rz+extra+wave)*math.sin(a))

def solidify(obj,thickness):
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('真实衣料厚度','SOLIDIFY'); mod.thickness=thickness; mod.offset=-.4
    bpy.ops.object.modifier_apply(modifier=mod.name)

NROWS,NCOLS=42,112
points,faces,uv=[],[],[]
for row in range(NROWS+1):
    t=row/NROWS; opening=.30+.075*math.sin(t*math.pi)
    for col in range(NCOLS+1):
        a=math.pi/2+opening+(math.tau-2*opening)*col/NCOLS
        points.append(felt_position(t,a)); uv.append((col/NCOLS*3,t*2))
        if row and col:
            k=(row-1)*(NCOLS+1)+col-1; faces.append((k,k+1,k+NCOLS+2,k+NCOLS+1))
cloak=mesh('ThickWoolFeltCloak',points,faces,mats['Cloak'],'cloak_back',uv)
solidify(cloak,.005)
# Shoulder area follows the torso; lower panels respond to their own cloth bones.
for group in list(cloak.vertex_groups): cloak.vertex_groups.remove(group)
cloak_groups={name:cloak.vertex_groups.new(name=name) for name in ['spine','cloak_back','cloak.L','cloak.R']}
for v in cloak.data.vertices:
    x,h,f=v.co.x,v.co.z,-v.co.y
    torso=max(0,min(1,(h-.99)/.27)); name='cloak.L' if x<-.06 and f>-.07 else ('cloak.R' if x>.06 and f>-.07 else 'cloak_back')
    if torso: cloak_groups['spine'].add([v.index],torso,'REPLACE')
    if torso<1: cloak_groups[name].add([v.index],1-torso,'REPLACE')

# Curled short wool locks, all real tapered mesh geometry (no hair add-on).
for row in range(23):
    for col in range(67):
        t=max(.012,min(.96,.018+row/23*.94+rng.uniform(-.014,.014)))
        a=math.pi/2+.34+(math.tau-.68)*(col+rng.uniform(-.40,.40))/67
        x,h,f=felt_position(t,a,.001)
        joint='spine' if h>1.22 else ('cloak.L' if x<-.06 and f>-.07 else ('cloak.R' if x>.06 and f>-.07 else 'cloak_back'))
        length=.018+rng.random()*.020
        outward=Vector((math.cos(a),0,math.sin(a)))
        center=Vector((x,h,f))
        slant=rng.uniform(-.008,.008)
        path=[tuple(center),tuple(center+outward*.005+Vector((slant*.6,-length*.42,.001))),tuple(center+outward*.003+Vector((slant,-length,.001)))]
        curve('ShortWoolLock',path,.0030+rng.random()*.0011,mats['TuftLight'] if rng.random()<.035 else mats['Tuft'],joint,taper=[.12,1,.01])
for side in [-1,1]:
    suffix='L' if side<0 else 'R'
    a,b=Vector(shoulders[suffix]),Vector(elbows[suffix])
    tube('FeltShoulderSleeve.'+suffix,tuple(a+Vector((0,.012,0))),tuple(a.lerp(b,.84)),.083,.084,mats['Cloak'],'upper_arm.'+suffix,40,.06)
    sphere('RoundedFeltShoulder.'+suffix,(a.x,a.y+.002,a.z),(.076,.054,.076),mats['Cloak'],'upper_arm.'+suffix,32,20)
    for row in range(9):
        t=max(0,min(.93,row/9*.89+rng.uniform(-.025,.025)))
        center=a.lerp(b,t)
        for col in range(23):
            angle=math.tau*(col+rng.uniform(-.35,.35))/23
            radius=.091+.005*math.sin(t*math.pi)
            x,h,f=center+Vector((radius*math.cos(angle),.012,radius*math.sin(angle)))
            curve('SleeveWoolLock',[(x,h,f),(x+.002,h-.013,f+.002),(x+.001,h-.030-rng.random()*.009,f+.001)],.0032,mats['Tuft'],'upper_arm.'+suffix,taper=[.15,1,.01])

# Broad cream waist wrap, diagonal folds, tied tails and frayed ends.
loft('CreamWaistSash',[(.942,.160,.105,0,0),(.964,.162,.106,0,0),(1.003,.158,.104,0,0),(1.024,.153,.102,0,0)],mats['Linen'],'hips',64,.025)
for i in range(6):
    pts=[]
    for j in range(41):
        a=math.pi*j/40
        pts.append((.161*math.cos(a),.952+i*.011+.012*math.cos(a+i*.4),.109*math.sin(a)+.002))
    curve('SashDiagonalFold',pts,.0025,mats['LinenEdge'],'hips')
sphere('SashTiedKnot',(.083,.988,.104),(.022,.024,.018),mats['Linen'],'hips')
for tail in range(2):
    x=.071+tail*.022
    ribbon('LongCreamSashTail',[(x,.986,.113),(x-.003,.84,.129),(x+.003,.70,.142),(x-.006,.585+tail*.04,.151)],.035,mats['Linen'],'hips')
    for fringe in range(6):
        xx=x-.020+fringe*.006
        curve('SashFrayedThread',[(xx,.595+tail*.04,.15),(xx+.001,.575+tail*.04-rng.random()*.01,.15)],.00065,mats['LinenEdge'],'hips')

# Back satchel and three-strand shoulder rope.
bag_center=Vector((.115,.943,-.177))
bag=sphere('CoarseClothSatchel',tuple(bag_center),(.111,.163,.061),mats['Bag'],'pouch',48,32)
for v in bag.data.vertices:
    d=v.co-p(tuple(bag_center)); v.co.x+=.002*math.sin(v.co.z*58+d.x*35); v.co.y+=.003*math.sin(v.co.z*49+d.x*41)
# Woven stripes are fitted to the outer/back ellipsoid, not floating flat bands.
for stripe in range(5):
    xcenter=-.072+stripe*.035
    pts,faces,uv=[],[],[]
    for row in range(33):
        t=row/32; phi=-1.10+2.25*t
        for side in [-1,1]:
            xx=xcenter+side*.006
            radius=math.sqrt(max(0,1-(xx/.111)**2))
            pts.append((bag_center.x+xx,bag_center.y+.163*radius*math.sin(phi),bag_center.z-.062*radius*math.cos(phi)-.005))
            uv.append(((side+1)/2*.2,t))
        if row: faces.append((row*2-2,row*2-1,row*2+1,row*2))
    mesh('SatchelWovenStripe',pts,faces,mats['BagStripe'],'pouch',uv)
def rope(name,path,radius,joint):
    curve(name+'Core',path,radius,mats['Rope'],joint)
    # Helical strands along Catmull-smoothed center sampled from a temporary curve.
    for strand in range(3):
        pts=[]
        for segment in range(len(path)-1):
            a,b=Vector(path[segment]),Vector(path[segment+1])
            direction=(p(tuple(b))-p(tuple(a))).normalized()
            across=direction.cross(Vector((0,0,1)))
            if across.length<.01: across=direction.cross(Vector((1,0,0)))
            across.normalize(); other=direction.cross(across)
            for j in range(15):
                t=j/15; angle=(segment+t)*math.tau*5+strand*math.tau/3
                v=p(tuple(a.lerp(b,t)))+(across*math.cos(angle)+other*math.sin(angle))*radius*.85
                pts.append((v.x,v.z,-v.y))
        curve(name+'TwistedStrand',pts,radius*.23,mats['RopeLight'],joint)
rope('ShoulderHempRope',[(.146,1.015,.116),(.164,1.245,.101),(.160,1.354,.005),(.151,1.303,-.125),(.106,1.147,-.197)],.008,'spine')
for side in [-1,1]:
    rope('SatchelGatheredCord',[(.115,.945,-.22),(.115+side*.085,1.051,-.202),(.115+side*.045,1.121,-.175),(.115,1.151,-.155)],.004,'pouch')
for i in range(3):
    curve('ShoulderRopeKnot',[(.15,1.297-i*.006,-.127),(.175,1.293-i*.006,-.141),(.173,1.314-i*.006,-.157),(.151,1.304-i*.006,-.128)],.005,mats['Rope'],'spine')

# A hollow horse bell with rim, suspension loop, slit and clapper.
bell_center=(-.112,.844,.136)
loft('HollowHorseBell',[(.807,.043,.039,-.112,.136),(.819,.044,.040,-.112,.136),(.849,.039,.035,-.112,.136),(.876,.028,.025,-.112,.136),(.890,.009,.009,-.112,.136)],mats['Brass'],'charms',48)
loft('DarkBellMouth',[(.806,.036,.033,-.112,.136),(.808,.036,.033,-.112,.136)],mats['BellDark'],'charms',40)
curve('BellRolledRim',[(-.112+.044*math.cos(math.tau*i/48),.814,.136+.040*math.sin(math.tau*i/48)) for i in range(49)],.003,mats['Brass'],'charms')
curve('BellSuspensionLoop',[(-.121,.888,.137),(-.128,.907,.139),(-.112,.918,.140),(-.099,.902,.138),(-.104,.888,.137)],.0037,mats['Brass'],'charms')
sphere('BellClapper',(-.112,.802,.136),(.008,.012,.008),mats['Brass'],'charms')
rope('BellHangingCord',[(-.11,.973,.113),(-.130,.953,.127),(-.112,.916,.139)],.0035,'charms')
curve('BellSoundSlit',[(-.124,.838,.173),(-.110,.834,.176),(-.095,.838,.173)],.0018,mats['BellDark'],'charms')

# Uneven vine staff, with nodes and worn lengthwise grain; tool bone can stow it.
staff_path=[(-.312,.019,.142),(-.307,.27,.144),(-.303,.52,.143),(-.302,.75,.145),(-.295,.96,.143),(-.287,1.105,.140)]
curve('VineWalkingStaff',staff_path,.011,mats['Wood'],'tool.L',taper=[.88,.90,.95,1,1.03,1])
for i in range(9):
    h=.07+i*.116
    sphere('StaffNaturalNode',(-.310+h*.020,h,.144),(.0118,.005,.0118),mats['WoodLight'],'tool.L',16,10)
for i in range(7):
    a=math.tau*i/7
    pts=[(x+.0105*math.cos(a),h,f+.0105*math.sin(a)) for x,h,f in staff_path]
    curve('StaffLongGrain',pts,.00065,mats['WoodLight'],'tool.L')

# Tied head cloth, actual rear knot/tails, swept back hair and loose wisps.
points,faces=[],[]
HC,HR=96,28
for row in range(HR+1):
    t=row/HR
    for col in range(HC):
        a=math.tau*col/HC; front=math.sin(a)
        low=1.465+.195*max(0,min(1,(front+.05)/.75))
        h=low+(1.78-low)*math.sin(t*math.pi/2)
        r=.094*math.cos(t*math.pi/2)+.0005
        points.append((r*math.cos(a),h+.0015*math.sin(a*9)*math.sin(t*math.pi),-.015+r*.86*math.sin(a)))
for row in range(HR):
    for col in range(HC):
        k=row*HC+col; n=row*HC+(col+1)%HC; faces.append((k,n,n+HC,k+HC))
mesh('SweptBackScalp',points,faces,mats['Hair'],'head')
sphere('TiedBackHair',(.005,1.746,-.047),(.071,.052,.060),mats['Hair'],'head',40,24)
for i in range(28):
    a=math.tau*i/28
    pts=[]
    for j in range(17):
        t=.08+j/16*.86
        low=1.465+.195*max(0,min(1,(math.sin(a)+.05)/.75))
        h=low+(1.78-low)*math.sin(t*math.pi/2)
        r=.094*math.cos(t*math.pi/2)+.0015
        pts.append((r*math.cos(a),h,-.015+r*.86*math.sin(a)))
    curve('CombedHairStrand',pts,.0008,mats['HairGray'] if i%8==0 else mats['Hair'],'head',taper=[.15]+[.65]*15+[.05])
for layer in range(2):
    pts,faces,uv=[],[],[]
    for i in range(129):
        a=math.tau*i/128
        for j in range(7):
            v=-1+j/3; center=1.695+layer*.025+.013*math.cos(a+.5)+.004*math.sin(2*a)
            r=.099+.0025*(1-v*v)+layer*.0003
            pts.append((r*math.cos(a),center+v*.018,-.014+r*.82*math.sin(a))); uv.append((i/128*2,j/6*.4))
        if i:
            for j in range(6):
                k=(i-1)*7+j; faces.append((k,k+1,k+8,k+7))
    obj=mesh('WrappedHeadClothFold',pts,faces,mats['Headband'],'head',uv); solidify(obj,.0025)
sphere('RearHeadclothKnot',(0,1.712,-.104),(.026,.023,.017),mats['Headband'],'head')
for tail in range(2):
    x=-.013+tail*.026
    ribbon('HeadclothRearTail',[(x,1.71,-.111),(x+(-.014 if tail==0 else .02),1.616,-.121),(x+.012,1.515+tail*.022,-.132)],.041,mats['Headband'],'ribbon')
for side in [-1,1]:
    for i in range(5):
        curve('AgeingTempleHair',[(side*(.073+i*.003),1.682,.041-i*.004),(side*(.087+i*.002),1.617,.041-i*.005),(side*.094,1.548-i*.006,.011-i*.003)],.0022,mats['HairGray'] if i==4 else mats['Hair'],'head',taper=[1,.9,.04])
    for i in range(2):
        curve('LooseWindblownHair',[(side*.065,1.77,-.015),(side*(.094+i*.010),1.79-i*.004,.010),(side*.11,1.76-i*.009,.0)],.0012,mats['Hair'],'head',taper=[1,.7,.02])

# Consolidate meshes, normalize normals, keep only primary vertex Color and UV.
curve_batch.flush()
print('LAO_MESH_PARTS_READY',len(geo.parts),flush=True)
for obj in geo.parts:
    bm=bmesh.new(); bm.from_mesh(obj.data); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(obj.data); bm.free()
bpy.ops.object.select_all(action='DESELECT')
for obj in geo.parts: obj.select_set(True)
bpy.context.view_layer.objects.active=face; bpy.ops.object.join()
character=bpy.context.object; character.name='LaoQing_CharacterMesh'
used={f.material_index for f in character.data.polygons}
for i in reversed(range(len(character.data.materials))):
    if i not in used: character.data.materials.pop(index=i)
for attr in list(character.data.color_attributes):
    if attr.name!='Color': character.data.color_attributes.remove(attr)
colors=character.data.color_attributes['Color']
skin_mats={mats['Skin'],mats['Neck'],face_palette['Face_SoftSkin'],face_palette['Face_EarAndLid']}
slots={i for i,m in enumerate(character.data.materials) if m in skin_mats}
skin_indices={i for poly in character.data.polygons if poly.material_index in slots for i in poly.vertices}
bm=bmesh.new(); bm.from_mesh(character.data); bvh=BVHTree.FromBMesh(bm); bm.free()
samples=[]
for i in range(64):
    r=math.sqrt((i+.5)/64); a=i*2.399963229728653
    samples.append((r*math.cos(a),r*math.sin(a),math.sqrt(1-r*r)))
ao={}
for index in skin_indices:
    v=character.data.vertices[index]; n=v.normal.normalized(); t=n.cross(Vector((0,0,1)))
    if t.length<.01: t=n.cross(Vector((1,0,0)))
    t.normalize(); b=n.cross(t); value=0
    for x,y,z in samples:
        hit,_,_,distance=bvh.ray_cast(v.co+n*.00055,t*x+b*y+n*z,.10)
        if hit is not None: value+=math.exp(-distance/.048)
    ao[index]=value/64
neighbors={i:set() for i in skin_indices}
for edge in character.data.edges:
    a,b=edge.vertices
    if a in neighbors and b in neighbors: neighbors[a].add(b); neighbors[b].add(a)
for _ in range(3): ao={i:.6*v+.4*sum(ao[n] for n in neighbors[i])/max(1,len(neighbors[i])) for i,v in ao.items()}
for poly in character.data.polygons:
    if character.data.materials[poly.material_index] not in skin_mats: continue
    for loop in poly.loop_indices:
        shade=max(.68,1-.58*ao[character.data.loops[loop].vertex_index]**.8)
        colors.data[loop].color=(shade,shade*.994,shade*.985,1)
for mat in skin_mats:
    shader=mat.node_tree.nodes.get('Principled BSDF'); base=shader.inputs['Base Color'].default_value[:]
    attr=mat.node_tree.nodes.new('ShaderNodeVertexColor'); attr.layer_name='Color'
    b,out=multiply(mat,None,base); mat.node_tree.links.new(attr.outputs['Color'],b); mat.node_tree.links.new(out,shader.inputs['Base Color'])

# Dedicated game rig, including independent felt skirt panels, bag, bell and staff.
arm_data=bpy.data.armatures.new('老箐_骨架'); armature=bpy.data.objects.new('LaoQing_Armature',arm_data); collection.objects.link(armature)
bpy.ops.object.select_all(action='DESELECT'); armature.select_set(True); bpy.context.view_layer.objects.active=armature; bpy.ops.object.mode_set(mode='EDIT')
def bone(name,head,tail,parent=None):
    item=arm_data.edit_bones.new(name); item.head=p(head); item.tail=p(tail)
    if parent: item.parent=arm_data.edit_bones[parent]
bone('root',(0,0,0),(0,.12,0))
bone('hips',(0,.91,0),(0,1.03,0),'root'); bone('spine',(0,1.03,0),(0,1.31,0),'hips')
bone('neck',(0,1.31,0),(0,1.405,0),'spine'); bone('head',(0,1.405,0),(0,1.75,0),'neck')
bone('eyes',(0,1.561,.08),(0,1.59,.08),'head')
bone('cloak_back',(0,1.20,-.12),(0,.64,-.14),'spine')
bone('cloak.L',(-.17,1.20,.06),(-.19,.65,.09),'spine'); bone('cloak.R',(.17,1.20,.06),(.19,.65,.09),'spine')
bone('pouch',(.115,1.15,-.155),(.115,.82,-.18),'spine')
bone('charms',(-.11,.97,.12),(-.11,.82,.14),'hips')
bone('ribbon',(0,1.71,-.11),(0,1.51,-.13),'head')
for side,suffix in [(-1,'L'),(1,'R')]:
    bone('upper_arm.'+suffix,shoulders[suffix],elbows[suffix],'spine')
    bone('forearm.'+suffix,elbows[suffix],wrists[suffix],'upper_arm.'+suffix)
    bone('hand.'+suffix,wrists[suffix],hands[suffix],'forearm.'+suffix)
    if suffix=='L': bone('tool.L',hands[suffix],(-.302,.75,.143),'hand.L')
    bone('thigh.'+suffix,(side*.084,.92,0),(side*.084,.34,0),'hips')
    bone('shin.'+suffix,(side*.084,.34,0),(side*.084,.10,0),'thigh.'+suffix)
    bone('foot.'+suffix,(side*.084,.10,0),(side*.084,.04,.14),'shin.'+suffix)
bpy.ops.object.mode_set(mode='OBJECT'); arm_data.display_type='STICK'
assert len(arm_data.bones)==25
character.parent=armature; character.matrix_parent_inverse=Matrix.Identity(4)
modifier=character.modifiers.new('骨骼蒙皮','ARMATURE'); modifier.object=armature
assert all(v.groups for v in character.data.vertices)
assert all(g.name in arm_data.bones for g in character.vertex_groups)
def rotate(name,axis,angle):
    pose=armature.pose.bones[name]; local=pose.bone.matrix_local.to_3x3().inverted()@Vector(axis)
    pose.rotation_quaternion=Quaternion(local.normalized(),angle)
armature.animation_data_create(); bpy.context.scene.render.fps=30; actions={}
for mode,frames in [('idle',141),('walk',24),('jump',24),('push',24),('carry',24),('inspect',90)]:
    action=bpy.data.actions.new(mode); action.use_fake_user=True; armature.animation_data.action=action
    for frame in range(frames+1):
        time=frame/30; phase=math.tau*frame/frames; stride=math.sin(phase) if mode in {'walk','push','carry'} else 0
        for pose in armature.pose.bones:
            pose.rotation_mode='QUATERNION'; pose.rotation_quaternion=Quaternion(); pose.location=(0,0,0); pose.scale=(1,1,1)
        rotate('head',(0,1,0),math.sin(time*1.4)*.009)
        rotate('cloak_back',(1,0,0),stride*.025); rotate('cloak.L',(1,0,0),stride*.055); rotate('cloak.R',(1,0,0),-stride*.055)
        rotate('pouch',(1,0,0),stride*.035); rotate('charms',(0,1,0),stride*.12); rotate('ribbon',(1,0,0),stride*.07+math.sin(time*2)*.014)
        for suffix,sign in [('L',1),('R',-1)]:
            rotate('thigh.'+suffix,(1,0,0),stride*.28*sign)
            rotate('shin.'+suffix,(1,0,0),max(0,-stride*sign)*.32)
            if mode=='walk': rotate('upper_arm.'+suffix,(1,0,0),-stride*(.035 if suffix=='L' else .15)*sign)
        if mode=='jump':
            rotate('thigh.L',(1,0,0),-.30); rotate('thigh.R',(1,0,0),.25)
            rotate('shin.L',(1,0,0),.52); rotate('shin.R',(1,0,0),.54)
            armature.pose.bones['tool.L'].scale=(.001,.001,.001)
        if mode in {'push','carry'}:
            for suffix in ['L','R']:
                rotate('upper_arm.'+suffix,(1,0,0),-.85 if mode=='push' else -1.10)
                rotate('forearm.'+suffix,(1,0,0),-.20)
            armature.pose.bones['tool.L'].scale=(.001,.001,.001)
        if mode=='inspect':
            rotate('head',(1,0,0),.07); rotate('upper_arm.R',(1,0,0),-.45); rotate('forearm.R',(1,0,0),-.72)
        if mode=='idle' and frame in range(135,140): armature.pose.bones['eyes'].scale.y=.08
        for pose in armature.pose.bones:
            for prop in ['rotation_quaternion','location','scale']: pose.keyframe_insert(data_path=prop,frame=frame,group=pose.name)
    actions[mode]=action
armature.animation_data.action=actions['idle']
scene=bpy.context.scene; scene.frame_start=0; scene.frame_end=141; scene.frame_set(0)
ref_collection=bpy.data.collections.new('REFERENCE_老箐用户三视图'); scene.collection.children.link(ref_collection)
image=bpy.data.images.load(str(PROJECT/'references/老箐_用户三视图.png')); image.pack()
reference=bpy.data.objects.new('老箐_用户原图',None); reference.empty_display_type='IMAGE'; reference.data=image
reference.empty_display_size=3.5; reference.location=(-3.5,0,1); reference.rotation_euler=(math.pi/2,0,0); reference.hide_render=True; ref_collection.objects.link(reference)
export_path=ASSETS/'lao_qing_rigged.glb'
bpy.ops.object.select_all(action='DESELECT'); character.select_set(True); armature.select_set(True); bpy.context.view_layer.objects.active=armature
with contextlib.redirect_stdout(io.StringIO()):
    bpy.ops.export_scene.gltf(filepath=str(export_path),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False)
raw=export_path.read_bytes(); size=struct.unpack_from('<I',raw,12)[0]; gltf=json.loads(raw[20:20+size].decode('utf8'))
assert len(gltf['skins'])==1 and {a['name'] for a in gltf['animations']}==set(actions)
cloak_mat=next(m for m in gltf['materials'] if m['name']=='Lao_DarkFeltCloak')
assert cloak_mat['pbrMetallicRoughness'].get('baseColorTexture') and cloak_mat['pbrMetallicRoughness']['baseColorFactor'][0]<.1
report={'blender':bpy.app.version_string,'character':'老箐','bones':len(arm_data.bones),'vertices':len(character.data.vertices),'polygons':len(character.data.polygons),'animations':[a['name'] for a in gltf['animations']],'skins':1,'uv_layers':len(character.data.uv_layers),'vertex_ao_samples':64,'packed_images':2,'glb':str(export_path)}
(OUT/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
if hasattr(bpy.context.preferences.filepaths,'file_preview_type'): bpy.context.preferences.filepaths.file_preview_type='NONE'
bpy.ops.object.select_all(action='DESELECT'); character.select_set(True); bpy.context.view_layer.objects.active=character
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL'; area.spaces.active.region_3d.view_location=(0,0,.94); area.spaces.active.region_3d.view_distance=2.8
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'老箐_角色工程.blend'))
print('LAO_QING_BLENDER_OK',json.dumps(report,ensure_ascii=False))
