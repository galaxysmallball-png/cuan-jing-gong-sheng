extends Control

signal close_requested
const UiStyle = preload("res://scripts/interface_skin.gd")
var party: Node3D
var pairs: Label
var current_goal: Label
var second_heading: Label
var second_controls: Label
var first_controls: Label
var footer_help: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var shade:=ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color(.025,.035,.03,.52)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var panel:=Panel.new()
	panel.position=Vector2(260,55)
	panel.size=Vector2(760,610)
	panel.add_theme_stylebox_override("panel",UiStyle.texture_paper())
	add_child(panel)
	_label(panel,Vector2(36,24),Vector2(600,38),25,"行 旅 提 示",UiStyle.VERMILION)
	var close:=Button.new()
	close.position=Vector2(680,28)
	close.size=Vector2(44,34)
	close.text="×"
	UiStyle.button(close)
	close.pressed.connect(func(): close_requested.emit())
	panel.add_child(close)
	_label(panel,Vector2(36,68),Vector2(688,24),15,"眼下这一程",UiStyle.VERMILION)
	current_goal=_label(panel,Vector2(36,97),Vector2(688,64),16,"",UiStyle.INK)
	pairs=_label(panel,Vector2(36,173),Vector2(688,56),14,"",UiStyle.INK)
	_label(panel,Vector2(36,241),Vector2(320,28),18,"旅人一 · 1P",UiStyle.VERMILION)
	second_heading=_label(panel,Vector2(400,241),Vector2(324,28),18,"旅人二 · 2P",Color(.20,.37,.40))
	first_controls=_label(panel,Vector2(36,280),Vector2(320,154),14,
		"WASD　前后左右\n空格　跳跃\nE　任务操作\nF　交谈、察看、下一句\nG　切换附近目标\nTab　切换专属角色",UiStyle.INK)
	second_controls=_label(panel,Vector2(400,280),Vector2(324,154),14,
		"方向键　前后左右\n小键盘 Enter　跳跃\nP / 小键盘0　任务操作\n/　交谈、察看、下一句\n.　切换附近目标\n右 Shift　切换专属角色",UiStyle.INK)
	footer_help=_label(panel,Vector2(36,447),Vector2(688,94),12,
		"任务看左下此刻所往；站稳操作时，右下显示各自的进度。\nB 包裹 · C 成就册 · F2 档案 · V 续话 · 右上声音设置\nR 回位置、保留任务 · T 从第一关重玩、清空本轮成就\n碑面：再点空白处放回，点凹槽放入；Q / 右键旋转 · H / Esc 返回",UiStyle.INK)
	var coach_button:=Button.new()
	coach_button.position=Vector2(36,558)
	coach_button.size=Vector2(688,30)
	coach_button.text="重新展开同行引导，继续旅程"
	coach_button.add_theme_font_size_override("font_size",UiStyle.text_size(14))
	UiStyle.notice_button(coach_button)
	coach_button.pressed.connect(func():
		if party!=null: party.get_parent().experience.restore_coach()
		close_requested.emit()
	)
	panel.add_child(coach_button)
	visible=false


func show_for(owner_party: Node3D, _current_goal: String) -> void:
	party = owner_party
	var goal_lines: PackedStringArray=party.get_parent().objective().text.split("\n")
	current_goal.text="\n".join(goal_lines.slice(0,2))
	second_heading.text="旅人二 · 2P" if party.local_coop else "单人同行"
	second_controls.visible=party.local_coop
	if preload("res://scripts/mobile_platform.gd").active():
		first_controls.text="左侧摇杆　前后左右\n跳跃　越过障碍\n操作　按住完成劳作\n交谈　与附近人物交谈\n换人　轮换自己的同行\n点按场景中的碑和器物"
		second_controls.text="右侧摇杆　前后左右\n右侧跳跃　越过障碍\n右侧操作　按住共同劳作\n右侧交谈　与附近人物交谈\n右侧换人　轮换自己的同行\n两人可同时按住各自操作"
		footer_help.text="右上可查看包裹、共生见闻和声音设置。\n点按器物进入小艺；点按或拖动完成对应手艺。\n碑面：点字拿起，点旋转调方向，再点凹槽放下；再点空白放回。\n双人传拓：分别按住两侧合拓；回到手机桌面会自动暂停。"
	var lines: Array[String] = []
	for slot in range(2 if party.local_coop else 1):
		var names: Array[String] = []
		for role in party.roles_for_player(slot): names.append(party.NAMES[role])
		lines.append("%dP 专属　%s" % [slot + 1, "、".join(names)])
	pairs.text = "\n".join(lines)
	visible = true


func _label(parent: Control, at: Vector2, dimensions: Vector2, size: int, words: String, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.text = words
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if size>=18: label.add_theme_font_override("font",UiStyle.heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label
