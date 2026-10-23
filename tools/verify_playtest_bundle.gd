extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1: push_error("Missing playtest output directory"); quit(1); return
	var output: String = arguments[0]
	# Keep automated collection separate from the player's permanent local book.
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",output.path_join("bundle-achievements-profile.json"))
	# Read notices from this matching Godot engine and its compiled libraries.
	var notices: String = "Godot Engine\n\n" + Engine.get_license_text() + "\n\nThird-party components\n\n"
	for component in Engine.get_copyright_info():
		notices += str(component.name) + "\n"
		for part in component.parts:
			notices += "  " + str(part.license) + "\n"
			for owner in part.copyright: notices += "  " + str(owner) + "\n"
		notices += "\n"
	var licenses: Dictionary = Engine.get_license_info()
	for name in licenses:
		notices += "\n===== " + str(name) + " =====\n" + str(licenses[name]) + "\n"
	var file := FileAccess.open(output.path_join("Godot引擎与第三方许可.txt"), FileAccess.WRITE)
	if file == null: push_error("Cannot write engine notices"); quit(1); return
	file.store_string(notices)
	file.close()
	var scene := load("res://scenes/world.tscn") as PackedScene
	if scene == null: push_error("The shipped PCK cannot load the game"); quit(1); return
	var world: Node3D = scene.instantiate()
	root.add_child(world)
	current_scene = world
	world.chapter_films.enabled=false
	for frame in range(20): await process_frame
	var ui: CanvasLayer = world.get_node("PartyUI")
	if ui.screen != ui.Screen.TITLE or not ui.title_art.visible: push_error("Shipped cover does not initialize"); quit(1); return
	for video in [world.get_node("PartyUI").opening_film.FILM_PATH]+world.chapter_films.PATHS:
		var stream=load(video)
		if not stream is VideoStreamTheora:
			push_error("Packaged supplied story film missing: "+video); quit(1); return
	var keepsakes_verified: bool=false
	if world.get("keepsakes")!=null:
		if world.keepsakes.pickups.size()!=4 or true in world.keepsakes.collected or not world.achievements.collected.is_empty():
			push_error("Packaged fresh journey carries old inventory or achievements"); quit(1); return
		for index in range(4):
			if not world.keepsakes.pickups[index].visible or world.courtyard.landscape.objects[index].visible:
				push_error("Packaged personal items do not start scattered in the first two scenes"); quit(1); return
		keepsakes_verified=true
	if world.courtyard.get("tablet_arriving")!=null and (world.courtyard._tablet.visible or world.courtyard._arrival_sled.visible):
		push_error("Packaged courtyard begins with an untransported stele"); quit(1); return
	if world.music.TRACKS.size() != 4 or ui.opening_draw.CARD_TEXTURES.size() != 8:
		push_error("Shipped audio or original cards are incomplete"); quit(1); return
	ui._begin_game()
	ui._refresh()
	world.restart_current_scene()
	for frame in range(5): await physics_frame
	if not ui.goal_panel.visible or not ui.restart_button.visible or world.current_space != 0:
		push_error("Shipped goal or restart fails"); quit(1); return
	var folk_verified: bool = false
	if world.get("folk") != null:
		if ui.effects_slider == null or ui.effects_slider.value != 85 or world.folk.items.size() != 21 or world.festival.lanterns.size() < 12:
			push_error("Latest packaged volume/objects/festival resources are incomplete"); quit(1); return
		world.folk.open_item("bai_tiedye")
		for frame in range(3): await process_frame
		if not world.folk.overlay.visible or world.folk.preview_model == null:
			push_error("Packaged floating 3D introduction fails"); quit(1); return
		if world.folk.has_method("_start_activity"): world.folk._start_activity()
		var craft_driver: Script=load(get_script().resource_path.get_base_dir().path_join("native_craft_test_driver.gd"))
		if craft_driver==null or not await craft_driver.complete(self,world.folk.board):
			push_error("Packaged tied resist craft cannot be played with actual mouse controls"); quit(1); return
		if not world.folk.games_done[0]: push_error("Packaged craft activity fails"); quit(1); return
		world.folk.close()
		world.restart_current_scene()
		for frame in range(3): await process_frame
		folk_verified = true
	var grand_verified: bool = false
	if world.get("click_interactions") != null:
		ui._open_audio_settings()
		for frame in range(3): await process_frame
		if not ui.audio_settings.visible or ui.music_slider == null or ui.sound_button.visible:
			push_error("Packaged modal sound settings fail"); quit(1); return
		world.music.set_volume(.4)
		ui._close_audio_settings()
		world.start_creek_preview()
		for frame in range(3): await process_frame
		world.click_interactions.open_history()
		if not world.click_interactions.overlay.visible or not world.click_interactions.history_text.text.contains("1778"):
			push_error("Packaged Yangqitian history is missing"); quit(1); return
		world.click_interactions.close()
		world.folk.open_item("scholar_tools")
		world.folk._toggle_reference()
		for frame in range(3): await process_frame
		if not world.folk.reference_image.visible or world.folk.preview_model.find_child("HollowBambooTube", true, false) == null or world.folk.reference_image.size.x > 431 or world.festival.grand.sky_lanterns.size() < 8:
			push_error("Packaged museum image, detailed scholar prop or grand court is missing"); quit(1); return
		world.folk.close()
		grand_verified = true
	var planar_verified: bool = false
	if world.get("walk_space") != null:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_W
		if not InputMap.event_is_action(key, "move_forward") or InputMap.event_is_action(key, "jump"):
			push_error("Packaged four-direction controls are missing"); quit(1); return
		world.start_garden_preview()
		for frame in range(4): await physics_frame
		world.player.global_position = Vector3(35, .8, 0)
		world.party.second_player.global_position = Vector3(35.8, .8, 0)
		for frame in range(4): await physics_frame
		if not world.bridge.tablet_delivered or world.bridge._tablet.visible or not world.courtyard._tablet.visible:
			push_error("Packaged returning players resurrect the transport stone"); quit(1); return
		planar_verified = true
	var scenery_verified: bool = false
	if world.get("scene_atmosphere") != null:
		ui._open_audio_settings()
		for frame in range(3): await process_frame
		var panel_rect: Rect2 = ui.audio_settings.panel.get_global_rect()
		if panel_rect.position.x < 890 or panel_rect.position.y > 90 or panel_rect.end.x > 1257:
			push_error("Packaged sound settings are not in the upper-right"); quit(1); return
		ui._close_audio_settings()
		if world.scene_atmosphere.waterfall == null or world.scene_atmosphere.town_lights.multimesh.instance_count != 180:
			push_error("Packaged concept scenery is incomplete"); quit(1); return
		for rail in world.walk_space.bridge_rails:
			if rail.shape.size.y < 5: push_error("Packaged bridge has a reachable rope top"); quit(1); return
		scenery_verified = true
	var walkway_verified: bool = false
	if world.walk_space.get("navigation") != null:
		ui._refresh()
		if ui.sound_button.position.x < 1150:
			push_error("Packaged sound entry still covers a title face"); quit(1); return
		if world.walk_space.deck_depth_bounds(35).y > .71:
			push_error("Packaged bridge ends are not protected"); quit(1); return
		var plaques: Array[Node] = get_nodes_in_group("world_plaques")
		for title in ["同源异彩","灯火共庭"]:
			var found: bool = false
			for plaque in plaques:
				if plaque.get_meta("title") == title:
					var box: AABB = world.folk._bounds(plaque)
					found = box.size.x >= 3.5 and box.size.y >= .8
			if not found: push_error("Packaged large final plaque missing: "+title); quit(1); return
		walkway_verified = true
	var photo_guide_verified: bool = false
	if world.folk.get("photo_catalog") != null:
		var catalog: Dictionary = world.folk.photo_catalog
		if catalog.items.size()!=21 or catalog.photos.size()!=18:
			push_error("Packaged real-photo catalog is incomplete"); quit(1); return
		for id in world.folk.items:
			if not catalog.items.has(id) or catalog.items[id].is_empty():
				push_error("No packaged real photograph for "+id); quit(1); return
			for photo_id in catalog.items[id]:
				var entry: Dictionary = catalog.photos[photo_id]
				var photograph: Texture2D = load(entry.file)
				if photograph==null or entry.source.is_empty() or entry.author.is_empty() or entry.license.is_empty():
					push_error("Packaged real photograph or attribution fails: "+photo_id); quit(1); return
		if not world.scene_atmosphere.waterfall.mesh is ArrayMesh or world.scene_atmosphere.waterfall.get_meta("bottom_width")<1:
			push_error("Packaged waterfall is not tapered"); quit(1); return
		world.start_garden_preview()
		world.courtyard.court_lit=true
		var journey: Array[String] = ["Packaged photo-guide verification"]
		world.courtyard.show_record(journey)
		for frame in range(4): await process_frame
		if not world.music.scroll_arrangement or world.music.decks[world.music.active_deck].stream!=world.music.SCROLL_TRACK:
			push_error("Packaged scroll does not enter its raised-key celebration arrangement"); quit(1); return
		for frame in range(4): await process_frame
		var art: Node3D = world.courtyard.landscape
		if not art.record_cover_open or not art.record_cover.visible or art.record_cover.texture!=art.SCROLL_COVER:
			push_error("Packaged supplied scroll cover is missing"); quit(1); return
		art.turn_record(1)
		if art.record_cover_open or art.record_page!=0 or art.record_art.texture!=art.SCROLL_IMAGES[0]:
			push_error("Packaged new cover skips the first mural"); quit(1); return
		world.courtyard.close_record()
		photo_guide_verified=true
	var achievement_verified: bool = false
	if world.get("achievements")!=null:
		var book: CanvasLayer = world.achievements
		if book.Content.ITEMS.size()!=21 or book.Content.GROUPS.size()!=8 or book.Content.BADGES.size()!=8:
			push_error("Packaged achievement catalog is incomplete"); quit(1); return
		ui._open_achievements()
		for frame in range(3): await process_frame
		if ui.screen!=ui.Screen.ACHIEVEMENTS or not paused or not book.overlay.visible:
			push_error("Packaged achievement entry does not open"); quit(1); return
		for id in book.Content.ITEMS: book.record_item(id)
		if not world.courtyard.landscape.collection_reward.complete:
			push_error("Packaged full achievement set does not unlock the colour egg"); quit(1); return
		book.select_group("交融成就")
		if book.collected.size()!=21 or book.unlocked.size()!=8 or book.connected_groups()!=7:
			push_error("Packaged cross-ethnic collection achievements fail"); quit(1); return
		book._required_link("item:bai_tiedye")
		if not book.detail_photo.visible or book.detail_photo.texture==null or not book.detail_credit.text.contains("来源"):
			push_error("Packaged achievement book cannot replay collected photograph"); quit(1); return
		book.reset_session()
		if not book.collected.is_empty() or not book.unlocked.is_empty():
			push_error("Packaged achievement new-session reset fails"); quit(1); return
		ui._close_achievements()
		if paused: push_error("Packaged achievement window leaves the game paused"); quit(1); return
		achievement_verified=true
	var activity_verified: bool = false
	if world.folk.get("activity_profile")!=null:
		var profiles: Dictionary = world.folk.Activities.PROFILES
		if profiles.size()!=21 or profiles.caravan_pack.weights==profiles.yang_trade_goods.weights:
			push_error("Packaged object activities still reuse the same load"); quit(1); return
		var ui_skin: Script = load("res://scripts/interface_skin.gd")
		if ui.sound_button.get_theme_font("font")!=ui_skin.heading_font() or ui.satchel.close_button.get_theme_stylebox("normal").texture!=(ui_skin.NOTICE_PAPER if "NOTICE_PAPER" in ui_skin.get_script_constant_map() else ui_skin.PARCEL_PAPER):
			push_error("Packaged Cuan entry font or supplied parcel paper is missing"); quit(1); return
		world.folk.open_item("garden_item_2")
		if not world.folk.activity_story.visible or world.folk.activity_portrait.texture==null or world.folk.board.running:
			push_error("Packaged object story does not precede the activity"); quit(1); return
		world.folk._start_activity()
		if not world.folk.board.running or not world.folk.board.playing_demo:
			push_error("Packaged object activity cannot start after its story"); quit(1); return
		world.folk.board._note(world.folk.board.recipe[0])
		if world.folk.board.lit!=-1 or world.folk.board.message.contains("→"):
			push_error("Packaged listening activity reveals its answer"); quit(1); return
		world.folk.close()
		activity_verified=true
	var typography_verified: bool = false
	var typography: Script = load("res://scripts/interface_skin.gd")
	if typography.has_method("body_font"):
		if not typography.heading_font() is FontVariation or typography.heading_font().variation_embolden<=0 or typography.heading_font().variation_embolden>0.5:
			push_error("Packaged titles do not have a restrained Cuan stroke weight"); quit(1); return
		if not _check_cuan_tree(world,typography): quit(1); return
		for custom_font in [world.folk.board.font,world.courtyard.landscape.font,world.achievements.font]:
			if not _is_cuan(custom_font,typography): push_error("Custom-drawn text is not Cuan"); quit(1); return
		typography_verified=true
	var craft_polish_verified: bool = false
	if typography.has_method("text_size"):
		if typography.text_size(18)<=18 or world.folk.board.VISUAL_VERSION!=2 or world.scene_atmosphere.waterfall.get_meta("left_drift",0)<.75:
			push_error("Packaged text scale, craft art or curved waterfall is missing"); quit(1); return
		if ui.satchel_notice_frame.get_theme_stylebox("panel").texture!=typography.NOTICE_PAPER or world.achievements.toast_button.get_theme_stylebox("normal").texture!=typography.NOTICE_PAPER:
			push_error("Packaged receipt buttons do not use supplied bird paper"); quit(1); return
		world.courtyard.reset_lesson()
		if not world.courtyard.tablet_arriving or world.courtyard._tablet.global_position.x>41:
			push_error("Packaged stone does not start its incoming transfer at the gate"); quit(1); return
		for frame in range(4): await physics_frame
		if not is_instance_valid(world.courtyard.carry_rig) or world.courtyard.carry_rig.carriers.size()!=4:
			push_error("Packaged arrival has no four-character carrying rig"); quit(1); return
		for body in world.courtyard.carry_rig.carriers:
			if body.is_physics_processing() or not world.party._visual(body).transport_pose:
				push_error("Packaged load is moving without its actual bearers"); quit(1); return
		for frame in range(ceili(world.courtyard.ARRIVAL_SECONDS*60)+12): await physics_frame
		if world.courtyard.tablet_arriving or absf(world.courtyard._tablet.position.x-world.courtyard.PLACEMENT_X)>.01:
			push_error("Packaged incoming stone does not settle at the plinth"); quit(1); return
		if is_instance_valid(world.courtyard.carry_rig): push_error("Packaged arrival retains a stale carrier rig"); quit(1); return
		for body in world.party.all_bodies():
			if not body.is_physics_processing() or world.party._visual(body).transport_pose:
				push_error("Packaged arrival does not return a real character to gameplay"); quit(1); return
		craft_polish_verified=true
		if world.achievements.toast_button.visible or world.achievements.toast_text.get_theme_font("font")!=ui.satchel_notice.get_theme_font("font") or world.achievements.toast_text.horizontal_alignment!=HORIZONTAL_ALIGNMENT_CENTER:
			push_error("Packaged achievement receipt differs from the parcel notice"); quit(1); return
	var gate_motion_verified: bool=false
	var gate_roofs: Array[Node]=get_nodes_in_group("city_gate_roof")
	if gate_roofs.size()!=1 or gate_roofs[0].tile_count<150 or gate_roofs[0].find_children("*","CollisionObject3D",true,false).size()!=0:
		push_error("Packaged city gate lacks detailed nonblocking tiled roof"); quit(1); return
	for body in world.party.all_bodies():
		var model: Node3D=world.party._visual(body).detailed_model
		if model.motion_variants.size()!=7 or model._clips.size()!=6:
			push_error("Packaged character lacks native motion variants"); quit(1); return
		var planted: Animation=model.animation_player.get_animation(model.motion_variants.carry_plant)
		for track in range(planted.get_track_count()):
			if planted.track_get_type(track)==Animation.TYPE_ROTATION_3D and str(planted.track_get_path(track)).ends_with("thigh.L"):
				if absf(planted.rotation_track_interpolate(track,.12).dot(planted.rotation_track_interpolate(track,.45)))<.9999:
					push_error("Packaged stationary carry still shuffles feet"); quit(1); return
		if model.animation_player.get_animation(model.motion_variants.jump_fall).loop_mode!=Animation.LOOP_NONE:
			push_error("Packaged fall repeats airborne takeoff"); quit(1); return
	gate_motion_verified=true
	var stone_roof_verified: bool = false
	if world.courtyard.get("tablet_raising")!=null:
		if get_nodes_in_group("layered_bank_details").size()!=4 or get_nodes_in_group("curved_tile_roofs").size()<10:
			push_error("Packaged layered banks or detailed roofs are missing"); quit(1); return
		world.folk.open_item("bai_tiedye")
		if world.folk.practice_dyes.is_empty(): push_error("Packaged practice cloth has no independent ink material"); quit(1); return
		for dye in world.folk.practice_dyes:
			if dye.get_shader_parameter("print_progress")!=0.0: push_error("Packaged cloth is already printed"); quit(1); return
		world.folk._start_activity()
		if true in world.folk.board.stamps: push_error("Packaged print activity starts with ink"); quit(1); return
		world.folk.close()
		var chapter: Node3D = world.courtyard
		chapter._raise_tablet()
		if not chapter.tablet_raising or chapter.tablet_placed or not world.party.player.interaction_locked:
			push_error("Packaged stele skips the supported raising phase"); quit(1); return
		if chapter.raise_rig.actors.size()!=4 or chapter.raise_rig.hand_lines.size()!=8:
			push_error("Packaged stele rises without its actual four workers / hand lines"); quit(1); return
		for body in chapter.raise_rig.actors:
			if body.is_physics_processing() or not world.party._visual(body).transport_pose:
				push_error("Packaged hoist leaves a real worker outside the animation"); quit(1); return
		var foot_y: float = chapter.raise_rig.foot_y
		var socket_y: float = chapter.raise_rig.socket_y
		for frame in range(ceili(chapter.RAISE_SECONDS*60)+12): await physics_frame
		var foot: Vector3 = chapter._tablet.transform*Vector3(0,foot_y,0)
		if not chapter.tablet_placed or chapter.tablet_raising or world.party.player.interaction_locked or absf(foot.y-socket_y)>.005:
			push_error("Packaged stele does not settle or release controls"); quit(1); return
		stone_roof_verified=true
	var two_steles_verified: bool = false
	var rotation_stream: AudioStreamWAV=world.sfx.draw_spin.stream
	if rotation_stream.format!=AudioStreamWAV.FORMAT_16_BITS or rotation_stream.loop_end!=roundi(rotation_stream.get_length()*rotation_stream.mix_rate):
		push_error("Packaged draw rotation has truncated / compressed-byte loop"); quit(1); return
	if world.sfx.SOUNDS.opening_card_flip.resource_path!="res://assets/audio/interactions/card_flip.wav" or world.sfx.SOUNDS.opening_card_pick.resource_path!="res://assets/audio/interactions/card_pick.wav":
		push_error("Packaged opening cards do not use the original sound assets"); quit(1); return
	if world.courtyard.landscape.get_node_or_null("CourtyardRightReturn/ContinuousDeck")==null or world.courtyard._tablet.mesh.get_aabb().size.z<.4:
		push_error("Packaged courtyard continuation / solid stele is missing"); quit(1); return
	if not world.cooperation.inspector.practice_status is Label or world.cooperation.inspector.puzzle_viewport.size.x<1620 or world.cooperation._board_status.visible:
		push_error("Packaged reading text is still rasterized in the small 3D viewport"); quit(1); return
	if get_nodes_in_group("eroded_cliff_details").size()!=2 or get_nodes_in_group("leaf_canopy_detail").size()<6 or get_nodes_in_group("broken_gallery_tile_detail").size()!=1 or get_nodes_in_group("artisan_tea_service").size()!=1 or get_nodes_in_group("hollow_horse_bell_detail").size()<2:
		push_error("Packaged audited rock / botanical / pottery / roof details missing"); quit(1); return
	if world.cooperation.get("comparison_complete")!=null:
		var first: Node3D = world.cooperation
		first.reset_lesson()
		if first.inspector.background_paper.texture.resource_path!="res://assets/interface/parcel_paper.png":
			push_error("Packaged stele paper is not the supplied floral image"); quit(1); return
		first.inspector.rubbing.completed=true
		first.step=4
		first.clues.fill(true)
		first.slots.assign([0,1,2,3,4,5])
		first.turns.fill(0)
		if first._check_solution() or first.observed or first.gate_open:
			push_error("Packaged small stele can bypass required large-stele seal"); quit(1); return
		first.inspected_id=0
		first.record_comparison()
		if first.large_stele_checked: push_error("Packaged small stele grants the large seal"); quit(1); return
		first.reset_lesson()
		first.open_inspection(1)
		var lore: Control = first.inspector.lore
		lore._start()
		for answer in [1,0,2]: lore.answer(answer)
		if not first.comparison_complete or first.clues.count(true)!=0 or first.observed:
			push_error("Packaged large stele reward is missing or bypasses the small stele"); quit(1); return
		if not first.large_stele_checked or world.sfx.draw_spin.stream==null:
			push_error("Packaged required seal or rotation loop missing"); quit(1); return
		if lore.NOTE.contains("淡字") or not lore.NOTE.contains("纪年题签"):
			push_error("Packaged large stele still rewards a duplicate small-stele clue"); quit(1); return
		for index in range(6):
			if first._slot_labels[index].text!=str(index+1):
				push_error("Packaged comparison reveals small-stele glyph answers"); quit(1); return
		ui._open_satchel()
		ui.satchel._show_comparison(true)
		if not ui.satchel.comparison_text.text.contains("458") or not ui.satchel.comparison_known:
			push_error("Packaged comparison note cannot be reviewed"); quit(1); return
		ui._close_satchel()
		first.close_puzzle()
		if get_nodes_in_group("eave_lantern_bays").size()!=9:
			push_error("Packaged lanterns are not distributed among architectural bays"); quit(1); return
		two_steles_verified=true
	var cooperative_verified: bool = false
	if world.get("experience")!=null:
		var experience: CanvasLayer = world.experience
		if not world.cooperation.CLUES[0].contains("1、3、5") or not world.cooperation.CLUES[3].contains("2、4、6") or world.bridge.RESCUE_SECONDS<2:
			push_error("Packaged complementary clues or rope challenge is missing"); quit(1); return
		world.courtyard.items_done.assign([true,true,true,true,false,false,false])
		world.courtyard.lamp_count=4
		experience.open_design()
		if not paused or ui.screen!=ui.Screen.ARRANGE or not experience.overlay.visible:
			push_error("Packaged joint courtyard designer cannot open"); quit(1); return
		experience.select_design(0,0)
		experience.select_design(1,2)
		experience.confirm_design(0)
		if experience.design_done: push_error("One packaged controller can confirm for both"); quit(1); return
		experience.confirm_design(1)
		if not experience.design_done or paused or not world.courtyard.composition_ready() or not world.archive_text().contains(experience.design_summary()):
			push_error("Packaged shared design does not unlock lamps / retain its result"); quit(1); return
		var cloths: Array[Node] = get_nodes_in_group("shared_court_cloths")
		if cloths.size()!=7: push_error("Packaged shared cloth panels are missing"); quit(1); return
		for cloth in cloths:
			if cloth.get_meta("cloth_index")==3 and cloth.material_override.get_shader_parameter("partner_motif")!=1:
				push_error("Packaged central cloth does not combine both voices"); quit(1); return
		experience.reset_from(2)
		cooperative_verified=true
	var scene_art_verified: bool=false
	var scene_art: Node3D=world.get_node_or_null("SceneArtPolish")
	if scene_art!=null:
		if scene_art.glows.size()!=12 or scene_art.source_parts<700 or scene_art.batches.size()>26 or scene_art.find_children("*","CollisionObject3D",true,false).size()!=0:
			push_error("Packaged scene art is incomplete or adds gameplay colliders"); quit(1); return
		var skies: Array[Node]=world.scene_atmosphere.find_children("LayeredSky","MeshInstance3D",true,false)
		if skies.size()!=1 or skies[0].mesh.size.x!=72:
			push_error("Packaged chapters do not share the continuous panorama"); quit(1); return
		scene_art_verified=true
	var feedback_verified: bool=false
	var right_enter:=InputEventKey.new()
	right_enter.physical_keycode=KEY_KP_ENTER
	var old_ctrl:=InputEventKey.new()
	old_ctrl.physical_keycode=KEY_CTRL
	old_ctrl.location=KEY_LOCATION_RIGHT
	if not InputMap.event_is_action(right_enter,"p2_jump") or InputMap.event_is_action(old_ctrl,"p2_jump"):
		push_error("Packaged 2P jump is not keypad Enter"); quit(1); return
	var garden: Node3D=world.courtyard.landscape
	if garden.world_scroll_paper.material_override.albedo_texture!=garden.SCROLL_COVER or garden.chronicle_label.text!="二爨一脉 · 405—458":
		push_error("Packaged world scroll lacks supplied floral paper / chronology reward"); quit(1); return
	if world.bridge.landscape.repair_blocks.size()!=7 or not world.bridge.landscape.repair_pier.visible:
		push_error("Packaged bridgehead has no visible repairable pier"); quit(1); return
	var grand: Node3D=world.festival.grand
	if grand.FIREWORK_COLORS.size()!=6 or grand.celebration.material_override.shader.resource_path!="res://shaders/festival_spark.gdshader":
		push_error("Packaged fireworks lack the six-colour vertex shader"); quit(1); return
	feedback_verified=true
	# Finish the earlier courtyard fixture before testing a fresh first act;
	# its intentionally unconfirmed design would otherwise open over the paper.
	world.current_space=0
	world.restart_current_scene()
	for frame in range(5): await physics_frame
	var rubbing: Control=world.cooperation.inspector.rubbing
	world.cooperation.open_inspection(0)
	if not rubbing.visible or rubbing.completed:
		push_error("Packaged first act skips cooperative rubbing"); quit(1); return
	# The driver is external test code; game scripts must load from the PCK.
	var driver: Script=load(get_script().resource_path.get_base_dir().path_join("rubbing_test_driver.gd"))
	if driver==null or not await driver.complete(self,rubbing):
		push_error("Packaged rubbing controls cannot complete: phase="+str(rubbing.phase)+" offsets="+str(rubbing.offsets)+" fixed="+str(rubbing.fixed)+" active="+str(rubbing._active())+" screen="+str(ui.screen)+" paused="+str(paused)); quit(1); return
	if world.cooperation.step!=0 or world.cooperation.gate_open:
		push_error("Packaged rubbing bypasses four-role reading"); quit(1); return
	world.cooperation.close_puzzle()
	world.party.switch_to(2,0)
	world.party.player.global_position=Vector3(9.2,.8,-.55)
	world.party.player.velocity=Vector3.ZERO
	for frame in range(15): await physics_frame
	if world.keepsakes.collect(0,world.party.player):
		push_error("Packaged keepsake can be collected by the wrong role"); quit(1); return
	world.party.switch_to(0,0)
	world.party.player.global_position=Vector3(9.2,.8,-.55)
	world.party.player.velocity=Vector3.ZERO
	for frame in range(15): await physics_frame
	if not world.keepsakes.collect(0,world.party.player):
		push_error("Packaged keepsake rejects its actual owner"); quit(1); return
	if world.guidance==null or world.guidance.cards.size()!=2 or world.guidance.get_child_count()!=2 or not world.guidance.find_children("*","Button",true,false).is_empty():
		push_error("Packaged compact work feedback retains route / direct-switch panels"); quit(1); return
	if get_nodes_in_group("bridgehead_pier_barrier").size()!=1 or get_nodes_in_group("crafted_stele_alcove").size()!=1:
		push_error("Packaged pier barrier or crafted stele setting missing"); quit(1); return
	if world.courtyard.ARRIVAL_SECONDS<6.3 or world.courtyard.RAISE_SECONDS<4.7 or not world.sfx.SOUNDS.stone.resource_path.contains("folk_cues_20261020") or not world.music.SCROLL_TRACK.resource_path.contains("scroll_festival"):
		push_error("Packaged slow carrying / supported raising / folk audio missing"); quit(1); return
	if ui.satchel_notice.text.contains("按 B") or world.achievements.pending_toast.contains("按 C"):
		push_error("Packaged receipts retain unwanted view-key wording"); quit(1); return
	var craft_modes: Dictionary={}
	for id in world.folk.items: craft_modes[world.folk.Activities.for_item(id).mode]=true
	if craft_modes.size()!=12 or not world.folk.description_scroll.clip_contents or world.achievements.locate_button==null or not world.bridge._a_cai.get_node("Character").hoe_detail.is_in_group("forged_hoe_detail") or world.folk.court_aliases.size()!=5:
		push_error("Packaged crafts / explanation / locator / forged hoe: modes="+str(craft_modes.keys())+" clipped="+str(world.folk.description_scroll.clip_contents)+" locator="+str(world.achievements.locate_button!=null)+" hoes="+str(get_nodes_in_group("forged_hoe_detail").size())); quit(1); return
	if get_nodes_in_group("continuous_mountain_ridge").size()!=4 or world.scene_details.route_surface.position.z> -2.3 or not world.bridge.landscape.stage_labels[2].no_depth_test:
		push_error("Packaged route rock / readable title / continuous mountains missing"); quit(1); return
	for id in ["tea_jar","fire_basin","flint_pouch"]:
		var anchor: Node3D=world.folk.items[id].anchor
		if not anchor.has_meta("standalone_artifact") or not anchor.find_children("*","Label3D",true,false).is_empty():
			push_error("Packaged small props are still hidden on a person or labelled"); quit(1); return
	if not world.courtyard.landscape.collection_reward.materials[0].shader.has_method("get_code") or world.courtyard.landscape.collection_reward.inlay.get_child_count()<15:
		push_error("Packaged colour egg materials / fine inlay missing"); quit(1); return
	var rewards: Node3D=world.celebration_rewards
	if rewards==null or rewards.button==null or rewards.fireworks.particles.multimesh.instance_count<2000 or rewards.flowers.multimesh.instance_count!=128:
		push_error("Packaged interactive fireworks / bounded footflower pools missing"); quit(1); return
	for i in range(4):
		if world.keepsakes.pickups[i].get_node_or_null("KeepsakeGuidingLight")==null or world.keepsakes.labels[i].visible:
			push_error("Packaged guiding pickup light missing or replaced by idle text"); quit(1); return
	var pouch: Node3D=world.folk.items.flint_pouch.anchor.get_node("Object")
	if pouch.get_node_or_null("GatheredClothBody")==null or pouch.get_node("GatheredClothBody").mesh.get_faces().size()<12000:
		push_error("Packaged gathered pouch still uses the former coarse oval"); quit(1); return
	if not world.sfx.SOUNDS.has("firework_launch") or world.sfx.SOUNDS.firework_burst.get_length()<1.0 or world.courtyard.landscape.collection_reward.glow_light==null:
		push_error("Packaged firework audio or stele radiance missing"); quit(1); return
	ui._toggle_hint()
	for frame in range(4): await process_frame
	if not paused or world.guidance.cards[0].visible or ui.hint_panel.current_goal.text.is_empty():
		push_error("Packaged help lacks current goal or fails to hide gameplay guidance"); quit(1); return
	ui._close_hint()
	for frame in range(4): await process_frame
	var marker := FileAccess.open(output.path_join("bundle-check.json"), FileAccess.WRITE)
	marker.store_string(JSON.stringify({"result": "PLAYTEST_BUNDLE_OK", "engine": Engine.get_version_info().string,
		"cards": 8, "music_tracks": 4, "cover_and_level_one_loaded_from_shipped_pck": true,
		"mandatory_large_stele_seal_supplied_floral_paper_and_card_rotation_audio_verified": true,
		"sharp_canvas_text_and_three_scene_detail_pass_verified": true,
		"five_supplied_films_and_original_card_cues_solid_stele_and_right_return_verified": true,
		"glowing_keepsakes_and_stele_refined_pouch_interactive_firework_audio_and_cleared_footflowers_verified": true,
		"latest_volume_and_3d_craft_verified": folk_verified, "latest_grand_court_verified": grand_verified,
		"planar_controls_and_stone_handoff_verified": planar_verified,
		"upper_right_sound_and_concept_scenery_verified": scenery_verified,
		"sound_entry_large_plaques_and_walkway_verified": walkway_verified,
		"all_21_cultural_items_18_photos_supplied_cover_and_tapered_waterfall_verified": photo_guide_verified,
		"achievement_book_21_items_seven_ethnic_associations_eight_badges_and_session_reset_verified": achievement_verified,
		"per_object_stories_unique_activities_cuan_titles_and_parcel_paper_verified": activity_verified,
		"all_runtime_text_cuan_and_slightly_bolder_headings_verified": typography_verified,
		"larger_text_woven_crafts_curved_waterfall_stone_arrival_and_bird_paper_receipts_verified": craft_polish_verified,
		"layered_banks_curved_roofs_blank_cloth_and_supported_stele_lift_verified": stone_roof_verified,
		"architectural_lantern_groups_two_stele_activity_note_and_centered_receipt_verified": two_steles_verified,
		"cooperative_teaching_alternating_clues_tension_control_and_joint_courtyard_design_verified": cooperative_verified,
		"continuous_panorama_native_architectural_foliage_details_and_lamp_aureoles_verified": scene_art_verified,
		"scattered_keepsakes_shared_pickup_bag_and_courtyard_inventory_verified": keepsakes_verified,
		"distinct_chronology_ear_only_listening_keypad_enter_floral_world_scroll_six_colour_sparks_and_visible_pier_verified": feedback_verified,
		"cooperative_rubbing_before_reading_and_no_role_clue_bypass_verified": rubbing.completed,
		"owner_only_keepsake_pickup_verified": world.keepsakes.collected[0],
		"compact_active_work_without_route_or_switch_buttons_current_goal_help_and_pier_barrier_verified": true,
		"city_gate_tiled_roof_and_runtime_planted_work_jump_motion_verified": gate_motion_verified,
		"slower_real_carry_actor_hoist_crafted_alcove_and_raised_key_scroll_audio_verified": true,
		"twenty_one_stories_twelve_mechanisms_actual_resist_craft_mouse_completion_and_object_locators_verified": true,
		"shared_centered_receipts_and_four_real_bearers_flat_arrival_restore_controls_and_raise_verified": craft_polish_verified}, "\t"))
	marker.close()
	print("PLAYTEST_BUNDLE_OK: isolated shipped PCK, cover, eight cards, four scores, goal/restart, bundled engine notices")
	_stop_bundle_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	var drain_until: int = Time.get_ticks_msec()+100
	while Time.get_ticks_msec()<drain_until: await process_frame
	quit(0)


func _stop_bundle_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D: node.stop()
	for child in node.get_children(): _stop_bundle_audio(child)


func _is_cuan(font: Font, typography: Script) -> bool:
	if font==null: return false
	if font==typography.body_font() or font==typography.heading_font() or font==typography.CUAN_FONT: return true
	if font is FontVariation: return _is_cuan(font.base_font,typography)
	return font.resource_path=="res://assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf"


func _check_cuan_tree(node: Node, typography: Script) -> bool:
	if node is Label or node is Button or node is Label3D or node is RichTextLabel:
		var fonts: Array[Font] = []
		if node is Label3D: fonts.append(node.font)
		elif node is RichTextLabel:
			for key in ["normal_font","bold_font","italics_font","bold_italics_font","mono_font"]: fonts.append(node.get_theme_font(key))
		else: fonts.append(node.get_theme_font("font"))
		for font in fonts:
			if not _is_cuan(font,typography):
				push_error("Non-Cuan runtime text at "+str(node.get_path())+" font="+str(font)); return false
	for child in node.get_children():
		if not _check_cuan_tree(child,typography): return false
	return true
