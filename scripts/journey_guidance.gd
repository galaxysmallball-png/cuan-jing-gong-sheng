extends CanvasLayer

const UiSkin=preload("res://scripts/interface_skin.gd")
var world: Node3D
var cards: Array[Panel]=[]
var names: Array[Label]=[]
var tasks: Array[Label]=[]
var bars: Array[ProgressBar]=[]


func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="JourneyGuidance"
	layer=13
	process_mode=Node.PROCESS_MODE_ALWAYS
	for slot in range(2):
		var card:=Panel.new()
		card.size=Vector2(292,74)
		card.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel",UiSkin.notice_paper())
		add_child(card)
		cards.append(card)
		var accent: Color=UiSkin.VERMILION if slot==0 else Color(.14,.34,.39)
		names.append(_label(card,Vector2(14,7),Vector2(264,24),13,accent,true))
		tasks.append(_label(card,Vector2(14,34),Vector2(264,24),13,UiSkin.INK))
		var bar:=ProgressBar.new()
		bar.position=Vector2(16,65)
		bar.size=Vector2(260,3)
		bar.max_value=1
		bar.show_percentage=false
		bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var track:=StyleBoxFlat.new()
		track.bg_color=Color(.22,.25,.21,.15)
		var fill:=StyleBoxFlat.new()
		fill.bg_color=accent
		bar.add_theme_stylebox_override("background",track)
		bar.add_theme_stylebox_override("fill",fill)
		card.add_child(bar)
		bar.size.y=3
		bars.append(bar)
		card.visible=false


func _label(parent: Control, at: Vector2, dimensions: Vector2, px: int, tint: Color, heading: bool=false) -> Label:
	var label:=Label.new()
	label.position=at
	label.size=dimensions
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",UiSkin.heading_font() if heading else UiSkin.body_font())
	label.add_theme_font_size_override("font_size",UiSkin.text_size(px))
	label.add_theme_color_override("font_color",tint)
	parent.add_child(label)
	return label


func _process(_delta: float) -> void:
	for card in cards: card.visible=false
	var ui: CanvasLayer=world.get_node("PartyUI")
	if not world.party.started or ui.screen!=ui.Screen.GAME or get_tree().paused or world.courtyard.record_open or world.cooperation.inspected_id>=0 or world.story.frame.visible or world.courtyard.tablet_arriving or world.courtyard.tablet_raising: return
	var visible_slots: Array[int]=[]
	for slot in range(world.party.human_players().size()):
		var body: CharacterBody3D=world.party.human_players()[slot]
		var data: Dictionary=progress_for(body)
		if data.is_empty(): continue
		names[slot].text="%dP · %s"%[slot+1,world.party.NAMES[body.character_id]]
		tasks[slot].text="%s  %d%%"%[data.text,roundi(data.ratio*100)]
		bars[slot].value=data.ratio
		cards[slot].visible=true
		visible_slots.append(slot)
	for index in range(visible_slots.size()):
		cards[visible_slots[index]].position=Vector2(964,698-(visible_slots.size()-index)*80)


func progress_for(body: CharacterBody3D) -> Dictionary:
	if not body.is_on_floor() or world.party.planar_speed(body)>.15 or not Input.is_action_pressed(body.action("interact")): return {}
	var role: int=body.character_id
	var bridge: Node3D=world.bridge
	var court: Node3D=world.courtyard
	if bridge._timber_progress>0 and role==2 and world.party.at_station(body,24,1.2): return _progress("备木捆扎",bridge._timber_progress,1.6)
	if bridge.step==5:
		if bridge.steady_held and role==1: return _progress("顶碑护稳",bridge.action_progress,bridge.RESCUE_SECONDS)
		if bridge.rope_held and role==2: return _progress("收放绳索",bridge.action_progress,bridge.RESCUE_SECONDS)
	if bridge.action_progress>0 and bridge._holding_role==role:
		return _progress(["认水痕","辨旧路","稳固石墩","联络村民","合力架桥","护稳石碑"][mini(bridge.step,5)],bridge.action_progress,bridge.RESCUE_SECONDS if bridge.step==5 else 1.6)
	if court.action_progress>0 and not court.tablet_placed and world.party.at_station(body,50,1.6): return _progress("合力扶碑",court.action_progress,court.lighting_hold_seconds)
	for index in range(7):
		var owner: int=index if index<4 else court.oil_carriers[index-4]
		if owner==role and court.item_progress[index]>0 and world.party.at_station(body,40+court.ITEM_POSITIONS[index]): return _progress(court.ITEMS[index],court.item_progress[index],court.lighting_hold_seconds)
	return {}


func _progress(text: String, amount: float, duration: float) -> Dictionary:
	return {"text":text,"ratio":clampf(amount/duration,0,1)}


func blocks_world_click(at: Vector2) -> bool:
	for card in cards:
		if card.visible and card.get_global_rect().has_point(at): return true
	return false
