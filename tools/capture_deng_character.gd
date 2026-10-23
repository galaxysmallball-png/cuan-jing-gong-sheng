extends "res://tools/verify_deng_character.gd"


func _initialize() -> void:
	capture = true
	call_deferred("_run")
