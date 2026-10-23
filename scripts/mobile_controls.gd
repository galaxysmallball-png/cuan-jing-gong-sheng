extends CanvasLayer

const Platform=preload("res://scripts/mobile_platform.gd")
const UiSkin=preload("res://scripts/interface_skin.gd")
var world: Node3D
var surface: Control
var mode_button: Button
var help_button: Button
var rotate_button: Button
var task_label: Label
var fingers: Dictionary={}
var held: Dictionary={}
var sticks: Array[Vector2]=[Vector2.ZERO,Vector2.ZERO]
var context: String=""
var controls: Array[Dictionary]=[]

func setup(owner_world: Node3D) -> void:
	name="MobileControls"
	world=owner_world
	get_tree().quit_on_go_back=false
	layer=28
	process_mode=Node.PROCESS_MODE_ALWAYS
	surface=Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	surface.draw.connect(_draw)
	task_label=Label.new()
	task_label.position=Vector2(24,134)
	task_label.size=Vector2(500,72)
	task_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	task_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	task_label.add_theme_font_override("font",UiSkin.body_font())
	task_label.add_theme_font_size_override("font_size",17)
	task_label.add_theme_color_override("font_color",Color(.96,.88,.70))
	task_label.add_theme_color_override("font_outline_color",Color(.035,.055,.05,.9))
	task_label.add_theme_constant_override("outline_size",4)
	add_child(task_label)
	mode_button=_button(Vector2(905,650),Vector2(340,48),"",_change_mode)
	help_button=_button(Vector2(548,22),Vector2(128,40),"行旅帮助",func(): world.get_node("PartyUI")._toggle_hint())
	rotate_button=_button(Vector2(1098,650),Vector2(160,48),"旋 转",func(): world.cooperation.rotate_selected())

func _button(at: Vector2,dimensions: Vector2,text: String,callback: Callable) -> Button:
	var button:=Button.new()
	button.position=at
	button.size=dimensions
	button.text=text
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_override("font",UiSkin.heading_font())
	button.add_theme_font_size_override("font_size",UiSkin.text_size(18))
	UiSkin.button(button)
	button.pressed.connect(callback)
	add_child(button)
	return button

func _change_mode() -> void:
	Platform.cooperative=not Platform.cooperative
	_release_all()
	get_tree().paused=false
	get_tree().reload_current_scene()

func _get_context() -> String:
	var ui: CanvasLayer=world.get_node("PartyUI")
	if ui.screen!=ui.Screen.GAME or get_tree().paused or world.story.frame.visible or world.courtyard.record_open or world.courtyard.tablet_arriving or world.courtyard.tablet_raising: return ""
	if world.cooperation.inspected_id==0 and not world.cooperation.inspector.lore_open:
		return "rubbing" if not world.cooperation.inspector.rubbing.completed else "glyphs"
	if world.cooperation.inspected_id>=0: return ""
	return "walking"

func _process(_delta: float) -> void:
	var ui: CanvasLayer=world.get_node("PartyUI")
	world.experience.coach.visible=false
	world.experience.coach_tab.visible=false
	mode_button.visible=ui.screen==ui.Screen.TITLE
	mode_button.text="双人同屏 · 点击改单人" if world.party.local_coop else "单人触屏 · 点击改双人"
	help_button.visible=ui.screen==ui.Screen.GAME and not world.courtyard.record_open and world.cooperation.inspected_id<0
	var next_context: String=_get_context()
	if context!=next_context:
		_release_all()
		context=next_context
		_build_controls()
	rotate_button.visible=context=="glyphs" and world.cooperation.selected_tile>=0
	task_label.visible=context=="walking"
	if context=="walking":
		var lines: PackedStringArray=world.objective().text.split("\n")
		task_label.text="\n".join(lines.slice(0,2)).replace("按 B","点右上包裹")
		ui.goal_panel.visible=false
		if world.guidance!=null:
			for card in world.guidance.cards: card.visible=false
	# Dialogue's own touch button stays usable above the controls.
	if world.story.frame.visible:
		world.story.next_button.text="续话"
		world.story.next_button.custom_minimum_size=Vector2(150,46)
		world.story.next_button.size=Vector2(150,46)
		world.story.next_button.position=world.story.frame.size-Vector2(166,58)
	surface.queue_redraw()

