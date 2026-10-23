extends "res://scripts/environment_art.gd"

const Props = preload("res://scripts/chapter_props.gd")

var chapter: Node3D

var stone: ShaderMaterial
var wood: ShaderMaterial
var earth: ShaderMaterial
var rope_material: StandardMaterial3D
var fir_crown: Node3D
var route: Node3D
var pier_stones: Node3D
var repair_pier: Node3D
var repair_blocks: Array[MeshInstance3D]=[]
var rope_supply: Node3D
var safety_rope: Array[MeshInstance3D] = []
var stage_labels: Array[Label3D] = []
var flames: Array[MeshInstance3D] = []
var torch_lights: Array[OmniLight3D] = []
var bridge_planks: Array[MeshInstance3D] = []
var rescue_rings: Array[MeshInstance3D] = []
var handoff_label: Label3D
var approach_rails: Node3D



func setup(owner_chapter: Node3D) -> void:
	chapter = owner_chapter
	name = "CreekLandscape"
	rng.seed = 405458
	stone = _surface(Color(0.25, 0.31, 0.32), 0.0)
	wood = _surface(Color(0.28, 0.19, 0.105), 2.0)
	earth = _surface(Color(0.19, 0.23, 0.21), 0.0)
	rope_material = _flat(Color(0.57, 0.43, 0.25))
	var space: Node3D = chapter.get_parent()
	for path in ["Floor/Mesh", "RightBank/Mesh", "BackWall", "PillarA", "PillarB"]:
		space.get_node(path).visible = false
	space.get_node("MiddleLight").light_color = Color(0.36, 0.52, 0.72)
	space.get_node("MiddleLight").light_energy = 0.55
	for path in ["Creek", "SupplyDock", "MaterialCrate/Mesh", "MaterialCrate/BandA", "MaterialCrate/BandB"]:
		chapter.get_node(path).visible = false
	chapter.get_node("MaterialCrate/Caption").visible = false
	for child in chapter.get_node("BridgeAssembly").get_children():
		child.visible = false
	_build_horizon()
	_build_banks()
	_build_water()
	_build_story_places()
	_build_bridge()
	_build_transport()
	_build_exit()
	for at in [Vector3(0.9, 0, -1.4), Vector3(5.7, 0, -1.7), Vector3(10.8, 0, -1.5), Vector3(18.7, 0, -1.5)]:
		_torch(at)
	sync_state()


func _build_horizon() -> void:
	for index in range(3):
		var fog := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(25, 2.1)
		fog.mesh = quad
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/mist_ribbon.gdshader")
		material.set_shader_parameter("strength", 0.13)
		fog.material_override = material
		fog.position = Vector3(10, 0.4 + index * 1.6, -4.8 - index * 2.0)
		add_child(fog)


