extends "res://scripts/environment_art.gd"

const CharacterNames = preload("res://scripts/character_names.gd")
const Story = preload("res://scripts/culture_content.gd")
const UiStyle = preload("res://scripts/interface_skin.gd")
const ScrollMount = preload("res://scripts/scroll_mount.gd")
const SCROLL_IMAGES: Array[Texture2D] = [preload("res://assets/story/scroll_bridge.png"), preload("res://assets/story/scroll_symbols.png"), preload("res://assets/story/scroll_generations.png"), preload("res://assets/story/scroll_lights_single_taiwan_20261022.png")]
# Kept in step with lantern_garden.gd: the stele, its pedestal, guard frame and
# floor marker all share the hall's centre line so the courtyard reads as one axis.
const SHRINE_AXIS_X: float = 10.0
var record_art: TextureRect
var record_cover: TextureRect
var record_cover_open: bool = false
var world_scroll_paper: MeshInstance3D
var chronicle_label: Label3D
var record_body: Panel
var record_signature: Label
const SCROLL_COVER = preload("res://assets/interface/scroll_cover.png")
var chapter: Node3D
var stone: ShaderMaterial
var plaster: ShaderMaterial
var wood: ShaderMaterial
var roof: Material
var bronze: Material
var paper: Material
var font: Font
var objects: Array[Node3D] = []
var targets: Array[Label3D] = []
var flames: Array[MeshInstance3D] = []
var carried: Array[Node3D] = []
var supplies: Array[Node3D] = []
var carry_labels: Array[Label3D] = []
var ground_markers: Array[MeshInstance3D] = []
var stele_plinth: MeshInstance3D
var placement_marker: MeshInstance3D
var task_cards: Array[Panel] = []
var task_labels: Array[Label] = []
var task_headers: Array[Label] = []
var task_bars: Array[ProgressBar] = []
var supply_label: Label3D
var placement_label: Label3D
var inscription: MeshInstance3D
var scroll: Node3D
var scroll_tween: Tween
var canvas: CanvasLayer
var dialogue: Panel
var dialogue_text: Label
var dialogue_left: float = 0
var record: Control
var record_title: Label
var record_text: Label
var record_number: Label
var next_button: Button
var previous_button: Button
var record_page: int = 0
var record_lines: Array[String] = []
var resident_work_left: Array[float] = [0, 0]
var collection_reward: Node


func setup(owner_chapter: Node3D) -> void:
	chapter = owner_chapter
	name = "LanternGarden"
	rng.seed = 405458
	font = preload("res://scripts/interface_skin.gd").body_font()

	stone = _stone(Color(0.34, 0.36, 0.30), 0.17)
	plaster = _stone(Color(0.57, 0.51, 0.37), 0.06)
	wood = _surface(Color(0.24, 0.14, 0.075), 2)
	roof = _flat(Color(0.14, 0.20, 0.20))
	bronze = _flat(Color(0.45, 0.29, 0.10))
	paper = _flat(Color(0.81, 0.71, 0.49))
	_build_ground()
	_build_architecture()
	var right_return := preload("res://scripts/courtyard_right_return.gd").new()
	add_child(right_return)
	right_return.setup(stone, wood)
	var shrine_detail: Node3D=preload("res://scripts/shrine_court_detail.gd").new()
	add_child(shrine_detail)
	shrine_detail.setup(self)
	_build_destinations()
	_build_table()
	_build_scroll()
	_build_ui()
	chapter.warm_light.position = Vector3(9.3, 4.0, 0.8)
	chapter.warm_light.omni_range = 16
	chapter.warm_light.light_color = Color(1, 0.73, 0.39)
	var fill := OmniLight3D.new()
	fill.position = Vector3(13, 5, -0.3)
	fill.light_color = Color(0.47, 0.62, 0.71)
	fill.light_energy = 0.75
	fill.omni_range = 18
	add_child(fill)
	var front_fill := OmniLight3D.new()
	front_fill.position = Vector3(10, 2.4, 6)
	front_fill.light_color = Color(0.57, 0.65, 0.65)
	front_fill.light_energy = 0.45
	front_fill.omni_range = 15
	add_child(front_fill)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.94, 1.95)
	inscription = MeshInstance3D.new()
	inscription.mesh = mesh
	inscription.position = Vector3(0, 0.03, chapter._tablet.mesh.get_aabb().size.z / 2 + .006)
	var face := ShaderMaterial.new()
	face.shader = preload("res://shaders/aged_inscription.gdshader")
	preload("res://scripts/historical_steles.gd").dress(chapter._tablet, 0)
	# dress() repaints the stele with the same courtyard-stone shader as the back
	# wall, at nearly the same colour. Lifting the face and cutting the moss keeps
	# the two surfaces from merging into one flat plane behind the incense table.
	var stele_face: ShaderMaterial = chapter._tablet.material_override
	stele_face.set_shader_parameter("base_color", Color(.55, .53, .46))
	stele_face.set_shader_parameter("moss_amount", .05)
	inscription.material_override = face
	chapter._tablet.add_child(inscription)
	collection_reward=preload("res://scripts/stele_collection_reward.gd").new()
	add_child(collection_reward)
	collection_reward.setup(chapter)
	# Existing modern Cuan illustration, shared with the inspected model in act one.
	placement_label = _text(self, Vector3(SHRINE_AXIS_X, 0.18, 0.6), "石阿朵 + 同伴 · 合力立碑", 25)
	placement_marker = _ground_marker(SHRINE_AXIS_X)
	for index in range(3):
		var lamp: Node3D = _oil(Vector3.ZERO, true)
		lamp.visible = false
		carry_labels.append(_text(lamp, Vector3(0, 0.48, 0), ["院门灯", "石阶灯", "碑亭灯"][index], 22))
		carried.append(lamp)


