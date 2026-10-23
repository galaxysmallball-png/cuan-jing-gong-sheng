extends Control

signal continue_requested
signal cancel_requested

const CharacterNames = preload("res://scripts/character_names.gd")
const Party = preload("res://scripts/party.gd")
const UiStyle = preload("res://scripts/interface_skin.gd")
const BACKGROUND = preload("res://assets/interface/card_draw_background.png")
const CARD_KEYS: Array[String] = ["deng_shunian", "shi_aduo", "lao_qing", "yang_sanniang", "a_cai", "pu_mo", "yu_nan", "a_qiang"]
const CARD_NAMES: Array[String] = ["邓书年（汉族）", "石阿朵（白族）", "老箐（彝族）", "杨三娘（回族）", "阿彩（苗族）", "普嫫（彝族）", "玉喃（傣族）", "阿强（壮族）"]
const CARD_TEXTURES: Array[Texture2D] = [
	preload("res://assets/character_cards/deng_shunian.png"),
	preload("res://assets/character_cards/shi_aduo.png"),
	preload("res://assets/character_cards/lao_qing.png"),
	preload("res://assets/character_cards/yang_sanniang.png"),
	preload("res://assets/character_cards/a_cai.png"),
	preload("res://assets/character_cards/pu_mo.png"),
	preload("res://assets/character_cards/yu_nan.png"),
	preload("res://assets/character_cards/a_qiang.png")
]
enum Phase { FIRST_SPIN, FIRST_REVEAL, SECOND_SPIN, FINAL_REVEAL, READY }
const RADIUS: float = 3.2
const FIRST_SECONDS: float = 3.4
const FIRST_REVEAL_SECONDS: float = 0.65
const SECOND_SECONDS: float = 2.4
const FINAL_SECONDS: float = 0.8
const STEP: float = TAU / 8.0
var phase: Phase = Phase.FIRST_SPIN
var elapsed: float = 0.0
var orbit_angle: float = 0.0
var _start_angle: float = 0.0
var _end_angle: float = 0.0
var result_roles: Array[int] = []
var cards: Array[Node3D] = []
var fronts: Array[MeshInstance3D] = []
var frames: Array[MeshInstance3D] = []
var backs: Array[MeshInstance3D] = []
var viewport: SubViewport
var camera: Camera3D
var axis: MeshInstance3D
var title: Label
var subtitle: Label
var progress: Label
var continue_button: Button
var skip_button: Button
var replay_button: Button
var cancel_button: Button
var slot_names: Array[Label] = []
var slot_roles: Array[Label] = []
var _font: Font
var _running: bool = false
var _selected: Array[int] = []
var _sound_sector: int = -100


func _rotation_sound(speed: float, active: bool) -> void:
	var audio: Node=get_tree().get_first_node_in_group("game_audio")
	if audio!=null: audio.update_draw_rotation(speed,active)


func _settle_rotation() -> void:
	var audio: Node=get_tree().get_first_node_in_group("game_audio")
	if audio!=null: audio.settle_draw_rotation()


func _sound(kind: String) -> void:
	var audio: Node = get_tree().get_first_node_in_group("game_audio")
	if audio != null: audio.play(kind)


