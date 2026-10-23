extends "res://tools/verify_field_satchel.gd"


func _initialize() -> void:
	capture = true
	call_deferred("_run")
