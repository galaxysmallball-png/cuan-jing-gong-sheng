extends "res://scripts/party_chapter.gd"

signal observation_completed
@export var observation_seconds: float = 1.6
const GLYPHS: Array[String] = ["晋", "故", "振", "威", "建", "宁"]
const CUAN_FONT: FontFile = preload("res://assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf")
const Inspector = preload("res://scripts/stele_inspector.gd")
const TRAY_ORDER: Array[int] = [3, 0, 5, 2, 1, 4]
const INITIAL_TURNS: Array[int] = [0, 2, 1, 2, 0, 3]
const CLUES: Array[String] = [
	"邓书年：我认出第1、3、5字，依次是「晋、振、建」。请同伴补上间字。",
	"石阿朵：六个凹位排作一列，先从最上方起。",
	"老箐：有几片倒置了。看卡角记号，将箭头转向上方。",
	"杨三娘：第2、4、6字依次是「故、威、宁」。和邓先生的三字交错合读。"
]
var step: int = 0
var observed: bool = false
var gate_open: bool = false
var opening: bool = false
var puzzle_active: bool = false
var inspected_id: int = -1
var inspector: CanvasLayer
var clues: Array[bool] = [false, false, false, false]
var comparison_complete: bool = false
var large_stele_checked: bool=false
var clue_progress: Array[float] = [0.0, 0.0, 0.0, 0.0]
var slots: Array[int] = [-1, -1, -1, -1, -1, -1]
var turns: Array[int] = []
var selected_tile: int = -1
var cursor_tile: int = 0
var cursor_slot: int = 0
var feedback: String = ""
var _gate_tween: Tween
var _beam: SpotLight3D
var _board: Node3D
var _tiles: Array[Node3D] = []
var _slot_nodes: Array[MeshInstance3D] = []
var _slot_labels: Array[Label3D] = []
var _arrow_labels: Array[Label3D] = []
var _board_status: Label3D
var _clue_role: int = -1
var _keyboard_selection: bool = false
var _mouse_down_tile: int = -1
var _mouse_down_slot: int = -1
var _feedback_seconds: float = 0.0
var _ending_seconds: float = 0.0


func _ready() -> void:
	$Partner.visible = false
	_beam = $Partner/RightArm/Lantern/Beam
	_beam.reparent(self)
	_build_board()
	inspector = Inspector.new()
	add_child(inspector)
	inspector.setup(self, _board, CUAN_FONT)
	reset_lesson()


