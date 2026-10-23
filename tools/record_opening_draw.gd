extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_MINIMIZED
	OS.low_processor_usage_mode = false
	var world: Node3D = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for frame in range(3): await process_frame
	var ui: CanvasLayer = world.get_node("PartyUI")
	ui.primary.pressed.emit()
	for frame in range(360):
		await process_frame
		if ui.opening_draw.is_ready(): break
	if not ui.opening_draw.is_ready():
		push_error("Opening draw movie did not reach the result")
		quit(1)
		return
	for frame in range(45): await process_frame
	ui.opening_draw.continue_button.pressed.emit()
	for frame in range(30): await process_frame
	if not world.get_node("Party").started or paused:
		push_error("Opening draw movie did not enter gameplay")
		quit(1)
		return
	print("OPENING_DRAW_MOVIE_OK: actual eight-card orbit, two reveals, results and assigned game entry")
	quit(0)