func _stone(color: Color, moss_amount: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/courtyard_stone.gdshader")
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("moss_amount", moss_amount)
	return material


func _text(parent: Node3D, at: Vector3, words: String, font_size: int = 26) -> Label3D:
	var label := Label3D.new()
	label.position = at
	label.font = UiStyle.heading_font()
	label.font_size = UiStyle.text_size(font_size)
	label.pixel_size = 0.007
	label.text = CharacterNames.annotate(words)
	label.outline_size = 5
	label.modulate = Color(1, 0.85, 0.53)
	parent.add_child(label)
	return label


func _build_ground() -> void:
	var bank := preload("res://scripts/layered_bank.gd").new()
	add_child(bank)
	bank.setup(-.25,28.0,-.73,-3.65,3.69,Color(.27,.31,.27),1)
	_box(self, Vector3(10, -0.3, 0), Vector3(20.5, 0.58, 6.8), stone)
	for row in range(7):
		for col in range(23):
			var x: float = 0.1 + col * 0.89 + (0.22 if row % 2 == 0 else 0)
			var tile: MeshInstance3D = _box(self, Vector3(x, -0.025 + rng.randf_range(-0.006, 0.006), -2.7 + row * 0.78), Vector3(0.83, 0.045, 0.71), _flat_shade(Color(0.28, 0.31, 0.26), rng.randf_range(0.88, 1.16)))
			tile.rotation.y = rng.randf_range(-0.025, 0.025)
	for index in range(28):
		_box(self, Vector3(0.1 + index * 0.74, 0.08, 2.85), Vector3(0.70, 0.2, 0.26), stone)
	for row in range(3):
		for col in range(26):
			_box(self, Vector3(-0.1 + col * 0.81 + row % 2 * 0.20, -0.22 - row * 0.22, 3.38), Vector3(0.78, 0.20, 0.55), _flat_shade(Color(0.17, 0.20, 0.16), rng.randf_range(0.8, 1.05)))
	# Steps sit behind the continuous walking lane, avoiding invisible jump barriers.
	# On the tested stelae axis the terrace reads as three clear risers; the yard
	# slab under it is unchanged, so the walking lane and floor height stay put.
	for index in range(3):
		_box(self, Vector3(9.8, 0.055 + index * 0.09, -1.1 - index * 0.45), Vector3(5.9, 0.11 + index * 0.18, 0.50), stone)
	_box(self, Vector3(10, 0.28, -2.55), Vector3(5.8, 0.46, 2.1), stone)
	for index in range(18):
		var at := Vector3(rng.randf_range(0.4, 19.5), 0, 3.02)
		var leaf: Material = _flat(Color(0.15, 0.21, 0.08))
		for stem in range(4):
			_rod(self, at, at + Vector3(rng.randf_range(-0.18, 0.18), rng.randf_range(0.10, 0.28), 0.04), 0.014, leaf)
		if index % 3 == 0: _rock(self, at, Vector3(0.35, 0.18, 0.3), stone)


func _post(x: float, z: float, height: float) -> void:
	_box(self, Vector3(x, 0.18, z), Vector3(0.42, 0.36, 0.42), stone)
	_rod(self, Vector3(x, 0.32, z), Vector3(x, height, z), 0.11, wood)
	_box(self, Vector3(x, height - 0.1, z), Vector3(0.44, 0.16, 0.38), wood)


func _tiled_roof(center: float, width: float, y: float, z: float, depth: float) -> void:
	var tiled := preload("res://scripts/curved_tile_roof.gd").new()
	add_child(tiled)
	tiled.position=Vector3(center,y,z)
	tiled.setup(width,depth)


func _build_architecture() -> void:
	_box(self, Vector3(10, 1.8, -4.1), Vector3(20.5, 3.6, 0.4), plaster)
	for index in range(28):
		_box(self, Vector3(index * 0.75, 0.25, -3.84), Vector3(0.71, 0.49, 0.16), stone)
	_tiled_roof(10, 21, 3.8, -4.08, 0.9)
	# Central stele pavilion, with an open front and a timber protection frame.
	for x in [7.1, 12.9]:
		for z in [-3.4, -1.65]: _post(x, z, 4.0)
	for z in [-3.4, -1.65]:
		_rod(self, Vector3(6.9, 3.85, z), Vector3(13.1, 3.85, z), 0.14, wood)
	for x in [7.1, 12.9]:
		_rod(self, Vector3(x, 3.85, -3.6), Vector3(x, 3.85, -1.4), 0.12, wood)
	_tiled_roof(10, 7.0, 4.63, -2.65, 3.1)
	preload("res://scripts/world_signs.gd").plaque(self, Vector3(10, 3.60, -.78), "灯火共庭", Vector2(3.6, .84))
	stele_plinth=_box(self, Vector3(SHRINE_AXIS_X, 0.42, -2.35), Vector3(1.75, 0.46, 0.95), stone)
	stele_plinth.name="SteleSocketPlinth"
	for x in [SHRINE_AXIS_X - 0.95, SHRINE_AXIS_X + 0.95]:
		_rod(self, Vector3(x, 0.55, -2.1), Vector3(x, 3.45, -2.1), 0.045, bronze)
	_rod(self, Vector3(SHRINE_AXIS_X - 0.95, 3.45, -2.1), Vector3(SHRINE_AXIS_X + 0.95, 3.45, -2.1), 0.045, bronze)
	# The ribbon is tied to the side of this timber guard, away from the stone.
	for y in [0.75, 1.25, 2.28]:
		_rod(self, Vector3(SHRINE_AXIS_X + 1.65, y, -2), Vector3(SHRINE_AXIS_X + 3.75, y, -2), 0.035, wood)
	_rod(self, Vector3(SHRINE_AXIS_X + 1.65, 0.45, -2), Vector3(SHRINE_AXIS_X + 1.65, 2.3, -2), 0.042, wood)
	# Left display wall and right open gallery have different silhouettes.
	for x in [4.6, 15.2, 19.3]: _post(x, -2.3, 3.2)
	_tiled_roof(5.7, 2.8, 3.65, -3.1, 2.2)
	_tiled_roof(17.2, 5.0, 3.75, -3.0, 2.4)
	_rod(self, Vector3(14.9, 3.13, -2.3), Vector3(19.6, 3.13, -2.3), 0.12, wood)
	for x in [5.0, 14.5, 18.9]:
		_box(self, Vector3(x, 0.5, -3), Vector3(1.9, 0.15, 0.56), wood)
		for offset in [-0.65, 0.65]: _box(self, Vector3(x + offset, 0.25, -3), Vector3(0.13, 0.5, 0.46), wood)
	# Round lattice window at the end of the gallery.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.69
	torus.outer_radius = 0.79
	ring.mesh = torus
	ring.position = Vector3(18.4, 2.1, -3.82)
	ring.rotation.x = PI / 2
	ring.material_override = wood
	add_child(ring)
	_box(self, Vector3(18.4, 2.1, -3.79), Vector3(1.32, 1.32, 0.025), _flat(Color(0.10, 0.19, 0.20)))
	var lattice: Array = []
	for offset in [-0.42, 0.0, 0.42]:
		var extent: float = sqrt(0.66 * 0.66 - offset * offset)
		lattice.append([Vector3(18.4 + offset, 2.1 - extent, -3.75), Vector3(18.4 + offset, 2.1 + extent, -3.75), 0.023])
		lattice.append([Vector3(18.4 - extent, 2.1 + offset, -3.75), Vector3(18.4 + extent, 2.1 + offset, -3.75), 0.023])
	_rods_merged(self, wood, lattice).name = "LatticeWindowBars"
	for at in [Vector3(1.4, 0, -2.4), Vector3(19.3, 0, 1.8)]:
		_rock(self, at + Vector3(0, 0.20, 0), Vector3(0.7, 0.45, 0.7), stone)
		_rod(self, at, at + Vector3(-0.15, 2.4, 0), 0.06, wood)
		for branch in range(7):
			var end: Vector3 = at + Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(1.4, 2.8), rng.randf_range(-0.2, 0.2))
			_rod(self, at + Vector3(0, 1.5, 0), end, 0.024, wood)
			_rock(self, end, Vector3(0.65, 0.24, 0.32), _flat(Color(0.21, 0.28, 0.10)))