func _build_board() -> void:
	_board = Node3D.new()
	_board.name = "MemoryPuzzle"
	add_child(_board)
	# Transparent viewport lets the user's floral paper continue behind the work.
	var title: Label3D = Props.label(_board, Vector3(13.1, 5.12, 0.52), "雾中拾字 · 四人合看")
	title.font_size = preload("res://scripts/interface_skin.gd").text_size(45)
	title.modulate=Color(.49,.22,.15)
	title.outline_size=0
	title.visible=false
	var note: Label3D = Props.label(_board, Vector3(13.1, 1.67, 0.52), "梁培生小爨字形 · 六字节选练习 · 非原碑复原")
	note.font_size = preload("res://scripts/interface_skin.gd").text_size(24)
	note.modulate=Color(.26,.29,.24)
	note.outline_size=0
	note.visible=false
	_board_status = Props.label(_board, Vector3(12.0, 2.1, 0.54), "")
	_board_status.font_size = preload("res://scripts/interface_skin.gd").text_size(29)
	_board_status.modulate=Color(.30,.25,.18)
	_board_status.outline_size=0
	_board_status.visible=false
	for index in range(6):
		var slot: MeshInstance3D = Props.box(_board, _slot_position(index), Vector3(0.85, 0.48, 0.08), Color(.66,.56,.39))
		slot.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		_slot_nodes.append(slot)
		var number: Label3D = Props.label(_board, _slot_position(index) + Vector3(0.66, 0, 0.1), "·")
		number.font_size = preload("res://scripts/interface_skin.gd").text_size(26)
		number.modulate=Color(.30,.25,.18)
		number.outline_size=0
		_slot_labels.append(number)
	for id in range(6):
		var tile := Node3D.new()
		_board.add_child(tile)
		_tiles.append(tile)
		var tile_mesh: MeshInstance3D=Props.box(tile, Vector3.ZERO, Vector3(0.69, 0.69, 0.1), Color(.90,.82,.63))
		tile_mesh.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		var glyph: Label3D = Props.label(tile, Vector3(0, 0, 0.08), GLYPHS[id])
		glyph.name = "CuanGlyph"
		glyph.font = CUAN_FONT
		glyph.font_size = preload("res://scripts/interface_skin.gd").text_size(128)
		glyph.outline_size = 0
		glyph.modulate = Color(0.10, 0.13, 0.15)
		var arrow: Label3D = Props.label(tile, Vector3(0.23, 0.23, 0.1), "↑")
		arrow.font_size = preload("res://scripts/interface_skin.gd").text_size(25)
		arrow.modulate = Color(0.27, 0.18, 0.08)
		_arrow_labels.append(arrow)
	var light := OmniLight3D.new()
	light.position = Vector3(13, 4.3, 3.5)
	light.omni_range = 7
	light.light_energy = 1.5
	light.light_color = Color(0.75, 0.85, 1.0)
	_board.add_child(light)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart_lesson"):
		reset_lesson()
		return
	if not party.started:
		return
	_ending_seconds = maxf(0, _ending_seconds - delta)
	_feedback_seconds = maxf(0, _feedback_seconds - delta)
	_beam.visible = not gate_open
	var bearer: CharacterBody3D = party.role_body(3)
	_beam.global_position = bearer.global_position + Vector3(0.1, 0.3, 0.05)
	_beam.look_at($SmallPanel.global_position, Vector3.UP)
	if Input.is_action_just_pressed("restart"):
		close_puzzle()
		return
	if inspector.lore_open or not puzzle_active or not inspector.rubbing.completed:
		return
	action_progress = 0.0
	for role in range(4):
		var held: bool = false
		for body in party.human_players():
			if body.character_id == role and Input.is_action_just_pressed(body.action("interact")):
				held = true
		clue_progress[role]=0
		if held and not clues[role]:
			clues[role] = true
			step += 1
			clue_progress[role] = 0.0
			action_progress = 0.0
			_set_feedback(CLUES[role] + "（线索已放入包裹）", 8)
			var root_world: Node = get_node("../../..")
			if is_instance_valid(root_world.story): root_world.story.speak(party.NAMES[role], CLUES[role].get_slice("：", 1), 5, true)
			_update_board()
			_check_solution()


func open_puzzle() -> void:
	open_inspection(0)


func open_inspection(id: int) -> void:
	if id < 0 or id > 1 or not party.started or not player.controls_enabled:
		return
	get_node("../../..").sfx.play("stone")
	inspected_id = id
	puzzle_active = id == 0 and not observed
	party.set_interaction_lock(true)
	_clue_role = party.active_id
	_set_feedback("先合作覆纸、扑墨、揭纸，取下练习拓片后再交流四人的见闻。" if not inspector.rubbing.completed else "各按一次操作键分享，再换到自己的另一位同行；把两份间隔字与方向线索合起来。" if party.local_coop else "按一次 E 分享当前角色的线索，再按 Tab 换下一位同行。", 5)
	inspector.open(id)
	_update_board()


func close_puzzle() -> void:
	puzzle_active = false
	inspected_id = -1
	party.set_interaction_lock(false)
	action_progress = 0
	clue_progress.fill(0.0)
	_mouse_down_tile = -1
	_mouse_down_slot = -1
	selected_tile = -1
	if inspector != null:
		inspector.close()
	_update_board()


func record_comparison() -> void:
	if inspected_id!=1:
		_set_feedback("请到场景右侧的大爨碑前核对，才能收下对照印记。",6)
		return
	large_stele_checked=true
	if comparison_complete: return
	comparison_complete=true
	get_node("../../..").sfx.play("paper")
	_set_feedback("大小爨碑对照印记已合，线索已放入包裹。回小爨碑合读六字，校验所护之碑。",8)
	_update_board()
	_check_solution()


func _process(_delta: float) -> void:
	if not puzzle_active or selected_tile < 0:
		return
	if _keyboard_selection:
		_tiles[selected_tile].position = _slot_position(cursor_slot) + Vector3(-1.05, 0, 0.35)
	else:
		var camera: Camera3D = inspector.puzzle_camera
		if camera == null:
			return
		var mouse: Vector2 = inspector.puzzle_local_position(get_viewport().get_mouse_position())
		var plane := Plane(Vector3(0, 0, 1), 1.15)
		var hit: Variant = plane.intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
		if hit != null:
			_tiles[selected_tile].global_position = Vector3(clampf(hit.x, 10.4, 15.8), clampf(hit.y, 1.95, 4.9), 1.15)


