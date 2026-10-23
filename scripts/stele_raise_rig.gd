extends "res://scripts/environment_art.gd"

var chapter: Node3D
var origin: Vector3
var initial_rotation: Quaternion
var foot_y: float
var socket_y: float
var ropes: Array[MeshInstance3D] = []
var materials: Array[StandardMaterial3D] = []
var fade_left: float = -1
var actors: Array[CharacterBody3D]=[]
var actor_starts: Array[Vector3]=[]
var actor_physics: Array[bool]=[]
var hand_lines: Array[MeshInstance3D]=[]
var actors_released: bool=false
var lift_progress: float=0
const WORK_SPOTS: Array[Vector3]=[Vector3(-1.05,.70,-.60),Vector3(1.05,.70,-.60),Vector3(-2.15,.70,.55),Vector3(2.15,.70,.55)]


func setup(owner_chapter: Node3D) -> void:
	name="SteleLiftingRig"
	chapter=owner_chapter
	origin=chapter._tablet.position
	initial_rotation=chapter._tablet.quaternion
	foot_y=_lowest_point(chapter._tablet,Transform3D.IDENTITY)
	var plinth: MeshInstance3D = chapter.landscape.stele_plinth
	socket_y=plinth.position.y+plinth.get_aabb().end.y
	var timber := _rig_material(Color(.37,.24,.13))
	var rope := _rig_material(Color(.66,.55,.35))
	var iron := _rig_material(Color(.25,.29,.26))
	var x: float = chapter.PLACEMENT_X
	for side in [-1,1]:
		var crown := Vector3(x+side*1.60,3.65,-2.93)
		for z in [-3.43,-2.63]:
			var foot := Vector3(x+side*1.78,.58,z)
			_box(self,foot-Vector3(0,.06,0),Vector3(.45,.12,.47),timber)
			_rod(self,foot,crown,.075,timber)
		_rod(self,Vector3(x+side*1.72,1.55,-3.25),Vector3(x+side*1.65,1.55,-2.77),.045,timber)
		_box(self,crown,Vector3(.29,.17,.28),iron)
	_rod(self,Vector3(x-1.78,3.68,-2.93),Vector3(x+1.78,3.68,-2.93),.11,timber)
	# A low trestle takes the slab's weight during the first levering movement.
	for offset in [-.35,.35]:
		_rod(self,Vector3(x-1.3,.12,-2.35+offset),Vector3(x-1.3,.34,-2.35),.065,timber)
	_rod(self,Vector3(x-1.65,.34,-2.35),Vector3(x-.96,.34,-2.35),.075,timber)
	for side in [-1,1]:
		ropes.append(_rod(self,Vector3(x+side*.46,3.56,-2.86),Vector3(x,1,-2.2),.014,rope))
	# The same four party bodies who delivered the slab now take the levering
	# and haul lines; no duplicate figures and no independent sliding stone.
	for role in range(4):
		var body: CharacterBody3D=chapter.party.role_body(role)
		actors.append(body)
		actor_starts.append(body.global_position)
		actor_physics.append(body.is_physics_processing())
		body.set_physics_process(false)
		body.velocity=Vector3.ZERO
		var visual: Node3D=chapter.party._visual(body)
		visual.transport_pose=true
		visual.transport_phase=-1
		visual.transport_speed=0
		for side in range(2): hand_lines.append(_rod(self,Vector3.ZERO,Vector3.UP,.011,rope))
	apply_pose(0)
	set_meta("foot_pivot",foot_y)
	set_meta("socket_top",socket_y)


func _rig_material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color=tint
	material.roughness=.94
	materials.append(material)
	return material


func _lowest_point(node: Node3D, relative: Transform3D) -> float:
	if node.get_meta("nonstructural_effect",false): return 100
	var result: float = (relative*node.get_aabb()).position.y if node is MeshInstance3D else 100
	for child in node.get_children():
		if child is Node3D: result=minf(result,_lowest_point(child,relative*child.transform))
	return result


