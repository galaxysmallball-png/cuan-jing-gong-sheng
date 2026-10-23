extends "res://tools/verify_a_cai_character.gd"


func _initialize() -> void:
	capture = true
	call_deferred("_run")
