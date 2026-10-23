extends "res://scripts/traveler_visual.gd"

const CharacterNames = preload("res://scripts/character_names.gd")
var character_id: int = 0
var _accessories: Node3D
var _label: Label3D
var detailed_model: Node3D
var _model_direction: float = 1.0
var _planar_heading: float = .58
var transport_pose: bool=false
var transport_speed: float=0
var transport_phase: float=-1
var transport_crouch: float=0
var transport_heading: float=.58
var transport_work_kind: String=""
const DETAILED_SCENES: Dictionary = {
	0: preload("res://scenes/characters/deng_shunian_character.tscn"),
	1: preload("res://scenes/characters/shi_aduo_character.tscn"),
	2: preload("res://scenes/characters/lao_qing_character.tscn"),
	3: preload("res://scenes/characters/yang_sanniang_character.tscn"),
}


func _ready() -> void:
	_accessories = Node3D.new()
	add_child(_accessories)
	_label = Label3D.new()
	_label.position = Vector3(0, 1.72, 0)
	_label.font_size = preload("res://scripts/interface_skin.gd").text_size(26)
	_label.pixel_size = 0.0045
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var font := preload("res://scripts/interface_skin.gd").heading_font()

	_label.font = font
	add_child(_label)
	set_character_id(get_parent().character_id)


func set_character_id(id: int) -> void:
	character_id = id
	if _accessories == null:
		return
	for child in _accessories.get_children():
		_accessories.remove_child(child)
		child.queue_free()
	detailed_model = null
	for path in ["Torso", "Head", "Nose", "Eye", "LeftLeg", "RightLeg", "LeftArm", "RightArm"]:
		get_node(path).visible = id not in DETAILED_SCENES
	var coats: Array[Color] = [Color(0.15, 0.23, 0.32), Color(0.43, 0.49, 0.45), Color(0.17, 0.21, 0.23), Color(0.16, 0.23, 0.30)]
	for path in ["Torso", "LeftArm/Sleeve", "RightArm/Sleeve", "LeftLeg/Leg", "RightLeg/Leg"]:
		var mesh: MeshInstance3D = get_node(path)
		var material: StandardMaterial3D = mesh.material_override.duplicate()
		material.albedo_color = coats[id]
		mesh.material_override = material
	$Mantle.visible = false
	$Hair.visible = false
	$Scarf.visible = false
	$Strap.visible = id == 0 or id == 2
	$Satchel.visible = id == 0 or id == 2
	var first_player: bool = get_parent().name == "Player"
	var second_player: bool = get_parent().name == "Player2"
	_label.text = ("1P ▼\n" if first_player else ("2P ▼\n" if second_player else "")) + CharacterNames.DISPLAY_NAMES[id]
	_label.modulate = Color(1.0, 0.8, 0.45) if first_player else (Color(0.45, 0.85, 1) if second_player else Color(0.9, 0.93, 0.92))
	_label.position.y = [1.98, 1.84, 1.96, 1.91][id]
	if id in DETAILED_SCENES:
		$Strap.visible = false
		$Satchel.visible = false
		detailed_model = DETAILED_SCENES[id].instantiate()
		_accessories.add_child(detailed_model)
		var owner_party: Node = _model_party()
		_model_direction = owner_party.role_directions.get(id, 1.0) if owner_party != null else 1.0
		_planar_heading = owner_party.role_headings.get(id, .58) if owner_party != null else .58
		if absf(player.velocity.x) > 0.15:
			_model_direction = signf(player.velocity.x)
		rotation.y = _model_heading()


