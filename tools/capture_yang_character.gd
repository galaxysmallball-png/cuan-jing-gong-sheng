extends "res://tools/verify_yang_character.gd"


func _initialize() -> void:
	capture = true
	call_deferred("_run")
