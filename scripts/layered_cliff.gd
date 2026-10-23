extends RefCounted

# Continuous eroded rock with broad shoulders, changing beds and a tapered
# crest. The front is a real triangulated surface, never stretched prisms.
static func build(parent: Node3D, at: Vector3, width: float, height: float, seed_value: float) -> Node3D:
	var root:=Node3D.new()
	root.position=at
	root.name="ErodedContinuousCliff"
	root.add_to_group("eroded_cliff_details")
	parent.add_child(root)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols: int=38
	var rows: int=28
	for col in range(cols):
		for row in range(rows):
			var a: Vector3=point(col/float(cols),row/float(rows),width,height,seed_value)
			var b: Vector3=point((col+1)/float(cols),row/float(rows),width,height,seed_value)
			var c: Vector3=point(col/float(cols),(row+1)/float(rows),width,height,seed_value)
			var d: Vector3=point((col+1)/float(cols),(row+1)/float(rows),width,height,seed_value)
			tri(st,a,c,b)
			tri(st,b,c,d)
	for edge in [0.0,1.0]:
		for row in range(rows):
			var a: Vector3=point(edge,row/float(rows),width,height,seed_value)
			var b: Vector3=point(edge,(row+1)/float(rows),width,height,seed_value)
			var c:=Vector3(a.x,a.y,-2.2)
			var d:=Vector3(b.x,b.y,-2.2)
			if edge==0:
				tri(st,a,c,b);tri(st,c,d,b)
			else:
				tri(st,a,b,c);tri(st,c,b,d)
	for col in range(cols):
		var a: Vector3=point(col/float(cols),1,width,height,seed_value)
		var b: Vector3=point((col+1)/float(cols),1,width,height,seed_value)
		tri(st,a,Vector3(a.x,a.y-.12,-2.2),b)
		tri(st,b,Vector3(a.x,a.y-.12,-2.2),Vector3(b.x,b.y-.12,-2.2))
	st.generate_normals()
	var node:=MeshInstance3D.new()
	node.mesh=st.commit()
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/layered_cliff.gdshader")
	material.set_shader_parameter("base_color",Color(.29,.36,.37))
	material.set_shader_parameter("seed_offset",seed_value)
	node.material_override=material
	node.name="ContinuousRockBack"
	root.set_meta("surface_grid",Vector2i(cols,rows))
	root.add_child(node)
	# Broad, staggered plates provide real ledges, broken corners and cast
	# shadows. Three tinted batches retain that structure without twelve draws.
	var batches: Array[SurfaceTool]=[]
	for i in range(3):
		var tool:=SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches.append(tool)
	for row in range(4):
		for col in range(3):
			var jitter: float=sin(row*8.1+col*3.7+seed_value)
			var w: float=(2.55-row*.20+jitter*.15)*width/7
			var h: float=1.55-row*.07+jitter*.13
			var x: float=(-2.32+col*2.26+(row%2)*.22)*width/7
			var y: float=.8+row*1.23+jitter*.10
			var silhouette:=PackedVector2Array([Vector2(-.48*w,-.43*h),Vector2(.25*w,-.49*h),Vector2(.51*w,-.27*h),Vector2(.47*w,.26*h),Vector2(.26*w,.48*h),Vector2(-.25*w,.43*h),Vector2(-.52*w,.23*h),Vector2(-.54*w,-.23*h)])
			var block: MeshInstance3D=preload("res://scripts/natural_outcrop.gd").make(root,Vector3(x,y,.28+jitter*.10-row*.045),silhouette,.70,material)
			batches[(row+col)%3].append_from(block.mesh,0,block.transform)
			block.free()
	for i in range(3):
		var batch:=MeshInstance3D.new()
		batch.mesh=batches[i].commit()
		var stone: ShaderMaterial=material.duplicate()
		stone.set_shader_parameter("base_color",Color(.29,.36,.37)*(1.0+(i-1)*.065))
		batch.material_override=stone
		batch.name="BrokenLedgeCourse"+str(i)
		root.add_child(batch)
	root.set_meta("broken_ledge_plates",12)
	return root

static func point(u: float,v: float,width: float,height: float,s: float) -> Vector3:
	var crest: float=.79+.055*sin(u*7.6+s)+.04*sin(u*17.8+s*2)+.018*sin(u*41+s)
	var shoulder: float=pow(maxf(0,1-pow(absf(u-.5)*1.8,4)),.18)
	var y: float=v*height*crest*shoulder
	var x: float=(u-.5)*width*lerpf(1.08,.86,v)+sin(v*9.7+s)*.12
	var strata: float=floor((y+.09*sin(x*1.4+s))*4.5)/4.5
	var ledge: float=.17*sin(strata*4.8+s)+.08*sin(strata*9.5+x*.8)
	var folds: float=.24*sin(x*1.8+s+v*.7)+.08*sin(x*4.9+s*1.5)
	var z: float=folds+ledge-.32*v+.10*sin(u*29+v*13+s)
	return Vector3(x,y,z)

static func tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	for p in [a,b,c]:
		st.set_uv(Vector2(p.x,p.y))
		st.add_vertex(p)
