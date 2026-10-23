extends CanvasLayer

# One focus per human keeps dense groups of props legible. Nothing here completes
# a chapter task: examining and chatting have their own keys, separate from holds.
const UiStyle = preload("res://scripts/interface_skin.gd")
const CARD_SIZE := Vector2(228, 90)
const PAGE_CHARACTERS: int = 20
var world: Node3D
var party: Node3D
var first: Node3D
var bridge: Node3D
var court: Node3D
var entries: Array[Dictionary] = []
var focus: Array[String] = ["", ""]
var pinned: Array[String] = ["", ""]
var reading: Array[String] = ["", ""]
var pages: Array[int] = [0, 0]
var cards: Array[Panel] = []
var titles: Array[Label] = []
var words: Array[Label] = []
var keys: Array[Label] = []
var tails: Array[Line2D] = []
var arrowheads: Array[Polygon2D] = []
var buttons: Array[Button] = []
var reading_papers: Array[TextureRect] = []
var idle_names: Array[Label3D] = []


func setup(owner_world: Node3D) -> void:
	world = owner_world
	party = world.party
	first = world.cooperation
	bridge = world.bridge
	court = world.courtyard
	name = "NearbyInteractions"
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_people()
	_register_props()
	for entry in world.scene_details.props:
		_add(entry.id, entry.title, entry.anchor, entry.offset, entry.chapter, "look", -1, entry.description)
		entries[-1]["sound"] = entry.sound
	for slot in range(2): _build_card(slot)


func _add(id: String, title: String, anchor: Node3D, offset: Vector3, chapter: int,
		kind: String = "look", index: int = -1, description: String = "") -> void:
	entries.append({"id": id, "title": title, "anchor": anchor, "offset": offset,
		"chapter": chapter, "kind": kind, "index": index, "description": description})


func _spot(id: String, title: String, chapter: int, at: Vector3,
		kind: String = "look", index: int = -1, description: String = "") -> void:
	var marker := Marker3D.new()
	marker.name = "Interaction_" + id
	[first, bridge, court][chapter].add_child(marker)
	marker.position = at
	_add(id, title, marker, Vector3.ZERO, chapter, kind, index, description)


func _register_people() -> void:
	_add("a_cai", "阿彩（苗族）", bridge._a_cai, Vector3(0, 2.28, 0), 1, "person", 0)
	_add("a_qiang", "阿强（壮族）", bridge._a_qiang, Vector3(0, 2.28, 0), 1, "person", 1)
	_add("pu_mo", "普嫫（彝族）", court.get_node("Residents/ResidentA"), Vector3(0, 2.20, 0), 2, "person", 2)
	_add("yu_nan", "玉喃（傣族）", court.get_node("Residents/ResidentB"), Vector3(0, 2.28, 0), 2, "person", 3)
	_add("donkey", "驮布毛驴与布筐", court.get_node("Residents/ResidentB/Character/PackDonkey"), Vector3(0, 1.85, 0), 2,
		"look", -1, "驮筐里是玉喃带来的布卷与锦带。山路虽远，人货皆须慢行。")
	for item in [
		["a_cai_hoe", "阿彩的小锄头", bridge._a_cai, Vector3(0.4, 1.9, 0), 1, "小锄头是阿彩下地用的农具。此番来帮忙，她也将绳索带到了桥边。"],
		["a_cai_basket", "阿彩的竹篓", bridge._a_cai, Vector3(-0.3, 1.2, 0), 1, "腰间小竹篓，装着随身零物。阿彩话不多，见人需要帮手，便来搭把手。"],
		["baby_carrier", "背婴布", bridge._a_cai, Vector3(0, 1.8, -0.3), 1, "花纹背布护着熟睡的孩子。交谈时轻些，莫惊了孩子。"],
		["a_qiang_beam", "阿强的榫卯木梁", bridge._a_qiang, Vector3(0.4, 1.8, 0), 1, "木梁端头留着榫口。阿强肩上带梁来，架桥时便放下木料，与众人合力。"],
		["a_qiang_knife", "木鞘柴刀", bridge._a_qiang, Vector3(-0.25, 1.1, 0), 1, "柴刀入鞘，别在腰间，是阿强整理木料的随身工具。"],
		["tea_jar", "黑陶茶罐", world.scene_details.dispersed_items.tea_jar, Vector3(0,.90,0), 2, "普嫫把黑陶茶罐留在保护架右边、茶席左边的小木几上，等护碑的人歇脚分茶。"],
		["fire_basin", "三足铜火盆", world.scene_details.dispersed_items.fire_basin, Vector3(0,.40,0), 2, "三足铜火盆安在左廊、拓片墙前的石垫上，留着炭火，供往来的人暖手。"],
		["flint_pouch", "火石小布袋", world.scene_details.dispersed_items.flint_pouch, Vector3(0,.88,0), 2, "普嫫把火石小布袋放在右侧圆窗下、织架前方的木几上，备好火具，留给后来的人。"],
		["yu_nan_brocade", "玉喃的锦带", court.get_node("Residents/ResidentB"), Vector3(0.3, 1.4, 0.2), 2, "锦带系在灯柄，便于提握。玉喃带来的布卷在驮筐里，可与毛驴一道察看。"],
	]:
		_add(item[0], item[1], item[2], item[3], item[4], "look", -1, item[5])


