extends "res://scripts/environment_art.gd"

var world: Node3D
var sky_lanterns: Array[Node3D] = []
var lantern_origins: Array[Vector3] = []
var warm_materials: Array[StandardMaterial3D] = []
var celebration: MultiMeshInstance3D
var clock: float = 0
const FIREWORK_COLORS: Array[Color]=[Color(1,.32,.22),Color(1,.77,.24),Color(.32,.91,.70),Color(.36,.66,1),Color(.77,.48,1),Color(1,.48,.73)]


func setup(owner_world: Node3D) -> void:
	world = owner_world
	name = "GrandCourtSkyline"
	rng.seed = 4051778
	var stone: Material = _surface(Color(.31, .32, .26), 0)
	var red: Material = _surface(Color(.27, .09, .055), 2)
	var roof: Material = _flat(Color(.10, .19, .20))
	var gold: Material = _flat(Color(.65, .43, .17))
	var warm: Material = _flat(Color(.85, .45, .13), true, true)
	# Successive roof lines and blue mountain silhouettes give the court depth.
	for side in [-1, 1]:
		var x: float = 50 + side * 9.0
		for tier in range(3):
			var y: float = 2.9 + tier * 1.35
			var width: float = 3.7 - tier * .55
			_box(self, Vector3(x, y, -7.8), Vector3(width * .75, 1.2, 1.6), stone)
			_roof(Vector3(x, y + .75, -7.8), width, 2.6, roof, gold)
			for column in range(5): _box(self, Vector3(x - width * .25 + column * width * .125, y + .12, -6.97), Vector3(.12, .44, .025), warm)
	# Tall timber gate spans the original pavilion without changing its walkway.
	for x in [44.4, 55.6]:
		_box(self, Vector3(x, .35, -6.0), Vector3(.85, .70, .90), stone)
		_rod(self, Vector3(x, .65, -6), Vector3(x, 6.45, -6), .18, red)
		for y in [1.0, 5.5, 6.1]: _box(self, Vector3(x, y, -6), Vector3(.57, .15, .58), gold)
	for y in [5.85, 6.26]: _box(self, Vector3(50, y, -6), Vector3(12.1, .18, .42), red)
	for i in range(39):
		var x: float = 44.45 + i * .29
		var brace := _box(self, Vector3(x, 6.04, -5.76), Vector3(.035, .34, .035), gold)
		brace.rotation.z = .65 if i % 2 else -.65
	_roof(Vector3(50, 6.7, -6), 13.6, 2.5, roof, gold)
	preload("res://scripts/world_signs.gd").plaque(self, Vector3(50, 5.95, -4.2), "同源异彩", Vector2(4.4, .84))
	for i in range(7):
		var x: float = 43.2 + i * 2.25
		var cloth: MeshInstance3D = world.scene_details._cloth(self, Vector3(x, 4.95, -5.4), Vector2(.62, 1.35), i % 3)
		cloth.add_to_group("shared_court_cloths")
		cloth.set_meta("cloth_index",i)
		_rod(self, Vector3(x - .4, 5.67, -5.4), Vector3(x + .4, 5.67, -5.4), .022, gold)
	# Four local groups hang below the high gate beam and tower eaves.
	# These replace the unsupported row floating over all roof ridges.
	var bays: Array = [
		["GateLeft",Vector3(44.65,6.26,-5.72),Vector3(46.65,6.26,-5.72)],
		["GateRight",Vector3(53.35,6.26,-5.72),Vector3(55.35,6.26,-5.72)],
		["TowerLeft",Vector3(40.35,5.83,-6.43),Vector3(41.65,5.83,-6.43)],
		["TowerRight",Vector3(58.35,5.83,-6.43),Vector3(59.65,5.83,-6.43)]
	]
	for bay_data in bays:
		var bay := Node3D.new()
		bay.name="RoundLanternBay"+bay_data[0]
		bay.set_meta("beam_start",bay_data[1])
		bay.set_meta("beam_end",bay_data[2])
		bay.set_meta("lantern_count",2)
		bay.add_to_group("eave_lantern_bays")
		add_child(bay)
		for index in range(2):
			var anchor: Vector3 = bay_data[1].lerp(bay_data[2],(index+.5)/2.0)
			var origin: Vector3 = anchor-Vector3(0,.44,0)
			_hanging_round_lantern(bay,origin,anchor,index,gold,red)
	for side in [-1, 1]:
		for index in range(10):
			var x: float = 40.6 + index * 2.05
			_box(self, Vector3(x, .065, side * 1.3 + .9), Vector3(.16, .025, .22), gold)
	_build_celebration()