func _build_banks() -> void:
	for section in [[-0.5, 12.0], [18.0, 21.0]]:
		var length: float = section[1] - section[0]
		_box(self, Vector3((section[0] + section[1]) * 0.5, -1.7, 0), Vector3(length, 3.3, 5.0), earth)
		for index in range(int(length / 1.3) + 1):
			var x: float = section[0] + 0.5 + index * 1.3
			for row in range(3):
				var slab: MeshInstance3D = _rock(self, Vector3(x, -0.075, -0.9 + row * 0.9), Vector3(1.3, 0.13, 0.78), stone)
				slab.rotation.y = rng.randf_range(-0.09, 0.09)
	for section in [[-.5,12.0,1],[18.0,21.0,-1]]:
		var bank := preload("res://scripts/layered_bank.gd").new()
		add_child(bank)
		bank.setup(section[0],section[1],-.10,-3.85,2.66,Color(.26,.32,.33),section[2])
	# Rear bank rocks step back instead of forming one wall across the lane. On the
	# west bank they also stay off the east-facing edge, which is what the 2.5D
	# camera used to be blocked by. Meridian (x 11.4-18.4) keeps the deep gorge.
	for index in range(17):
		var x: float = rng.randf_range(-0.2, 21)
		var tier: int = index % 3
		var z: float = [-1.35, -2.35, -3.35][tier] + rng.randf_range(-0.18, 0.18)
		var in_channel: bool = x > 11.4 and x < 18.4
		if not in_channel and x < 11.4:
			x = maxf(x, 0.8)
		var tall: float = [2.0, 2.7, 3.2][tier]
		if in_channel:
			var rock_art=preload("res://scripts/natural_outcrop.gd")
			var width: float=rng.randf_range(1.4,2.6)
			var outline:=PackedVector2Array([Vector2(-width*.47,-1.55),Vector2(width*.39,-1.5),Vector2(width*.53,-.67),Vector2(width*.44,.47),Vector2(width*.15,.81),Vector2(-width*.27,.70),Vector2(-width*.53,.32),Vector2(-width*.57,-.73)])
			rock_art.make(self,Vector3(x,-1.5,z+.5),outline,1.35,stone).name="WaterWornChannelBoulder"
		else:
			_rock(self,Vector3(x,-.9+tier*.30,z),Vector3(rng.randf_range(1.4,2.8),tall,1.5),stone)
	for index in range(32):
		var x: float = rng.randf_range(-0.1, 20.5)
		if x > 11.4 and x < 18.3: continue
		var z: float = 2.8 if index % 2 == 0 else -2.5
		_reeds(Vector3(x, -0.1, z))


func _reeds(at: Vector3) -> void:
	for index in range(4):
		var offset := Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.12, 0.12))
		_rod(self, at + offset, at + offset + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.25, 0.68), 0), 0.012, _flat(Color(0.16, 0.24, 0.18)))


func _build_water() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6.7, 24)
	plane.subdivide_width = 16
	plane.subdivide_depth = 30
	water.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/creek_water.gdshader")
	water.material_override = material
	# Settle the channel one metre below the old surface. The visible walkway and
	# the bridge base (y 0.72) are not modelled here, so the gorge deepens without
	# touching the lane, the deck or the player's floor height.
	water.position = Vector3(15, -3.25, -2.0)
	add_child(water)
	var rock_centers := PackedVector2Array()
	for index in range(12):
		var z: float = rng.randf_range(-8, 7)
		var x: float = rng.randf_range(12.5, 17.7)
		rock_centers.append(Vector2(x + chapter.global_position.x, z))
		_rock(self, Vector3(x, -3.22, z), Vector3(0.65, rng.randf_range(0.4, 0.85), 1.0), stone)
	material.set_shader_parameter("rock_centers", rock_centers)
	# Fragments belong to the washed-out old bridge, outside the playable lane.
	for index in range(6):
		var fragment: MeshInstance3D = _rock(self, Vector3(12.3 + index * 0.9, -2.75, -2.4), Vector3(0.9, 0.65, 0.7), stone)
		fragment.rotation.z = rng.randf_range(-0.6, 0.6)
	for side in [11.8, 18.2]:
		for level in range(4):
			_box(self, Vector3(side, -0.5 - level * 0.5, -1.75), Vector3(0.65, 0.42, 0.85), stone)
		_rod(self, Vector3(side, -0.1, -1.7), Vector3(side + (0.8 if side < 15 else -0.8), -0.65, -1.7), 0.10, wood)
	for index in range(2):
		var spray := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(7.3, 1.6)
		spray.mesh = quad
		var mist := ShaderMaterial.new()
		mist.shader = preload("res://shaders/mist_ribbon.gdshader")
		mist.set_shader_parameter("strength", 0.15)
		spray.material_override = mist
		spray.position = Vector3(15, -2.30 - index * 0.80, 2.7 + index * 1.1)
		add_child(spray)


