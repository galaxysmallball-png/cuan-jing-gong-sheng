extends "res://scripts/environment_art.gd"

var chapter: Node3D
var carriers: Array[CharacterBody3D]=[]
var starts: Array[Vector3]=[]
var physics_enabled: Array[bool]=[]
var controls_enabled: Array[bool]=[]
var grips: Array[MeshInstance3D]=[]
var slings: Array[MeshInstance3D]=[]
var released: bool=false
var progress: float=0
var walk_phase: float=0
const OFFSETS: Array[Vector3]=[Vector3(-1.65,.70,.90),Vector3(.95,.70,.90),Vector3(-2.20,.70,-.70),Vector3(1.50,.70,-.70)]


func setup(owner_chapter: Node3D) -> void:
	name="FourPersonSteleCarry"
	chapter=owner_chapter
	var wood: Material=_surface(Color(.36,.23,.12),2)
	var rope: Material=_flat(Color(.68,.55,.33))
	for role in range(4):
		var body: CharacterBody3D=chapter.party.role_body(role)
		carriers.append(body)
		starts.append(body.global_position)
		physics_enabled.append(body.is_physics_processing())
		body.set_physics_process(false)
		body.velocity=Vector3.ZERO
		var visual: Node3D=chapter.party._visual(body)
		visual.transport_pose=true
		visual.transport_speed=.8
		grips.append(_rod(self,Vector3.ZERO,Vector3.UP*.4,.025,wood))
		for side in range(2): slings.append(_rod(self,Vector3.ZERO,Vector3.UP,.012,rope))
	for body in chapter.party.human_players(): controls_enabled.append(body.controls_enabled)
	chapter.party.set_controls(false)
	chapter.party.set_interaction_lock(true)
	apply_pose(0)


func apply_pose(amount: float) -> void:
	progress=amount
	var raw_travel: float=clampf((amount-.12)/.74,0,1)
	# Short acceleration/deceleration ramps preserve the arrival duration while
	# removing the abrupt jump to full carrying speed at either end.
	var ramp: float=.08
	var travel: float=(raw_travel-ramp*.5)/(1-ramp)
	if raw_travel<ramp: travel=raw_travel*raw_travel/(2*ramp*(1-ramp))
	elif raw_travel>1-ramp: travel=1-pow(1-raw_travel,2)/(2*ramp*(1-ramp))
	travel=clampf(travel,0,1)
	var lift: float=smoothstep(0,.14,amount)
	var lower: float=smoothstep(.84,1,amount)
	var start: Vector3=chapter.arrival_from
	var load: Vector3=start.lerp(Vector3(chapter.PLACEMENT_X,.5,-1.8),travel)
	walk_phase=travel*absf(chapter.PLACEMENT_X-start.x)/.95
	var moving_weight: float=sin(raw_travel*PI)
	var breath: float=sin(walk_phase*TAU*2)*.012*moving_weight
	var frame_height: float=lerpf(.11,.82,lift)*(1-lower)+chapter.FRAME_REST_Y*lower
	chapter._arrival_sled.position=Vector3(load.x,frame_height+breath,load.z)
	chapter._tablet.position=Vector3(load.x,frame_height+chapter.TABLET_FRAME_OFFSET+breath,load.z)
	chapter._tablet.rotation=Vector3(-PI/2,0,PI/2)
	var gathering: float=smoothstep(0,.12,amount)
	for role in range(4):
		var offset: Vector3=OFFSETS[role]
		# Keep the walkers on the courtyard lane as the suspended load is lowered
		# into its alcove; the visible ropes stay attached to the real hands.
		var lane_z: float=lerpf(start.z,-.20,travel)
		var target: Vector3=chapter.to_global(Vector3(load.x+offset.x,offset.y,lane_z+offset.z))
		carriers[role].global_position=starts[role].lerp(target,gathering)
		var visual: Node3D=chapter.party._visual(carriers[role])
		var cruise_speed: float=absf(chapter.PLACEMENT_X-start.x)/(chapter.ARRIVAL_SECONDS*.74*(1-ramp))
		visual.transport_speed=cruise_speed*minf(1,minf(raw_travel/ramp,(1-raw_travel)/ramp)) if amount>.12 and amount<.86 else 0
		visual.transport_phase=walk_phase
		visual.transport_crouch=(1-lift)*gathering+lower


func _process(_delta: float) -> void:
	if released: return
	for role in range(carriers.size()):
		var model: Node3D=chapter.party._visual(carriers[role]).detailed_model
		var skeleton: Skeleton3D=model.skeleton
		var hands: Array[Vector3]=[]
		for suffix in ["L","R"]:
			var index: int=skeleton.find_bone("hand."+suffix)
			hands.append(to_local(skeleton.global_transform*skeleton.get_bone_global_pose(index).origin))
		_place_rod(grips[role],hands[0],hands[1])
		for side in range(2):
			var anchor: Vector3=chapter._arrival_sled.position+Vector3(-.91 if role in [0,2] else .91,.17,-.36 if role>=2 else .36)
			_place_rod(slings[role*2+side],hands[side],anchor+Vector3(0,0,(-.08 if side==0 else .08)))
		grips[role].visible=progress>.04 and progress<.99
		for side in range(2): slings[role*2+side].visible=grips[role].visible


func release() -> void:
	if released: return
	released=true
	for index in range(carriers.size()):
		var body: CharacterBody3D=carriers[index]
		if not is_instance_valid(body): continue
		body.set_physics_process(physics_enabled[index])
		body.velocity=Vector3.ZERO
		var visual: Node3D=chapter.party._visual(body)
		visual.transport_pose=false
		visual.transport_phase=-1
		visual.transport_crouch=0
		chapter.party.role_headings[body.character_id]=.58
	for slot in range(chapter.party.human_players().size()):
		var body: CharacterBody3D=chapter.party.human_players()[slot]
		body.controls_enabled=controls_enabled[slot]
	chapter.party.set_interaction_lock(false)


func _exit_tree() -> void:
	if not released and is_instance_valid(chapter): release()
