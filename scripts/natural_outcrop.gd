extends RefCounted

# An irregular, bevelled rock profile. Each face follows the silhouette rather
# than scaling a box; the crown and chamfer give the stone a readable volume.
static func make(parent: Node3D, at: Vector3, outline: PackedVector2Array, depth: float, material: Material) -> MeshInstance3D:
	var center:=Vector2.ZERO
	for point in outline: center+=point
	center/=outline.size()
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(outline.size()):
		var a: Vector2=outline[i]
		var b: Vector2=outline[(i+1)%outline.size()]
		var aa: Vector2=a.lerp(center,.09)
		var bb: Vector2=b.lerp(center,.09)
		tri(st,Vector3(a.x,a.y,-depth),Vector3(b.x,b.y,-depth),Vector3(a.x,a.y,-.09))
		tri(st,Vector3(b.x,b.y,-depth),Vector3(b.x,b.y,-.09),Vector3(a.x,a.y,-.09))
		tri(st,Vector3(a.x,a.y,-.09),Vector3(b.x,b.y,-.09),Vector3(bb.x,bb.y,0))
		tri(st,Vector3(a.x,a.y,-.09),Vector3(bb.x,bb.y,0),Vector3(aa.x,aa.y,0))
		tri(st,Vector3(aa.x,aa.y,0),Vector3(bb.x,bb.y,0),Vector3(center.x,center.y,.18))
	st.generate_normals()
	var node:=MeshInstance3D.new()
	node.mesh=st.commit()
	node.position=at
	node.material_override=material
	parent.add_child(node)
	return node

static func tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	for p in [a,c,b]:
		st.set_uv(Vector2(p.x,p.y))
		st.add_vertex(p)

static func stone(tint: Color, moss: float=.25) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/courtyard_stone.gdshader")
	material.set_shader_parameter("base_color",tint)
	material.set_shader_parameter("moss_amount",moss)
	return material
