extends Node3D

const CharacterNames = preload("res://scripts/character_names.gd")
@export var camera_follow_speed: float = 5.0
@export_range(9.0, 12.0, 0.5) var first_space_camera_size: float = 10.5

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $SideCamera
@onready var room_label: Label = $Guide/RoomName
@onready var tip_label: Label = $Guide/Tip
@onready var cooperation: Node3D = $Spaces/Space01/Cooperation
@onready var bridge: Node3D = $Spaces/Space02/BridgeCooperation
@onready var courtyard: Node3D = $Spaces/Space03/CourtyardCooperation
@onready var party: Node3D = $Party

var current_space: int = 0
var visited_spaces: Array[int] = []
var ending_reached: bool = false
var completed_actions: Array[String] = []
var music: Node
var sfx: Node
var story: CanvasLayer
var scene_details: Node3D
var folk: CanvasLayer
var festival: Node3D
var click_interactions: CanvasLayer
var walk_space: Node3D
var scene_atmosphere: Node3D
var achievements: CanvasLayer
var experience: CanvasLayer
var keepsakes: Node3D
var guidance: CanvasLayer
var mobile_controls: CanvasLayer
var chapter_films: Node
var celebration_rewards: Node3D

const SPACE_NAMES: Array[String] = [
	"第一关 · 雾廊碑院",
	"第二关 · 断溪古道",
	"第三关 · 灯火共庭"
]


func _ready() -> void:
	_update_space()
	_update_camera(0.0, true)
	scene_details = preload("res://scripts/cultural_scene_details.gd").new()
	add_child(scene_details)
	scene_details.setup(self)
	var nearby_ui := preload("res://scripts/nearby_interactions.gd").new()
	add_child(nearby_ui)
	nearby_ui.setup(self)
	room_label.position = Vector2(132, 24)
	room_label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(19))
	room_label.add_theme_font_override("font",preload("res://scripts/interface_skin.gd").heading_font())
	tip_label.visible = false
	music = preload("res://scripts/scene_music.gd").new()
	add_child(music)
	sfx = preload("res://scripts/interaction_audio.gd").new()
	add_child(sfx)
	story = preload("res://scripts/story_dialogue.gd").new()
	add_child(story)
	folk = preload("res://scripts/folk_collection.gd").new()
	add_child(folk)
	folk.setup(self)
	festival = preload("res://scripts/festival_court.gd").new()
	add_child(festival)
	festival.setup(self)
	folk.register_court_guests(festival.guests)
	nearby_ui._add("a_cai_court", "阿彩（苗族）", festival.guests[0], Vector3(0, 2.28, 0), 2, "person", 0)
	nearby_ui._add("a_qiang_court", "阿强（壮族）", festival.guests[1], Vector3(0, 2.28, 0), 2, "person", 1)
	click_interactions = preload("res://scripts/world_click_interactions.gd").new()
	add_child(click_interactions)
	click_interactions.setup(self)
	walk_space = preload("res://scripts/planar_walk_space.gd").new()
	add_child(walk_space)
	walk_space.setup(self)
	scene_atmosphere = preload("res://scripts/scene_atmosphere.gd").new()
	add_child(scene_atmosphere)
	scene_atmosphere.setup(self)
	var scene_art:=preload("res://scripts/scene_art_polish.gd").new()
	add_child(scene_art)
	scene_art.setup(self)
	achievements = preload("res://scripts/achievement_book.gd").new()
	add_child(achievements)
	achievements.setup(self)
	experience=preload("res://scripts/cooperative_experience.gd").new()
	add_child(experience)
	experience.setup(self)
	keepsakes=preload("res://scripts/journey_keepsakes.gd").new()
	add_child(keepsakes)
	keepsakes.setup(self)
	guidance=preload("res://scripts/journey_guidance.gd").new()
	add_child(guidance)
	guidance.setup(self)
	chapter_films=preload("res://scripts/chapter_films.gd").new()
	add_child(chapter_films)
	chapter_films.setup(self)
	celebration_rewards=preload("res://scripts/celebration_rewards.gd").new()
	add_child(celebration_rewards)
	celebration_rewards.setup(self)
	if preload("res://scripts/mobile_platform.gd").active():
		mobile_controls=preload("res://scripts/mobile_controls.gd").new()
		add_child(mobile_controls)
		mobile_controls.setup(self)