func _build_story_places() -> void:
	# Flood line and broken masonry are the route-finding evidence.
	var masonry:=Node3D.new()
	masonry.name="BrokenOldBridgeAbutment"
	add_child(masonry)
	var cut_stone: Material=preload("res://scripts/natural_outcrop.gd").stone(Color(.43,.46,.40),.35)
	for row in range(3):
		var widths: Array=[.63,.50,.72] if row%2==0 else [.42,.74,.54]
		var edge: float=1.55+row*.07
		for col in range(3 if row<2 else 2):
			var width: float=widths[col]
			var block: MeshInstance3D=_pier_block(masonry,Vector3(edge+width*.5,.10+row*.27,-1.80+row*.04),Vector3(width-.025,.26,.72-row*.08),cut_stone)
			block.rotation.z=(col-1)*.018
			edge+=width
	_pier_block(masonry,Vector3(2.17,.84,-1.73),Vector3(1.18,.17,.79),cut_stone).rotation.z=.04
	for i in range(5):
		var rubble: MeshInstance3D=_rock(masonry,Vector3(2.85+i*.16,.07,-1.2+sin(i)*.18),Vector3(.23,.12,.21),cut_stone)
		rubble.rotation.y=i*.8
	# A broken silt line runs over individual stones rather than floating in air.
	for i in range(7):
		_box(masonry,Vector3(1.64+i*.22,.39+sin(i*1.7)*.012,-1.405),Vector3(.18,.021,.006),_flat(Color(.48,.46,.34)))
	_rod(self, Vector3(0.5, 0, -1.4), Vector3(0.5, 2.4, -1.4), 0.07, wood)
	preload("res://scripts/world_signs.gd").plaque(self, Vector3(0.6, 2.0, -1.35), "杨旗田", Vector2(1.5, 0.50), -1)
	# The source is a flood-felled fir; preparing it means cutting and binding usable lengths.
	fir_crown = Node3D.new()
	add_child(fir_crown)
	_rod(fir_crown, Vector3(3.2, 0.5, -1.6), Vector3(5.3, 0.7, -2.5), 0.24, wood)
	for index in range(5):
		_rod(fir_crown, Vector3(4.2, 0.6, -2.0), Vector3(4.0 + index * 0.3, 1.4, -2.5 - index * 0.18), 0.045, wood)
	for index in range(5):
		var z: float=-.25+(index%3)*.25 if index<3 else -.125+(index-3)*.25
		var y: float=-.18 if index<3 else .04
		var radius: float=.14 if index<3 else .125
		var log_mesh: MeshInstance3D=_rod(chapter.crate,Vector3(-.49-index*.012,y,z),Vector3(.46-index*.018,y+.012,z),radius,_flat(Color(.29+index*.015,.20+index*.01,.12)))
		(log_mesh.mesh as CylinderMesh).radial_segments=22
		for end in [-1,1]:
			var x: float=-.505-index*.012 if end<0 else .475-index*.018
			var disk: MeshInstance3D=_rod(chapter.crate,Vector3(x,y,z),Vector3(x+end*.009,y,z),radius*.90,_flat(Color(.59,.45,.28)))
			(disk.mesh as CylinderMesh).radial_segments=22
			for ring in range(1,4):
				var torus:=TorusMesh.new()
				torus.inner_radius=radius*(ring*.21)-.002
				torus.outer_radius=torus.inner_radius+.004
				torus.rings=28
				torus.ring_segments=5
				var grain:=MeshInstance3D.new()
				grain.mesh=torus
				grain.material_override=_flat(Color(.40,.29,.17))
				grain.position=Vector3(x+end*.012,y,z)
				grain.rotation.z=PI/2
				chapter.crate.add_child(grain)
		for seam in range(9):
			var a: float=seam*TAU/9
			_rod(chapter.crate,Vector3(-.44,y+cos(a)*radius,z+sin(a)*radius),Vector3(.41,y+.014+cos(a+.05)*radius,z+sin(a+.05)*radius),.005,_flat(Color(.21,.15,.095)))
	for x in [-0.33, 0.33]:
		_box(chapter.crate, Vector3(x, -.36, 0), Vector3(.14,.13,.91), wood)
		for segment in range(28):
			var a: float=segment*TAU/28
			var b: float=(segment+1)*TAU/28
			_rod(chapter.crate,Vector3(x,-.10+cos(a)*.29,sin(a)*.43),Vector3(x,-.10+cos(b)*.29,sin(b)*.43),.016,rope_material)
		_rod(chapter.crate,Vector3(x,.19,-.08),Vector3(x+.08,.22,.03),.023,rope_material)
	# Abstract notches indicate a fictional route; no fabricated historical inscription is used.
	route = Node3D.new()
	add_child(route)
	# The recessed marking belongs to CraftAndTrailDetails' rock surface. Keep
	# this state anchor, without a second rock or bright rods crossing the carving.
	pier_stones = Node3D.new()
	add_child(pier_stones)
	for side in [12.0, 18.0]:
		for level in range(4):
			for row in range(2):
				_rock(pier_stones, Vector3(side, -0.3 - level * 0.48, -0.8 + row * 1.4), Vector3(0.9, 0.50, 1.1), stone)
	# The repair target at local x10.5 must exist before it can be strengthened.
	# This shoulder sits behind the walk lane, with no new physical step to climb.
	repair_pier=Node3D.new()
	repair_pier.name="RepairableBridgeheadPier"
	repair_pier.position=Vector3(10.5,0,-.95)
	add_child(repair_pier)
	var ashlar: Material=_surface(Color(.46,.45,.39),0)
	var cap_stone: Material=_surface(Color(.54,.51,.43),0)
	_pier_block(repair_pier,Vector3(0,.02,0),Vector3(1.92,.20,1.26),ashlar)
	_pier_block(repair_pier,Vector3(0,.15,0),Vector3(1.64,.16,1.08),cap_stone)
	_box(repair_pier,Vector3(0,.72,0),Vector3(1.33,1.02,.79),_flat(Color(.17,.19,.18)))
	for row in range(3):
		for col in range(2):
			# The bond alternates: the centre joint steps sideways every course.
			var widths: Array=[.53,.87] if row%2 else [.84,.56]
			var x: float=-.71+widths[0]*.5 if col==0 else .71-widths[1]*.5
			var target:=Vector3(x,.39+row*.34,0)
			var block: MeshInstance3D=_pier_block(repair_pier,target,Vector3(widths[col],.32,.91),ashlar)
			block.rotation=Vector3.ZERO
			var loose: Vector3=target+Vector3((-.045 if col==0 else .06)*row,-row*.035,.035*(row%2))
			block.set_meta("loose_position",loose)
			block.set_meta("fixed_position",target)
			block.set_meta("loose_angle",(-.025 if col==0 else .035)*row)
			repair_blocks.append(block)
	var cap: MeshInstance3D=_pier_block(repair_pier,Vector3(0,1.30,0),Vector3(1.78,.25,1.16),cap_stone)
	cap.set_meta("loose_position",Vector3(.10,1.24,.03))
	cap.set_meta("fixed_position",Vector3(0,1.30,0))
	cap.set_meta("loose_angle",.14)
	repair_blocks.append(cap)
	# A wooden saddle and tenon make the pier's bridge-bearing purpose legible.
	_box(repair_pier,Vector3(0,1.48,-.13),Vector3(1.40,.13,.29),wood)
	for x in [-.55,.55]:
		_box(repair_pier,Vector3(x,1.52,-.13),Vector3(.16,.23,.38),wood)
	# Continuous cut-stone toe, visible on the gorge face below the deck.
	for row in range(5):
		for col in range(2):
			_pier_block(self,Vector3(11.38+(col-.5)*.70,-.35-row*.43,2.80),Vector3(.68,.41,.50),ashlar)
	_pier_block(self,Vector3(11.38,-.08,2.80),Vector3(1.64,.17,.65),cap_stone)
	rope_supply = Node3D.new()
	add_child(rope_supply)
	for index in range(4):
		var coil := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.16
		torus.outer_radius = 0.22
		torus.rings = 12
		torus.ring_segments = 6
		coil.mesh = torus
		coil.material_override = rope_material
		coil.position = Vector3(9.5, 0.10 + index * 0.06, -1.65)
		rope_supply.add_child(coil)
	var stops: Array[Vector3] = [Vector3(2.5, 1.7, -1), Vector3(4, 1.8, -1), Vector3(7, 3.18, -1.0), Vector3(10.5, 2.1, -0.7), Vector3(15, 2.7, -0.8), Vector3(18.45, 2.4, -0.6)]
	for index in range(stops.size()):
		var text: String = ["旧桥基 · 察看水痕", "杉木 · 截料捆扎", "岩壁 · 辨认旧路", "桥头 · 砌墩架桥", "桥中 · 顶稳碑角", "右岸 · 握绳牵引"][index]
		var label: Label3D = Props.label(self, stops[index], text)
		label.font_size = preload("res://scripts/interface_skin.gd").text_size(36)
		label.pixel_size = 0.007
		if index==2: label.no_depth_test=true
		stage_labels.append(label)
	handoff_label = Props.label(self, Vector3(19.6, 1.9, -.5), "右岸交接 · 一同送碑入院")
	handoff_label.font_size = preload("res://scripts/interface_skin.gd").text_size(28)
	handoff_label.pixel_size = .006


