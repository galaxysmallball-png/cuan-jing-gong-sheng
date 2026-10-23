extends SceneTree

# Headless geometry audit for the three scenes: where the triangles are,
# how many materials, and what lies below/behind the camera view.
# Read-only; writes nothing to the project.

var root_world: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(root_world)
	current_scene = root_world
	for i in range(20): await process_frame
	for ui in ["PartyUI", "NearbyInteractions", "StoryDialogue"]:
		var n: Node = root_world.get_node_or_null(ui)
		if n: n.visible = false
	await process_frame
	for space in root_world.get_node("Spaces").get_children():
		_audit_space(space)
	_audit_atmosphere(root_world.get_node("ConceptSceneAtmosphere"))
	_audit_total()
	quit(0)


func _audit_total() -> void:
	var tris: int = 0
	var nodes: int = 0
	var mats: Dictionary = {}
	var lights: int = 0
	for mi in root_world.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh:
			tris += mi.mesh.get_faces().size() / 3
			nodes += 1
			var key: String = _mat_key(mi)
			mats[key] = mats.get(key, 0) + 1
	lights = root_world.find_children("*", "OmniLight3D", true, false).size()
	print("TOTAL tris=", tris, " mesh_nodes=", nodes, " distinct_material_keys=", mats.size(), " omni_lights=", lights)
	var visible_lights: int = 0
	for l in root_world.find_children("*", "OmniLight3D", true, false):
		if l.is_visible_in_tree() and l.light_energy > 0.01: visible_lights += 1
	print("  lights actually contributing (energy>0.01): ", visible_lights)


func _audit_space(space: Node) -> void:
	print("##### ", space.name)
	var groups: Dictionary = {}
	var total: int = 0
	for mi in space.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null: continue
		var t: int = mi.mesh.get_faces().size() / 3
		total += t
		var key: String = _mat_key(mi)
		if not groups.has(key): groups[key] = [0, 0]
		groups[key][0] += 1
		groups[key][1] += t
	print("  tris=", total, " nodes=", space.find_children("*", "MeshInstance3D", true, false).size(), " material_keys=", groups.size())
	var keys: Array = groups.keys()
	keys.sort_custom(func(a, b): return groups[a][1] > groups[b][1])
	for k in keys.slice(0, 14):
		print("   ", k, " nodes=", groups[k][0], " tris=", groups[k][1])
	# vertical distribution: what is below the ground plane / far behind
	var below: int = 0
	var behind: int = 0
	for mi in space.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null: continue
		var t: int = mi.mesh.get_faces().size() / 3
		var p: Vector3 = _world_center(mi)
		if p.y < -0.99: below += t
		if p.z < -3.4: behind += t
	print("   tris with centre below y=-1.0: ", below, "   centre behind z<-3.4: ", behind)
	# named children of the space
	for c in space.get_children():
		print("   child: ", c.name, " (", c.get_class(), ")")


func _world_center(mi: MeshInstance3D) -> Vector3:
	var aabb: AABB = mi.get_aabb()
	return mi.global_transform * aabb.get_center()


func _mat_key(mi: MeshInstance3D) -> String:
	var m: Material = mi.material_override
	if m == null and mi.mesh and mi.mesh.get_surface_count() > 0:
		m = mi.mesh.surface_get_material(0)
	if m == null: return "none"
	if m is ShaderMaterial: return "shader:" + m.shader.resource_path.get_file()
	return "standard:" + str(m.get_instance_id())


func _audit_atmosphere(node: Node3D) -> void:
	print("##### ", node.name)
	var total: int = 0
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null: continue
		var t: int = mi.mesh.get_faces().size() / 3
		total += t
		print("   ", mi.name, " tris=", t, " pos=", mi.global_position, " mat=", _mat_key(mi))
	print("  atmosphere tris=", total)
	for child in node.get_children():
		print("  child: ", child.name, " (", child.get_class(), ") at ", (child as Node3D).position if child is Node3D else "")