func _build_destinations() -> void:
	var spots: Array[Vector3] = [Vector3(6.2, 1.9, -2.7), Vector3(9, 0.8, -1.6), Vector3(11.7, 2.75, -1.9), Vector3(12.8, 2.25, -1.6)]
	for index in range(4):
		var object := Node3D.new()
		object.position = spots[index]
		add_child(object)
		objects.append(object)
	# Rubbing is mounted in its own frame; chisel rests on a display rack.
	_box(self, spots[0], Vector3(0.91, 1.39, 0.09), wood)
	_box(objects[0], Vector3(0, 0, 0.06), Vector3(0.75, 1.20, 0.025), paper)
	var rubbing: Label3D = _text(objects[0], Vector3(0, 0.02, 0.085), "晋 故\n振 威\n建 宁", 39)
	rubbing.font = preload("res://assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf")
	rubbing.modulate = Color(0.12, 0.14, 0.11)
	rubbing.outline_size = 0
	_box(self, Vector3(9, 0.58, -1.6), Vector3(0.9, 0.11, 0.45), wood)
	for x in [-0.28, 0.28]:
		_box(objects[1], Vector3(x, -0.05, 0), Vector3(0.07, 0.17, 0.13), wood)
	_rod(objects[1], Vector3(-0.35, 0.06, 0.04), Vector3(0.35, 0.11, 0.04), 0.045, _flat(Color(0.48, 0.48, 0.40)))
	_rod(objects[1], Vector3(-0.35, 0.06, 0.04), Vector3(-0.45, 0.01, 0.04), 0.014, bronze)
	_rod(objects[2], Vector3(0, 0.05, 0), Vector3(0, 0.7, 0), 0.018, _flat(Color(0.46, 0.31, 0.13)))
	preload("res://scripts/artisan_prop_detail.gd").bell(objects[2],bronze)
	var red: Material = _flat(Color(0.62, 0.10, 0.055))
	for side in [-1, 1]:
		var ribbon: MeshInstance3D = _box(objects[3], Vector3(side * 0.09, -0.17, 0.05), Vector3(0.055, 0.65, 0.025), red)
		ribbon.rotation.z = side * 0.18
		_rod(objects[3], Vector3.ZERO, Vector3(side * 0.22, 0.13, 0), 0.033, red)
	for index in range(7):
		var lamp_at: Vector3 = [Vector3(6.2, 2.8, -1.9), Vector3(8.0, 1.0, -1.5), Vector3(11.7, 3.2, -1.5), Vector3(12.8, 3.1, -1.5), Vector3(2.2, 1.45, -1.3), Vector3(5, 0.35, -0.9), Vector3(15.5, 1.1, -1.4)][index]
		var lamp: Node3D = _oil(lamp_at, false)
		chapter._lamps.append(lamp)
		if index >= 4:
			_box(self, lamp_at - Vector3(0, 0.15, 0), Vector3(0.53, 0.14, 0.48), stone)
			if index != 5: _box(self, Vector3(lamp_at.x, lamp_at.y * 0.5 - 0.12, lamp_at.z), Vector3(0.24, lamp_at.y - 0.3, 0.24), stone)
		var label: Label3D = _text(self, Vector3(chapter.ITEM_POSITIONS[index], 0.15, 0.8), chapter.ITEMS[index], 24)
		targets.append(label)
		ground_markers.append(_ground_marker(chapter.ITEM_POSITIONS[index]))


