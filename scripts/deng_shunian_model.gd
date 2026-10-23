extends Node3D

# Original, editable 3D geometry interpreted from the user's character sheet.
# Front is +Z. Feet rest at Y=0; the model contains no gameplay collisions.
var rig: Node3D
var head_rig: Node3D
var skirt: Node3D
var bag: Node3D
var ornaments: Node3D
var eyes: Node3D
var brush: Node3D
var arms: Array[Node3D] = []
var forearms: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var ribbons: Array[Node3D] = []
var _materials: Dictionary = {}
var _elapsed: float = 0
var _gait: float = 0
var _cloth_texture: ImageTexture


func _ready() -> void:
	if get_child_count() == 0: build()
	bind_rig()


func build() -> void:
	name = "DengShunian"
	scale = Vector3.ONE * 0.86
	_make_materials()
	rig = _joint(self, "Rig", Vector3.ZERO)
	_build_robe()
	_build_legs()
	_build_arms()
	_build_head()
	_build_bag()
	_build_ornaments()
	pose(0, 0, 0, true, false, false)


func bind_rig() -> void:
	rig = get_node("Rig")
	head_rig = rig.get_node("Head")
	skirt = rig.get_node("Skirt")
	bag = rig.get_node("BookBag")
	ornaments = rig.get_node("WaistOrnaments")
	eyes = head_rig.get_node("Eyes")
	brush = rig.get_node("RightArm/Forearm/Brush")
	arms.assign([rig.get_node("LeftArm"), rig.get_node("RightArm")])
	forearms.assign([arms[0].get_node("Forearm"), arms[1].get_node("Forearm")])
	legs.assign([rig.get_node("LeftLeg"), rig.get_node("RightLeg")])
	knees.assign([legs[0].get_node("Knee"), legs[1].get_node("Knee")])
	ribbons.assign([head_rig.get_node("HatRibbonLeft"), head_rig.get_node("HatRibbonRight")])


func _joint(parent: Node3D, part_name: String, at: Vector3) -> Node3D:
	var part := Node3D.new()
	part.name = part_name
	part.position = at
	parent.add_child(part)
	return part


