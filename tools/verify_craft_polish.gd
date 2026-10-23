extends "res://tools/verify_photo_guide.gd"

const UiSkin = preload("res://scripts/interface_skin.gd")


func _initialize() -> void:
	capture="--capture-craft" in OS.get_cmdline_user_args()
	var profile := ProjectSettings.globalize_path("res://previews/craft-polish-test-profile.json")
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",profile)
	var file := FileAccess.open(profile,FileAccess.WRITE)
	file.store_string('{"version":1,"collected":{},"unlocked":{}}')
	file.close()
	create_timer(150,true).timeout.connect(func(): _fail("Craft polish verification timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		root.mode=Window.MODE_MINIMIZED
		OS.low_processor_usage_mode=false
		capture_viewport=SubViewport.new()
		capture_viewport.size=Vector2i(1280,720)
		capture_viewport.own_world_3d=true
		capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d=Viewport.MSAA_4X
		root.add_child(capture_viewport)
	world=load("res://scenes/world.tscn").instantiate()
	if capture: capture_viewport.add_child(world)
	else: root.add_child(world); current_scene=world
	party=world.party
	player=party.player
	second=party.second_player
	first=world.cooperation
	bridge=world.bridge
	court=world.courtyard
	ui=world.get_node("PartyUI")
	nearby_ui=world.get_node("NearbyInteractions")
	await _frames(12)
	if court._tablet.visible or bridge.tablet_delivered: _fail("Courtyard stele exists before bridge delivery"); return
	if ui.heading.get_theme_font_size("font_size")!=UiSkin.text_size(36):
		_fail("Cuan text was not enlarged"); return
	await _start_default_party()
	await _put(12.5,13)
	await _click_stone(0)
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(110)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(4)
	if not ui.satchel_notice.visible or ui.satchel_notice_frame.get_theme_stylebox("panel").texture!=UiSkin.NOTICE_PAPER:
		_fail("Clue receipt does not use supplied bird paper"); return
	if ui.satchel_notice.get_line_count()>ui.satchel_notice.get_visible_line_count(): _fail("Enlarged clue receipt clips"); return
	_save_coop("craft-clue-receipt")
	await _near_key(KEY_B)
	if ui.screen!=ui.Screen.SATCHEL or not paused or ui.satchel.close_button.get_theme_stylebox("normal").texture!=UiSkin.NOTICE_PAPER:
		_fail("Receipt B hint does not open the correctly skinned parcel"); return
	_save_coop("craft-parcel")
	await _click_at(ui.satchel.close_button.get_global_rect().get_center())
	await _near_key(KEY_ESCAPE)
	await _put(5.8,6.3)
	await _click_prop("bai_tiedye")
	await _click_at(world.folk.start_activity_button.get_global_rect().get_center())
	if world.folk.board.VISUAL_VERSION!=2: _fail("The old motif/balance artwork remains"); return
	_save_coop("craft-indigo-motifs")
	await _near_key(KEY_ESCAPE)
	ui._notice_seconds=0
	await _frames(5)
	if not world.achievements.toast.visible or world.achievements.toast_button.get_theme_stylebox("normal").texture!=UiSkin.NOTICE_PAPER:
		_fail("Achievement receipt does not expose the new paper button"); return
	_save_coop("craft-achievement-receipt")
	await _click_at(world.achievements.toast_button.get_global_rect().get_center())
	if ui.screen!=ui.Screen.ACHIEVEMENTS or not paused: _fail("Achievement receipt button does not open collection"); return
	await _near_key(KEY_ESCAPE)
	world.start_creek_preview()
	await _frames(5)
	if court._tablet.visible: _fail("Entering chapter two creates the courtyard stele early"); return
	world.folk.open_item("caravan_pack")
	await _click_at(world.folk.start_activity_button.get_global_rect().get_center())
	await _click_at(world.folk.board.get_global_rect().position+world.folk.board.option_position(4))
	if not world.folk.board.packs[4]: _fail("Redesigned cargo hitbox does not move the clicked weight"); return
	_save_coop("craft-cargo-balance")
	await _near_key(KEY_ESCAPE)
	world.start_garden_preview()
	await _frames(2)
	if not court.tablet_arriving or bridge._tablet.visible or not court._tablet.visible or court._tablet.global_position.x>41:
		_fail("Stone does not enter continuously from the bridge side"); return
	var entry_x: float = court._tablet.global_position.x
	_save_coop("craft-stone-enters")
	await _frames(70)
	if court._tablet.global_position.x<=entry_x+.5 or court._tablet.global_position.x>=49.9 or not court.tablet_arriving:
		_fail("Incoming stone does not move toward the empty central plinth"); return
	ui._open_audio_settings()
	var paused_x: float = court._tablet.global_position.x
	await _frames(15)
	if absf(court._tablet.global_position.x-paused_x)>.001: _fail("Stone keeps arriving under a paused modal"); return
	ui._close_audio_settings()
	await _frames(135)
	if court.tablet_arriving or court.tablet_placed or absf(court._tablet.position.x-court.PLACEMENT_X)>.01:
		_fail("Bridge-delivered stone does not wait at plinth for the cooperative lift"); return
	_save_coop("craft-stone-ready-to-lift")
	await _put(34,35)
	await _frames(5)
	var fall: MeshInstance3D = world.get_node("ConceptSceneAtmosphere").waterfall
	var vertices: PackedVector3Array = fall.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var top_x: float = 0
	var bottom_x: float = 0
	var tops: int = 0
	var bottoms: int = 0
	for v in vertices:
		if v.y>3.49: top_x+=v.x; tops+=1
		if v.y<-3.49: bottom_x+=v.x; bottoms+=1
	if tops==0 or bottoms==0 or bottom_x/bottoms>top_x/tops-.75 or not fall.has_meta("source_gap"):
		_fail("Waterfall does not curve left from a documented rock gap"); return
	if bridge._tablet.visible: _fail("Returning to the bridge respawns a delivered stone"); return
	await _frames(500)
	_save_coop("craft-curved-waterfall")
	print("CRAFT_POLISH_OK: enlarged Cuan text, native woven motifs and cargo balance with actual mouse input, supplied bird-paper receipt buttons and modal navigation, empty third-act plinth before handoff, single visible stone arrives from bridge with pause-safe motion and waits for lifting, curved left-drifting waterfall from rock gap, no bridge respawn")
	quit(0)
