extends "res://tools/verify_nearby_interactions.gd"


func _initialize() -> void:
	capture = "--capture-details" in OS.get_cmdline_user_args()
	create_timer(110, true).timeout.connect(func(): _fail("World details check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1280, 720)
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
	world = load("res://scenes/world.tscn").instantiate()
	if capture: capture_viewport.add_child(world)
	else: root.add_child(world); current_scene = world
	party = world.party
	player = party.player
	second = party.second_player
	first = world.cooperation
	bridge = world.bridge
	court = world.courtyard
	ui = world.get_node("PartyUI")
	nearby_ui = world.get_node("NearbyInteractions")
	await _frames(10)
	if not ui.primary.get_theme_stylebox("normal") is StyleBoxTexture or ui.primary.get_theme_stylebox("normal").texture != ui.UiStyle.TITLE_BUTTON:
		_fail("Cover buttons lack supplied first image"); return
	_save_coop("details-title-buttons")
	await _click_at(ui.primary.get_global_rect().get_center())
	await _frames(4)
	if not "button" in world.sfx.events or not "card_flip" in world.sfx.events or ui.screen != ui.Screen.DRAW:
		_fail("Mouse button or orbital card movement lacks sound"); return
	ui.opening_draw._process(1.0)
	_save_coop("details-card-turn")
	ui.opening_draw.reveal_now()
	if not "card_pick" in world.sfx.events: _fail("Card reveal lacks sound"); return
	ui._cancel_draw()
	await _frames(5)
	await _start_default_party()
	await _frames(30)
	if ui.screen != ui.Screen.GAME: _fail("Check failed to start game after returning from card test: " + str(ui.screen)); return
	await _click_at(ui.hint_button.get_global_rect().get_center())
	if ui.screen != ui.Screen.HELP or not paused: _fail("Hint does not open"); return
	var help_paper: StyleBoxTexture = ui.hint_panel.get_child(1).get_theme_stylebox("panel")
	if help_paper.texture != ui.UiStyle.GAME_BUTTON or ui.hint_button.get_theme_stylebox("normal").texture != ui.UiStyle.GAME_BUTTON:
		_fail("Hint panel or game button lacks second supplied image"); return
	_save_coop("details-help-background")
	await _near_key(KEY_N)
	if not world.sfx.muted or world.music.muted: _fail("N must mute effects independently in paused help"); return
	await _near_key(KEY_N)
	await _near_key(KEY_ESCAPE)
	world.sfx.events.clear()
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	if not "jump" in world.sfx.events or player.velocity.y <= 0: _fail("Actual jump has no subtle launch sound"); return
	await _frames(42)
	await _put(5.9, 6.6)
	await _focus_id(0, "bai_tiedye")
	await _near_key(KEY_F)
	if not nearby_ui.reading_papers[0].visible or nearby_ui.reading_papers[0].texture != ui.UiStyle.GAME_BUTTON:
		_fail("Expanded approach hint lacks supplied second image"); return
	_save_coop("details-dyed-cloth-and-trade")
	if world.scene_details.props.size() != 8 or nearby_ui.entries.size() < 72:
		_fail("Visible craft objects lack approach interactions"); return
	world.start_creek_preview()
	await _put(27, 28)
	await _focus_id(0, "old_route")
	await _near_key(KEY_F)
	_save_coop("details-route-grooves")
	if world.scene_details.route_surface.get_child_count() < 40: _fail("Route still lacks modeled carving detail"); return
	await _put(22.0, 22.2)
	await _frames(40)
	if world.sfx.ambience.playing or world.sfx.ambience_gain > .01: _fail("Far-away creek should be inaudible"); return
	await _put(22.0, 30.8)
	await _frames(40)
	if not world.sfx.ambience.playing or world.sfx.ambience_gain < .5:
		_fail("Creek must fade in for either nearby human player"); return
	await _click_at(ui.effects_button.get_global_rect().get_center())
	if not world.sfx.muted or world.sfx.ambience.playing or world.music.muted:
		_fail("Effects switch does not silence ambience independently"); return
	var count: int = world.sfx.events.size()
	world.sfx.play("card_flip")
	if world.sfx.events.size() != count: _fail("Muted effects still play"); return
	await _near_key(KEY_N)
	bridge.step = 1
	party.switch_to(2, 0)
	await _put(24, 24.8)
	await _frames(15)
	Input.action_press("interact")
	await _frames(18)
	if bridge._timber_progress <= 0 or not "wood" in world.sfx.active_holds or not world.sfx.hold_players[0].playing:
		_fail("Valid timber hold has no continuing work sound"); return
	await _click_at(ui.hint_button.get_global_rect().get_center())
	await _frames(3)
	if not world.sfx.active_holds.is_empty() or world.sfx.ambience.playing: _fail("Pause leaves ongoing work/stream audio"); return
	Input.action_release("interact")
	await _near_key(KEY_ESCAPE)
	await _frames(4)
	if not world.sfx.active_holds.is_empty(): _fail("Releasing hold leaves work loop"); return
	world.start_garden_preview()
	party.switch_to(1, 1)
	await _put(49.0, 49.7)
	await _frames(18)
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(18)
	if court.action_progress <= 0 or not "stone" in world.sfx.active_holds:
		_fail("Joint stone hold has no ongoing sound"); return
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(5)
	if not world.sfx.active_holds.is_empty(): _fail("Cancelled joint raising leaves work sound"); return
	await _put(42, 43)
	await _focus_id(0, "dai_brocade")
	await _near_key(KEY_F)
	_save_coop("details-brocade")
	await _put(54.0, 56)
	_save_coop("details-tea-and-loom")
	world.restart_current_scene()
	await _frames(5)
	if world.sfx.muted or not world.sfx.active_holds.is_empty(): _fail("Restart leaves stale work sounds"); return
	print("WORLD_DETAIL_SOUND_OK: two supplied UI papers, real button click/card turn/reveal/jump, eight modeled craft groups and interactable objects, large carved route grooves, both-player creek distance fade, independent effects switch in paused/game UI, valid continuous wood and joint stone holds, release/pause/restart cancellation, music preserved")
	quit(0)
