extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world: Node3D = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var ui: CanvasLayer = world.get_node("PartyUI")
	var party: Node3D = world.get_node("Party")
	var first: Node3D = world.get_node("Spaces/Space01/Cooperation")
	var bridge: Node3D = world.get_node("Spaces/Space02/BridgeCooperation")
	if not ui.chapter_preview.visible:
		push_error("Title is missing the second-chapter review entry"); quit(1); return
	ui.chapter_preview.pressed.emit()
	for frame in range(60): await physics_frame
	if not party.started or ui.screen != ui.Screen.GAME or not first.gate_open or not first.observed \
		or party.player.global_position.x < 20 or party.second_player.global_position.x < 20 \
		or bridge.step != 0 or bridge.timber_prepared or bridge.bridge_ready or bridge.gap_stabilized \
		or bridge.get_node("BridgeAssembly").visible:
		push_error("Chapter review skips creek tasks or fails to begin with both players"); quit(1); return
	Input.action_press("restart_lesson")
	for frame in range(3): await physics_frame
	Input.action_release("restart_lesson")
	for frame in range(60): await physics_frame
	if first.gate_open or party.player.global_position.x > 6 or party.second_player.global_position.x > 6:
		push_error("T after the review entry does not restore a full fresh game"); quit(1); return
	print("CREEK_PREVIEW_OK: title button enters an untouched creek with both players; T restores full game")
	quit(0)
