extends "res://scripts/character_animation_controller.gd"

@export var stowed_bones: PackedStringArray
@export var companion_path: NodePath


func animate_model(delta: float, speed: float, grounded: bool, pushing: bool, carrying: bool, reading: bool = false) -> void:
	var previous: String = current_state
	super.animate_model(delta, speed, grounded, pushing, carrying, reading)
	if current_state != previous and current_state in ["carry", "push", "jump"] and not stowed_bones.is_empty():
		animation_player.play(_playing_clip, 0.0)
		animation_player.advance(0)
	if not companion_path.is_empty():
		get_node(companion_path).animate_model(delta, speed, true, false, false)


func pose(time: float, gait: float, speed: float, grounded: bool, pushing: bool, carrying: bool, reading: bool = false) -> void:
	super.pose(time, gait, speed, grounded, pushing, carrying, reading)
	if not companion_path.is_empty():
		get_node(companion_path).pose(time, gait, speed, true, false, false)