func _material(key: String, color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = key
	material.albedo_color = color
	material.roughness = roughness
	material.metallic_specular = 0.18
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


func _make_materials() -> void:
	var image := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 320405
	noise.frequency = 0.12
	for y in range(128):
		for x in range(128):
			var grain: float = 0.84 + noise.get_noise_2d(x, y) * 0.14
			grain += (0.026 if x % 3 == 0 else 0) + (0.018 if y % 3 == 0 else 0)
			image.set_pixel(x, y, Color(grain, grain, grain))
	image.generate_mipmaps()
	_cloth_texture = ImageTexture.create_from_image(image)
	for entry in [["Indigo", Color(0.34, 0.42, 0.46)], ["DarkCloth", Color(0.075, 0.076, 0.069)],
		["Lapel", Color(0.105, 0.115, 0.108)], ["Linen", Color(0.70, 0.65, 0.51)],
		["Belt", Color(0.26, 0.29, 0.21)], ["Trousers", Color(0.25, 0.32, 0.34)]]:
		var material: StandardMaterial3D = _material(entry[0], entry[1])
		material.albedo_texture = _cloth_texture
		material.metallic_specular = 0.08
		material.vertex_color_use_as_albedo = true
	_material("Skin", Color(0.69, 0.49, 0.31), 0.96)
	_material("SkinLight", Color(0.76, 0.56, 0.37), 0.96)
	_material("SkinShadow", Color(0.44, 0.27, 0.16))
	_material("Hair", Color(0.045, 0.043, 0.032))
	_material("Ink", Color(0.038, 0.038, 0.030))
	_material("EyeWhite", Color(0.91, 0.86, 0.71), 0.6)
	_material("Iris", Color(0.12, 0.09, 0.051), 0.55)
	_material("Pupil", Color(0.012, 0.014, 0.010), 0.4)
	_material("Paper", Color(0.75, 0.69, 0.51))
	_material("PaperEdge", Color(0.51, 0.44, 0.30))
	_material("Bamboo", Color(0.40, 0.26, 0.11))
	_material("Cord", Color(0.32, 0.23, 0.12))
	_material("Bronze", Color(0.48, 0.31, 0.12), 0.62)
	_material("Jade", Color(0.41, 0.54, 0.47), 0.55)
	_material("Sole", Color(0.28, 0.25, 0.18))
	_material("Stitch", Color(0.32, 0.33, 0.28))


func _sphere(parent: Node3D, part_name: String, at: Vector3, radii: Vector3, material: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 20
	mesh.rings = 10
	node.mesh = mesh
	node.scale = radii
	node.position = at
	node.material_override = _materials[material]
	parent.add_child(node)
	return node


func _box(parent: Node3D, part_name: String, at: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = _materials[material]
	parent.add_child(node)
	return node


func _finish(parent: Node3D, part_name: String, st: SurfaceTool, material: String) -> MeshInstance3D:
	st.index()
	st.generate_normals()
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = st.commit()
	node.material_override = _materials[material]
	parent.add_child(node)
	return node


func _vertex(st: SurfaceTool, point: Vector3, uv: Vector2, tint: Color = Color.WHITE) -> void:
	st.set_uv(uv)
	st.set_color(tint)
	st.add_vertex(point)


func _loft(parent: Node3D, part_name: String, rows: Array, material: String, cloth: bool = false, segments: int = 32, open_ends: bool = false) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var points: Array = []
	var colors: Array = []
	for row_index in range(rows.size()):
		var row: Array = rows[row_index]
		var ring: Array[Vector3] = []
		var tints: Array[Color] = []
		for index in range(segments + 1):
			var angle: float = TAU * index / segments
			var fold: float = (sin(angle * 9 + row[0] * 0.7) + sin(angle * 17 - row[0]) * 0.25) * 0.008 if cloth else 0
			var point := Vector3(cos(angle) * (row[1] + fold), row[0], sin(angle) * (row[2] + fold))
			if row.size() > 3: point += Vector3(row[3], 0, row[4])
			ring.append(point)
			var weight: float = pow(1.0 - float(row_index) / maxf(rows.size() - 1, 1), 5)
			var speckle: float = absf(sin(angle * 27 + row[0] * 99) * cos(angle * 11 - row[0] * 73))
			var tint: Color = Color.WHITE.lerp(Color(1.75, 1.52, 1.16), weight * speckle * 0.67) if cloth else Color.WHITE
			if cloth: tint *= 0.94 + sin(angle * 9) * 0.065
			tint.a = 1
			tints.append(tint)
		points.append(ring)
		colors.append(tints)
	for row in range(rows.size() - 1):
		for index in range(segments):
			for corner in [[row, index], [row + 1, index], [row + 1, index + 1], [row, index], [row + 1, index + 1], [row, index + 1]]:
				_vertex(st, points[corner[0]][corner[1]], Vector2(float(corner[1]) / segments * 2, float(corner[0]) / (rows.size() - 1) * 3), colors[corner[0]][corner[1]])
	for end in ([] if open_ends else [0, rows.size() - 1]):
		var center := Vector3(0, rows[end][0], 0)
		if rows[end].size() > 3: center += Vector3(rows[end][3], 0, rows[end][4])
		for index in range(segments):
			var vertices: Array = [center, points[end][index], points[end][index + 1]]
			if end == 0: vertices.reverse()
			for point: Vector3 in vertices: _vertex(st, point, Vector2(point.x, point.z))
	return _finish(parent, part_name, st, material)


func _pipe(parent: Node3D, part_name: String, points: Array, radius: float, material: String, segments: int = 7) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for index in range(points.size()):
		var tangent: Vector3 = points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]
		var axis := Basis(Quaternion(Vector3.UP, tangent.normalized()))
		var ring: Array[Vector3] = []
		for side in range(segments + 1):
			var angle: float = TAU * side / segments
			ring.append(points[index] + axis * Vector3(cos(angle) * radius, 0, sin(angle) * radius))
		rings.append(ring)
	for row in range(points.size() - 1):
		for side in range(segments):
			for corner in [[row, side], [row + 1, side], [row + 1, side + 1], [row, side], [row + 1, side + 1], [row, side + 1]]:
				_vertex(st, rings[corner[0]][corner[1]], Vector2(float(corner[1]) / segments, corner[0]))
	return _finish(parent, part_name, st, material)


func _ribbon(parent: Node3D, part_name: String, points: Array, width: float, material: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges: Array = []
	for index in range(points.size()):
		var tangent: Vector3 = points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]
		var side: Vector3 = tangent.cross(Vector3.BACK).normalized() * width * 0.5
		edges.append([points[index] - side, points[index] + side])
	for row in range(points.size() - 1):
		for corner in [[row, 0], [row + 1, 0], [row + 1, 1], [row, 0], [row + 1, 1], [row, 1]]:
			_vertex(st, edges[corner[0]][corner[1]], Vector2(corner[1], float(corner[0]) / (points.size() - 1)))
	return _finish(parent, part_name, st, material)


func _build_robe() -> void:
	_loft(rig, "UpperRobe", [[0.98,0.158,0.125],[1.03,0.16,0.128],[1.14,0.168,0.13],[1.27,0.186,0.127],[1.35,0.194,0.12],[1.43,0.12,0.093]], "Indigo", true)
	skirt = _joint(rig, "Skirt", Vector3(0, 1.01, 0))
	_loft(skirt, "PleatedLongHem", [[-0.72,0.24,0.17],[-0.69,0.238,0.17],[-0.62,0.23,0.167],[-0.52,0.222,0.164],[-0.40,0.21,0.157],[-0.27,0.195,0.145],[-0.14,0.18,0.136],[0,0.16,0.127]], "Indigo", true, 48)
	_loft(skirt, "DarkHemBinding", [[-0.735,0.241,0.174],[-0.703,0.242,0.174]], "Lapel", true, 48)
	# Front overlap and hand-sewn seams follow the robe's actual surface.
	_pipe(skirt, "FrontSeam", [Vector3(-0.025,-0.69,0.174),Vector3(-0.012,-0.43,0.166),Vector3(0,-0.16,0.145),Vector3(0.03,0,0.128)], 0.003, "Lapel")
	for index in range(7):
		var x: float = -0.18 + index * 0.06
		_pipe(skirt, "Fold", [Vector3(x,-0.65,0.16 - absf(x) * 0.25),Vector3(x*0.85,-0.35,0.16 - absf(x) * 0.26),Vector3(x*0.65,-0.05,0.13 - absf(x)*0.24)], 0.0015, "Stitch", 5)
	_loft(rig, "Neck", [[1.39,0.061,0.054],[1.53,0.052,0.050]], "Skin")
	_ribbon(rig, "InnerCollarLeft", [Vector3(-0.081,1.46,0.073),Vector3(-0.045,1.35,0.126),Vector3(0.012,1.23,0.142)], 0.025, "Linen")
	_ribbon(rig, "InnerCollarRight", [Vector3(0.081,1.46,0.073),Vector3(0.045,1.35,0.136),Vector3(-0.10,1.06,0.15)], 0.041, "Linen")
	_ribbon(rig, "CrossLapelUnder", [Vector3(-0.115,1.44,0.074),Vector3(-0.077,1.32,0.14),Vector3(0.024,1.20,0.145)], 0.045, "Lapel")
	_ribbon(rig, "CrossLapelOver", [Vector3(0.115,1.44,0.074),Vector3(0.08,1.32,0.15),Vector3(-0.105,1.015,0.155)], 0.050, "Lapel")
	_loft(rig, "Sash", [[0.976,0.169,0.139],[1.009,0.17,0.14],[1.039,0.165,0.134]], "Belt", true)
	_sphere(rig, "SashKnot", Vector3(-0.07,1.01,0.15), Vector3(0.039,0.031,0.02), "Belt")
	_ribbon(rig, "SashTailLong", [Vector3(-0.075,1.0,0.15),Vector3(-0.09,0.81,0.161),Vector3(-0.08,0.62,0.164),Vector3(-0.12,0.44,0.175)], 0.041, "Belt")
	_ribbon(rig, "SashTailShort", [Vector3(-0.055,1,0.15),Vector3(-0.02,0.84,0.166),Vector3(-0.035,0.69,0.17)], 0.032, "Belt")
	for side in [-1,1]:
		_pipe(rig, "ShoulderSeam", [Vector3(side*0.1,1.43,-0.045),Vector3(side*0.17,1.37,-0.018),Vector3(side*0.20,1.31,0.01)], 0.002, "Stitch")


func _build_legs() -> void:
	for index in range(2):
		var side: float = -1 if index == 0 else 1
		var leg: Node3D = _joint(rig, "LeftLeg" if index == 0 else "RightLeg", Vector3(side*0.10,0.87,0))
		legs.append(leg)
		_loft(leg, "LooseTrousers", [[-0.36,0.071,0.075],[-0.25,0.087,0.086],[-0.10,0.078,0.08],[0,0.069,0.075]], "Trousers", true)
		var knee: Node3D = _joint(leg, "Knee", Vector3(0,-0.35,0))
		knees.append(knee)
		_loft(knee, "Calf", [[-0.32,0.052,0.052],[-0.20,0.064,0.061],[-0.06,0.073,0.07],[0.015,0.069,0.071]], "Trousers", true)
		_loft(knee, "LinenBindings", [[-0.385,0.055,0.056],[-0.34,0.058,0.06],[-0.27,0.064,0.063],[-0.22,0.065,0.066]], "Linen", true)
		for wrap in range(5):
			var path: Array[Vector3] = []
			for step in range(18):
				var angle: float = TAU*step/17
				path.append(Vector3(cos(angle)*0.065,-0.36+wrap*0.028+sin(angle)*0.012,sin(angle)*0.065))
			_pipe(knee, "WrappedSeam", path, 0.0018, "PaperEdge", 5)
		_sphere(knee, "ClothShoe", Vector3(0,-0.435,0.05), Vector3(0.069,0.048,0.135), "DarkCloth")
		_sphere(knee, "LayeredSole", Vector3(0,-0.468,0.052), Vector3(0.074,0.018,0.139), "Sole")
		_sphere(knee, "WornToe", Vector3(0,-0.433,0.169), Vector3(0.048,0.026,0.016), "Sole")


func _build_arms() -> void:
	for index in range(2):
		var side: float = -1 if index == 0 else 1
		var arm: Node3D = _joint(rig, "LeftArm" if index == 0 else "RightArm", Vector3(side*0.198,1.34,0))
		arms.append(arm)
		var upper_length: float = 0.32 if index == 0 else 0.23
		_loft(arm, "UpperSleeve", [[-upper_length-0.015,0.10,0.10],[-upper_length*0.72,0.10,0.105],[-0.05,0.077,0.088],[0.035,0.055,0.070]], "Indigo", true, 32, true)
		var forearm: Node3D = _joint(arm, "Forearm", Vector3(0,-upper_length,0))
		forearms.append(forearm)
		_loft(forearm, "WideSleeve", [[-0.27,0.132,0.13],[-0.24,0.127,0.129],[-0.16,0.116,0.119],[-0.055,0.092,0.102],[0.02,0.09,0.098]], "Indigo", true, 32, true)
		_loft(forearm, "CuffBinding", [[-0.285,0.132,0.132],[-0.255,0.134,0.134]], "Lapel", true, 32, true)
		_loft(forearm, "Undersleeve", [[-0.31,0.096,0.10],[-0.274,0.103,0.107]], "Linen", true, 32, true)
		_loft(forearm, "CuffLining", [[-0.308,0.089,0.094],[-0.19,0.078,0.085]], "Lapel", false, 24, true)
		_sphere(forearm, "Palm", Vector3(0,-0.337,0.01), Vector3(0.038,0.057,0.029), "SkinLight")
		for finger in range(4):
			var x: float = -0.027+finger*0.017
			_pipe(forearm, "Finger", [Vector3(x,-0.355,0.026),Vector3(x,-0.389,0.03),Vector3(x,-0.400,0.017)], 0.007, "SkinLight", 6)
		_pipe(forearm, "Thumb", [Vector3(side*0.03,-0.324,0.02),Vector3(side*0.049,-0.35,0.037),Vector3(side*0.034,-0.372,0.039)], 0.010, "Skin", 7)
		for fold in range(3):
			var x: float = -0.075+fold*0.067
			_pipe(forearm, "SleeveFold", [Vector3(x,-0.24,0.113),Vector3(x*0.75,-0.13,0.106),Vector3(x*0.55,-0.035,0.09)], 0.0015, "Stitch", 5)
	brush = _joint(forearms[1], "Brush", Vector3(0.012,-0.36,0.033))
	_pipe(brush, "BambooBrushHandle", [Vector3(0,0.10,0),Vector3(0,-0.24,0)], 0.007, "Bamboo")
	_pipe(brush, "BrushFerrule", [Vector3(0,-0.23,0),Vector3(0,-0.265,0)], 0.009, "DarkCloth")
	_loft(brush, "BrushTip", [[-0.31,0.001,0.001],[-0.29,0.009,0.009],[-0.26,0.008,0.008]], "Ink", false, 10)


func _build_head() -> void:
	head_rig = _joint(rig, "Head", Vector3(0,1.48,0))
	_loft(head_rig, "LongFace", [[0,0.041,0.053],[0.025,0.060,0.067],[0.075,0.083,0.079],[0.14,0.105,0.092],[0.22,0.111,0.095],[0.285,0.103,0.09],[0.325,0.085,0.074]], "SkinLight", false, 36)
	for side in [-1,1]:
		_sphere(head_rig, "Ear", Vector3(side*0.112,0.166,0.0), Vector3(0.022,0.040,0.018), "Skin")
		_pipe(head_rig, "EarRidge", [Vector3(side*0.115,0.19,0.014),Vector3(side*0.122,0.167,0.02),Vector3(side*0.114,0.144,0.016)], 0.003, "SkinShadow")
	# Small eyes and nose are sculpted volumes, not text or pasted reference pixels.
	eyes = _joint(head_rig, "Eyes", Vector3(0,0.21,0.088))
	for side in [-1,1]:
		_sphere(eyes, "EyeWhite", Vector3(side*0.05,0,0), Vector3(0.032,0.039,0.009), "EyeWhite")
		_sphere(eyes, "Iris", Vector3(side*0.046,-0.002,0.011), Vector3(0.013,0.018,0.004), "Iris")
		_sphere(eyes, "Pupil", Vector3(side*0.046,-0.002,0.014), Vector3(0.008,0.012,0.003), "Pupil")
		_sphere(eyes, "Catchlight", Vector3(side*0.046-0.003,0.005,0.017), Vector3(0.0025,0.0035,0.001), "EyeWhite")
		_pipe(head_rig, "UpperEyelid", [Vector3(side*0.018,0.225,0.091),Vector3(side*0.045,0.253,0.092),Vector3(side*0.078,0.235,0.080)], 0.0025, "Hair")
		_pipe(head_rig, "LowerEyelid", [Vector3(side*0.023,0.187,0.091),Vector3(side*0.050,0.170,0.094),Vector3(side*0.078,0.188,0.08)], 0.0018, "SkinShadow")
		_pipe(head_rig, "WorriedBrow", [Vector3(side*0.018,0.287,0.083),Vector3(side*0.045,0.280,0.091),Vector3(side*0.085,0.259,0.078)], 0.004, "Hair")
		_pipe(head_rig, "CheekLine", [Vector3(side*0.084,0.173,0.076),Vector3(side*0.070,0.139,0.076)], 0.0018, "SkinShadow", 5)
	_loft(head_rig, "Nose", [[0.12,0.008,0.008,0,0.113],[0.135,0.016,0.021,0,0.123],[0.16,0.012,0.022,0,0.115],[0.205,0.009,0.011,0,0.092]], "Skin", false, 12)
	_pipe(head_rig, "Mouth", [Vector3(-0.026,0.077,0.080),Vector3(0,0.082,0.087),Vector3(0.025,0.077,0.080)], 0.0024, "SkinShadow")
	_pipe(head_rig, "LowerLip", [Vector3(-0.013,0.064,0.080),Vector3(0.010,0.064,0.082)], 0.0015, "Skin")
	_sphere(head_rig, "TiedHair", Vector3(0,0.23,-0.035), Vector3(0.113,0.121,0.086), "Hair")
	for side in [-1,1]:
		for strand in range(4):
			_ribbon(head_rig, "LooseHair", [Vector3(side*(0.055+strand*0.017),0.326,0.045-strand*0.009),Vector3(side*(0.087+strand*0.01),0.297,0.065),Vector3(side*(0.101+strand*0.01),0.242,0.059),Vector3(side*(0.105+strand*0.012),0.18-strand*0.018,0.028)], 0.009-strand*0.001, "Hair")
		for strand in range(3):
			_pipe(head_rig, "Flyaway", [Vector3(side*0.095,0.25,-0.023),Vector3(side*(0.13+strand*0.008),0.22-strand*0.036,-0.007),Vector3(side*(0.14+strand*0.005),0.14-strand*0.04,-0.019)], 0.0018, "Hair", 5)
	_build_hat()


func _build_hat() -> void:
	var outline: Array[Vector2] = [Vector2(-1,-0.7),Vector2(-0.7,-1),Vector2(0.7,-1),Vector2(1,-0.7),Vector2(1,0.7),Vector2(0.7,1),Vector2(-0.7,1),Vector2(-1,0.7)]
	for layer in range(2):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rows: Array = []
		for level in range(3):
			var ring: Array[Vector3] = []
			for point in outline:
				var y: float = (0.31+level*0.047) if layer == 0 else (0.39+level*0.067)
				var rx: float = (0.138 if level < 2 else 0.132) if layer == 0 else (0.112+level*0.012)
				y += point.x * 0.013 if layer == 1 else point.x * -0.007
				if layer == 1 and level == 2: y += sin(point.x*2.0 + point.y*3.7)*0.018
				ring.append(Vector3(point.x*rx + (0.010*level if layer == 1 else 0),y,point.y*(0.107 if layer == 0 else 0.092)))
			rows.append(ring)
		for row in range(2):
			for side in range(8):
				for corner in [[row,side],[row+1,side],[row+1,(side+1)%8],[row,side],[row+1,(side+1)%8],[row,(side+1)%8]]:
					_vertex(st, rows[corner[0]][corner[1]], Vector2(corner[1]/8.0,corner[0]/2.0), Color.WHITE * (0.8+side*0.025))
		for side in range(8):
			for point: Vector3 in [Vector3(0.01,0.405 if layer == 0 else 0.52,0),rows[2][side],rows[2][(side+1)%8]]:
				_vertex(st, point, Vector2(point.x*3,point.z*3))
		_finish(head_rig, "HatBand" if layer == 0 else "FoldedHatCrown", st, "DarkCloth")
	_pipe(head_rig, "HatFrontSeam", [Vector3(-0.12,0.324,0.108),Vector3(0,0.314,0.109),Vector3(0.12,0.308,0.108)], 0.002, "Stitch")
	_ribbon(head_rig, "HatTopFold", [Vector3(-0.09,0.525,-0.04),Vector3(0,0.52,0.035),Vector3(0.13,0.515,0.075)], 0.018, "Lapel")
	for side in [-1,1]:
		var ribbon: Node3D = _joint(head_rig, "HatRibbonLeft" if side == -1 else "HatRibbonRight", Vector3(side*0.08,0.33,-0.08))
		ribbons.append(ribbon)
		_ribbon(ribbon, "ClothTail", [Vector3.ZERO,Vector3(side*0.025,-0.085,-0.025),Vector3(side*0.065,-0.16,-0.045),Vector3(side*0.075,-0.28,-0.033)], 0.028, "DarkCloth")


func _build_bag() -> void:
	bag = _joint(rig, "BookBag", Vector3(-0.29,0.76,-0.05))
	_loft(bag, "SoftClothBag", [[-0.20,0.095,0.08],[-0.17,0.125,0.093],[-0.08,0.14,0.10],[0.035,0.13,0.085],[0.12,0.12,0.072]], "Indigo", true)
	var rim: Array[Vector3] = []
	for index in range(33):
		var angle: float = TAU*index/32
		rim.append(Vector3(cos(angle)*0.12,0.12+cos(angle*3)*0.01,sin(angle)*0.073))
	_pipe(bag, "BoundBagOpening", rim, 0.009, "Lapel")
	_ribbon(rig, "FrontShoulderStrap", [Vector3(-0.14,1.44,0.035),Vector3(-0.16,1.27,0.13),Vector3(-0.21,1.02,0.12),Vector3(-0.32,0.83,0.05)], 0.035, "Lapel")
	_ribbon(rig, "BackShoulderStrap", [Vector3(-0.14,1.44,-0.09),Vector3(-0.10,1.33,-0.13),Vector3(-0.01,1.24,-0.143),Vector3(-0.13,1.04,-0.15),Vector3(-0.31,0.85,-0.12)], 0.035, "Lapel")
	for index in range(4):
		var scroll: Node3D = _joint(bag, "PaperRoll", Vector3(-0.075+index*0.045,0.13,-0.015+index%2*0.032))
		scroll.rotation.z = -0.18+index*0.10
		_loft(scroll, "RolledPaper", [[-0.09,0.019,0.019],[0.10+index%2*0.045,0.019,0.019]], "Paper", false, 12)
		var spiral: Array[Vector3] = []
		for step in range(27):
			var angle: float = TAU*step/12
			var radius: float = 0.018*(1-float(step)/30)
			spiral.append(Vector3(cos(angle)*radius,0.101+index%2*0.045,sin(angle)*radius))
		_pipe(scroll, "PaperSpiral", spiral, 0.0012, "PaperEdge", 4)
	var folio: MeshInstance3D = _box(bag, "RubbingFolio", Vector3(0.055,0.11,-0.015), Vector3(0.07,0.24,0.018), "PaperEdge")
	folio.rotation.z = -0.13
	for index in range(2):
		_pipe(bag, "ToolHandle", [Vector3(0.084-index*0.027,0.02,0.025),Vector3(0.11-index*0.029,0.25-index*0.02,0.025)], 0.007, "Bamboo")
	for side in [-1,1]:
		_pipe(bag, "DrawCord", [Vector3(side*0.11,0.10,0.06),Vector3(side*0.105,-0.04,0.10),Vector3(side*0.11,-0.10,0.085)], 0.003, "Cord")
		_sphere(bag, "CordKnot", Vector3(side*0.11,-0.1,0.085), Vector3(0.007,0.009,0.007), "Cord")
	for index in range(9):
		var x: float = -0.075+index*0.018
		_pipe(bag, "BagStitch", [Vector3(x,-0.15,0.085),Vector3(x+0.005,-0.145,0.087)], 0.0013, "Stitch", 4)


func _build_ornaments() -> void:
	ornaments = _joint(rig, "WaistOrnaments", Vector3(0.13,1.015,0.12))
	_pipe(ornaments, "PendantCord", [Vector3.ZERO,Vector3(0.012,-0.11,0.025),Vector3(0.015,-0.16,0.035)], 0.0028, "Cord")
	for index in range(3):
		_sphere(ornaments, "OldBead", Vector3(0.013,-0.055-index*0.025,0.027), Vector3(0.010,0.012,0.009), "Bronze")
	var jade := MeshInstance3D.new()
	jade.name = "OldJadeRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.012
	torus.outer_radius = 0.036
	torus.rings = 24
	torus.ring_segments = 8
	jade.mesh = torus
	jade.material_override = _materials.Jade
	jade.position = Vector3(0.015,-0.18,0.035)
	jade.rotation.x = PI/2
	jade.scale = Vector3(1,0.4,1)
	ornaments.add_child(jade)
	_pipe(ornaments, "InkTubeCord", [Vector3(0.045,0,0),Vector3(0.071,-0.12,0.02)], 0.003, "Cord")
	var tube: Node3D = _joint(ornaments, "InkTube", Vector3(0.075,-0.19,0.018))
	_loft(tube, "BambooTube", [[-0.075,0.017,0.017],[0.075,0.017,0.017]], "Bamboo", false, 12)
	for y in [-0.068,0.062]:
		_loft(tube, "TubeBand", [[y,0.019,0.019],[y+0.009,0.019,0.019]], "Bronze", false, 12)
	_pipe(ornaments, "Tassel", [Vector3(0.016,-0.217,0.035),Vector3(0.016,-0.29,0.035)], 0.004, "Cord")


func animate_model(delta: float, speed: float, grounded: bool, pushing: bool, carrying: bool, reading: bool = false) -> void:
	_elapsed += delta
	if speed > 0.15: _gait += delta * speed * 3.5
	pose(_elapsed, _gait, speed, grounded, pushing, carrying, reading)


func pose(time: float, gait: float, speed: float, grounded: bool, pushing: bool, carrying: bool, reading: bool = false) -> void:
	var moving: float = clampf(speed/3.0,0,1)
	var sway: float = sin(gait)*moving if grounded else 0
	rig.position.y = absf(sin(gait))*0.012*moving if grounded else 0
	skirt.rotation.z = sway*0.025
	skirt.rotation.x = -0.07 if not grounded else -0.018*moving
	head_rig.rotation = Vector3(0.12 if reading else sin(time*1.6)*0.012, sin(time*0.9)*0.018, -0.02+sway*0.012)
	for index in range(2):
		var side: float = 1 if index == 0 else -1
		legs[index].rotation.x = sway*0.40*side if grounded else (-0.28 if index == 0 else 0.34)
		knees[index].rotation.x = maxf(0,-sway*side)*0.50 if grounded else 0.65
		arms[index].rotation = Vector3(-0.8 if pushing else (-1.0 if carrying else (sway*0.04 if index == 0 else -sway*0.24)),0,side*0.12)
		forearms[index].rotation.x = -0.45 if pushing else (-0.75 if carrying else (-2.8 if index == 0 else -0.10))
		if reading and not pushing and not carrying:
			arms[index].rotation.x = -0.20 if index == 0 else -0.5
			forearms[index].rotation.x = -2.1 if index == 0 else -1.8
		if not ribbons.is_empty(): ribbons[index].rotation.x = sin(time*2.3+index)*0.035+sway*0.12
	bag.rotation.z = -0.04+sway*0.055
	bag.rotation.x = absf(sway)*0.05
	ornaments.rotation.z = sin(time*2.4)*0.018+sway*0.13
	var blink: float = fmod(time,4.7)
	eyes.scale.y = 0.08 if blink > 4.52 and blink < 4.65 else 1.0
	brush.visible = not pushing and not carrying
