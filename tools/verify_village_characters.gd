extends "res://tools/verify_deng_character.gd"

const VILLAGER_PROFILES: Array[Dictionary] = [
	{"key":"a_qiang", "label":"阿强（壮族）", "bones":22, "center":1.40, "face":1.53, "accessory":0.93, "detail":"红腰带、木鞘砍刀与盘扣", "subtitle":"露额头巾 / 对襟短衣 / 红腰带 / 榫卯杉木梁 / 草鞋"},
	{"key":"yu_nan", "label":"玉喃（傣族）", "bones":23, "center":1.40, "face":1.53, "accessory":0.34, "detail":"黑筒裙的孔雀傣锦纹样", "subtitle":"低髻木梳 / 水红交领衣 / 银腰带 / 孔雀傣锦 / 驮布毛驴"},
	{"key":"pu_mo", "label":"普嫫（彝族）", "bones":28, "center":1.35, "face":1.44, "accessory":0.86, "detail":"旧披毡、黑陶茶罐与三足铜火盆", "subtitle":"黑布包头与灰发 / 细彩边蓝衣 / 旧羊毛披毡 / 茶罐与火盆"},
	{"key":"pack_donkey", "label":"玉喃的驮布毛驴", "bones":22, "center":1.16, "face":1.25, "accessory":0.84, "detail":"编织驮筐、布卷与傣锦", "subtitle":"灰白毛色 / 长耳 / 笼头 / 编织驮筐 / 傣锦布卷"}
]


