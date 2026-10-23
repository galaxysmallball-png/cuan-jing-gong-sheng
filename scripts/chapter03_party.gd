extends "res://scripts/party_chapter.gd"

signal courtyard_completed
@export var warm_light_energy: float = 2.3
@export var lighting_hold_seconds: float = 1.6
@export var light_spread_seconds: float = 2.4
const LAMP_ROLES: Array[int] = [0, 1, 2, 3, 3, 3, 3]
const ITEMS: Array[String] = ["拓片展示", "錾子陈列", "屋檐马铃", "保护架红线", "院门油灯", "石阶油灯", "碑亭油灯"]
var tablet_placed: bool = false
var lamp_count: int = 0
var court_lit: bool = false
var closing: bool = false
var _lamps: Array[Node3D] = []
var _tablet: MeshInstance3D
var _tween: Tween
@onready var first: Node3D = get_node("../../Space01/Cooperation")
@onready var bridge: Node3D = get_node("../../Space02/BridgeCooperation")
@onready var warm_light: OmniLight3D = $"../WarmLight"


func _ready() -> void:
	$Keeper.visible = false
	$LampStand.visible = false
	$LampStand/Collision.disabled = true
	$Fixtures.visible = false
	$LightingHandle.visible = false
	$PlacementMarker.visible = false
	$"../PillarB".visible = false
	_tablet = Props.box(self, Vector3(3, 1.3, -1.7), Vector3(1.1, 2.4, 0.3), Color(0.30, 0.36, 0.37))
	Props.label(self, Vector3(3, 3.0, -1.3), "道具碑 · 虚构")
	Props.marker(self, 3, "石阿朵：安放道具碑")
	for index in range(7):
		var fixture := Node3D.new()
		add_child(fixture)
		fixture.position = Vector3(5 + index * 2, 0, -1.9)
		Props.box(fixture, Vector3(0, 0.8, 0), Vector3(0.08, 1.6, 0.08), Color(0.3, 0.25, 0.16))
		var shade: MeshInstance3D = Props.box(fixture, Vector3(0, 1.7, 0), Vector3(0.35, 0.45, 0.35), Color(0.42, 0.34, 0.2))
		shade.name = "Shade"
		shade.material_override.emission_enabled = true
		var glow := OmniLight3D.new()
		glow.name = "Glow"
		glow.position = Vector3(0, 1.7, 0.15)
		glow.light_color = Color(1, 0.65, 0.30)
		glow.light_energy = 0.0
		glow.omni_range = 3.4
		fixture.add_child(glow)
		Props.label(fixture, Vector3(0, 2.2, 0.3), "%d · %s" % [index + 1, ITEMS[index]])
		Props.marker(self, 5 + index * 2, "%d" % (index + 1))
		_lamps.append(fixture)
	reset_lesson()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart_lesson"):
		reset_lesson()
		return
	if not party.started or not _previous_completed():
		return
	if not tablet_placed:
		if _hold(1, 3, delta, lighting_hold_seconds):
			tablet_placed = true
			_tablet.rotation.z = 0.0
	elif lamp_count < 7:
		if _hold(LAMP_ROLES[lamp_count], 5 + lamp_count * 2, delta, lighting_hold_seconds):
			_lamps[lamp_count].get_node("Glow").light_energy = 2.0
			_lamps[lamp_count].get_node("Shade").material_override.emission = Color(0.9, 0.4, 0.1)
			lamp_count += 1
			warm_light.light_energy = lerpf(0.45, warm_light_energy, lamp_count / 7.0)
			if lamp_count == 7: _finish_court()
	if closing or court_lit:
		$Residents.visible = true
		for index in range(2):
			var resident: Node3D = $Residents.get_child(index)
			resident.position = resident.position.move_toward(Vector3(14 + index * 2, 0, -2), delta * 1.2)


func _previous_completed() -> bool:
	return first.gate_open and bridge.gap_stabilized


func _finish_court() -> void:
	closing = true
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_interval(light_spread_seconds)
	_tween.finished.connect(func():
		court_lit = true
		closing = false
		courtyard_completed.emit()
	)


func show_record(lines: Array[String]) -> void:
	$EndingScroll.visible = true
	$EndingScroll/Record.text = "\n".join(lines)


func get_hint() -> String:
	if not _previous_completed(): return "护碑还未完成：回到桥中扶稳道具碑。\n先完成碑院观察与古道任务链。"
	if not tablet_placed: return _instruction(1, "在入口标记安放道具碑", "设施均为虚构的记忆场景，道具不是真实文物。")
	if closing: return "七盏灯已亮，居民回到庭院，正在留下共同的旅程。\n向右到庭院尽头，等待合作记录展开。"
	if court_lit: return "四人护碑、七灯共庭已完成。向右走到尽头查看记录。\nF2 查看文化与虚构分层 · T 从头重玩"
	return _instruction(LAMP_ROLES[lamp_count], "到第 %d 盏灯归位：%s" % [lamp_count + 1, ITEMS[lamp_count]], "已亮 %d / 7 · 物品来自角色与村民，依次归位，场景中操作。" % lamp_count)


func reset_lesson() -> void:
	if _tween != null and _tween.is_valid(): _tween.kill()
	tablet_placed = false
	lamp_count = 0
	court_lit = false
	closing = false
	action_progress = 0.0
	_tablet.rotation.z = PI / 2
	for lamp in _lamps:
		lamp.get_node("Glow").light_energy = 0.0
		lamp.get_node("Shade").material_override.emission = Color.BLACK
	for fixture in $Fixtures.get_children(): fixture.get_node("Glow").light_energy = 0.0
	$LampStand/Glow.light_energy = 0.0
	warm_light.light_energy = 0.45
	$Residents.visible = false
	$Residents.get_child(0).position = Vector3(17, 0, -2)
	$Residents.get_child(1).position = Vector3(19, 0, -2)
	$EndingScroll.visible = false
	$EndingScroll/Record.text = ""