func _register_props() -> void:
	for id in range(2):
		_add("stele_%d" % id, ["小爨碑 · 六字归位", "大爨碑 · 二爨合读"][id],
			first.get_node("SmallPanel" if id == 0 else "LargePanel"), Vector3(0, 1.5, 0.15), 0, "stele", id)
	_spot("rubbing_table", "拓印案 · 纸、笔与墨", 0, Vector3(9.3, 1.50, -2), "look", -1,
		"纸铺案上，笔墨在侧。先到小爨碑察看字形，再由四位同行各述所见；收下的线索可按 B 翻看。")
	_spot("paper_box", "案下木匣", 0, Vector3(9, 0.75, -2), "look", -1, "木匣收着备用纸张。拓印用具仍放在案上，可一道察看。")
	_spot("exit_sign", "古道指路牌", 0, Vector3(17.35, 2.1, -2.5), "look", -1, "循牌向右，便是断溪古道。碑院六字归位后，同行之门方开。")
	_spot("courtyard_gate", "碑院木门", 0, Vector3(18.95, 2.4, 0), "gate")
	var art: Node = world.get_node("Spaces/Space01").find_child("SteleCourtyard", true, false)
	if art != null:
		for index in range(art.lanterns.size()):
			_add("courtyard_lantern_%d" % index, "廊下提灯", art.lanterns[index], Vector3(0, 0.5, 0), 0,
				"look", -1, "一盏旧灯，照着残墙与碑面。沿廊前行，可到拓印案与两碑前察看。")
	for index in range(2):
		var stone: Node3D = first.get_node("SmallPanel" if index == 0 else "LargePanel")
		_spot("stele_candle_%d" % index, "碑前烛台", 0, Vector3(stone.position.x - 0.65, 0.9, -1.95),
			"look", -1, "烛火照着碑座。察看碑面时，可由四位同行补全识字、次序与辨向的线索。")
	_spot("village_sign", "村口路牌", 1, Vector3(0.6, 2.45, -1.35), "look", -1, "路牌指向来时村路。若要请人送绳，杨三娘可在旧桥基旁联络。")
	_spot("flood_base", "旧桥基 · 水痕", 1, Vector3(2.5, 1.55, -1.5), "creek", 0)
	_spot("fallen_fir", "倒杉 · 备料处", 1, Vector3(4, 1.65, -1.6), "creek", 1)
	_add("timber_sled", "杉木木橇", bridge.crate, Vector3(0, 1.15, 0), 1, "creek", 2)
	_spot("old_route", "岩壁旧路刻痕", 1, Vector3(7, 1.85, -2.1), "creek", 3)
	_spot("bridge_pier", "桥头石墩", 1, Vector3(10.5, 1.7, -0.7), "creek", 4)
	_add("rope_coils", "桥头绳索", bridge.landscape.rope_supply, Vector3(9.5, 0.85, -1.65), 1,
		"look", -1, "阿彩与阿强送来的绳索，可用来捆扎木梁、护住碑身。桥成后还须两位玩家合力救碑。")
	_spot("wooden_bridge", "临时木桥", 1, Vector3(13, 1.3, 0), "bridge")
	_spot("rope_post", "右岸木桩 · 牵引绳", 1, Vector3(18.4, 1.8, -0.65), "creek", 5)
	_add("transport_stele", "护送中的道具碑", bridge._tablet, Vector3(0, 0.8, 0), 1, "transport")
	for index in range(bridge.landscape.flames.size()):
		_add("creek_torch_%d" % index, "古道火把", bridge.landscape.flames[index], Vector3(0, 0.45, 0), 1,
			"look", -1, "火把照着溪岸。脚下有断桥，先察看旧桥基，备好杉木，莫急着过溪。")
	for x in [19.5, 21.6]:
		_spot("gate_lamp_%s" % x, "城门壁灯", 1 if x < 20 else 2, Vector3(x if x < 20 else x - 20, 2.6, -1.85), "look", -1, "门灯亮着，前方便是共庭。待碑身护稳，再与同伴一同入院。")
	_add("garden_stele", "共庭碑座 · 道具碑", court._tablet, Vector3(0, 1.8, 0), 2, "placement")
	_spot("guard_frame", "木制保护架", 2, Vector3(12.8, 2.6, -1.8), "look", -1,
		"木架护着碑身。杨三娘的红线系在架上；先扶正道具碑，再让各人物件归位。")
	for index in range(7):
		var at: Vector3 = [Vector3(6.2, 2.8, -2.7), Vector3(9, 1.4, -1.6), Vector3(11.7, 3.4, -1.9),
			Vector3(12.8, 2.9, -1.6), Vector3(2.2, 2.1, -1.3), Vector3(5, 1.2, -0.9), Vector3(15.5, 1.8, -1.4)][index]
		_spot("garden_item_%d" % index, court.ITEMS[index], 2, at, "garden_item", index)
	for index in range(4):
		_add("memorial_lamp_%d" % index, ["拓片旁油灯", "工具架旁油灯", "马铃旁油灯", "红线旁油灯"][index],
			court._lamps[index], Vector3(0, 0.55, 0), 2, "memorial_lamp", index)
	_spot("lamp_table", "村民灯桌", 2, Vector3(3.7, 1.65, -1.9), "supply")
	for index in range(3):
		_add("supply_lamp_%d" % index, ["待送院门的油灯", "待送石阶的油灯", "待送碑亭的油灯"][index],
			court.landscape.supplies[index], Vector3(0, 0.65, 0), 2, "supply", index)
	_add("garden_scroll", "同行长卷", court.landscape.scroll, Vector3(0, 1.1, 0), 2, "scroll")
	for x in [5.0, 14.5, 18.9]:
		_spot("bench_%s" % x, "廊下木凳", 2, Vector3(x, 1.25, -3), "look", -1, "旧木凳留给往来歇脚的人。碑安顿好，灯点起来，便可到右廊共看一路同行。")