func _process(delta: float) -> void:
	if detailed_model == null:
		super._process(delta)
		return
	if transport_pose:
		_planar_heading=transport_heading
		_model_direction=1
		rotation.y=transport_heading
		detailed_model.work_kind=transport_work_kind
		detailed_model.crouch_amount=transport_crouch
		detailed_model.synchronized_phase=transport_phase
		detailed_model.animate_model(delta,transport_speed,true,false,true,false)
		return
	var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	if speed > 0.15:
		if absf(player.velocity.x) > .1: _model_direction = signf(player.velocity.x)
		_planar_heading = .58 + atan2(-player.velocity.z, player.velocity.x)
		_facing = 0 if _model_direction > 0 else PI
		var owner_party: Node = _model_party()
		if owner_party != null:
			owner_party.role_directions[character_id] = _model_direction
			owner_party.role_headings[character_id] = _planar_heading
	# Reverse the full model by 180 degrees: walking left reveals its actual back.
	var pushing: bool = player.is_on_floor() and speed > 0.15 and player.handling_speed_limit >= 0
	detailed_model.vertical_speed=player.velocity.y
	detailed_model.crouch_amount=0
	detailed_model.synchronized_phase=-1
	detailed_model.work_kind=_work_context(speed)
	var target_heading: float=_model_heading()
	if not detailed_model.work_kind.is_empty():
		var facing: Vector2=_work_facing(detailed_model.work_kind)
		# Work uses the rig's actual +Z front; the travelling three-quarter
		# presentation angle would otherwise point the hands past the object.
		target_heading=atan2(facing.x,facing.y)
	rotation.y=lerp_angle(rotation.y,target_heading,1-exp(-12*delta))
	detailed_model.animate_model(delta, speed, player.is_on_floor(), pushing, player.get("carrying_pose") == true, player.get("interaction_locked") == true)


func _work_context(speed: float) -> String:
	if speed>.15 or not player.is_on_floor(): return ""
	var owner_party: Node=_model_party()
	if owner_party==null or not owner_party.started or player not in owner_party.human_players(): return ""
	var world: Node=owner_party.get_parent()
	var court: Node3D=world.courtyard
	if court.tablet_raising and owner_party.at_station(player,court.global_position.x+court.PLACEMENT_X,1.8): return "stone"
	if owner_party.movement_locked() or not Input.is_action_pressed(player.action("interact")): return ""
	var bridge: Node3D=world.bridge
	if bridge._timber_progress>0 and character_id==2 and owner_party.at_station(player,24,1.2): return "wood"
	if bridge.building and owner_party.at_station(player,30.5,1.4): return "wood"
	if bridge.step==5:
		if bridge.steady_held and character_id==1: return "stone"
		if bridge.rope_held and character_id==2: return "rope"
	elif bridge.action_progress>0 and bridge.step>=0 and bridge.step<5:
		var roles: Array[int]=[2,0,1,3,-1]
		var stations: Array[float]=[22.5,27,30.5,22.5,30.5]
		if (roles[bridge.step]<0 or roles[bridge.step]==character_id) and owner_party.at_station(player,stations[bridge.step]):
			return ["place","place","stone","place","wood"][bridge.step]
	if court.action_progress>0 and not court.tablet_placed and owner_party.at_station(player,50,1.6): return "stone"
	for index in range(7):
		if court.item_progress[index]>.0 and owner_party.at_station(player,40+court.ITEM_POSITIONS[index]):
			if (index<4 and index==character_id) or (index>=4 and court.oil_carriers[index-4]==character_id): return "place"
	return ""


func _work_facing(kind: String) -> Vector2:
	var world: Node=_model_party().get_parent()
	var target:=Vector3(player.global_position.x,0,-1.8)
	if kind=="rope": target=world.bridge._tablet.global_position
	elif kind=="stone" and player.global_position.x<40:
		target=world.bridge.landscape.repair_pier.global_position if world.bridge.step==2 else world.bridge._tablet.global_position
	elif world.courtyard.tablet_raising: target=world.courtyard._tablet.global_position
	var direction:=Vector2(target.x-player.global_position.x,target.z-player.global_position.z)
	return direction.normalized() if direction.length()>.05 else Vector2(0,-1)


func _model_heading() -> float:
	return _planar_heading


func _model_party() -> Node:
	var owner_party: Node = player.get("party")
	if owner_party != null:
		return owner_party
	var parent: Node = player.get_parent()
	return parent if parent.has_method("role_body") else parent.get_node_or_null("Party")


func _box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh.material_override = material
	_accessories.add_child(mesh)
