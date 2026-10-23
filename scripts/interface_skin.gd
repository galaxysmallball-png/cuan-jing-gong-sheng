extends RefCounted

const INK := Color(0.18, 0.20, 0.18)
const PAPER := Color(0.94, 0.89, 0.76, 0.97)
const BRONZE := Color(0.57, 0.40, 0.24)
const VERMILION := Color(0.52, 0.22, 0.15)
const TITLE_BUTTON = preload("res://assets/interface/title_button_paper.png")
const GAME_BUTTON = preload("res://assets/interface/game_button_paper.png")
const PARCEL_PAPER = preload("res://assets/interface/parcel_paper.png")
const NOTICE_PAPER = preload("res://assets/interface/notice_bird_paper.png")
const TEXT_SCALE: float = 1.16
const CUAN_FONT = preload("res://assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf")
static var _body_font: FontFile
static var _heading_font: FontVariation


static func body_font() -> Font:
	if _body_font==null:
		_body_font=CUAN_FONT.duplicate()
		var fallback := SystemFont.new()
		fallback.font_names=PackedStringArray(["Microsoft YaHei","SimHei"])
		_body_font.fallbacks=[fallback]
	return _body_font


static func heading_font() -> Font:
	if _heading_font==null:
		_heading_font=FontVariation.new()
		_heading_font.base_font=body_font()
		# A small increase in the actual glyph stroke; retain the open counters.
		_heading_font.variation_embolden=0.3
	return _heading_font


static func parcel_button(control: Button) -> void:
	button(control)
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxTexture.new()
		style.texture=PARCEL_PAPER
		style.modulate_color=Color(.88,.82,.70) if state=="pressed" else Color(1.06,1.03,.95) if state=="hover" else Color.WHITE
		style.set_content_margin_all(0)
		control.add_theme_stylebox_override(state,style)


static func paper(accent: Color = BRONZE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0.02, 0.03, 0.025, 0.25)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style


static func texture_paper(title: bool = false, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = TITLE_BUTTON if title else GAME_BUTTON
	# Render the supplied composition intact; source pixels remain unchanged.
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.modulate_color = tint
	style.set_content_margin_all(0)
	return style


static func button(control: Button, primary: bool = false, title: bool = false) -> void:
	control.add_theme_font_override("font",heading_font())
	control.focus_mode = Control.FOCUS_NONE
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var tint := Color.WHITE
		if state == "hover": tint = Color(1.08, 1.04, .95)
		elif state == "pressed": tint = Color(.88, .82, .70)
		var style: StyleBoxTexture = texture_paper(title, tint)
		control.add_theme_stylebox_override(state, style)
	control.add_theme_color_override("font_color", VERMILION if primary else INK)
	control.add_theme_color_override("font_hover_color", VERMILION)
	control.add_theme_color_override("font_pressed_color", INK)
	control.add_theme_color_override("font_focus_color", INK)


static func text_size(base: int) -> int:
	return roundi(base*TEXT_SCALE)


static func notice_paper() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture=NOTICE_PAPER
	style.set_content_margin_all(0)
	return style


static func layout_notice(frame: Panel, words: Label, anchor: Vector2, centered: bool=false) -> void:
	words.add_theme_font_override("font",heading_font())
	words.add_theme_font_size_override("font_size",text_size(16))
	words.add_theme_color_override("font_color",VERMILION)
	words.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	words.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var text_width: float=0
	for line in words.text.split("\n"):
		text_width=maxf(text_width,heading_font().get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size(16)).x)
	var width: float=clampf(text_width+52,340,570)
	frame.position=Vector2(anchor.x-width*(.5 if centered else 1.0),anchor.y)
	words.position=Vector2(20,6) if words.get_parent()==frame else frame.position+Vector2(20,6)
	words.size=Vector2(width-40,38)
	var height: float=maxf(38,words.get_minimum_size().y)
	words.size.y=height
	frame.size=Vector2(width,height+12)


static func notice_button(control: Button) -> void:
	button(control)
	for state in ["normal","hover","pressed","focus"]:
		var style := notice_paper()
		style.modulate_color=Color(.88,.82,.70) if state=="pressed" else Color(1.06,1.03,.95) if state=="hover" else Color.WHITE
		control.add_theme_stylebox_override(state,style)
