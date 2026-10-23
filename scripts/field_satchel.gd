extends Control

signal close_requested

const CharacterNames = preload("res://scripts/character_names.gd")
const UiSkin = preload("res://scripts/interface_skin.gd")
const NOTE_TITLES: Array[String] = ["辨字笺", "寻首笺", "辨向笺", "合读笺"]
var progress_label: Label
var close_button: Button
var cards: Array[Panel] = []
var titles: Array[Label] = []
var origins: Array[Label] = []
var statuses: Array[Label] = []
var contents: Array[Label] = []
var _font: Font
var comparison_button: Button
var comparison_sheet: Panel
var comparison_title: Label
var comparison_text: Label
var comparison_known: bool = false
var keepsake_button: Button
var showing_keepsakes: bool=false
var note_collected: Array[bool]=[false,false,false,false]
var note_clues: Array[String]=["","","",""]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = preload("res://scripts/interface_skin.gd").body_font()

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.025, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_panel(self, Vector2(96,64), Vector2(1088,592), Color(0.105,0.13,0.12), Color(0.53,0.43,0.25))
	_text(self, Vector2(136,84), Vector2(160,52), 36, "包 裹", Color(0.94,0.86,0.66))
	_text(self, Vector2(294,104), Vector2(152,30), 16, "同行行囊", Color(0.73,0.73,0.62))
	keepsake_button=Button.new()
	keepsake_button.position=Vector2(460,91)
	keepsake_button.size=Vector2(210,43)
	keepsake_button.text="翻看随身物件"
	keepsake_button.add_theme_font_size_override("font_size",UiSkin.text_size(16))
	keepsake_button.focus_mode=Control.FOCUS_NONE
	UiSkin.notice_button(keepsake_button)
	keepsake_button.pressed.connect(func(): _show_keepsakes(not showing_keepsakes))
	add_child(keepsake_button)
	progress_label = _text(self, Vector2(986,104), Vector2(155,30), 18, "", Color(0.85,0.75,0.48))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	comparison_button=Button.new()
	comparison_button.position=Vector2(690,91)
	comparison_button.size=Vector2(236,43)
	comparison_button.text="翻看二爨对照笺"
	comparison_button.add_theme_font_size_override("font_size",UiSkin.text_size(16))
	comparison_button.focus_mode=Control.FOCUS_NONE
	UiSkin.notice_button(comparison_button)
	comparison_button.pressed.connect(func(): _show_comparison(not comparison_sheet.visible))
	add_child(comparison_button)
	var rule := ColorRect.new()
	rule.position = Vector2(136,149)
	rule.size = Vector2(1008,1)
	rule.color = Color(0.54,0.46,0.29,0.65)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
	for index in range(4):
		var at := Vector2(136 + (index % 2) * 512, 170 + floori(index / 2.0) * 190)
		var card: Panel = _panel(self, at, Vector2(496,172), Color(0.22,0.25,0.23), Color(0.39,0.40,0.32))
		cards.append(card)
		var paper := UiSkin.texture_paper()
		paper.texture=UiSkin.PARCEL_PAPER
		card.add_theme_stylebox_override("panel",paper)
		var reading_paper := ColorRect.new()
		reading_paper.position=Vector2(12,8)
		reading_paper.size=Vector2(472,148)
		reading_paper.color=Color(.96,.90,.76,.82)
		reading_paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(reading_paper)
		titles.append(_text(card, Vector2(18,12), Vector2(320,32), 23, NOTE_TITLES[index], Color.WHITE))
		var status: Label = _text(card, Vector2(388,17), Vector2(88,26), 16, "", Color.WHITE)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		statuses.append(status)
		origins.append(_text(card, Vector2(18,48), Vector2(460,26), 16, CharacterNames.DISPLAY_NAMES[index] + " · 见闻", Color.WHITE))
		contents.append(_text(card, Vector2(18,84), Vector2(460,72), 18, "", Color.WHITE))
	comparison_sheet=_panel(self,Vector2(136,170),Vector2(1008,362),Color(.95,.89,.74),Color(.53,.43,.25))
	comparison_sheet.add_theme_stylebox_override("panel",UiSkin.notice_paper())
	var reading_paper := ColorRect.new()
	reading_paper.position=Vector2(20,14)
	reading_paper.size=Vector2(968,334)
	reading_paper.color=Color(.96,.90,.77,.88)
	reading_paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
	comparison_sheet.add_child(reading_paper)
	comparison_title=_text(comparison_sheet,Vector2(28,20),Vector2(952,37),24,"",UiSkin.VERMILION)
	comparison_text=_text(comparison_sheet,Vector2(28,70),Vector2(952,270),19,"",UiSkin.INK)
	comparison_sheet.visible=false
	_text(self, Vector2(136,551), Vector2(770,26), 16, "收得一笺，便留一闻。已录内容可随时翻看。", Color(0.85,0.81,0.68))
	_text(self, Vector2(136,586), Vector2(740,36), 15, "翻看时暂停同行，收起后继续。R 保留见闻，T 重启旅程。", Color(0.62,0.67,0.60))
	close_button = Button.new()
	close_button.position = Vector2(918,576)
	close_button.size = Vector2(226,48)
	close_button.text = "收起包裹 · B / Esc"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_override("font", _font)
	close_button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(18))
	close_button.add_theme_color_override("font_color", Color(0.12,0.14,0.11))
	close_button.add_theme_stylebox_override("normal", _style(Color(0.72,0.62,0.36), Color(0.81,0.71,0.44)))
	close_button.add_theme_stylebox_override("hover", _style(Color(0.84,0.74,0.46), Color(0.93,0.84,0.59)))
	close_button.add_theme_stylebox_override("pressed", _style(Color(0.62,0.53,0.29), Color(0.81,0.71,0.44)))
	close_button.pressed.connect(func(): close_requested.emit())
	UiSkin.notice_button(close_button)
	add_child(close_button)
	visible = false


