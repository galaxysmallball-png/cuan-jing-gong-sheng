extends "res://scripts/party_chapter.gd"

signal courtyard_completed
@export var warm_light_energy: float = 2.8
@export var lighting_hold_seconds: float = 1.6
@export var light_spread_seconds: float = 2.4
const LAMP_ROLES: Array[int] = [0, 1, 2, 3, -1, -1, -1]
const ITEMS: Array[String] = ["拓片上墙", "錾子入架", "屋檐马铃", "保护架红线", "院门油灯", "石阶油灯", "碑亭侧灯"]
const ITEM_POSITIONS: Array[float] = [6.2, 9.0, 11.7, 12.8, 2.2, 5.0, 15.5]
# The stele stands on the shrine's centre line, not offset to one side: the
# concept board reads the courtyard as a single axis (gate, stele, hall plaque).
const SHRINE_AXIS_X: float = 10.0
const PLACEMENT_X: float = SHRINE_AXIS_X
const SUPPLY_X: float = 3.7
var tablet_placed: bool = false
var rest_stands: Node3D
var tablet_arriving: bool = false
var tablet_raising: bool = false
var raise_progress: float = 0
var raise_focus_left: float = 0
var raise_rig: Node3D
const RAISE_SECONDS: float = 4.8
var arrival_elapsed: float = 0
var arrival_from := Vector3.ZERO
const ARRIVAL_SECONDS: float = 6.4
const FRAME_REST_Y: float=.78
const TABLET_FRAME_OFFSET: float=.49
const FLAT_REST_Y: float=FRAME_REST_Y+TABLET_FRAME_OFFSET
var lamp_count: int = 0
var court_lit: bool = false
var closing: bool = false
var record_open: bool = false
var items_done: Array[bool] = [false, false, false, false, false, false, false]
var item_progress: Array[float] = [0, 0, 0, 0, 0, 0, 0]
# Oil lamps are claimed by character identity, so changing controllers never duplicates them.
var oil_carriers: Array[int] = [-1, -1, -1]
var landscape: Node3D
var _arrival_sled: Node3D
var carry_rig: Node3D
var _tablet: MeshInstance3D
var _lamps: Array[Node3D] = []
var _tween: Tween
var _raise_tween: Tween
var _entered: bool = false
@onready var first: Node3D = get_node("../../Space01/Cooperation")
@onready var bridge: Node3D = get_node("../../Space02/BridgeCooperation")
@onready var warm_light: OmniLight3D = $"../WarmLight"


func _ready() -> void:
	for path in ["Keeper", "LampStand", "Fixtures", "LightingHandle", "PlacementMarker", "BenchA", "BenchB", "EndingScroll"]:
		get_node(path).visible = false
	$LampStand/Collision.disabled = true
	for path in ["Floor/Mesh", "BackWall", "PillarA", "PillarB"]:
		get_node("../" + path).visible = false
	# The back wall is (0.40, 0.41, 0.34); a stele in that range disappears into
	# it. The face is therefore lifted well above the wall and the cap and plinth
	# dropped below it, so the silhouette reads at a glance.
	_tablet = Props.box(self, Vector3(PLACEMENT_X, 1.0, -1.8), Vector3(1.1, 2.4, 0.42), Color(0.63, 0.64, 0.58))
	Props.box(_tablet, Vector3(0, 1.24, 0), Vector3(1.30, 0.18, 0.42), Color(0.28, 0.30, 0.28))
	Props.box(_tablet, Vector3(0, -1.14, 0), Vector3(1.26, 0.14, 0.46), Color(0.26, 0.28, 0.26))
	_arrival_sled=Node3D.new()
	_arrival_sled.name="IncomingCarryingFrame"
	add_child(_arrival_sled)
	for z in [-.38,.38]:
		Props.box(_arrival_sled,Vector3(0,0,z),Vector3(2.7,.14,.13),Color(.30,.19,.10))
	for x in [-1.0,-.5,0,.5,1.0]:
		Props.box(_arrival_sled,Vector3(x,.10,0),Vector3(.31,.12,.94),Color(.43,.29,.15))
	Props.box(_arrival_sled,Vector3(0,.19,0),Vector3(2.18,.09,.82),Color(.56,.50,.34))
	rest_stands=Node3D.new()
	rest_stands.name="CarryingFrameRestTrestles"
	add_child(rest_stands)
	for x in [-.85,.85]:
		for z in [-.31,.31]:
			Props.box(rest_stands,Vector3(PLACEMENT_X+x,.60,-1.8+z),Vector3(.12,.22,.16),Color(.31,.22,.13))
		Props.box(rest_stands,Vector3(PLACEMENT_X+x,.69,-1.8),Vector3(.18,.05,.84),Color(.39,.27,.14))
	landscape = preload("res://scripts/garden_art.gd").new()
	add_child(landscape)
	landscape.setup(self)
	reset_lesson()


