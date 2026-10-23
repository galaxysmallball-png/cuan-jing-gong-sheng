extends "res://scripts/environment_art.gd"


func build(parent: Node3D) -> void:
	var bamboo := ShaderMaterial.new()
	bamboo.shader = preload("res://shaders/bamboo_fiber.gdshader")
	var cut: Material = _surface(Color(.65, .46, .23), 1)
	var paper: Material = _surface(Color(.86, .79, .62), 1)
	var paper_edge: Material = _flat(Color(.58, .48, .32))
	var wood: Material = _surface(Color(.18, .09, .035), 2)
	var ink: Material = _flat(Color(.09, .095, .085))
	var cord: Material = _flat(Color(.43, .16, .10))
	var pot := Node3D.new()
	pot.name = "HollowBambooTube"
	pot.position = Vector3(-.32, .45, 0)
	parent.add_child(pot)
	_tube(pot, .245, .211, .67, bamboo, cut)
	for height in [-.28, .27]: _band(pot, Vector3(0, height, 0), .247, .011, cut)
	for index in range(3):
		var scroll := Node3D.new()
		scroll.name = "TiedPaperScroll_%d" % index
		scroll.position = Vector3(-.135 + index * .12, .57 + (index % 2) * .10, -.02 + sin(index * 2.0) * .09)
		scroll.rotation.z = -.10 + index * .11
		pot.add_child(scroll)
		_tube(scroll, .045 + index * .005, .017, .94 + index * .06, paper, paper_edge)
		_rod(scroll, Vector3(0, -.55, 0), Vector3(0, .57 + index * .03, 0), .012, wood)
		for y in [-.34, .32]: _band(scroll, Vector3(0, y, 0), .049 + index * .005, .006, cord)
	for index in range(2):
		var foot := Vector3(-.23 + index * .09, .38, .09)
		var tip := Vector3(-.13 + index * .14, 1.21, .11)
		_rod(parent, foot, tip, .011, wood)
		_rod(parent, tip, tip + Vector3(.013, .14, 0), .017, ink)
	# A sewn travelling satchel has depth, folds, ties and a looped shoulder strap.
	var cloth: Material = _surface(Color(.065, .12, .18), 1)
	var bag := MeshInstance3D.new()
	bag.name = "IndigoRubbingSatchel"
	var sphere := SphereMesh.new()
	sphere.radius = .33
	sphere.height = .66
	sphere.radial_segments = 32
	sphere.rings = 16
	bag.mesh = sphere
	bag.position = Vector3(.35, .32, .02)
	bag.scale = Vector3(1, .90, .65)
	bag.material_override = cloth
	parent.add_child(bag)
	_box(parent, Vector3(.35, .43, .16), Vector3(.51, .20, .075), cloth)
	for side in [-1, 1]:
		for i in range(12):
			var y: float = .14 + i * .028
			_rod(parent, Vector3(.35 + side * .245, y, .14), Vector3(.35 + side * .255, y + .011, .16), .003, cut)
	for i in range(25):
		var a: float = PI * i / 25
		var b: float = PI * (i + 1) / 25
		_rod(parent, Vector3(.35 + cos(a) * .25, .47 + sin(a) * .40, -.015), Vector3(.35 + cos(b) * .25, .47 + sin(b) * .40, -.015), .020, cloth)
	_rod(parent, Vector3(.23, .48, .22), Vector3(.43, .31, .24), .009, cord)
	_rod(parent, Vector3(.46, .48, .22), Vector3(.25, .30, .24), .009, cord)
	_box(parent, Vector3(.09, .075, .38), Vector3(.35, .09, .22), ink)
	_box(parent, Vector3(.09, .126, .38), Vector3(.24, .008, .12), _flat(Color(.025, .03, .028)))
	for i in range(2):
		var book := _box(parent, Vector3(.47, .085 + i * .065, .38), Vector3(.32, .055, .23), paper)
		book.rotation.y = -.13 + i * .2
		_box(book, Vector3(0, .029, 0), Vector3(.335, .008, .24), cloth)
		for j in range(3): _rod(book, Vector3(-.13, .035, -.08 + j * .07), Vector3(-.13, -.03, -.08 + j * .07), .004, cut)


func _tube(parent: Node3D, radius: float, inside: float, height: float, outer_material: Material, edge_material: Material) -> void:
	var surfaces: Array[SurfaceTool] = []
	for i in range(2):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		surfaces.append(st)
	for i in range(64):
		var a: float = TAU * i / 64
		var b: float = TAU * (i + 1) / 64
		var o0 := Vector3(cos(a) * radius, -height / 2, sin(a) * radius)
		var o1 := Vector3(cos(b) * radius, -height / 2, sin(b) * radius)
		var t0 := o0 + Vector3(0, height, 0)
		var t1 := o1 + Vector3(0, height, 0)
		var n0 := Vector3(cos(a) * inside, height / 2, sin(a) * inside)
		var n1 := Vector3(cos(b) * inside, height / 2, sin(b) * inside)
		for triangle in [[o0, t0, t1], [o0, t1, o1]]:
			for point: Vector3 in triangle: surfaces[0].add_vertex(point)
		for triangle in [[t0, n0, n1], [t0, n1, t1], [n0, n0 - Vector3(0, height - .015, 0), n1 - Vector3(0, height - .015, 0)], [n0, n1 - Vector3(0, height - .015, 0), n1]]:
			for point: Vector3 in triangle: surfaces[1].add_vertex(point)
	for i in range(2):
		surfaces[i].generate_normals()
		var node := MeshInstance3D.new()
		node.mesh = surfaces[i].commit()
		node.material_override = outer_material if i == 0 else edge_material
		parent.add_child(node)


func _band(parent: Node3D, at: Vector3, radius: float, thickness: float, material: Material) -> void:
	var node := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius + thickness
	torus.rings = 64
	torus.ring_segments = 8
	node.mesh = torus
	node.position = at
	node.material_override = material
	parent.add_child(node)
