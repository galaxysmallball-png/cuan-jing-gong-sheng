extends "res://scripts/party_chapter.gd"

const CharacterNames = preload("res://scripts/character_names.gd")
signal bridge_completed
@export var push_speed: float = 1.5
@export var build_seconds: float = 2.0
var step: int = 0
var material_delivered: bool = false
var bridge_ready: bool = false
var gap_stabilized: bool = false
var tablet_delivered: bool = false
var helpers_called: bool = false
var is_pushing: bool = false
var building: bool = false
var timber_prepared: bool = false
var steady_held: bool = false
var rope_held: bool = false
var landscape: Node3D
var _timber_progress: float = 0.0
var _entered: bool = false
var _risk_announced: bool = false
var _dialogue_left: float = 0.0
var _dialogue_panel: ColorRect
var _dialogue_label: Label
var _tween: Tween
var _unload: Tween
var _helpers: Node3D
var _a_cai: Node3D
var _a_qiang: Node3D
var _a_cai_greeted: bool = false
var transport_clock: float = 0.0
const RESCUE_SECONDS: float = 2.4
var rope_tension: float = .22
var rope_at_post: bool = false
var tension_safe: bool = false
var _tablet: MeshInstance3D
@onready var crate: AnimatableBody3D = $MaterialCrate
@onready var first: Node3D = get_node("../../Space01/Cooperation")


func _ready() -> void:
	$Worker.visible = false
	_helpers = Node3D.new()
	add_child(_helpers)
	var people: Array[PackedScene] = [preload("res://scenes/villagers/a_cai_villager.tscn"), preload("res://scenes/villagers/a_qiang_villager.tscn")]
	for index in range(2):
		var villager: Node3D = people[index].instantiate()
		_helpers.add_child(villager)
		villager.position = Vector3(1.0 + index, 0, -2.0)
		if index == 0: _a_cai = villager
		else: _a_qiang = villager
	_tablet = Props.box(self, Vector3(12.5, 1.10, 0), Vector3(2.2, 0.35, 0.9), Color(0.33, 0.38, 0.38))
	landscape = preload("res://scripts/creek_art.gd").new()
	add_child(landscape)
	landscape.setup(self)
	_build_dialogue()
	reset_lesson()