func _ground_marker(x: float) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.18
	ring.outer_radius = 0.24
	ring.rings = 24
	ring.ring_segments = 6
	marker.mesh = ring
	marker.position = Vector3(x, 0.032, 0.45)
	marker.scale.y = 0.16
	marker.material_override = _flat(Color(0.83, 0.65, 0.31), true, true)
	add_child(marker)
	return marker


func _oil(at: Vector3, portable: bool) -> Node3D:
	var lamp := Node3D.new()
	lamp.position = at
	add_child(lamp)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.19
	mesh.bottom_radius = 0.11
	mesh.height = 0.10
	mesh.radial_segments = 14
	var bowl := MeshInstance3D.new()
	bowl.mesh = mesh
	bowl.material_override = bronze
	lamp.add_child(bowl)
	_rod(lamp, Vector3(0.08, 0.05, 0), Vector3(0.14, 0.12, 0), 0.018, _flat(Color(0.10, 0.08, 0.035)))
	var flame: MeshInstance3D = _flame(lamp, 0.055, 0.20)
	flame.name = "Shade"
	flame.position = Vector3(0.14, 0.21, 0)
	flame.material_override = _flat(Color(1, 0.62, 0.13), true, true)
	flames.append(flame)
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.position = Vector3(0, 0.28, 0.32)
	glow.light_color = Color(1, 0.60, 0.23)
	glow.light_energy = 0.5 if portable else 0
	glow.omni_range = 2.6 if portable else 4.0
	lamp.add_child(glow)
	return lamp


