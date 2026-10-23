extends Node3D

var world: Node3D
var bridge_rails: Array[CollisionShape3D] = []
var prop_colliders: Array[CollisionShape3D] = []
var navigation := AStarGrid2D.new()
var navigation_stamp: Vector3 = Vector3.INF
var navigation_gate: bool = false
var navigation_bridge: bool = false
const CELL := .2
const ORIGIN := Vector2(1, -1)


func setup(owner_world: Node3D) -> void:
	world = owner_world
	name = "PlanarWalkSpace"
	for side in [-1, 1]:
		# No reachable horizontal top: jumping and following remain inside the deck.
		var rail := _blocker(self, Vector3(35, 2.8, side * 1.05), Vector3(6.5, 6.0, .10))
		rail.get_parent().add_to_group("bridge_safety_boundary")
		bridge_rails.append(rail)
	# Daily-life props occupy the rear of the walkway; do not walk through racks and baskets.
	for entry in world.scene_details.props:
		if entry.id == "old_route": continue
		var box: AABB = world.folk._bounds(entry.anchor)
		if box.size.is_zero_approx(): continue
		var size := Vector3(maxf(.2, box.size.x - .12), 4.5, maxf(.2, box.size.z - .12))
		var center: Vector3 = box.get_center()
		center.y = size.y / 2
		prop_colliders.append(_blocker(entry.anchor, center, size))
	# Keep people in front of the visible masonry, including when jumping.
	# Register before the log: the final collider remains the movable log used
	# by the material-delivered navigation invalidation below.
	var pier: Node3D=world.bridge.landscape.repair_pier
	var pier_barrier: CollisionShape3D=_blocker(pier,Vector3(0,2.2,0),Vector3(2.04,4.5,1.34))
	pier_barrier.get_parent().name="PierWalkBarrier"
	pier_barrier.get_parent().add_to_group("bridgehead_pier_barrier")
	prop_colliders.append(pier_barrier)
	# The movable log is a pushing object, not a raised walking surface.
	var log_collision: CollisionShape3D = world.bridge.get_node("MaterialCrate/Collision")
	log_collision.shape = log_collision.shape.duplicate()
	log_collision.shape.size.y = 4.5
	log_collision.position.y = 1.75
	prop_colliders.append(log_collision)
	navigation.region = Rect2i(0, 0, 291, 14)
	navigation.cell_size = Vector2(CELL, CELL)
	navigation.offset = ORIGIN
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.update()
	_sync_rails()


func _blocker(parent: Node3D, at: Vector3, size: Vector3) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = at
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return collision


func _sync_rails() -> void:
	for shape in bridge_rails:
		if shape.disabled == world.bridge.bridge_ready: shape.set_deferred("disabled", not world.bridge.bridge_ready)


func _physics_process(_delta: float) -> void:
	if world != null: _sync_rails()


func deck_depth_bounds(x: float) -> Vector2:
	if not world.bridge.bridge_ready: return Vector2(-1.05, 1.75)
	# Taper on solid ground before either bridge end, including diagonal and airborne entry.
	var blend: float = minf(smoothstep(31.0, 31.7, x), 1.0-smoothstep(38.3, 39.0, x))
	return Vector2(lerpf(-1.05, -.70, blend), lerpf(1.75, .70, blend))


func constrain_to_deck(body: CharacterBody3D) -> void:
	var bounds: Vector2 = deck_depth_bounds(body.global_position.x)
	var z: float = clampf(body.global_position.z, bounds.x, bounds.y)
	if not is_equal_approx(z, body.global_position.z):
		body.global_position.z = z
		body.velocity.z = 0


func _sync_navigation() -> void:
	var stamp: Vector3 = world.bridge.crate.global_position
	if world.bridge.material_delivered: stamp = Vector3.ZERO
	if navigation_stamp.distance_to(stamp) < .12 and navigation_gate == world.cooperation.gate_open and navigation_bridge == world.bridge.bridge_ready: return
	navigation_stamp = stamp
	navigation_gate = world.cooperation.gate_open
	navigation_bridge = world.bridge.bridge_ready
	var obstacles: Array[Rect2] = []
	for shape in prop_colliders:
		if shape.disabled or (shape == prop_colliders.back() and world.bridge.material_delivered): continue
		var center: Vector3 = shape.global_position
		var size: Vector3 = shape.shape.size
		obstacles.append(Rect2(Vector2(center.x-size.x/2,center.z-size.z/2),Vector2(size.x,size.z)).grow(.35))
	for x in range(navigation.region.size.x):
		var wx: float = ORIGIN.x + x*CELL
		var bounds: Vector2 = deck_depth_bounds(wx)
		for z in range(navigation.region.size.y):
			var point := ORIGIN + Vector2(x,z)*CELL
			var solid: bool = point.y < bounds.x+.05 or point.y > bounds.y-.05
			if not navigation_bridge and wx > 31.70 and wx < 38.30: solid = true
			if not navigation_gate and wx > 18.60 and wx < 19.3: solid = true
			for obstacle in obstacles:
				if obstacle.has_point(point): solid = true; break
			navigation.set_point_solid(Vector2i(x,z),solid)


func _cell(at: Vector2) -> Vector2i:
	var cell: Vector2 = (at-ORIGIN)/CELL
	return Vector2i(clampi(roundi(cell.x),0,290),clampi(roundi(cell.y),0,13))


func _nearest_free(cell: Vector2i) -> Vector2i:
	if not navigation.is_point_solid(cell): return cell
	for radius in range(1,18):
		var found := Vector2i(-1,-1)
		var best: float = INF
		for x in range(cell.x-radius,cell.x+radius+1):
			for z in range(cell.y-radius,cell.y+radius+1):
				var at := Vector2i(x,z)
				if not navigation.region.has_point(at) or navigation.is_point_solid(at): continue
				var distance: float = Vector2(at-cell).length_squared()
				if distance < best: best = distance; found = at
		if found.x >= 0: return found
	return cell


func _segment_clear(a: Vector2, b: Vector2) -> bool:
	var steps: int = maxi(1,ceili(a.distance_to(b)/.08))
	for i in range(1,steps+1):
		if navigation.is_point_solid(_cell(a.lerp(b,i/float(steps)))): return false
	return true


func follower_waypoint(body: CharacterBody3D, goal: Vector3) -> Vector3:
	_sync_navigation()
	var here := Vector2(body.global_position.x,body.global_position.z)
	var start: Vector2i = _nearest_free(_cell(here))
	var finish: Vector2i = _nearest_free(_cell(Vector2(goal.x,goal.z)))
	var route: PackedVector2Array = navigation.get_point_path(start,finish,true)
	if route.is_empty(): return body.global_position
	var point: Vector2 = route[0]
	if here.distance_to(point) < .25:
		for i in range(1,mini(route.size(),8)):
			if not _segment_clear(here,route[i]): break
			point = route[i]
	return Vector3(point.x,body.global_position.y,point.y)