func _allowed() -> bool:
	return party.started and not get_tree().paused and not party.movement_locked() \
		and world.get_node("PartyUI").screen == 2 and not court.record_open and first.inspected_id < 0


func _available(entry: Dictionary) -> bool:
	if not entry.anchor.is_visible_in_tree(): return false
	if entry.chapter == 1 and not first.gate_open: return false
	if entry.chapter == 2 and not bridge.gap_stabilized: return false
	if entry.id == "wooden_bridge": return bridge.bridge_ready
	return true


func _point(entry: Dictionary) -> Vector3:
	var base_id: String=entry.id.get_slice("@",0)
	if world.folk!=null and (base_id=="a_cai_hoe" or world.folk.ATTACHED.has(base_id)) and world.folk.picker_bodies.has(entry.id):
		return world.folk.picker_bodies[entry.id].get_child(0).global_position
	# Offsets stay upright even when a carried stone tilts or the donkey turns.
	return entry.anchor.global_position + entry.offset


func nearby(slot: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _allowed() or slot >= party.human_players().size(): return result
	var body: CharacterBody3D = party.human_players()[slot]
	for entry in entries:
		if not _available(entry): continue
		var point: Vector3 = _point(entry)
		if absf(body.global_position.x - point.x) > 2.15 or absf(body.global_position.y - 0.7) > 2.0: continue
		if Vector2(body.global_position.x - point.x, body.global_position.z - point.z).length() > 3.6: continue
		if int(clampf(body.global_position.x / 20.0, 0, 2)) != entry.chapter: continue
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Vector2(_point(a).x - body.global_position.x, _point(a).z - body.global_position.z).length() - _priority(a) < Vector2(_point(b).x - body.global_position.x, _point(b).z - body.global_position.z).length() - _priority(b))
	return result