static func choose_roles(player_count: int, generator: RandomNumberGenerator = null) -> Array[int]:
	# All eight cards are shown; only the original four protagonists are eligible.
	# Choose before the orbit begins so the final pose cannot land on a villager.
	var random: RandomNumberGenerator = generator
	if random == null:
		random = RandomNumberGenerator.new()
		random.randomize()
	var pool: Array[int] = [0, 1, 2, 3]
	var chosen: Array[int] = []
	for slot in range(clampi(player_count, 1, 2)):
		var index: int = random.randi_range(0, pool.size() - 1)
		chosen.append(pool[index])
		pool.remove_at(index)
	return chosen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = preload("res://scripts/interface_skin.gd").body_font()

	var background := TextureRect.new()
	background.name = "DrawBackground"
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	container.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	stage.add_child(environment)
	camera = Camera3D.new()
	camera.fov = 43
	camera.position = Vector3(0, 0.8, 10)
	stage.add_child(camera)
	camera.look_at(Vector3.ZERO)
	# An actual vertical axis and two orbit hoops make the rotation readable.
	axis = MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.009
	rod.bottom_radius = 0.009
	rod.height = 3.7
	axis.mesh = rod
	axis.material_override = _material(Color(0.46, 0.37, 0.19, 0.58))
	stage.add_child(axis)
	for height in [-1.67, 1.67]:
		var hoop := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = RADIUS - 0.012
		torus.outer_radius = RADIUS + 0.012
		torus.rings = 96
		torus.ring_segments = 8
		hoop.mesh = torus
		hoop.position.y = height
		hoop.material_override = _material(Color(0.40, 0.33, 0.20, 0.32))
		stage.add_child(hoop)
	for index in range(8): _make_card(stage, index)
	var heading_paper := Panel.new()
	heading_paper.position = Vector2(346, 16)
	heading_paper.size = Vector2(588, 84)
	heading_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper_style: StyleBoxFlat = UiStyle.paper()
	paper_style.bg_color = Color(0.96, 0.92, 0.82, 0.88)
	paper_style.border_color.a = 0.18
	paper_style.shadow_size = 0
	heading_paper.add_theme_stylebox_override("panel", paper_style)
	add_child(heading_paper)
	title = _text(Vector2(240, 18), Vector2(800, 52), 32, "行 旅 签 · 八 方 相 逢", UiStyle.INK)
	subtitle = _text(Vector2(180, 72), Vector2(920, 26), 16, "山有来路，人有相逢。", UiStyle.BRONZE)
	progress = _text(Vector2(340, 607), Vector2(600, 36), 19, "", UiStyle.INK)
	_text_backing(progress)
	for slot in range(2):
		var color := UiStyle.VERMILION if slot == 0 else Color(0.17, 0.32, 0.36)
		slot_names.append(_text(Vector2.ZERO, Vector2(400, 36), 22, "", color))
		slot_roles.append(_text(Vector2.ZERO, Vector2(400, 32), 16, "", UiStyle.INK))
		_text_backing(slot_names[slot])
		_text_backing(slot_roles[slot])
	continue_button = _button("携手入场 · Enter", Vector2(470, 654), Vector2(340, 46), func(): continue_requested.emit(), true)
	skip_button = _button("掠过动画 · Enter / Esc", Vector2(982, 654), Vector2(266, 42), reveal_now)
	replay_button = _button("重看旋牌", Vector2(32, 654), Vector2(190, 42), replay)
	cancel_button = _button("返回题页", Vector2(30, 30), Vector2(142, 38), func(): cancel_requested.emit())
	visible = false


func _material(color: Color, texture: Texture2D = null) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.albedo_texture = texture
	material.roughness = 1
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if color.a < 1: material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _make_card(stage: Node3D, index: int) -> void:
	var card := Node3D.new()
	card.name = CARD_KEYS[index]
	stage.add_child(card)
	cards.append(card)
	var height: float = 3.0
	var width: float = height * CARD_TEXTURES[index].get_width() / float(CARD_TEXTURES[index].get_height())
	var frame := MeshInstance3D.new()
	var board := BoxMesh.new()
	board.size = Vector3(width + 0.055, height + 0.055, 0.024)
	frame.mesh = board
	frame.material_override = _material(Color(0.35, 0.29, 0.18))
	card.add_child(frame)
	frames.append(frame)
	var front := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	front.mesh = quad
	front.position.z = 0.014
	front.material_override = _material(Color.WHITE, CARD_TEXTURES[index])
	card.add_child(front)
	fronts.append(front)
	var back := MeshInstance3D.new()
	back.mesh = quad
	back.position.z = -0.014
	back.rotation.y = PI
	back.material_override = _material(Color(0.11, 0.16, 0.16))
	card.add_child(back)
	backs.append(back)
	var back_text := Label3D.new()
	back_text.text = "爨 境\n\n共 生"
	back_text.font = preload("res://scripts/interface_skin.gd").heading_font()
	back_text.font_size = preload("res://scripts/interface_skin.gd").text_size(76)
	back_text.pixel_size = 0.004
	back_text.modulate = Color(0.68, 0.57, 0.36)
	back_text.outline_size = 0
	back_text.position.z = -0.019
	back_text.rotation.y = PI
	card.add_child(back_text)


