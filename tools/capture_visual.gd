extends SceneTree

# Captures the game's own rendered viewport, not the user's desktop.
# Requires a real renderer; intentionally refuses dummy/headless rendering.
func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual capture requires a real graphics renderer")
		quit(1)
		return
	root.mode = Window.MODE_MINIMIZED
	OS.low_processor_usage_mode = false
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var world: Node3D = load("res://scenes/world.tscn").instantiate()
	viewport.add_child(world)
	var prefix: String = "lesson05"
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if not arguments.is_empty():
		prefix = arguments[0].validate_filename()
	DirAccess.make_dir_recursive_absolute("res://previews")
	world.get_node("Guide").visible = false
	for frame in range(40):
		await process_frame
	await _save(viewport, prefix + "-entry.png")
	var player: CharacterBody3D = world.get_node("Player")
	player.global_position = Vector3(6.0, 0.8, 0.0)
	for frame in range(30):
		await physics_frame
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for frame in range(180):
		await physics_frame
	player.global_position = Vector3(13.5, 0.8, 0.0)
	for frame in range(60):
		await physics_frame
	await _save(viewport, prefix + "-observation.png")
	print("VISUAL_CAPTURE_OK: real viewport, entry and partner-lit observation")
	quit(0)


func _save(viewport: SubViewport, filename: String) -> void:
	# Explicitly draw the offscreen viewport even when the helper window is minimized.
	RenderingServer.force_draw(false)
	var rendered: Image = viewport.get_texture().get_image()
	if rendered == null or rendered.is_empty():
		push_error("Renderer returned no image")
		quit(1)
		return
	var error: Error = rendered.save_png("res://previews/" + filename)
	if error != OK:
		push_error("Could not save visual preview: %s" % error)
		quit(1)
