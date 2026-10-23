extends RefCounted

static var LETTERING: Font = preload("res://scripts/interface_skin.gd").heading_font()


static func plaque(parent: Node3D, at: Vector3, words: String, size: Vector2, arrow: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "Plaque_" + words
	root.position = at
	parent.add_child(root)
	root.add_to_group("world_plaques")
	root.set_meta("title", words)
	_box(root, Vector3.ZERO, Vector3(size.x, size.y, 0.12), Color(0.12, 0.17, 0.16))
	_box(root, Vector3(0, 0, 0.067), Vector3(size.x - 0.09, size.y - 0.08, 0.022), Color(0.075, 0.105, 0.10))
	var edge := Color(0.58, 0.40, 0.19)
	for side in [-1, 1]:
		_box(root, Vector3(0, side * (size.y / 2 - 0.035), 0.085), Vector3(size.x - 0.045, 0.018, 0.018), edge)
		_box(root, Vector3(side * (size.x / 2 - 0.035), 0, 0.085), Vector3(0.018, size.y - 0.045, 0.018), edge)
		for y in [-1, 1]:
			_box(root, Vector3(side * (size.x / 2 - 0.065), y * (size.y / 2 - 0.065), 0.10), Vector3(0.025, 0.025, 0.014), Color(0.83, 0.65, 0.30))
	var label := Label3D.new()
	label.name = "Lettering"
	label.text = words
	label.font = LETTERING
	label.font_size = 80
	label.pixel_size = minf(size.y * 0.84 / 80, size.x * 0.89 / (80 * words.length()))
	label.position.z = 0.105
	label.modulate = Color(0.95, 0.80, 0.48)
	label.outline_size = 0
	root.add_child(label)
	if arrow != 0:
		var direction := Label3D.new()
		direction.text = "›" if arrow > 0 else "‹"
		direction.font = LETTERING
		direction.font_size = 42
		direction.pixel_size = 0.004
		direction.position = Vector3(arrow * (size.x / 2 - 0.12), 0, 0.11)
		direction.modulate = label.modulate
		root.add_child(direction)
	return root


static func _box(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override = material
	parent.add_child(node)