func _process(delta: float) -> void:
	_update_camera(delta)
	_update_space()
	if chapter_films!=null and chapter_films.check_entry(): return
	if cooperation.gate_open:
		for body in party.human_players():
			if body.global_position.x >= 20.0:
				body.fall_recovery_position = Vector3(41.0 if bridge.gap_stabilized and body.global_position.x >= 40 else 21.0, 0.8, 0.0)
	if Input.is_action_just_pressed("toggle_guide"):
		get_node("PartyUI")._toggle_hint()
	_check_ending()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_lesson"):
		ending_reached = false
		completed_actions.clear()
		visited_spaces.clear()
		if experience!=null: experience.reset_from(0)
		reset_journey_collections()


func reset_journey_collections() -> void:
	if celebration_rewards!=null: celebration_rewards.reset()
	if chapter_films!=null: chapter_films.reset_journey()
	if achievements!=null: achievements.reset_session()
	if keepsakes!=null: keepsakes.reset_from(0)
	var ui: CanvasLayer=get_node("PartyUI")
	ui._notice_seconds=0
	ui._notice_keepsake=false


func _check_ending() -> void:
	if not ending_reached and player.global_position.x >= 57.5 and player.is_on_floor() and party.planar_speed(player) < 0.15 \
		and cooperation.observed and cooperation.gate_open and bridge.bridge_ready and courtyard.court_lit:
		if party.local_coop and (party.second_player.global_position.x < 57.5 or not party.second_player.is_on_floor() or party.planar_speed(party.second_player) >= 0.15):
			return
		ending_reached = true
		completed_actions.assign([
			"四人互补：识读与辨向",
			"合力修路：护送道具碑",
			"合织共庭：七灯相照"
		])
		courtyard.show_record(completed_actions)


func _update_camera(delta: float, immediate: bool = false) -> void:
	# Ease back to the existing wider framing as the traveler leaves the sample.
	var center_x: float = player.global_position.x
	var span: float = 0.0
	if party.local_coop:
		center_x = (center_x + party.second_player.global_position.x) * 0.5
		span = absf(player.global_position.x - party.second_player.global_position.x)
	var view_size: float = lerpf(first_space_camera_size, 12.0, smoothstep(17.0, 23.0, center_x))
	var court_framing: float = smoothstep(38.0, 42.0, center_x)
	view_size += court_framing * 1.3
	var rescue_focus: bool = current_space == 1 and bridge.bridge_ready and not bridge.gap_stabilized
	if rescue_focus: view_size = 10.0
	view_size = maxf(view_size, span / (1280.0 / 720.0) + 3.5)
	camera.size = view_size if immediate else lerpf(camera.size, view_size, 1 - exp(-camera_follow_speed * delta))
	var target_x: float = clampf(center_x + (1.0 if party.local_coop else 3.0), 10.0, 50.0)
	if rescue_focus: target_x = clampf((center_x + bridge._tablet.global_position.x) * .5 + .5, 10, 50)
	var target_position := Vector3(target_x, 4.0 + court_framing * 1.4, 16.0)
	var look_height: float = 1.6 + court_framing * 1.4
	if immediate:
		camera.global_position = target_position
	else:
		camera.global_position = camera.global_position.lerp(
			target_position, 1.0 - exp(-camera_follow_speed * delta)
		)
	camera.look_at(Vector3(camera.global_position.x, look_height, 0.0), Vector3.UP)


func _update_space() -> void:
	var progress_x: float = player.global_position.x
	if party.local_coop:
		progress_x = minf(progress_x, party.second_player.global_position.x)
	current_space = mini(int(progress_x / 20.0), 2)
	if current_space not in visited_spaces:
		visited_spaces.append(current_space)
	room_label.text = SPACE_NAMES[current_space]
	if current_space == 0:
		tip_label.text = cooperation.get_hint()
	elif current_space == 1:
		tip_label.text = bridge.get_hint()
	elif ending_reached:
		room_label.text = "第三关 · 共庭有光"
		tip_label.text = "七灯已亮，同行长卷留在廊下。\nEnter 再看长卷 · F2 文化档案 · T 从头重玩"
	else:
		tip_label.text = courtyard.get_hint()
	if party.local_coop and not party.movement_locked() \
		and absf(player.global_position.x - party.second_player.global_position.x) >= party.MAX_PLAYER_DISTANCE - 0.2:
		tip_label.text = "两位玩家相距较远，请等候或朝同伴靠近。\n" + tip_label.text.get_slice("\n", 0)
	tip_label.text = CharacterNames.annotate(tip_label.text)


