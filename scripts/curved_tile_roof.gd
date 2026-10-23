extends "res://scripts/environment_art.gd"

var roof_width: float
var roof_depth: float
var tile_count: int = 0


func setup(width: float, depth: float, tint: Color = Color(.20,.27,.28)) -> void:
	name="CurvedTileRoof"
	add_to_group("curved_tile_roofs")
	roof_width=width
	roof_depth=depth
	var columns: int = maxi(8,ceili(width/.19))
	var rows: int = maxi(2,ceili(depth*.5/.29))
	var pitch: float = width/columns
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		for col in range(columns):
			for row in range(rows):
				tile_count+=1
				var shade: float = .90+.16*fmod(col*.618+row*.37+side*.12,1.0)
				for cross in range(4):
					for segment in range(2):
						var quad: Array[Vector3] = []
						for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
							var u: float = (cross+corner.x)/4.0-.5
							var v: float = (segment+corner.y)/2.0
							var x: float = -width*.5+(col+.5)*pitch+u*pitch*.97
							var t: float = (row+v*1.06)/rows
							var point: Vector3 = _point(x,t,side)
							point.y+=cos(u*PI)*.044+(1-v)*.012
							quad.append(point)
						for id in ([0,2,1,1,2,3] if side<0 else [0,1,2,1,3,2]):
							st.set_color(Color(shade,shade,shade))
							st.set_uv(Vector2(col+cross/4.0,row+segment/2.0))
							st.add_vertex(quad[id])
	st.index()
	st.generate_normals()
	var tiles := MeshInstance3D.new()
	tiles.name="OverlappingBarrelTiles"
	tiles.mesh=st.commit()
	var tile_material := StandardMaterial3D.new()
	tile_material.albedo_color=tint
	tile_material.vertex_color_use_as_albedo=true
	tile_material.roughness=.84
	tile_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	tiles.material_override=tile_material
	add_child(tiles)
	var rim: Material = _flat(tint*1.19)
	var wood: Material = _surface(Color(.26,.15,.08),2)
	var ridges: Array = []
	var timber: Array = []
	var end_carvings: Array = []
	for side in [-1,1]:
		for col in range(columns):
			var x: float = -width*.5+(col+.5)*pitch
			var end: Vector3 = _point(x,1.04,side)
			# Rounded tile ends, a narrow drip edge and recessed rafter heads.
			ridges.append([end+Vector3(0,0,-side*.045),end+Vector3(0,0,side*.025),.052])
			if side==1 and col%2==0:
				for part in range(8):
					var a: float = TAU*part/8
					var b: float = TAU*(part+1)/8
					end_carvings.append([end+Vector3(cos(a)*.035,sin(a)*.035,.030),end+Vector3(cos(b)*.035,sin(b)*.035,.030),.004])
			if col%2==0:
				timber.append([end+Vector3(0,-.11,-side*.30),end+Vector3(0,-.11,-side*.02),.031])
		for segment in range(maxi(6,columns/2)):
			var a: float = -width*.5+segment*width/maxi(6,columns/2)
			var b: float = -width*.5+(segment+1)*width/maxi(6,columns/2)
			ridges.append([_point(a,1,side)-Vector3(0,.06,0),_point(b,1,side)-Vector3(0,.06,0),.035])
		for end in [-1,1]:
			var previous: Vector3 = _point(end*width*.5,.72,side)
			for part in range(1,7):
				var p: float = part/6.0
				var next: Vector3 = _point(end*(width*.5+p*.23),.72+p*.31,side)+Vector3(0,p*p*.15,0)
				ridges.append([previous,next,.045*(1-p*.35)])
				previous=next
	for col in range(columns):
		var x: float = -width*.5+(col+.5)*pitch
		ridges.append([Vector3(x-pitch*.5,.10,0),Vector3(x+pitch*.5,.10,0),.079])
	_rods_merged(self,rim,ridges).name="RidgeCapsAndDripTiles"
	_rods_merged(self,wood,timber).name="RecessedRafterHeads"
	_rods_merged(self,_flat(tint*.73),end_carvings).name="CarvedTileEndRings"
	# Fascia is behind the rounded tile lip, rather than a large exposed roof slab.
	var beams: Array = []
	for side in [-1,1]:
		beams.append([Vector3(width-.18,.12,.10),Transform3D(Basis.IDENTITY,Vector3(0,-.52,side*depth*.43))])
	_boxes_merged(self,wood,beams).name="EaveFascia"
	set_meta("tile_count",tile_count)
	set_meta("surface","overlapping_curved_barrel_tiles")


func _point(x: float, t: float, side: int) -> Vector3:
	var corner: float = pow(clampf(absf(x)/(roof_width*.5),0,1),10)*.21*t*t
	return Vector3(x,.04-.58*sin(t*PI*.5)+.13*pow(t,6)+corner,side*roof_depth*.5*t)