func _input(event: InputEvent) -> void:
	if get_tree().paused or not party.started or not player.controls_enabled:
		return
	if inspected_id < 0:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if get_node("../../../PartyUI").blocks_world_click(event.position): return
			var nearby_ui: Node = get_node("../../../").get_node_or_null("NearbyInteractions")
			if nearby_ui != null and nearby_ui.blocks_world_click(event.position): return
			var id: int = inspector.stone_at(event.position)
			if id >= 0:
				open_inspection(id)
				get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo \
		and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE):
		close_puzzle()
		get_viewport().set_input_as_handled()
		return
	if not puzzle_active:
		return
	if not inspector.rubbing.completed: return
	if event is InputEventMouseButton:
		if not inspector.is_over_puzzle(event.position):
			return
		var puzzle_position: Vector2 = inspector.puzzle_local_position(event.position)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			rotate_selected()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var slot: int = _pick_slot(puzzle_position)
			if event.pressed:
				if selected_tile >= 0:
					if slot >= 0: place_selected(slot)
					else: return_selected()
					_mouse_down_tile = -1
					_mouse_down_slot = -1
				else:
					var tile: int = _pick_tile(puzzle_position)
					if tile >= 0:
						select_tile(tile)
						_keyboard_selection = false
						_mouse_down_tile = tile
						_mouse_down_slot = slot
			elif _mouse_down_tile >= 0:
				if slot >= 0 and slot != _mouse_down_slot and selected_tile >= 0:
					place_selected(slot)
				_mouse_down_tile = -1
				_mouse_down_slot = -1
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		# The arrow keys remain 2P's controls, including ↓ for their clue.
		# The shared board uses I/J/K/L so a clue cannot also move a tile.
		if party.local_coop and key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			return
		if key in [KEY_J, KEY_L, KEY_I, KEY_K]:
			key = {KEY_J: KEY_LEFT, KEY_L: KEY_RIGHT, KEY_I: KEY_UP, KEY_K: KEY_DOWN}[key]
		match key:
			KEY_ESCAPE:
				close_puzzle()
			KEY_Q:
				rotate_selected()
			KEY_BACKSPACE:
				return_selected()
			KEY_LEFT, KEY_RIGHT:
				cursor_tile = posmod(cursor_tile + (1 if key == KEY_RIGHT else -1), 6)
				select_tile(cursor_tile)
				_keyboard_selection = true
			KEY_UP, KEY_DOWN:
				cursor_slot = posmod(cursor_slot + (1 if key == KEY_DOWN else -1), 6)
				_keyboard_selection = true
				_update_board()
			KEY_ENTER, KEY_KP_ENTER:
				if selected_tile < 0:
					select_tile(cursor_tile)
					_keyboard_selection = true
				else:
					place_selected(cursor_slot)
			_:
				return
		get_viewport().set_input_as_handled()


func select_tile(id: int) -> void:
	if not puzzle_active or not inspector.rubbing.completed or id < 0 or id >= 6:
		return
	get_node("../../..").sfx.play("paper")
	for index in range(6):
		if slots[index] == id:
			slots[index] = -1
	selected_tile = id
	cursor_tile = id
	_set_feedback("已拿起「%s」：Q / 右键转向，点凹槽放入；再点空白处可放回。" % GLYPHS[id], 5)
	_update_board()


func rotate_selected() -> void:
	if not puzzle_active or selected_tile < 0:
		return
	get_node("../../..").sfx.play("paper")
	turns[selected_tile] = (turns[selected_tile] + 1) % 4
	_set_feedback("「%s」箭头已朝上，可放入凹槽。" % GLYPHS[selected_tile] if turns[selected_tile] == 0 else "继续按 Q / 右键，直到「%s」的箭头朝上。" % GLYPHS[selected_tile], 4)
	_update_board()


func return_selected() -> void:
	if not puzzle_active:
		return
	selected_tile = -1
	_keyboard_selection=false
	_mouse_down_tile=-1
	_mouse_down_slot=-1
	_set_feedback("字卡已放回，可重新拿起。",3)
	_update_board()


func place_selected(index: int) -> void:
	if not puzzle_active or selected_tile < 0 or index < 0 or index >= 6:
		return
	# Occupied positions return the previous card to the tray; no card is lost.
	slots[index] = selected_tile
	get_node("../../..").sfx.play("stone")
	selected_tile = -1
	cursor_slot = index
	_update_board()
	if not _check_solution() and -1 not in slots:
		get_node("../../..").sfx.play("wrong")
		_set_feedback(solution_feedback(), 6)


