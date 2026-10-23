extends "res://scripts/environment_art.gd"

var chapter: Node3D
var stone: ShaderMaterial
var plaster: ShaderMaterial
var wood: ShaderMaterial
var roof: StandardMaterial3D
var moss: StandardMaterial3D
var lanterns: Array[Node3D] = []
var lamp_lights: Array[OmniLight3D] = []
var guide_light: OmniLight3D
var gate_visual: Node3D


func setup(owner_chapter: Node3D, mist_strength: float, moonlight: float) -> void:
	chapter = owner_chapter
	name = "SteleCourtyard"
	rng.seed = 1778405
	stone = _stone(Color(0.29, 0.33, 0.31), 0.32)
	plaster = _stone(Color(0.40, 0.41, 0.34), 0.14)
	wood = _surface(Color(0.20, 0.14, 0.09), 2.0)
	roof = _flat(Color(0.13, 0.18, 0.19))
	moss = _flat(Color(0.16, 0.23, 0.12))
	chapter.get_node("ObservationMarker").visible = false
	chapter.get_node("GateLever").visible = false
	chapter.get_node("Gate/Mesh").visible = false
	chapter._beam.light_energy = 2.6
	var cold: OmniLight3D = chapter.get_node("../ColdLight")
	cold.light_color = Color(0.46, 0.64, 0.76)
	cold.light_energy = 0.60
	_build_landscape(mist_strength)
	_build_paving()
	_build_ruined_corridor()
	_build_pavilion()
	_build_steles()
	_build_workbench()
	_build_exit()
	var wash := OmniLight3D.new()
	wash.position = Vector3(7.2, 4.5, -0.9)
	wash.light_color = Color(0.51, 0.70, 0.79)
	wash.light_energy = moonlight * 0.8
	wash.omni_range = 10.0
	add_child(wash)
	for at in [Vector3(2.7, 2.3, -1.25), Vector3(8.4, 2.45, -1.6), Vector3(10.8, 3.05, -1.85), Vector3(16.5, 3.05, -1.85)]:
		_lantern(at)