func _physics_process(delta: float) -> void:
	# Party reset positions runs earlier in the same tick. Release the carry rig
	# before it can overwrite those positions with its cinematic formation.
	if Input.is_action_just_pressed("restart_lesson"):
		reset_lesson()
		return
	if Input.is_action_just_pressed("restart") and tablet_arriving:
		_finish_arrival()
		return
	if Input.is_action_just_pressed("restart") and tablet_raising:
		if _raise_tween: _raise_tween.kill()
		if is_instance_valid(raise_rig): raise_rig.release_actors()
		_apply_raise(1)
		_finish_raising()
		return
	raise_focus_left=maxf(0,raise_focus_left-delta)
	rest_stands.visible=bridge.tablet_delivered and not tablet_placed and (not tablet_arriving or arrival_elapsed/ARRIVAL_SECONDS>.92)
	_tablet.visible = bridge.tablet_delivered
	if not bridge.tablet_delivered:
		_clear_carry()
		tablet_arriving=false
		arrival_elapsed=0
	if tablet_arriving and not tablet_placed and party.started:
		if not is_instance_valid(carry_rig):
			carry_rig=preload("res://scripts/stele_carry_rig.gd").new()
			add_child(carry_rig)
			carry_rig.setup(self)
		arrival_elapsed=minf(ARRIVAL_SECONDS,arrival_elapsed+delta)
		carry_rig.apply_pose(arrival_elapsed/ARRIVAL_SECONDS)
		if arrival_elapsed>=ARRIVAL_SECONDS:
			_finish_arrival()
		landscape.sync_state()
	if not tablet_raising and not tablet_arriving:
		_arrival_sled.visible=bridge.tablet_delivered and not tablet_placed
		_arrival_sled.position=Vector3(_tablet.position.x,_tablet.position.y-TABLET_FRAME_OFFSET,_tablet.position.z)
	if Input.is_action_just_pressed("restart") and record_open:
		close_record(false)
	if not party.started or not _previous_completed() or record_open:
		return
	if not _entered and player.global_position.x >= 40:
		_entered = true
		landscape.say("石阿朵", "碑从桥上送来了。先让它落到碑座，诸位在旁稳住。")
	if tablet_raising: return
	if not tablet_placed:
		if not tablet_arriving and bridge.tablet_delivered and _place_together(delta): _raise_tablet()
		return
	if court_lit or closing: return
	if personal_items_done() and not composition_ready(): return
	if personal_items_done(): _take_oil_lamps()
	action_progress = 0.0
	var completed: Array[int] = []
	for index in range(7):
		if items_done[index]: continue
		var held: bool = false
		if index < 4 or personal_items_done():
			for body in party.human_players():
				var permitted: bool = body.character_id == LAMP_ROLES[index] if index < 4 else oil_carriers[index - 4] == body.character_id
				if index<4 and not has_keepsake(index): permitted=false
				if permitted and _standing_hold(body, ITEM_POSITIONS[index]): held = true
		item_progress[index] = item_progress[index] + delta if held else 0.0
		action_progress = maxf(action_progress, item_progress[index])
		if item_progress[index] >= lighting_hold_seconds:
			_complete_item(index)
			completed.append(index)
	if not completed.is_empty() and not closing: _announce_items(completed)
	landscape.sync_state()


