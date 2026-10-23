extends "res://tools/verify_photo_guide.gd"


func _initialize() -> void:
	capture="--capture-stone-roof" in OS.get_cmdline_user_args()
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",ProjectSettings.globalize_path("res://previews/stone-roof-profile.json"))
	create_timer(200,true).timeout.connect(func(): _fail("Scenery / print / lifting check timed out"))
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
	var banks: Array[Node] = get_nodes_in_group("layered_bank_details")
	var roofs: Array[Node] = get_nodes_in_group("curved_tile_roofs")
	if banks.size()!=4 or roofs.size()<10: _fail("Refined banks or tiled roof assemblies are incomplete"); return
	for bank in banks:
		if bank.get_child_count()!=1 or bank.get_child(0).mesh.get_faces().size()<500:
			_fail("Rock strata are not detailed merged geometry"); return
	for roof in roofs:
		if roof.get_meta("tile_count",0)<32 or roof.get_node_or_null("OverlappingBarrelTiles")==null or roof.get_child_count()>5:
			_fail("Curved roof lacks overlapping tiles or exceeds its batch budget"); return
	await _start_default_party()
	await _detail_view("bank-rock-strata",Vector3(28,-.6,12),Vector3(28,-1.55,2.7),10)
	await _put(5.8,6.4)
	await _click_prop("bai_tiedye")
	var folk: CanvasLayer = world.folk
	if folk.practice_dyes.is_empty(): _fail("Practice cloth did not receive independent dye materials"); return
	for dye in folk.practice_dyes:
		if dye.get_shader_parameter("print_progress")!=0.0: _fail("Preview cloth already has a pattern before interaction"); return
	await _click_at(folk.start_activity_button.get_global_rect().get_center())
	await _frames(3)
	if true in folk.board.stamps or folk.practice_ink!=0: _fail("Starting print activity stamps the cloth automatically"); return
	_save_coop("refine-cloth-blank")
	var recipe: Array = folk.board.recipe.duplicate()
	await _click_at(folk.board.get_global_rect().position+folk.board.option_position(recipe[0]))
	await _frames(20)
	if not folk.board.stamps[recipe[0]] or folk.board.stamp_reveals[recipe[0]]<.8 or folk.practice_ink<=0:
		_fail("Actual cloth click does not reveal the corresponding ink"); return
	_save_coop("refine-cloth-first-print")
	for index in range(1,recipe.size()): await _click_at(folk.board.get_global_rect().position+folk.board.option_position(recipe[index]))
	await _frames(25)
	if not folk.board.won or folk.practice_ink<.99: _fail("Completed practice cloth is not fully printed"); return
	_save_coop("refine-cloth-complete")
	await _click_at(folk.play_again.get_global_rect().get_center())
	if true in folk.board.stamps or folk.practice_ink!=0: _fail("Retry does not return to clean cloth"); return
	await _near_key(KEY_ESCAPE)
	world.start_garden_preview()
	await _frames(210)
	await _detail_view("detailed-distant-eaves",Vector3(50,8.2,8),Vector3(50,6.7,-6),15)
	party.switch_to(1,1)
	await _put(50.3,49.7)
	await _dual_hold()
	if not court.tablet_raising or court.tablet_placed or not player.interaction_locked or not second.interaction_locked:
		_fail("Joint hold does not begin a supported staged raise"); return
	var foot_y: float = court.raise_rig.foot_y
	var socket_y: float = court.raise_rig.socket_y
	_save_coop("refine-raise-cradle")
	await _frames(78)
	var angle: float = court._tablet.rotation.z
	var foot: Vector3 = court._tablet.transform*Vector3(0,foot_y,0)
	if angle<=.05 or angle>=PI/2 or foot.y<socket_y-.01 or court.raise_rig.ropes.size()!=2:
		_fail("Stone lift is not rotating safely around its supported foot"); return
	_save_coop("refine-raise-halfway")
	ui._open_audio_settings()
	var held_pose: Transform3D = court._tablet.transform
	await _frames(18)
	if not court._tablet.transform.is_equal_approx(held_pose): _fail("Stele raise ignores modal pause"); return
	ui._close_audio_settings()
	for index in range(12):
		await _frames(10)
		foot=court._tablet.transform*Vector3(0,foot_y,0)
		if foot.y<socket_y-.005: _fail("Stele foot clips through the plinth during the raise"); return
	await _frames(18)
	foot=court._tablet.transform*Vector3(0,foot_y,0)
	if not court.tablet_placed or court.tablet_raising or player.interaction_locked or second.interaction_locked or absf(foot.y-socket_y)>.005 or absf(court._tablet.rotation.z)>.001:
		_fail("Stele does not settle precisely into its plinth and release players"); return
	_save_coop("refine-raise-seated")
	world.restart_current_scene()
	await _frames(210)
	await _put(50.3,49.7)
	await _dual_hold()
	if not court.tablet_raising: _fail("Restarted courtyard cannot replay the lift"); return
	world.restart_current_scene()
	await _frames(210)
	if court.tablet_placed or court.tablet_raising or is_instance_valid(court.raise_rig) or player.interaction_locked:
		_fail("Restart during lift leaves a rig, late callback, or control lock"); return
	print("STONE_ROOF_OK: four merged irregular bank foundations, curved overlapping tiles on distant/foreground roofs, blank practice cloth with independent preview dyes and mouse-driven ink reveal/retry, foot-pivot lifting with timber/rope supports, pause-safe settling at exact plinth height, delayed task unlock and reset cleanup")
	quit(0)


func _detail_view(title: String, at: Vector3, target: Vector3, width: float) -> void:
	if not capture: return
	var original: Camera3D = capture_viewport.get_camera_3d()
	var detail := Camera3D.new()
	world.add_child(detail)
	detail.projection=Camera3D.PROJECTION_ORTHOGONAL
	detail.keep_aspect=Camera3D.KEEP_WIDTH
	detail.size=width
	detail.global_position=at
	detail.look_at(target)
	detail.make_current()
	detail.force_update_transform()
	await _frames(3)
	var controls: Array[CanvasItem] = []
	var visible: Array[bool] = []
	for layer in world.find_children("*","CanvasLayer",true,false):
		for child in layer.get_children():
			if child is CanvasItem:
				controls.append(child)
				visible.append(child.visible)
				child.visible=false
	var story_was_visible: bool = world.story.frame.visible
	world.story.frame.visible=false
	_save_coop("refine-"+title)
	for index in range(controls.size()): controls[index].visible=visible[index]
	world.story.frame.visible=story_was_visible
	original.make_current()
	detail.free()