func _build_controls() -> void:
	controls.clear()
	if context.is_empty(): return
	if context in ["rubbing","glyphs"]:
		for slot in range(2 if world.party.local_coop else 1):
			controls.append({"kind":"interact","slot":slot,"at":Vector2(91 if slot==0 else 1189,576),"radius":45.0,"text":"合拓" if context=="rubbing" else "分享"})
			controls.append({"kind":"cycle","slot":slot,"at":Vector2(91 if slot==0 else 1189,480),"radius":32.0,"text":"换人"})
		return
	for slot in range(2 if world.party.local_coop else 1):
		var dual: bool=world.party.local_coop
		var center:=Vector2(96 if slot==0 else 1184,586) if dual else Vector2(145,580)
		controls.append({"kind":"stick","slot":slot,"at":center,"radius":60.0 if dual else 76.0,"text":""})
		var base: float=395 if slot==0 else 885
		var inner: float=300 if slot==0 else 980
		controls.append({"kind":"interact","slot":slot,"at":Vector2(base,610) if dual else Vector2(1150,570),"radius":40.0 if dual else 48.0,"text":"操作"})
		controls.append({"kind":"jump","slot":slot,"at":Vector2(inner,650) if dual else Vector2(1028,630),"radius":31.0 if dual else 36.0,"text":"跳跃"})
		controls.append({"kind":"cycle","slot":slot,"at":Vector2(base,514) if dual else Vector2(1150,468),"radius":30.0 if dual else 33.0,"text":"换人"})
		controls.append({"kind":"talk","slot":slot,"at":Vector2(inner,548) if dual else Vector2(1028,528),"radius":30.0 if dual else 33.0,"text":"交谈"})

