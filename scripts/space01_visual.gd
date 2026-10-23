extends Node3D

@export_range(0.0, 0.25, 0.01) var mist_strength: float = 0.16
@export_range(0.5, 2.5, 0.1) var moonlight_energy: float = 1.5


func _ready() -> void:
	for group in ["Paving", "Masonry", "Timber", "DisplayFrames", "Foreground", "Growth", "Mist", "Moonlight"]:
		get_node(group).visible = false
	var art: Node3D = preload("res://scripts/courtyard_art.gd").new()
	add_child(art)
	art.setup(get_node("../Cooperation"), mist_strength, moonlight_energy)