func _standing_hold(body: CharacterBody3D, local_x: float, radius: float = 0.88) -> bool:
	return not party.movement_locked() and body.is_on_floor() and party.planar_speed(body) < 0.15 \
		and party.at_station(body, global_position.x + local_x, radius) \
		and Input.is_action_pressed(body.action("interact"))


func _place_together(delta: float) -> bool:
	if not party.local_coop: return _hold(1, PLACEMENT_X, delta, lighting_hold_seconds)
	var helpers: int = 0
	var stoneworker: bool = false
	for body in party.human_players():
		if _standing_hold(body, PLACEMENT_X, 1.6):
			helpers += 1
			stoneworker = stoneworker or body.character_id == 1
	action_progress = action_progress + delta if helpers == 2 and stoneworker else 0.0
	return action_progress >= lighting_hold_seconds


func receive_tablet(from_world: Vector3) -> void:
	if tablet_placed or tablet_arriving: return
	arrival_from=to_local(from_world)
	arrival_from.x=clampf(arrival_from.x,-1.2,1.0)
	arrival_from.y=.50
	arrival_from.z=-.25
	arrival_elapsed=0
	tablet_arriving=true
	_tablet.position=arrival_from
	_tablet.rotation=Vector3(-PI/2,0,PI/2)
	_tablet.visible=true
	_arrival_sled.visible=true
	_arrival_sled.position=Vector3(_tablet.position.x,_tablet.position.y-TABLET_FRAME_OFFSET,_tablet.position.z)
	landscape.sync_state()


func _clear_carry() -> void:
	if is_instance_valid(carry_rig):
		carry_rig.release()
		carry_rig.queue_free()
	carry_rig=null


func _finish_arrival() -> void:
	_clear_carry()
	tablet_arriving=false
	arrival_elapsed=ARRIVAL_SECONDS
	_tablet.position=Vector3(PLACEMENT_X,FLAT_REST_Y,-1.8)
	_tablet.rotation=Vector3(-PI/2,0,PI/2)
	_arrival_sled.position=Vector3(PLACEMENT_X,FRAME_REST_Y,-1.8)
	landscape.say("石阿朵","一、二，放稳。碑已抬到碑座前，再合力慢慢扶起来。",4)


func _raise_tablet() -> void:
	if tablet_raising or tablet_placed: return
	tablet_arriving=false
	tablet_raising=true
	raise_progress=0
	action_progress=0
	raise_rig=preload("res://scripts/stele_raise_rig.gd").new()
	add_child(raise_rig)
	raise_rig.setup(self)
	party.set_interaction_lock(true)
	get_node("../../..").sfx.play("wood")
	landscape.say("石阿朵","先垫稳碑脚，绳子慢慢收。大家顺着我的号子，一点点扶起来。",5,true)
	_raise_tween=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_raise_tween.tween_method(_apply_raise,0.0,1.0,RAISE_SECONDS)
	_raise_tween.tween_callback(_finish_raising)
	landscape.sync_state()


func _apply_raise(progress: float) -> void:
	raise_progress=progress
	if is_instance_valid(raise_rig): raise_rig.apply_pose(progress)


func _finish_raising() -> void:
	tablet_raising=false
	tablet_placed=true
	raise_progress=1
	raise_focus_left=1.2
	_arrival_sled.visible=false
	party.set_interaction_lock(false)
	if is_instance_valid(raise_rig): raise_rig.dismantle()
	get_node("../../..").sfx.play("stone")
	landscape.say("杨三娘","碑脚落座了，稳稳当当。各人带来的物件，也有了共同的归处。",5,true)
	landscape.sync_state()


func personal_items_done() -> bool:
	return items_done[0] and items_done[1] and items_done[2] and items_done[3]