func _run() -> void:
	if capture:
		if DisplayServer.get_name() == "headless": _fail("Villager previews require a real renderer"); return
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
	for profile in VILLAGER_PROFILES:
		var scene_path: String = "res://scenes/characters/" + profile.key + "_character.tscn"
		var model: Node3D = load(scene_path).instantiate()
		root.add_child(model)
		if model.skeleton.get_bone_count() != profile.bones or model._clips.size() != 6:
			_fail("Villager rig/clip mismatch: " + profile.key); return
		for state in ["idle", "walk", "push", "carry", "jump", "inspect"]:
			model.pose(0.2, 0, 2 if state == "walk" else 0, state != "jump", state == "push", state == "carry", state == "inspect")
			if model.current_state != state: _fail("Missing pose for " + profile.key); return
			if profile.key == "a_qiang":
				var beam: int = model.skeleton.find_bone("beam")
				if (model.skeleton.get_bone_pose_scale(beam).length() < 0.01) != (state in ["push", "carry", "jump"]):
					_fail("A Qiang beam fails to stow/restore"); return
			if profile.key == "yu_nan":
				var donkey: Node3D = model.get_node("PackDonkey")
				if donkey.skeleton.get_bone_count() != 22 or donkey.current_state != ("walk" if state == "walk" else "idle"):
					_fail("Yu Nan's donkey fails to follow the walking/idle pose"); return
		model.queue_free()
		await process_frame
		if capture:
			art_scene_path = scene_path
			art_name = profile.label
			art_key = profile.key.replace("_", "-")
			portrait_center = profile.center
			face_center = profile.face
			neck_center = profile.center - 0.03
			studio_subtitle = profile.subtitle
			show_apron_detail = true
			accessory_detail_title = profile.detail
			accessory_center = profile.accessory
			accessory_rotation = 0
			accessory_size = 1.0 if profile.key in ["pu_mo", "pack_donkey"] else 0.62
			studio_spacing = 1.64 if profile.key == "yu_nan" else 1.22
			studio_size = 3.45 if profile.key == "yu_nan" else 2.55
			capture_viewport.size = Vector2i(1600, 1000)
			await _render_studio()
	if capture:
		await _render_lineup()
		capture_viewport.size = Vector2i(1280, 720)
	await _create_world()
	if party.NAMES.size() != 4 or not _unique_ids(): _fail("Villagers added selectable party slots"); return
	ui.chapter_preview.pressed.emit()
	await _frames(50)
	# Fixture covers only upstream tasks; full co-op regression checks those tasks.
	bridge.step = 3
	bridge.timber_prepared = true
	bridge.material_delivered = true
	bridge.crate.position = Vector3(9.5, 0.5, -1.9)
	bridge.get_node("MaterialCrate/Collision").set_deferred("disabled", true)
	party.switch_to(3, 0)
	if not await _duo_walk(22.5, 23.0): _fail("Cannot approach the villager call point"); return
	await _hold()
	var qiang: Node3D = bridge._a_qiang.get_node("Character")
	if bridge.step != 4 or not bridge._a_qiang.is_visible_in_tree() or qiang.current_state != "walk" or bridge._a_qiang.get_node("NameLabel").text != "阿强（壮族）":
		_fail("Calling the villagers does not bring named A Qiang with A Cai"); return
	_save_coop("villagers-creek-approach")
	await _frames(350)
	if qiang.current_state != "idle" or bridge.bridge_ready: _fail("A Qiang fails to stop or builds automatically"); return
	if not await _duo_walk(30.5, 30.3): _fail("Cannot regroup beside the villagers"); return
	await _frames(160)
	_save_coop("villagers-creek")
	Input.action_press("interact")
	Input.action_press("p2_interact")
	for frame in range(160):
		await physics_frame
		if bridge.building: break
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(20)
	if not bridge.building or qiang.current_state != "carry" or qiang.skeleton.get_bone_pose_scale(qiang.skeleton.find_bone("beam")).length() > 0.01:
		_fail("A Qiang keeps the shoulder beam across the assembly pose"); return
	_save_coop("villagers-creek-work")
	await _frames(150)
	if not bridge.bridge_ready or bridge.gap_stabilized or qiang.current_state != "idle" or not bridge._dialogue_label.text.begins_with("阿强（壮族）："):
		_fail("A Qiang assembly completion, dialogue or required rescue changed"); return
	world.queue_free()
	await process_frame
	await process_frame
	await _create_world()
	ui.garden_preview.pressed.emit()
	await _frames(60)
	if court.get_node("Residents").visible or court.lamp_count != 0: _fail("Garden NPCs skip the player's personal tasks"); return
	if not await _duo_walk(50.3, 49.7): _fail("Cannot reach the garden pedestal"); return
	await _dual_hold(false, true)
	if court.tablet_placed: _fail("A villager replaces the second player at the stele"); return
	await _dual_hold()
	if not court.tablet_placed: _fail("Players cannot raise the stele"); return
	if not await _duo_walk(46.2, 49.7): _fail("Cannot place the first pair of objects"); return
	await _dual_hold()
	party.switch_to(2, 0)
	party.switch_to(3, 1)
	if not await _duo_walk(51.7, 52.8): _fail("Cannot place the second pair of objects"); return
	await _dual_hold()
	if court.lamp_count != 4 or not court.personal_items_done() or not court.get_node("Residents").visible:
		_fail("The two garden villagers do not appear for oil lamps"); return
	if not court.landscape.dialogue_text.text.begins_with("普嫫（彝族）："):
		_fail("Pu Mo's invitation lacks her name and ethnicity"); return
	if not await _duo_walk(43.7, 43.4): _fail("Cannot return to the lamp table"); return
	await _frames(300)
	var pumo: Node3D = court.get_node("Residents/ResidentA/Character")
	var yunan: Node3D = court.get_node("Residents/ResidentB/Character")
	var pack: Node3D = yunan.get_node("PackDonkey")
	if pumo.current_state != "inspect" or yunan.current_state != "idle" or pack.current_state != "idle" or court.oil_carriers != [-1, -1, -1]:
		_fail("Garden idle/work states or unclaimed oil lamps are wrong"); return
	_save_coop("villagers-garden-table")
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(4)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	if court.oil_carriers[0] != 2 or court.oil_carriers[1] != 3 or not court.landscape.dialogue_text.text.begins_with("玉喃（傣族）：") or yunan.current_state != "inspect":
		_fail("Yu Nan's named lamp handoff, work pose or carrier ownership fails"); return
	_save_coop("villagers-garden-handoff")
	if not await _duo_walk(42.2, 45.0): _fail("Cannot deliver the first two lamps"); return
	await _dual_hold()
	if court.lamp_count != 6: _fail("Villagers changed parallel oil lamp delivery"); return
	if not await _duo_walk(43.7, 43.4): _fail("Cannot collect the final lamp"); return
	await _dual_hold(true, false)
	if not await _duo_walk(55.5, 55.8): _fail("Cannot carry the final lamp"); return
	await _dual_hold(true, false)
	if court.lamp_count != 7 or not court.landscape.dialogue_text.text.contains("普嫫（彝族）：火点着了，就不散了。"):
		_fail("Pu Mo's final line or seventh player-delivered lamp is missing"); return
	_save_coop("villagers-seven-lights")
	await _frames(180)
	if not court.court_lit or absf(court.warm_light.light_energy - 2.8) > 0.01: _fail("Seven lights no longer complete the court"); return
	await _tap("restart_lesson")
	await _frames(40)
	if court.get_node("Residents").visible or bridge.helpers_called or pumo.current_state != "idle" or yunan.current_state != "idle" or pack.current_state != "idle" or not _unique_ids():
		_fail("T does not reset villagers, donkey and original party"); return
	print("VILLAGE_CHARACTERS_OK: three distinct rigs/six clips and 22-bone pack donkey, named ethnic labels, unchanged four playable roles, actual call/walk/idle/assembly, timber stow/restore, original rescue requirement, garden entry/personal items/lamp handoff/delivery/seven lights/Pu Mo line/reset")
	quit(0)


