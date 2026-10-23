extends CanvasLayer

const SkinStyle = preload("res://scripts/interface_skin.gd")
const Names = preload("res://scripts/character_names.gd")
const Cards = preload("res://scripts/opening_card_draw.gd")
const PAPER = preload("res://assets/dialogue/dialogue_paper.png")
const SHEETS: Array[Texture2D] = [preload("res://assets/dialogue/deng_shunian.png"), preload("res://assets/dialogue/shi_aduo.png"), preload("res://assets/dialogue/lao_qing.png"), preload("res://assets/dialogue/yang_sanniang.png")]
const BUSTS: Array[Rect2] = [Rect2(125, 18, 320, 435), Rect2(111, 30, 330, 446), Rect2(125, 25, 310, 420), Rect2(115, 135, 300, 405)]
const SPEAKERS: Array[String] = ["邓书年", "石阿朵", "老箐", "杨三娘", "阿彩", "普嫫", "玉喃", "阿强"]
var world: Node3D
var frame: Panel
var portrait: TextureRect
var speaker_label: Label
var words: Label
var next_button: Button
var paper: TextureRect
var queue: Array[Dictionary] = []
var seen: Dictionary = {}
var current: Dictionary = {}
var remaining: float = 0
var stage: int = -1
var shown_count: int = 0


func _ready() -> void:
	name = "StoryDialogue"
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	world = get_parent()
	frame = Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true
	var style := SkinStyle.paper()
	style.bg_color = Color.TRANSPARENT
	frame.add_theme_stylebox_override("panel", style)
	add_child(frame)
	paper = TextureRect.new()
	paper.texture = PAPER
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	paper.modulate.a = .84
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(paper)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait)
	speaker_label = _label(20, true)
	words = _label(17)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_button = Button.new()
	next_button.text = "续话 · V"
	next_button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(12))
	SkinStyle.button(next_button)
	next_button.pressed.connect(advance)
	frame.add_child(next_button)
	frame.visible = false


func _label(size: int, heading: bool = false) -> Label:
	var label := Label.new()
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if heading: label.add_theme_font_override("font",SkinStyle.heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("font_color", SkinStyle.VERMILION if heading else SkinStyle.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(label)
	return label


func speak(speaker: String, line: String, seconds: float = 5, immediate: bool = false) -> void:
	_sync_stage()
	var entry := {"speaker": speaker, "line": line, "seconds": maxf(seconds, line.length() * .115 + 1.6)}
	if immediate:
		current = entry
		remaining = entry.seconds
		_show_current()
	else:
		queue.append(entry)
		if remaining <= 0: advance()


func advance() -> void:
	if queue.is_empty(): current = {}; remaining = 0; frame.visible = false; return
	current = queue.pop_front()
	remaining = current.seconds
	_show_current()


func _show_current() -> void:
	var base: String = current.speaker.get_slice("（", 0)
	var index: int = SPEAKERS.find(base)
	var atlas := AtlasTexture.new()
	if index >= 0 and index < 4:
		atlas.atlas = SHEETS[index]
		atlas.region = BUSTS[index]
	elif index >= 4:
		atlas.atlas = Cards.CARD_TEXTURES[index]
		var dimensions: Vector2 = atlas.atlas.get_size()
		atlas.region = Rect2(dimensions * Vector2(.30, .08), dimensions * Vector2(.51, .57))
	else:
		atlas.atlas = SHEETS[3]
		atlas.region = BUSTS[3]
	portrait.texture = atlas
	speaker_label.text = Names.annotate(current.speaker)
	words.text = current.line
	shown_count += 1
	_layout()


func _layout() -> void:
	var compact: bool = world.cooperation.inspected_id >= 0
	var font: Font = words.get_theme_font("font")
	var text_width: float = font.get_string_size(words.text, HORIZONTAL_ALIGNMENT_LEFT, -1, SkinStyle.text_size(17)).x
	var name_width: float = speaker_label.get_theme_font("font").get_string_size(speaker_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, SkinStyle.text_size(20)).x
	var inset: float = 92 if compact else 128
	var width: float = clampf(maxf(text_width, name_width) + inset + 32, 340, 864)
	var height: float = 112 if compact else 156
	if compact:
		inset = 76
		width = 325
		height = 110
	var raising: bool = not compact and (world.courtyard.tablet_raising or world.courtyard.raise_focus_left>0)
	if raising:
		width=480
		inset=108
	frame.size = Vector2(width, height)
	frame.position = Vector2(1256 - width, 712 - height if compact else 698 - height)
	if compact: frame.position = Vector2(65,602)
	if world.current_space == 2 and not compact:
		for card in world.courtyard.landscape.task_cards:
			if card.visible: frame.position.y = 618 - height; break
	if raising: frame.position=Vector2(24,84)
	paper.position = Vector2(1, 1)
	paper.size = frame.size - Vector2(2, 2)
	portrait.position = Vector2(8, 5)
	portrait.size = Vector2(inset - 20, height - 10)
	speaker_label.position = Vector2(inset, 10)
	speaker_label.size = Vector2(width - inset - 20, 28)
	words.position = Vector2(inset, 40)
	words.size = Vector2(width - inset - 18, height - 62)
	words.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(13 if compact else 17))
	speaker_label.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(14 if compact else 20))
	if compact:
		words.position.y = 32
		words.size.y = 68
	next_button.position = Vector2(width - 85, height - 25)
	next_button.visible = not compact
	next_button.size = Vector2(76, 20)


