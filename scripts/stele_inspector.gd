extends CanvasLayer

const Art = preload("res://scripts/stele_art.gd")
const CharacterNames = preload("res://scripts/character_names.gd")
var chapter: Node3D
var inspected_id: int = -1
var images: Array[Texture2D] = []
var image_viewports: Array[SubViewport] = []
var faces: Array[MeshInstance3D] = []
var cover: ColorRect
var image: TextureRect
var heading: Label
var hint: Label
var caption: Label
var comparison: Label
var close_button: Button
var puzzle_container: SubViewportContainer
var puzzle_viewport: SubViewport
var puzzle_camera: Camera3D
var stage_guide: Label
var clue_headers: Array[Label] = []
var share_buttons: Array[Button] = []
var cycle_buttons: Array[Button] = []
var lore: Control
var lore_button: Button
var lore_open: bool = false
var rubbing: Control
var background_paper: TextureRect
var practice_title: Label
var practice_status: Label
var practice_note: Label


func setup(owner_chapter: Node3D, board: Node3D, font: FontFile) -> void:
	chapter = owner_chapter
	layer = 9
	for id in range(2):
		var image_viewport: SubViewport = Art.create_viewport(self, font, id)
		image_viewports.append(image_viewport)
		images.append(image_viewport.get_texture())
		var stone: MeshInstance3D = chapter.get_node("SmallPanel" if id == 0 else "LargePanel")
		var face := MeshInstance3D.new()
		face.name = "InscriptionFace"
		var quad := QuadMesh.new()
		quad.size = Vector2(1.04, 1.82) if id == 0 else Vector2(1.25, 1.88)
		face.mesh = quad
		face.position.z = 0.148
		if id == 1: face.position.y = -.25
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/aged_inscription.gdshader")
		material.set_shader_parameter("albedo_texture", images[id])
		face.material_override = material
		stone.add_child(face)
		faces.append(face)
		var body := StaticBody3D.new()
		body.name = "ClickTarget"
		body.collision_layer = 4
		body.collision_mask = 0
		body.set_meta("stele_id", id)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.1, 1.9, 0.30) if id == 0 else Vector3(1.35, 2.5, 0.30)
		collision.shape = shape
		body.add_child(collision)
		stone.add_child(body)
		stone.get_node("Caption").text = "小爨碑 · 六字归位" if id==0 else "大爨碑 · 二爨合读"
	_build_viewer(board)
	if DisplayServer.get_name() != "headless":
		_bake_images()


