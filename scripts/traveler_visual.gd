extends Node3D

@onready var player: CharacterBody3D = get_parent()

var _step: float = 0.0
var _facing: float = 0.0


func _process(delta: float) -> void:
	var speed: float = absf(player.velocity.x)
	var grounded: bool = player.is_on_floor()
	var moving: bool = speed > 0.15
	if moving:
		_facing = 0.0 if player.velocity.x > 0.0 else PI
	_step += delta * speed * 4.8
	rotation.y = lerp_angle(rotation.y, _facing, 1.0 - exp(-12.0 * delta))
	var sway: float = sin(_step) * minf(speed / 3.0, 1.0) if grounded and moving else 0.0
	var pushing: bool = grounded and moving and player.handling_speed_limit >= 0.0
	$LeftLeg.rotation.z = lerpf($LeftLeg.rotation.z, sway * 0.45 if grounded else -0.28, 1.0 - exp(-14.0 * delta))
	$RightLeg.rotation.z = lerpf($RightLeg.rotation.z, -sway * 0.45 if grounded else 0.4, 1.0 - exp(-14.0 * delta))
	$LeftArm.rotation.z = 0.75 if pushing else -sway * 0.3
	$RightArm.rotation.z = 0.75 if pushing else sway * 0.3
	if player.get("carrying_pose") == true:
		$LeftArm.rotation.z = 1.45
		$RightArm.rotation.z = 1.45
	$Torso.position.y = 0.68 + (absf(sin(_step)) * 0.018 if grounded and moving else 0.0)
	$Scarf.rotation.z = sin(_step * 0.5) * (0.10 if moving else 0.025)