func _stone(color: Color, amount: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/courtyard_stone.gdshader")
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("moss_amount", amount)
	return material


func _quad(at: Vector3, size: Vector2, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	add_child(node)
	return node


func _build_landscape(mist_strength: float) -> void:
	for index in range(4):
		var fog := ShaderMaterial.new()
		fog.shader = preload("res://shaders/mist_ribbon.gdshader")
		fog.set_shader_parameter("strength", mist_strength if index < 2 else mist_strength * 0.7)
		var at: Vector3 = [Vector3(5.0, 0.30, 1.5), Vector3(14.0, 0.36, 1.5), Vector3(10.0, 1.2, -4.7), Vector3(10.0, 2.9, -8.0)][index]
		_quad(at, Vector2(13 if index < 2 else 23, 0.85 if index < 2 else 1.9), fog)
	for pair in [[Vector3(7.2, 2.8, -0.3), -0.28], [Vector3(9.1, 2.9, -0.5), -0.28]]:
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/courtyard_light.gdshader")
		var ray: MeshInstance3D = _quad(pair[0], Vector2(0.85, 4.8), material)
		ray.rotation.z = pair[1]
	for index in range(8):
		_fern(Vector3(rng.randf_range(0.5, 19), -0.03, 2.5), rng.randf_range(0.65, 1.1))
	for at in [Vector3(-0.2, -0.1, 2.9), Vector3(18.8, -0.1, 2.9), Vector3(8.3, 0, -3.2)]:
		_bamboo(at)


func _build_paving() -> void:
	var dark: ShaderMaterial = _stone(Color(0.19, 0.24, 0.23), 0.44)
	# One ground block only. The floor collision lives on Spaces/Space0x/Floor and
	# its mesh is hidden; stacking a second slab here only buried faces inside it.
	_box(self, Vector3(10, -0.40, 0), Vector3(20, 0.8, 5.5), dark)
	# The paving and the buried embankment have real visual value, so this only
	# keeps the small scatter from being generated where it cannot be seen: the
	# back row (z=-2.35) sits fully inside the rear embankment block below.
	for row in range(5):
		for index in range(20):
			var at := Vector3(0.48 + index + (0.10 if row % 2 else 0), -0.065, -2.0 + row * 0.95)
			var slab: MeshInstance3D = _rock(self, at, Vector3(rng.randf_range(0.95, 1.10), 0.13, rng.randf_range(0.90, 1.02)), stone)
			slab.rotation.y = rng.randf_range(-0.12, 0.12)
	for level in range(3):
		for index in range(15):
			var block: MeshInstance3D = _rock(self, Vector3(0.5 + index * 1.4, -0.22 - level * 0.20, 2.65 + level * 0.32), Vector3(1.45, 0.30, 0.70), dark)
			block.rotation.y = rng.randf_range(-0.04, 0.04)
	_box(self, Vector3(10, -1.13, 3.4), Vector3(21.2, 0.8, 2.0), _surface(Color(0.10, 0.15, 0.12), 0))
	var bank := preload("res://scripts/layered_bank.gd").new()
	add_child(bank)
	bank.setup(-.5,20.5,-.76,-3.65,4.46,Color(.24,.30,.29))
	# Rear scatter used to be planted inside the embankment block; keep it only on
	# the visible front row so it reads as edge rubble instead of buried geometry.
	for index in range(11):
		var x: float = rng.randf_range(0.5, 19)
		var z: float = 2.25
		_rock(self, Vector3(x, 0.08, z), Vector3(rng.randf_range(0.16, 0.44), 0.20, rng.randf_range(0.16, 0.36)), stone)
		if index % 3 == 0:
			_fern(Vector3(x, 0.01, z), 0.5)
	# A few dark damp patches catch lantern light without filling the walking lane.
	var wet := StandardMaterial3D.new()
	wet.albedo_color = Color(0.09, 0.16, 0.17, 0.55)
	wet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wet.roughness = 0.22
	for at in [Vector3(6.7, 0.015, 1.0), Vector3(9.5, 0.015, -0.5), Vector3(16.8, 0.015, 1.2)]:
		var puddle := MeshInstance3D.new()
		var disk := CylinderMesh.new()
		disk.top_radius = 0.52
		disk.bottom_radius = 0.52
		disk.height = 0.005
		disk.radial_segments = 14
		puddle.mesh = disk
		puddle.material_override = wet
		puddle.position = at
		puddle.scale.z = 0.46
		add_child(puddle)


func _build_ruined_corridor() -> void:
	# Broken walls leave an opening towards the trees, rather than sealing the space.
	for index in range(13):
		var x: float = 0.5 + index * 0.75
		var height: float = [3.2, 3.4, 2.9, 2.6, 1.7, 1.3, 1.2, 1.3, 1.3, 1.2, 1.5, 2.1, 2.5][index]
		_box(self, Vector3(x, height * 0.5, -3.1), Vector3(0.77, height, 0.43), plaster)
		_rock(self, Vector3(x, height, -3.1), Vector3(0.85, 0.18, 0.65), stone)
	for x in [1.15, 3.1, 8.1]:
		_post(Vector3(x, 0, -1.8), 3.8)
	_rod(self, Vector3(1.0, 3.62, -1.8), Vector3(5.9, 3.62, -1.8), 0.13, wood)
	_rod(self, Vector3(7.0, 3.58, -1.8), Vector3(8.5, 3.58, -1.8), 0.13, wood)
	var tile_surface:=SurfaceTool.new()
	tile_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fragments: int=0
	var tile_mesh: ArrayMesh=preload("res://scripts/barrel_tile_fragment.gd").mesh(.19,.83)
	for index in range(12):
		if index in [7, 8, 9]: continue
		var x: float = 0.9 + index * 0.61
		_rod(self, Vector3(x, 3.65, -3.65), Vector3(x + 0.1, 3.35, -0.95), 0.055, wood)
		if index < 6:
			for strip in range(3):
				for col in range(3):
					if index==4 and strip==2 and col==2: continue
					var at:=Vector3(x+(col-1)*.196,3.77-strip*.10,-3.1+strip*.7)
					tile_surface.append_from(tile_mesh,0,Transform3D(Basis(Vector3.RIGHT,.13),at))
					fragments+=1
					if strip==2: _rod(self,at+Vector3(0,-.014,.39),at+Vector3(0,-.014,.45),.038,roof)
	var remnants:=MeshInstance3D.new()
	remnants.mesh=tile_surface.commit()
	var remnants_clay: StandardMaterial3D=roof.duplicate()
	remnants_clay.cull_mode=BaseMaterial3D.CULL_DISABLED
	remnants.material_override=remnants_clay
	remnants.name="BrokenGalleryBarrelTileRemnants"
	remnants.set_meta("tile_fragments",fragments)
	remnants.add_to_group("broken_gallery_tile_detail")
	add_child(remnants)
	# A surviving round lattice window is framed by the collapsed wall.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.06
	torus.outer_radius = 1.23
	torus.rings = 32
	torus.ring_segments = 6
	ring.mesh = torus
	ring.material_override = stone
	ring.position = Vector3(5.3, 2.43, -2.96)
	ring.rotation.x = PI / 2.0
	add_child(ring)
	for offset in [-0.72, -0.36, 0.0, 0.36, 0.72]:
		var extent: float = sqrt(1.02 * 1.02 - offset * offset)
		_rod(self, Vector3(5.3 + offset, 2.43 - extent, -2.90), Vector3(5.3 + offset, 2.43 + extent, -2.90), 0.025, wood)
	for y in [2.05, 2.78]:
		_rod(self, Vector3(4.38, y, -2.87), Vector3(6.22, y, -2.87), 0.03, wood)
	for index in range(5):
		var at := Vector3(7.5 + index * 0.3, 3.6 - index * 0.46, -2.75)
		_rod(self, at, at + Vector3(0.14, -0.48, 0), 0.018, moss)
		_leaf(at + Vector3(0.05, -0.18, 0.05), Vector3(0.35, 0.06, 0), 0.13)
		_leaf(at + Vector3(0.10, -0.36, 0.05), Vector3(-0.32, 0.1, 0), 0.12)
	_rod(self, Vector3(8.7, 0.05, -2.0), Vector3(10.0, 0.18, -2.6), 0.09, wood)


func _post(at: Vector3, height: float) -> void:
	_box(self, at + Vector3(0, 0.14, 0), Vector3(0.48, 0.28, 0.47), stone)
	_rod(self, at + Vector3(0, 0.25, 0), at + Vector3(0, height, 0), 0.13, wood)
	_box(self, at + Vector3(0, height - 0.22, 0), Vector3(0.36, 0.14, 0.30), wood)


func _build_pavilion() -> void:
	# The two original inscriptions and their click targets retain their exact positions.
	_box(self, Vector3(13.6, 1.7, -3.35), Vector3(6.7, 3.4, 0.36), _stone(Color(0.17, 0.22, 0.22), 0.12))
	for x in [10.6, 13.55, 16.5]:
		_post(Vector3(x, 0.0, -2.98), 3.9)
	_rod(self, Vector3(10.35, 3.72, -2.95), Vector3(16.75, 3.72, -2.95), 0.16, wood)
	_rod(self, Vector3(10.3, 3.76, -1.22), Vector3(16.85, 3.76, -1.22), 0.10, wood)
	for x in [10.6, 16.5]:
		_rod(self, Vector3(x, 3.72, -3.0), Vector3(x, 3.72, -1.15), 0.08, wood)
		_rod(self, Vector3(x, 3.0, -3.0), Vector3(x + (0.56 if x < 12 else -0.56), 3.70, -3.0), 0.07, wood)
	var slabs: Array = []
	var ridges: Array = []
	for index in range(26):
		var x: float = 10.25 + index * 0.255
		for row in range(5):
			var z: float = -3.9 + row * 0.55
			var y: float = 4.35 - absf(z + 2.9) * 0.30
			var tilt := Basis(Vector3.RIGHT, -0.29 if z < -2.9 else 0.29)
			slabs.append([Vector3(0.245, 0.11, 0.70), Transform3D(tilt, Vector3(x, y, z))])
			if index % 3 == 0:
				ridges.append([Vector3(x, y + 0.075, z - 0.3), Vector3(x, y + 0.075, z + 0.3), 0.042])
	ridges.append([Vector3(10.08, 4.46, -2.9), Vector3(16.95, 4.46, -2.9), 0.08])
	_boxes_merged(self, roof, slabs).name = "PavilionTiles"
	_rods_merged(self, roof, ridges).name = "PavilionRidges"
	for side in [-1.0, 1.0]:
		var x: float = 13.5 + side * 3.43
		_rod(self, Vector3(x, 4.45, -2.9), Vector3(x + side * 0.22, 4.60, -2.9), 0.065, roof)
		# The concept shows flying corners on the gate pavilion; the flat beam above
		# read as a plain ridge. Curl both eave ends up and out, and carry the same
		# sweep at the front eave line behind the stelae.
		_upturned_eave(self, Vector3(x, 4.42, -3.95), Vector3(x + side * 0.62, 4.42, -3.05), 0.058, roof)
		_upturned_eave(self, Vector3(x, 4.36, 0.05), Vector3(x + side * 0.52, 4.36, -0.85), 0.050, roof)
	var light := OmniLight3D.new()
	light.position = Vector3(13.55, 2.8, -0.7)
	light.light_color = Color(0.92, 0.79, 0.55)
	light.light_energy = 1.3
	light.omni_range = 5.5
	add_child(light)


func _build_steles() -> void:
	for id in range(2):
		var panel: MeshInstance3D = chapter.get_node("SmallPanel" if id == 0 else "LargePanel")
		panel.material_override = _stone(Color(0.31, 0.34, 0.32), 0.08)
		preload("res://scripts/historical_steles.gd").dress(panel, id)
		var x: float = panel.position.x
		var width: float = 1.57 if id == 0 else 1.87
		_box(self, Vector3(x, 0.10, -2.38), Vector3(width, 0.20, 0.88), stone)
		_box(self, Vector3(x, 0.24, -2.38), Vector3(width - 0.18, 0.10, 0.67), stone)
		var half_height: float = 0.95 if id == 0 else 1.25
		var half_width: float = 0.55 if id == 0 else 0.675
		_box(panel, Vector3(0, half_height + 0.035, -0.015), Vector3(half_width * 2.0 + 0.13, 0.13, 0.35), stone)
		for side in [-1.0, 1.0]:
			_box(panel, Vector3(side * (half_width - 0.014), 0, 0.12), Vector3(0.055, half_height * 1.96, 0.075), stone)
		var caption: Label3D = panel.get_node("Caption")
		caption.font_size = preload("res://scripts/interface_skin.gd").text_size(36)
		caption.modulate = Color(0.96, 0.86, 0.64)
		caption.outline_size = 5
		var candle: MeshInstance3D = _box(self, Vector3(x - width * 0.5 + 0.1, 0.39, -1.95), Vector3(0.10, 0.20, 0.10), _flat(Color(0.68, 0.51, 0.28)))
		var wick: MeshInstance3D = _flame(candle, 0.02, 0.09)
		wick.position = Vector3(0, 0.14, 0)
		wick.material_override = _flat(Color(1.0, 0.65, 0.26), true, true)


func _build_workbench() -> void:
	var at := Vector3(9.3, 0.85, -2.0)
	_box(self, at, Vector3(1.15, 0.13, 0.65), wood)
	for x in [-0.46, 0.46]:
		for z in [-0.23, 0.23]:
			_rod(self, at + Vector3(x, -0.82, z), at + Vector3(x, 0, z), 0.035, wood)
	var paper: Material = _flat(Color(0.61, 0.61, 0.48))
	_box(self, at + Vector3(-0.04, 0.08, 0), Vector3(0.64, 0.012, 0.40), paper)
	for x in [8.99, 9.55]:
		_rod(self, Vector3(x, 0.98, -2.15), Vector3(x, 0.98, -1.82), 0.035, paper)
	_box(self, at + Vector3(0.38, 0.14, -0.02), Vector3(0.17, 0.12, 0.20), _flat(Color(0.08, 0.10, 0.11)))
	_rod(self, Vector3(9.30, 0.98, -2.15), Vector3(9.55, 1.01, -2.1), 0.012, wood)
	_box(self, Vector3(9.0, 0.30, -2.0), Vector3(0.50, 0.14, 0.42), wood)


func _build_exit() -> void:
	for z in [-1.3, 1.3]:
		_post(Vector3(18.95, 0, z), 3.55)
	_rod(self, Vector3(18.95, 3.46, -1.48), Vector3(18.95, 3.46, 1.48), 0.13, wood)
	# Flying corners on the entrance gate, as drawn in the board. They sit one
	# step above the beam and never dip into the tall jump clearance (y 1.2-5.0).
	for z in [-1.48, 1.48]:
		var outward: float = signf(z)
		_upturned_eave(self, Vector3(18.95, 3.46, z), Vector3(18.95, 3.46, z + outward * 0.72), 0.075, wood)
	var gate: Node3D = chapter.get_node("Gate")
	gate_visual = Node3D.new()
	gate_visual.name = "LatticeGate"
	gate.add_child(gate_visual)
	for index in range(9):
		_box(gate_visual, Vector3(0, -0.90, -1.15 + index * 0.29), Vector3(0.16, 3.15, 0.08), wood)
	for y in [-2.2, -0.9, 0.6]:
		_box(gate_visual, Vector3(0, y, 0), Vector3(0.20, 0.12, 2.5), wood)
	guide_light = OmniLight3D.new()
	guide_light.position = Vector3(18.2, 2.1, 0)
	guide_light.light_color = Color(1, 0.67, 0.34)
	guide_light.light_energy = 0.30
	guide_light.omni_range = 5.0
	add_child(guide_light)
	_lantern(Vector3(18.7, 2.75, -1.0))
	preload("res://scripts/world_signs.gd").plaque(self, Vector3(17.35, 1.65, -2.5), "古道", Vector2(1.20, 0.46), 1)


func _lantern(at: Vector3) -> void:
	var fixture := Node3D.new()
	fixture.position = at
	add_child(fixture)
	lanterns.append(fixture)
	var glow: Material = _flat(Color(0.83, 0.54, 0.24), true, true)
	var body := MeshInstance3D.new()
	var lamp := CylinderMesh.new()
	lamp.top_radius = 0.13
	lamp.bottom_radius = 0.15
	lamp.height = 0.37
	lamp.radial_segments = 10
	body.mesh = lamp
	body.material_override = glow
	fixture.add_child(body)
	for y in [-0.21, 0.21]:
		_box(fixture, Vector3(0, y, 0), Vector3(0.34, 0.06, 0.32), wood)
	for x in [-0.15, 0.15]:
		for z in [-0.13, 0.13]:
			_rod(fixture, Vector3(x, -0.20, z), Vector3(x, 0.20, z), 0.014, wood)
	_rod(fixture, Vector3(0, 0.24, 0), Vector3(0, 0.62, 0), 0.014, wood)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0, -0.1, 0.4)
	light.light_color = Color(1.0, 0.68, 0.36)
	light.light_energy = 0.8
	light.omni_range = 4.4
	add_child(light)
	lamp_lights.append(light)


func _leaf(at: Vector3, direction: Vector3, width: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := Vector3(-direction.y, direction.x, 0).normalized() * width
	for point: Vector3 in [Vector3.ZERO, direction * 0.5 + side, direction, Vector3.ZERO, direction, direction * 0.5 - side]:
		st.add_vertex(point)
	st.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	node.position = at
	var material: StandardMaterial3D = _flat(Color(0.14, 0.24, 0.13))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	add_child(node)


func _fern(at: Vector3, size: float) -> void:
	for side in [-1.0, 1.0]:
		var top: Vector3 = at + Vector3(side * size * 0.42, size * 0.55, 0)
		_rod(self, at, top, 0.008, moss)
		for index in range(4):
			var point: Vector3 = at.lerp(top, 0.25 + index * 0.18)
			_leaf(point, Vector3(side * 0.12 * size, 0.12 * size, 0), size * 0.05)
			_leaf(point, Vector3(-side * 0.12 * size, 0.10 * size, 0), size * 0.05)


func _bamboo(at: Vector3) -> void:
	for index in range(4):
		var bottom: Vector3 = at + Vector3((index - 1.5) * 0.19, 0, index * 0.07)
		var height: float = rng.randf_range(2.6, 4.3)
		var top: Vector3 = bottom + Vector3((index - 1.5) * 0.22, height, 0)
		_rod(self, bottom, top, 0.028, moss)
		for joint in range(7):
			var point: Vector3=bottom.lerp(top,.14+joint*.115)
			var ring:=MeshInstance3D.new()
			var mesh:=CylinderMesh.new()
			mesh.top_radius=.031
			mesh.bottom_radius=.031
			mesh.height=.018
			mesh.radial_segments=10
			ring.mesh=mesh
			ring.position=point
			ring.material_override=_flat(Color(.27,.34,.18))
			add_child(ring)
			if joint%2==0: continue
			for side in [-1.0,1.0]:
				var branch: Vector3=point+Vector3(side*.42,.14,.04)
				_rod(self,point,branch,.008,moss)
				for leaf in range(5):
					var start: Vector3=point.lerp(branch,.23+leaf*.16)
					var tip: Vector3=start+Vector3(side*(.13+leaf*.013),.18 if leaf%2==0 else -.14,.03)
					preload("res://scripts/botanical_detail.gd").sprig(self,start,tip,.024,Color(.17,.29,.14))


func _process(delta: float) -> void:
	if chapter == null: return
	gate_visual.visible = not chapter.gate_open
	var seconds: float = Time.get_ticks_msec() * 0.001
	for index in range(lanterns.size()):
		lanterns[index].rotation.z = sin(seconds * 0.8 + index) * 0.025
		lamp_lights[index].light_energy = 0.8 + sin(seconds * 4.2 + index * 2) * 0.04
	guide_light.light_energy = move_toward(guide_light.light_energy, 1.25 if chapter.observed else 0.30, delta)