func _text(at: Vector2, dimensions: Vector2, font_size: int, words: String, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _font)
	if font_size>=22: label.add_theme_font_override("font",preload("res://scripts/interface_skin.gd").heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(font_size))
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func _text_backing(label: Label) -> void:
	var plate := ColorRect.new()
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.color = Color(0.96, 0.92, 0.82, 0.88)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.show_behind_parent = true
	label.add_child(plate)


func _button(words: String, at: Vector2, dimensions: Vector2, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.position = at
	button.size = dimensions
	button.text = words
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(19 if primary else 16))
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.21, 0.20) if state == "normal" else Color(0.24, 0.29, 0.25)
		style.border_color = Color(0.69, 0.56, 0.32) if primary else Color(0.29, 0.35, 0.32)
		style.set_border_width_all(2 if primary else 1)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color(0.95, 0.85, 0.61) if primary else Color(0.72, 0.76, 0.68))
	button.pressed.connect(callback)
	UiStyle.button(button, primary)
	add_child(button)
	return button


func begin(chosen: Array[int]) -> bool:
	if chosen.size() not in [1, 2]: return false
	for id in chosen:
		if id < 0 or id >= 4 or chosen.count(id) != 1: return false
	result_roles = chosen.duplicate()
	phase = Phase.FIRST_SPIN
	elapsed = 0
	orbit_angle = -0.12
	_start_angle = orbit_angle
	_end_angle = _landing_angle(orbit_angle, chosen[0], 2)
	_selected.clear()
	_sound_sector = -100
	_rotation_sound(0,false)
	_sound("opening_card_flip")
	_running = true
	visible = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if DisplayServer.get_name() != "headless" else SubViewport.UPDATE_DISABLED
	for index in range(8):
		cards[index].visible = true
		cards[index].scale = Vector3.ONE
		frames[index].material_override.albedo_color = Color(0.35, 0.29, 0.18)
	continue_button.visible = false
	continue_button.disabled = true
	replay_button.visible = false
	skip_button.visible = true
	title.text = "行 旅 签 · 八 方 相 逢"
	subtitle.text = "山有来路，人有相逢。"
	for label in slot_names + slot_roles: label.visible = false
	progress.visible = true
	progress.text = "为 1P 结一位同行者……"
	_pose_ring()
	return true


func stop() -> void:
	_rotation_sound(0,false)
	_running = false
	visible = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func replay() -> void:
	begin(result_roles.duplicate())


func is_ready() -> bool:
	return phase == Phase.READY


func _landing_angle(from_angle: float, card_id: int, turns: int) -> float:
	return from_angle + turns * TAU + fposmod(-card_id * STEP - from_angle, TAU)


func _coast(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0, 1), 3)


