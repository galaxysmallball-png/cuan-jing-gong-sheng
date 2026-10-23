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
	create_timer(300,true).timeout.connect(func():
		if not check_done: _fail("Celebration reward checks timed out"))
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
	var rewards: Node3D=world.celebration_rewards
	if rewards.button.visible or not rewards.footprints.is_empty(): _fail("Rewards are unlocked at the fresh start"); return
	for i in range(4):
		if i>=2:
			first.observed=true
			first.gate_open=true
			first.get_node("Gate").position.y=8
		var slot: int=party.owner_of(i)
		party.switch_to(i,slot)
		var at: Vector3=world.keepsakes.POSITIONS[i]
		await _put(at.x-.15,at.x+.15)
		await _quiet()
		var pickup: Node3D=world.keepsakes.pickups[i]
		var glow: Node3D=pickup.get_node("KeepsakeGuidingLight")
		if not glow.is_visible_in_tree() or glow.find_children("*","OmniLight3D",true,false).is_empty() or world.keepsakes.labels[i].visible:
			_fail("Uncollected keepsake has no guiding glow / retains an idle name"); return
		if i==0: _save_coop("reward-keepsake-glow")
		if not world.keepsakes.collect(i,party.human_players()[slot]) or glow.is_visible_in_tree(): _fail("Glow survives collection / correct owner cannot collect"); return
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	court._raise_tablet()
	await _frames(ceili(court.RAISE_SECONDS*60)+8)
	await _put(48.4,49.0)
	await _quiet()
	world.folk.open_item("flint_pouch")
	await _frames(8)
	var folk: CanvasLayer=world.folk
	var body: MeshInstance3D=folk.preview_model.get_node("GatheredClothBody")
	if body.mesh.get_faces().size()<12000 or folk.preview_model.get_node_or_null("RaisedEmbroideryAndSeams")==null or folk.preview_model.get_node_or_null("BraidedDrawstringsAndRolledHem")==null:
		_fail("Pouch does not use the refined gathered cloth / embroidery / braid model"); return
	_save_coop("reward-flint-pouch-detail")
	folk.preview_model.rotation.y=.62
	await _frames(5)
	_save_coop("reward-flint-pouch-side")
	folk.close()
	await _quiet()
	# Clearing the story and collecting everything are independent reward gates.
	Input.action_press("move_right")
	await _frames(24)
	Input.action_release("move_right")
	if rewards.flower_count>0: _fail("Footflowers appear before clearing the game"); return
	var book: CanvasLayer=world.achievements
	var keys: Array=book.Content.ITEMS.keys()
	for i in range(keys.size()-1): book.record_item(keys[i])
	await _frames(4)
	if rewards.button.visible: _fail("Firework button appears before all achievements"); return
	book.record_item(keys[-1])
	await _frames(150)
	await _quiet()
	var egg: Node=court.landscape.collection_reward
	if not egg.complete or not rewards.button.visible or egg.glow_light.light_energy<.9 or float(egg.aura_material.get_shader_parameter("strength"))<.5:
		_fail("Full collection does not reveal the luminous stele and firework button"); return
	if not ui.blocks_world_click(rewards.button.get_global_rect().get_center()): _fail("Firework button clicks through to scenery"); return
	_save_coop("reward-glowing-stele-and-button")
	ui._open_satchel()
	await _frames(4)
	rewards.launch_fireworks()
	if rewards.button.visible or rewards.fireworks.launched!=0: _fail("Fireworks can be launched behind a modal"); return
	ui._close_satchel()
	await _frames(4)
	# Route real firework audio into a capture bus, excluding music and ambience.
	world.music.muted=true
	world.sfx.ambience.stop()
	for audio in world.sfx.players: audio.stop()
	AudioServer.add_bus()
	var bus: int=AudioServer.bus_count-1
	AudioServer.set_bus_name(bus,"FireworkProof")
	var sound_capture:=AudioEffectCapture.new()
	sound_capture.buffer_length=3.0
	AudioServer.add_bus_effect(bus,sound_capture)
	for audio in world.sfx.players: audio.bus="FireworkProof"
	await _click_at(rewards.button.get_global_rect().get_center())
	for frame in range(75):
		await process_frame
		OS.delay_msec(16)
	if rewards.fireworks.launched!=1 or rewards.fireworks.used<80 or rewards.fireworks.burst_sounds<2 or not "firework_launch" in world.sfx.events or not "firework_burst" in world.sfx.events:
		_fail("Actual firework click fails to launch a multicolour burst and matching sounds"); return
	var samples: PackedVector2Array=sound_capture.get_buffer(sound_capture.get_frames_available())
	var peak: float=0
	for sample in samples: peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	if peak<.005: _fail("Firework audio produces no actual mixed samples"); return
	print("FIREWORK_AUDIO_MIX_OK peak=",peak," frames=",samples.size())
	_save_coop("reward-player-fireworks")
	rewards.launch_fireworks()
	if rewards.fireworks.launched!=1: _fail("Firework cooldown allows repeated stacking"); return
	await _frames(200)
	world.sfx.toggle_mute()
	var audible: int=world.sfx.events.count("firework_launch")+world.sfx.events.count("firework_burst")
	await _click_at(rewards.button.get_global_rect().get_center())
	await _frames(80)
	if rewards.fireworks.launched!=2 or world.sfx.events.count("firework_launch")+world.sfx.events.count("firework_burst")!=audible:
		_fail("Muted fireworks do not preserve visual launch / silence audio"); return
	world.sfx.toggle_mute()
	for audio in world.sfx.players: audio.bus="Master"
	AudioServer.remove_bus(bus)
	court.court_lit=true
	world.ending_reached=true
	await _put(51.1,51.9)
	await _quiet()
	Input.action_press("move_right")
	Input.action_press("p2_move_right")
	await _frames(64)
	Input.action_release("move_right")
	Input.action_release("p2_move_right")
	if rewards.footprints.size()<6 or rewards.footprints.size()>rewards.TRAIL_CAPACITY:
		_fail("Cleared-party walking does not leave bounded coloured flower steps"); return
	_save_coop("reward-rainbow-footflowers")
	await _frames(360)
	if not rewards.footprints.is_empty(): _fail("Footflowers do not fade after the party stops"); return
	await _tap("restart_lesson")
	await _frames(5)
	if rewards.button.visible or rewards.fireworks.used!=0 or not rewards.footprints.is_empty() or egg.complete:
		_fail("New journey retains completion effects / firework controls"); return
	for i in range(4):
		if not world.keepsakes.pickups[i].get_node("KeepsakeGuidingLight").is_visible_in_tree(): _fail("New journey fails to restore pickup glows"); return
	check_done=true
	print("CELEBRATION_REWARDS_OK: four owner-only pickups glow then hide/reset, detailed woven pouch, luminous collected stele, real right-bottom firework click / sound mix / mute / cooldown / modal guard, cleared-game walking flowers / fading / fixed pool, new-journey cleanup")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	quit(0)

func _quiet() -> void:
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	world.story.frame.visible=false
	await _frames(8)

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
func _click_at(at: Vector2) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=at
		event.global_position=at
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		world.get_viewport().push_input(event,true)
		await _frames(2)
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