func _build_table() -> void:
	_box(self, Vector3(3.7, 0.67, -1.9), Vector3(1.9, 0.13, 0.72), wood)
	for x in [3.0, 4.4]: _box(self, Vector3(x, 0.3, -1.9), Vector3(0.13, 0.6, 0.57), wood)
	for index in range(3): supplies.append(_oil(Vector3(3.15 + index * 0.53, 0.81, -1.8), true))
	supply_label = _text(self, Vector3(3.7, 2.4, -1.1), "村民灯桌 · 取灯处", 24)


func _build_scroll() -> void:
	scroll = Node3D.new()
	scroll.position = Vector3(16.8, 2.25, -1.4)
	add_child(scroll)
	_box(scroll, Vector3.ZERO, Vector3(4.7, 1.6, 0.045), paper)
	world_scroll_paper=MeshInstance3D.new()
	world_scroll_paper.name="OrnateWorldScrollPaper"
	var sheet:=QuadMesh.new()
	sheet.size=Vector2(4.7,1.6)
	world_scroll_paper.mesh=sheet
	world_scroll_paper.position.z=.028
	var cover_material:=StandardMaterial3D.new()
	cover_material.albedo_texture=SCROLL_COVER
	cover_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	world_scroll_paper.material_override=cover_material
	scroll.add_child(world_scroll_paper)
	for x in [-2.4, 2.4]: _rod(scroll, Vector3(x, -0.9, 0), Vector3(x, 0.9, 0), 0.075, wood)
	for y in [-0.68, 0.68]: _box(scroll, Vector3(0, y, 0.035), Vector3(4.5, 0.018, 0.015), bronze)
	var title: Label3D = _text(scroll, Vector3(0, 0.38, 0.055), "一 路 同 行 · 七 灯 共 庭", 30)
	title.modulate = Color(0.22, 0.16, 0.08)
	title.outline_size = 0
	var verse: Label3D = _text(scroll, Vector3(0, -0.13, 0.055), "字有所读，石有所依\n人有来路，灯有归处", 28)
	verse.modulate = Color(0.26, 0.22, 0.13)
	verse.outline_size = 0
	chronicle_label=_text(scroll,Vector3(0,-.56,.060),"二爨一脉 · 405—458",18)
	chronicle_label.modulate=Color(.48,.20,.12)
	chronicle_label.outline_size=0
	chronicle_label.visible=false
	_text(self, Vector3(18, 0.2, 0.7), "廊下共看长卷", 24).set_meta("scroll_caption", true)