func _physics_process(delta: float) -> void:
	for body in party.human_players():
		body.handling_speed_limit = -1.0
		body.carrying_pose = false
	if Input.is_action_just_pressed("restart_lesson"):
		reset_lesson()
		return
	if not party.started or not first.gate_open:
		return
	if not _entered and player.global_position.x >= 20.5:
		_entered = true
		_say("老箐", "山洪冲坏了桥底。先放稳，寻旧桥脚，再备杉木。")
	is_pushing = false
	if step >= 1 and not material_delivered:
		if timber_prepared:
			_push_material(delta)
		else:
			_prepare_timber(delta)
	if step == 0 and _hold(2, 2.5, delta):
		step = 1
		_say("老箐", "水痕犹在，旧桥脚尚未全塌。杉木在前头，先截好捆牢。")
	elif step == 1 and _hold(0, 7, delta):
		step = 2
		_say("邓书年", "这些旧路痕迹通向右岸。循着旧桥基，应能搭出一条通路。")
	elif step == 2 and material_delivered and _hold(1, 10.5, delta):
		step = 3
		_say("石阿朵", "墩脚已稳。只备木料还不成，得有人送绳子来。")
	elif step == 3 and _hold(3, 2.5, delta):
		helpers_called = true
		for index in range(2): _helpers.get_child(index).position=Vector3(2.2+index*.8,0,1.1)
		_helpers.visible = true
		step = 4
		_say("杨三娘", "绳索和帮手都到了！诸位到桥头，合力把木梁送上去。")
	elif step == 4 and not building and party.nearby_count(30.5) == 4 and _hold(-1, 10.5, delta):
		_start_build()
	elif step == 5:
		_steady_tablet(delta)
	if helpers_called:
		for index in range(2):
			var villager: Node3D = _helpers.get_child(index)
			var destination := Vector3(9 + index, 0, 1.1)
			if bridge_ready: destination = Vector3(_tablet.position.x + (-1.3 if index == 0 else 1.3), 0, .5)
			if tablet_delivered: destination = Vector3(18.6 + index * .5, 0, .85)
			destination.x = minf(destination.x, 19.1)
			var moving: bool = villager.position.distance_to(destination) > 0.03
			villager.position = villager.position.move_toward(destination, delta * 2.6)
			var model: Node3D = villager.get_node("Character")
			model.animate_model(delta, 1.3 if moving else 0.0, true, false, building or (bridge_ready and not tablet_delivered))
			if index == 0:
				if not moving and not _a_cai_greeted and step == 4 and _dialogue_left <= 0:
					_a_cai_greeted = true
					_say("阿彩", "好。绳索在此。", 2.5)
	if gap_stabilized and not tablet_delivered:
		var at_handoff: bool = true
		for body in party.human_players():
			if body.global_position.x < 39.8: at_handoff = false
		if at_handoff: deliver_tablet()
	_tablet.visible = bridge_ready and not tablet_delivered
	if _tablet.visible:
		var carrying_x: float = player.global_position.x
		if party.local_coop:
			carrying_x = (carrying_x + party.second_player.global_position.x) * 0.5
		# Forward progress belongs to the transport, never to the player's return trip.
		var target_x: float = maxf(_tablet.position.x, clampf(carrying_x - global_position.x, 12.5, 19.8 if gap_stabilized else 15.0))
		var traveling: bool = absf(target_x - _tablet.position.x) > .025
		if traveling: transport_clock += delta
		_tablet.position.x = move_toward(_tablet.position.x, target_x, delta * 2.6)
		_tablet.position.y = lerpf(_tablet.position.y, 1.10 + (.018 * sin(transport_clock * 5.0) if traveling else 0), minf(1, delta * 8))
		var risk: float = 0.0 if gap_stabilized else smoothstep(13.8, 14.7, _tablet.position.x)
		var tilt: float = risk * (-.13 + sin(transport_clock * 3) * .015) * (1 - clampf(action_progress / RESCUE_SECONDS,0,1))
		if step==5 and steady_held: tilt+=(rope_tension-.53)*.15
		_tablet.rotation.z = lerpf(_tablet.rotation.z, tilt, minf(1, delta * 7))
		if risk > 0.8 and not _risk_announced:
			_risk_announced = true
			_say("杨三娘", "当心！碑往外滑了！阿朵顶住碑角，老箐去右岸拉绳！", 6)
		for body in party.human_players():
			body.carrying_pose = Vector2(body.global_position.x - _tablet.global_position.x, body.global_position.z).length() < 2.0
			if body.character_id == 2 and rope_at_post: body.carrying_pose = true
			if not gap_stabilized and body.global_position.x > 32 and body.global_position.x < 38:
				body.handling_speed_limit = push_speed
	landscape.sync_state()


func deliver_tablet() -> void:
	if tablet_delivered: return
	tablet_delivered = true
	_tablet.visible = false
	landscape.sync_state()
	var root_world: Node = get_node("../../..")
	root_world.courtyard.receive_tablet(_tablet.global_position)
	if party.started: _say("石阿朵", "碑已过溪，沿这条路送到院中碑座，再一起扶正。", 4)


func _prepare_timber(delta: float) -> void:
	_timber_progress = _timber_progress + delta if _role_holding(2, 4.0, 1.2) else 0.0
	if _timber_progress >= 1.6:
		timber_prepared = true
		_timber_progress = 0.0
		_say("老箐", "杉木已截好，捆在木橇上。贴近木料，按住操作键往桥头推。")


func _role_holding(role: int, local_x: float, radius: float = 0.9) -> bool:
	if party.movement_locked(): return false
	for body in party.human_players():
		if body.character_id == role and body.is_on_floor() and party.planar_speed(body) < 0.15 \
			and party.at_station(body, global_position.x + local_x, radius) \
			and Input.is_action_pressed(body.action("interact")):
			return true
	return false