func _build_viewer(board: Node3D) -> void:
	cover = ColorRect.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.color = Color(0.025, 0.04, 0.055, 0.97)
	add_child(cover)
	background_paper=TextureRect.new()
	background_paper.texture=preload("res://assets/interface/parcel_paper.png")
	background_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_paper.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	background_paper.stretch_mode=TextureRect.STRETCH_SCALE
	background_paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cover.add_child(background_paper)
	heading = _label(Vector2(65, 118), Vector2(1020, 45), 28)
	stage_guide = _label(Vector2(65, 76), Vector2(1165, 32), 18)
	stage_guide.add_theme_color_override("font_color",Color(.50,.22,.15))
	image = TextureRect.new()
	image.position = Vector2(75, 178)
	image.size = Vector2(270, 390)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(image)
	caption = _label(Vector2(65, 574), Vector2(325, 32), 11)
	caption.text = "小爨为参考拓影；大爨为现代字库示意。\n右侧六字为节选练习。"
	hint = _label(Vector2(65, 620), Vector2(325, 66), 12)
	comparison = _label(Vector2(440, 235), Vector2(710, 340), 23)
	comparison.visible=false
	puzzle_container = SubViewportContainer.new()
	puzzle_container.position = Vector2(410, 172)
	puzzle_container.size = Vector2(1620, 876)
	puzzle_container.scale=Vector2(.5,.5)
	puzzle_container.stretch = true
	cover.add_child(puzzle_container)
	puzzle_viewport = SubViewport.new()
	puzzle_viewport.size = Vector2i(1620, 876)
	puzzle_viewport.own_world_3d = true
	puzzle_viewport.transparent_bg = true
	puzzle_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	puzzle_container.add_child(puzzle_viewport)
	board.reparent(puzzle_viewport, false)
	puzzle_camera = Camera3D.new()
	puzzle_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	puzzle_camera.size = 4.4
	puzzle_viewport.add_child(puzzle_camera)
	puzzle_camera.position = Vector3(13.1, 3.45, 12)
	puzzle_camera.current = true
	# Reading text is native canvas text. It is not rasterized into the small
	# 3D viewport then enlarged with the cards on high-resolution displays.
	practice_title=_label(Vector2(432,203),Vector2(770,39),22)
	practice_title.text="雾中拾字 · 四人合看"
	practice_title.add_theme_color_override("font_color",preload("res://scripts/interface_skin.gd").VERMILION)
	practice_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	practice_status=_label(Vector2(442,470),Vector2(407,86),18)
	practice_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	practice_note=_label(Vector2(430,579),Vector2(786,28),14)
	practice_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	practice_note.text="梁培生小爨字形 · 六字节选练习 · 非原碑复原"
	close_button = Button.new()
	close_button.position = Vector2(1100, 117)
	close_button.size = Vector2(130, 43)
	close_button.text = "关闭 / Esc"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_override("font", heading.get_theme_font("font"))
	close_button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(18))
	close_button.pressed.connect(chapter.close_puzzle)
	preload("res://scripts/interface_skin.gd").button(close_button)
	cover.add_child(close_button)
	rubbing=preload("res://scripts/cuan_rubbing.gd").new()
	rubbing.position=Vector2(410,172)
	cover.add_child(rubbing)
	rubbing.setup(chapter)
	rubbing.finished.connect(_refresh_practice)
	lore=preload("res://scripts/stele_lore.gd").new()
	lore.position=Vector2(410,172)
	cover.add_child(lore)
	lore.setup(chapter)
	lore_button=Button.new()
	lore_button.position=Vector2(884,117)
	lore_button.size=Vector2(198,43)
	lore_button.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(16))
	preload("res://scripts/interface_skin.gd").button(lore_button)
	lore_button.pressed.connect(func(): _show_lore(not lore_open))
	cover.add_child(lore_button)
	for slot in range(2):
		var card := Panel.new()
		card.position = Vector2(410+slot*410,615)
		card.size = Vector2(390,84)
		card.add_theme_stylebox_override("panel",preload("res://scripts/interface_skin.gd").texture_paper())
		cover.add_child(card)
		var label := _label(Vector2.ZERO,Vector2(366,23),14)
		label.reparent(card)
		label.position = Vector2(12,6)
		label.add_theme_color_override("font_color",Color(.20,.24,.21))
		clue_headers.append(label)
		var share := Button.new()
		share.position = Vector2(12,35)
		share.size = Vector2(224,34)
		share.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(14))
		preload("res://scripts/interface_skin.gd").button(share)
		card.add_child(share)
		var action: String = "interact" if slot==0 else "p2_interact"
		share.button_down.connect(func(): Input.action_press(action))
		share.button_up.connect(func(): Input.action_release(action))
		share_buttons.append(share)
		var cycle := Button.new()
		cycle.position = Vector2(245,35)
		cycle.size = Vector2(133,34)
		cycle.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(14))
		preload("res://scripts/interface_skin.gd").button(cycle)
		card.add_child(cycle)
		cycle.pressed.connect(func(): chapter.party.cycle(slot))
		cycle_buttons.append(cycle)
	cover.visible = false


