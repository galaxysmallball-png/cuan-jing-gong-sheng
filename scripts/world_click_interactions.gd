extends CanvasLayer

const UiSkin = preload("res://scripts/interface_skin.gd")
const HISTORY_URL = "https://www.ynxc.gov.cn/html/2026/whxdfocus_0831/3037025.html"
var world: Node3D
var pickers: Dictionary = {}
var entries: Dictionary = {}
var overlay: Control
var history_text: Label
var opened: String = ""
var last_person: String = ""
var last_slot: int = 0


func setup(owner_world: Node3D) -> void:
	world = owner_world
	name = "WorldClickInteractions"
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	var nearby: Node = world.get_node("NearbyInteractions")
	for entry in nearby.entries:
		if entry.kind == "person": register(entry, Vector3(.8, 1.95, .7), Vector3(0, 1, 0))
	for plaque in get_tree().get_nodes_in_group("world_plaques"):
		if plaque.get_meta("title", "") != "杨旗田": continue
		var entry := {"id": "yangqitian_history", "anchor": plaque, "chapter": 1, "kind": "history", "index": -1, "title": "杨旗田 · 小爨来处", "offset": Vector3(0, .45, 0), "description": ""}
		nearby.entries.append(entry)
		register(entry, Vector3(1.95, .85, .35), Vector3.ZERO)
	_build_window()


func register(entry: Dictionary, dimensions: Vector3, at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 16
	body.collision_mask = 0
	body.position = at
	body.set_meta("world_click_id", entry.id)
	entry.anchor.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	pickers[entry.id] = body
	entries[entry.id] = entry


func _build_window() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(.025, .035, .04, .74)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(260, 130)
	panel.size = Vector2(760, 460)
	var style := StyleBoxTexture.new()
	style.texture = preload("res://assets/interface/task_flower_paper.png")
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	_label(panel, "杨旗田 · 小爨来处", Vector2(42, 31), Vector2(560, 42), 29, UiSkin.VERMILION)
	history_text = _label(panel, "杨旗田位于今云南曲靖市麒麟区越州镇。1778年（清乾隆四十三年），《爨宝子碑》在这里被发现。\n\n这通立于405年的东晋碑刻，兼有隶书与楷书的特征，保存了地方人物与官职等史料。它让我们从一方碑石，走近南中的历史与文字交流。\n\n从乡野发现、辨认到保护，碑的流传也离不开珍视它的人。本作由此展开护碑同行的故事；游戏人物和过溪情节为艺术创作。", Vector2(44, 92), Vector2(671, 285), 20, UiSkin.INK)
	var source := Button.new()
	source.text = "资料来源 · 云南文明探源"
	source.position = Vector2(44, 398)
	source.size = Vector2(290, 34)
	UiSkin.button(source)
	source.pressed.connect(func(): OS.shell_open(HISTORY_URL))
	panel.add_child(source)
	var close_button := Button.new()
	close_button.text = "收起 · Esc"
	close_button.position = Vector2(578, 398)
	close_button.size = Vector2(136, 34)
	UiSkin.button(close_button)
	close_button.pressed.connect(close)
	panel.add_child(close_button)
	overlay.visible = false


func _label(parent: Control, text: String, at: Vector2, dimensions: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("font_color", color)
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if size>=24: label.add_theme_font_override("font",UiSkin.heading_font())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.text = text
	label.size = dimensions
	return label


func open_history() -> void:
	if not _allowed(): return
	opened = "yangqitian_history"
	overlay.visible = true
	world.get_node("PartyUI").screen = 10
	world.get_node("PartyUI")._refresh()
	get_tree().paused = true
	world.sfx.play("paper")


func close() -> void:
	if not overlay.visible: return
	overlay.visible = false
	opened = ""
	world.get_node("PartyUI").screen = 2
	world.get_node("PartyUI")._refresh()
	get_tree().paused = false


func talk(id: String) -> void:
	if not _allowed() or not entries.has(id): return
	var entry: Dictionary = entries[id]
	if not world.get_node("NearbyInteractions")._available(entry): return
	var humans: Array = world.party.human_players()
	var slot: int = 0
	if humans.size() > 1:
		var first_distance := Vector2(humans[0].global_position.x - entry.anchor.global_position.x, humans[0].global_position.z - entry.anchor.global_position.z)
		var second_distance := Vector2(humans[1].global_position.x - entry.anchor.global_position.x, humans[1].global_position.z - entry.anchor.global_position.z)
		if second_distance.length_squared() < first_distance.length_squared(): slot = 1
	last_person = id
	last_slot = slot
	var nearby: Node = world.get_node("NearbyInteractions")
	nearby.focus[slot] = id
	nearby.pinned[slot] = id
	nearby.reading[slot] = id
	nearby.pages[slot] = 0
	world.story.queue.clear()
	var lines: Array[String] = nearby._raw_lines(entry, slot)
	world.story.speak(entry.title, lines[0], 5, true)
	var role: int = humans[slot].character_id
	var replies: Array[String] = ["先生认字，乡亲识得山路与手艺。请再讲些，在下愿闻。", "石与木各有性子，多亏乡亲相助，咱们才护得稳。", "我认山路，诸位识人情；走到一处，路才走得长。", "乡音虽异，好意却相通。有话慢慢说，咱们一道商量。"]
	world.story.speak(world.party.NAMES[role], replies[role], 5)
	if lines.size() > 1: world.story.speak(entry.title, lines[1], 5)
	if entry.index >= 2: world.courtyard.landscape.resident_work(entry.index - 2)
	world.sfx.play("talk")


func _allowed() -> bool:
	return world.party.started and not get_tree().paused and world.get_node("PartyUI").screen == 2 and world.cooperation.inspected_id < 0 and not world.courtyard.record_open


func _process(_delta: float) -> void:
	if world == null: return
	for id in pickers:
		pickers[id].collision_layer = 16 if world.get_node("NearbyInteractions")._available(entries[id]) else 0


func _input(event: InputEvent) -> void:
	if overlay.visible and event is InputEventKey:
		if event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE: close()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _allowed() or not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: return
	if world.get_node("PartyUI").blocks_world_click(event.position): return
	var attached_id: String=world.folk.attached_at(event.position)
	if not attached_id.is_empty():
		world.folk.open_item(attached_id)
		if world.folk.overlay.visible: get_viewport().set_input_as_handled(); return
	var origin: Vector3 = world.camera.project_ray_origin(event.position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + world.camera.project_ray_normal(event.position) * 100, 16)
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return
	var id: String = hit.collider.get_meta("world_click_id", "")
	if id == "yangqitian_history": open_history()
	elif entries.has(id) and entries[id].kind=="keepsake": world.keepsakes.click_collect(entries[id].index)
	elif entries.has(id):
		# An attached tool shares its owner's silhouette. Let the tool's focused
		# hitbox open its introduction before the broad NPC body starts a dialogue.
		var tool_query:=PhysicsRayQueryParameters3D.create(origin,origin+world.camera.project_ray_normal(event.position)*100,8)
		var tool_hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(tool_query)
		if not tool_hit.is_empty() and tool_hit.collider.has_meta("folk_id") and origin.distance_to(tool_hit.position)<=origin.distance_to(hit.position)+.18:
			world.folk.open_item(tool_hit.collider.get_meta("folk_id"))
			if world.folk.overlay.visible:
				get_viewport().set_input_as_handled()
				return
		talk(id)
	get_viewport().set_input_as_handled()
