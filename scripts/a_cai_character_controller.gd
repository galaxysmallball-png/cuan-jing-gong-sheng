extends "res://scripts/character_animation_controller.gd"

var hoe_detail: Node3D


func _ready() -> void:
	super._ready()
	preload("res://scripts/skinned_prop_mesh.gd").omit(self,["hoe"])
	hoe_detail=preload("res://scripts/forged_hoe_detail.gd").new()
	add_child(hoe_detail)
	hoe_detail.build()
	_sync_hoe()


func _process(_delta: float) -> void:
	_sync_hoe()


func _sync_hoe() -> void:
	if current_state in ["carry","push","jump"]:
		var upright:=Basis(Vector3.BACK,PI/2-.12)
		hoe_detail.transform=Transform3D(upright,Vector3(-.58,.73,.12)-upright*Vector3(0,1.34,-.02))
	else:
		var index: int=skeleton.find_bone("hoe")
		hoe_detail.global_transform=skeleton.global_transform*skeleton.get_bone_global_pose(index)*skeleton.get_bone_global_rest(index).affine_inverse()


func animate_model(delta: float, speed: float, grounded: bool, pushing: bool, carrying: bool, reading: bool = false) -> void:
	var previous: String = current_state
	super.animate_model(delta, speed, grounded, pushing, carrying, reading)
	# At a stationary work pose speed_scale is low. An interpolated scale would
	# leave a half-sized hoe across her arms during the start of assembly.
	if current_state != previous and current_state in ["carry", "push", "jump"]:
		animation_player.play(_clips[current_state], 0.0)
		animation_player.advance(0)
