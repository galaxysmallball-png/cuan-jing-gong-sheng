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


const MobilePlatform=preload("res://scripts/mobile_platform.gd")

func _initialize() -> void:
	capture=true
	call_deferred("_run")

func _run() -> void:
	root.mode=Window.MODE_MINIMIZED
	capture_viewport=SubViewport.new()
	capture_viewport.size=Vector2i(1280,720)
	capture_viewport.own_world_3d=true
	capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	for dual in [false,true]:
		var watchdog:=create_timer(120,true)
		var timeout_callback: Callable=func(): _fail("Android touch checks timed out")
		watchdog.timeout.connect(timeout_callback)
		MobilePlatform.cooperative=dual
		world=load("res://scenes/world.tscn").instantiate()
		capture_viewport.add_child(world)
		world.chapter_films.enabled=false
		party=world.party
		player=party.player
		second=party.second_player
		first=world.cooperation
		bridge=world.bridge
		court=world.courtyard
		ui=world.get_node("PartyUI")
		nearby_ui=world.get_node("NearbyInteractions")
		await _frames(10)
		if world.mobile_controls==null or quit_on_go_back or party.local_coop!=dual or party.all_bodies().size()!=4:
			_fail("Android mode does not initialize four characters / touch controls"); return
		if nearby_ui.idle_names.size()!=2 or world.celebration_rewards.fireworks.CAPACITY!=12000 or world.courtyard.landscape.collection_reward.glow_light==null:
			_fail("Android package does not contain the current guidance and celebration systems"); return
		ui._begin_game()
		ui._refresh()
		await _frames(8)
		var mobile: CanvasLayer=world.mobile_controls
		for dialogue in range(8):
			if not world.story.frame.visible: break
			if not mobile.controls.is_empty(): _fail("Touch controls cover the opening dialogue"); return
			await _click_at(world.story.next_button.get_global_rect().get_center())
		await _frames(4)
		if mobile.context!="walking": _fail("Opening dialogue cannot resume touch walking"); return
		var firework_rect: Rect2=world.celebration_rewards.button.get_global_rect()
		for sample in [firework_rect.get_center(),firework_rect.position+Vector2(4,4),firework_rect.end-Vector2(4,4)]:
			if mobile.blocks(sample): _fail("Touch pads overlap the firework button"); return
		var start: float=player.position.x
		await _touch(0,_control(mobile,"stick",0).at+Vector2(65,0),true)
		await _touch(1,_control(mobile,"interact",0).at,true)
		await _frames(45)
		if player.position.x<start+1 or not Input.is_action_pressed("interact"):
			_fail("Multi-touch cannot move and hold operation together"); return
		await _touch(1,Vector2.ZERO,false)
		if Input.is_action_pressed("interact") or not Input.is_action_pressed("move_right"):
			_fail("Releasing one touch cancels another finger"); return
		if dual:
			await _touch(2,_control(mobile,"stick",1).at-Vector2(55,0),true)
			await _touch(3,_control(mobile,"interact",1).at,true)
			await _frames(12)
			if not Input.is_action_pressed("p2_move_left") or not Input.is_action_pressed("p2_interact") or Input.is_action_pressed("interact"):
				_fail("Dual-screen fingers are not independently routed"); return
			await _touch(2,Vector2.ZERO,false)
			await _touch(3,Vector2.ZERO,false)
		await _touch(0,Vector2.ZERO,false)
		var role: int=party.active_id
		await _touch(4,_control(mobile,"cycle",0).at,true)
		await _touch(4,Vector2.ZERO,false)
		if role==party.active_id: _fail("Touch role switching fails"); return
		await _frames(35)
		if world.story.frame.visible and not mobile.controls.is_empty(): _fail("Touch pads cover the dialogue"); return
		if world.story.frame.visible: _save_coop("android-touch-dialogue")
		for dialogue in range(8):
			if not world.story.frame.visible: break
			await _click_at(world.story.next_button.get_global_rect().get_center())
		await _frames(4)
		if mobile.context!="walking" or mobile.controls.is_empty() or world.experience.coach.visible or world.experience.coach_tab.visible:
			_fail("Touch controls fail to return / duplicated keyboard guide remains"); return
		_save_coop("android-touch-dual" if dual else "android-touch-single")
		await _touch(5,_control(mobile,"stick",0).at+Vector2(40,0),true)
		ui._open_satchel()
		await _frames(3)
		if Input.is_action_pressed("move_right") or not mobile.controls.is_empty():
			_fail("Touch movement sticks after opening a modal"); return
		ui._close_satchel()
		await _frames(3)
		mobile._notification(NOTIFICATION_APPLICATION_PAUSED)
		await _frames(3)
		if not paused or ui.screen!=ui.Screen.ARCHIVE:
			_fail("Backgrounding does not pause the Android game"); return
		ui._close_archive()
		await _frames(3)
		mobile._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		if ui.screen!=ui.Screen.HELP: _fail("Android back does not open help/pause"); return
		mobile._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await _frames(3)
		if paused or ui.screen!=ui.Screen.GAME: _fail("Android back cannot resume game"); return
		for slot_index in range(party.human_players().size()):
			var actor: CharacterBody3D=party.human_players()[slot_index]
			actor.global_position=Vector3(12.25 if slot_index==0 else 14.75,.75,0)
			actor.velocity=Vector3.ZERO
		world._update_camera(0,true)
		await _frames(5)
		nearby_ui.pinned.assign(["stele_0","stele_1"])
		await _frames(5)
		for slot_index in range(party.human_players().size()):
			if not nearby_ui.cards[slot_index].visible or not nearby_ui.tails[slot_index].visible or not nearby_ui.arrowheads[slot_index].visible:
				_fail("Mobile non-pickup card / line / arrow missing"); return
		_save_coop("android-nonpickup-guidance-dual" if dual else "android-nonpickup-guidance-single")
		var scroll_lines: Array[String]=[]
		court.show_record(scroll_lines)
		court.landscape.turn_record(1)
		for page in range(court.landscape.record_last_page()): court.landscape.turn_record(1)
		await _frames(6)
		if court.landscape.record_art.texture.resource_path!="res://assets/story/scroll_lights_single_taiwan_20261022.png":
			_fail("Android final scroll artwork was not updated"); return
		_save_coop("android-scroll-final-single-taiwan")
		court.close_record(false)
		print("ANDROID_SCROLL_AND_NONPICKUP_GUIDANCE_OK dual=",dual)
		watchdog.timeout.disconnect(timeout_callback)
		_stop_test_audio(world)
		world.queue_free()
		await process_frame
		await process_frame
		await _drain_test_audio()
	MobilePlatform.cooperative=false
	var launcher: Texture2D=load("res://assets/interface/user_launcher_20261021.png")
	if launcher==null or launcher.get_size()!=Vector2(1254,1254): _fail("User launcher icon missing / altered"); return
	print("ANDROID_TOUCH_OK: real ScreenTouch routing, single and dual modes, four roles, concurrent stick/hold, independent release, role switching, modal/background release, Android back")
	quit(0)

