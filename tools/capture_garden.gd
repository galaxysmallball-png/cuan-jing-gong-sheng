extends "res://tools/verify_garden_preview.gd"


func _initialize() -> void:
	capture = true
	call_deferred("_run")