func apply_pose(progress: float) -> void:
	lift_progress=progress
	var pivot := Vector3(chapter.PLACEMENT_X,origin.y,-2.35)
	var orientation: Quaternion
	if progress<.16:
		var t: float = smoothstep(0,1,progress/.16)
		orientation=initial_rotation
		var prepared: Vector3 = pivot-Basis(orientation)*Vector3(0,foot_y,0)
		chapter._tablet.position=origin.lerp(prepared,t)
	else:
		if progress<.86:
			var t: float = smoothstep(0,1,(progress-.16)/.70)
			orientation=initial_rotation.slerp(Quaternion(Vector3.BACK,.065),t)
			pivot.y=lerpf(origin.y,socket_y+.09,t)
		else:
			var t: float = smoothstep(0,1,(progress-.86)/.14)
			orientation=Quaternion(Vector3.BACK,.065).slerp(Quaternion.IDENTITY,t)
			pivot.y=lerpf(socket_y+.09,socket_y,t)
		chapter._tablet.position=pivot-Basis(orientation)*Vector3(0,foot_y,0)
	chapter._tablet.quaternion=orientation
	# A tilted cap has a lower corner than its centre-line foot. Keep that
	# corner above the platform throughout the turn, then seat the foot exactly.
	var rotated_bottom: float=_lowest_point(chapter._tablet,Transform3D(Basis(orientation),Vector3.ZERO))
	var clearance: float=.018*(1-smoothstep(.95,1,progress))
	chapter._tablet.position.y=maxf(chapter._tablet.position.y,socket_y+clearance-rotated_bottom)
	for index in range(2):
		var side: int = -1 if index==0 else 1
		var attachment: Vector3 = chapter._tablet.transform*Vector3(side*.38,.72,.22)
		_place_rod(ropes[index],Vector3(chapter.PLACEMENT_X+side*.46,3.56,-2.86),attachment)
	# The delivery sled is drawn back as the hoist takes the load.
	chapter._arrival_sled.position.x=chapter.PLACEMENT_X-progress*.7
	chapter._arrival_sled.position.z=-1.8+smoothstep(.15,.75,progress)*.65
	chapter._arrival_sled.visible=progress<.80
	if not actors_released:
		for role in range(4):
			var target: Vector3=chapter.to_global(Vector3(chapter.PLACEMENT_X,0,0)+WORK_SPOTS[role])
			actors[role].global_position=actor_starts[role].lerp(target,smoothstep(0,.16,progress))
			var visual: Node3D=chapter.party._visual(actors[role])
			var facing: Vector3=chapter.to_global(Vector3(chapter.PLACEMENT_X,1,-2.35))-actors[role].global_position
			visual.transport_heading=atan2(facing.x,facing.z)
			visual.transport_work_kind=("stone" if role<2 else "rope") if progress>.12 and progress<.96 else ""
			visual.transport_crouch=.32*(1-smoothstep(.12,.45,progress))
			visual.transport_speed=0
	_update_hand_lines()


func _update_hand_lines() -> void:
	if actors_released: return
	for role in range(actors.size()):
		var skeleton: Skeleton3D=chapter.party._visual(actors[role]).detailed_model.skeleton
		for side in range(2):
			var hand: int=skeleton.find_bone("hand.L" if side==0 else "hand.R")
			var grip: Vector3=to_local(skeleton.global_transform*skeleton.get_bone_global_pose(hand).origin)
			var anchor: Vector3
			if role<2:
				anchor=chapter._tablet.transform*Vector3(-.50 if role==0 else .50,-.25+side*.35,.20)
			else:
				anchor=Vector3(chapter.PLACEMENT_X+(-.46 if role==2 else .46),3.56,-2.86)
			_place_rod(hand_lines[role*2+side],grip,anchor)
			hand_lines[role*2+side].visible=lift_progress>.10 and lift_progress<.98


func release_actors() -> void:
	if actors_released: return
	actors_released=true
	for index in range(actors.size()):
		var body: CharacterBody3D=actors[index]
		if not is_instance_valid(body): continue
		body.set_physics_process(actor_physics[index])
		body.velocity=Vector3.ZERO
		var visual: Node3D=chapter.party._visual(body)
		visual.transport_pose=false
		visual.transport_work_kind=""
		visual.transport_heading=.58
		visual.transport_crouch=0
		visual.transport_phase=-1
		chapter.party.role_headings[body.character_id]=.58
	for line in hand_lines: line.visible=false


func dismantle() -> void:
	release_actors()
	for material in materials: material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	fade_left=.65


func _process(delta: float) -> void:
	_update_hand_lines()
	if fade_left<0: return
	fade_left=maxf(0,fade_left-delta)
	for material in materials:
		var tint: Color = material.albedo_color
		tint.a=fade_left/.65
		material.albedo_color=tint
	if fade_left<=0: queue_free()


func _exit_tree() -> void:
	if not actors_released and is_instance_valid(chapter): release_actors()
