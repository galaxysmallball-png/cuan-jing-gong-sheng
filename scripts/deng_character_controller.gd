extends "res://scripts/character_animation_controller.gd"


func _init() -> void:
	model_scene = preload("res://assets/characters/deng_shunian/deng_shunian_neck_v3.glb")
	skin_material_names = PackedStringArray(["Face_SoftSkin", "Face_EarAndLid", "Face_Neck"])
