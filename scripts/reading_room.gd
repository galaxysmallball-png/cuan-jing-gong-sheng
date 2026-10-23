extends Control

const Content = preload("res://scripts/culture_content.gd")
const UiStyle = preload("res://scripts/interface_skin.gd")
const Draw = preload("res://scripts/opening_card_draw.gd")
const PAPER = preload("res://assets/story/story_paper.png")
var card: TextureRect
var name_label: Label
var body: RichTextLabel
var note: Label
var number: Label
var source_links: RichTextLabel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := TextureRect.new()
	background.texture = PAPER
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	name_label = _label(Vector2(460, 148), Vector2(690, 48), 29)
	number = _label(Vector2(1030, 54), Vector2(140, 38), 18)
	card = TextureRect.new()
	card.position = Vector2(110, 146)
	card.size = Vector2(300, 450)
	card.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	body = _rich(Vector2(460, 220), Vector2(690, 345), 19)
	note = _label(Vector2(460, 570), Vector2(690, 37), 13)
	source_links = _rich(Vector2(120, 480), Vector2(1030, 124), 15)
	source_links.meta_clicked.connect(func(url: Variant): OS.shell_open(str(url)))
	visible = false


func show_person(index: int) -> void:
	var person: Dictionary = Content.PEOPLE[index]
	visible = true
	card.visible = true
	card.texture = Draw.CARD_TEXTURES[index]
	name_label.position = Vector2(460, 148)
	name_label.size = Vector2(690, 48)
	name_label.text = person.name
	body.position = Vector2(460, 215)
	body.size = Vector2(690, 345)
	body.text = "[color=#7e3826]" + person.role + "[/color]\n\n[b]乡里与行当[/b]\n" + person.home \
		+ "\n[b]衣饰与日常[/b]\n" + person.daily + "\n[b]此行所愿[/b]\n" + person.wish
	body.scroll_to_line(0)
	number.text = "%02d / 08" % (index + 1)
	note.position = Vector2(460, 570)
	note.text = "游戏原创人物 · 按剧本与角色卡编写，生活描写属于角色自身"
	source_links.visible = false


func show_culture(index: int) -> void:
	var entry: Dictionary = Content.CULTURE[index]
	visible = true
	card.visible = false
	name_label.position = Vector2(120, 142)
	name_label.size = Vector2(1030, 48)
	name_label.text = entry.subtitle
	body.position = Vector2(120, 215)
	body.size = Vector2(1030, 255)
	body.text = entry.body
	body.scroll_to_line(0)
	number.text = "%02d / 04" % (index + 1)
	source_links.visible = true
	var citations: Array[String] = []
	for id in entry.sources:
		var source: Dictionary = Content.SOURCES[id]
		citations.append("[url=%s]%s[/url]" % [source.url, source.title])
	source_links.text = "[b]资料出处[/b]  ·  点击查看原文\n" + "\n".join(citations)
	note.position = Vector2(120, 610)
	note.text = "史料为公开资料转述；护碑人物与情节为原创。"


func _label(at: Vector2, dimensions: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if size>=24: label.add_theme_font_override("font",UiStyle.heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("font_color", UiStyle.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _rich(at: Vector2, dimensions: Vector2, size: int) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.position = at
	label.size = dimensions
	label.bbcode_enabled = true
	label.scroll_active = true
	var font := preload("res://scripts/interface_skin.gd").body_font()

	for type in ["normal_font", "italics_font", "mono_font"]: label.add_theme_font_override(type, font)
	label.add_theme_font_override("bold_font",UiStyle.heading_font())
	label.add_theme_font_override("bold_italics_font",UiStyle.heading_font())
	label.add_theme_font_size_override("normal_font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_font_size_override("bold_font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("default_color", UiStyle.INK)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_constant_override("line_separation", 3)
	add_child(label)
	return label