func objective() -> Dictionary:
	var text: String
	var progress: String
	if current_space == 0:
		progress = "闻 %d/4 · 字 %d/6" % [cooperation.clues.count(true),cooperation.placed_count()]
		if not cooperation.observed and not cooperation.inspector.rubbing.completed: progress="传拓 %d / 3"%mini(cooperation.inspector.rubbing.phase,3)
		if cooperation.gate_open: text = "碑文已合，向右出院。\n等同伴一同前往断溪古道。"
		elif cooperation.opening: text = "碑文已合，院门正开启。\n稍候，与同伴向右出发。"
		elif cooperation.puzzle_active: text = cooperation.stage_instruction()+ ("" if not cooperation.inspector.rubbing.completed else "\n下方同行卡可分享、换人。")
		else: text = "点击小爨碑，覆纸、扑墨、揭纸，合读六字。\n再到大爨碑核对年代、碑主与来处。\n两碑印记合验，才可启程护碑。"
	elif current_space == 1:
		progress = "%d / 6" % mini(bridge.step, 6)
		if bridge.building: text = "众人正在铺梁、固定桥面。\n待木桥落稳，再护碑过溪。"
		elif bridge.step in [1, 2] and not bridge.timber_prepared: text = "老箐在杉木旁截料捆扎。\n邓书年可先到岩壁辨认旧路。"
		else:
			match bridge.step:
				0: text = "老箐到左侧旧桥基察看水痕。\n先认清通路，再备杉木。"
				1: text = "邓书年识读岩壁旧路。\n任意角色将备好的木料推往桥头。"
				2: text = "将木料推到桥头交付点。\n送达后，由石阿朵稳固桥墩。" if not bridge.material_delivered else "石阿朵在桥头稳固石墩。\n随后请杨三娘联络村民。"
				3: text = "杨三娘回左侧岔道联络村民。\n请来绳索与帮手，再回桥头。"
				4: text = "两位玩家在桥头会合。\n四人到齐，站稳按住操作键架桥。"
				5:
					text = "桥心顶碑，右岸收放绳索。\n张力留在绿色区，等碑身稳定。" if party.local_coop else "慢行护碑，到桥心停稳。\n按住操作键，同行协助收放绳索。"
					progress = "护碑 %d%%" % int(bridge.action_progress / bridge.RESCUE_SECONDS * 100)
				_: text = "碑已送入院中，向右进入灯火共庭。" if bridge.tablet_delivered else "碑已护稳，向右走到交接处。\n与同伴一同到场，送碑入院。"
	else:
		progress = "七灯 %d / 7" % courtyard.lamp_count
		if courtyard.tablet_raising:
			text="众人正在收绳扶碑。\n等碑脚稳稳落座，再安放各自的物件。"
			progress="立碑 %d%%"%int(courtyard.raise_progress*100)
		elif courtyard.tablet_arriving:
			text = "四位同行正合抬石碑入院。\n放稳抬架后，再合力扶碑落座。"
			progress="合抬 %d%%"%int(courtyard.arrival_elapsed/courtyard.ARRIVAL_SECONDS*100)
		elif not courtyard.tablet_placed: text = "石阿朵与同伴在院中碑座会合。\n站稳，同时按住操作键扶碑。"
		elif courtyard.court_lit: text = "灯火已相连。\n到右侧廊下停步，与同伴共看长卷。"
		elif courtyard.closing: text = "七灯渐次亮起。\n稍候，到右侧廊下共看长卷。"
		elif not courtyard.personal_items_done():
			text = "各位将沿途拾得的物件归位。\n完成后，切换自己的另一位同行。" if keepsakes==null or not false in keepsakes.collected else "随身物件尚未拾齐。\n按 B 翻看随身物件，查看来路散落位置。"
		elif experience!=null and not experience.design_done: text="一起试配两幅庭院纹样。\n各自确认后，再分头送灯。\n左上布置按钮可继续。"
		else: text = "到村民灯桌领取油灯。\n送往院门、石阶、碑亭并站稳安放。"
	if experience==null and not cooperation.puzzle_active and not courtyard.record_open: text += "\n点特色器物，可读见闻、试作小艺。"
	return {"text": text, "progress": progress}