func _hanging_round_lantern(bay: Node3D, origin: Vector3, anchor: Vector3, index: int, gold: Material, red: Material) -> void:
	var lantern := Node3D.new()
	lantern.position = origin
	lantern.scale=Vector3.ONE*.74
	bay.add_child(lantern)
	sky_lanterns.append(lantern)
	lantern_origins.append(origin)
	var shell := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .27
	sphere.height = .68
	sphere.radial_segments = 20
	sphere.rings = 12
	shell.mesh = sphere
	var shade := StandardMaterial3D.new()
	shade.albedo_color = Color(.76, .25, .085) if index % 3 else Color(.89, .59, .22)
	shade.emission_enabled = true
	shade.emission = Color(1, .43, .09)
	shade.roughness = .9
	warm_materials.append(shade)
	shell.material_override = shade
	lantern.add_child(shell)
	for y in [-.29, .29]: _box(lantern, Vector3(0, y, 0), Vector3(.35, .035, .30), gold)
	for angle in range(12):
		for segment in range(9):
			var a: float = -.95 + segment * 1.9 / 9
			var b: float = -.95 + (segment + 1) * 1.9 / 9
			var phase: float = angle * TAU / 12
			_rod(lantern, Vector3(cos(phase) * cos(a) * .273, sin(a) * .34, sin(phase) * cos(a) * .273), Vector3(cos(phase) * cos(b) * .273, sin(b) * .34, sin(phase) * cos(b) * .273), .0035, gold)
	_rod(lantern, Vector3(0, -.3, 0), Vector3(0, -.57, 0), .012, red)
	_rod(bay, origin + Vector3(0, .29*.74, 0), anchor, .007, gold)
	_rod(bay,anchor,anchor+Vector3(0,.07,-.06),.015,gold)


func _roof(at: Vector3, width: float, depth: float, _roof: Material, _gold: Material) -> void:
	var tiled := preload("res://scripts/curved_tile_roof.gd").new()
	add_child(tiled)
	tiled.position=at
	tiled.setup(width,depth,Color(.16,.24,.26))


func _build_celebration() -> void:
	celebration = MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.instance_count = 240
	var mesh := SphereMesh.new()
	mesh.radius = .028
	mesh.height = .056
	mesh.radial_segments = 5
	mesh.rings = 3
	multi.mesh = mesh
	celebration.multimesh = multi
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/festival_spark.gdshader")
	celebration.material_override = material
	add_child(celebration)
	celebration.visible = false


func _process(delta: float) -> void:
	if world == null: return
	clock += delta
	var warmth: float = world.courtyard.lamp_count / 7.0
	for index in range(sky_lanterns.size()):
		sky_lanterns[index].rotation.z = sin(clock * .55 + index) * .055
		warm_materials[index].emission_energy_multiplier = .15 + warmth * .95
	celebration.visible = world.courtyard.court_lit
	if not celebration.visible: return
	# Slow coloured blossoms above the distant eaves, clear of faces and plaques.
	for index in range(240):
		var group: int = index / 60
		var t: float = fposmod(clock * .16 + group * .27, 1)
		var angle: float = (index % 60) * TAU / 60 + group * .4
		var radius: float = sin(t * PI * .5) * (.85 + (index % 3) * .12)
		var center := Vector3(42.8 + group * 4.8, 7.05 + (group % 2) * .18, -9.0)
		var at: Vector3 = center + Vector3(cos(angle) * radius, sin(angle) * radius - t * t * .8, 0)
		var scale: float = sin(t * PI) * .9
		celebration.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), at))
		var hue: Color=FIREWORK_COLORS[(group+int(clock*.16))%FIREWORK_COLORS.size()]
		celebration.multimesh.set_instance_color(index,hue.lerp(Color(.78,.86,1),t*.16))