func _priority(entry: Dictionary) -> float:
	if entry.kind=="keepsake": return .65
	if entry.kind == "person": return 0.3
	if entry.kind == "stele": return 0.5
	if entry.kind == "creek":
		if (entry.index == 0 and bridge.step in [0, 3]) or (entry.index in [1, 2] and bridge.step in [1, 2]) \
			or (entry.index == 3 and bridge.step == 1) or (entry.index == 4 and bridge.step in [2, 4]) \
			or (entry.index == 5 and bridge.step == 5): return 0.5
	if entry.kind == "garden_item" and court.tablet_placed and not court.items_done[entry.index]: return 0.4
	return 0.0


func _choose(slot: int) -> Dictionary:
	var candidates: Array[Dictionary] = nearby(slot)
	if candidates.is_empty():
		focus[slot] = ""
		pinned[slot] = ""
		reading[slot] = ""
		return {}
	var selected: Dictionary = candidates[0]
	for entry in candidates:
		if entry.id == pinned[slot]: selected = entry; break
	if selected.id != pinned[slot]: pinned[slot] = ""
	if focus[slot] != selected.id:
		reading[slot] = ""
		pages[slot] = 0
	focus[slot] = selected.id
	return selected


func cycle(slot: int) -> void:
	var candidates: Array[Dictionary] = nearby(slot)
	if candidates.is_empty(): return
	var current: int = 0
	for index in range(candidates.size()):
		if candidates[index].id == focus[slot]: current = index; break
	pinned[slot] = candidates[(current + 1) % candidates.size()].id
	_choose(slot)


func activate(slot: int) -> void:
	if not _allowed(): return
	var entry: Dictionary = _choose(slot)
	if entry.is_empty(): return
	world.sfx.play_entry(entry)
	if entry.kind=="keepsake":
		world.keepsakes.collect(entry.index,party.human_players()[slot])
		return
	if entry.kind == "history":
		world.click_interactions.open_history()
		return
	if entry.kind == "stele":
		first.open_inspection(entry.index)
		return
	if entry.kind == "scroll" and court.court_lit and world.ending_reached:
		court.show_record(world.completed_actions)
		return
	if reading[slot] == entry.id:
		pages[slot] += 1
		if pages[slot] >= _lines(entry, slot).size(): reading[slot] = ""; pages[slot] = 0
	else:
		reading[slot] = entry.id
		pages[slot] = 0
		if entry.kind == "person" and entry.index >= 2: court.landscape.resident_work(entry.index - 2)
	if entry.kind == "person" and reading[slot] == entry.id:
		world.story.speak(entry.title, _lines(entry, slot)[pages[slot]], 4, true)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_R, KEY_T]:
		clear()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo or not _allowed(): return
	match event.physical_keycode:
		KEY_F: activate(0)
		KEY_G: cycle(0)
		KEY_SLASH:
			if not party.local_coop: return
			activate(1)
		KEY_PERIOD, KEY_KP_1:
			if not party.local_coop: return
			cycle(1)
		_: return
	get_viewport().set_input_as_handled()


func clear() -> void:
	focus.assign(["", ""])
	pinned.assign(["", ""])
	reading.assign(["", ""])
	pages.assign([0, 0])
	for card in cards: card.visible = false
	for label in idle_names: label.visible=false
	for tail in tails: tail.visible = false
	for arrow in arrowheads: arrow.visible = false


func blocks_world_click(at: Vector2) -> bool:
	for card in cards:
		if card.visible and card.get_rect().has_point(at): return true
	return false


func _operation(slot: int) -> String:
	return "操作键"