func has_keepsake(index: int) -> bool:
	var inventory: Node3D=get_node("../../..").keepsakes
	return inventory!=null and inventory.collected[index]


func composition_ready() -> bool:
	var experience: CanvasLayer = get_node("../../..").experience
	return experience==null or experience.design_done


func _take_oil_lamps() -> void:
	for body in party.human_players():
		if party.movement_locked() or not body.is_on_floor() or party.planar_speed(body) > 0.15 \
			or not party.at_station(body, global_position.x + SUPPLY_X, 1.0) \
			or not Input.is_action_just_pressed(body.action("interact")) or body.character_id in oil_carriers:
			continue
		for index in range(3):
			if not items_done[index + 4] and oil_carriers[index] < 0:
				oil_carriers[index] = body.character_id
				landscape.resident_work(1)
				landscape.say("玉喃", "灯柄已系好锦带。这盏送到" + ["院门", "石阶", "碑亭侧边"][index] + "，咱们一同把院子照亮。", 4)
				break


func _complete_item(index: int) -> void:
	items_done[index] = true
	item_progress[index] = 0.0
	lamp_count += 1
	if index >= 4: oil_carriers[index - 4] = -1
	warm_light.light_energy = lerpf(0.45, warm_light_energy, lamp_count / 7.0)
	if lamp_count == 7: _finish_court()


func _announce_items(indices: Array[int]) -> void:
	if lamp_count == 4 and personal_items_done():
		landscape.resident_work(0)
		landscape.say("普嫫", "物件已安顿妥当。把两幅纹样合着试配，给这座院子留下一份共同的颜色。", 6)
	elif indices.size() > 1:
		var placed: Array[String] = []
		for index in indices: placed.append(ITEMS[index])
		landscape.say("杨三娘", "、".join(placed) + "均已归位，灯也一同亮了。", 4)
	elif indices[0] < 4:
		var index: int = indices[0]
		landscape.say(party.NAMES[index], ["把所识之字留在此处，也让后来人看见。", "錾子已归架，石头也该歇一歇了。", "马铃挂在檐下。风一过，便知有人同行。", "红线系在保护架上，后来人便容易寻到。"][index])
	else:
		landscape.say("玉喃", ITEMS[indices[0]] + "已放稳，此处也有光了。", 3)


func _previous_completed() -> bool:
	return first.gate_open and bridge.gap_stabilized and bridge.tablet_delivered


func _finish_court() -> void:
	closing = true
	landscape.begin_scroll(light_spread_seconds)
	landscape.say("普嫫", "火点着了，就不散了。诸位到廊下，共看这一路。", 7)
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_interval(light_spread_seconds)
	_tween.finished.connect(func():
		court_lit = true
		closing = false
		courtyard_completed.emit()
	)


func show_record(lines: Array[String]) -> void:
	if record_open: return
	record_open = true
	party.set_interaction_lock(true)
	party.set_controls(false)
	landscape.open_record(lines)


func close_record(play_epilogue: bool=true) -> void:
	if not record_open: return
	var finished: bool=not landscape.record_cover_open and landscape.record_page==landscape.record_last_page()
	record_open = false
	landscape.close_record()
	party.set_interaction_lock(false)
	party.set_controls(true)
	if finished and play_epilogue:
		get_node("../../..").chapter_films.finish_scroll()


func _input(event: InputEvent) -> void:
	if not record_open or not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_ESCAPE: close_record()
		KEY_A, KEY_LEFT, KEY_PAGEUP: landscape.turn_record(-1)
		KEY_D, KEY_RIGHT, KEY_PAGEDOWN: landscape.turn_record(1)
		KEY_ENTER, KEY_SPACE:
			if landscape.record_page == landscape.record_last_page(): close_record()
			else: landscape.turn_record(1)
		_: return
	get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and event.physical_keycode == KEY_ENTER and not record_open \
		and court_lit and get_node("../../..").ending_reached and player.global_position.x >= 40:
		show_record(get_node("../../..").completed_actions)
		get_viewport().set_input_as_handled()


