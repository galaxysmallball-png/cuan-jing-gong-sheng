extends "res://tools/verify_local_coop.gd"

var art_scene_path: String = "res://scenes/characters/deng_shunian_character.tscn"
var art_name: String = "邓书年"
var art_key: String = "deng"
var portrait_center: float = 1.43
var face_center: float = 1.43
var neck_center: float = 1.31
var show_apron_detail: bool = false
var studio_subtitle: String = ""
var accessory_detail_title: String = "绣花围裙与随身工具"
var accessory_center: float = 0.80
var accessory_rotation: float = 0.0
var accessory_size: float = 0.62
var studio_spacing: float = 1.0
var studio_size: float = 2.22

func _run() -> void:
	if capture:
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1600,1000)
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
		await _render_studio()
		capture_viewport.size = Vector2i(1280,720)
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
	await _frames(25)
	if not _one_deng_model(): _fail("Deng's detailed model is not attached exactly once"); return
	await _start_default_party()
	if not await _duo_walk(12.6,11.7): _fail("Character cannot walk into the stele courtyard"); return
	await _frames(60)
	_save_coop("deng-in-game")
	var visual: Node3D = party._visual(player)
	var model: Node3D = visual.detailed_model
	if model.skeleton.get_bone_count() < 20 or model.animation_player.get_animation_list().size() < 6:
		_fail("The imported Blender skeleton or six animation clips are missing"); return
	if not _faces_front(visual): _fail("Walking right does not show the front three-quarter view"); return
	await _press_key(KEY_A,true)
	await _frames(44)
	await _press_key(KEY_A,false)
	await _frames(25)
	if not _faces_back(visual): _fail("Walking left does not reveal the real back of the model"); return
	_save_coop("deng-in-game-back")
	await _frames(30)
	if not _faces_back(visual): _fail("Releasing movement unexpectedly turns the back to the camera"); return
	await _press_key(KEY_W,true)
	await _frames(9)
	await _press_key(KEY_W,false)
	if player.global_position.y <= 1.0: _fail("The new character cannot jump"); return
	_save_coop("deng-jump")
	await _frames(60)
	party.switch_to(2,0)
	party.switch_to(0,1)
	await _frames(30)
	if not _one_deng_model() or party._visual(player).detailed_model == null or party._visual(second).detailed_model == null:
		_fail("Switching 2P to Deng leaves the old geometry or duplicates the detailed model"); return
	visual = party._visual(second)
	if not _faces_back(visual): _fail("Switching a stopped Deng to 2P loses his heading"); return
	await _press_key(KEY_RIGHT,true)
	await _frames(30)
	await _press_key(KEY_RIGHT,false)
	await _frames(20)
	if not _faces_front(visual): _fail("2P cannot turn Deng back toward the front"); return
	await _press_key(KEY_LEFT,true)
	await _frames(30)
	await _press_key(KEY_LEFT,false)
	await _frames(20)
	if not _faces_back(visual): _fail("2P cannot turn Deng toward the back"); return
	_save_coop("deng-player2")
	party.switch_to(1,1)
	# Freeze only follower locomotion briefly to inspect the role's inherited heading.
	var deng_follower: CharacterBody3D = party.role_body(0)
	deng_follower.set_physics_process(false)
	deng_follower.velocity = Vector3.ZERO
	await _frames(5)
	if not _faces_back(party._visual(deng_follower)): _fail("Deng loses his heading when becoming a follower"); return
	deng_follower.set_physics_process(true)
	await _frames(45)
	if not _one_deng_model() or party._visual(party.role_body(0)).detailed_model == null:
		_fail("Deng loses his model when becoming a follower"); return
	_save_coop("deng-follower")
	party.switch_to(0,0)
	await _frames(4)
	model = party._visual(player).detailed_model
	model.animate_model(0.1,1.5,true,true,false)
	if model.current_state != "push":
		_fail("The model cannot assume a pushing pose"); return
	model.animate_model(0.1,0,true,false,true)
	if model.current_state != "carry":
		_fail("The model cannot assume a carrying pose"); return
	model.animate_model(0.1,0,true,false,false,true)
	if model.current_state != "inspect": _fail("Reading does not select the inspection animation"); return
	await _click_stone(1)
	await _key(KEY_ESCAPE)
	if player.interaction_locked: _fail("The new art blocks inscription inspection"); return
	await _tap("restart_lesson")
	await _frames(45)
	if not _unique_ids() or not _one_deng_model() or party.active_id != 0 or party.second_id != 1:
		_fail("Reset does not restore Deng and the four distinct characters"); return
	print("DENG_CHARACTER_OK: refined rigged model, front/back turning for 1P and 2P, stationary and follower heading, jump, unique ownership, pushing/carrying/reading, stone inspection and reset")
	quit(0)