func _create_world() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	if capture: capture_viewport.add_child(world)
	else:
		root.add_child(world)
		current_scene = world
	player = world.get_node("Player")
	party = world.get_node("Party")
	second = party.second_player
	ui = world.get_node("PartyUI")
	first = world.get_node("Spaces/Space01/Cooperation")
	bridge = world.get_node("Spaces/Space02/BridgeCooperation")
	court = world.get_node("Spaces/Space03/CourtyardCooperation")
	await _frames(30)


func _render_lineup() -> void:
	capture_viewport.size = Vector2i(1600, 1000)
	var stage := Node3D.new()
	capture_viewport.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.67, 0.65, 0.58)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.86, 0.87, 0.84)
	env.environment.ambient_light_energy = 0.55
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 1.1
	light.shadow_enabled = true
	stage.add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1, 2.6, 3)
	fill.omni_range = 10
	fill.light_color = Color(0.76, 0.83, 0.91)
	fill.light_energy = 0.75
	stage.add_child(fill)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.58, 0.57, 0.51)
	floor_material.roughness = 1
	floor.material_override = floor_material
	floor.position.y = -0.01
	stage.add_child(floor)
	var layer := CanvasLayer.new()
	stage.add_child(layer)
	_studio_label(layer, Vector2(60, 35), Vector2(1480, 55), 36, "爨境·共生 · 三位村民角色首版")
	_studio_label(layer, Vector2(60, 92), Vector2(1480, 40), 21, "独立网格与骨架 / 服饰与随身物件 / 玉喃的驮布毛驴")
	for index in range(3):
		var profile: Dictionary = VILLAGER_PROFILES[index]
		var model: Node3D = load("res://scenes/characters/" + profile.key + "_character.tscn").instantiate()
		stage.add_child(model)
		model.position.x = [-1.52, 0.55, 1.83][index]
		model.rotation.y = 0.15
		model.pose(0, 0, 0, true, false, false)
		var label: Label = _studio_label(layer, Vector2([100, 690, 1160][index], 915), Vector2(350, 50), 27, profile.label)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.0
	stage.add_child(camera)
	camera.position = Vector3(0.05, 1.15, 5)
	camera.look_at(Vector3(0.05, 0.95, 0))
	await _frames(12)
	_save_coop("villagers-lineup")
	stage.queue_free()
	await process_frame
	await process_frame