func show_notes(collected: Array[bool], clues: Array[String], has_comparison: bool=false) -> void:
	note_collected.assign(collected)
	note_clues.assign(clues)
	comparison_known=has_comparison
	_show_comparison(false)
	visible=true


func _draw_notes() -> void:
	progress_label.text = "已录 %d / 5" % (note_collected.count(true)+int(comparison_known))
	for index in range(4):
		var known: bool = note_collected[index]
		var ink: Color = Color(0.18,0.16,0.12) if known else Color(.40,.38,.30)
		var paper := UiSkin.texture_paper(false,Color.WHITE if known else Color(.80,.78,.72))
		paper.texture=UiSkin.PARCEL_PAPER
		cards[index].add_theme_stylebox_override("panel",paper)
		for label: Label in [titles[index], origins[index], statuses[index], contents[index]]:
			label.add_theme_color_override("font_color", ink)
		statuses[index].text = "已录" if known else "待拾"
		titles[index].text=NOTE_TITLES[index]
		origins[index].text=CharacterNames.DISPLAY_NAMES[index]+" · 见闻"
		origins[index].add_theme_color_override("font_color",Color(.39,.32,.21))
		contents[index].text = note_clues[index].get_slice("：", 1) if known else "此笺尚未放入包裹。\n打开小爨碑，请这位同伴分享见闻。"


func _show_comparison(showing: bool) -> void:
	showing_keepsakes=false
	keepsake_button.text="翻看随身物件"
	_draw_notes()
	comparison_sheet.visible=showing
	for card in cards: card.visible=not showing
	comparison_button.text="回到四人见闻" if showing else "翻看二爨对照笺"
	comparison_title.text="二爨对照笺 · 已录" if comparison_known else "二爨对照笺 · 待拾"
	comparison_text.text=preload("res://scripts/stele_lore.gd").NOTE if comparison_known else "点击场景右侧的大爨碑，阅读两碑介绍，完成三步「二爨合读」，取得大爨对照印记。\n\n印记与小爨传拓、四人见闻、六字归位共同完成第一关；缺少任何一项，院门都不会开启。"


func _show_keepsakes(showing: bool) -> void:
	if not showing:
		_show_comparison(false)
		return
	showing_keepsakes=true
	comparison_sheet.visible=false
	comparison_button.text="翻看二爨对照笺"
	keepsake_button.text="回到四人见闻"
	var inventory: Node3D=get_parent().get_parent().keepsakes
	progress_label.text="收纳 %d / 4"%inventory.collected.count(true)
	for index in range(4):
		cards[index].visible=true
		var known: bool=inventory.collected[index]
		var placed: bool=get_parent().get_parent().courtyard.items_done[index]
		var ink: Color=UiSkin.INK if known else Color(.40,.38,.30)
		var paper:=UiSkin.texture_paper(false,Color.WHITE if known else Color(.80,.78,.72))
		paper.texture=UiSkin.PARCEL_PAPER
		cards[index].add_theme_stylebox_override("panel",paper)
		for label: Label in [titles[index],origins[index],statuses[index],contents[index]]:
			label.add_theme_color_override("font_color",ink)
		titles[index].text=inventory.TITLES[index]
		origins[index].text=inventory.PLACES[index]
		statuses[index].text="归位" if placed else "已拾" if known else "待拾"
		contents[index].text=inventory.entry_text(index)


func _text(parent: Node, at: Vector2, dimensions: Vector2, font_size: int, words: String, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.text = words
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _font)
	if font_size>=23: label.add_theme_font_override("font",UiSkin.heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(font_size))
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style


func _panel(parent: Node, at: Vector2, dimensions: Vector2, color: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = dimensions
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(color, border))
	parent.add_child(panel)
	return panel
