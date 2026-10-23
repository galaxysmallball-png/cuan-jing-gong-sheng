extends Node

const TRACKS: Array[AudioStream] = [preload("res://assets/audio/courtyard.wav"), preload("res://assets/audio/creek.wav"), preload("res://assets/audio/garden.wav"), preload("res://assets/audio/finale.wav")]
const TITLES: Array[String] = ["碑院相逢", "踏歌过溪", "暖灯对歌", "万家同欢"]
const SCROLL_TRACK: AudioStream=preload("res://assets/audio/folk_cues_20261020/scroll_festival.wav")
var scroll_arrangement: bool=false
var muted: bool = false
var volume: float = 1.0
var current_track: int = -1
var decks: Array[AudioStreamPlayer] = []
var weights: Array[float] = [0, 0]
var active_deck: int = 1
var transitions: int = 0
var cinematic_active: bool=false


func _ready() -> void:
	name = "SceneMusic"
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in range(2):
		var deck := AudioStreamPlayer.new()
		deck.volume_db = -80
		add_child(deck)
		decks.append(deck)
	for track in TRACKS+[SCROLL_TRACK]:
		track.loop_mode = AudioStreamWAV.LOOP_FORWARD
		track.loop_begin = 0
		track.loop_end = int(round(track.get_length() * track.mix_rate))


func _process(delta: float) -> void:
	for deck in decks: deck.stream_paused=cinematic_active
	if cinematic_active: return
	var world: Node3D = get_parent()
	var target: int = world.current_space if world.party.started else 0
	if world.courtyard.court_lit or world.courtyard.closing or world.courtyard.record_open: target = 3
	var scene_scroll: bool=world.courtyard.landscape.scroll.visible and (world.courtyard.closing or world.courtyard.court_lit)
	var wants_scroll: bool=world.courtyard.record_open or scene_scroll
	if target != current_track or wants_scroll!=scroll_arrangement: _change(target,wants_scroll)
	for index in range(2):
		weights[index] = move_toward(weights[index], 1.0 if index == active_deck else 0.0, delta / 1.6)
		var level: float = -7.0 if current_track == 3 else -9.0
		if world.get_node("PartyUI").screen==world.get_node("PartyUI").Screen.DRAW: level-=4.5
		decks[index].volume_db = -80 if muted or volume <= 0 or weights[index] < 0.0001 else linear_to_db(weights[index] * volume) + level
		if weights[index] == 0 and index != active_deck: decks[index].stop()


func _change(track: int, scroll: bool=false) -> void:
	current_track = track
	scroll_arrangement=scroll
	active_deck = 1 - active_deck
	decks[active_deck].stream = SCROLL_TRACK if scroll else TRACKS[track]
	decks[active_deck].play()
	transitions += 1


func restart_current() -> void:
	current_track = -1


func toggle_mute() -> void:
	muted = not muted


func set_volume(value: float) -> void:
	volume = clampf(value, 0, 1)


func track_title() -> String:
	if scroll_arrangement: return "长卷同欢·升调"
	return TITLES[maxi(0, current_track)]
