extends SceneTree

var viewport: SubViewport
var frames: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_MINIMIZED
	OS.low_processor_usage_mode = false
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var world: Node3D = load("res://scenes/world.tscn").instantiate()
	viewport.add_child(world)
	DirAccess.make_dir_recursive_absolute("res://previews/interface-movie-frames")
	for frame in range(3):
		await process_frame
		_save()
	var ui: CanvasLayer = world.get_node("PartyUI")
	ui.primary.pressed.emit()
	for frame in range(360):
		await process_frame
		_save()
		if ui.opening_draw.is_ready(): break
	if not ui.opening_draw.is_ready(): push_error("Draw did not finish"); quit(1); return
	for frame in range(45):
		await process_frame
		_save()
	ui.opening_draw.continue_button.pressed.emit()
	for frame in range(30):
		await process_frame
		_save()
	var file := FileAccess.open("res://previews/interface-movie-frames.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames": frames, "fps": 30, "width": 1280, "height": 720, "source": "actual Godot SubViewport frames"}))
	file.close()
	print("INTERFACE_MOVIE_FRAMES_OK ", frames)
	quit(0)


func _save() -> void:
	RenderingServer.force_draw(false)
	var picture: Image = viewport.get_texture().get_image()
	if picture == null or picture.is_empty() or picture.save_jpg("res://previews/interface-movie-frames/frame-%04d.jpg" % frames, 0.94) != OK:
		push_error("Could not save an actual movie frame")
		quit(1)
		return
	frames += 1
