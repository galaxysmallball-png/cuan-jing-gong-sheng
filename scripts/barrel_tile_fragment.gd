extends RefCounted

static func mesh(width: float, length: float) -> ArrayMesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for col in range(8):
		for face in [0,1]:
			var corners: Array=[Vector2(0,0),Vector2(0,1),Vector2(1,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]
			if face==1: corners.reverse()
			for corner: Vector2 in corners:
				var u: float=(col+corner.x)/8.0
				st.set_uv(Vector2(u,corner.y))
				st.add_vertex(Vector3((u-.5)*width,cos((u-.5)*PI)*.045-face*.035,-length*.5+corner.y*length))
		for end in [-1,1]:
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var u: float=(col+corner.x)/8.0
				st.set_uv(corner)
				st.add_vertex(Vector3((u-.5)*width,cos((u-.5)*PI)*.045-corner.y*.035,end*length*.5))
	st.generate_normals()
	return st.commit()
