extends "res://scripts/environment_art.gd"

# Native scenery derived from the user's three concept boards. No scenery colliders:
# the established walking lane, interactive objects and puzzle anchors stay authoritative.
var world: Node3D
var scenes: Array[Node3D] = []
var town_lights: MultiMeshInstance3D
var waterfall: MeshInstance3D
var static_meshes: Array[MeshInstance3D] = []


func setup(owner_world: Node3D) -> void:
	world = owner_world
	name = "ConceptSceneAtmosphere"
	rng.seed = 20261018
	for index in range(3):
		var scene := Node3D.new()
		scene.name = ["SunsetSteleCourt", "MoonlitCreek", "SharedLampCourt"][index]
		scene.position.x = index * 20
		add_child(scene)
		scenes.append(scene)
		_horizon(scene, index)
	_misty_court()
	_creek_valley()
	_lamp_court()
	_batch_static()


func _quad(parent: Node3D, at: Vector3, dimensions: Vector2, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.position = at
	node.material_override = material
	parent.add_child(node)
	return node


func _horizon(parent: Node3D, index: int) -> void:
	# One continuous sky removes coplanar chapter panels and hard colour joins.
	if index==0:
		var sky:=ShaderMaterial.new()
		sky.shader=preload("res://shaders/concept_sky.gdshader")
		_quad(parent,Vector3(30,-.8,-24),Vector2(72,22),sky).name="LayeredSky"
	# A single strip per depth layer spans all chapters. Separate coplanar strips
	# used to overlap for six metres at the gates and flicker into horizontal bands.
	for layer in range(4 if index==0 else 0):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var last := Vector3(-6,-3,-21+layer*3)
		for i in range(721):
			var x: float = -6 + i*.10
			var peak: float = .15+sin(x*.31+layer)*.65+sin(x*.87+layer*1.8)*.34+sin(x*2.3+layer)*.15
			peak += sin(x*5.7+layer)*.065+sin(x*13.1)*.026
			peak += (3-layer)*.35
			var point := Vector3(x,peak,-21+layer*3)
			if i > 0:
				for vertex: Vector3 in [last, point, Vector3(last.x,-18,last.z), point, Vector3(x,-18,point.z), Vector3(last.x,-18,last.z)]: st.add_vertex(vertex)
			last = point
		st.generate_normals()
		var ridge := MeshInstance3D.new()
		ridge.name="ContinuousMountainLayer%d"%layer
		ridge.add_to_group("continuous_mountain_ridge")
		ridge.mesh = st.commit()
		var tint: Color = Color(.25,.34,.38).lerp(Color(.065,.14,.17),layer/3.0)
		var haze := ShaderMaterial.new()
		haze.shader = preload("res://shaders/mountain_haze.gdshader")
		haze.set_shader_parameter("tint",tint)
		haze.set_shader_parameter("daylight_tint",Color(.49,.43,.38).lerp(Color(.13,.24,.25),layer/3.0))
		haze.set_shader_parameter("continuous_palette",true)
		ridge.material_override = haze
		parent.add_child(ridge)
	# The downward side camera projects distant geometry upward. Keep the high
	# range inside its framing, rather than filling the sky with a clipped slab.
	if index == 2:
		var back := SurfaceTool.new()
		back.begin(Mesh.PRIMITIVE_TRIANGLES)
		var last_back := Vector3(-3, 5.4, -23)
		for i in range(261):
			var bx: float = -3 + i*.10
			var bpeak: float = 5.55+sin(bx*.39+2.1)*.55+sin(bx*1.47+.6)*.24+sin(bx*5.3)*.07
			var bpoint := Vector3(bx,bpeak,-23)
			if i > 0:
				for vertex: Vector3 in [last_back, bpoint, Vector3(last_back.x,-18,last_back.z), bpoint, Vector3(bx,-18,bpoint.z), Vector3(last_back.x,-18,last_back.z)]: back.add_vertex(vertex)
			last_back = bpoint
		back.generate_normals()
		var back_ridge := MeshInstance3D.new()
		back_ridge.mesh = back.commit()
		var back_haze := ShaderMaterial.new()
		back_haze.shader = preload("res://shaders/mountain_haze.gdshader")
		back_haze.set_shader_parameter("tint", Color(.085,.125,.175))
		back_ridge.material_override = back_haze
		parent.add_child(back_ridge)
	for i in range(3):
		var mist := ShaderMaterial.new()
		mist.shader = preload("res://shaders/mist_ribbon.gdshader")
		mist.set_shader_parameter("strength", .14 if index != 1 else .08)
		_quad(parent,Vector3(10,-.3+i*.8,-11-i*3),Vector2(21,1.2),mist)


func _tree(parent: Node3D, at: Vector3, height: float, tint: Color) -> void:
	var bark: Material = _surface(Color(.20,.16,.115),2)
	var trunk: Vector3 = at + Vector3(-.15,height*.61,0)
	_rod(parent,at,at+Vector3(.07,height*.3,.04),height*.045,bark)
	_rod(parent,at+Vector3(.07,height*.3,.04),trunk,height*.032,bark)
	var ends: Array[Vector3] = []
	for j in range(8):
		var angle: float = j*TAU/8+.3
		var end: Vector3 = at+Vector3(cos(angle)*height*.31,height*(.72+rng.randf()*.16),sin(angle)*height*.20)
		var elbow: Vector3 = trunk.lerp(end,.56)+Vector3(0,.16,0)
		_rod(parent,trunk,elbow,height*.014,bark)
		_rod(parent,elbow,end,height*.007,bark)
		ends.append(end)
	var leaves := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = preload("res://scripts/botanical_detail.gd").leaf_mesh()
	multimesh.instance_count = 520
	for i in range(520):
		var center: Vector3 = ends[i%8]
		var angle: float = rng.randf()*TAU
		var spread: float = sqrt(rng.randf())*height*.19
		var point: Vector3 = center + Vector3(cos(angle)*spread,rng.randf_range(-.16,.25)*height*.45,sin(angle)*spread*.55)
		var scale := Vector3(rng.randf_range(.20,.34),rng.randf_range(.16,.27),rng.randf_range(.18,.29))*height/4
		var basis := Basis.from_euler(Vector3(rng.randf_range(-.4,.4),angle,rng.randf_range(-.3,.3))).scaled(scale)
		multimesh.set_instance_transform(i,Transform3D(basis,point))
		multimesh.set_instance_color(i,tint*rng.randf_range(.70,1.4))
	leaves.multimesh = multimesh
	var foliage := StandardMaterial3D.new()
	foliage.vertex_color_use_as_albedo = true
	foliage.cull_mode=BaseMaterial3D.CULL_DISABLED
	foliage.roughness = .86
	leaves.material_override = foliage
	leaves.name = "BroadleafCanopy"
	leaves.add_to_group("leaf_canopy_detail")
	parent.add_child(leaves)


func _roof_detail(parent: Node3D, center: float, width: float, y: float, z: float, depth: float) -> void:
	var tile: Material = _surface(Color(.18,.25,.27),0)
	var edge: Material = _surface(Color(.29,.32,.28),0)
	var timber: Material = _surface(Color(.28,.16,.08),2)
	var count: int = int(width/.19)
	for i in range(count):
		var x: float = center-width*.5+(i+.5)*width/count
		for row in range(4):
			var t: float = row/4.0
			var t2: float = (row+1)/4.0
			var a := Vector3(x,y-.42+pow(t,1.45)*.42,z+depth*.52*(1-t))
			var b := Vector3(x,y-.42+pow(t2,1.45)*.42,z+depth*.52*(1-t2)+.035)
			_rod(parent,a,b,.045,tile)
		_rod(parent,Vector3(x,y-.43,z+depth*.52),Vector3(x,y-.43,z+depth*.52+.055),.058,edge)
		if i%3==0:
			_box(parent,Vector3(x,y-.66,z+depth*.40),Vector3(.08,.20,.22),timber)
			_box(parent,Vector3(x,y-.76,z+depth*.35),Vector3(.26,.08,.28),timber)
	for side in [-1,1]:
		_rod(parent,Vector3(center+side*width*.5,y,z),Vector3(center+side*(width*.5+.24),y+.19,z),.075,tile)


func _puddle(parent: Node3D, at: Vector3, dimensions: Vector2, warm: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/courtyard_puddle.gdshader")
	material.set_shader_parameter("warm", warm)
	var puddle: MeshInstance3D = _quad(parent,at,dimensions,material)
	puddle.rotation.x = -PI/2


func _growth(parent: Node3D, at: Vector3, length: float) -> void:
	var stems: Material = _flat(Color(.22,.26,.12))
	var leaves: Material = _flat(Color(.19,.29,.14))
	for i in range(6):
		var x: float = at.x + rng.randf_range(-.3,.3)
		var end := Vector3(x,at.y-length*rng.randf_range(.45,1),at.z+.12)
		_rod(parent,Vector3(x,at.y,at.z),end,.008,stems)
		for j in range(5):
			var point: Vector3 = Vector3(x,at.y,at.z).lerp(end,j/5.0)
			for side in [-1,1]:
				preload("res://scripts/botanical_detail.gd").sprig(parent,point,point+Vector3(side*.13,-.07,.045),.04,Color(.19,.29,.14))


func _misty_court() -> void:
	var parent: Node3D = scenes[0]
	_tree(parent,Vector3(1.2,0,-4.2),4.5,Color(.26,.32,.18))
	_tree(parent,Vector3(18.3,0,-4.6),5.2,Color(.20,.29,.19))
	_roof_detail(parent,13.55,6.75,4.48,-2.9,2.3)
	var stone: Material = _surface(Color(.31,.34,.30),0)
	for i in range(23):
		var x: float = .35+i*.34
		_rock(parent,Vector3(x,.10,-2.9),Vector3(.31,rng.randf_range(.15,.31),.28),stone)
	for x in [2.7,6.3,10.7,16.4]: _growth(parent,Vector3(x,2.5 if x<8 else 3.8,-1.95),.8)
	for x in [3.6,6.4,11.2,16.4]: _puddle(parent,Vector3(x,.013,1.65),Vector2(1.7,.57),.65)
	# Sunset rim light balances the cool fog; it does not bleach the inscription.
	var sunset := OmniLight3D.new()
	sunset.position = Vector3(4.5,5,-2)
	sunset.light_color = Color(1,.62,.33)
	sunset.light_energy = 1.15
	sunset.omni_range = 12
	parent.add_child(sunset)


func _creek_valley() -> void:
	var parent: Node3D = scenes[1]
	var cliff: Material = _surface(Color(.23,.31,.34),0)
	for side in [4.5,18.5]:
		preload("res://scripts/layered_cliff.gd").build(parent,Vector3(side,-1.55,-6.6),7.0,7.2,side*.37)
	_tree(parent,Vector3(1.5,0,-4.2),4.8,Color(.16,.27,.24))
	_tree(parent,Vector3(9.9,0,-4.5),4.9,Color(.13,.26,.24))
	_tree(parent,Vector3(19.7,.1,-4.0),4.4,Color(.15,.28,.22))
	var falling := ShaderMaterial.new()
	falling.shader = preload("res://shaders/waterfall.gdshader")
	waterfall = MeshInstance3D.new()
	var stream := SurfaceTool.new()
	stream.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Gravity spreads the falling water: narrow source, broad foot, no parallel-sided sheet.
	for row in range(32):
		for col in range(8):
			for corner in [Vector2(0,0),Vector2(0,1),Vector2(1,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
				var u: float = (col+corner.x)/8.0
				var v: float = (row+corner.y)/32.0
				var width: float = lerpf(.18,1.35,pow(v,1.35))
				stream.set_uv(Vector2(u,v))
				stream.add_vertex(Vector3(-.95*v*v+(u-.5)*width,3.5-v*7,.035*sin(v*14)*v))
	stream.generate_normals()
	waterfall.mesh = stream.commit()
	waterfall.position = Vector3(17.2,1.2,-5.7)
	waterfall.material_override = falling
	waterfall.set_meta("top_width",.18)
	waterfall.set_meta("left_drift",.95)
	waterfall.set_meta("source_gap",Vector3(17.2,4.7,-5.7))
	waterfall.set_meta("bottom_width",1.35)
	parent.add_child(waterfall)
	waterfall.name = "CliffWaterfall"
	# Two asymmetric continuous faces form a fissure, without a lintel or pipe mouth.
	var rock_art=preload("res://scripts/natural_outcrop.gd")
	var wet_stone: Material=rock_art.stone(Color(.27,.36,.39),.12)
	var left: MeshInstance3D=rock_art.make(parent,Vector3(17.2,0,-5.74),PackedVector2Array([Vector2(-2.0,-2.4),Vector2(-.85,-2.4),Vector2(-.75,-.8),Vector2(-.58,1.0),Vector2(-.30,2.85),Vector2(-.12,4.58),Vector2(-.19,4.93),Vector2(-.55,5.24),Vector2(-1.22,5.0),Vector2(-1.46,4.3),Vector2(-1.69,2.2)]),1.4,wet_stone)
	left.name="WaterfallLeftFissure"
	var right: MeshInstance3D=rock_art.make(parent,Vector3(17.2,0,-5.73),PackedVector2Array([Vector2(.20,-2.4),Vector2(2.0,-2.4),Vector2(1.85,1.2),Vector2(1.69,3.68),Vector2(1.10,4.92),Vector2(.54,5.39),Vector2(.17,5.15),Vector2(.11,4.76),Vector2(.22,4.46),Vector2(.06,3.42),Vector2(-.03,2.2)]),1.55,wet_stone)
	right.name="WaterfallRightFissure"
	_quad(parent,Vector3(17.2,4.78,-5.80),Vector2(.25,.36),_flat(Color(.08,.14,.15)))
	var spray := ShaderMaterial.new()
	spray.shader = preload("res://shaders/mist_ribbon.gdshader")
	spray.set_shader_parameter("strength",.26)
	_quad(parent,Vector3(16.25,-1.95,-5.25),Vector2(1.9,.85),spray)
	_puddle(parent,Vector3(8.5,.015,1.4),Vector2(1.9,.55),0)
	_puddle(parent,Vector3(19,.015,1.5),Vector2(1.2,.45),0)
	# Two small old stone piles sit below the deck, never across the traversable lane.
	for x in [12.5,17.6]:
		for row in range(4):
			for col in range(3):
				_rock(parent,Vector3(x+(col-1)*.36,-.45-row*.45,-.75),Vector3(.43,.46,.6),cliff)
	for x in [3.5,7.4,18.7]: _growth(parent,Vector3(x,1.4,-3.0),.9)


func _lamp_court() -> void:
	var parent: Node3D = scenes[2]
	_tree(parent,Vector3(1.7,.1,-3.5),4.1,Color(.24,.32,.17))
	_tree(parent,Vector3(18.8,.1,-3.6),4.6,Color(.23,.30,.16))
	for x in [2.8,5.3,8.0,11.3,14.5,17.4]:
		_puddle(parent,Vector3(x,.026,1.65),Vector2(1.8,.72),1)
	var bronze: Material = _surface(Color(.44,.30,.12),0)
	# Carved balustrade behind the playable path and around the stele platform.
	for x in [7.8,8.35,9.65,10.2]:
		_box(parent,Vector3(x,.48,-1.85),Vector3(.17,.61,.17),bronze)
		_rock(parent,Vector3(x,.83,-1.85),Vector3(.21,.20,.21),bronze)
	for interval in [Vector2(7.8,8.35),Vector2(9.65,10.2)]:
		_rod(parent,Vector3(interval.x,.67,-1.85),Vector3(interval.y,.67,-1.85),.045,bronze)
	_town(parent)
	var warm := OmniLight3D.new()
	warm.position = Vector3(10,3.5,1.7)
	warm.light_color = Color(1,.65,.29)
	warm.light_energy = .55
	warm.omni_range = 12
	parent.add_child(warm)


func _town(parent: Node3D) -> void:
	var tiles: Material = _flat(Color(.15,.23,.28),true)
	var walls: Material = _flat(Color(.27,.29,.28),true)
	var houses: int = 60
	var lamps_per_house: int = 3
	# Short individual footings connect the houses to continuous hillside ranks.
	var footing: Material = _flat(Color(.085,.125,.155),true)
	# Continuous hillside terraces support the ranks of houses. Disconnected short
	# cubes underneath each house alone still made the village look suspended.
	for rank in range(3):
		var terrain:=SurfaceTool.new()
		terrain.begin(Mesh.PRIMITIVE_TRIANGLES)
		var last:=Vector3(1.8,0,-20.8-rank*.55)
		for i in range(169):
			var x: float=1.8+i*.10
			var top: float=5.00+rank*.23+sin(x*.39+2.1)*.3
			top-=pow(maxf(0,2.9-x),2)*.55+pow(maxf(0,x-17.1),2)*.55
			var point:=Vector3(x,top,last.z)
			if i>0:
				for vertex: Vector3 in [last,point,Vector3(last.x,-2,last.z),point,Vector3(x,-2,last.z),Vector3(last.x,-2,last.z)]: terrain.add_vertex(vertex)
			last=point
		terrain.generate_normals()
		var hill:=MeshInstance3D.new()
		hill.mesh=terrain.commit()
		hill.material_override=_flat(Color(.075+rank*.008,.115+rank*.008,.14+rank*.012),true)
		parent.add_child(hill)
	var lamps := MultiMesh.new()
	lamps.transform_format = MultiMesh.TRANSFORM_3D
	lamps.use_colors = true
	var mesh := SphereMesh.new()
	mesh.radius = .022
	mesh.height = .044
	mesh.radial_segments = 6
	mesh.rings = 3
	lamps.mesh = mesh
	lamps.instance_count = houses * lamps_per_house
	for i in range(houses):
		# Three staggered ranks so the skyline is a slope, not a straight line.
		var rank: int = i % 3
		var x: float = rng.randf_range(2.6,17.4)
		var y: float = 5.12 + rank * .23 + sin(x*.39+2.1)*.3 + rng.randf_range(-.03,.05)
		var z: float = -20.6 - rank * .55 + rng.randf_range(-.20,.20)
		var w: float = rng.randf_range(.24,.44)
		_box(parent,Vector3(x,y-.17,z),Vector3(w*1.12,.30,.24),footing)
		_box(parent,Vector3(x,y,z),Vector3(w,.20,.18),walls)
		for side in [-1,1]:
			var roof: MeshInstance3D = _box(parent,Vector3(x+side*w*.23,y+.14,z),Vector3(w*.60,.030,.26),tiles)
			roof.rotation.z = side*-.23
		for j in range(lamps_per_house):
			lamps.set_instance_transform(i*lamps_per_house+j,Transform3D(Basis.IDENTITY,Vector3(x+(j-1)*w*.24,y-.02,z+.12)))
			lamps.set_instance_color(i*lamps_per_house+j,Color(1,rng.randf_range(.68,.91),.50))
	town_lights = MultiMeshInstance3D.new()
	town_lights.name = "ValleyTownLights"
	town_lights.multimesh = lamps
	var window_light:=_flat(Color(.94,.65,.30),true,true).duplicate() as StandardMaterial3D
	window_light.vertex_color_use_as_albedo=true
	window_light.emission_energy_multiplier=.75
	town_lights.material_override=window_light
	parent.add_child(town_lights)


func _batch_static() -> void:
	# Merge repeated stone/timber/tile meshes per material to keep native scenery inexpensive.
	var groups: Dictionary = {}
	var nodes: Array[Node] = find_children("*","MeshInstance3D",true,false)
	for node: MeshInstance3D in nodes:
		if node.material_override is ShaderMaterial and node.material_override.shader != SURFACE: continue
		var material: Material = node.material_override
		if not groups.has(material): groups[material] = []
		groups[material].append(node)
	for material: Material in groups:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var centroid := Vector3.ZERO
		var count: int = 0
		for node: MeshInstance3D in groups[material]:
			st.append_from(node.mesh,0,global_transform.affine_inverse()*node.global_transform)
			centroid += node.global_position
			count += 1
			node.get_parent().remove_child(node)
			node.free()
		var batch := MeshInstance3D.new()
		batch.mesh = st.commit()
		batch.material_override = material
		# A merged batch sits at the origin, so the node position no longer says
		# where the geometry is. Keep the authored centroid and part count as
		# metadata; editors can jump back to the group without re-deriving it.
		batch.name = _batch_name(material, count)
		batch.set_meta("authored_centroid", centroid / maxf(1.0, count))
		batch.set_meta("merged_parts", count)
		add_child(batch)
		static_meshes.append(batch)


func _batch_name(material: Material, count: int) -> String:
	var kind: String = "Surface"
	if material is ShaderMaterial:
		match material.shader.resource_path.get_file():
			"weathered_surface.gdshader": kind = "Weathered"
			"courtyard_stone.gdshader": kind = "CourtyardStone"
			"courtyard_puddle.gdshader": kind = "Puddle"
			"mist_ribbon.gdshader": kind = "Mist"
			"waterfall.gdshader": kind = "Waterfall"
			"mountain_haze.gdshader": kind = "Ridge"
			"concept_sky.gdshader": kind = "Sky"
	else:
		var c: Color = material.albedo_color if material is StandardMaterial3D else Color.WHITE
		kind = "Solid_%02x%02x%02x" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]
	return "Batch_%s_%d" % [kind, count]