func _check_solution() -> bool:
	if not comparison_complete or not large_stele_checked:
		if slots.count(-1)==0: _set_feedback("六字已放齐，还缺大爨碑的对照印记。先收好字卡，到右侧大爨碑核对年代与碑主。",8)
		return false
	if step != 4 or observed or not inspector.rubbing.completed:
		return false
	for index in range(6):
		if slots[index] != index or turns[index] != 0:
			return false
	observed = true
	close_puzzle()
	observation_completed.emit()
	_ending_seconds = 7
	_open_gate()
	return true


func _slot_position(index: int) -> Vector3:
	return Vector3(14.7, 4.7 - index * 0.51, 0.58)


func _tray_position(id: int) -> Vector3:
	var index: int = TRAY_ORDER.find(id)
	return Vector3(11.0 + (index % 3) * 1.05, 4.25 - floori(index / 3.0) * 1.05, 0.72)


func _update_board() -> void:
	if _board_status == null:
		return
	var placed: int = 0
	for index in range(6):
		var color := Color(.66,.56,.39)
		if slots[index] >= 0:
			placed += 1
			color = Color(.73,.63,.45)
		elif puzzle_active and cursor_slot == index:
			color = Color(.81,.69,.47)
		_slot_nodes[index].material_override.albedo_color = color
		_slot_labels[index].text = str(index+1)
		_slot_labels[index].modulate=Color(.30,.25,.18)
	for id in range(6):
		var index: int = slots.find(id)
		_tiles[id].position = _slot_position(index) + Vector3(0, 0, 0.13) if index >= 0 else _tray_position(id)
		_tiles[id].scale = Vector3.ONE * (0.61 if index >= 0 else 1.0)
		_tiles[id].rotation.z = turns[id] * PI / 2.0
		var mesh: MeshInstance3D = _tiles[id].get_child(0)
		mesh.material_override.albedo_color = Color(.98,.82,.45) if selected_tile == id else Color(.90,.82,.63)
		_arrow_labels[id].visible = true
	_board_status.text = "线索 %d / 4 · 归位 %d / 6" % [step, placed]
	if clues[0]:
		_board_status.text += "\n1、3、5：晋、振、建"
	if clues[3]:
		_board_status.text += "\n2、4、6：故、威、宁"


func _pick_slot(at: Vector2) -> int:
	return _nearest_screen(at, _slot_nodes, 0.54)


func _pick_tile(at: Vector2) -> int:
	return _nearest_screen(at, _tiles, 0.42, selected_tile)


func _nearest_screen(at: Vector2, nodes: Array, radius: float, excluded: int = -1) -> int:
	var camera: Camera3D = inspector.puzzle_camera
	if camera == null:
		return -1
	var best: int = -1
	var best_distance: float = INF
	for index in range(nodes.size()):
		if index == excluded:
			continue
		var point: Vector3 = nodes[index].global_position
		if camera.is_position_behind(point):
			continue
		var screen: Vector2 = camera.unproject_position(point)
		var edge: Vector2 = camera.unproject_position(point + Vector3(radius, 0, 0))
		var distance: float = at.distance_to(screen)
		if distance < screen.distance_to(edge) and distance < best_distance:
			best = index
			best_distance = distance
	return best


func _set_feedback(message: String, seconds: float) -> void:
	feedback = message
	_feedback_seconds = seconds


func _open_gate() -> void:
	opening = true
	_gate_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_gate_tween.tween_property($Gate, "position:y", 8.0, 1.8)
	_gate_tween.finished.connect(func(): gate_open = true; opening = false)