func _steady_tablet(delta: float) -> void:
	if party.local_coop:
		steady_held = _role_holding(1, 15.0)
		rope_held = _role_holding(2, 18.4)
		var rope_body: CharacterBody3D = party.role_body(2)
		rope_at_post=rope_body in party.human_players() and rope_body.is_on_floor() and party.at_station(rope_body,global_position.x+18.4,.9) and party.planar_speed(rope_body)<.15 and not party.movement_locked()
		rope_tension=move_toward(rope_tension,1.0 if rope_held else 0.0,delta*(.62 if rope_held else .40))
		tension_safe=rope_tension>=.35 and rope_tension<=.72
		var supported: bool = steady_held and rope_at_post and party.nearby_count(35.0)==4
		if supported and tension_safe: action_progress=minf(RESCUE_SECONDS,action_progress+delta)
		else: action_progress=maxf(0,action_progress-delta*.30)
		if action_progress < RESCUE_SECONDS: return
	else:
		# In solo play the companions manage the line while the human supports the slab.
		rope_tension=.53
		tension_safe=true
		if party.nearby_count(35.0) != 4 or not _hold(-1, 15, delta,RESCUE_SECONDS): return
	gap_stabilized = true
	step = 6
	action_progress = 0.0
	_tablet.rotation.z = 0.0
	_say("老箐", "我年轻时跑马帮，过这样的溪，见过人丧命。今日……都还平安。这碑，命硬。", 8)
	bridge_completed.emit()


func _build_dialogue() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	_dialogue_panel = ColorRect.new()
	_dialogue_panel.position = Vector2(280, 584)
	_dialogue_panel.size = Vector2(640, 76)
	_dialogue_panel.color = Color(0.025, 0.045, 0.055, 0.90)
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_dialogue_panel)
	_dialogue_label = Label.new()
	_dialogue_label.position = Vector2(17, 11)
	_dialogue_label.size = Vector2(606, 62)
	_dialogue_label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(16))
	_dialogue_label.add_theme_color_override("font_color", Color(0.99, 0.86, 0.62))
	var font := preload("res://scripts/interface_skin.gd").body_font()

	_dialogue_label.add_theme_font_override("font", font)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_panel.add_child(_dialogue_label)


func _say(speaker: String, line: String, seconds: float = 5.0) -> void:
	_dialogue_label.text = CharacterNames.annotate(speaker + "：" + line)
	_dialogue_left = seconds
	var root_world: Node = get_node("../../..")
	if is_instance_valid(root_world.story):
		var urgent: bool = line.begins_with("当心") or line.begins_with("我年轻时")
		if urgent: root_world.story.queue.clear()
		root_world.story.speak(speaker, line, seconds, urgent)


func _process(delta: float) -> void:
	_dialogue_left = maxf(0, _dialogue_left - delta)
	if _dialogue_panel == null or party.player == null: return
	var x: float = player.global_position.x
	if party.local_coop:
		x = (x + party.second_player.global_position.x) * 0.5
	_dialogue_panel.visible = false


func _push_material(delta: float) -> void:
	if party.movement_locked():
		return
	for body in party.human_players():
		var axis: float = Input.get_axis(body.action("move_left"), body.action("move_right"))
		var distance: float = crate.global_position.x - body.global_position.x
		if not (body.is_on_floor() and Input.is_action_pressed(body.action("interact")) and absf(distance) <= 1.25 \
			and absf(body.global_position.z - crate.global_position.z) < .65 \
			and absf(Input.get_axis(body.action("move_forward"), body.action("move_back"))) < .1 and absf(distance) >= 0.4 and axis * distance > 0):
			continue
		is_pushing = true
		body.handling_speed_limit = minf(push_speed, body.move_speed)
		var speed: float = party.limit_walk(body, axis * body.handling_speed_limit, delta)
		crate.position.x = clampf(crate.position.x + speed * delta, 4, 9.5)
		if crate.position.x >= 9.48:
			material_delivered = true
			$MaterialCrate/Collision.set_deferred("disabled", true)
			_unload = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
			_unload.tween_property(crate, "position:z", -1.9, 0.6)
		# Two simultaneous inputs never move the same crate twice in one frame.
		break


