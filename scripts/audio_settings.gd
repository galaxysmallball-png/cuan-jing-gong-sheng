extends Control

signal close_requested
const UiSkin = preload("res://scripts/interface_skin.gd")
var world: Node3D
var music_button: Button
var effects_button: Button
var music_slider: HSlider
var effects_slider: HSlider
var music_level: Label
var effects_level: Label
var panel: Panel


func setup(owner_world: Node3D) -> void:
	world = owner_world
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(.025, .04, .045, .20)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	panel = Panel.new()
	panel.position = Vector2(902, 74)
	panel.size = Vector2(354, 272)
	panel.add_theme_stylebox_override("panel", UiSkin.texture_paper())
	add_child(panel)
	_label(panel, "声 音 设 置", Vector2(24, 18), Vector2(200, 32), 22)
	var close_button := _button(panel, "收起 Esc", Vector2(250, 20), Vector2(82, 30))
	close_button.pressed.connect(func(): close_requested.emit())
	for index in range(2):
		var y: float = 76 + index * 78
		_label(panel, "背景音乐" if index == 0 else "动作与环境音效", Vector2(24, y), Vector2(220, 26), 18)
		var toggle := _button(panel, "", Vector2(250, y - 2), Vector2(82, 30))
		var slider := HSlider.new()
		slider.position = Vector2(24, y + 34)
		slider.size = Vector2(238, 26)
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = 100 if index == 0 else 85
		slider.focus_mode = Control.FOCUS_NONE
		panel.add_child(slider)
		var level := _label(panel, "", Vector2(276, y + 34), Vector2(56, 26), 17)
		if index == 0:
			music_button = toggle
			music_slider = slider
			music_level = level
			toggle.pressed.connect(func(): world.music.toggle_mute())
			slider.value_changed.connect(func(value: float): world.music.set_volume(value / 100))
		else:
			effects_button = toggle
			effects_slider = slider
			effects_level = level
			toggle.pressed.connect(func(): world.sfx.toggle_mute())
			slider.value_changed.connect(func(value: float): world.sfx.set_volume(value / 100))
	_label(panel, "拖动即调节 · 收起后继续同行", Vector2(24, 237), Vector2(308, 22), 14)
	visible = false


func _label(parent: Control, text: String, at: Vector2, dimensions: Vector2, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("font_color", UiSkin.INK)
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if size>=18: label.add_theme_font_override("font",UiSkin.heading_font())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	UiSkin.button(button)
	button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(16))
	parent.add_child(button)
	return button


func sync() -> void:
	if not visible: return
	music_button.text = "音乐 · 关" if world.music.muted else "音乐 · 开"
	effects_button.text = "音效 · 关" if world.sfx.muted else "音效 · 开"
	music_level.text = "%d%%" % roundi(world.music.volume * 100)
	effects_level.text = "%d%%" % roundi(world.sfx.volume * 100)
	music_slider.set_value_no_signal(world.music.volume * 100)
	effects_slider.set_value_no_signal(world.sfx.volume * 100)
	music_slider.modulate.a = .5 if world.music.muted else 1
	effects_slider.modulate.a = .5 if world.sfx.muted else 1
