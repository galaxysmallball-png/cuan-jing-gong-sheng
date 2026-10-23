extends RefCounted

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, title: String = "") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	node.material_override = material
	parent.add_child(node)
	if not title.is_empty():
		label(node, Vector3(0, size.y / 2.0 + 0.3, 0.1), title)
	return node


static func label(parent: Node3D, at: Vector3, text: String) -> Label3D:
	var node := Label3D.new()
	node.position = at
	node.text = text
	node.font_size = preload("res://scripts/interface_skin.gd").text_size(28)
	node.pixel_size = 0.005

	node.font = preload("res://scripts/interface_skin.gd").heading_font()
	parent.add_child(node)
	return node


static func marker(parent: Node3D, x: float, text: String) -> MeshInstance3D:
	return box(parent, Vector3(x, 0.025, 0.2), Vector3(1.1, 0.035, 0.65), Color(0.25, 0.5, 0.57), text)