func interaction_progress() -> Dictionary:
	var labels: Array[String] = []
	var ratio: float = 0
	if current_space==0 and cooperation.inspected_id==0:
		var correct: int = 0
		for index in range(6):
			if cooperation.slots[index]==index and cooperation.turns[index]==0: correct+=1
		return {"text":"合读见闻 %d/4 · 正确归位 %d/6"%[cooperation.clues.count(true),correct],"ratio":cooperation.clues.count(true)/8.0+correct/12.0}
	for slot in range(party.human_players().size()):
		var actor: CharacterBody3D = party.human_players()[slot]
		var amount: float = cooperation.clue_progress[actor.character_id] / cooperation.observation_seconds
		if amount > 0:
			labels.append("%dP 识字 %d%%" % [slot + 1, mini(100, int(amount * 100))])
			ratio = maxf(ratio, amount)
	if bridge._timber_progress > 0:
		var amount: float = bridge._timber_progress / 1.6
		labels.append("备木 %d%%" % int(amount * 100))
		ratio = maxf(ratio, amount)
	if bridge.action_progress > 0:
		var amount: float = bridge.action_progress / (bridge.RESCUE_SECONDS if bridge.step==5 else 1.6)
		labels.append("%s %d%%" % [["认水痕", "辨路", "砌墩", "联络", "架桥", "合力护碑"][mini(bridge.step, 5)], mini(100, int(amount * 100))])
		ratio = maxf(ratio, amount)
	elif bridge.building:
		ratio = 1 - absf(bridge.get_node("BridgeAssembly").rotation.z) / (PI / 2)
		labels.append("架桥 %d%%" % int(ratio * 100))
	elif bridge.is_pushing:
		ratio = (bridge.crate.position.x - 4) / 5.5
		labels.append("推运 %d%%" % int(ratio * 100))
	if not courtyard.tablet_placed and courtyard.action_progress > 0:
		var amount: float = courtyard.action_progress / courtyard.lighting_hold_seconds
		labels.append("合力扶碑 %d%%" % int(amount * 100))
		ratio = maxf(ratio, amount)
	else:
		for index in range(7):
			var amount: float = courtyard.item_progress[index] / courtyard.lighting_hold_seconds
			if amount > 0:
				labels.append("%s %d%%" % [courtyard.ITEMS[index], int(amount * 100)])
				ratio = maxf(ratio, amount)
	if courtyard.tablet_raising:
		labels.append("合力立碑 %d%%"%int(courtyard.raise_progress*100))
		ratio=maxf(ratio,courtyard.raise_progress)
	if courtyard.tablet_arriving:
		var arrival_ratio: float = courtyard.arrival_elapsed/courtyard.ARRIVAL_SECONDS
		labels.append("送碑入院 %d%%"%int(arrival_ratio*100))
		ratio=maxf(ratio,arrival_ratio)
	var finished: bool = [cooperation.observed, bridge.gap_stabilized, courtyard.court_lit][current_space]
	if labels.is_empty() and finished: return {"text": "本关已成 100%", "ratio": 1.0}
	return {"text": " · ".join(labels) if not labels.is_empty() else "交互进度 0%", "ratio": clampf(ratio, 0, 1)}


func restart_current_scene() -> void:
	if not party.started: return
	var chapter: int = current_space
	get_tree().paused = false
	cooperation.close_puzzle()
	courtyard.reset_lesson()
	if chapter <= 1: bridge.reset_lesson()
	if chapter == 0: cooperation.reset_lesson()
	ending_reached = false
	completed_actions.clear()
	party.reset_positions(false)
	var entry_x: float = [5.0, 22.5, 42.5][chapter]
	for index in range(party.all_bodies().size()):
		var actor: CharacterBody3D = party.all_bodies()[index]
		actor.global_position = Vector3(entry_x - index * 0.75, 0.8, 0)
		actor.velocity = Vector3.ZERO
		if actor in party.human_players(): actor.fall_recovery_position = actor.global_position
	party.set_interaction_lock(false)
	party.set_controls(true)
	get_node("NearbyInteractions").clear()
	story.reset_from(chapter)
	sfx.reset_cues()
	folk.reset_from(chapter)
	if keepsakes!=null: keepsakes.reset_from(chapter)
	if experience!=null: experience.reset_from(chapter)
	_update_space()
	_update_camera(0, true)
	music.restart_current()


