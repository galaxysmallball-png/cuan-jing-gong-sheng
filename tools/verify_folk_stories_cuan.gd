extends "res://tools/verify_photo_guide.gd"

const Activities = preload("res://scripts/folk_activity_profiles.gd")
const UiSkin = preload("res://scripts/interface_skin.gd")


func _initialize() -> void:
	capture="--capture-folk-stories" in OS.get_cmdline_user_args()
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",ProjectSettings.globalize_path("res://previews/folk-stories-achievement-profile.json"))
	create_timer(240,true).timeout.connect(func(): _fail("Per-object story/mini-game check timed out"))
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
	await _frames(16)
	for control in [ui.primary,ui.secondary,ui.culture_button,ui.sound_button,ui.achievement_button,ui.heading,world.room_label]:
		if control.get_theme_font("font")!=UiSkin.heading_font(): _fail("Title or directional entry still uses a different font: "+str(control)); return
	_save_coop("folk-stories-cuan-title")
	await _start_default_party()
	await _put(12.5,13)
	await _click_stone(0)
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(110)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(3)
	if first.step!=2 or not ui.satchel_notice.visible or not ui.satchel_notice.text.contains("包裹") or not ui.satchel_notice.text.contains("B"):
		_fail("Clue receipt is hidden while looking at the stele"); return
	var heading_width: float = first.inspector.heading.get_theme_font("font").get_string_size(first.inspector.heading.text,HORIZONTAL_ALIGNMENT_LEFT,-1,28).x
	if first.inspector.heading.position.x+heading_width>ui.satchel_notice.position.x:
		_fail("Clue receipt overlaps the viewer title"); return
	_save_coop("folk-stories-visible-clue-receipt")
	await _near_key(KEY_B)
	await _frames(3)
	if not ui.satchel.visible or not paused or ui.satchel.close_button.get_theme_stylebox("normal").texture!=UiSkin.NOTICE_PAPER:
		_fail("Parcel button does not use the supplied flower paper"); return
	for card in ui.satchel.cards:
		if card.get_theme_stylebox("panel").texture!=UiSkin.PARCEL_PAPER: _fail("Parcel note cards do not use the supplied paper"); return
	_save_coop("folk-stories-flower-parcel")
	await _near_key(KEY_B)
	await _near_key(KEY_ESCAPE)
	var signatures: Dictionary = {}
	var weight_sets: Dictionary = {}
	var completed: int = 0
	for stage in range(3):
		if stage==1:
			world.start_creek_preview()
			bridge.step=4
			bridge.helpers_called=true
			bridge._helpers.visible=true
		elif stage==2:
			world.start_garden_preview()
			court.tablet_placed=true
			for index in range(4): court.items_done[index]=true
			court.lamp_count=4
			court.landscape.sync_state()
		await _frames(32)
		for id in world.folk.items:
			if world.folk.items[id].chapter!=stage: continue
			world.folk.open_item(id)
			await _frames(4)
			var folk: CanvasLayer = world.folk
			var board: Control = folk.board
			if not Activities.PROFILES.has(id) or not folk.activity_story.visible or board.visible or board.running:
				_fail("Item has no story gate: "+id); return
			if folk.activity_portrait.texture==null or folk.activity_story_body.text!=Activities.PROFILES[id].story or not folk.activity_story_heading.text.contains(Activities.PROFILES[id].speaker):
				_fail("Story/portrait is not specific to this item and character: "+id); return
			if folk.activity_story_body.get_line_count()>folk.activity_story_body.get_visible_line_count() or folk.description.get_line_count()>folk.description.get_visible_line_count():
				_fail("Story or object text clips: "+id); return
			board.choose(0)
			if board.answered!=0 or true in board.packs: _fail("Playing before story confirmation changes progress: "+id); return
			if id in ["scholar_tools","miao_batik","garden_item_2"]: _save_coop("folk-stories-prologue-"+id)
			if id=="yang_trade_goods": await _near_key(KEY_ENTER)
			else: await _click_at(folk.start_activity_button.get_global_rect().get_center())
			if not board.running or folk.activity_story.visible or not board.visible: _fail("Cannot formally start the activity: "+id); return
			var signature: String = JSON.stringify([board.mode,board.weights if board.mode==1 else board.recipe])
			if signatures.has(signature): _fail("Different objects reuse an identical challenge: "+id); return
			signatures[signature]=id
			var before_clues: Array[bool] = first.clues.duplicate()
			var before_lights: int = court.lamp_count
			if board.mode==1:
				weight_sets[JSON.stringify(board.weights)]=true
				if id in ["caravan_pack","a_cai_basket","donkey"]: _save_coop("folk-stories-weight-"+id)
				var solution: int = -1
				for mask in range(1<<board.weights.size()):
					var amount: int = 0
					for index in range(board.weights.size()):
						if mask&(1<<index): amount+=board.weights[index]
					if amount*2==board.total_weight(): solution=mask; break
				if solution<0: _fail("Weight profile is unsolvable: "+id); return
				for index in range(board.weights.size()):
					if solution&(1<<index): await _click_at(board.get_global_rect().position+board.option_position(index))
			else:
				if board.mode==2:
					board.choose(board.recipe[0])
					if board.answered!=0: _fail("Music accepts response before demonstration ends: "+id); return
					await _frames(ceili((board.recipe.size()+1)*.48*60)+20)
					if board.playing_demo: _fail("Per-item music demonstration never finishes: "+id); return
				var wrong: int = (board.recipe[0]+1)%(board.actions.size() if board.mode==3 else 3)
				await _click_at(board.get_global_rect().position+board.option_position(wrong))
				if board.answered!=0 or board.won: _fail("Incorrect order is accepted: "+id); return
				for choice in board.recipe: await _click_at(board.get_global_rect().position+board.option_position(choice))
			await _frames(3)
			completed+=1
			if not board.won or not folk.completed_items.has(id) or folk.completed_items.size()!=completed:
				_fail("Activity completion is not tracked by item: "+id); return
			if first.clues!=before_clues or court.lamp_count!=before_lights: _fail("An optional activity completes main tasks: "+id); return
			if id in ["dai_brocade","scholar_tools","garden_item_2"]: _save_coop("folk-stories-finished-"+id)
			await _click_at(folk.play_again.get_global_rect().get_center())
			if not folk.activity_story.visible or board.running or board.won: _fail("Retry does not reset to the corresponding story: "+id); return
			await _near_key(KEY_ESCAPE)
	if completed!=21 or signatures.size()!=21 or weight_sets.size()!=6 or world.folk.games_done!=[true,true,true]:
		_fail("Not all per-object variations and chapter records are present"); return
	var retained: int = world.achievements.collected.size()
	world.restart_current_scene()
	await _frames(4)
	for id in world.folk.completed_items:
		if world.folk.items[id].chapter>=2: _fail("Scene restart retains completed mini-games from that scene"); return
	if world.achievements.collected.size()!=retained: _fail("Activity restart clears permanent achievements"); return
	print("FOLK_STORIES_CUAN_OK: title/direction/button Cuan font, visible in-stele clue receipt and B review, supplied flower parcel cards/button, 21 unique character/object prologues with portraits and start gates, 21 distinct solvable activities including six weight sets and 3-7 step motifs / 4-7 notes / ordered preparations, actual mouse play and wrong-order handling, per-item completion, replay and chapter reset without main-task or achievement loss")
	quit(0)