func get_hint() -> String:
	if _ending_seconds > 0:
		return "邓书年：单凭我，未能认全。多谢诸位补齐线索。\n杨三娘：那便一同护碑入城。待门开启，向右出发。"
	if opening:
		return "四人的线索与六张字卡都已补全，门正在升起。"
	if inspected_id == 1:
		return "大爨碑 · 阅读二爨介绍，完成三步合读。\n取得第一关必需的对照印记；之后回小爨碑合读，确认所护之碑。"
	if gate_open:
		return "观察档案已解锁，四人向右前往断溪古道。\nF2 两碑对照 · T 从头重玩"
	if not puzzle_active:
		return "小爨碑传拓、四人合读六字；大爨碑核对年代与碑主。\n两处见闻都收齐，院门才会打开。"
	if not inspector.rubbing.completed: return stage_instruction()
	var role: int = party.active_id
	var clue: String = CLUES[role] if clues[role] else "%s：按一下 E 分享所见，再与其他线索合读。" % party.NAMES[role]
	if _feedback_seconds > 0:
		clue = feedback
	if party.local_coop:
		return stage_instruction() + "\n1P：按 E 分享 / Tab 换人；2P：按 P 分享 / 右 Shift 换人。\n将两份间隔字合读：鼠标拿字 → Q 转正 → 点击 1—6 格。B 回看见闻。"
	return clue + "\nB 翻看包裹 · 鼠标拿放 · Q / 右键旋转 · ←→ 选字 / ↑↓ 选位 / Enter 放置 · Esc 离开"


func placed_count() -> int:
	return 6-slots.count(-1)


func pending_names() -> String:
	var pending: Array[String] = []
	for role in range(4):
		if not clues[role]: pending.append(party.NAMES[role].get_slice("（",0))
	return "、".join(pending)


func stage_instruction() -> String:
	if gate_open or opening: return "⑤ 碑文已合 · 等院门打开，与同伴向右出院。"
	if not puzzle_active:
		return "① 大爨对照已得 · 点击小爨碑传拓合读。" if large_stele_checked else "① 两碑合读 · 小爨传拓取字，大爨核对年代与碑主，两处都要完成。"
	if not inspector.rubbing.completed:
		return ["② 合作传拓 · 两人调整纸边，再分别压纸。","② 合作传拓 · 选区轻扑，绿色区内按键；各拓一列。","② 合作传拓 · 两边同时揭纸，松手会回落。","② 合作传拓 · 取下练习拓片，再交流四人见闻。"][inspector.rubbing.phase]
	if clues.count(true)<4: return "③ 四人交流 · 已分享 %d/4 · 还差：%s" % [clues.count(true),pending_names()]
	if not large_stele_checked and clues.count(true)==4: return "④ 缺大爨对照印记 · 字卡会保留，收起后点击右侧大爨碑，核对年代与碑主。"
	if slots.count(-1)==0: return solution_feedback()
	if selected_tile>=0: return "④ 已拿起「%s」 · Q / 右键转正 → 点凹位；邓书年给1/3/5，杨三娘补2/4/6。" % GLYPHS[selected_tile]
	return "④ 六字归位 %d/6 · 合读两份间隔字，再按编号放下；B 可回看各人的线索。" % placed_count()


func solution_feedback() -> String:
	if not large_stele_checked: return "请先到右侧大爨碑完成对照校验，确认大小爨碑与所护之碑；当前字卡保留。"
	if clues.count(true)<4: return "六字已放齐，还需 %s 分享见闻；按一下操作键，再换人补齐。" % pending_names()
	for index in range(6):
		if slots[index] < 0: return "还有空位。拿起字卡，放入右侧编号凹槽。"
		if slots[index] != index: return "第 %d 格次序未合：取回字卡，对照邓书年与杨三娘的两份间隔字，交错重排。" % (index+1)
		if turns[slots[index]] != 0: return "第 %d 格方向未正：拿起后按 Q / 右键，转到箭头朝上，再放回。" % (index+1)
	return "四人见闻与六字都已合上，院门将开启。"


func reset_lesson() -> void:
	if _gate_tween != null and _gate_tween.is_valid():
		_gate_tween.kill()
	step = 0
	observed = false
	gate_open = false
	opening = false
	puzzle_active = false
	inspected_id = -1
	if inspector != null:
		inspector.close()
	party.set_interaction_lock(false)
	clues.assign([false, false, false, false])
	comparison_complete=false
	large_stele_checked=false
	if inspector!=null:
		inspector.lore.reset_lore()
		inspector.rubbing.reset_practice()
	clue_progress.fill(0.0)
	slots.assign([-1, -1, -1, -1, -1, -1])
	turns.assign(INITIAL_TURNS)
	selected_tile = -1
	cursor_tile = 0
	cursor_slot = 0
	_clue_role = -1
	_mouse_down_tile = -1
	_mouse_down_slot = -1
	_keyboard_selection = false
	action_progress = 0.0
	_feedback_seconds = 0
	_ending_seconds = 0
	$Gate.position = Vector3(19, 2.5, 0)
	_beam.visible = false
	_update_board()
