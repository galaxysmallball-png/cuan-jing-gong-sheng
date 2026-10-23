extends CharacterBody3D

@export var character_id: int = 1
var handling_speed_limit: float = -1.0
var move_speed: float = 3.8
var gravity: float = 24.0
var detour_x: float = NAN


func _physics_process(delta: float) -> void:
	var party: Node3D = get_parent()
	if not party.started or party.movement_locked():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var goal: Vector3 = party.follower_target_position(self)
		if party.get_parent().walk_space != null:
			goal = party.get_parent().walk_space.follower_waypoint(self,goal)
		var offset := Vector2(goal.x - global_position.x, goal.z - global_position.z)
		var direction: Vector2 = offset.normalized()
		var speed: float = minf(move_speed, offset.length() * 4) if offset.length() > .15 else 0.0
		velocity.x = direction.x * speed
		velocity.z = direction.y * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	global_position.z = clampf(global_position.z, -1.05, 1.75)
	global_position.x = clampf(global_position.x, 1.0, 59.0)
	if party.get_parent().walk_space != null:
		party.get_parent().walk_space.constrain_to_deck(self)
	if global_position.y < -5.0:
		global_position = party.player.fall_recovery_position
		velocity = Vector3.ZERO


func _ray(origin: Vector3, offset: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + offset, 1)
	query.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
