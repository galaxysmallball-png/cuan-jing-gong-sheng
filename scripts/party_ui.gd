extends CanvasLayer

enum Screen { TITLE, INTRO, GAME, ARCHIVE, SATCHEL, DRAW, HELP, CULTURE, INSPECT, SETTINGS, HISTORY, ACHIEVEMENTS, ARRANGE, FILM }
var opening_film: Control
var _film_input_frame: int=-1
var _film_return: Screen=Screen.TITLE
var _film_was_paused: bool=false
var _film_controls: bool=false
var _film_completion: Callable
const CultureContent = preload("res://scripts/culture_content.gd")
const ReadingRoom = preload("res://scripts/reading_room.gd")
var reading_room: Control
var culture_button: Button
var previous_page: Button
var return_title: Button
var culture_index: int = 0
const UiStyle = preload("res://scripts/interface_skin.gd")
const ControlsHint = preload("res://scripts/controls_hint.gd")
const JourneyGoal = preload("res://scripts/journey_goal.gd")
var goal_panel: Panel
var restart_button: Button
var music_button: Button
var effects_button: Button
var effects_slider: HSlider
var effects_level: Label
var music_slider: HSlider
var audio_settings: Control
var sound_button: Button
var _settings_return: Screen = Screen.TITLE
var _settings_was_paused: bool = false
const COVER_IMAGE = preload("res://assets/interface/title_cover.png")
var title_art: TextureRect
var hint_button: Button
var hint_panel: Control
const FieldSatchel = preload("res://scripts/field_satchel.gd")
const OpeningCardDraw = preload("res://scripts/opening_card_draw.gd")
var opening_draw: Control
var _draw_input_frame: int = -1
var _accept_key_down: bool = false
var _skip_key_down: bool = false
var screen: Screen = Screen.TITLE
var intro_index: int = 0
var party: Node3D
var cover: ColorRect
var heading: Label
var detail: Label
var primary: Button
var secondary: Button
var chapter_preview: Button
var garden_preview: Button
var hud: Label
var _action_frame: int = -1
var satchel: Control
var satchel_button: Button
var satchel_notice: Label
var satchel_notice_frame: Panel
var _clue_chapter: Node3D
var _last_clue_count: int = 0
var _notice_seconds: float = 0.0
var _notice_keepsake: bool = false
var _satchel_input_frame: int = -1
var achievement_button: Button
var _achievement_return: Screen = Screen.TITLE
var _achievement_was_paused: bool = false


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	party = get_parent().get_node("Party")
	cover = ColorRect.new()
	cover.color = Color(0.025, 0.04, 0.055, 0.95)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cover)
	title_art = TextureRect.new()
	title_art.texture = COVER_IMAGE
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(title_art)
	reading_room = ReadingRoom.new()
	cover.add_child(reading_room)
	heading = _label(Vector2(150, 140), Vector2(980, 70), 36)
	detail = _label(Vector2(160, 245), Vector2(960, 220), 23)
	primary = _button("", Vector2(450, 495), _primary)
	secondary = _button("跳过介绍 / Esc", Vector2(450, 565), _skip)
	chapter_preview = _button("直接试玩第二幕 · 断溪古道", Vector2(450, 565), _begin_creek_preview)
	garden_preview = _button("直接试玩第三幕 · 灯火共庭", Vector2(450, 625), _begin_garden_preview)
	culture_button = _button("识爨 · 文化记", Vector2(32, 22), _open_culture)
	culture_button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(16))
	culture_button.size = Vector2(180, 36)
	previous_page = _button("上一位", Vector2(620, 640), _previous_page)
	return_title = _button("返回封面", Vector2(32, 24), _return_title)
	return_title.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(16))
	return_title.size = Vector2(140, 36)
	hud = Label.new()
	hud.position = Vector2(24, 75)
	hud.size = Vector2(540, 58)
	hud.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(16))
	hud.add_theme_font_override("font", heading.get_theme_font("font"))
	hud.add_theme_color_override("font_color", Color(0.96, 0.82, 0.56))
	add_child(hud)
	_clue_chapter = get_parent().get_node("Spaces/Space01/Cooperation")
	satchel_button = Button.new()
	satchel_button.position = Vector2(860,22)
	satchel_button.size = Vector2(140,36)
	satchel_button.focus_mode = Control.FOCUS_NONE
	satchel_button.tooltip_text = "翻看已经收入的见闻；在碑前拼字时也可打开。"
	satchel_button.add_theme_font_override("font", heading.get_theme_font("font"))
	satchel_button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(17))
	satchel_button.pressed.connect(_open_satchel)
	UiStyle.button(satchel_button)
	add_child(satchel_button)
	hint_button = Button.new()
	hint_button.position = Vector2(24,22)
	hint_button.size = Vector2(92,36)
	hint_button.text = "提 示"
	hint_button.add_theme_font_override("font", heading.get_theme_font("font"))
	hint_button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(17))
	UiStyle.button(hint_button)
	hint_button.pressed.connect(_toggle_hint)
	add_child(hint_button)
	goal_panel = JourneyGoal.new()
	add_child(goal_panel)
	restart_button = Button.new()
	restart_button.position = Vector2(1014, 22)
	restart_button.size = Vector2(136, 36)
	restart_button.text = "重新开始"
	restart_button.tooltip_text = "重新开始当前关卡，保留此前通关与本轮角色归属"
	restart_button.add_theme_font_override("font", heading.get_theme_font("font"))
	restart_button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(16))
	UiStyle.button(restart_button)
	restart_button.pressed.connect(_restart_scene)
	add_child(restart_button)
	sound_button = Button.new()
	sound_button.position = Vector2(1164, 22)
	sound_button.size = Vector2(92, 36)
	sound_button.text = "声音设置"
	sound_button.add_theme_font_override("font", heading.get_theme_font("font"))
	sound_button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(15))
	UiStyle.button(sound_button)
	sound_button.pressed.connect(_open_audio_settings)
	add_child(sound_button)
	satchel_notice = Label.new()
	satchel_notice.position = Vector2(1000,66)
	satchel_notice.size = Vector2(250,42)
	satchel_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	satchel_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	satchel_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	satchel_notice_frame=Panel.new()
	satchel_notice_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	satchel_notice_frame.add_theme_stylebox_override("panel",UiStyle.notice_paper())
	add_child(satchel_notice_frame)
	satchel_notice.add_theme_font_override("font", heading.get_theme_font("font"))
	satchel_notice.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(16))
	satchel_notice.add_theme_color_override("font_color", UiStyle.VERMILION)
	satchel_notice.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	satchel_notice.add_theme_constant_override("shadow_offset_x", 1)
	satchel_notice.add_theme_constant_override("shadow_offset_y", 2)
	add_child(satchel_notice)
	satchel = FieldSatchel.new()
	satchel.close_requested.connect(_close_satchel)
	add_child(satchel)
	opening_draw = OpeningCardDraw.new()
	opening_draw.continue_requested.connect(_finish_draw)
	opening_draw.cancel_requested.connect(_cancel_draw)
	add_child(opening_draw)
	hint_panel = ControlsHint.new()
	hint_panel.close_requested.connect(_close_hint)
	add_child(hint_panel)
	audio_settings = preload("res://scripts/audio_settings.gd").new()
	add_child(audio_settings)
	audio_settings.setup(get_parent())
	audio_settings.close_requested.connect(_close_audio_settings)
	music_button = audio_settings.music_button
	effects_button = audio_settings.effects_button
	effects_slider = audio_settings.effects_slider
	effects_level = audio_settings.effects_level
	music_slider = audio_settings.music_slider
	achievement_button=Button.new()
	achievement_button.position=Vector2(700,22)
	achievement_button.size=Vector2(146,36)
	achievement_button.add_theme_font_override("font",heading.get_theme_font("font"))
	achievement_button.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(14))
	achievement_button.tooltip_text="共生见闻成就册：按民族翻看已收录器物与交融成就。C 打开。"
	UiStyle.button(achievement_button)
	achievement_button.pressed.connect(_open_achievements)
	add_child(achievement_button)
	opening_film=preload("res://scripts/opening_film.gd").new()
	add_child(opening_film)
	opening_film.completed.connect(_film_finished)
	_refresh()