func _panel(parent: Control, at: Vector2, size: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.64, 0.43, 0.19)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _label(parent: Control, at: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = size
	label.add_theme_font_override("font", font)
	if font_size>=24: label.add_theme_font_override("font",UiStyle.heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(font_size))
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 8
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	for slot in range(2):
		var accent := Color(.51, .23, .13) if slot == 0 else Color(.12, .32, .38)
		var card: Panel = _panel(root, Vector2(350 + slot * 458, 630), Vector2(436, 68), Color(0.035, 0.055, 0.05, 0.94))
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxTexture.new()
		style.texture = preload("res://assets/interface/task_flower_paper.png")
		style.modulate_color = Color(1, 1, 1, .94)
		card.add_theme_stylebox_override("panel", style)
		task_cards.append(card)
		task_headers.append(_label(card, Vector2(16, 8), Vector2(404, 19), 13, accent))
		task_labels.append(_label(card, Vector2(16, 30), Vector2(404, 22), 14, UiStyle.INK))
		var bar := ProgressBar.new()
		bar.position = Vector2(16, 58)
		bar.size = Vector2(408, 3)
		bar.show_percentage = false
		bar.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(1))
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.13, 0.18, 0.17)
		bar.add_theme_stylebox_override("background", track)
		var fill := StyleBoxFlat.new()
		fill.bg_color = accent
		bar.add_theme_stylebox_override("fill", fill)
		card.add_child(bar)
		# Apply the thin height after replacing the default theme's minimum size.
		bar.size = Vector2(408, 3)
		task_bars.append(bar)
	dialogue = _panel(root, Vector2(280, 584), Vector2(640, 76), Color(0.07, 0.09, 0.07, 0.94))
	dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text = _label(dialogue, Vector2(17, 10), Vector2(606, 62), 16, Color(1, 0.87, 0.64))
	record = ColorRect.new()
	record.color = Color(0.018, 0.025, 0.023, 1)
	record.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var record_layer := CanvasLayer.new()
	record_layer.layer = 11
	add_child(record_layer)
	record_layer.add_child(record)
	record_art = TextureRect.new()
	record_art.position = Vector2(64, 26)
	record_art.size = Vector2(1152, 648)
	record_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	record_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	record_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	record.add_child(record_art)
	var mount := ScrollMount.new()
	record.add_child(mount)
	record_cover = TextureRect.new()
	record_cover.texture = SCROLL_COVER
	record_cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	record_cover.position = Vector2(64,26)
	record_cover.size = Vector2(1152,648)
	record_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	record.add_child(record_cover)
	var cover_title := _label(record_cover,Vector2(220,158),Vector2(712,100),64,Color(.32,.16,.08))
	cover_title.text = "共 生 长 卷"
	cover_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cover_font: Font = UiStyle.heading_font()
	cover_title.add_theme_font_override("font",cover_font)
	var subtitle := _label(record_cover,Vector2(220,280),Vector2(712,45),28,Color(.45,.22,.11))
	subtitle.text = "同源异彩 · 和合共生"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font",cover_font)
	var invitation := _label(record_cover,Vector2(245,366),Vector2(662,90),22,Color(.24,.25,.20))
	invitation.text = "从碑院的一字一画，到古道的一梁一绳。\n众人各有所长，共点一院灯火。"
	invitation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invitation.add_theme_font_override("font",cover_font)
	var enter_note := _label(record_cover,Vector2(310,510),Vector2(532,36),18,Color(.45,.24,.12))
	enter_note.text = "点击「展卷共读」或按 Enter，读这一路同行。"
	enter_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var signature: Label = _label(record, Vector2(130, 56), Vector2(550, 47), 31, Color(1, 0.91, 0.64))
	record_signature = signature
	signature.text = "共 生 长 卷"
	signature.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.02, 1))
	signature.add_theme_constant_override("shadow_offset_x", 2)
	signature.add_theme_constant_override("shadow_offset_y", 2)
	var panel: Panel = _panel(record, Vector2(130, 421), Vector2(1020, 195), Color(0.025, 0.04, 0.045, 0.91))
	record_body = panel
	record_number = _label(record, Vector2(1010, 64), Vector2(160, 30), 17, Color(1, 0.94, 0.74))
	record_number.add_theme_color_override("font_shadow_color", Color.BLACK)
	record_number.add_theme_constant_override("shadow_offset_x", 1)
	record_number.add_theme_constant_override("shadow_offset_y", 2)
	record_title = _label(panel, Vector2(24, 14), Vector2(972, 37), 28, Color(1, 0.88, 0.55))
	record_text = _label(panel, Vector2(24, 61), Vector2(972, 121), 20, Color(0.98, 0.96, 0.87))
	var title_font: Font = UiStyle.heading_font()
	signature.add_theme_font_override("font", title_font)
	record_title.add_theme_font_override("font", title_font)
	previous_button = _button(record, Vector2(130, 632), "上一页", func():
		turn_record(-1)
	)
	next_button = _button(record, Vector2(965, 632), "下一页", func():
		if record_page == record_last_page(): chapter.close_record()
		else: turn_record(1)
	)
	var back: Button = _button(record, Vector2(548, 632), "返回庭院", func(): chapter.close_record())
	for button in [previous_button, next_button, back]:
		button.size = Vector2(185, 40)
		UiStyle.button(button)


