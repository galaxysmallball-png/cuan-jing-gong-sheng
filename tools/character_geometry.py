"""Mesh primitives shared by the Lao Qing build; derived from the existing Shi tools.

The build initializes collection, parts, mats and rng on this module explicitly.
No scene or source file is opened or rebuilt when this utility is imported.
"""
import bpy
import math
from mathutils import Vector

collection = None
parts = []
mats = {}
rng = None

def p(point):
    x,h,f = point
    return Vector((x,-f,h))


class CurveBatch:
    """Build many wool/rope/hair tubes without thousands of scene operators."""
    def __init__(self):
        self.batches = {}

    def __call__(self,name,points,radius,mat,joint='spine',taper=None):
        controls = [p(v) for v in points]
        scales = taper or [1]*len(points)
        centers,weights = [],[]
        steps = 4 if len(points)<13 else 1
        for i in range(len(controls)-1):
            before = controls[max(0,i-1)]
            a,b = controls[i:i+2]
            after = controls[min(len(controls)-1,i+2)]
            for j in range(steps):
                t = j/steps
                center = .5*((2*a)+(-before+b)*t+(2*before-5*a+4*b-after)*t*t+(-before+3*a-3*b+after)*t**3)
                centers.append(center)
                weights.append(scales[i]*(1-t)+scales[i+1]*t)
        centers.append(controls[-1]); weights.append(scales[-1])
        vertices,faces,material = self.batches.setdefault((joint,mat.name),([],[],mat))
        sides = 6 if radius<.003 else 8
        start = len(vertices)
        for i,center in enumerate(centers):
            direction = (centers[min(i+1,len(centers)-1)]-centers[max(0,i-1)]).normalized()
            across = direction.cross(Vector((0,0,1)))
            if across.length<.01: across=direction.cross(Vector((1,0,0)))
            across.normalize(); other=direction.cross(across)
            for j in range(sides):
                angle = math.tau*j/sides
                v = center+(across*math.cos(angle)+other*math.sin(angle))*radius*weights[i]
                vertices.append((v.x,v.z,-v.y))
            if i:
                for j in range(sides):
                    k=start+(i-1)*sides+j; n=start+(i-1)*sides+(j+1)%sides
                    faces.append((k,n,n+sides,k+sides))
        faces.append(tuple(reversed([start+j for j in range(sides)])))
        faces.append(tuple(start+(len(centers)-1)*sides+j for j in range(sides)))

    def flush(self):
        for (joint,name),(vertices,faces,material) in self.batches.items():
            mesh('细节曲线_'+joint+'_'+name,vertices,faces,material,joint)
        self.batches.clear()

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


