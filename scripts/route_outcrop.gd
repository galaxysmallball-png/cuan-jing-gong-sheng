extends RefCounted

# A closed, uneven outcrop with a recessed middle and chipped bedding edges.
# Its surface is modelled in depth; the route shader only supplies the incision.
const COLS: int=32
const ROWS: int=30

static func point(u: float,v: float) -> Vector3:
	var s: float=u*2-1
	var width: float=1.52-.13*v-.19*smoothstep(.73,1,v)+.025*sin(v*19)
	var x: float=s*width+.025*sin(v*9)
	var crest: float=_crest(u)
	var y: float=lerpf(-.06,crest,v)
	var shelf: float=.055*sin(floor((y+.08*sin(x*1.7))*3.7)*2.3+x*.8)
	var z: float=.12+.16*cos(s*1.6)+.035*sin(x*4.7+y*2.2)+.015*sin(x*11.9+y*8.1)+shelf
	# A narrow, darker split at the right shoulder has a real recessed profile.
	z-=.10*exp(-pow((x-1.01+.10*sin(y*2.8))/.10,2))
	return Vector3(x,y,z)

static func _crest(u: float) -> float:
	var heights: PackedFloat32Array=[2.25,2.51,2.49,2.67,2.62,2.50,2.46,2.17]
	var segment: int=mini(6,int(u*7))
	return lerpf(heights[segment],heights[segment+1],clampf(u*7-segment,0,1))

static func build(parent: Node3D) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(ROWS+1):
		for col in range(COLS+1):
			var p: Vector3=point(float(col)/COLS,float(row)/ROWS)
			st.set_uv(Vector2(p.x,p.y))
			st.add_vertex(p)
	for row in range(ROWS):
		for col in range(COLS):
			var a: int=row*(COLS+1)+col
			for id in [a,a+COLS+1,a+1,a+1,a+COLS+1,a+COLS+2]: st.add_index(id)
	st.generate_normals()
	var front: ArrayMesh=st.commit()
	# All four outside edges turn into a recessed rear body, rather than ending
	# in a paper-thin silhouette. Keep a hard crease at the chipped perimeter.
	var edge:=SurfaceTool.new()
	edge.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in range(4):
		var steps: int=COLS if side<2 else ROWS
		for i in range(steps):
			var t: float=float(i)/steps
			var tt: float=float(i+1)/steps
			var a: Vector3=point(t,0) if side==0 else point(1-t,1) if side==1 else point(0,1-t) if side==2 else point(1,t)
			var b: Vector3=point(tt,0) if side==0 else point(1-tt,1) if side==1 else point(0,1-tt) if side==2 else point(1,tt)
			var aa:=Vector3(a.x*.86,a.y*.95,-.95)
			var bb:=Vector3(b.x*.86,b.y*.95,-.95)
			for p in [a,b,aa,b,bb,aa]:
				edge.set_uv(Vector2(p.x,p.y))
				edge.add_vertex(p)
	edge.generate_normals()
	edge.commit(front)
	var mesh:=MeshInstance3D.new()
	mesh.mesh=front
	mesh.set_meta("sculpted_surface",true)
	parent.add_child(mesh)
	return mesh
