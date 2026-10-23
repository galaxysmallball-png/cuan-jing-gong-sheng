extends Node3D

# Shared geometry and materials for the courtyard and creek environments.
const SURFACE = preload("res://shaders/weathered_surface.gdshader")
# One low-poly flame mesh shared by every lamp, torch and candle. As a bare
# primitive each one cost 4,224 triangles for a shape a few pixels tall.
var _flame_meshes: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _materials: Dictionary = {}

func _surface(color: Color, pattern: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("pattern", pattern)
	return material


func _flat(color: Color, unshaded: bool = false, glow: bool = false) -> StandardMaterial3D:
	var key: String = str(color) + str(unshaded) + str(glow)
	if _materials.has(key): return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.5
	_materials[key] = material
	return material


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node


# Per-tile colour jitter is what the paving needs; a unique material per tile is
# not. Rounding the multiplier to sixteenths keeps the same mottled look while
# collapsing hundreds of one-off materials into a handful of shared ones.
func _flat_shade(base: Color, factor: float) -> StandardMaterial3D:
	var step: float = clampf(roundf(factor * 16.0) / 16.0, 0.75, 1.25)
	return _flat(Color(base.r * step, base.g * step, base.b * step))


# Same idea for boxes: a tiled roof is hundreds of identical slabs that share one
# material, so they belong in one mesh rather than one node each.
func _boxes_merged(parent: Node3D, material: Material, entries: Array) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cache: Dictionary = {}
	for entry: Array in entries:
		var size: Vector3 = entry[0]
		var key: String = "%.3f_%.3f_%.3f" % [size.x, size.y, size.z]
		var mesh: BoxMesh = cache.get(key)
		if mesh == null:
			mesh = BoxMesh.new()
			mesh.size = size
			cache[key] = mesh
		st.append_from(mesh, 0, entry[1])
	st.generate_tangents()
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	node.material_override = material
	parent.add_child(node)
	return node


func _rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.06
	mesh.height = 1.0
	# At 720p a 2 cm rod is about two pixels wide: seven sides buy nothing there,
	# while the scene spends most of its draw calls on them. Step the sides down
	# with the radius instead of using one density everywhere.
	if radius < 0.02:
		mesh.radial_segments = 3
	elif radius < 0.035:
		mesh.radial_segments = 5
	else:
		mesh.radial_segments = 7
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	_place_rod(node, a, b)
	return node


func _place_rod(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var offset: Vector3 = b - a
	if offset.length() < 0.001:
		node.visible = false
		return
	node.visible = true
	var rotation_basis := Basis(Quaternion(Vector3.UP, offset.normalized()))
	node.transform = Transform3D(rotation_basis * Basis.from_scale(Vector3(1, offset.length(), 1)), (a + b) * 0.5)


# Size is baked into the mesh, never into node.scale: lanterns hang under parents
# that already carry a vertical stretch, and a scaled child compounds it into a
# metre-tall blob. One cached mesh per distinct size keeps the low-poly shape.
func _flame(parent: Node3D, radius: float, height: float) -> MeshInstance3D:
	var key: String = "%.3f x %.3f" % [radius, height]
	var mesh: SphereMesh = _flame_meshes.get(key)
	if mesh == null:
		mesh = SphereMesh.new()
		mesh.radius = radius
		mesh.height = height
		mesh.radial_segments = 6
		mesh.rings = 3
		_flame_meshes[key] = mesh
	var node := MeshInstance3D.new()
	node.mesh = mesh
	parent.add_child(node)
	return node


# Curved corner upturn of a hip-and-gable eave: sweeping x/y while tapering the
# section, so the two ends read as flying corners instead of a flat beam.
func _upturned_eave(parent: Node3D, from: Vector3, to: Vector3, radius: float, material: Material, steps: int = 7) -> void:
	var previous := from
	for index in range(1, steps + 1):
		var t: float = float(index) / steps
		var point := from.lerp(to, t) + Vector3(0, pow(t, 2.1) * absf(to.x - from.x) * 0.34, 0)
		_rod(parent, previous, point, radius * (1.0 - t * 0.62), material)
		previous = point


func _rock(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lower: Array[Vector3] = []
	var upper: Array[Vector3] = []
	for index in range(7):
		var angle: float = TAU * index / 7.0
		var radius: float = rng.randf_range(0.42, 0.57)
		lower.append(Vector3(cos(angle) * radius, -0.5, sin(angle) * radius))
		upper.append(Vector3(cos(angle) * radius * 0.88, rng.randf_range(0.28, 0.51), sin(angle) * radius * 0.88))
	for index in range(7):
		var next: int = (index + 1) % 7
		for triangle in [[lower[index], upper[index], upper[next]], [lower[index], upper[next], lower[next]], [upper[index], Vector3(0.02, 0.56, -0.03), upper[next]], [lower[index], lower[next], Vector3(0, -0.5, 0)]]:
			for point: Vector3 in [triangle[0], triangle[2], triangle[1]]:
				st.set_uv(Vector2(point.x, point.z))
				st.add_vertex(point)
	st.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	node.material_override = material
	node.position = at
	node.scale = size
	node.rotation.y = rng.randf_range(-0.35, 0.35)
	parent.add_child(node)
	return node


# Builds every strut between two bounds into one mesh. A lattice window used to
# cost one node and one draw call per bar; the bars are a few pixels wide, so the
# silhouette is identical after merging and the batch drops by 24x per window.
func _rods_merged(parent: Node3D, material: Material, segments: Array) -> MeshInstance3D:
	var identity := Transform3D(Basis.IDENTITY, Vector3.ZERO)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for pair: Array in segments:
		var a: Vector3 = pair[0]
		var b: Vector3 = pair[1]
		var radius: float = pair[2]
		var offset: Vector3 = b - a
		if offset.length() < 0.001: continue
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius * 1.06
		mesh.height = 1.0
		mesh.radial_segments = 3 if radius < 0.02 else 5 if radius < 0.035 else 7
		var basis := Basis(Quaternion(Vector3.UP, offset.normalized())) * Basis.from_scale(Vector3(1, offset.length(), 1))
		st.append_from(mesh, 0, Transform3D(basis, (a + b) * 0.5))
	st.generate_tangents()
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	node.material_override = material
	parent.add_child(node)
	return node


func _pine(at: Vector3, height: float, distant: bool = false) -> void:
	var trunk: Material = _flat(Color(0.07, 0.09, 0.09), distant)
	_rod(self, at, at + Vector3(0.06, height, 0), height * 0.022, trunk)
	for layer in range(4):
		var tree := MeshInstance3D.new()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var radius: float = height * (0.20 - layer * 0.031)
		var rim: Array[Vector3] = []
		for index in range(18):
			var angle: float = TAU * index / 18.0
			var r: float = radius * rng.randf_range(0.72, 1.1) * (1.0 if index % 2 == 0 else 0.78)
			rim.append(Vector3(cos(angle) * r, -height * 0.20 + rng.randf_range(-0.07, 0.07), sin(angle) * r))
		for index in range(18):
			for point: Vector3 in [rim[index], rim[(index + 1) % 18], Vector3(height * 0.02, height * 0.24, 0)]:
				st.add_vertex(point)
		st.generate_normals()
		tree.mesh = st.commit()
		tree.position = at + Vector3(0, height * (0.40 + layer * 0.15), 0)
		tree.material_override = _flat(Color(0.055, 0.13 + layer * 0.009, 0.12), distant)
		add_child(tree)