func _button(parent: Control, at: Vector2, words: String, callback: Callable) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(250, 48)
	button.text = words
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(20))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func say(speaker: String, words: String, seconds: float = 5.0, immediate: bool = false) -> void:
	dialogue_text.text = CharacterNames.annotate(speaker + "：" + words)
	dialogue_left = seconds
	var root_world: Node = chapter.get_node("../../..")
	if is_instance_valid(root_world.story): root_world.story.speak(speaker, words, seconds, immediate)


func sync_state() -> void:
	placement_label.visible = chapter.bridge.tablet_delivered and not chapter.tablet_arriving and not chapter.tablet_raising and not chapter.tablet_placed
	placement_marker.visible = placement_label.visible
	for index in range(4): objects[index].visible = chapter.items_done[index]
	for index in range(7):
		var done: bool = chapter.items_done[index]
		chapter._lamps[index].get_node("Shade").visible = done
		chapter._lamps[index].get_node("Glow").light_energy = 0.85 if done else 0
		# Oil lamps are carried in, so the unfilled pedestals stay empty.
		chapter._lamps[index].visible = done or index < 4
		targets[index].visible = chapter.tablet_placed and not done and ((index < 4 and chapter.has_keepsake(index)) or (index>=4 and chapter.personal_items_done()))
		targets[index].modulate = Color(0.57, 1, 0.68) if chapter.item_progress[index] > 0 else Color(1, 0.85, 0.53)
		ground_markers[index].visible = targets[index].visible
	supply_label.visible = chapter.personal_items_done() and chapter.lamp_count < 7
	for index in range(3):
		supplies[index].visible = not chapter.items_done[index + 4] and chapter.oil_carriers[index] < 0


func _process(delta: float) -> void:
	if chapter == null: return
	chronicle_label.visible=chapter.first.comparison_complete
	var time: float = Time.get_ticks_msec() / 1000.0
	for index in range(flames.size()):
		flames[index].scale.y = 0.91 + 0.12 * sin(time * 6 + index * 2.4)
	objects[2].rotation.z = sin(time * 1.8) * 0.065
	if chapter.first.inspector.images.size() > 0:
		inscription.material_override.set_shader_parameter("albedo_texture", chapter.first.inspector.images[0])
	if chapter.party == null or chapter.party.player == null: return
	_refresh_guidance()
	for index in range(3):
		carried[index].visible = chapter.oil_carriers[index] >= 0
		if carried[index].visible:
			carried[index].global_position = chapter.party.role_body(chapter.oil_carriers[index]).global_position + Vector3(0.31, 0.27, 0.38)
			carry_labels[index].modulate = _role_color(chapter.oil_carriers[index])
	var residents: Node3D = chapter.get_node("Residents")
	residents.visible = chapter.personal_items_done()
	if residents.visible:
		for index in range(2):
			var resident: Node3D = residents.get_child(index)
			var destination := Vector3(2.5, 0, -2.2) if index == 0 else Vector3(6.2, 0, -2.4)
			var moving: bool = resident.position.distance_to(destination) > 0.01
			resident.position = resident.position.move_toward(destination, delta * 0.6)
			resident_work_left[index] = maxf(0, resident_work_left[index] - delta)
			resident.get_node("Character").animate_model(delta, 0.6 if moving else 0.0, true, false, false, not moving and (index == 0 or resident_work_left[index] > 0))
	dialogue_left = maxf(0, dialogue_left - delta)
	dialogue.visible = false
	for child in get_children():
		if child.has_meta("scroll_caption"): child.visible = chapter.court_lit


