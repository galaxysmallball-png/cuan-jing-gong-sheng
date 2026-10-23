extends Node3D

@export var model_scene: PackedScene
@export var skin_material_names: PackedStringArray
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var current_state: String = ""
var _clips: Dictionary = {}
var motion_variants: Dictionary={}
var work_kind: String=""
var vertical_speed: float=0
var crouch_amount: float=0
var synchronized_phase: float=-1
var landing_weight: float=0
var _was_grounded: bool=true
var _landing_left: float=0
var _gait_speed: float=0
var _playing_clip: String=""
var _model: Node3D
var _model_rest: Transform3D


func _ready() -> void:
	var model: Node3D = model_scene.instantiate()
	add_child(model)
	_model=model
	_model_rest=model.transform
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
			if material != null and material.resource_name in skin_material_names:
				material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
				material.roughness = 0.35
				material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
				material.disable_receive_shadows = false
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	animation_player = model.find_children("*", "AnimationPlayer", true, false)[0]
	for clip in animation_player.get_animation_list():
		for state in ["idle", "walk", "jump", "push", "carry", "inspect"]:
			if str(clip).to_lower().ends_with(state):
				_clips[state] = clip
				animation_player.get_animation(clip).loop_mode = Animation.LOOP_NONE if state == "jump" else Animation.LOOP_LINEAR
	motion_variants=preload("res://scripts/motion_clip_polish.gd").build(skeleton,animation_player,_clips)
	animate_model(0, 0, true, false, false)
	animation_player.advance(0)


func _state(speed: float, grounded: bool, pushing: bool, carrying: bool, reading: bool) -> String:
	if not grounded: return "jump"
	if carrying: return "carry"
	if pushing: return "push"
	if reading: return "inspect"
	return "walk" if speed > 0.15 else "idle"


func animate_model(delta: float, speed: float, grounded: bool, pushing: bool, carrying: bool, reading: bool = false) -> void:
	var state: String = _state(speed, grounded, pushing, carrying, reading)
	var clip: String=_clips[state]
	if grounded and not work_kind.is_empty() and motion_variants.has("work_"+work_kind):
		state="push"
		clip=motion_variants["work_"+work_kind]
	elif state=="carry" and motion_variants.has("carry_plant"):
		if crouch_amount>.18: clip=motion_variants.carry_lift
		elif speed<.15: clip=motion_variants.carry_plant
	elif state=="jump" and vertical_speed<-.3 and motion_variants.has("jump_fall"):
		clip=motion_variants.jump_fall
	# A completed airborne clip holds its last pose; it never restarts in midair.
	if current_state!=state or _playing_clip!=clip:
		animation_player.play(clip,.09 if state=="jump" else .18)
		_playing_clip=clip
	current_state=state
	_gait_speed=move_toward(_gait_speed,speed,delta*12)
	var locomotion: bool=clip==str(_clips.walk) or (clip==str(_clips.carry) and speed>.15) or (clip==str(_clips.push) and speed>.15)
	var stride: float=.95 if state=="carry" else 1.15
	animation_player.speed_scale=clampf(_gait_speed*animation_player.get_animation(clip).length/stride,.16,2.3) if locomotion else 1.0
	if synchronized_phase>=0 and state=="carry" and locomotion:
		animation_player.seek(fposmod(synchronized_phase,1)*animation_player.get_animation(clip).length,true)
	if grounded and not _was_grounded: _landing_left=.24
	_was_grounded=grounded
	_landing_left=maxf(0,_landing_left-delta)
	landing_weight=sin(clampf(_landing_left/.24,0,1)*PI) if grounded else 0
	var lean: float=clampf(_gait_speed*.010,0,.045) if grounded and speed>.15 else 0
	var presentation:=Transform3D(Basis.from_euler(Vector3(lean,0,0)).scaled(Vector3(1,1-landing_weight*.045,1)),Vector3.ZERO)
	_model.transform=_model_rest*presentation


func pose(time: float, _gait: float, speed: float, grounded: bool, pushing: bool, carrying: bool, reading: bool = false) -> void:
	current_state = _state(speed, grounded, pushing, carrying, reading)
	animation_player.play(_clips[current_state])
	animation_player.seek(time, true)
	animation_player.pause()
	_playing_clip=""
	_model.transform=_model_rest
	_was_grounded=grounded
	_landing_left=0
	landing_weight=0
