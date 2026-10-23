extends SceneTree

var model: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://scenes/characters")
	DirAccess.make_dir_recursive_absolute("res://assets/characters/deng_shunian")
	model = preload("res://scripts/deng_shunian_model.gd").new()
	root.add_child(model)
	await process_frame
	if model.get_node_or_null("Rig/Head/Eyes") == null:
		push_error("Character geometry did not build"); quit(1); return
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	model.add_child(player)
	var library := AnimationLibrary.new()
	for config in [["idle",4.7,0.0,true,false,false,false], ["walk",TAU/10.5,3.0,true,false,false,false],
		["jump",0.8,3.0,false,false,false,false], ["push",TAU/10.5,2.0,true,true,false,false],
		["carry",TAU/10.5,2.5,true,false,true,false], ["inspect",3.0,0.0,true,false,false,true]]:
		var animation := Animation.new()
		animation.resource_name = config[0]
		animation.length = config[1]
		animation.loop_mode = Animation.LOOP_LINEAR if config[0] != "jump" else Animation.LOOP_NONE
		var paths: Array[String] = ["Rig", "Rig/Head", "Rig/Skirt", "Rig/BookBag", "Rig/WaistOrnaments", "Rig/LeftArm", "Rig/RightArm", "Rig/LeftArm/Forearm", "Rig/RightArm/Forearm", "Rig/LeftLeg", "Rig/RightLeg", "Rig/LeftLeg/Knee", "Rig/RightLeg/Knee", "Rig/Head/HatRibbonLeft", "Rig/Head/HatRibbonRight", "Rig/Head/Eyes"]
		for path in paths:
			for type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
				var track: int = animation.add_track(type)
				animation.track_set_path(track, NodePath(path))
		var frames: int = int(ceil(animation.length*30))
		for frame in range(frames+1):
			var time: float = animation.length*frame/frames
			model.pose(time,time*10.5,config[2],config[3],config[4],config[5],config[6])
			for index in range(paths.size()):
				var part: Node3D = model.get_node(paths[index])
				animation.track_insert_key(index*3,time,part.position)
				animation.track_insert_key(index*3+1,time,Quaternion.from_euler(part.rotation))
				animation.track_insert_key(index*3+2,time,part.scale)
		library.add_animation(config[0],animation)
	player.add_animation_library("",library)
	model.pose(0,0,0,true,false,false)
	_set_owner(model,model)
	var packed := PackedScene.new()
	if packed.pack(model) != OK or ResourceSaver.save(packed,"res://scenes/characters/deng_shunian.tscn") != OK:
		push_error("Could not save editable Godot character scene"); quit(1); return
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_scene(model,state) != OK or document.write_to_filesystem(state,"res://assets/characters/deng_shunian/邓书年.glb") != OK:
		push_error("Could not export character GLB"); quit(1); return
	var check := GLTFDocument.new()
	var check_state := GLTFState.new()
	if check.append_from_file("res://assets/characters/deng_shunian/邓书年.glb",check_state) != OK:
		push_error("Exported GLB cannot be read back"); quit(1); return
	if check_state.get_meshes().size() < 40 or check_state.get_animations().size() != 6:
		push_error("GLB lost the model geometry or six animation clips"); quit(1); return
	print("DENG_ASSET_OK: editable TSCN, re-readable GLB, ",check_state.get_meshes().size()," meshes and six animation clips")
	quit(0)


func _set_owner(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_set_owner(child,scene_root)