func _save_launcher_icon() -> void:
	var icon:=SubViewport.new()
	icon.size=Vector2i(512,512)
	icon.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(icon)
	var paper:=TextureRect.new()
	paper.texture=load("res://assets/interface/parcel_paper.png")
	paper.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	paper.size=Vector2(512,512)
	icon.add_child(paper)
	for item in [["爨",Vector2(20,8),Vector2(472,360),300],["共 生",Vector2(30,360),Vector2(452,120),80]]:
		var text:=Label.new()
		text.text=item[0]
		text.position=item[1]
		text.size=item[2]
		text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		text.add_theme_font_override("font",preload("res://scripts/interface_skin.gd").heading_font())
		text.add_theme_font_size_override("font_size",item[3])
		text.add_theme_color_override("font_color",Color(.52,.19,.13))
		icon.add_child(text)
	await _frames(4)
	RenderingServer.force_draw(false)
	icon.get_texture().get_image().save_png("res://assets/interface/android_launcher.png")
	icon.queue_free()

func _control(mobile: CanvasLayer,kind: String,slot: int) -> Dictionary:
	for control in mobile.controls:
		if control.kind==kind and control.slot==slot: return control
	return {}

func _touch(index: int,at: Vector2,pressed: bool) -> void:
	var event:=InputEventScreenTouch.new()
	event.index=index
	event.position=at
	event.pressed=pressed
	capture_viewport.push_input(event)
	await _frames(2)

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
