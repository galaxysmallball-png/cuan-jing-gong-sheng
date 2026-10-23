extends "res://tools/verify_lao_character.gd"


func _initialize() -> void:
	capture = true
	call_deferred("_run")
