extends CharacterBody3D

# Change these values in the Inspector when Player is selected.
@export var move_speed: float = 4.2
@export var jump_speed: float = 7.0
@export var gravity: float = 24.0

var spawn_position: Vector3
var fall_recovery_position: Vector3
var fall_recovery_count: int = 0
var handling_speed_limit: float = -1.0
var character_id: int = 0
var controls_enabled: bool = true
var interaction_locked: bool = false
var party: Node3D
var control_slot: int = 0
var carrying_pose: bool = false


func _ready() -> void:
	spawn_position = global_position
	fall_recovery_position = spawn_position


func _physics_process(delta: float) -> void:
	if not controls_enabled or interaction_locked:
		velocity = Vector3.ZERO
		return
	if global_position.y < -5.0:
		global_position = fall_recovery_position
		velocity = Vector3.ZERO
		fall_recovery_count += 1

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed(action("jump")):
		velocity.y = jump_speed
		var effects: Node = get_tree().get_first_node_in_group("game_audio")
		if effects != null: effects.play("jump")

	var current_speed: float = move_speed
	if handling_speed_limit >= 0.0 and is_on_floor():
		current_speed = minf(move_speed, handling_speed_limit)
	var direction: Vector2 = Input.get_vector(action("move_left"), action("move_right"), action("move_forward"), action("move_back"))
	velocity.x = direction.x * current_speed
	velocity.z = direction.y * current_speed
	if party != null:
		velocity.x = party.limit_walk(self, velocity.x, delta)
	move_and_slide()
	global_position.z = clampf(global_position.z, -1.05, 1.75)
	global_position.x = clampf(global_position.x, 1.0, 59.0)
	if party != null and party.get_parent().walk_space != null:
		party.get_parent().walk_space.constrain_to_deck(self)


func action(base: String) -> String:
	return base if control_slot == 0 else "p2_" + base


func reset_to_start() -> void:
	global_position = spawn_position
	fall_recovery_position = spawn_position
	velocity = Vector3.ZERO
