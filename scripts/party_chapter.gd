extends Node3D

const Props = preload("res://scripts/chapter_props.gd")
@onready var party: Node3D = get_node("../../../Party")
@onready var player: CharacterBody3D = get_node("../../../Player")
var action_progress: float = 0.0
var _holding_role: int = -1


func _hold(role: int, local_x: float, delta: float, seconds: float = 1.6) -> bool:
	var contributor: int = -1
	if not party.movement_locked():
		for body in party.human_players():
			if (role < 0 or body.character_id == role) and body.is_on_floor() \
				and party.at_station(body, global_position.x + local_x) \
				and Input.is_action_pressed(body.action("interact")) and party.planar_speed(body) < 0.15:
				contributor = body.character_id
				break
	if contributor != _holding_role:
		action_progress = 0.0
	_holding_role = contributor
	action_progress = minf(action_progress + delta, seconds) if contributor >= 0 else 0.0
	if action_progress >= seconds:
		action_progress = 0.0
		return true
	return false


func _instruction(role: int, task: String, extra: String = "") -> String:
	var name: String = "任意角色" if role < 0 else "%d · %s" % [role + 1, party.NAMES[role]]
	return "%s：%s · %s站稳操作 %d%%\n%s" % [name, task, "1P 按 E，2P 按 P / 小键盘0 " if party.local_coop else "按住 E ", int(action_progress / 1.6 * 100.0), extra]
