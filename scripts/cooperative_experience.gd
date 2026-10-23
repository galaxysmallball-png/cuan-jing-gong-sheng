extends CanvasLayer

const UiSkin = preload("res://scripts/interface_skin.gd")
const Art = preload("res://scripts/folk_activity_art.gd")
const DESIGNS: Array[String] = ["赭金菱纹","蓝白花叶","靛蓝回旋"]
const MOTIFS: Array[int] = [2,0,1]
var world: Node3D
var coach: Panel
var coach_title: Label
var coach_words: Label
var coach_action: Button
var coach_tab: Button
var coach_hidden: bool = false
var rope_coach_expanded: bool = false
var coach_stage: String = ""
var moved: Array[bool] = [false,false]
var jumped: Array[bool] = [false,false]
var starting_positions: Array[Vector3] = []
var rope_panel: Panel
var rope_words: Label
var gauge: Control
var overlay: Control
var design_panel: Panel
var design_cards: Array[Panel] = []
var choice_buttons: Array[Array] = []
var confirm_buttons: Array[Button] = []
var design_headers: Array[Label] = []
var choices: Array[int] = [1,0]
var confirmed: Array[bool] = [false,false]
var design_done: bool = false
var auto_offered: bool = false
var first_walk_finished: bool=false
var solo_side: int = 0


func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="CooperativeExperience"
	layer=14
	process_mode=Node.PROCESS_MODE_ALWAYS
	coach=_panel(self,Vector2(24,120),Vector2(352,162))
	coach_title=_label(coach,Vector2(18,12),Vector2(316,28),19,"同行小引",true)
	coach_words=_label(coach,Vector2(18,46),Vector2(316,68),15,"")
	coach_action=_button(coach,Vector2(18,119),Vector2(190,31),"查看操作 · H",_coach_action)
	_button(coach,Vector2(220,119),Vector2(112,31),"收起引导",func(): coach_hidden=true)
	coach_tab=_button(self,Vector2(24,120),Vector2(125,31),"同行引导",restore_coach)
	rope_panel=_panel(self,Vector2(430,78),Vector2(420,123))
	_label(rope_panel,Vector2(18,8),Vector2(384,27),19,"扶碑与收放绳",true)
	gauge=preload("res://scripts/cooperative_art.gd").new()
	gauge.position=Vector2(18,40)
	gauge.size=Vector2(384,25)
	gauge.chapter=world.bridge
	rope_panel.add_child(gauge)
	rope_words=_label(rope_panel,Vector2(18,73),Vector2(384,45),14,"")
	_build_designer()
	coach.visible=false
	coach_tab.visible=false
	rope_panel.visible=false


