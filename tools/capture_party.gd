extends "res://tools/verify_party_game.gd"

var viewport: SubViewport


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("Party preview requires a real renderer"); return
	root.mode = Window.MODE_MINIMIZED
	OS.low_processor_usage_mode = false
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	world = load("res://scenes/world.tscn").instantiate()
	world.get_node("Party").local_coop = false
	viewport.add_child(world)
	player = world.get_node("Player")
	party = world.get_node("Party")
	ui = world.get_node("PartyUI")
	first = world.get_node("Spaces/Space01/Cooperation")
	bridge = world.get_node("Spaces/Space02/BridgeCooperation")
	court = world.get_node("Spaces/Space03/CourtyardCooperation")
	for glyph in "晋故振威建宁宋龙骧将军":
		if not first.CUAN_FONT.has_char(glyph.unicode_at(0)):
			_fail("Cuan font is missing glyph: " + glyph); return
	print("CUAN_FONT_OK: ", first.CUAN_FONT.get_font_name(), " covers both inscription excerpts")
	DirAccess.make_dir_recursive_absolute("res://previews")
	await _frames(20)
	for id in range(2):
		var inscription: Image = first.inspector.images[id].get_image()
		if inscription == null or inscription.is_empty():
			_fail("Stone inscription image is empty"); return
		if inscription.save_png("res://previews/stele-inscription-%d.png" % id) != OK:
			_fail("Cannot save stone inscription image"); return
	_save("party-title.png")
	await _tap("ui_accept")
	_save("party-intro.png")
	for index in range(4): await _tap("ui_accept")
	await _frames(6)
	_save("party-birth.png")
	if not await _walk(10): _fail("Cannot render following"); return
	await _frames(90)
	_save("party-follow.png")
	if not await _at(0, 13.5): _fail("Cannot stage observation"); return
	await _frames(60)
	_save("stele-models.png")
	await _click_stone(1)
	await _frames(10)
	_save("stele-large-image.png")
	await _key(KEY_ESCAPE)
	await _click_stone(0)
	await _frames(10)
	_save("puzzle-entry.png")
	_save("stele-small-image.png")
	for id in range(4):
		await _select(id)
		await _hold()
	_save("puzzle-clues.png")
	_save("puzzle-cuan-clues.png")
	_save("stele-small-puzzle.png")
	await _finish_observation()
	await _frames(150)
	if not first.gate_open: _fail("Memory puzzle did not unlock the door"); return
	_save("puzzle-solved.png")
	if not await _at(2, 22.5): _fail("Cannot find the bridge"); return
	await _hold()
	if not await _walk(23.1): _fail("Cannot push wood"); return
	await _hold()
	Input.action_press("interact")
	Input.action_press("move_right")
	for frame in range(1200):
		await physics_frame
		if bridge.material_delivered: break
	Input.action_release("interact")
	Input.action_release("move_right")
	await _frames(45)
	if not await _at(0, 27): _fail("Cannot read route"); return
	await _hold()
	if not await _at(1, 30.5): _fail("Cannot build piers"); return
	await _hold()
	if not await _at(3, 22.5): _fail("Cannot request villagers"); return
	await _hold()
	if not await _walk(30.5): _fail("Cannot regroup"); return
	await _frames(180)
	await _hold()
	await _frames(200)
	if not await _walk(35): _fail("Cannot cross bridge"); return
	await _frames(90)
	_save("party-bridge.png")
	await _hold()
	if not await _at(1, 49): _fail("Cannot install tablet"); return
	await _hold()
	for index in range(7):
		if not await _complete_courtyard_item(index): _fail("Cannot light the courtyard"); return
	await _frames(180)
	if not await _walk(58): _fail("Cannot reach record"); return
	await _frames(60)
	_save("party-ending.png")
	await _tap("open_archive")
	_save("party-archive.png")
	await _tap("open_archive")
	print("PARTY_RENDER_OK: inscribed models, both enlarged images, puzzle, title, intro, following, bridge, ending and archive rendered")
	quit(0)


func _save(filename: String) -> void:
	RenderingServer.force_draw(false)
	var result: Image = viewport.get_texture().get_image()
	if result == null or result.is_empty() or result.save_png("res://previews/" + filename) != OK:
		_fail("Preview image could not be saved")
