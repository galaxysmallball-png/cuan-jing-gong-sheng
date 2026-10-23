extends Node3D

signal courtyard_completed

enum Stage { WAITING, WALKING, READY, LIGHTING, DONE }

@export_range(0.8, 2.5, 0.1) var push_speed: float = 1.5
@export_range(0.5, 3.0, 0.1) var lighting_hold_seconds: float = 1.6
@export_range(1.0, 5.0, 0.1) var light_spread_seconds: float = 2.4
@export_range(1.0, 4.0, 0.1) var warm_light_energy: float = 2.3

@onready var player: CharacterBody3D = get_node("../../../Player")
@onready var first_cooperation: Node3D = get_node("../../Space01/Cooperation")
@onready var bridge_cooperation: Node3D = get_node("../../Space02/BridgeCooperation")
@onready var stand: AnimatableBody3D = $LampStand
@onready var keeper: Node3D = $Keeper
@onready var warm_light: OmniLight3D = $"../WarmLight"

var stage: Stage = Stage.WAITING
var stand_placed: bool = false
var keeper_ready: bool = false
var court_lit: bool = false
var lighting_progress: float = 0.0
var is_pushing: bool = false
var _walk_time: float = 0.0
var _lighting_tween: Tween
var _placement_tween: Tween
var _marker_material: StandardMaterial3D
var _lamp_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	_marker_material = $PlacementMarker/Mesh.get_active_material(0).duplicate()
	$PlacementMarker/Mesh.material_override = _marker_material
	for fixture in $Fixtures.get_children():
		var material: StandardMaterial3D = fixture.get_node("Shade").get_active_material(0).duplicate()
		fixture.get_node("Shade").material_override = material
		_lamp_materials.append(material)
	reset_lesson()


func _physics_process(delta: float) -> void:
	is_pushing = false
	if Input.is_action_just_pressed("restart_lesson"):
		reset_lesson()
		return
	if not _previous_completed():
		return
	if not stand_placed:
		_update_stand(delta)
	match stage:
		Stage.WAITING:
			if stand_placed and _near_keeper() and Input.is_action_just_pressed("interact"):
				stage = Stage.WALKING
		Stage.WALKING:
			_walk_time += delta
			keeper.position = keeper.position.move_toward(Vector3(10.5, 0, -0.85), 1.8 * delta)
			$Keeper/LeftLeg.rotation.x = sin(_walk_time * 8.0) * 0.18
			$Keeper/RightLeg.rotation.x = -sin(_walk_time * 8.0) * 0.18
			if keeper.position.distance_to(Vector3(10.5, 0, -0.85)) < 0.03:
				stage = Stage.READY
				keeper_ready = true
				$Keeper/LeftLeg.rotation.x = 0.0
				$Keeper/RightLeg.rotation.x = 0.0
		Stage.READY:
			if _at_lighting_marker() and Input.is_action_pressed("interact"):
				lighting_progress = minf(lighting_progress + delta, lighting_hold_seconds)
			else:
				lighting_progress = 0.0
			$LightingHandle.rotation.z = deg_to_rad(-20.0 + 40.0 * lighting_progress / lighting_hold_seconds)
			if lighting_progress >= lighting_hold_seconds:
				_begin_lighting()
		Stage.LIGHTING, Stage.DONE:
			_update_residents(delta)


func _previous_completed() -> bool:
	return first_cooperation.observed and first_cooperation.gate_open and bridge_cooperation.bridge_ready


