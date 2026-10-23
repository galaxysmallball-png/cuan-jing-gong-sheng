extends Node3D

signal character_changed
const CharacterNames = preload("res://scripts/character_names.gd")
const NAMES: Array[String] = CharacterNames.DISPLAY_NAMES
const ROLES: Array[String] = ["寻文者", "百工匠", "行路人", "联络者"]
var player: CharacterBody3D
var active_id: int = 0
var started: bool = false
var followers: Array[CharacterBody3D] = []
var last_direction: float = 1.0
var actor_scene: PackedScene = preload("res://scenes/party_actor.tscn")
const MAX_PLAYER_DISTANCE: float = 14.0
@export var local_coop: bool = true
var second_player: CharacterBody3D
var second_id: int = 1
var second_direction: float = 1.0
# Belongs to the role, so swapping between players and followers keeps its heading.
var role_directions: Dictionary = {0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0}
var role_headings: Dictionary = {0: .58, 1: .58, 2: .58, 3: .58}
# Ownership includes the inactive companion, not only the currently controlled body.
var owned_roles: Array[PackedInt32Array] = [PackedInt32Array([0, 2]), PackedInt32Array([1, 3])]


static func pairs_for(chosen: Array[int]) -> Array[PackedInt32Array]:
	if chosen.size() != 2 or chosen[0] == chosen[1]: return []
	for role in chosen:
		if role < 0 or role > 3: return []
	var remaining: Array[int] = [0, 1, 2, 3]
	for role in chosen: remaining.erase(role)
	# The stoneworker and route finder must belong to different controllers:
	# both human inputs are required for the existing bridge rescue.
	if (1 in [chosen[0], remaining[0]]) == (2 in [chosen[0], remaining[0]]):
		remaining.reverse()
	return [PackedInt32Array([chosen[0], remaining[0]]), PackedInt32Array([chosen[1], remaining[1]])]


func roles_for_player(slot: int) -> PackedInt32Array:
	if slot < 0 or slot > 1 or (slot == 1 and not local_coop): return PackedInt32Array()
	return owned_roles[slot].duplicate() if local_coop else PackedInt32Array([0, 1, 2, 3])


func owner_of(role: int) -> int:
	if role < 0 or role > 3: return -1
	if not local_coop: return 0
	return 0 if role in owned_roles[0] else 1


func _ready() -> void:
	if preload("res://scripts/mobile_platform.gd").active():
		local_coop=preload("res://scripts/mobile_platform.gd").cooperative
	player = get_parent().get_node("Player")
	player.party = self
	player.controls_enabled = false
	player.collision_layer = 2
	player.collision_mask = 1
	if local_coop:
		second_player = actor_scene.instantiate()
		second_player.set_script(preload("res://scripts/player.gd"))
		second_player.name = "Player2"
		second_player.control_slot = 1
		second_player.character_id = 1
		second_player.move_speed = player.move_speed
		second_player.controls_enabled = false
		second_player.party = self
		second_player.position = player.spawn_position - Vector3(0.95, 0, 0)
		add_child(second_player)
	for id in range(2 if local_coop else 1, 4):
		var actor: CharacterBody3D = actor_scene.instantiate()
		actor.character_id = id
		add_child(actor)
		followers.append(actor)
	reset_positions(true)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_lesson") and started:
		reset_positions(true)
	elif Input.is_action_just_pressed("restart") and started:
		reset_positions(false)
	if not started or not player.controls_enabled:
		return
	for id in range(4):
		if Input.is_action_just_pressed("select_%d" % (id + 1)):
			switch_to(id)
	if Input.is_action_just_pressed("cycle_character"):
		cycle(0)
	if local_coop and Input.is_action_just_pressed("p2_cycle_character"):
		cycle(1)
	if absf(player.velocity.x) > 0.1:
		last_direction = signf(player.velocity.x)
	if local_coop and absf(second_player.velocity.x) > 0.1:
		second_direction = signf(second_player.velocity.x)


func switch_to(id: int, slot: int = 0) -> bool:
	if id < 0 or id >= 4 or slot < 0 or slot > 1 or not started or not player.controls_enabled:
		return false
	if slot == 1 and not local_coop:
		return false
	if id not in roles_for_player(slot): return false
	var controlled: CharacterBody3D = player if slot == 0 else second_player
	var current: int = active_id if slot == 0 else second_id
	if id == current:
		return true
	# A role belongs to one controller; switching never steals the other player's role.
	if local_coop and id == (second_id if slot == 0 else active_id):
		return false
	for actor in followers:
		if actor.character_id == id:
			# Identities retain their world positions; only the input-controlled body changes.
			var previous_position: Vector3 = controlled.global_position
			var previous_velocity: Vector3 = controlled.velocity
			controlled.global_position = actor.global_position
			controlled.velocity = actor.velocity
			actor.global_position = previous_position
			actor.velocity = previous_velocity
			actor.character_id = current
			_visual(actor).set_character_id(current)
			if slot == 0:
				active_id = id
			else:
				second_id = id
			controlled.character_id = id
			controlled.handling_speed_limit = -1.0
			_visual(controlled).set_character_id(id)
			character_changed.emit()
			return true
	return false


func _visual(body: CharacterBody3D) -> Node3D:
	return body.get_node("TravelerVisual" if body == player else "Visual")