func _lines(entry: Dictionary, slot: int) -> Array[String]:
	var result: Array[String] = []
	for original in _raw_lines(entry, slot):
		var remaining: String = original
		while remaining.length() > PAGE_CHARACTERS:
			var prefix: String = remaining.substr(0, PAGE_CHARACTERS)
			var cut: int = maxi(prefix.rfind("。"), maxi(prefix.rfind("，"), prefix.rfind("；"))) + 1
			if cut < PAGE_CHARACTERS / 2: cut = PAGE_CHARACTERS
			result.append(remaining.substr(0, cut))
			remaining = remaining.substr(cut)
		result.append(remaining)
	return result


func _raw_lines(entry: Dictionary, slot: int) -> Array[String]:
	var op: String = _operation(slot)
	var index: int = entry.index
	match entry.kind:
		"keepsake": return ["须由"+party.NAMES[entry.index].get_slice("（",0)+"本人拾取。切换到本人，走近站稳，按自己的操作键或点击物件。",entry.description]
		"history": return ["点路牌或按交互键，读杨旗田与《爨宝子碑》的来处。"]
		"stele": return ["放大碑面，六字归位。须由四位同行分享线索。" if index == 0 else "放大对照图，察看碑额字形。也可直接点击碑身。"]
		"person":
			if entry.id == "a_cai_court": return ["桥已修好，孩子也睡得安稳。诸位来看看花布，歇一歇脚。", "你们认字护石，我们抬梁送绳，各人的手艺，今夜都成了护碑的一份力。"]
			if entry.id == "a_qiang_court": return ["木梁搭起一条路，人也就走到一处了。今夜这院子，真热闹。", "下回若要修架补凳，叫我一声。先生的拓片，我也想学着认几个字。"]
			match index:
				0: return ["绳索在此。诸位站稳，咱们一道抬。" if not bridge.bridge_ready else "桥搭好了。慢些过，先把碑护稳。", "孩子睡着呢，我也搭把手。锄头、竹篓都在身边，用得上便说。"]
				1: return ["梁木已备妥。桥头还须诸位会合，再按住操作键架桥。" if not bridge.bridge_ready else "莫慌，木梁已稳。阿朵顶住碑角，老箐去右岸拉绳。" if not bridge.gap_stabilized else "碑已护稳，诸位可安心往城中去。", "我靠木作吃饭，榫口、绳结都得做牢。肩上杉木，腰间柴刀，走山路少不了。"]
				2: return ["火点着了，就不散了。" if court.court_lit else "茶还温着。桌上三盏油灯，送到院门、石阶与碑亭，便能照亮这院子。", "这黑陶罐盛茶，铜火盆暖手。老箐和我来自同村，今夜人都平安，便好。"]
				3: return ["七盏灯都有了归处，来路上的人，也该歇一歇了。" if court.court_lit else "灯柄已系好锦带。到灯桌按一下 %s 领灯，再送去对应灯座，按住 %s 安放。" % [op, op], "毛驴驮来的布卷还在筐里。这点锦带系在灯柄上，也算留下一段同行的情分。"]
		"gate": return ["木门已开，向右走，便入断溪古道。" if first.gate_open else "先察看小爨碑，由四位同行分享线索，将六字归位，木门方开。"]
		"creek":
			match index:
				0: return ["水痕尚在。老箐在此站稳，按住 %s 察看旧桥基。" % op if bridge.step == 0 else "绳索已请来，去桥头与同伴会合。" if bridge.helpers_called else "需要绳索时，由杨三娘回此处，站稳按住 %s 联络村民。" % op]
				1: return ["杉木已截好，接下来推运木橇。" if bridge.timber_prepared else "先让老箐察看旧桥基；随后在杉木旁站稳，按住 %s 截料捆扎。" % op]
				2: return ["木料已交付，可由石阿朵稳固桥墩。" if bridge.material_delivered else "先让老箐截料捆扎。" if not bridge.timber_prepared else "贴近木橇，按住 %s 并朝木料方向行走，推到桥头交付点。" % op]
				3: return ["旧路已辨明，接下来把木料送到桥头，稳固石墩。" if bridge.step >= 2 else "邓书年在刻痕前站稳，按住 %s 识读旧路；须先察看旧桥基。" % op]
				4: return ["桥面已固定，可慢些过溪。" if bridge.bridge_ready else "正在架桥，稍候便好。" if bridge.building else "诸位都到桥头，任意角色站稳按住 %s 合力架桥。" % op if bridge.step == 4 else "木料到齐、旧路辨明后，石阿朵在此按住 %s 稳固石墩，再请村民送绳。" % op]
				5: return ["碑身已稳，绳索可缓缓放下。" if bridge.gap_stabilized else "老箐在此按下 %s 收绳、松开放绳，让张力留在绿色区；石阿朵在桥心持续按住顶碑。" % op]
		"bridge": return ["桥可通行。碑过桥中时，石阿朵顶碑，老箐在右岸调节绳索张力，按下收、松开放。" if not bridge.gap_stabilized else "木桥与碑身都已稳妥，同行者可向右入院。"]
		"transport": return ["碑身正从溪上护送。两位玩家须在桥中、右岸分工顶碑与拉绳，方可进院。" if not bridge.gap_stabilized else "碑已护稳，沿桥向右走，到右岸交接处一同送碑入院。"]
		"placement": return ["碑已立稳，接下来安放四人的随身物件。" if court.tablet_placed else "石阿朵与另一位玩家在碑座旁站稳，同时按住各自操作键；你这边按住 %s。" % op]
		"garden_item":
			if court.items_done[index]: return ["此物已安放妥当，旁边的灯也亮了。" if index < 4 else "这盏油灯已经安放点亮。"]
			if not court.tablet_placed: return ["先到院中碑座，石阿朵与同伴合力扶碑立正，再安放物件。"]
			if index < 4: return ["由%s在此站稳，按住 %s，完成%s。" % [party.NAMES[index], op, court.ITEMS[index]]]
			if not court.personal_items_done(): return ["先安放四人的随身物件，村民随后送来油灯。"]
			var carrier: int = court.oil_carriers[index - 4]
			return ["先到村民灯桌，停下按一次 %s 领取这盏油灯。" % op if carrier < 0 else "油灯由%s携带；带到此处站稳，按住自己的操作键安放。" % party.NAMES[carrier]]
		"memorial_lamp": return ["这盏灯已随物件归位而点亮。" if court.items_done[index] else "对应的随身物件归位后，这盏灯便会亮起。旁边的物件安放处可查看操作。"]
		"supply": return ["七灯已亮，诸位可去廊下共看长卷。" if court.court_lit else "先扶碑，再安放四件随身物品；村民随后来送灯。" if not court.personal_items_done() else "停下，按一次 %s 领取油灯；每位角色一次持一盏。再到对应灯座按住 %s 安放。" % [op, op]]
		"scroll": return ["长卷已展开。两位玩家到右侧廊下停步，一道看这段同行；看过后可再来翻阅。" if court.court_lit else "长卷尚未展开。扶正碑身、安放物件，再将三盏油灯送到各自灯座，七灯齐亮后便可共看。"]
	return [entry.description]