func _pier_block(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	mesh.mesh=preload("res://scripts/dressed_stone.gd").block(dimensions)
	mesh.position=at
	mesh.material_override=material
	parent.add_child(mesh)
	return mesh


func _build_bridge() -> void:
	var assembly: Node3D = chapter.get_node("BridgeAssembly")
	approach_rails = Node3D.new()
	add_child(approach_rails)
	for end in [12.0,18.0]:
		var outside: float = end + (-.9 if end < 15 else .9)
		for side in [-1,1]:
			_rod(approach_rails,Vector3(outside,0,side*1.9),Vector3(outside,.8,side*1.9),.045,wood)
			for y in [.38,.70]:
				_rod(approach_rails,Vector3(outside,y,side*1.9),Vector3(end,y,side*1.03),.025,rope_material)
	for z in [-0.76, 0.76]:
		_rod(assembly, Vector3(0, -0.26, z), Vector3(6, -0.26, z), 0.14, wood)
	for index in range(23):
		var plank: MeshInstance3D = _box(assembly, Vector3(0.05 + index * 0.27, -0.13, 0), Vector3(0.25, 0.16, 2.05), wood)
		plank.rotation.y = rng.randf_range(-0.035, 0.035)
		bridge_planks.append(plank)
	for side in [-1.03, 1.03]:
		for x in [0.0, 1.5, 3.0, 4.5, 6.0]:
			_rod(assembly, Vector3(x, -0.2, side), Vector3(x, 0.75, side), 0.045, wood)
		for index in range(16):
			var x: float = index * 0.375
			var end: float = x + 0.375
			_rod(assembly, Vector3(x, 0.70 - sin(x * PI / 1.5) * 0.07, side), Vector3(end, 0.70 - sin(end * PI / 1.5) * 0.07, side), 0.025, rope_material)
	for index in range(12):
		safety_rope.append(_rod(self, Vector3(15, 1.3, 0), Vector3(18.5, 1.0, -0.6), 0.024, rope_material))
	_rod(self, Vector3(18.5, 0, -0.65), Vector3(18.5, 1.3, -0.65), 0.09, wood)
	for x in [15.0, 18.4]:
		var marker := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = .26
		ring.outer_radius = .31
		ring.rings = 32
		ring.ring_segments = 8
		marker.mesh = ring
		marker.position = Vector3(x, .035, 0)
		marker.scale.y = .12
		marker.material_override = _flat(Color(.93, .72, .34), true)
		add_child(marker)
		rescue_rings.append(marker)


func _build_transport() -> void:
	var litter := preload("res://scripts/tablet_transport_art.gd").new()
	chapter._tablet.add_child(litter)
	litter.setup(chapter)


func _build_exit() -> void:
	var wall: Material = _surface(Color(0.26, 0.29, 0.25), 1.0)
	# The gate's return wall covers the bare courtyard edge and joins the two spaces.
	_box(self, Vector3(23.1, 2.8, -3.05), Vector3(7.9, 5.8, 0.35), wall)
	for x in [22.4, 25.6]:
		_box(self, Vector3(x, 2.7, -2.8), Vector3(0.32, 5.5, 0.35), stone)
	_box(self, Vector3(23.1, 5.55, -2.9), Vector3(8.2, 0.24, 0.65), _flat(Color(0.09, 0.15, 0.16)))
	var courtyard: Node3D = chapter.get_node("../../Space03")
	courtyard.get_node("Floor/Mesh").material_override = earth
	courtyard.get_node("BackWall").material_override = wall
	for x in [19.2, 21.9]:
		_box(self, Vector3(x, 1.6, -2.6), Vector3(0.9, 3.3, 0.7), wall)
	_box(self, Vector3(20.55, 3.25, -2.6), Vector3(3.7, 0.45, 0.9), wall)
	var gate_roof := preload("res://scripts/curved_tile_roof.gd").new()
	add_child(gate_roof)
	gate_roof.position=Vector3(20.55,4.10,-2.6)
	gate_roof.setup(4.4,2.5,Color(.18,.25,.26))
	gate_roof.name="CityGateTiledRoof"
	gate_roof.add_to_group("city_gate_roof")
	var framing: Array=[]
	var braces: Array=[]
	for z in [-3.40,-1.80]:
		framing.append([Vector3(3.75,.14,.16),Transform3D(Basis.IDENTITY,Vector3(20.55,3.49,z))])
		for x in [19.2,21.9]:
			for tier in range(3):
				framing.append([Vector3(.30+tier*.18,.09,.29),Transform3D(Basis.IDENTITY,Vector3(x,3.27+tier*.11,z))])
			for side in [-1,1]:
				braces.append([Vector3(x,3.13,z),Vector3(x+side*.39,3.51,z),.032])
	for x in [19.2,21.9]:
		framing.append([Vector3(.13,.15,1.94),Transform3D(Basis.IDENTITY,Vector3(x,3.51,-2.6))])
	_boxes_merged(gate_roof,wood,framing.map(func(part):
		part[1].origin-=gate_roof.position
		return part)).name="GateBearingBeamsAndBrackets"
	for part in braces:
		part[0]-=gate_roof.position
		part[1]-=gate_roof.position
	_rods_merged(gate_roof,wood,braces).name="GateDiagonalTimberBraces"
	preload("res://scripts/world_signs.gd").plaque(self, Vector3(20.55, 2.9, -2.1), "往城中", Vector2(1.75, 0.53), 1)
	for x in [19.5, 21.6]:
		_box(self, Vector3(x, 2.1, -1.85), Vector3(0.26, 0.45, 0.26), _flat(Color(0.95, 0.57, 0.22), true, true))
		var glow := OmniLight3D.new()
		glow.position = Vector3(x, 2, -0.6)
		glow.light_color = Color(1, 0.63, 0.29)
		glow.light_energy = 1.4
		glow.omni_range = 5
		add_child(glow)


func _torch(at: Vector3) -> void:
	_rod(self, at, at + Vector3(0, 1.7, 0), 0.045, wood)
	_box(self, at + Vector3(0, 1.58, 0), Vector3(0.16, 0.15, 0.16), _flat(Color(0.13, 0.12, 0.10)))
	var flame: MeshInstance3D = _flame(self, 0.12, 0.40)
	flame.material_override = _flat(Color(1.0, 0.55, 0.15), true, true)
	flame.position = at + Vector3(0, 1.87, 0)
	flames.append(flame)
	var glow := OmniLight3D.new()
	glow.position = at + Vector3(0, 1.9, 0.7)
	glow.light_color = Color(1.0, 0.62, 0.30)
	glow.light_energy = 1.1
	glow.omni_range = 4.8
	add_child(glow)
	torch_lights.append(glow)


func sync_state() -> void:
	if chapter == null or stage_labels.is_empty(): return
	approach_rails.visible = chapter.bridge_ready
	handoff_label.visible = chapter.gap_stabilized and not chapter.tablet_delivered
	fir_crown.scale.y = 0.55 if chapter.timber_prepared else 1.0
	route.visible = chapter.step >= 1
	pier_stones.visible = true
	rope_supply.visible = chapter.helpers_called
	var active: Array = []
	match chapter.step:
		0: active = [0]
		1: active = [1, 2] if not chapter.timber_prepared else [2]
		2: active = [1] if not chapter.timber_prepared else [3]
		3: active = [0]
		4: active = [3]
		5: active = [4, 5]
	stage_labels[0].text = "村口岔道 · 联络帮手" if chapter.step == 3 else "旧桥基 · 察看水痕"
	stage_labels[3].text="桥头石墩 · 筑牢后架桥" if chapter.step<3 else "桥头石墩 · 已筑牢"
	for index in range(stage_labels.size()):
		stage_labels[index].visible = index in active
		stage_labels[index].modulate = Color(1.0, 0.82, 0.51)
	if chapter.step == 5:
		stage_labels[5].text="右岸 · 收放绳索"
		stage_labels[4].modulate = Color(0.60, 0.90, 0.69) if chapter.steady_held else Color(1, 0.82, 0.51)
		stage_labels[5].modulate = Color(0.60, 0.90, 0.69) if chapter.tension_safe and chapter.rope_at_post else Color(1, 0.82, 0.51)
	for node in safety_rope:
		node.visible = chapter._tablet.visible
	for index in range(rescue_rings.size()):
		rescue_rings[index].visible = chapter.step == 5
		var held: bool = chapter.steady_held if index == 0 else chapter.tension_safe and chapter.rope_at_post
		rescue_rings[index].material_override = _flat(Color(.48, .88, .67) if held else Color(.93, .72, .34), true)


func _process(_delta: float) -> void:
	if chapter == null: return
	var mortar: float=1.0 if chapter.step>=3 else clampf(chapter.action_progress/1.6,0,1) if chapter.step==2 and chapter.material_delivered else 0.0
	for block in repair_blocks:
		block.position=(block.get_meta("loose_position") as Vector3).lerp(block.get_meta("fixed_position"),smoothstep(0,1,mortar))
		block.rotation.z=lerpf(float(block.get_meta("loose_angle")),0,mortar)
	var seconds: float = Time.get_ticks_msec() * 0.001
	for index in range(flames.size()):
		var wave: float = sin(seconds * 8.1 + index * 2.0) * 0.07 + sin(seconds * 14.0 + index) * 0.035
		flames[index].scale = Vector3(1.0 - wave, 1.0 + wave * 1.8, 1)
		torch_lights[index].light_energy = 1.1 + wave
	if chapter.bridge_ready and not chapter.gap_stabilized:
		var start: Vector3 = chapter._tablet.transform * Vector3(.84, -.25, -.48)
		var end := Vector3(18.5, 1.0, -0.65)
		for index in range(safety_rope.size()):
			var a: float = float(index) / safety_rope.size()
			var b: float = float(index + 1) / safety_rope.size()
			var sag: float = lerpf(.34, .035, chapter.rope_tension)
			_place_rod(safety_rope[index], start.lerp(end, a) - Vector3(0, sin(a * PI) * sag, 0), start.lerp(end, b) - Vector3(0, sin(b * PI) * sag, 0))
	elif chapter._tablet.visible:
		# The same safety line travels with the litter after the rescue.
		var start: Vector3 = chapter._tablet.transform * Vector3(.84, -.25, -.48)
		var end: Vector3 = chapter._tablet.transform * Vector3(1.58, -.32, -.46)
		for index in range(safety_rope.size()):
			_place_rod(safety_rope[index], start.lerp(end, float(index) / safety_rope.size()), start.lerp(end, float(index + 1) / safety_rope.size()))
	for plank in bridge_planks:
		var distance: float = absf(plank.global_position.x - chapter._tablet.global_position.x)
		plank.position.y = -.13 - (.018 * exp(-distance * distance * 2) if chapter._tablet.visible else 0)

