extends "res://scripts/party_chapter.gd"

signal observation_completed
@export var observation_seconds: float = 1.6
var step: int = 0
var observed: bool = false
var gate_open: bool = false
var opening: bool = false
var _gate_tween: Tween
var _rotation_tween: Tween
var _glyphs: Label3D
var _beam: SpotLight3D


func _ready() -> void:
	$Partner.visible = false
	_beam = $Partner/RightArm/Lantern/Beam
	_beam.reparent(self)
	_glyphs = Props.label(self, Vector3(13.5, 3.4, -1.9), "晋  故  振\n威  建  宁")
	Props.label(self, Vector3(13.5, 4.1, -1.9), "四人合看 · 常规字体训练影像")
	reset_lesson()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart_lesson"):
		reset_lesson()
		return
	if not party.started:
		return
	_beam.visible = not gate_open
	var bearer: CharacterBody3D = party.role_body(3)
	_beam.global_position = bearer.global_position + Vector3(0.1, 0.3, 0.05)
	_beam.look_at(global_position + Vector3(13.5, 1.3, -2.4), Vector3.UP)
	if step < 4 and _hold(step, 13.5, delta, observation_seconds):
		step += 1
		if step == 3:
			_rotation_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
			_rotation_tween.tween_property(_glyphs, "rotation:z", 0.0, 0.65)
		if step == 4:
			observed = true
			observation_completed.emit()
			_open_gate()


func _open_gate() -> void:
	opening = true
	_gate_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_gate_tween.tween_property($Gate, "position:y", 8.0, 1.8)
	_gate_tween.finished.connect(func(): gate_open = true; opening = false)


func get_hint() -> String:
	if opening:
		return "四人互相补全观察，门正在升起。\n完成识读、材料定位、辨向与阅读次序；护碑任务为虚构。"
	if gate_open:
		return "小爨观察档案已解锁。四人向右前往断溪古道。\nF2 查看两碑对照 · 1—4 / Tab 切换 · T 从头重玩"
	var tasks: Array[String] = ["到观察位置，识读训练字卡", "到观察位置，检查复制影像的材料定位", "到观察位置，转正倒置的记忆字卡", "到观察位置，说明竖向阅读次序"]
	return _instruction(step, tasks[step], "其余三人自动跟随；杨三娘协助照明。六字使用常规字体，不冒充爨体。")


func reset_lesson() -> void:
	if _gate_tween != null and _gate_tween.is_valid():
		_gate_tween.kill()
	if _rotation_tween != null and _rotation_tween.is_valid():
		_rotation_tween.kill()
	step = 0
	observed = false
	gate_open = false
	opening = false
	action_progress = 0.0
	$Gate.position = Vector3(19, 2.5, 0)
	_beam.visible = false
	_glyphs.rotation.z = PI
