extends SceneTree

# Read-only probe: find every emissive/orange mesh whose visible radius is far
# larger than a flame (the concept boards show soft glows, not solid hexagons).


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in range(40):
		await process_frame
	for space_name in ["Spaces/Space01", "Spaces/Space02", "Spaces/Space03"]:
		var space: Node = world.get_node_or_null(space_name)
		if space: space.visible = true
	for i in range(5):
		await process_frame
	var hits: int = 0
	for node in world.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node
		if mi.mesh == null: continue
		var aabb: AABB = mi.mesh.get_aabb()
		var s: Vector3 = mi.global_transform.basis.get_scale().abs()
		var size: Vector3 = Vector3(absf(aabb.size.x) * s.x, absf(aabb.size.y) * s.y, absf(aabb.size.z) * s.z)
		var extent: float = maxf(size.x, maxf(size.y, size.z))
		var mat: Material = mi.material_override
		var col := Color(0, 0, 0)
		var emissive: bool = false
		if mat is StandardMaterial3D:
			col = (mat as StandardMaterial3D).albedo_color
			emissive = (mat as StandardMaterial3D).emission_enabled
		elif mat is ShaderMaterial:
			var v: Variant = (mat as ShaderMaterial).get_shader_parameter("color")
			if v is Color: col = v
			else:
				v = (mat as ShaderMaterial).get_shader_parameter("tint")
				if v is Color: col = v
		var orange: bool = col.r > .75 and col.g > .35 and col.g < .85 and col.b < .35
		if not orange: continue
		if extent < .45: continue
		if hits < 25:
			print("BIG_ORANGE  ext=%.2f  size=%s  path=%s  mesh=%s  mat=%s" % [extent, str(size), str(world.get_path_to(mi)), mi.mesh.get_class(), ("std" if mat is StandardMaterial3D else ("shader:" + mat.resource_path.get_file() if mat is ShaderMaterial else "null"))])
		hits += 1
	print("BIG_ORANGE_TOTAL=", hits)
	quit(0)
