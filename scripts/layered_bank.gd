extends "res://scripts/environment_art.gd"

var bedrock: ShaderMaterial
var face_rows: int = 11


func setup(left: float, right: float, top: float, bottom: float, front: float, tint: Color, side: int = 0) -> void:
	name="LayeredRockFoundation"
	add_to_group("layered_bank_details")
	rng.seed=20261019+roundi(left*37+front*13)
	bedrock=ShaderMaterial.new()
	bedrock.shader=preload("res://shaders/layered_bank.gdshader")
	bedrock.set_shader_parameter("base_color",tint)
	_face(Vector3(left,0,front),Vector3(right,0,front),top,bottom,Vector3.FORWARD*-1)
	if side!=0:
		var x: float = right if side>0 else left
		_face(Vector3(x,0,-2.25),Vector3(x,0,front),top,bottom,Vector3(side,0,0))
	# Short, offset ledges break the silhouette; none rises into the walk surface.
	for index in range(ceili((right-left)/.85)):
		var x: float = left+.25+index*.85+rng.randf_range(-.16,.16)
		if x>right-.15: continue
		var rock: MeshInstance3D = _rock(self,Vector3(x,top-.24,front+.06),Vector3(rng.randf_range(.75,1.24),.31,rng.randf_range(.42,.72)),bedrock)
		rock.rotation.y=rng.randf_range(-.2,.2)
	for index in range(ceili((right-left)/1.5)):
		var x: float = left+.5+index*1.5+rng.randf_range(-.28,.28)
		if x>right: continue
		var rock: MeshInstance3D = _rock(self,Vector3(x,bottom+.25,front+.12),Vector3(rng.randf_range(1.0,1.9),rng.randf_range(.45,.85),.9),bedrock)
		rock.rotation.z=rng.randf_range(-.22,.22)
	# Broken ledges stand proud of the stratum skin, staggered across several beds.
	for layer in range(1,6):
		for index in range(ceili((right-left)/1.8)):
			var x: float = left+.6+index*1.8+(layer%2)*.65+rng.randf_range(-.2,.2)
			if x>right-.2 or rng.randf()<.22: continue
			var y: float = lerpf(top,bottom,layer/6.0)+rng.randf_range(-.12,.12)
			var ledge: MeshInstance3D = _rock(self,Vector3(x,y,front+.20),Vector3(rng.randf_range(.65,1.45),rng.randf_range(.22,.50),rng.randf_range(.40,.72)),bedrock)
			ledge.rotation.y=rng.randf_range(-.22,.22)
			ledge.rotation.z=rng.randf_range(-.12,.12)
	_merge()
	set_meta("face_rows",face_rows)
	set_meta("style","irregular_horizontal_strata")


func _face(a: Vector3, b: Vector3, top: float, bottom: float, normal: Vector3) -> void:
	var columns: int = maxi(3,ceili(a.distance_to(b)/.43))
	var points: Array[Vector3] = []
	for row in range(face_rows+1):
		var v: float = float(row)/face_rows
		for col in range(columns+1):
			var t: float = float(col)/columns
			var point: Vector3 = a.lerp(b,t)
			var rough: float = sin(t*22+row*.43)*.065+sin(t*47-row*.91)*.045
			point.y=lerpf(top,bottom,v)+(rough if row>0 else -.035*absf(sin(t*19)))
			point+=normal*(.14*sin(t*15+row*.75)+.09*cos(t*31-row*.15)+.10*cos(row*1.7)+(.12 if row%3==1 else 0))
			points.append(point)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(face_rows):
		for col in range(columns):
			var i: int = row*(columns+1)+col
			for id in [i,i+columns+1,i+1,i+1,i+columns+1,i+columns+2]:
				st.set_uv(Vector2(points[id].x,points[id].y))
				st.add_vertex(points[id])
	st.index()
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name="FracturedBankFace"
	mesh.mesh=st.commit()
	mesh.material_override=bedrock
	add_child(mesh)


func _merge() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for child: Node in get_children():
		if not child is MeshInstance3D: continue
		st.append_from(child.mesh,0,child.transform)
		child.free()
	var merged := MeshInstance3D.new()
	merged.name="LayeredLedgesAndTalus"
	merged.mesh=st.commit()
	merged.material_override=bedrock
	add_child(merged)
