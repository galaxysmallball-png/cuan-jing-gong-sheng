extends "res://tools/verify_village_characters.gd"


func _initialize() -> void:
	capture = true
	call_deferred("_run")