func _draw() -> void:
	for control in controls:
		var at: Vector2=control.at
		var radius: float=control.radius
		var tint: Color=Color(.90,.72,.43,.78) if control.slot==0 else Color(.48,.79,.82,.78)
		surface.draw_circle(at,radius,Color(.035,.055,.055,.57))
		surface.draw_arc(at,radius,0,TAU,48,tint,2,true)
		if control.kind=="stick":
			surface.draw_line(at-Vector2(radius*.63,0),at+Vector2(radius*.63,0),Color(1,1,1,.13),1,true)
			surface.draw_line(at-Vector2(0,radius*.63),at+Vector2(0,radius*.63),Color(1,1,1,.13),1,true)
			surface.draw_circle(at+sticks[control.slot]*radius*.68,radius*.36,Color(tint,.68))
		else:
			if control.kind=="interact" and context=="walking" and world.guidance!=null:
				var progress: Dictionary=world.guidance.progress_for(world.party.human_players()[control.slot])
				if not progress.is_empty() and progress.ratio>0:
					surface.draw_arc(at,radius+6,-PI/2,-PI/2+TAU*progress.ratio,48,tint,4,true)
			var font: Font=UiSkin.heading_font()
			var size: int=19
			var width: float=font.get_string_size(control.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
			surface.draw_string(font,at+Vector2(-width/2,7),control.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(.97,.89,.72))
	if context=="walking":
		var title: String=world.party.NAMES[world.party.active_id]
		if world.party.local_coop: title+="   ·   "+world.party.NAMES[world.party.second_id]
		surface.draw_string(UiSkin.heading_font(),Vector2(24,116),title,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color(.94,.83,.60))

func blocks(at: Vector2) -> bool:
	for control in controls:
		if at.distance_to(control.at)<=control.radius+10: return true
	return false

func _input(event: InputEvent) -> void:
	# Godot also emulates mouse events for the primary touch. Consume those over
	# the pads so the same finger cannot click scenery or a panel underneath.
	if event is InputEventMouseButton and blocks(event.position):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if not event.pressed:
			if fingers.has(event.index):
				_release_finger(event.index)
				get_viewport().set_input_as_handled()
			return
		for control in controls:
			if event.position.distance_to(control.at)>control.radius+10: continue
			# One owner per control prevents an extra finger from releasing another.
			if fingers.values().any(func(other): return other.kind==control.kind and other.slot==control.slot): return
			fingers[event.index]=control
			if control.kind=="stick": _move_stick(control,event.position)
			elif control.kind=="cycle": world.party.cycle(control.slot)
			elif control.kind=="talk": _talk(control.slot)
			else: _action(control.slot,control.kind,1)
			get_viewport().set_input_as_handled()
			return
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var control: Dictionary=fingers[event.index]
		if control.kind=="stick": _move_stick(control,event.position)
		elif event.position.distance_to(control.at)>control.radius+36: _release_finger(event.index)
		get_viewport().set_input_as_handled()

func _talk(slot: int) -> void:
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_F if slot==0 else KEY_SLASH
	key.pressed=true
	Input.parse_input_event(key)
	key=key.duplicate()
	key.pressed=false
	Input.parse_input_event.call_deferred(key)

func _move_stick(control: Dictionary,at: Vector2) -> void:
	var direction: Vector2=((at-control.at)/control.radius).limit_length()
	if direction.length()<.18: direction=Vector2.ZERO
	sticks[control.slot]=direction
	_action(control.slot,"move_left",maxf(0,-direction.x))
	_action(control.slot,"move_right",maxf(0,direction.x))
	_action(control.slot,"move_forward",maxf(0,-direction.y))
	_action(control.slot,"move_back",maxf(0,direction.y))

func _action(slot: int,kind: String,strength: float) -> void:
	var action: String=("p2_" if slot==1 else "")+kind
	if strength>.01:
		held[action]=true
		Input.action_press(action,strength)
	else:
		held.erase(action)
		Input.action_release(action)

func _release_finger(index: int) -> void:
	var control: Dictionary=fingers[index]
	if control.kind=="stick": _move_stick(control,control.at)
	elif control.kind in ["jump","interact"]: _action(control.slot,control.kind,0)
	fingers.erase(index)

func _release_all() -> void:
	for action in held: Input.action_release(action)
	held.clear()
	fingers.clear()
	sticks.assign([Vector2.ZERO,Vector2.ZERO])

func _exit_tree() -> void:
	_release_all()

func _notification(what: int) -> void:
	if world==null or not is_instance_valid(world) or not is_inside_tree(): return
	var ui: CanvasLayer=world.get_node("PartyUI")
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
		_release_all()
		if ui.screen==ui.Screen.GAME: ui._open_archive()
		elif ui.screen==ui.Screen.FILM and not ui.opening_film.player.paused: ui.opening_film.toggle_pause()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:
		_release_all()
		if ui.screen==ui.Screen.FILM: ui.opening_film.finish()
		elif world.courtyard.record_open: world.courtyard.close_record()
		elif world.cooperation.inspected_id>=0: world.cooperation.close_puzzle()
		elif ui.screen==ui.Screen.GAME: ui._toggle_hint()
		elif ui.screen==ui.Screen.HELP: ui._close_hint()
		elif ui.screen==ui.Screen.ARCHIVE: ui._close_archive()
		elif ui.screen==ui.Screen.SATCHEL: ui._close_satchel()
		elif ui.screen==ui.Screen.ACHIEVEMENTS: ui._close_achievements()
		elif ui.screen==ui.Screen.SETTINGS: ui._close_audio_settings()
		elif ui.screen==ui.Screen.INSPECT: world.folk.close()
		elif ui.screen==ui.Screen.DRAW: ui._cancel_draw()
		elif ui.screen in [ui.Screen.CULTURE,ui.Screen.INTRO]: ui._return_title()
		elif ui.screen==ui.Screen.TITLE: get_tree().quit()
