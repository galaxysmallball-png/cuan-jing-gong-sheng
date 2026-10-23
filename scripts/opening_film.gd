extends Control

signal completed
const FILM_PATH: String="res://assets/video/opening_story.ogv"
const FILM_RATIO: float=2592.0/1440.0
var player: VideoStreamPlayer
var skip_button: Button
var pause_button: Button
var active: bool=false
var world: Node3D
var frame: AspectRatioContainer
var film_viewport: Viewport
var previous_disable_3d: bool=false

func _ready() -> void:
	name="OpeningStoryFilm"
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var black:=ColorRect.new()
	black.color=Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(black)
	frame=AspectRatioContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.ratio=FILM_RATIO
	frame.stretch_mode=AspectRatioContainer.STRETCH_FIT
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	player=VideoStreamPlayer.new()
	player.expand=true
	player.mouse_filter=Control.MOUSE_FILTER_IGNORE
	player.finished.connect(func(): finish.call_deferred())
	frame.add_child(player)
	pause_button=_button("暂 停",false,toggle_pause)
	skip_button=_button("掠过剧情",true,finish)
	visible=false

func _button(words: String,right: bool,callback: Callable) -> Button:
	var button:=Button.new()
	button.text=words
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT if right else Control.PRESET_BOTTOM_LEFT)
	button.position=Vector2(-186,-66) if right else Vector2(24,-66)
	button.size=Vector2(162,44)
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_override("font",preload("res://scripts/interface_skin.gd").heading_font())
	button.add_theme_font_size_override("font_size",20)
	var panel:=StyleBoxFlat.new()
	panel.bg_color=Color(.035,.045,.045,.66)
	panel.border_color=Color(.75,.64,.43,.7)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal",panel)
	button.add_theme_stylebox_override("hover",panel)
	button.add_theme_stylebox_override("pressed",panel)
	button.add_theme_color_override("font_color",Color(.95,.88,.73))
	button.pressed.connect(callback)
	add_child(button)
	return button

func begin(owner_world: Node3D,path: String=FILM_PATH,ratio: float=FILM_RATIO) -> bool:
	if active: return false
	world=owner_world
	player.stream=load(path)
	if player.stream==null: return false
	frame.ratio=ratio
	active=true
	visible=true
	film_viewport=world.get_viewport()
	previous_disable_3d=film_viewport.disable_3d
	film_viewport.disable_3d=true
	world.music.cinematic_active=true
	pause_button.text="暂 停"
	player.paused=false
	_sync_volume()
	player.play()
	return true

func _process(_delta: float) -> void:
	if active: _sync_volume()

func _sync_volume() -> void:
	player.volume=0 if world.music.muted else world.music.volume

func toggle_pause() -> void:
	if not active: return
	player.paused=not player.paused
	pause_button.text="继 续" if player.paused else "暂 停"

func finish() -> void:
	if not active: return
	active=false
	player.stop()
	player.paused=false
	player.stream=null
	visible=false
	if is_instance_valid(film_viewport): film_viewport.disable_3d=previous_disable_3d
	world.music.cinematic_active=false
	completed.emit()

func handle_input(event: InputEvent) -> void:
	if not active or not event is InputEventKey: return
	if event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ENTER,KEY_KP_ENTER,KEY_ESCAPE: finish()
			KEY_SPACE: toggle_pause()
			KEY_M: world.music.toggle_mute()
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if active and is_instance_valid(film_viewport): film_viewport.disable_3d=previous_disable_3d