func resident_work(index: int, seconds: float = 2.5) -> void:
	resident_work_left[index] = seconds


func _role_color(role: int) -> Color:
	if chapter.party.active_id == role: return Color(1, 0.82, 0.43)
	if chapter.party.local_coop and chapter.party.second_id == role: return Color(0.42, 0.82, 1)
	return Color(0.83, 0.65, 0.31)


func _refresh_guidance() -> void:
	var humans: Array[CharacterBody3D] = chapter.party.human_players()
	var in_courtyard: bool = false
	for body in humans: in_courtyard = in_courtyard or body.global_position.x >= 40
	for slot in range(task_cards.size()):
		# The three-chapter guidance footer now owns personal progress. Keep
		# these legacy references for scene consumers, without duplicate cards.
		if chapter.get_node("../../..").get("guidance")!=null:
			task_cards[slot].visible=false
			continue
		task_cards[slot].visible = chapter.party.started and in_courtyard and not chapter.record_open and slot < humans.size()
		if not task_cards[slot].visible: continue
		var body: CharacterBody3D = humans[slot]
		var task: Dictionary = chapter.player_task(body)
		task_cards[slot].visible = task.progress > 0
		task_headers[slot].text = "%dP  %s     七灯 %d / 7" % [slot + 1, chapter.party.NAMES[body.character_id], chapter.lamp_count]
		task_labels[slot].text = CharacterNames.annotate(task.text).replace("按住 E · ", "").replace("按住 P · ", "")
		task_bars[slot].value = task.progress * 100
		task_headers[slot].text += "   %d%%" % roundi(task.progress * 100)
	for index in range(7):
		var role: int = index if index < 4 else chapter.oil_carriers[index - 4]
		var color: Color = Color(0.57, 1, 0.68) if chapter.item_progress[index] > 0 else _role_color(role)
		ground_markers[index].material_override = _flat(color, true, true)
	placement_marker.material_override = _flat(Color(0.57, 1, 0.68) if chapter.action_progress > 0 else Color(0.83, 0.65, 0.31), true, true)


func begin_scroll(seconds: float) -> void:
	scroll.visible = true
	scroll.scale.x = 0.01
	scroll_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	scroll_tween.tween_property(scroll, "scale:x", 1.0, seconds).set_trans(Tween.TRANS_SINE)


func open_record(lines: Array[String]) -> void:
	chapter.get_node("../../..").sfx.play("page")
	record_lines.assign(lines)
	record_page = 0
	record_cover_open = true
	_refresh_record()
	record.visible = true


func turn_record(direction: int) -> void:
	if record_cover_open:
		if direction > 0:
			record_cover_open = false
			chapter.get_node("../../..").sfx.play("page")
			_refresh_record()
		return
	if record_page != clampi(record_page + direction, 0, record_last_page()): chapter.get_node("../../..").sfx.play("page")
	record_page = clampi(record_page + direction, 0, record_last_page())
	_refresh_record()


func _refresh_record() -> void:
	record_cover.visible = record_cover_open
	record_art.visible = not record_cover_open
	record_signature.visible = not record_cover_open
	record_body.visible = not record_cover_open
	record_number.visible = not record_cover_open
	previous_button.visible = not record_cover_open
	record_number.text = "卷 %d  /  %d" % [record_page + 1, Story.SCROLL.size()]
	record_title.text = Story.SCROLL[record_page].title
	record_text.text = Story.SCROLL[record_page].text
	record_art.texture = SCROLL_IMAGES[record_page]
	previous_button.disabled = record_page == 0
	next_button.text = "展卷共读" if record_cover_open else "回到灯火中" if record_page == record_last_page() else "下一页"


func record_last_page() -> int:
	return Story.SCROLL.size() - 1


func close_record() -> void:
	record.visible = false


func reset_art() -> void:
	if scroll_tween != null and scroll_tween.is_valid(): scroll_tween.kill()
	scroll.visible = false
	scroll.scale = Vector3.ONE
	record.visible = false
	dialogue.visible = false
	dialogue_left = 0
	for lamp in carried: lamp.visible = false
	for card in task_cards: card.visible = false
	sync_state()