func _build_card(slot: int) -> void:
	var color := UiStyle.VERMILION if slot == 0 else Color(0.20, 0.38, 0.42)
	var small_name:=Label3D.new()
	small_name.name="NearbySmallName%d"%slot
	small_name.font=UiStyle.body_font()
	small_name.font_size=UiStyle.text_size(18)
	small_name.pixel_size=.0045
	small_name.modulate=Color(1,.85,.53)
	small_name.outline_modulate=Color(.07,.08,.07)
	small_name.outline_size=5
	small_name.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	small_name.no_depth_test=true
	small_name.visible=false
	world.add_child(small_name)
	idle_names.append(small_name)
	var tail := Line2D.new()
	tail.width = 1
	tail.default_color = color
	tail.visible = false
	add_child(tail)
	tails.append(tail)
	var arrow := Polygon2D.new()
	arrow.color = color
	arrow.visible = false
	add_child(arrow)
	arrowheads.append(arrow)
	var card := Panel.new()
	card.size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = UiStyle.paper(color.lightened(0.16))
	style.bg_color.a = 0.62
	card.add_theme_stylebox_override("panel", style)
	card.visible = false
	add_child(card)
	cards.append(card)
	var paper := TextureRect.new()
	paper.texture = UiStyle.GAME_BUTTON
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.modulate.a = .62
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(paper)
	reading_papers.append(paper)
	var font := preload("res://scripts/interface_skin.gd").body_font()

	for field in range(3):
		var label := Label.new()
		label.position = [Vector2(10, 5), Vector2(10, 25), Vector2(10, 56)][field]
		label.size = [Vector2(208, 20), Vector2(208, 48), Vector2(208, 18)][field]
		label.add_theme_font_override("font", font)
		if field==0: label.add_theme_font_override("font",UiStyle.heading_font())
		label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size([13, 14, 11][field]))
		label.add_theme_color_override("font_color", color if field != 1 else UiStyle.INK)
		label.add_theme_color_override("font_shadow_color", Color(.96, .91, .79, .85))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if field == 0:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)
		[titles, words, keys][field].append(label)
	var button := Button.new()
	button.flat = true
	button.position = Vector2(0, 138)
	button.size = Vector2(CARD_SIZE.x, 20)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed"]: button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(func():
		var entry: Dictionary = _choose(slot)
		if not entry.is_empty() and world.folk.can_inspect(entry.id): world.folk.open_item(entry.id)
		else: activate(slot)
	)
	card.add_child(button)
	buttons.append(button)