func _start_build() -> void:
	building = true
	_say("阿彩", "抬！慢些，稳住。", 2.5)
	$BridgeAssembly.visible = true
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property($BridgeAssembly, "rotation:z", 0.0, build_seconds)
	_tween.finished.connect(func():
		bridge_ready = true
		building = false
		step = 5
		$BridgeBody/Collision.set_deferred("disabled", false)
		$WorkLight.light_energy = 3.0
		_say("阿强", "木梁已稳。过桥慢些。", 3)
	)


func get_hint() -> String:
	if not first.gate_open: return "请先完成四人的碑院观察。"
	if building: return "四人已经会合，合力铺设临时通路。\n等桥面固定后，过溪时在中点扶稳道具碑。"
	if step in [1, 2] and not timber_prepared:
		return "老箐到杉木旁站稳，1P 按住 E 或 2P 按住 P / 小键盘0 截料捆扎 %d%%。\n邓书年可同时去岩壁辨认旧路，备好的杉木才能推往桥头。" % int(_timber_progress / 1.6 * 100.0)
	match step:
		0: return _instruction(2, "到旧桥基察看山洪水痕", "先找通路，再备杉木，稳住护碑的路。")
		1: return _instruction(0, "在前方旧路标记处识读", "推料：1P 按 E + D；2P 按 P / 小键盘0 + →。")
		2:
			if not material_delivered: return "先把木料推到蓝色交付点：1P 按 E + D，2P 按 P / 小键盘0 + →。\n任何角色都能推运；之后切换石阿朵处理石墩。"
			return _instruction(1, "在石墩标记处固定材料")
		3: return _instruction(3, "回到古道入口联络村民", "村民带来绳索，随后全队回到桥前。")
		4: return _instruction(-1, "全队在桥前会合后合力架桥", "两位玩家都要走到桥前，另两名伙伴会跟上。" if party.local_coop else "需四人都到附近；伙伴会自动跟上。")
		5:
			if party.local_coop:
				return "石阿朵在桥心按住操作键顶碑；老箐在右岸按下收绳、松开放绳。\n让张力停在绿色区，合力护稳 %d%%；过紧或过松会缓慢回退。" % int(action_progress / RESCUE_SECONDS * 100.0)
			return _instruction(-1, "走到桥中标记，扶稳道具碑", "桥已可走，必须完成扶稳任务才能继续共庭。")
	return "碑已送入院中，前往灯火共庭合力立碑。" if tablet_delivered else "碑已护稳，向右走到交接处，一同送碑入院。"


func reset_lesson() -> void:
	for tween in [_tween, _unload]:
		if tween != null and tween.is_valid(): tween.kill()
	step = 0
	material_delivered = false
	bridge_ready = false
	gap_stabilized = false
	tablet_delivered = false
	helpers_called = false
	_a_cai_greeted = false
	building = false
	is_pushing = false
	timber_prepared = false
	steady_held = false
	rope_held = false
	rope_at_post=false
	tension_safe=false
	rope_tension=.22
	_timber_progress = 0.0
	_entered = false
	_risk_announced = false
	_dialogue_left = 0.0
	_dialogue_panel.visible = false
	action_progress = 0.0
	crate.position = Vector3(4, 0.5, 0)
	$MaterialCrate/Collision.set_deferred("disabled", false)
	$BridgeBody/Collision.set_deferred("disabled", true)
	$BridgeAssembly.rotation.z = deg_to_rad(-75)
	$BridgeAssembly.visible = false
	$WorkLight.light_energy = 1.0
	_helpers.visible = false
	_tablet.visible = false
	_tablet.position = Vector3(12.5, 1.10, 0)
	_tablet.rotation = Vector3.ZERO
	transport_clock = 0
	for index in range(2): _helpers.get_child(index).position = Vector3(1.0 + index, 0, -2)
	_a_cai.get_node("Character").pose(0, 0, 0, true, false, false)
	_a_qiang.get_node("Character").pose(0, 0, 0, true, false, false)
	landscape.sync_state()