func _process(delta: float) -> void:
	if not _running or not visible or is_ready():
		_rotation_sound(0,false)
		return
	elapsed += delta
	match phase:
		Phase.FIRST_SPIN, Phase.SECOND_SPIN:
			var duration: float = FIRST_SECONDS if phase == Phase.FIRST_SPIN else SECOND_SECONDS
			orbit_angle = lerpf(_start_angle, _end_angle, _coast(elapsed / duration))
			var sector: int=floori(orbit_angle/STEP)
			if sector!=_sound_sector:
				_sound("opening_card_flip")
				_sound_sector=sector
			_pose_ring()
			if elapsed >= duration:
				_settle_rotation()
				var slot: int = 0 if phase == Phase.FIRST_SPIN else 1
				_selected.append(result_roles[slot])
				frames[result_roles[slot]].material_override.albedo_color = Color(0.95, 0.74, 0.29) if slot == 0 else Color(0.48, 0.82, 0.94)
				phase = Phase.FIRST_REVEAL if slot == 0 and result_roles.size() == 2 else Phase.FINAL_REVEAL
				elapsed = 0
		Phase.FIRST_REVEAL:
			var t: float = smoothstep(0, 1, elapsed / FIRST_REVEAL_SECONDS)
			var card: Node3D = cards[result_roles[0]]
			card.position = Vector3(0, 0, RADIUS).lerp(Vector3(-3.1, 0.3, 3.3), t)
			card.rotation = Vector3(0, -0.05 * t, 0)
			card.scale = Vector3.ONE * lerpf(1, 0.74, t)
			if t >= 1:
				_show_first_pick()
				phase = Phase.SECOND_SPIN
				elapsed = 0
				_start_angle = orbit_angle
				_end_angle = _landing_angle(orbit_angle, result_roles[1], 1)
				progress.text = "1P 已结缘 · 再为 2P 寻一位同行者……"
		Phase.FINAL_REVEAL:
			var t: float = smoothstep(0, 1, elapsed / FINAL_SECONDS)
			for slot in range(result_roles.size()):
				var card: Node3D = cards[result_roles[slot]]
				var start: Vector3 = Vector3(-3.1, 0.3, 3.3) if slot == 0 and result_roles.size() == 2 else Vector3(0, 0, RADIUS)
				card.position = start.lerp(_final_position(slot), t)
				card.rotation = Vector3.ZERO
				card.scale = Vector3.ONE * lerpf(0.74 if slot == 0 and result_roles.size() == 2 else 1.0, 1.0, t)
			for index in range(8):
				if index not in result_roles: cards[index].scale = Vector3.ONE * maxf(0.001, 1 - t)
			for label in slot_names + slot_roles: label.visible = false
			if t >= 1: _show_results()


func _pose_ring() -> void:
	for index in range(8):
		if index in _selected: continue
		var angle: float = orbit_angle + index * STEP
		cards[index].position = Vector3(sin(angle) * RADIUS, 0, cos(angle) * RADIUS)
		cards[index].rotation = Vector3(0, angle, 0)


func _final_position(slot: int) -> Vector3:
	return Vector3((-1.5 if slot == 0 else 1.5) if result_roles.size() == 2 else 0.0, 0.22, 4.0)


func _show_first_pick() -> void:
	slot_names[0].position = Vector2(31, 518)
	slot_names[0].text = "1P · " + CARD_NAMES[result_roles[0]]
	slot_names[0].visible = true
	slot_roles[0].position = Vector2(31, 555)
	slot_roles[0].text = ["寻文者", "百工匠", "行路人", "联络者"][result_roles[0]]
	slot_roles[0].visible = true


func reveal_now() -> void:
	if not _running or is_ready(): return
	_show_results()


func _show_results() -> void:
	_settle_rotation()
	phase = Phase.READY
	title.text = "同 行 已 定 · 共 赴 碑 前"
	subtitle.text = "每人掌两位同行，携手各尽所长。" if result_roles.size() == 2 else "各有所长，便可一路相助。"
	progress.visible = false
	for index in range(8): cards[index].visible = index in result_roles
	for slot in range(result_roles.size()):
		var id: int = result_roles[slot]
		cards[id].position = _final_position(slot)
		cards[id].rotation = Vector3.ZERO
		cards[id].scale = Vector3.ONE
		frames[id].material_override.albedo_color = Color(0.95, 0.74, 0.29) if slot == 0 else Color(0.48, 0.82, 0.94)
		var left: float = (200.0 if slot == 0 else 680.0) if result_roles.size() == 2 else 440.0
		slot_names[slot].position = Vector2(left, 105)
		slot_names[slot].text = "%dP · %s" % [slot + 1, CARD_NAMES[id]]
		slot_names[slot].visible = true
		slot_roles[slot].position = Vector2(left, 605)
		slot_roles[slot].text = ["寻文者", "百工匠", "行路人", "联络者"][id]
		if result_roles.size() == 2:
			var pair: PackedInt32Array = Party.pairs_for(result_roles)[slot]
			slot_roles[slot].text = "专属同行：%s" % CARD_NAMES[pair[1]]
		slot_roles[slot].visible = true
	if result_roles.size() == 1:
		slot_names[1].visible = false
		slot_roles[1].visible = false
	continue_button.text = "携手入场 · Enter" if result_roles.size() == 2 else "启程同行 · Enter"
	continue_button.visible = true
	continue_button.disabled = false
	skip_button.visible = false
	replay_button.visible = true