func _label(at: Vector2, dimensions: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if size>=18: label.add_theme_font_override("font",preload("res://scripts/interface_skin.gd").heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("font_color",preload("res://scripts/interface_skin.gd").VERMILION if size>=23 else preload("res://scripts/interface_skin.gd").INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(label)
	return label


func _bake_images() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	for id in range(2):
		var rendered: Image = image_viewports[id].get_texture().get_image()
		if rendered == null or rendered.is_empty():
			continue
		images[id] = ImageTexture.create_from_image(rendered)
		faces[id].material_override.set_shader_parameter("albedo_texture", images[id])
		image_viewports[id].render_target_update_mode = SubViewport.UPDATE_DISABLED
	if inspected_id >= 0:
		image.texture = images[inspected_id]


func open(id: int) -> void:
	inspected_id = id
	image.texture = images[id]
	heading.text = Art.NAMES[id] + " · 字形放大观察"
	_show_lore(id==1)
	if id==1: lore.show_page(1)
	cover.visible = true
	close_button.release_focus()


func _show_lore(showing: bool) -> void:
	lore_open=showing
	lore.visible=showing
	_refresh_practice()
	comparison.visible=false
	lore_button.visible=inspected_id==0
	lore_button.text="回到传拓合读" if showing else "了解大小爨碑"
	chapter.puzzle_active=inspected_id==0 and not showing and not chapter.observed
	if showing:
		chapter.clue_progress.fill(0.0)
		chapter.action_progress=0
		lore.show_page(0 if inspected_id==0 else 1)


func _refresh_practice() -> void:
	var practice: bool=inspected_id==0 and not lore_open
	rubbing.visible=practice and not rubbing.completed and not chapter.observed
	puzzle_container.visible=practice and not rubbing.visible
	for words in [practice_title,practice_status,practice_note]:
		words.visible=puzzle_container.visible


func close() -> void:
	inspected_id = -1
	cover.visible = false
	rubbing.release_tools()
	for button in share_buttons:
		if button.button_pressed:
			Input.action_release("interact")
			Input.action_release("p2_interact")


func _process(_delta: float) -> void:
	if cover != null and cover.visible:
		practice_status.text=chapter._board_status.text
		hint.visible = chapter.get_node("../../..").story.current.is_empty()
		stage_guide.text = "小爨传拓取字 → 大爨核对来处 → 两碑印记合验，完成六字归位。" if lore_open else chapter.stage_instruction()
		hint.text = "先在练习刻板上覆纸、扑墨、揭纸。\n完成后，四人合读拓字。\nB 包裹 · H 提示 · Esc 返回" if rubbing.visible else "鼠标拿字 → Q 转向 → 点击凹槽放下\nB 包裹 · H 提示 · Esc 返回" if chapter.puzzle_active else "B 包裹 · H 提示 · Esc 返回"
		for slot in range(2):
			var present: bool = chapter.puzzle_active and not rubbing.visible and slot < chapter.party.human_players().size()
			share_buttons[slot].get_parent().visible = present
			if not present: continue
			var body: CharacterBody3D = chapter.party.human_players()[slot]
			var role: int = body.character_id
			var pending: Array[String] = []
			for id in chapter.party.roles_for_player(slot):
				if not chapter.clues[id]: pending.append(chapter.party.NAMES[id].get_slice("（",0))
			clue_headers[slot].text = "%dP %s · %s" % [slot+1,chapter.party.NAMES[role].get_slice("（",0),"已分享 ✓" if chapter.clues[role] else "等待分享"]
			var key: String = "E" if slot==0 else "P"
			share_buttons[slot].text = "本组已齐 · 合读间隔字" if pending.is_empty() else "此位已分享 · 请换人" if chapter.clues[role] else "按一下 %s 或点此分享" % key
			cycle_buttons[slot].text = "换人 · Tab" if slot==0 else "换人 · 右Shift"
			if preload("res://scripts/mobile_platform.gd").active():
				cycle_buttons[slot].text="换位同行"
				if not chapter.clues[role]: share_buttons[slot].text="点按分享此人的见闻"
		if preload("res://scripts/mobile_platform.gd").active():
			hint.text="按住侧边合拓，配合覆纸、扑墨、揭纸。" if rubbing.visible else "点字拿起 → 点旋转调向 → 点凹槽放下\n再次点空白可放回；右上可收起。"


func stone_at(at: Vector2) -> int:
	var camera: Camera3D = chapter.get_viewport().get_camera_3d()
	if camera == null:
		return -1
	var origin: Vector3 = camera.project_ray_origin(at)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(at) * 80, 4)
	var hit: Dictionary = chapter.get_world_3d().direct_space_state.intersect_ray(query)
	return int(hit.collider.get_meta("stele_id", -1)) if not hit.is_empty() else -1


func stone_screen_position(id: int) -> Vector2:
	var camera: Camera3D = chapter.get_viewport().get_camera_3d()
	# Use the exposed lower face for mouse checks; proximity cards occupy the top.
	return camera.unproject_position(faces[id].global_position - Vector3(0, 0.65, 0))


func puzzle_screen_position(point: Vector3) -> Vector2:
	return puzzle_container.get_global_transform_with_canvas() * puzzle_camera.unproject_position(point)


func puzzle_local_position(at: Vector2) -> Vector2:
	return puzzle_container.get_global_transform_with_canvas().affine_inverse() * at


func is_over_puzzle(at: Vector2) -> bool:
	return puzzle_container.visible and Rect2(Vector2.ZERO, puzzle_container.size).has_point(puzzle_local_position(at))