func _panel(parent: Node, at: Vector2, dimensions: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position=at
	panel.size=dimensions
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",UiSkin.notice_paper())
	parent.add_child(panel)
	var reading := ColorRect.new()
	reading.position=Vector2(12,10)
	reading.size=dimensions-Vector2(24,20)
	reading.color=Color(.97,.92,.80,.92)
	reading.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(reading)
	return panel


func _label(parent: Node, at: Vector2, dimensions: Vector2, px: int, text: String, heading: bool=false) -> Label:
	var label := Label.new()
	label.position=at
	label.size=dimensions
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",UiSkin.heading_font() if heading else UiSkin.body_font())
	label.add_theme_font_size_override("font_size",UiSkin.text_size(px))
	label.add_theme_color_override("font_color",UiSkin.VERMILION if heading else UiSkin.INK)
	parent.add_child(label)
	return label


func _button(parent: Node, at: Vector2, dimensions: Vector2, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.position=at
	button.size=dimensions
	button.text=text
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size",UiSkin.text_size(14))
	UiSkin.notice_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _build_designer() -> void:
	overlay=Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color(0,0,0,.12)
	overlay.add_child(shade)
	design_panel=_panel(overlay,Vector2(120,330),Vector2(1040,365))
	_label(design_panel,Vector2(24,12),Vector2(990,35),25,"合织共庭 · 把各自的色彩留在一起",true)
	_label(design_panel,Vector2(24,53),Vector2(990,32),16,"先试配，再各自确认。左、右两组彩幔随选择变化，中幅合用两人的纹样。")
	for slot in range(2):
		var card: Panel = _panel(design_panel,Vector2(24+slot*504,92),Vector2(488,211))
		design_cards.append(card)
		design_headers.append(_label(card,Vector2(15,7),Vector2(450,27),17,"%dP · 选一幅纹样"%(slot+1),true))
		var row: Array = []
		for index in range(3):
			var icon := preload("res://scripts/cooperative_art.gd").new()
			icon.kind=index
			icon.position=Vector2(18+index*153,34)
			icon.size=Vector2(144,78)
			icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(icon)
			var choice: Button = _button(card,Vector2(18+index*153,117),Vector2(140,34),DESIGNS[index],func(): select_design(slot,index))
			row.append(choice)
		choice_buttons.append(row)
		confirm_buttons.append(_button(card,Vector2(18,164),Vector2(449,34),"确认这幅",func(): confirm_design(slot)))
	_label(design_panel,Vector2(24,317),Vector2(804,42),14,"1P：A / D 试配，E 确认；2P：← / → 试配，P 确认。单人依次完成两幅。")
	_button(design_panel,Vector2(875,317),Vector2(140,34),"稍后再选 · Esc",close_design)
	overlay.visible=false


func _process(_delta: float) -> void:
	var ui: CanvasLayer = world.get_node("PartyUI")
	var gameplay: bool = world.party.started and ui.screen==ui.Screen.GAME and not get_tree().paused and not world.courtyard.record_open and not world.courtyard.tablet_arriving and not world.courtyard.tablet_raising and world.courtyard.raise_focus_left<=0
	if world.party.started and starting_positions.is_empty():
		for body in world.party.human_players(): starting_positions.append(body.global_position)
	if gameplay:
		for slot in range(world.party.human_players().size()):
			var body: CharacterBody3D = world.party.human_players()[slot]
			if body.global_position.distance_to(starting_positions[slot])>.8: moved[slot]=true
			if body.velocity.y>1: jumped[slot]=true
		_update_coach()
		if not first_walk_finished and moved[0] and (not world.party.local_coop or moved[1]):
			first_walk_finished=true
			coach_hidden=true
	var rope_phase: bool = world.current_space==1 and world.bridge.step==5
	coach.visible=gameplay and (not coach_hidden or coach_stage=="design") and world.cooperation.inspected_id<0 and (not rope_phase or rope_coach_expanded)
	coach_tab.visible=gameplay and not coach.visible and world.cooperation.inspected_id<0
	rope_panel.visible=gameplay and world.current_space==1 and world.bridge.step==5
	if rope_panel.visible:
		rope_panel.position=Vector2(400,120) if coach.visible else Vector2(24,160)
		var bridge: Node3D = world.bridge
		gauge.queue_redraw()
		var state: String = "张力合适" if bridge.tension_safe else "太紧，松开操作键" if bridge.rope_tension>.72 else "太松，按住操作键收绳"
		if world.party.local_coop:
			if not bridge.steady_held: state="石阿朵先在桥心按住顶碑"
			elif not bridge.rope_at_post: state="老箐先到右岸木桩停稳"
			elif world.party.nearby_count(35)!=4: state="等其余同行靠近桥心"
			var support_key: String = "1P E" if world.party.owner_of(1)==0 else "2P P"
			var rope_key: String = "1P E" if world.party.owner_of(2)==0 else "2P P"
			rope_words.text="%s · 护稳 %d%%\n顶碑 %s 按住；牵绳 %s 按 / 放。"%[state,int(bridge.action_progress/bridge.RESCUE_SECONDS*100),support_key,rope_key]
		else: rope_words.text="同行协助牵绳 · 护稳 %d%%\n你在桥心按住 E，等碑身平稳。"%int(bridge.action_progress/bridge.RESCUE_SECONDS*100)
	if gameplay and world.current_space==2 and world.courtyard.tablet_placed and world.courtyard.personal_items_done() and not design_done:
		if not auto_offered:
			auto_offered=true
			open_design.call_deferred()
		else:
			for body in world.party.human_players():
				if world.party.at_station(body,43.7) and Input.is_action_just_pressed(body.action("interact")): open_design.call_deferred()


func _update_coach() -> void:
	var first: Node3D = world.cooperation
	var bridge: Node3D = world.bridge
	var court: Node3D = world.courtyard
	coach_action.text="查看操作 · H"
	if world.current_space==0:
		if not moved[0] or (world.party.local_coop and not moved[1]):
			coach_stage="walk"
			coach_title.text="① 先和同伴走几步"
			coach_words.text="1P：WASD；2P：方向键。\n空格 / 小键盘Enter 跳跃。前后绕行，\n一起向右找到小爨碑。"
			if not world.party.local_coop: coach_words.text="WASD 前后左右，空格跳跃。三位同伴会跟随你，一起向右找到小爨碑。"
		else:
			coach_stage="read"
			coach_title.text="② 先传拓，再合读"
			coach_words.text="点小爨碑，先合作拓字。\n覆纸、扑墨、揭纸后，四人分享。\nTab / 右Shift 换自己的同行。"
			if not world.party.local_coop: coach_words.text="点小爨碑，依次覆纸、扑墨、揭纸。取拓后用 E 分享见闻、Tab 换人，再合读六字。"
		if first.gate_open:
			coach_stage="exit"
			coach_title.text="碑文已合 · 一起向右"
			coach_words.text="拓片由邓书年拾，錾子由石阿朵拾。\n切换本人，走近按 E / P 或点击。\n按 B 翻看随身物件。"
	elif world.current_space==1:
		coach_stage="rope" if bridge.step==5 else "creek"
		coach_title.text="③ 一人顶碑，一人收放绳" if bridge.step==5 else "古道分工 · 看当前一步"
		coach_words.text="桥心：石阿朵按住操作键顶碑。\n右岸：老箐按下收绳、松开放绳。\n让张力留在绿色区。" if bridge.step==5 else "跟随左下任务备木修桥。\n老箐拾马铃，杨三娘拾红线。\n切换本人拾取，按 B 查看。"
		if bridge.step==5 and not world.party.local_coop: coach_words.text="走到桥心按住 E 扶碑。其余同行管理绳索，等他们靠近、碑身平稳后继续送往右岸。"
	else:
		coach_stage="design" if court.personal_items_done() and not design_done else "court"
		coach_title.text="④ 一起定下院子的颜色" if coach_stage=="design" else "共庭 · 让物件留下来"
		coach_words.text="各选一幅纹样，再各自确认。\n结果留在院中彩幔和档案里。\n可以先试配，确认后再送灯。" if coach_stage=="design" else "碑落座后，各放随身物件。\n合织彩幔，再分头送三盏灯。\n七灯亮起，一起去右廊看长卷。"
		if design_done: coach_words.text="共同选择的彩幔已挂在院中。\n到灯桌取灯，分头安放三盏灯。\n七灯亮起，再到右廊共看长卷。"
		if world.keepsakes!=null and false in world.keepsakes.collected:
			coach_words.text="物件要先在前两关拾取。\n按 B 翻随身物件，查看散落处。\n可沿来路返回，收好再入院归位。"
		if coach_stage=="design": coach_action.text="一起布置彩幔"


func _coach_action() -> void:
	if coach_stage=="design": open_design()
	else: world.get_node("PartyUI")._toggle_hint()


func restore_coach() -> void:
	coach_hidden=false
	rope_coach_expanded=world.current_space==1 and world.bridge.step==5


func blocks_world_click(at: Vector2) -> bool:
	if overlay.visible: return true
	for control in [coach,coach_tab,rope_panel]:
		if control.visible and control.get_global_rect().has_point(at): return true
	return false


func open_design() -> void:
	var ui: CanvasLayer = world.get_node("PartyUI")
	if design_done or overlay.visible or ui.screen!=ui.Screen.GAME or not world.courtyard.tablet_placed or not world.courtyard.personal_items_done(): return
	auto_offered=true
	ui.screen=ui.Screen.ARRANGE
	get_tree().paused=true
	overlay.visible=true
	_sync_design()
	_apply_design()
	ui._refresh()


func close_design() -> void:
	if not overlay.visible: return
	overlay.visible=false
	var ui: CanvasLayer = world.get_node("PartyUI")
	ui.screen=ui.Screen.GAME
	ui._satchel_input_frame=Engine.get_process_frames()
	get_tree().paused=false
	ui._refresh()


func select_design(slot: int, index: int) -> void:
	if not overlay.visible or confirmed[slot]: return
	choices[slot]=posmod(index,3)
	world.sfx.play("cloth")
	_apply_design()
	_sync_design()


func confirm_design(slot: int) -> void:
	if not overlay.visible: return
	world.sfx.play("button")
	confirmed[slot]=not confirmed[slot]
	if not world.party.local_coop and confirmed[slot]: solo_side=1-slot
	_sync_design()
	if not false in confirmed:
		design_done=true
		world.sfx.play("cloth")
		close_design()
		world.courtyard.landscape.say("玉喃","两幅各有色彩，中间这一幅，便让它们合在一起。再把三盏油灯送出去吧。",6,true)


func _sync_design() -> void:
	for slot in range(2):
		design_headers[slot].text="%dP · 选一幅纹样"%(slot+1) if world.party.local_coop else ("左幅" if slot==0 else "右幅")+" · 依次试配确认"
		for index in range(3):
			choice_buttons[slot][index].text=DESIGNS[index]+(" · 已选" if choices[slot]==index else "")
			choice_buttons[slot][index].disabled=confirmed[slot]
			choice_buttons[slot][index].modulate=Color(1,.77,.46) if choices[slot]==index else Color.WHITE
		confirm_buttons[slot].text="已确认：%s · 点击可调整"%DESIGNS[choices[slot]] if confirmed[slot] else ("%dP 确认 · %s"%[slot+1,"E" if slot==0 or not world.party.local_coop else "P"])


func _apply_design() -> void:
	for cloth: MeshInstance3D in get_tree().get_nodes_in_group("shared_court_cloths"):
		var index: int = cloth.get_meta("cloth_index")
		var motif: int = MOTIFS[choices[0 if index<3 else 1]]
		if index==3: motif=MOTIFS[choices[0]]
		cloth.material_override.set_shader_parameter("motif",motif)
		cloth.material_override.set_shader_parameter("partner_motif",MOTIFS[choices[1]] if index==3 else -1)


func handle_design_input(event: InputEvent) -> void:
	if not overlay.visible or not event is InputEventKey: return
	if event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode!=0 else event.keycode
		if code==KEY_ESCAPE: close_design()
		elif code in [KEY_A,KEY_D]:
			var side: int = 0 if world.party.local_coop else solo_side
			select_design(side,choices[side]+(-1 if code==KEY_A else 1))
		elif code==KEY_E: confirm_design(0 if world.party.local_coop else solo_side)
		elif world.party.local_coop and code in [KEY_LEFT,KEY_RIGHT]: select_design(1,choices[1]+(-1 if code==KEY_LEFT else 1))
		elif world.party.local_coop and code in [KEY_P,KEY_KP_0]: confirm_design(1)
	get_viewport().set_input_as_handled()


func reset_from(chapter: int) -> void:
	close_design()
	design_done=false
	auto_offered=false
	choices.assign([1,0])
	confirmed.assign([false,false])
	solo_side=0
	# Restore the original seven panels until the players choose their own.
	for cloth: MeshInstance3D in get_tree().get_nodes_in_group("shared_court_cloths"):
		cloth.material_override.set_shader_parameter("motif",int(cloth.get_meta("cloth_index"))%3)
		cloth.material_override.set_shader_parameter("partner_motif",-1)
	if chapter==0:
		rope_coach_expanded=false
		starting_positions.clear()
		moved.assign([false,false])
		jumped.assign([false,false])
		first_walk_finished=false


func design_summary() -> String:
	return DESIGNS[choices[0]]+"与"+DESIGNS[choices[1]]+"合织共庭" if design_done else "庭院合织尚未完成"


