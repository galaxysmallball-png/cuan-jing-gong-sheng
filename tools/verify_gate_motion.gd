extends "res://tools/verify_cooperative_experience.gd"

var watchdog: SceneTreeTimer
var checkpoint: String="startup"


func _initialize() -> void:
	capture=true
	watchdog=create_timer(180,true)
	watchdog.timeout.connect(_timed_out)
	call_deferred("_run")


func _run() -> void:
	root.mode=Window.MODE_MINIMIZED
	OS.low_processor_usage_mode=false
	capture_viewport=SubViewport.new()
	capture_viewport.size=Vector2i(1280,720)
	capture_viewport.own_world_3d=true
	capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	capture_viewport.msaa_3d=Viewport.MSAA_4X
	root.add_child(capture_viewport)
	world=load("res://scenes/world.tscn").instantiate()
	capture_viewport.add_child(world)
	party=world.party
	player=party.player
	second=party.second_player
	first=world.cooperation
	bridge=world.bridge
	court=world.courtyard
	ui=world.get_node("PartyUI")
	nearby_ui=world.get_node("NearbyInteractions")
	await _frames(15)
	await _start_default_party()
	var roofs: Array[Node]=get_nodes_in_group("city_gate_roof")
	if roofs.size()!=1 or roofs[0].tile_count<150 or roofs[0].find_children("*","CollisionObject3D",true,false).size()!=0:
		_fail("Exit gate lacks layered roof detail or introduces a walking collider"); return
	for part in ["OverlappingBarrelTiles","RidgeCapsAndDripTiles","RecessedRafterHeads","GateBearingBeamsAndBrackets","GateDiagonalTimberBraces"]:
		if roofs[0].get_node_or_null(part)==null: _fail("Missing gate construction: "+part); return
	await _detail_view("gate-roof",Vector3(40.55,5.4,6),Vector3(40.55,3.25,-2.6),6.6)
	checkpoint="walk and landing"
	await _put(6.4,7.3)
	await _press_key(KEY_D,true)
	await _frames(20)
	var model: Node3D=party._visual(player).detailed_model
	if model.current_state!="walk" or model.animation_player.speed_scale<1.2: _fail("Walking cadence does not follow actual travel speed"); return
	await _press_key(KEY_D,false)
	await _frames(12)
	if model.current_state!="idle": _fail("Stopping leaves the walking cycle running"); return
	await _press_key(KEY_SPACE,true)
	await _frames(4)
	await _press_key(KEY_SPACE,false)
	if model.current_state!="jump" or player.velocity.y<=0: _fail("Jump does not start with rising pose"); return
	await _detail_view("jump-rise",player.global_position+Vector3(0,1.25,8),player.global_position+Vector3(0,.35,0),5.8)
	await _frames(11)
	var paused_pose: float=model.animation_player.current_animation_position
	var paused_position: Vector3=player.global_position
	await _near_key(KEY_H)
	await _frames(12)
	if not paused or player.global_position!=paused_position or model.animation_player.current_animation_position!=paused_pose:
		_fail("Help does not freeze airborne motion"); return
	await _near_key(KEY_ESCAPE)
	var saw_fall: bool=false
	var saw_land: bool=false
	for frame in range(45):
		await _frames(1)
		if not player.is_on_floor() and player.velocity.y<-.3:
			if model.animation_player.current_animation!="motion/jump_fall": _fail("Falling replays the rising clip"); return
			if not saw_fall:
				saw_fall=true
				await _detail_view("jump-fall",player.global_position+Vector3(0,1.25,8),player.global_position+Vector3(0,.35,0),5.8)
		if model.landing_weight>.1: saw_land=true
	if not saw_fall or not saw_land or not player.is_on_floor() or model.landing_weight!=0:
		_fail("Jump lacks falling/landing recovery or fails to return to stable floor"); return
	checkpoint="real stationary timber work"
	world.start_creek_preview()
	party.switch_to(2,0)
	bridge.step=1
	await _put(24,25.5)
	await _frames(15)
	await _press_key(KEY_E,true)
	await _frames(18)
	model=party._visual(player).detailed_model
	if bridge._timber_progress<=0 or model.work_kind!="wood" or model.animation_player.current_animation!="motion/work_wood":
		_fail("Valid timber task does not produce its working pose"); return
	var leg: int=model.skeleton.find_bone("thigh.L")
	var hand: int=model.skeleton.find_bone("hand.R")
	var planted: Quaternion=model.skeleton.get_bone_pose_rotation(leg)
	var hand_before: Vector3=model.skeleton.get_bone_global_pose(hand).origin
	var body_before: Vector3=player.global_position
	await _frames(14)
	if absf(planted.dot(model.skeleton.get_bone_pose_rotation(leg)))<.9999 or hand_before.distance_to(model.skeleton.get_bone_global_pose(hand).origin)<.004 or player.global_position.distance_to(body_before)>.003:
		_fail("Timber work slides feet or lacks an actual hand stroke"); return
	await _detail_view("timber-work",player.global_position+Vector3(0,1.4,7),player.global_position+Vector3(0,.35,0),5.6)
	await _press_key(KEY_E,false)
	await _frames(20)
	if model.work_kind!="" or model.current_state!="idle": _fail("Released work leaves a stale pose"); return
	checkpoint="stone work and planted carry"
	bridge.step=2
	bridge.material_delivered=true
	bridge.timber_prepared=true
	bridge.crate.position.x=9.5
	await _put(29.6,30.5)
	await _press_key(KEY_P,true)
	await _frames(24)
	var stone_model: Node3D=party._visual(second).detailed_model
	if bridge.action_progress<=0 or stone_model.work_kind!="stone": _fail("Stoneworker uses no masonry work pose"); return
	await _detail_view("stone-work",second.global_position+Vector3(0,1.4,7),second.global_position+Vector3(0,.35,0),5.6)
	await _press_key(KEY_P,false)
	bridge.bridge_ready=true
	bridge.step=5
	bridge.get_node("BridgeAssembly").visible=true
	bridge.get_node("BridgeAssembly").rotation.z=0
	bridge.get_node("BridgeBody/Collision").disabled=false
	await _put(38.4,35)
	await _frames(120)
	stone_model=party._visual(second).detailed_model
	if stone_model.current_state!="carry" or stone_model.animation_player.current_animation!="motion/carry_plant":
		_fail("Stationary support still plays walking legs"); return
	planted=stone_model.skeleton.get_bone_pose_rotation(stone_model.skeleton.find_bone("thigh.L"))
	await _frames(25)
	if absf(planted.dot(stone_model.skeleton.get_bone_pose_rotation(stone_model.skeleton.find_bone("thigh.L"))))<.9999:
		_fail("Stationary carry shuffles a planted foot"); return
	await _press_key(KEY_E,true)
	await _press_key(KEY_P,true)
	await _frames(18)
	if party._visual(player).detailed_model.work_kind!="rope" or stone_model.work_kind!="stone":
		_fail("Two actual rescue roles lack their distinct rope / support actions"); return
	_save_coop("motion-rope-and-stone-support")
	await _press_key(KEY_E,false)
	await _press_key(KEY_P,false)
	await _near_key(KEY_H)
	var time_before: float=stone_model.animation_player.current_animation_position
	await _frames(12)
	if stone_model.animation_player.current_animation_position!=time_before: _fail("Working animations keep running under pause"); return
	await _near_key(KEY_ESCAPE)
	await _tap("restart_lesson")
	await _frames(20)
	for body in party.all_bodies():
		var visual: Node3D=party._visual(body)
		if not visual.detailed_model.work_kind.is_empty() or visual.transport_pose or not body.is_physics_processing():
			_fail("Reset leaves action pose / control ownership behind"); return
	watchdog.timeout.disconnect(_timed_out)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("GATE_MOTION_OK: actual tiled exit gate / beam brackets and no new collisions, physical walking / stop, real rising-falling jump and landing recovery, pause freeze, real wood and masonry hands with planted feet, distinct rope/support actions, static loaded stance, release and reset cleanup")
	quit(0)


func _timed_out() -> void:
	_fail("Gate / motion timeout at "+checkpoint)
