extends RefCounted
static var leaf_material: StandardMaterial3D

static func blade(st: SurfaceTool,a: Vector3,b: Vector3,width: float,tint: Color) -> void:
	var direction: Vector3=b-a
	var side:=Vector3(-direction.y,direction.x,.12).normalized()*width
	var mid: Vector3=a.lerp(b,.43)+Vector3(0,0,.025)
	var outline: Array[Vector3]=[a,a.lerp(b,.28)+side,a.lerp(b,.67)+side*.64,b,a.lerp(b,.67)-side*.64,a.lerp(b,.28)-side]
	for i in range(outline.size()):
		var next: int=(i+1)%outline.size()
		st.set_color(tint.lightened(.08) if i<3 else tint.darkened(.08))
		for p in [outline[i],mid,outline[next]]: st.add_vertex(p)

static func leaf_mesh() -> ArrayMesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var a: float=i*2.39996
		var root:=Vector3(cos(a)*.32,sin(a)*.45,sin(i*1.9)*.2)
		var tip: Vector3=root+Vector3(cos(a)*.75,.15+sin(a)*.35,sin(a)*.6)
		blade(st,root,tip,.16,Color(.92,.96,.87))
	st.generate_normals()
	return st.commit()

static func sprig(parent: Node3D,a: Vector3,b: Vector3,width: float,tint: Color) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	blade(st,Vector3.ZERO,b-a,width,tint)
	st.generate_normals()
	var node:=MeshInstance3D.new()
	node.mesh=st.commit()
	node.position=a
	if leaf_material==null:
		leaf_material=StandardMaterial3D.new()
		leaf_material.vertex_color_use_as_albedo=true
		leaf_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		leaf_material.roughness=.94
	node.material_override=leaf_material
	parent.add_child(node)
	return node
