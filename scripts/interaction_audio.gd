extends Node

const SOUNDS = {
	"paper": preload("res://assets/audio/folk_cues_20261020/paper.wav"), "stone": preload("res://assets/audio/folk_cues_20261020/stone.wav"),
	"wood": preload("res://assets/audio/folk_cues_20261020/wood.wav"), "rope": preload("res://assets/audio/folk_cues_20261020/rope.wav"),
	"bell": preload("res://assets/audio/folk_cues_20261020/bell.wav"), "fire": preload("res://assets/audio/folk_cues_20261020/fire.wav"),
	"water": preload("res://assets/audio/folk_cues_20261020/water.wav"), "cloth": preload("res://assets/audio/folk_cues_20261020/cloth.wav"),
	"page": preload("res://assets/audio/folk_cues_20261020/page.wav"), "success": preload("res://assets/audio/folk_cues_20261020/success.wav"),
	"talk": preload("res://assets/audio/folk_cues_20261020/talk.wav"), "wrong": preload("res://assets/audio/folk_cues_20261020/wrong.wav"),
	"button": preload("res://assets/audio/folk_cues_20261020/button.wav"), "card_flip": preload("res://assets/audio/folk_cues_20261020/card_flip.wav"),
	"card_pick": preload("res://assets/audio/folk_cues_20261020/card_pick.wav"), "jump": preload("res://assets/audio/folk_cues_20261020/jump.wav"),
	"folk_reed": preload("res://assets/audio/folk_cues_20261020/folk_reed.wav"),
	"opening_card_flip": preload("res://assets/audio/interactions/card_flip.wav"),
	"opening_card_pick": preload("res://assets/audio/interactions/card_pick.wav"),
	"firework_launch": preload("res://assets/audio/grand_fireworks_20261021/firework_launch.wav"),
	"firework_burst": preload("res://assets/audio/grand_fireworks_20261021/firework_burst.wav")}
const HOLDS = {"paper": preload("res://assets/audio/folk_cues_20261020/hold_paper.wav"), "wood": preload("res://assets/audio/folk_cues_20261020/hold_wood.wav"),
	"stone": preload("res://assets/audio/folk_cues_20261020/hold_stone.wav"), "rope": preload("res://assets/audio/folk_cues_20261020/hold_rope.wav"),
	"fire": preload("res://assets/audio/folk_cues_20261020/hold_fire.wav"), "cloth": preload("res://assets/audio/folk_cues_20261020/hold_cloth.wav"),
	"bell": preload("res://assets/audio/folk_cues_20261020/hold_bell.wav")}
const STREAM = preload("res://assets/audio/interactions/stream.wav")
var muted: bool = false
var volume: float = .85
var ambience: AudioStreamPlayer
var ambience_gain: float = 0
var hold_players: Array[AudioStreamPlayer] = []
var active_holds: Array[String] = []
var players: Array[AudioStreamPlayer] = []
var cursor: int = 0
var last: Dictionary = {}
var events: Array[String] = []
var flags: Dictionary = {}
var pulse: float = 0
var draw_spin: AudioStreamPlayer
var draw_rate: float=0


func _ready() -> void:
	name = "InteractionAudio"
	add_to_group("game_audio")
	process_mode = Node.PROCESS_MODE_ALWAYS
	draw_spin=AudioStreamPlayer.new()
	draw_spin.stream=_loop(preload("res://assets/audio/card_rotation_audit_20261020/rotation.wav"))
	add_child(draw_spin)
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -18
		add_child(player)
		players.append(player)
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.volume_db = -12
		add_child(player)
		hold_players.append(player)
	ambience = AudioStreamPlayer.new()
	ambience.stream = _loop(STREAM)
	add_child(ambience)
	_register_buttons(get_tree().root)
	get_tree().node_added.connect(_node_added)


func _loop(source: AudioStreamWAV) -> AudioStreamWAV:
	var stream: AudioStreamWAV = source.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	# Imported WAVs may be QOA/ADPCM. Byte count is not a PCM frame count.
	stream.loop_end = roundi(source.get_length()*source.mix_rate)
	return stream


