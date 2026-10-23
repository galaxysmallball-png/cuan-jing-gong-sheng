extends Node3D

signal bridge_completed

enum Stage { WAITING, WALKING, BUILDING, DONE }

@export_range(0.8, 2.5, 0.1) var push_speed: float = 1.5
@export_range(1.0, 4.0, 0.1) var build_seconds: float = 2.0
@export_range(0.8, 3.0, 0.1) var worker_walk_speed: float = 1.8

@onready var player: CharacterBody3D = get_node("../../../Player")
@onready var crate: AnimatableBody3D = $MaterialCrate
@onready var worker: Node3D = $Worker
@onready var bridge_collision: CollisionShape3D = $BridgeBody/Collision
@onready var assembly: Node3D = $BridgeAssembly
@onready var lamp: OmniLight3D = $WorkLight

var stage: Stage = Stage.WAITING
var material_delivered: bool = false
var bridge_ready: bool = false
var is_pushing: bool = false
var _walk_time: float = 0.0
var _build_time: float = 0.0
var _build_tween: Tween
var _delivery_tween: Tween
var _dock_material: StandardMaterial3D


func _ready() -> void:
	_dock_material = $SupplyDock/Mesh.get_active_material(0).duplicate()
	$SupplyDock/Mesh.material_override = _dock_material
	reset_lesson()


func _physics_process(delta: float) -> void:
	player.handling_speed_limit = -1.0
	is_pushing = false
	if Input.is_action_just_pressed("restart_lesson"):
		reset_lesson()
		return
	if not material_delivered:
		_update_crate(delta)
	match stage:
		Stage.WAITING:
			if material_delivered and _near_worker() and Input.is_action_just_pressed("interact"):
				stage = Stage.WALKING
		Stage.WALKING:
			_walk_time += delta
			worker.position = worker.position.move_toward(Vector3(11.1, 0.0, -0.85), worker_walk_speed * delta)
			$Worker/LeftLeg.rotation.x = sin(_walk_time * 8.0) * 0.18
			$Worker/RightLeg.rotation.x = -sin(_walk_time * 8.0) * 0.18
			if worker.position.distance_to(Vector3(11.1, 0.0, -0.85)) < 0.03:
				_start_build()
		Stage.BUILDING:
			_build_time += delta
			$Worker/RightArm.rotation.z = -0.65 + sin(_build_time * 12.0) * 0.22
		Stage.DONE:
			pass


func _update_crate(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	var distance_x: float = crate.global_position.x - player.global_position.x
	# Push only from the side facing the box, while grounded and holding E.
	if player.is_on_floor() and Input.is_action_pressed("interact") \
		and absf(distance_x) <= 1.25 and absf(distance_x) >= 0.4 \
		and axis * distance_x > 0.0:
		is_pushing = true
		player.handling_speed_limit = minf(push_speed, player.move_speed)
		crate.position.x = clampf(crate.position.x + axis * minf(push_speed, player.move_speed) * delta, 4.0, 9.5)
		if crate.position.x >= 9.48:
			_deliver_material()


func _deliver_material() -> void:
	material_delivered = true
	is_pushing = false
	player.handling_speed_limit = -1.0
	$MaterialCrate/Collision.set_deferred("disabled", true)
	_dock_material.albedo_color = Color(0.75, 0.67, 0.35)
	_dock_material.emission = Color(0.25, 0.18, 0.06)
	# Unload the delivered bundle beside the path so it cannot obstruct the player.
	_delivery_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_delivery_tween.tween_property(crate, "position:z", -1.9, 0.6)


func _near_worker() -> bool:
	return player.is_on_floor() and Vector2(player.global_position.x, player.global_position.z).distance_to(
		Vector2(worker.global_position.x, worker.global_position.z)
	) <= 1.6


func _start_build() -> void:
	stage = Stage.BUILDING
	$Worker/LeftLeg.rotation.x = 0.0
	$Worker/RightLeg.rotation.x = 0.0
	_build_time = 0.0
	_build_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_build_tween.tween_property(assembly, "rotation:z", 0.0, build_seconds).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_build_tween.finished.connect(_finish_build)


func _finish_build() -> void:
	bridge_ready = true
	stage = Stage.DONE
	bridge_collision.set_deferred("disabled", false)
	$Worker/RightArm.rotation.z = -0.15
	lamp.light_energy = 3.0
	bridge_completed.emit()


func get_hint() -> String:
	if player.global_position.y < -1.5:
		return "断口还没有修通，正在回到古道入口。\n已完成的观察与材料交付会保留。"
	match stage:
		Stage.WAITING:
			if material_delivered:
				if _near_worker():
					return "E · 请工匠架桥\n工匠：材料到了，我来固定桥面，你稍等。"
				return "材料已交付。走近前方工匠，松开再按 E。\n你负责运来材料，他负责固定通路。"
			if is_pushing:
				return "正在推运材料：按住 E + D，送到蓝色标记。\n松开 E 就会停下；前方断口暂时无法通过。"
			return "走到材料箱左侧，按住 E + D 向右推。\n工匠：把木料送到蓝色标记，我来固定桥面。"
		Stage.WALKING:
			return "工匠正在断口边就位。\n等他固定桥面，随后再过溪。"
		Stage.BUILDING:
			return "工匠正在固定桥面 · %d%%\n你运来木料，他把路接起来。" % mini(int(_build_time / build_seconds * 100.0), 100)
		Stage.DONE:
			return "古道已修通，向右过桥，进入灯火共庭。\nR 仅回到起点 · T 从头重玩 · F1 隐藏提示"
	return ""


func reset_lesson() -> void:
	if _build_tween != null and _build_tween.is_valid():
		_build_tween.kill()
	if _delivery_tween != null and _delivery_tween.is_valid():
		_delivery_tween.kill()
	stage = Stage.WAITING
	material_delivered = false
	bridge_ready = false
	is_pushing = false
	_build_time = 0.0
	_walk_time = 0.0
	player.handling_speed_limit = -1.0
	crate.position = Vector3(4.0, 0.5, 0.0)
	$MaterialCrate/Collision.set_deferred("disabled", false)
	worker.position = Vector3(10.0, 0.0, -0.85)
	$Worker/RightArm.rotation.z = -0.15
	$Worker/LeftLeg.rotation.x = 0.0
	$Worker/RightLeg.rotation.x = 0.0
	assembly.rotation.z = deg_to_rad(-75.0)
	bridge_collision.set_deferred("disabled", true)
	lamp.light_energy = 1.0
	_dock_material.albedo_color = Color(0.25, 0.55, 0.65)
	_dock_material.emission = Color(0.08, 0.18, 0.22)