func get_hint() -> String:
	if not _previous_completed(): return "先在断溪古道扶稳碑体，再一起护送进院。\n石阿朵顶碑角，老箐在右岸拉绳。"
	if tablet_raising: return "绳索收紧，众人正将碑缓缓立起 %d%%。\n等碑脚落座，再安放随身物件。"%int(raise_progress*100)
	if tablet_arriving: return "四位同行正合抬石碑入院。\n到碑座前放稳后，再由石阿朵与同伴合力立碑。"
	if not tablet_placed:
		return "到院中碑座，石阿朵与另一位玩家站稳，同时按住各自操作键扶碑立正 %d%%。\n1P：E · 2P：P / 小键盘0 · 两人靠近碑座，先安稳，再点灯" % int(action_progress / lighting_hold_seconds * 100)
	if closing: return "七盏灯正在连成一片，长卷在院中展开。\n两位玩家一起走到右侧廊下，看看这段同行。"
	if court_lit: return "七灯共庭，物件都已有了归处。两位玩家一起到右侧廊下看长卷。\nF2 文化档案 · T 从头重玩"
	if not personal_items_done():
		var inventory: Node3D=get_node("../../..").keepsakes
		if inventory!=null and false in inventory.collected:
			return "尚未拾齐："+inventory.missing_names()+"。\n按 B 翻到随身物件，查看第一、二关的散落位置；沿来路可返回拾取。"
		return "随身物件可分头归位：邓书年拓片上墙、石阿朵錾子入架、老箐挂马铃、杨三娘系红线。\n到金色提示旁站稳，按住自己的操作键 · 已亮 %d / 7" % lamp_count
	if not composition_ready(): return "两位玩家一起试配庭院彩幔，各自确认一幅纹样。\n左上点「一起布置」，也可到灯桌按操作键继续；确认后再分头送灯。"
	var carrying: String = ""
	for index in range(3):
		if oil_carriers[index] >= 0:
			carrying += "%s → %s  " % [party.NAMES[oil_carriers[index]], ITEMS[index + 4]]
	return ("正在送灯：" + carrying if not carrying.is_empty() else "到入口物品台停下，按一次自己的操作键取油灯；任意角色都能送灯。") \
		+ "\n带灯到对应位置，按住操作键安放；两人可各送一盏 · 已亮 %d / 7" % lamp_count


func player_task(body: CharacterBody3D) -> Dictionary:
	if not _previous_completed(): return _task("先和同伴完成断溪救碑")
	if tablet_raising: return _task("合力立碑 %d%% · 等碑脚落座"%int(raise_progress*100),raise_progress*lighting_hold_seconds)
	if tablet_arriving: return _task("合抬入院 · 到碑座前放稳后合力立碑")
	if not tablet_placed:
		if party.local_coop:
			var has_stoneworker: bool = false
			for human in party.human_players(): has_stoneworker = has_stoneworker or human.character_id == 1
			if not has_stoneworker: return _task("请一位玩家切到石阿朵，再合力立碑")
		elif body.character_id != 1: return _task("切到石阿朵，去院中安放道具碑")
		var state: Dictionary = _task_at(body, PLACEMENT_X, "合力扶碑", action_progress, 1.6)
		if party.local_coop and _standing_hold(body, PLACEMENT_X, 1.6) and action_progress == 0:
			state.text = "已扶住 · 等同伴靠近并按住自己的操作键"
		return state
	if court_lit or closing:
		if get_node("../../..").ending_reached: return _task("七灯已亮 · Enter 再看同行长卷")
		return _task_at(body, 18, "到廊下停下，等同伴共看长卷", 0, 0.5, false)
	var role: int = body.character_id
	if not personal_items_done():
		if not items_done[role]:
			if not has_keepsake(role):
				var inventory: Node3D=get_node("../../..").keepsakes
				return _task("尚未拾取 · "+inventory.PLACES[role]+" · B看包裹",0,inventory.POSITIONS[role].x)
			return _task_at(body, ITEM_POSITIONS[role], ITEMS[role], item_progress[role])
		for index in range(4):
			if not items_done[index] and party.role_body(index) not in party.human_players():
				return _task("已归位 · 可切到%s，完成%s" % [party.NAMES[index], ITEMS[index]])
		return _task("你的物件已归位 · 等同伴完成另一件")
	if not composition_ready(): return _task("一起试配庭院彩幔 · 左上布置或灯桌继续")
	var oil: int = oil_carriers.find(role)
	if oil >= 0:
		return _task_at(body, ITEM_POSITIONS[oil + 4], "送往" + ITEMS[oil + 4], item_progress[oil + 4])
	for index in range(3):
		if not items_done[index + 4] and oil_carriers[index] < 0:
			var state: Dictionary = _task_at(body, SUPPLY_X, "到村民灯桌领取油灯", 0, 1.0, false)
			if absf(body.global_position.x - global_position.x - SUPPLY_X) <= 1.0:
				state.text = "停下，按一次 %s 领取油灯" % _operation_key(body)
			return state
	for owner_id in oil_carriers:
		if owner_id >= 0 and party.role_body(owner_id) not in party.human_players():
			return _task("油灯在%s手中 · 切回该角色继续送灯" % party.NAMES[owner_id])
	return _task("同伴正在送灯 · 可以到右侧廊下等候")