func _node_added(node: Node) -> void:
	if node is Button: _hook_button.call_deferred(node)


func _register_buttons(node: Node) -> void:
	if node is Button: _hook_button(node)
	for child in node.get_children(): _register_buttons(child)


func _hook_button(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta("effects_connected"): return
	button.set_meta("effects_connected", true)
	button.pressed.connect(_button_sound)


func _button_sound() -> void:
	play("button")


func toggle_mute() -> void:
	muted = not muted
	if muted:
		draw_spin.stop()
		for player in players + hold_players: player.stop()
		ambience.stop()
		active_holds.clear()
		ambience_gain = 0


func set_volume(value: float) -> void:
	volume = clampf(value, 0, 1)
	for player in players:
		if player.playing: player.volume_db = float(player.get_meta("base_db", -9)) + _volume_db()
	for player in hold_players: player.volume_db = -12 + _volume_db()


func _volume_db() -> float:
	return linear_to_db(volume) if volume > .001 else -80.0


func update_draw_rotation(speed: float, active: bool) -> void:
	draw_rate=speed if active else 0.0
	var draw_open: bool=get_parent().get_node("PartyUI").screen==get_parent().get_node("PartyUI").Screen.DRAW
	if not active or speed<.05 or muted or (get_tree().paused and not draw_open) or volume<=.001:
		draw_spin.stop()
		return
	var intensity: float=clampf(speed/14.0,0,1)
	draw_spin.pitch_scale=lerpf(.55,1.55,sqrt(intensity))
	draw_spin.volume_db=-14+intensity*6+_volume_db()
	if not draw_spin.playing: draw_spin.play()


func settle_draw_rotation() -> void:
	update_draw_rotation(0,false)
	play("opening_card_pick")


func play(kind: String) -> void:
	if muted: return
	if not SOUNDS.has(kind): kind = "wood"
	var now: int = Time.get_ticks_msec()
	if now - int(last.get(kind, -1000)) < 95: return
	last[kind] = now
	var player: AudioStreamPlayer = players[cursor]
	cursor = (cursor + 1) % players.size()
	player.stream = SOUNDS[kind]
	var base: float = -11 if kind == "jump" else (-15 if kind in ["button", "card_flip", "opening_card_flip"] else -9)
	if kind in ["firework_launch","firework_burst"]: base=-4
	player.set_meta("base_db", base)
	player.volume_db = base + _volume_db()
	player.pitch_scale = 1.0 + (cursor % 3 - 1) * .035
	player.play()
	events.append(kind)
	if events.size() > 128: events.pop_front()


func material_for(entry: Dictionary) -> String:
	if entry.has("sound"): return entry.sound
	var id: String = entry.id
	if entry.kind == "person": return "talk"
	if id == "donkey": return "cloth"
	if "scroll" in id: return "page"
	if "bell" in id or id == "garden_item_2": return "bell"
	if "rope" in id or "frame" in id or id == "garden_item_3": return "rope"
	if "lantern" in id or "lamp" in id or "torch" in id or "fire" in id or "candle" in id: return "fire"
	if "jar" in id: return "water"
	if "cloth" in id or "carrier" in id or "brocade" in id: return "cloth"
	if "rubbing" in id or id == "garden_item_0": return "paper"
	if "stele" in id or "pier" in id or "route" in id or "flint" in id or id in ["flood_base", "garden_item_1"]: return "stone"
	return "wood"


func play_entry(entry: Dictionary) -> void:
	play(material_for(entry))


func stop_fireworks() -> void:
	for player in players:
		if player.stream in [SOUNDS.firework_launch,SOUNDS.firework_burst]: player.stop()


func reset_cues() -> void:
	flags.clear()
	last.clear()
	pulse = 0
	for player in hold_players: player.stop()
	active_holds.clear()


func _cue(key: String, value: bool, sound: String) -> void:
	if value and not flags.get(key, false): play(sound)
	flags[key] = value


func _process(delta: float) -> void:
	var world: Node3D = get_parent()
	if muted or (get_tree().paused and world.get_node("PartyUI").screen!=world.get_node("PartyUI").Screen.DRAW): draw_spin.stop()
	_update_continuous(world, delta)
	if muted or get_tree().paused: return
	if not world.party.started: return
	if Input.is_action_just_pressed("restart_lesson"): reset_cues()
	for slot in range(world.party.human_players().size()):
		var actor: CharacterBody3D = world.party.human_players()[slot]
		if Input.is_action_just_pressed(actor.action("interact")):
			if world.cooperation.puzzle_active: play("paper")
			elif world.current_space == 1: play("rope" if world.bridge.step == 5 else "wood")
			elif world.current_space == 2: play("stone" if not world.courtyard.tablet_placed else "fire")
	for index in range(4): _cue("clue_%d" % index, world.cooperation.clues[index], "paper")
	_cue("gate", world.cooperation.opening, "wood")
	_cue("observed", world.cooperation.observed, "success")
	_cue("prepared", world.bridge.timber_prepared, "wood")
	_cue("delivered", world.bridge.material_delivered, "wood")
	_cue("rescued", world.bridge.gap_stabilized, "success")
	_cue("raised", world.courtyard.tablet_placed, "stone")
	for index in range(7): _cue("item_%d" % index, world.courtyard.items_done[index], ["paper", "stone", "bell", "rope", "fire", "fire", "fire"][index])
	pulse -= delta
	if (world.bridge.is_pushing or world.bridge.building) and pulse <= 0:
		play("wood")
		pulse = .45


func _hold_kinds(world: Node3D) -> Array[String]:
	var kinds: Array[String] = []
	var bridge: Node3D = world.bridge
	var court: Node3D = world.courtyard
	# Read actual work in all chapters: two humans can stand across a scene boundary.
	for progress in world.cooperation.clue_progress:
		if progress > 0: kinds.append("paper"); break
	if bridge._timber_progress > 0 or bridge.is_pushing or bridge.building: kinds.append("wood")
	if bridge.action_progress > 0 and bridge.step < 5:
		kinds.append(["stone", "paper", "stone", "cloth", "wood"][bridge.step])
	if bridge.step == 5:
		if bridge.steady_held: kinds.append("stone")
		if bridge.rope_held: kinds.append("rope")
		if not world.party.local_coop and bridge.action_progress > 0: kinds.append("stone")
	if not court.tablet_placed and court.action_progress > 0: kinds.append("stone")
	for index in range(7):
		if court.item_progress[index] > 0: kinds.append(["paper", "stone", "bell", "rope", "fire", "fire", "fire"][index])
	var unique: Array[String] = []
	for kind in kinds:
		if kind not in unique and unique.size() < 2: unique.append(kind)
	return unique


func _update_continuous(world: Node3D, delta: float) -> void:
	var ui: CanvasLayer = world.get_node("PartyUI")
	var allowed: bool = not muted and not get_tree().paused and world.party.started and ui.screen == 2 and not world.courtyard.record_open
	var next_holds: Array[String] = []
	if allowed: next_holds = _hold_kinds(world)
	for index in range(2):
		hold_players[index].volume_db = -12 + _volume_db()
		var kind: String = next_holds[index] if next_holds.size() > index else ""
		var previous: String = active_holds[index] if active_holds.size() > index else ""
		if kind != previous or (not kind.is_empty() and not hold_players[index].playing):
			hold_players[index].stop()
			if not kind.is_empty():
				hold_players[index].stream = _loop(HOLDS[kind])
				hold_players[index].play()
	active_holds = next_holds
	var distance: float = 100
	if allowed and world.cooperation.gate_open:
		for actor in world.party.human_players():
			distance = minf(distance, absf(actor.global_position.x - clampf(actor.global_position.x, 32, 38)))
	var target: float = (1 - smoothstep(0, 9, distance)) if allowed else 0.0
	ambience_gain = move_toward(ambience_gain, target, delta * 1.8)
	if ambience_gain > .002 and allowed:
		ambience.volume_db = linear_to_db(ambience_gain) - 17 + _volume_db()
		if not ambience.playing: ambience.play()
	else:
		ambience.stop()
		if not allowed: ambience_gain = 0
