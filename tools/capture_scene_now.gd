extends SceneTree

# GPU capture of the three acts at play resolution, for before/after comparison
# against the concept boards. Writes to res://previews/scene-compare-2026-10-18/.
# Run with a normal (non-headless) window; the SubViewport path used by
# verify_*.gd crashes this Godot build on GL, so capture the root viewport.

const OUT := "res://previews/scene-compare-2026-10-18/"
const SHOTS := [
	{"name": "now-act1-court", "x": 9.5},
	{"name": "now-act1-exit", "x": 15.6},
	{"name": "now-act2-creek", "x": 29.5},
	{"name": "now-act2-waterfall", "x": 36.4},
	{"name": "now-act3-court", "x": 49.6},
	{"name": "now-act3-facade", "x": 52.4},
]

var world: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	print("step: loading world")
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	print("step: world added")
	for i in range(50):
		await process_frame
	print("step: frames done")
	await _tap("ui_accept")
	await _tap("skip_intro")
	await _tap("ui_accept")
	print("step: intro skipped")
	world.party.reset_positions(true)
	await _frames(10)
	world.get_node("PartyUI").visible = false
	world.get_node("NearbyInteractions").visible = false
	await _frames(6)
	print("step: ui hidden, shooting")
	for shot in SHOTS:
		await _shoot(shot)
	print("SCENE_CAPTURE_OK: ", SHOTS.size(), " frames -> ", OUT)
	quit(0)


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(4)
	Input.action_release(action)
	await _frames(4)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _shoot(shot: Dictionary) -> void:
	var x: float = shot["x"]
	world.party.player.global_position = Vector3(x, 1.0, 0)
	world.party.second_player.global_position = Vector3(x - 1.2, 1.0, 0)
	world.party.player.velocity = Vector3.ZERO
	world.party.second_player.velocity = Vector3.ZERO
	world._update_camera(0, true)
	await _frames(12)
	RenderingServer.force_draw(false)
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("empty capture: " + str(shot["name"]))
		return
	img.save_png(OUT + str(shot["name"]) + ".png")
	print("saved ", shot["name"])
