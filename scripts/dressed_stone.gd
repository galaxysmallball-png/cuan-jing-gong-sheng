extends RefCounted


static func block(dimensions: Vector3, bevel: float=.035) -> ArrayMesh:
	# Cut rectangular masonry, with a real bevel around the bed and exposed face.
	var h: Vector3=dimensions*.5
	var b: float=minf(bevel,minf(h.x,minf(h.y,h.z))*.4)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array]=[]
	for section in range(4):
		var inset: float=b if section in [0,3] else 0.0
		var x: float=h.x-inset
		var y: float=h.y-inset
		var z: float=[-h.z,-h.z+b,h.z-b,h.z][section]
		var ring:=PackedVector3Array()
		for point: Vector2 in [Vector2(-x+b,-y),Vector2(x-b,-y),Vector2(x,-y+b),Vector2(x,y-b),Vector2(x-b,y),Vector2(-x+b,y),Vector2(-x,y-b),Vector2(-x,-y+b)]:
			ring.append(Vector3(point.x,point.y,z))
		rings.append(ring)
	for index in range(8):
		var next: int=(index+1)%8
		for layer in range(3):
			_tri(st,rings[layer][index],rings[layer+1][index],rings[layer+1][next])
			_tri(st,rings[layer][index],rings[layer+1][next],rings[layer][next])
		_tri(st,Vector3(0,0,-h.z),rings[0][index],rings[0][next])
		_tri(st,Vector3(0,0,h.z),rings[3][next],rings[3][index])
	st.generate_normals()
	return st.commit()


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a,b,c]:
		st.set_uv(Vector2(point.x,point.y))
		st.add_vertex(point)
