extends Node

const PATHS: Array[String]=["res://assets/video/chapter_01.ogv","res://assets/video/chapter_02.ogv","res://assets/video/chapter_03.ogv","res://assets/video/epilogue.ogv"]
var world: Node3D
var enabled: bool=true
var played: Array[bool]=[false,false,false,false]
var current_film: int=-1
var queued_entry: int=-1
var entry_physics_frame: int=0
var entry_controls: bool=false

func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="ChapterStoryFilms"

func reset_journey() -> void:
	played.fill(false)
	current_film=-1
	queued_entry=-1

func play_before(index: int,after: Callable=Callable()) -> bool:
	if not enabled or played[index]:
		if after.is_valid(): after.call()
		return false
	var ui: CanvasLayer=world.get_node("PartyUI")
	if ui.screen==ui.Screen.FILM: return false
	played[index]=true
	current_film=index
	var complete:=func():
		current_film=-1
		if after.is_valid(): after.call()
	if not ui.play_story_film(PATHS[index],7.0/4.0,complete): complete.call()
	return true

func check_entry() -> bool:
	if not enabled or not world.party.started: return false
	var ui: CanvasLayer=world.get_node("PartyUI")
	if ui.screen!=ui.Screen.GAME or get_tree().paused or world.courtyard.record_open: return false
	if not played[0]: return _queue_entry(0)
	var progress: float=world.player.global_position.x
	for body in world.party.human_players(): progress=maxf(progress,body.global_position.x)
	if world.cooperation.gate_open and progress>=19.7 and not played[1]: return _queue_entry(1)
	# The third film follows the actual lift and settled stele, including direct
	# courtyard previews. Never interrupt transport or the four-person raising rig.
	if world.courtyard.tablet_placed and not world.courtyard.tablet_raising and not world.courtyard.tablet_arriving and not played[2]: return _queue_entry(2)
	return false

func _queue_entry(index: int) -> bool:
	if queued_entry<0:
		queued_entry=index
		entry_physics_frame=Engine.get_physics_frames()+2
		entry_controls=world.party.player.controls_enabled
		world.party.set_controls(false)
	elif Engine.get_physics_frames()>=entry_physics_frame:
		_play_queued()
	return true

func _play_queued() -> void:
	var index: int=queued_entry
	queued_entry=-1
	if index>=0 and enabled and not played[index]:
		world.party.set_controls(entry_controls)
		play_before(index)

func finish_scroll() -> void:
	if enabled and world.courtyard.court_lit and world.ending_reached:
		play_before(3)