func _update_stand(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	var distance_x: float = stand.global_position.x - player.global_position.x
	if player.is_on_floor() and Input.is_action_pressed("interact") \
		and absf(distance_x) <= 1.25 and absf(distance_x) >= 0.4 \
		and axis * distance_x > 0.0:
		is_pushing = true
		var speed: float = minf(push_speed, player.move_speed)
		player.handling_speed_limit = speed
		stand.position.x = clampf(stand.position.x + axis * speed * delta, 4.0, 9.5)
		$LampStand/WheelA.rotation.z -= axis * speed * delta / 0.16
		$LampStand/WheelB.rotation.z -= axis * speed * delta / 0.16
		if stand.position.x >= 9.48:
			_place_stand()


func _place_stand() -> void:
	stand_placed = true
	is_pushing = false
	player.handling_speed_limit = -1.0
	$LampStand/Collision.set_deferred("disabled", true)
	_marker_material.albedo_color = Color(0.8, 0.65, 0.32)
	_marker_material.emission = Color(0.22, 0.15, 0.04)
	_placement_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_placement_tween.tween_property(stand, "position:z", -1.7, 0.6)


func _near_keeper() -> bool:
	return player.is_on_floor() and Vector2(player.global_position.x, player.global_position.z).distance_to(
		Vector2(keeper.global_position.x, keeper.global_position.z)
	) <= 1.6


func _at_lighting_marker() -> bool:
	return player.is_on_floor() and absf(player.global_position.x - $PlacementMarker.global_position.x) <= 0.8


func _begin_lighting() -> void:
	stage = Stage.LIGHTING
	keeper_ready = false
	$Keeper/RightArm.rotation.z = -0.7
	$Residents.visible = true
	_lighting_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_lighting_tween.tween_method(_set_brightness, 0.0, 1.0, light_spread_seconds)
	_lighting_tween.finished.connect(_finish_lighting)


func _set_brightness(progress: float) -> void:
	warm_light.light_energy = lerpf(0.45, warm_light_energy, progress)
	$LampStand/Glow.light_energy = progress * 2.0
	for index in range(_lamp_materials.size()):
		var local_progress: float = clampf(progress * _lamp_materials.size() - index, 0.0, 1.0)
		_lamp_materials[index].emission = Color(1.0, 0.52, 0.15) * local_progress
		$Fixtures.get_child(index).get_node("Glow").light_energy = local_progress * 2.0


func _finish_lighting() -> void:
	_set_brightness(1.0)
	court_lit = true
	stage = Stage.DONE
	$Keeper/RightArm.rotation.z = -0.15
	courtyard_completed.emit()


func _update_residents(delta: float) -> void:
	_walk_time += delta
	var targets: Array[Vector3] = [Vector3(14, 0, -2), Vector3(16, 0, -2)]
	for index in range($Residents.get_child_count()):
		var resident: Node3D = $Residents.get_child(index)
		resident.position = resident.position.move_toward(targets[index], 1.2 * delta)
		var walking: bool = resident.position.distance_to(targets[index]) > 0.03
		resident.get_node("LeftLeg").rotation.x = sin(_walk_time * 8.0) * 0.18 if walking else 0.0
		resident.get_node("RightLeg").rotation.x = -sin(_walk_time * 8.0) * 0.18 if walking else 0.0


func show_record(lines: Array[String]) -> void:
	$EndingScroll.visible = true
	$EndingScroll/Record.text = "\n".join(lines)


func get_hint() -> String:
	if not _previous_completed():
		return "庭院的共建需要前两段合作成果。\n请先完成碑院观察与古道修桥。"
	match stage:
		Stage.WAITING:
			if stand_placed:
				if _near_keeper():
					return "E · 请守灯人接上灯火\n守灯人：你扶稳引灯柄，我来接上灯火。"
				return "灯架已归位。走近守灯人，松开再按 E。\n接下来一起点亮公共庭院。"
			return "走到灯架左侧，按住 E + D，推到蓝色公共位置。\n守灯人：让光照到大家能坐下的地方。"
		Stage.WALKING:
			return "守灯人正在灯架旁就位。\n你回到灯架前的标记，准备操作引灯柄。"
		Stage.READY:
			if _at_lighting_marker():
				return "按住 E，扶稳引灯柄 · %d%%\n守灯人准备好了，你们一起接上灯火。" % int(100.0 * lighting_progress / lighting_hold_seconds)
			return "守灯人已就位。回到灯架前的标记，站稳并按住 E。\n松开或离开会中断当前操作。"
		Stage.LIGHTING:
			return "灯火正沿庭院亮起，人们正在回到休息处。\n这次合作的成果成为大家共用的空间。"
		Stage.DONE:
			return "共庭有光。向右走到庭院尽头，查看本次合作记录。\nT 重玩三个空间 · R 仅回到起点 · F1 隐藏提示"
	return ""


func reset_lesson() -> void:
	if _lighting_tween != null and _lighting_tween.is_valid():
		_lighting_tween.kill()
	if _placement_tween != null and _placement_tween.is_valid():
		_placement_tween.kill()
	stage = Stage.WAITING
	stand_placed = false
	keeper_ready = false
	court_lit = false
	lighting_progress = 0.0
	$LightingHandle.rotation.z = deg_to_rad(-20.0)
	is_pushing = false
	_walk_time = 0.0
	stand.position = Vector3(4, 0.5, 0)
	$LampStand/Collision.set_deferred("disabled", false)
	$LampStand/WheelA.rotation.z = 0.0
	$LampStand/WheelB.rotation.z = 0.0
	keeper.position = Vector3(12, 0, -0.85)
	$Keeper/RightArm.rotation.z = -0.15
	$Keeper/LeftLeg.rotation.x = 0.0
	$Keeper/RightLeg.rotation.x = 0.0
	$Residents.visible = false
	$Residents.get_child(0).position = Vector3(17, 0, -2)
	$Residents.get_child(1).position = Vector3(19, 0, -2)
	$EndingScroll.visible = false
	$EndingScroll/Record.text = ""
	_marker_material.albedo_color = Color(0.25, 0.55, 0.65)
	_marker_material.emission = Color(0.08, 0.18, 0.22)
	_set_brightness(0.0)
