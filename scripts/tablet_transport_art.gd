extends "res://scripts/environment_art.gd"

var chapter: Node3D
var inscription: MeshInstance3D


func setup(owner_chapter: Node3D) -> void:
	chapter = owner_chapter
	name = "BoundWoodenLitter"
	var stone: Material = _surface(Color(0.30, 0.34, 0.32), 0)
	var timber: Material = _surface(Color(0.30, 0.19, 0.10), 2)
	var cloth: Material = _surface(Color(0.28, 0.31, 0.24), 1)
	var hemp: Material = _flat(Color(0.66, 0.51, 0.30))
	chapter._tablet.mesh = _beveled_stone()
	chapter._tablet.material_override = stone
	for z in [-0.48, 0.48]:
		_box(self, Vector3(0, -0.27, z), Vector3(3.30, 0.13, 0.13), timber)
		for x in [-1.57, 1.57]:
			for turn in range(6):
				_box(self, Vector3(x + turn * 0.015, -0.27, z), Vector3(0.008, 0.15, 0.15), hemp)
	for x in [-0.78, 0, 0.78]:
		_box(self, Vector3(x, -0.23, 0), Vector3(0.24, 0.14, 1.04), timber)
		_box(self, Vector3(x, -0.125, 0), Vector3(0.26, 0.08, 0.91), cloth)
	for x in [-0.68, 0.68]:
		var path: Array[Vector3] = [Vector3(x, -0.35, -0.54), Vector3(x, -0.10, -0.54), Vector3(x, .17, -.43), Vector3(x, .17, .43), Vector3(x, -.10, .54), Vector3(x, -.35, .54), Vector3(x, -.35, -.54)]
		for side in [-0.013, 0.013]:
			for index in range(path.size() - 1):
				_rod(self, path[index] + Vector3(side, 0, 0), path[index + 1] + Vector3(side, 0, 0), .012, hemp)
		for knot in range(3):
			_rod(self, Vector3(x - .08, .18 + knot * .014, .28), Vector3(x + .08, .18 + knot * .014, .32), .016, hemp)
		_rod(self, Vector3(x, .19, .33), Vector3(x + .11, -.02, .48), .014, hemp)
	var face := PlaneMesh.new()
	face.size = Vector2(.71, 1.90)
	inscription = MeshInstance3D.new()
	inscription.name = "Inscription"
	inscription.mesh = face
	inscription.position.y = .146
	inscription.rotation.y = PI / 2
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://shaders/aged_inscription.gdshader")
	ink.set_shader_parameter("albedo_texture", chapter.first.inspector.images[0])
	inscription.material_override = ink
	add_child(inscription)


func _beveled_stone() -> ArrayMesh:
	var ring: Array[Vector2] = [Vector2(-.98, -.44), Vector2(.98, -.44), Vector2(1.08, -.34), Vector2(1.08, .34), Vector2(.98, .44), Vector2(-.98, .44), Vector2(-1.08, .34), Vector2(-1.08, -.34)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(8):
		var a := Vector3(ring[index].x, .14, ring[index].y)
		var b := Vector3(ring[(index + 1) % 8].x, .14, ring[(index + 1) % 8].y)
		var c := Vector3(b.x * 1.03, -.11, b.z * 1.03)
		var d := Vector3(a.x * 1.03, -.11, a.z * 1.03)
		for triangle in [[Vector3(0, .14, 0), b, a], [a, b, c], [a, c, d], [Vector3(0, -.11, 0), d, c]]:
			for vertex: Vector3 in triangle:
				surface.set_uv(Vector2(vertex.x, vertex.z))
				surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()