func assign_opening_roles(chosen: Array[int]) -> bool:
	# Deal before controls start. Validate the entire set before changing any body.
	if started or chosen.size() != (2 if local_coop else 1): return false
	for id in chosen:
		if id < 0 or id >= NAMES.size() or chosen.count(id) != 1: return false
	if local_coop: owned_roles = pairs_for(chosen)
	var remaining: Array[int] = [0, 1, 2, 3]
	for id in chosen: remaining.erase(id)
	active_id = chosen[0]
	if local_coop: second_id = chosen[1]
	var humans: Array[CharacterBody3D] = human_players()
	for slot in range(humans.size()):
		humans[slot].character_id = chosen[slot]
		_visual(humans[slot]).set_character_id(chosen[slot])
	for index in range(followers.size()):
		followers[index].character_id = remaining[index]
		_visual(followers[index]).set_character_id(remaining[index])
	character_changed.emit()
	return true


func human_players() -> Array[CharacterBody3D]:
	var result: Array[CharacterBody3D] = []
	if is_instance_valid(player):
		result.append(player)
	if local_coop and is_instance_valid(second_player):
		result.append(second_player)
	return result


func set_controls(enabled: bool) -> void:
	for body in human_players():
		body.controls_enabled = enabled


func set_interaction_lock(locked: bool) -> void:
	for body in human_players():
		body.interaction_locked = locked
		if locked:
			body.velocity = Vector3.ZERO


func movement_locked() -> bool:
	return player.interaction_locked or not player.controls_enabled


func cycle(slot: int) -> void:
	var current: int = active_id if slot == 0 else second_id
	for offset in range(1, 4):
		if switch_to((current + offset) % 4, slot):
			return


func limit_walk(body: CharacterBody3D, speed: float, delta: float) -> float:
	if not local_coop or is_zero_approx(speed):
		return speed
	var other: CharacterBody3D = second_player if body == player else player
	var separation: float = body.global_position.x - other.global_position.x
	if speed * separation <= 0:
		return speed
	var room: float = maxf(0.0, MAX_PLAYER_DISTANCE - absf(separation))
	return signf(speed) * minf(absf(speed), room / delta)


func follower_target(actor: CharacterBody3D) -> float:
	var rank: int = followers.find(actor) + 1
	var leader: CharacterBody3D = player
	var direction: float = last_direction
	if local_coop:
		var owner_slot: int = owner_of(actor.character_id)
		leader = player if owner_slot == 0 else second_player
		direction = last_direction if owner_slot == 0 else second_direction
		if absf(player.global_position.x - second_player.global_position.x) < 2.0:
			# When both players travel together, leave room for both human-controlled bodies.
			direction = last_direction
			var rear: float = minf(player.global_position.x, second_player.global_position.x) if direction > 0 else maxf(player.global_position.x, second_player.global_position.x)
			var target: float = rear - direction * rank * 0.85
			if target < 1.2 or target > 58.5:
				target = rear + direction * rank * 0.85
			return clampf(target, 1.2, 58.5)
		rank = 1
	if direction > 0 and leader.global_position.x < 3.8:
		return leader.global_position.x + rank * 0.85
	if direction < 0 and leader.global_position.x > 56.2:
		return leader.global_position.x - rank * 0.85
	return clampf(leader.global_position.x - direction * rank * 0.85, 1.2, 58.5)


func nearby_count(x: float, radius: float = 4.5) -> int:
	var count: int = 0
	for actor in all_bodies():
		if Vector2(actor.global_position.x - x, actor.global_position.z).length() <= radius and actor.is_on_floor():
			count += 1
	return count


func follower_target_position(actor: CharacterBody3D) -> Vector3:
	var owner_slot: int = owner_of(actor.character_id)
	var leader: CharacterBody3D = player if owner_slot == 0 else second_player
	var x: float = follower_target(actor)
	var depth: float = clampf(leader.global_position.z + (.24 if followers.find(actor) % 2 else -.24), -.85, 1.5)
	# Exit through the deck end before spreading out onto the bank.
	if (x > 31.3 and x < 38.7) or (actor.global_position.x > 31.3 and actor.global_position.x < 38.7):
		depth = clampf(depth, -.48, .48)
		if absf(actor.global_position.z) > .52:
			if actor.global_position.x < 31.65 and x > 31.65:
				x = 31.3
				depth = 0
			elif actor.global_position.x > 38.35 and x < 38.35:
				x = 38.7
				depth = 0
	return Vector3(x, leader.global_position.y, depth)


static func planar_speed(body: CharacterBody3D) -> float:
	return Vector2(body.velocity.x, body.velocity.z).length()


static func at_station(body: CharacterBody3D, x: float, radius: float = 1.0) -> bool:
	return Vector2(body.global_position.x - x, body.global_position.z).length() <= radius


func all_bodies() -> Array[CharacterBody3D]:
	var result: Array[CharacterBody3D] = human_players()
	result.append_array(followers)
	return result


func role_body(id: int) -> CharacterBody3D:
	for actor in all_bodies():
		if actor.character_id == id:
			return actor
	return player


func reset_positions(reset_identity: bool) -> void:
	role_directions = {0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0}
	role_headings = {0: .58, 1: .58, 2: .58, 3: .58}
	if reset_identity:
		owned_roles = pairs_for([0, 1])
		active_id = 0
		second_id = 1
		player.character_id = 0
		if local_coop:
			second_player.character_id = 1
		for index in range(followers.size()):
			followers[index].character_id = index + (2 if local_coop else 1)
	for body in human_players():
		body.reset_to_start()
		body.handling_speed_limit = -1.0
		body.interaction_locked = false
		body.carrying_pose = false
		_visual(body).set_character_id(body.character_id)
	for index in range(followers.size()):
		followers[index].global_position = Vector3(player.spawn_position.x - (index + (2 if local_coop else 1)) * 0.95, 0.8, 0)
		followers[index].velocity = Vector3.ZERO
		_visual(followers[index]).set_character_id(followers[index].character_id)
	last_direction = 1.0
	second_direction = 1.0
	character_changed.emit()
