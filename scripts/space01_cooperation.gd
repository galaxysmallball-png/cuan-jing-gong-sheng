extends Node3D

signal observation_completed

enum Stage { WAITING, TO_LIGHT, LIGHTING, TO_GATE, OPENING, DONE }

@export_range(0.5, 5.0, 0.1) var observation_seconds: float = 1.6
@export_range(0.5, 5.0, 0.1) var partner_walk_speed: float = 2.2
@export var interaction_distance: float = 1.6
@export var observation_radius: float = 1.0

@onready var player: CharacterBody3D = get_node("../../../Player")
@onready var partner: Node3D = $Partner
@onready var beam: SpotLight3D = $Partner/RightArm/Lantern/Beam
@onready var gate: AnimatableBody3D = $Gate
@onready var left_arm: Node3D = $Partner/LeftArm
@onready var right_arm: Node3D = $Partner/RightArm

var stage: Stage = Stage.WAITING
var observation_progress: float = 0.0
var observed: bool = false
var gate_open: bool = false
var partner_ready: bool = false
var _walk_time: float = 0.0
var _gate_tween: Tween
var _marker_material: StandardMaterial3D


func _ready() -> void:
	_marker_material = $ObservationMarker/Mesh.get_active_material(0).duplicate()
	$ObservationMarker/Mesh.material_override = _marker_material
	reset_lesson()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart_lesson"):
		player.reset_to_start()
		reset_lesson()
		return

	match stage:
		Stage.WAITING:
			if Input.is_action_just_pressed("interact") and _near_partner():
				stage = Stage.TO_LIGHT
		Stage.TO_LIGHT:
			if _walk_partner($LightStation.position, delta):
				stage = Stage.LIGHTING
				partner_ready = true
		Stage.LIGHTING:
			if _at_observation() and Input.is_action_pressed("interact"):
				observation_progress = minf(observation_progress + delta, observation_seconds)
			else:
				# A steady viewpoint is needed; releasing E or leaving resets this short action.
				observation_progress = 0.0
			if observation_progress >= observation_seconds:
				observed = true
				partner_ready = false
				stage = Stage.TO_GATE
				observation_completed.emit()
		Stage.TO_GATE:
			if _walk_partner($GateStation.position, delta):
				_open_gate()

	beam.visible = stage == Stage.LIGHTING
	if beam.visible:
		beam.look_at($IlluminationTarget.global_position, Vector3.UP)
	_update_marker()


func _walk_partner(target: Vector3, delta: float) -> bool:
	partner.position = partner.position.move_toward(target, partner_walk_speed * delta)
	_walk_time += delta
	left_arm.rotation.x = sin(_walk_time * 8.0) * 0.24
	$Partner/LeftLeg.rotation.x = sin(_walk_time * 8.0) * 0.18
	$Partner/RightLeg.rotation.x = -sin(_walk_time * 8.0) * 0.18
	if partner.position.distance_to(target) < 0.03:
		left_arm.rotation.x = 0.0
		$Partner/LeftLeg.rotation.x = 0.0
		$Partner/RightLeg.rotation.x = 0.0
		return true
	return false


func _near_partner() -> bool:
	return Vector2(player.global_position.x, player.global_position.z).distance_to(
		Vector2(partner.global_position.x, partner.global_position.z)
	) <= interaction_distance


func _at_observation() -> bool:
	return absf(player.global_position.x - $ObservationMarker.global_position.x) <= observation_radius \
		and player.is_on_floor()


func _open_gate() -> void:
	stage = Stage.OPENING
	right_arm.rotation.z = -0.7
	_gate_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_gate_tween.tween_property(gate, "position:y", 8.0, 1.8).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_gate_tween.finished.connect(_gate_finished)


func _gate_finished() -> void:
	gate_open = true
	stage = Stage.DONE
	right_arm.rotation.z = -0.15


func _update_marker() -> void:
	var progress: float = observation_progress / observation_seconds
	var color: Color = Color(0.25, 0.55, 0.65).lerp(Color(1.0, 0.72, 0.32), progress)
	if observed:
		color = Color(0.65, 0.82, 0.57)
	_marker_material.albedo_color = color
	_marker_material.emission = color * 0.35


func get_hint() -> String:
	match stage:
		Stage.WAITING:
			if _near_partner():
				return "E · 请记录者提灯\n记录者：你来观察，我把光照稳。"
			return "走近前方提灯的伙伴，按 E 招呼。\nA / D 移动 · 空格跳跃 · T 从头重玩"
		Stage.TO_LIGHT:
			return "伙伴正在提灯就位。\n跟着他，走到两块展示板前的蓝色观察位置。"
		Stage.LIGHTING:
			if _at_observation():
				return "按住 E，站稳观察 · %d%%\n他负责照明，你负责留下两碑的记录。" % int(
					100.0 * observation_progress / observation_seconds
				)
			return "伙伴已照亮展示位置。\n走到蓝色标记上，站稳并按住 E。"
		Stage.TO_GATE:
			return "已记录：小爨 405 年，大爨 458 年。\n记录者正在前往门边，等他启门后一起通过。"
		Stage.OPENING:
			return "记录者：两碑各有来处，我们一起接着走。\n门正在升起，前方通往断溪古道。"
		Stage.DONE:
			return "合作观察已完成，向右进入第二空间。\nR 仅回到起点 · T 从头重玩 · F1 隐藏提示"
	return ""


func reset_lesson() -> void:
	if _gate_tween != null and _gate_tween.is_valid():
		_gate_tween.kill()
	stage = Stage.WAITING
	observation_progress = 0.0
	observed = false
	gate_open = false
	partner_ready = false
	partner.position = Vector3(6.0, 0.0, -0.7)
	gate.position = Vector3(19.0, 2.5, 0.0)
	beam.visible = false
	left_arm.rotation.x = 0.0
	right_arm.rotation.z = -0.15
	$Partner/LeftLeg.rotation.x = 0.0
	$Partner/RightLeg.rotation.x = 0.0
	_update_marker()
