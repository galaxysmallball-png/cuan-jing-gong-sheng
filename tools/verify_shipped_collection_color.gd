extends SceneTree
var world: Node3D
var party: Node3D
var player: CharacterBody3D
var second: CharacterBody3D
var first: Node3D
var bridge: Node3D
var court: Node3D
var ui: CanvasLayer
var nearby_ui: CanvasLayer
var capture: bool
var capture_viewport: SubViewport

var check_done: bool=false

func _initialize() -> void:
	capture=true
	create_timer(120,true).timeout.connect(func():
		if not check_done: _fail("Collection colour check timed out"))
	call_deferred("_run")

func _run() -> void:
	root.mode=Window.MODE_MINIMIZED
	capture_viewport=SubViewport.new()
	capture_viewport.size=Vector2i(1280,720)
	capture_viewport.own_world_3d=true
	capture_viewport.msaa_3d=Viewport.MSAA_4X
	capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	world=load("res://scenes/world.tscn").instantiate()
	capture_viewport.add_child(world)
	party=world.party
	player=party.player
	second=party.second_player
	first=world.cooperation
	bridge=world.bridge
	court=world.courtyard
	ui=world.get_node("PartyUI")
	nearby_ui=world.get_node("NearbyInteractions")
	await _frames(12)
	await _start_default_party()
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	court._raise_tablet()
	await _frames(ceili(court.RAISE_SECONDS*60)+8)
	await _put(46.4,46.0)
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	await _frames(5)
	world.set_process(false)
	world.camera.size=4.4
	world.camera.position=Vector3(50,3.8,16)
	world.camera.look_at(Vector3(50,2.0,-1.8),Vector3.UP)
	await _frames(8)
	var reward: Node=court.landscape.collection_reward
	var book: CanvasLayer=world.achievements
	var keys: Array=book.Content.ITEMS.keys()
	for i in range(keys.size()-1): book.record_item(keys[i])
	await _frames(8)
	if reward.complete or reward.amount!=0 or book.unlocked.size()>=book.Content.BADGES.size():
		_fail("Color egg unlocks before the last achievement"); return
	_save_coop("collection-egg-stone-before")
	book.record_item(keys[-1])
	if not reward.complete or book.unlocked.size()!=8: _fail("Collecting all eight achievements does not reveal the color egg"); return
	await _frames(35)
	if reward.amount<=0 or reward.amount>=1: _fail("Color reward does not reveal gradually"); return
	paused=true
	var mid: float=reward.amount
	for i in range(8): await process_frame
	if reward.amount!=mid: _fail("Color reveal moves behind a paused modal"); return
	paused=false
	await _frames(150)
	for material: ShaderMaterial in reward.materials:
		if float(material.get_shader_parameter("collection_color_amount"))<.999: _fail("Stone body and inscription do not both change colour"); return
	var small: MeshInstance3D=first.get_node("SmallPanel")
	if small.material_override.get_shader_parameter("collection_color_amount") not in [null,0.0]:
		_fail("Color egg changes unrelated scenery or the original stele"); return
	_save_coop("collection-egg-stone-after")
	if not reward.inlay.visible or reward.inlay.get_child_count()<15 or reward.motes.multimesh.instance_count!=18:
		_fail("Completed colour egg lacks its gold inlay and seven pigment settings"); return
	# Each material reverts immediately on a new journey, with all existing reset rules.
	world.set_process(true)
	await _tap("restart_lesson")
	await _frames(5)
	if reward.complete or reward.amount!=0 or not book.unlocked.is_empty(): _fail("New journey retains the secret colour state"); return
	for material: ShaderMaterial in reward.materials:
		if float(material.get_shader_parameter("collection_color_amount"))!=0: _fail("New journey leaves pigment on the inscription"); return
	if reward.inlay.visible: _fail("New journey leaves the secret gold inlay visible"); return
	check_done=true
	print("COLLECTION_COLOR_EGG_OK: 20 items do not trigger, all 21 / eight achievements reveal seven colours on body and inscription, gradual pause-safe reveal, original scenery unchanged, new journey restores stone")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	quit(0)

func _frames(count: int) -> void:
	for i in range(count): await physics_frame
func _start_default_party() -> void:
	world.chapter_films.enabled=false
	ui._begin_game()
	ui._refresh()
	await _frames(4)
func _put(x1: float,x2: float) -> void:
	player.global_position=Vector3(x1,.75,0)
	second.global_position=Vector3(x2,.75,0)
	player.velocity=Vector3.ZERO
	second.velocity=Vector3.ZERO
	world._update_camera(0,true)
	await _frames(5)
func _tap(action: String) -> void:
	Input.action_press(action)
	for i in range(3): await process_frame
	Input.action_release(action)
	await process_frame
func _save_coop(stage: String) -> void:
	RenderingServer.force_draw(false)
	var folder: String=OS.get_cmdline_user_args()[0]
	capture_viewport.get_texture().get_image().save_png(folder.path_join("shipped-"+stage+".png"))
func _stop_test_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D: node.stop()
	for child in node.get_children(): _stop_test_audio(child)
func _drain_test_audio() -> void:
	for i in range(4): await process_frame
func _fail(message: String) -> void:
	paused=false
	push_error(message)
	quit(1)