func _label(at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if font_size>=28: label.add_theme_font_override("font",UiStyle.heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(font_size))
	cover.add_child(label)
	return label


func _button(text: String, at: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = Vector2(380, 50)
	button.add_theme_font_override("font", heading.get_theme_font("font"))
	button.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(21))
	UiStyle.button(button, true, true)
	button.pressed.connect(callback)
	cover.add_child(button)
	return button


func _input(event: InputEvent) -> void:
	if screen==Screen.FILM:
		opening_film.handle_input(event)
		return
	if screen==Screen.ARRANGE:
		get_parent().experience.handle_design_input(event)
		return
	if screen==Screen.ACHIEVEMENTS:
		if event is InputEventKey:
			if event.pressed and not event.echo:
				if event.physical_keycode in [KEY_C,KEY_ESCAPE]: _close_achievements()
				elif event.physical_keycode==KEY_LEFT: get_parent().achievements.turn_page(-1)
				elif event.physical_keycode==KEY_RIGHT: get_parent().achievements.turn_page(1)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_C:
		_open_achievements()
		get_viewport().set_input_as_handled()
		return
	if screen == Screen.SETTINGS:
		if event is InputEventKey:
			if event.pressed and not event.echo:
				if event.physical_keycode == KEY_ESCAPE: _close_audio_settings()
				elif event.physical_keycode == KEY_M: get_parent().music.toggle_mute()
				elif event.physical_keycode == KEY_N: get_parent().sfx.toggle_mute()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_N:
		get_parent().sfx.toggle_mute()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and screen != Screen.GAME \
		and event.physical_keycode in [KEY_ENTER, KEY_ESCAPE, KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_H, KEY_B, KEY_F2]:
		get_parent().sfx.play("button")
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		get_parent().music.toggle_mute()
		get_viewport().set_input_as_handled()
		return
	if screen == Screen.INSPECT:
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			get_parent().folk.close()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		if event.is_action("ui_accept"): _accept_key_down = event.pressed
		if event.is_action("skip_intro"): _skip_key_down = event.pressed
		if event.pressed and not event.echo and screen in [Screen.TITLE, Screen.INTRO, Screen.ARCHIVE, Screen.CULTURE]:
			if event.is_action_pressed("ui_accept"):
				_primary()
				get_viewport().set_input_as_handled()
				return
			if screen == Screen.INTRO and event.is_action_pressed("skip_intro"):
				_skip()
				get_viewport().set_input_as_handled()
				return
			if screen == Screen.CULTURE and event.is_action_pressed("skip_intro"):
				_return_title()
				get_viewport().set_input_as_handled()
				return
			if screen in [Screen.INTRO, Screen.CULTURE] and event.physical_keycode == KEY_LEFT:
				_previous_page()
				get_viewport().set_input_as_handled()
				return
	if event is InputEventKey and event.pressed and not event.echo:
		if screen == Screen.HELP:
			if event.physical_keycode in [KEY_H, KEY_ESCAPE]: _close_hint()
			get_viewport().set_input_as_handled()
			return
		if screen == Screen.GAME and event.physical_keycode == KEY_H:
			_toggle_hint()
			get_viewport().set_input_as_handled()
			return
	if screen == Screen.DRAW:
		if event is InputEventKey:
			if event.pressed and not event.echo:
				if event.is_action_pressed("ui_accept"): _draw_action(true)
				elif event.is_action_pressed("skip_intro"): _draw_action(false)
			get_viewport().set_input_as_handled()
		return
	if not party.started or not event is InputEventKey:
		return
	if event.is_action_pressed("open_satchel") and not event.echo and screen in [Screen.GAME, Screen.SATCHEL]:
		if screen == Screen.SATCHEL:
			_close_satchel()
		else:
			_open_satchel()
		get_viewport().set_input_as_handled()
	elif screen == Screen.SATCHEL:
		if event.is_action_pressed("skip_intro") and not event.echo:
			_close_satchel()
		# Consume Esc before the underlying stele viewer can close as well.
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var modal_changed: bool = _satchel_input_frame == Engine.get_process_frames()
	if screen==Screen.FILM and _film_input_frame!=Engine.get_process_frames():
		if (not _accept_key_down and Input.is_action_just_pressed("ui_accept")) or (not _skip_key_down and Input.is_action_just_pressed("skip_intro")):
			opening_film.finish()
	if screen == Screen.DRAW:
		if not _accept_key_down and Input.is_action_just_pressed("ui_accept"): _draw_action(true)
		elif not _skip_key_down and Input.is_action_just_pressed("skip_intro"): _draw_action(false)
	elif not _accept_key_down and not modal_changed and Input.is_action_just_pressed("ui_accept") and screen in [Screen.TITLE, Screen.INTRO, Screen.ARCHIVE, Screen.CULTURE]:
		_primary()
	if not _skip_key_down and Input.is_action_just_pressed("skip_intro") and screen == Screen.INTRO:
		_skip()
	if not modal_changed and Input.is_action_just_pressed("open_archive") and party.started:
		if screen == Screen.ARCHIVE:
			_close_archive()
		elif screen == Screen.GAME:
			_open_archive()
	_update_satchel_entry(delta)
	var gameplay: bool = screen == Screen.GAME and not get_parent().courtyard.record_open
	goal_panel.visible = screen == Screen.GAME and not get_parent().courtyard.record_open and _clue_chapter.inspected_id < 0
	goal_panel.set_compact(_clue_chapter.inspected_id >= 0)
	restart_button.visible = gameplay
	sound_button.visible = screen in [Screen.TITLE, Screen.GAME, Screen.HELP] and not get_parent().courtyard.record_open
	audio_settings.sync()
	_sync_achievement_entry()
	var objective: Dictionary = get_parent().objective()
	goal_panel.show_goal(objective.text, objective.progress)
	goal_panel.show_interaction(get_parent().interaction_progress())


func _open_audio_settings() -> void:
	if screen not in [Screen.TITLE, Screen.GAME, Screen.HELP] or get_parent().courtyard.record_open: return
	_settings_return = screen
	_settings_was_paused = get_tree().paused
	screen = Screen.SETTINGS
	audio_settings.visible = true
	audio_settings.sync()
	get_tree().paused = true


func _close_audio_settings() -> void:
	if screen != Screen.SETTINGS: return
	screen = _settings_return
	audio_settings.visible = false
	get_tree().paused = _settings_was_paused
	_satchel_input_frame = Engine.get_process_frames()
	_refresh()


func _restart_scene() -> void:
	if screen != Screen.GAME: return
	get_parent().restart_current_scene()
	_refresh()


func blocks_world_click(at: Vector2) -> bool:
	var rewards: Node3D=get_parent().celebration_rewards
	if rewards!=null and rewards.button.visible and rewards.button.get_global_rect().has_point(at): return true
	if get_parent().mobile_controls!=null and get_parent().mobile_controls.blocks(at): return true
	if screen==Screen.ARRANGE: return true
	if get_parent().experience!=null and get_parent().experience.blocks_world_click(at): return true
	if get_parent().guidance!=null and get_parent().guidance.blocks_world_click(at): return true
	if audio_settings.visible: return true
	for control in [goal_panel, restart_button, sound_button, hint_button, satchel_button, achievement_button]:
		if control.visible and control.get_global_rect().has_point(at): return true
	return false


func _sync_achievement_entry() -> void:
	if achievement_button==null: return
	achievement_button.visible=screen in [Screen.TITLE,Screen.GAME] and (get_parent().courtyard==null or not get_parent().courtyard.record_open)
	achievement_button.position=Vector2(230,22) if screen==Screen.TITLE else Vector2(700,22)
	achievement_button.text="共生见闻 · 成就" if screen==Screen.TITLE else "共生见闻 %d/21"%(get_parent().achievements.collected.size() if get_parent().achievements!=null else 0)


func _open_achievements() -> void:
	if screen not in [Screen.TITLE,Screen.GAME,Screen.INSPECT,Screen.SATCHEL] or get_parent().courtyard.record_open or get_parent().achievements==null: return
	_achievement_return=screen
	_achievement_was_paused=get_tree().paused
	screen=Screen.ACHIEVEMENTS
	get_tree().paused=true
	get_parent().achievements.open_book()
	_refresh()


func _close_achievements() -> void:
	if screen!=Screen.ACHIEVEMENTS: return
	get_parent().achievements.overlay.visible=false
	screen=_achievement_return
	get_tree().paused=_achievement_was_paused
	_satchel_input_frame=Engine.get_process_frames()
	_refresh()


func _update_satchel_entry(delta: float) -> void:
	var count: int = _clue_chapter.clues.count(true)+int(_clue_chapter.comparison_complete)
	if count > _last_clue_count:
		_notice_keepsake=false
		satchel_notice.text = "新线索已放入包裹"
		_notice_seconds = 8.0
	elif count < _last_clue_count:
		_notice_seconds = 0.0
	_last_clue_count = count
	if screen == Screen.GAME and not get_tree().paused:
		_notice_seconds = maxf(0.0, _notice_seconds - delta)
	satchel_button.text = "包裹  %d / 5" % count
	var inspecting: bool = _clue_chapter.inspected_id>=0
	UiStyle.layout_notice(satchel_notice_frame,satchel_notice,Vector2(650,112) if inspecting else Vector2(1256,72),inspecting)
	var viewing_scroll: bool = get_parent().courtyard.record_open
	hint_button.visible = screen in [Screen.GAME, Screen.HELP] and not viewing_scroll
	satchel_button.visible = screen == Screen.GAME and not viewing_scroll
	satchel_notice.visible = screen == Screen.GAME and not viewing_scroll and not get_parent().courtyard.tablet_arriving and _notice_seconds > 0

	satchel_notice_frame.visible=satchel_notice.visible


func notify_keepsake(title: String) -> void:
	satchel_notice.text=title+"已放入包裹"
	_notice_seconds=8
	_notice_keepsake=true


func _open_satchel() -> void:
	if screen != Screen.GAME or not party.started:
		return
	screen = Screen.SATCHEL
	_satchel_input_frame = Engine.get_process_frames()
	satchel.show_notes(_clue_chapter.clues, _clue_chapter.CLUES, _clue_chapter.comparison_complete)
	if _notice_keepsake and _notice_seconds>0: satchel._show_keepsakes(true)
	get_tree().paused = true
	_refresh()


func _toggle_hint() -> void:
	if screen == Screen.HELP:
		_close_hint()
	elif screen == Screen.GAME and not get_parent().courtyard.record_open:
		screen = Screen.HELP
		hint_panel.show_for(party, get_parent().tip_label.text)
		get_tree().paused = true
		_refresh()


func _close_hint() -> void:
	if screen != Screen.HELP: return
	screen = Screen.GAME
	hint_panel.visible = false
	get_tree().paused = false
	_refresh()


func _close_satchel() -> void:
	if screen != Screen.SATCHEL:
		return
	screen = Screen.GAME
	_satchel_input_frame = Engine.get_process_frames()
	satchel.visible = false
	get_tree().paused = false
	_refresh()


func _primary() -> void:
	if _action_frame == Engine.get_process_frames():
		return
	_action_frame = Engine.get_process_frames()
	if screen == Screen.TITLE:
		_begin_film()
	elif screen == Screen.INTRO:
		intro_index += 1
		if intro_index >= CultureContent.PEOPLE.size():
			_begin_film()
	elif screen == Screen.CULTURE:
		if culture_index < CultureContent.CULTURE.size() - 1: culture_index += 1
		else: _return_title()
	elif screen == Screen.ARCHIVE:
		_close_archive()
	_refresh()


func _open_culture() -> void:
	if screen != Screen.TITLE: return
	culture_index = 0
	screen = Screen.CULTURE
	_refresh()


func _previous_page() -> void:
	if screen == Screen.INTRO: intro_index = maxi(0, intro_index - 1)
	elif screen == Screen.CULTURE: culture_index = maxi(0, culture_index - 1)
	_refresh()


func _return_title() -> void:
	if screen not in [Screen.INTRO, Screen.CULTURE]: return
	screen = Screen.TITLE
	_refresh()


func _skip() -> void:
	if screen == Screen.TITLE:
		screen = Screen.INTRO
		intro_index = 0
		_refresh()
	elif screen == Screen.INTRO:
		_begin_film()
		_refresh()


func _begin_film() -> void:
	if party.started or screen==Screen.FILM: return
	if not play_story_film(opening_film.FILM_PATH,opening_film.FILM_RATIO,_begin_draw):
		_begin_draw()


func play_story_film(path: String,ratio: float,after: Callable=Callable()) -> bool:
	if screen==Screen.FILM: return false
	if not opening_film.begin(get_parent(),path,ratio): return false
	_film_return=screen
	_film_was_paused=get_tree().paused
	_film_controls=party.started and party.player.controls_enabled
	_film_completion=after
	screen=Screen.FILM
	_film_input_frame=Engine.get_process_frames()
	party.set_controls(false)
	get_tree().paused=true
	primary.release_focus()
	_refresh()
	return true


func _film_finished() -> void:
	if screen!=Screen.FILM: return
	screen=_film_return
	get_tree().paused=_film_was_paused
	party.set_controls(_film_controls)
	var after: Callable=_film_completion
	_film_completion=Callable()
	_refresh()
	if after.is_valid(): after.call()


func _begin_draw() -> void:
	if party.started: return
	var chosen: Array[int] = OpeningCardDraw.choose_roles(2 if party.local_coop else 1)
	if not opening_draw.begin(chosen): return
	screen = Screen.DRAW
	_draw_input_frame = Engine.get_process_frames()
	party.set_controls(false)
	get_tree().paused = true
	primary.release_focus()
	secondary.release_focus()
	_refresh()


func _draw_action(accept: bool) -> void:
	if screen != Screen.DRAW or _draw_input_frame == Engine.get_process_frames(): return
	_draw_input_frame = Engine.get_process_frames()
	if not opening_draw.is_ready(): opening_draw.reveal_now()
	elif accept: _finish_draw()


func _finish_draw() -> void:
	if screen != Screen.DRAW or not opening_draw.is_ready(): return
	if not party.assign_opening_roles(opening_draw.result_roles): return
	opening_draw.stop()
	_begin_game()
	get_parent().chapter_films.play_before(0)
	_refresh()


func _cancel_draw() -> void:
	if screen != Screen.DRAW: return
	opening_draw.stop()
	get_tree().paused = false
	screen = Screen.TITLE
	_action_frame = Engine.get_process_frames()
	_refresh()


func _begin_game() -> void:
	if not party.started:
		get_parent().reset_journey_collections()
	get_tree().paused = false
	screen = Screen.GAME
	party.started = true
	party.set_controls(true)
	primary.release_focus()
	secondary.release_focus()
	chapter_preview.release_focus()
	garden_preview.release_focus()


func _begin_creek_preview() -> void:
	if screen != Screen.TITLE: return
	_begin_game()
	get_parent().chapter_films.played[0]=true
	get_parent().chapter_films.play_before(1,get_parent().start_creek_preview)
	_refresh()


func _begin_garden_preview() -> void:
	if screen != Screen.TITLE: return
	_begin_game()
	get_parent().chapter_films.played[0]=true
	get_parent().chapter_films.played[1]=true
	get_parent().start_garden_preview()
	_refresh()


func _open_archive() -> void:
	screen = Screen.ARCHIVE
	get_tree().paused = true
	_refresh()


func _close_archive() -> void:
	get_tree().paused = false
	screen = Screen.GAME
	primary.release_focus()
	_refresh()


func _refresh() -> void:
	if screen == Screen.SETTINGS: return
	_sync_achievement_entry()
	UiStyle.button(achievement_button,false,screen==Screen.TITLE)
	for button in [primary, secondary, chapter_preview, garden_preview, culture_button, previous_page, return_title]:
		UiStyle.button(button, true, screen == Screen.TITLE)
	UiStyle.button(sound_button, false, screen == Screen.TITLE)
	cover.visible = screen in [Screen.TITLE, Screen.INTRO, Screen.ARCHIVE, Screen.CULTURE]
	satchel.visible = screen == Screen.SATCHEL
	satchel_button.visible = screen == Screen.GAME
	satchel_notice.visible = screen == Screen.GAME and not get_parent().courtyard.tablet_arriving and _notice_seconds > 0
	hud.visible = false
	get_parent().get_node("Guide/RoomName").visible = screen in [Screen.GAME, Screen.HELP]
	get_parent().get_node("Guide/Tip").visible = false
	hint_button.visible = screen in [Screen.GAME, Screen.HELP]
	hint_panel.visible = screen == Screen.HELP
	title_art.visible = screen == Screen.TITLE
	reading_room.visible = screen in [Screen.INTRO, Screen.CULTURE]
	culture_button.visible = screen == Screen.TITLE
	previous_page.visible = screen in [Screen.INTRO, Screen.CULTURE]
	return_title.visible = screen in [Screen.INTRO, Screen.CULTURE]
	heading.visible = screen != Screen.TITLE
	detail.visible = screen != Screen.TITLE
	secondary.visible = screen in [Screen.TITLE, Screen.INTRO]
	chapter_preview.visible = screen == Screen.TITLE
	garden_preview.visible = screen == Screen.TITLE
	heading.position = Vector2(150, 140)
	heading.size = Vector2(980, 70)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	previous_page.position = Vector2(620, 640)
	detail.position = Vector2(160, 245)
	detail.size = Vector2(960, 220)
	detail.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(23))
	primary.position = Vector2(450, 495)
	primary.size = Vector2(380, 50)
	secondary.position = Vector2(450, 565)
	secondary.size = Vector2(380, 50)
	secondary.text = "掠过小传 · Esc"
	secondary.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(21))
	if screen == Screen.TITLE:
		primary.position = Vector2(500, 650)
		primary.size = Vector2(280, 48)
		heading.text = "爨境·共生"
		detail.text = "八方相逢，四人同行\n入场抽取同行者，共护碑石入城\n同键盘双人合作 · 每人控制一名，另两名跟随\n1P：WASD 前后左右、空格跳、E 操作\n2P：方向键移动、小键盘Enter跳、P/小键盘0操作\n清代护碑故事的虚构演绎" if party.local_coop else "八方相逢，四人同行\n入场抽取同行者 · 另三名伙伴跟随\n三个连续空间 · 单人操控与伙伴合作\n清代护碑故事的虚构演绎"
		primary.text = "启 程 同 行"
		secondary.position = Vector2(32, 660)
		secondary.size = Vector2(150, 34)
		secondary.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(15))
		secondary.text = "人物小传"
		chapter_preview.position = Vector2(876, 660)
		garden_preview.position = Vector2(1070, 660)
		chapter_preview.size = Vector2(180, 34)
		garden_preview.size = Vector2(180, 34)
		chapter_preview.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(15))
		garden_preview.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(15))
		chapter_preview.text = "试玩 · 断溪古道"
		garden_preview.text = "试玩 · 灯火共庭"
		chapter_preview.size = Vector2(180, 34)
		garden_preview.size = Vector2(180, 34)
	elif screen == Screen.INTRO:
		reading_room.show_person(intro_index)
		heading.position = Vector2(110, 55)
		heading.size = Vector2(820, 52)
		heading.text = "行 旅 人 物 志"
		heading.add_theme_color_override("font_color", UiStyle.INK)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		detail.visible = false
		primary.position = Vector2(940, 640)
		primary.text = "启程抽牌" if intro_index == CultureContent.PEOPLE.size() - 1 else "下一位"
		primary.size = Vector2(220, 44)
		previous_page.text = "上一位"
		previous_page.disabled = intro_index == 0
		previous_page.size = Vector2(140, 44)
		secondary.text = "启程抽牌"
		secondary.position = Vector2(110, 640)
		secondary.size = Vector2(180, 44)
	elif screen == Screen.CULTURE:
		reading_room.show_culture(culture_index)
		heading.position = Vector2(120, 60)
		heading.size = Vector2(890, 52)
		heading.text = CultureContent.CULTURE[culture_index].title
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		heading.add_theme_color_override("font_color", UiStyle.INK)
		detail.visible = false
		primary.position = Vector2(940, 640)
		primary.text = "返回封面" if culture_index == 3 else "下一页"
		primary.size = Vector2(220, 44)
		previous_page.position = Vector2(110, 640)
		previous_page.text = "上一页"
		previous_page.disabled = culture_index == 0
		previous_page.size = Vector2(140, 44)
	elif screen == Screen.ARCHIVE:
		heading.position.y = 90
		detail.position = Vector2(120, 185)
		detail.size = Vector2(1040, 360)
		detail.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(19))
		primary.position.y = 610
		heading.text = "文化与旅程档案"
		detail.text = get_parent().archive_text()
		primary.text = "返回游戏 / F2"
