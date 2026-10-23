extends Panel

const PAPER = preload("res://assets/interface/objective_paper.png")
const UiSkin = preload("res://scripts/interface_skin.gd")
var heading: Label
var body: Label
var count: Label
var action_label: Label
var action_bar: ProgressBar


func _ready() -> void:
	position = Vector2(24, 528)
	size = Vector2(344, 170)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var border := UiSkin.paper()
	border.bg_color = Color(0.32, 0.23, 0.13)
	border.shadow_size = 5
	add_theme_stylebox_override("panel", border)
	var paper := TextureRect.new()
	paper.texture = PAPER
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	paper.position = Vector2(2, 2)
	paper.size = size - Vector2(4, 4)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	heading = _label(Vector2(16, 12), Vector2(136, 26), 20, UiSkin.VERMILION, true)
	heading.text = "此 刻 所 往"
	count = _label(Vector2(164, 17), Vector2(164, 20), 12, UiSkin.INK)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var rule := ColorRect.new()
	rule.position = Vector2(16, 43)
	rule.size = Vector2(312, 1)
	rule.color = Color(0.51, 0.36, 0.20, 0.5)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
	body = _label(Vector2(16, 53), Vector2(312, 69), 15, UiSkin.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_label = _label(Vector2(16, 126), Vector2(312, 19), 12, UiSkin.VERMILION)
	action_bar = ProgressBar.new()
	action_bar.position = Vector2(16, 150)
	action_bar.size = Vector2(312, 7)
	action_bar.max_value = 1
	action_bar.show_percentage = false
	action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = Color(.4, .3, .18, .2)
	track.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiSkin.VERMILION
	fill.set_corner_radius_all(3)
	action_bar.add_theme_stylebox_override("background", track)
	action_bar.add_theme_stylebox_override("fill", fill)
	add_child(action_bar)
	action_bar.size = Vector2(312, 7)


func show_goal(text: String, progress: String) -> void:
	if body.text != text: body.text = text
	count.text = progress


func show_interaction(state: Dictionary) -> void:
	action_label.text = state.text if state.ratio>0 else ""
	action_bar.value = state.ratio


func set_compact(compact: bool) -> void:
	position = Vector2(24, 610 if compact else 528)
	size = Vector2(344, 88 if compact else 170)
	get_child(0).size = size - Vector2(4, 4)
	body.visible = not compact
	action_label.position.y = 45 if compact else 126
	action_bar.position.y = 69 if compact else 150


func _label(at: Vector2, dimensions: Vector2, font_size: int, color: Color, calligraphy: bool = false) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if calligraphy: label.add_theme_font_override("font",UiSkin.heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(font_size))
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