func _operation_key(body: CharacterBody3D) -> String:
	return "P / 小键盘0" if party.local_coop and body == party.second_player else "E"


func _task(text: String, progress: float = 0, target_x: float = NAN) -> Dictionary:
	return {"text": text, "progress": clampf(progress / lighting_hold_seconds, 0, 1), "target_x": target_x}


func _task_at(body: CharacterBody3D, local_x: float, task: String, progress: float, radius: float = 0.88, hold: bool = true) -> Dictionary:
	var distance: float = global_position.x + local_x - body.global_position.x
	var text: String
	if absf(distance) > radius:
		text = ("→ " if distance > 0 else "← ") + task
	elif not party.at_station(body, global_position.x + local_x, radius):
		text = ("向里靠近 · " if body.global_position.z > 0 else "向外靠近 · ") + task
	elif not body.is_on_floor(): text = "先落地 · " + task
	elif party.planar_speed(body) > 0.15: text = "停下 · " + task
	elif hold: text = "按住 %s · %s" % [_operation_key(body), task]
	else: text = task
	return _task(text, progress, global_position.x + local_x)


func reset_lesson() -> void:
	_clear_carry()
	var experience: CanvasLayer = get_node("../../..").experience
	if experience!=null: experience.reset_from(2)
	for tween in [_tween, _raise_tween]:
		if tween != null and tween.is_valid(): tween.kill()
	close_record(false)
	if tablet_raising: party.set_interaction_lock(false)
	if is_instance_valid(raise_rig): raise_rig.free()
	tablet_raising=false
	raise_progress=0
	tablet_placed = false
	raise_focus_left=0
	tablet_arriving = false
	arrival_elapsed = 0
	_tablet.visible = bridge.tablet_delivered
	lamp_count = 0
	_arrival_sled.visible = bridge.tablet_delivered
	court_lit = false
	closing = false
	_entered = false
	action_progress = 0.0
	items_done.fill(false)
	item_progress.fill(0.0)
	oil_carriers.fill(-1)
	_tablet.position = Vector3(PLACEMENT_X, FLAT_REST_Y, -1.8)
	_tablet.rotation = Vector3(-PI/2,0,PI/2)
	warm_light.light_energy = 0.45
	$Residents.visible = false
	$Residents.get_child(0).position = Vector3(1.3, 0, -2.2)
	$Residents.get_child(1).position = Vector3(6.3, 0, -2.4)
	for resident in $Residents.get_children(): resident.get_node("Character").pose(0, 0, 0, true, false, false)
	landscape.resident_work_left.fill(0)
	landscape.reset_art()
	if bridge.tablet_delivered: receive_tablet(Vector3(40.1,.85,-.25))