func _one_deng_model() -> bool:
	var count: int = 0
	for body in party.all_bodies():
		var visual: Node3D = party._visual(body)
		if body.character_id == 0:
			count += 1
			if visual.detailed_model == null or visual.get_node("Torso").visible: return false
		elif body.character_id in [1, 2, 3]:
			if visual.detailed_model == null or visual.get_node("Torso").visible: return false
		elif visual.detailed_model != null or not visual.get_node("Torso").visible: return false
	return count == 1


func _faces_front(visual: Node3D) -> bool:
	var front: Vector3 = visual.global_basis * Vector3.BACK
	return front.x > 0.3 and front.z > 0.3


func _faces_back(visual: Node3D) -> bool:
	var front: Vector3 = visual.global_basis * Vector3.BACK
	return front.x < -0.3 and front.z < -0.3


func _render_studio() -> void:
	var stage := Node3D.new()
	capture_viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.72,0.69,0.60)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.86,0.87,0.84)
	settings.ambient_light_energy = 0.4
	environment.environment = settings
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38,-30,0)
	light.light_color = Color(1,0.97,0.92)
	light.light_energy = 1.15
	light.shadow_enabled = true
	stage.add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2,2.2,3)
	fill.light_color = Color(0.68,0.78,0.88)
	fill.light_energy = 0.65
	fill.omni_range = 7
	stage.add_child(fill)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20,20)
	floor.mesh = plane
	floor.position.y = -0.01
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.58,0.57,0.51)
	material.roughness = 1
	floor.material_override = material
	stage.add_child(floor)
	var models: Array[Node3D] = []
	for index in range(3):
		var character: Node3D = load(art_scene_path).instantiate()
		stage.add_child(character)
		character.pose(0,0,0,true,false,false)
		character.position.x = (index-1)*studio_spacing
		character.rotation.y = [0,-PI/2,PI][index]
		models.append(character)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = studio_size
	camera.position = Vector3(0,1.10,5)
	stage.add_child(camera)
	camera.look_at(Vector3(0,0.97,0))
	var canvas := CanvasLayer.new()
	stage.add_child(canvas)
	var title: Label = _studio_label(canvas,Vector2(60,30),Vector2(1480,50),36,art_name+" · 游戏角色模型")
	var subtitle: Label = _studio_label(canvas,Vector2(60,85),Vector2(1480,36),20,"包头与白穗 / 卷袖马甲 / 绣花围裙 / 木锤铁凿" if show_apron_detail else "方巾 / 旧蓝长衫 / 交领与腰带 / 玉佩墨筒 / 书袋与卷轴")
	if not studio_subtitle.is_empty(): subtitle.text = studio_subtitle
	var captions: Array[Label] = []
	for index in range(3):
		var caption: Label = _studio_label(canvas,Vector2(205+index*450,938),Vector2(300,40),24,["正 面","侧 面","背 面"][index])
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		captions.append(caption)
	await _frames(12)
	_save_coop(art_key+"-three-views")
	for index in [1,2]: models[index].visible = false
	models[0].position.x = 0
	models[0].rotation.y = -0.25
	for caption in captions: caption.visible = false
	subtitle.visible = false
	capture_viewport.size = Vector2i(1000,1000)
	title.text = art_name+" · 面部与服装细节"
	title.add_theme_font_size_override("font_size",28)
	camera.size = 0.89
	camera.position = Vector3(0.25,portrait_center+0.06,3)
	camera.look_at(Vector3(0,portrait_center,0))
	await _frames(8)
	_save_coop(art_key+"-portrait")
	title.text = art_name+" · 面部细节"
	camera.size = 0.48
	camera.position = Vector3(0.08,face_center+0.03,3)
	camera.look_at(Vector3(0,face_center,0))
	models[0].rotation.y = 0
	await _frames(8)
	_save_coop(art_key+"-face-detail")
	title.text = "颈部与阴影"
	models[0].rotation.y = -0.55
	camera.size = 0.52
	camera.position = Vector3(0.08,neck_center+0.06,3)
	camera.look_at(Vector3(0,neck_center,0))
	await _frames(8)
	_save_coop(art_key+"-neck-detail")
	if show_apron_detail:
		title.text = accessory_detail_title
		models[0].rotation.y = accessory_rotation
		camera.size = accessory_size
		camera.position = Vector3(0,accessory_center+0.08,3)
		camera.look_at(Vector3(0,accessory_center,0))
		await _frames(8)
		_save_coop(art_key+"-apron-detail")
	title.text = art_name+" · 行走姿态"
	camera.size = 2.10
	camera.position = Vector3(0.5,1.15,4)
	camera.look_at(Vector3(0,0.97,0))
	models[0].rotation.y = 0.5
	models[0].pose(0.13,1.4,3,true,false,false)
	await _frames(8)
	_save_coop(art_key+"-walk-studio")
	stage.queue_free()
	await process_frame
	await process_frame


func _studio_label(parent: Node, at: Vector2, size: Vector2, font_size: int, words: String) -> Label:
	var label := Label.new()
	label.position = at
	label.size = size
	label.text = words
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","SimHei"])
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color(0.16,0.17,0.14))
	parent.add_child(label)
	return label