func _sync_stage() -> void:
	if stage == world.current_space: return
	stage = world.current_space
	queue.clear()
	current = {}
	remaining = 0


func reset_from(chapter: int) -> void:
	queue.clear()
	current = {}
	remaining = 0
	frame.visible = false
	for key in seen.keys():
		if seen[key] >= chapter: seen.erase(key)
	stage = -1


func _conversation(key: String, lines: Array) -> void:
	if seen.has(key): return
	seen[key] = stage
	for line in lines: speak(line[0], line[1], 4)


func _process(delta: float) -> void:
	var allowed: bool = world.party.started and world.get_node("PartyUI").screen == 2 and not world.courtyard.record_open
	frame.visible = allowed and not current.is_empty()
	if not allowed or get_tree().paused: return
	_sync_stage()
	if Input.is_action_just_pressed("restart_lesson"): reset_from(0)
	if stage == 0:
		_conversation("meet", [["邓书年", "在下只会认字，这碑上的古字，竟也认不全。"], ["石阿朵", "字慢慢认，先莫伤了碑面。我家三代同石头打交道，这石性，我认得。"], ["杨三娘", "一个识字，一个护石，都是好意。诸位再听听赶马人的话。"], ["老箐", "看旧痕，认方向。几样本事，都用得着。"]])
		if world.cooperation.observed:
			_conversation("read", [["邓书年", "我认得字，却不知它的来路。多谢诸位，把我不懂的补齐了。"], ["石阿朵", "你认字，我认石。他认路。合着看，才看得明白。"], ["杨三娘", "那便一道护碑入城。往后的路，还须互相照应。"]])
	elif stage == 1:
		if world.bridge.step >= 2:
			_conversation("route", [["邓书年", "旧字指着那边的桥基。老箐，这与您走过的山路，可对得上？"], ["老箐", "对得上。字留在石头上，路记在脚底下。合起来，才稳当。"]])
		if world.bridge.helpers_called:
			_conversation("helpers", [["杨三娘", "我把先生的文话，讲成乡亲听得懂的话。绳索与帮手，这不就来了。"], ["阿彩", "好。绳索在此，大家一道抬。"], ["阿强", "你们护石，我来打紧榫口。手艺不同，桥却是一道修的。"]])
		if world.bridge.gap_stabilized:
			_conversation("rescued", [["石阿朵", "方才若少了那一把绳，我这肩膀也撑不住。"], ["邓书年", "一人认字，搬不过溪；众手相扶，才有眼前这条路。"]])
	else:
		if world.courtyard.tablet_placed:
			_conversation("raised", [["石阿朵", "起初我只想把碑留在村里。如今才晓得，肯护它的人，不止我们一村。"], ["杨三娘", "乡音不同，护碑的心意却能说到一处。物件便各依各的来处安放吧。"]])
		if world.courtyard.personal_items_done():
			_conversation("tea", [["玉喃", "我带来保山的锦带，普嫫守着火。赶路的人，先暖一暖手。"], ["邓书年", "锦带、马铃、拓片，各有来处。到这院里，却一同替后来人留了记号。"]])
		if world.courtyard.closing or world.courtyard.court_lit:
			_conversation("lights", [["普嫫", "火点着了，就不散了。"], ["杨三娘", "各家的衣样、乡音都还在，今夜的灯，却照着同一座院子。"]])
	remaining -= delta
	if remaining <= 0: advance()
	if not current.is_empty(): _layout()


func _unhandled_key_input(event: InputEvent) -> void:
	if frame.visible and event.pressed and not event.echo and event.physical_keycode == KEY_V:
		advance()
		get_viewport().set_input_as_handled()