func _process(_delta: float) -> void:
	for slot in range(cards.size()):
		cards[slot].visible = false
		idle_names[slot].visible = false
		tails[slot].visible = false
		arrowheads[slot].visible = false
	if not _allowed(): return
	var camera: Camera3D = world.get_viewport().get_camera_3d()
	if camera == null: return
	var size: Vector2 = get_viewport().get_visible_rect().size
	var head_ceiling: float = size.y - 124
	for actor in party.all_bodies():
		if not actor.is_on_floor(): continue
		var head: Vector2 = camera.unproject_position(actor.global_position + Vector3(0, 1.4, 0))
		if head.x >= 0 and head.x <= size.x: head_ceiling = minf(head_ceiling, head.y - 42)
	var anchors: Array[Vector2] = []
	for slot in range(party.human_players().size()):
		var entry: Dictionary = _choose(slot)
		anchors.append(Vector2.ZERO)
		if entry.is_empty() or camera.is_position_behind(_point(entry)): continue
		# Only actual dropped keepsakes omit cards and pointers. Nearby viewing,
		# characters and task objects keep the usual card, line and arrow.
		var point: Vector2 = camera.unproject_position(_point(entry))
		if point.x < 0 or point.x > size.x: continue
		anchors[slot] = point
		var is_reading: bool = reading[slot] == entry.id
		if not is_reading and entry.kind=="keepsake":
			# Only dropped belongings use small text; other interactions retain their cards.
			if slot==0 or focus[slot]!=focus[0]:
				idle_names[slot].text=entry.title
				idle_names[slot].global_position=_point(entry)+Vector3(0,.08,0)
				idle_names[slot].visible=true
			continue
		reading_papers[slot].visible = is_reading
		cards[slot].get_theme_stylebox("panel").bg_color.a = .02 if is_reading else .62
		var lines: Array[String] = _lines(entry, slot)
		titles[slot].text = "%dP · %s" % [slot + 1, entry.title]
		words[slot].visible = is_reading
		words[slot].text = lines[mini(pages[slot], lines.size() - 1)] if is_reading else ""
		keys[slot].text = ""
		keys[slot].visible = false
		var measured: float = 0
		for label in [titles[slot], words[slot], keys[slot]]:
			var font_size: int = label.get_theme_font_size("font_size")
			measured = maxf(measured, label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		var card_width: float = clampf(ceilf(measured) + 20, 124, 300)
		cards[slot].size.x = card_width
		for label in [titles[slot], words[slot], keys[slot]]: label.size.x = card_width - 20
		buttons[slot].size.x = card_width
		words[slot].size.y = 0
		var body_height: float = words[slot].get_minimum_size().y + 3 if is_reading else 0
		words[slot].size.y = body_height
		var card_height: float = 27 + body_height
		cards[slot].size.y = card_height
		keys[slot].position.y = 26 + body_height
		buttons[slot].position = Vector2.ZERO
		buttons[slot].size = cards[slot].size
		cards[slot].position = Vector2(clampf(point.x - card_width / 2, 16, size.x - card_width - 16),
			clampf(minf(point.y - card_height - 74, head_ceiling - card_height), 82, size.y - card_height - 124))
		cards[slot].visible = true
		buttons[slot].tooltip_text = entry.title + "\n点击阅读；操作方法可点左上角提示"
	if cards[0].visible and cards[1].visible and cards[0].get_rect().intersects(cards[1].get_rect().grow(8)):
		var left_slot: int = 0 if anchors[0].x <= anchors[1].x else 1
		var middle: float = clampf((anchors[0].x + anchors[1].x) / 2, cards[left_slot].size.x + 24, size.x - cards[1 - left_slot].size.x - 24)
		cards[left_slot].position.x = middle - cards[left_slot].size.x - 8
		cards[1 - left_slot].position.x = middle + 8
	for slot in range(anchors.size()):
		if cards[slot].visible: _avoid_hud(slot,head_ceiling,size)
	for slot in range(anchors.size()):
		if not cards[slot].visible: continue
		tails[slot].points=PackedVector2Array([cards[slot].position+Vector2(cards[slot].size.x/2,cards[slot].size.y),anchors[slot]])
		tails[slot].visible=true
		var direction: Vector2=(anchors[slot]-tails[slot].points[0]).normalized()
		var normal:=Vector2(-direction.y,direction.x)
		arrowheads[slot].polygon=PackedVector2Array([anchors[slot],anchors[slot]-direction*10+normal*4,anchors[slot]-direction*10-normal*4])
		arrowheads[slot].visible=true


func _avoid_hud(slot: int, ceiling: float, viewport_size: Vector2) -> void:
	var ui: CanvasLayer=world.get_node("PartyUI")
	var obstacles: Array[Rect2]=[]
	var controls: Array=[ui.goal_panel,world.experience.coach,world.experience.coach_tab,world.experience.rope_panel,ui.satchel_notice_frame,world.achievements.toast]
	if world.guidance!=null: controls.append_array(world.guidance.cards)
	for control in controls:
		if control.visible: obstacles.append(control.get_global_rect().grow(6))
	var route_label: Label3D=bridge.landscape.stage_labels[2]
	if route_label.is_visible_in_tree():
		var camera: Camera3D=world.get_viewport().get_camera_3d()
		var box: AABB=route_label.get_aabb()
		var first_corner: Vector2=camera.unproject_position(route_label.to_global(box.position))
		var title_bounds:=Rect2(first_corner,Vector2.ZERO)
		for i in range(8):
			title_bounds=title_bounds.expand(camera.unproject_position(route_label.to_global(box.get_endpoint(i))))
		obstacles.append(title_bounds.grow(8))
	var other: Panel=cards[1-slot]
	if other.visible: obstacles.append(other.get_rect().grow(6))
	var original: Vector2=cards[slot].position
	var dimensions: Vector2=cards[slot].size
	var candidates: Array[Vector2]=[original]
	for rect in obstacles:
		candidates.append(Vector2(original.x,rect.position.y-dimensions.y-8))
		candidates.append(Vector2(rect.end.x+8,original.y))
		candidates.append(Vector2(rect.position.x-dimensions.x-8,original.y))
	for y in [116,152,192,232,272,312]:
		for x in [original.x,24.0,400.0,800.0,viewport_size.x-dimensions.x-24]: candidates.append(Vector2(x,y))
	var best: Vector2=original
	var score: float=INF
	for candidate in candidates:
		if candidate.x<16 or candidate.x+dimensions.x>viewport_size.x-16 or candidate.y<116 or candidate.y+dimensions.y>minf(ceiling,viewport_size.y-132): continue
		var bounds:=Rect2(candidate,dimensions)
		var value: float=candidate.distance_squared_to(original)
		for rect in obstacles:
			if bounds.intersects(rect): value+=10000000
		if value<score: score=value; best=candidate
	cards[slot].position=best