func archive_text() -> String:
	var text: String = "真实文化锚点：小爨立于 405 年，大爨立于 458 年。\n六字字形采用梁培生小爨现代字库，非原碑拓片或完整碑额复原。\n"
	if cooperation.observed:
		text += "已解锁小爨观察：1778 年发现于杨旗田；1852 年有邓尔恒题跋。\n"
	else:
		text += "小爨观察记录尚未解锁。\n"
	if cooperation.comparison_complete:
		text+="二爨合读：405年小爨、458年大爨，相隔53年；已解锁共庭长卷的二爨纪年题签。\n"
	if bridge.gap_stabilized:
		text += "已完成虚构护碑：辨路、读标、运料、联络、全队架桥与扶稳。\n"
	if courtyard.court_lit:
		text += "已完成虚构共庭：安放道具碑，七件物品归位，七灯点亮。\n"
	if experience!=null and experience.design_done: text+="同行共作："+experience.design_summary()+"。\n"
	text += "八位人物与护碑任务为游戏原创，职业能力不由族属决定。\n共生长卷为艺术创作：合力过桥、七族器物、代代守护、万家灯火。\n资料：曲靖市政府、云南宣传网、国家民委及国家文化记忆库。\n封面“识爨·文化记”可阅读整理文字，并查看原文出处。"
	return text


func start_creek_preview() -> void:
	# A review entry point seeds only the previous chapter; the creek itself starts untouched.
	cooperation.close_puzzle()
	if keepsakes!=null: keepsakes.seed_previous(1)
	cooperation.observed = true
	cooperation.gate_open = true
	cooperation.step = 4
	cooperation.clues.fill(true)
	cooperation.slots.assign([0, 1, 2, 3, 4, 5])
	cooperation.turns.fill(0)
	cooperation.get_node("Gate").position.y = 8.0
	cooperation._update_board()
	player.global_position = Vector3(21.5, 0.8, 0)
	player.velocity = Vector3.ZERO
	if party.local_coop:
		party.second_player.global_position = Vector3(20.55, 0.8, 0)
		party.second_player.velocity = Vector3.ZERO
	for index in range(party.followers.size()):
		party.followers[index].global_position = Vector3(19.6 - index * 0.95, 0.8, 0)
		party.followers[index].velocity = Vector3.ZERO
	_update_space()
	_update_camera(0.0, true)


func start_garden_preview() -> void:
	# Seed earlier chapters only; every courtyard task still needs to be played.
	start_creek_preview()
	if keepsakes!=null: keepsakes.seed_previous(2)
	bridge.timber_prepared = true
	bridge.material_delivered = true
	bridge.crate.position=Vector3(9.5,.5,-1.9)
	bridge.get_node("MaterialCrate/Collision").set_deferred("disabled",true)
	bridge.helpers_called = true
	bridge.bridge_ready = true
	bridge.gap_stabilized = true
	bridge.step = 6
	bridge.deliver_tablet()
	bridge.get_node("BridgeAssembly").visible = true
	bridge.get_node("BridgeAssembly").rotation.z = 0
	bridge.get_node("BridgeBody/Collision").set_deferred("disabled", false)
	player.global_position = Vector3(41.5, 0.8, 0)
	player.velocity = Vector3.ZERO
	if party.local_coop:
		party.second_player.global_position = Vector3(40.55, 0.8, 0)
		party.second_player.velocity = Vector3.ZERO
	for index in range(party.followers.size()):
		party.followers[index].global_position = Vector3(39.6 - index * 0.95, 0.8, 0)
		party.followers[index].velocity = Vector3.ZERO
	_update_space()
	_update_camera(0.0, true)
