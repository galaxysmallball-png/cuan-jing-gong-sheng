extends CanvasLayer

const UiSkin = preload("res://scripts/interface_skin.gd")
const Playboard = preload("res://scripts/folk_playboard.gd")
const Activities = preload("res://scripts/folk_activity_profiles.gd")
const EXTRAS: Array[String] = ["a_cai_hoe", "a_cai_basket", "baby_carrier", "a_qiang_beam", "a_qiang_knife", "tea_jar", "fire_basin", "flint_pouch", "yu_nan_brocade", "donkey", "garden_item_1", "garden_item_2", "garden_item_3"]
const ATTACHED: Dictionary={"a_cai_basket":["basket",Vector3(.197,.877,.048),Vector3(.19,.22,.19)],"baby_carrier":["carrier",Vector3(0,1.23,-.20),Vector3(.27,.35,.18)],"tea_jar":["teapot",Vector3(-.225,1.06,.146),Vector3(.22,.25,.22)],"fire_basin":["firepan",Vector3(.28,.64,.074),Vector3(.34,.35,.34)],"flint_pouch":["pouch",Vector3(.115,.79,.141),Vector3(.19,.23,.18)],"a_qiang_knife":["sheath",Vector3(.19,.78,.01),Vector3(.22,.40,.22)],"yu_nan_brocade":["brocade",Vector3(-.175,.93,.22),Vector3(.20,.43,.18)]}
var world: Node3D
var items: Dictionary = {}
var seen: Dictionary = {}
var games_done: Array[bool] = [false, false, false]
var active_id: String = ""
var overlay: Control
var heading: Label
var description: Label
var collection_label: Label
var board: Control
var preview: SubViewport
var preview_area: SubViewportContainer
var preview_stage: Node3D
var preview_model: Node3D
var preview_camera: Camera3D
var play_again: Button
var listen_button: Button
var picker_bodies: Dictionary = {}
var court_aliases: Dictionary={}
var reference_image: TextureRect
var reference_button: Button
var reference_credit: RichTextLabel
var next_reference: Button
var reference_index: int = 0
var photo_catalog: Dictionary = {}
var achievement_status: Label
var achievement_entry: Button
var activity_profile: Dictionary = {}
var activity_story: Panel
var activity_portrait: TextureRect
var activity_story_heading: Label
var activity_story_body: Label
var activity_level: Label
var start_activity_button: Button
var completed_items: Dictionary = {}
var practice_dyes: Array[ShaderMaterial] = []
var practice_ink: float = 0
var description_scroll: ScrollContainer
var marked_id: String=""
var location_marker: Label3D
const ISOLATED_PARTS: Dictionary={
	"tea_jar":["BlackClayTeaJar","JarLip","DarkTeaSurface","ClayJarWear"],
	"fire_basin":["CopperCoalPan","CoalPanRim","BrazierFoot","GlowingCoals","CopperPanHandle"],
	"flint_pouch":["HerbAndFlintPouch","PouchFlint","PouchStitchedFlower","PouchDrawstring"],
	"a_cai_basket":["HipBasket","BasketBoundRim","BasketSuspension"],
	"baby_carrier":["Carrier","SquareBatikBabyCarrier","WrappedBabyBody","BoundCarrier","SleepingBaby","Baby"],
	"yu_nan_brocade":["HeldBrocadeSample","BrocadeSample"],
	"a_qiang_beam":["ShoulderFirBeam","Mortise","FirWoodGrain","TimberWear"],
	"a_qiang_knife":["WoodenKnifeSheath","KnifeGrip","KnifePommel","Sheath"]}


func setup(owner_world: Node3D) -> void:
	world = owner_world
	name = "FolkCollection"
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	photo_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/references/folk/catalog.json"))
	for entry in world.get_node("NearbyInteractions").entries:
		if entry.has("sound") or entry.id in EXTRAS:
			items[entry.id] = entry
			_make_picker(entry)
	_build_window()


func can_inspect(id: String) -> bool:
	return items.has(id.get_slice("@",0))


func _make_picker(entry: Dictionary, key: String="") -> void:
	if key.is_empty(): key=entry.id
	var body := StaticBody3D.new()
	body.name = "FolkClick_" + entry.id
	body.collision_layer = 8
	body.collision_mask = 0
	body.set_meta("folk_id", entry.id)
	entry.anchor.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	if entry.has("sound") or entry.anchor.has_meta("standalone_artifact"):
		var bounds: AABB = _bounds(entry.anchor)
		if entry.anchor.has_meta("standalone_artifact"):
			bounds=_bounds(entry.anchor.get_node("Object"))
			bounds=entry.anchor.get_node("Object").transform*bounds
		shape.size = bounds.size.max(Vector3(.5, .5, .5)) + Vector3(.12, .12, .12)
		body.position = bounds.get_center()
	else:
		shape.size = Vector3(.5, .5, .5)
		body.position = entry.offset - Vector3(0, .25, 0)
		if entry.id=="a_qiang_beam":
			shape.size=Vector3(.75,.50,.65)
			body.position=Vector3(.46,1.64,0)
		elif entry.id=="a_qiang_knife":
			shape.size=Vector3(.55,.5,.6)
		elif entry.id=="a_cai_hoe":
			shape.size=Vector3(.23,.32,.19)
			collision.position=Vector3(.39,1.23,-.04)
		elif entry.id=="a_cai_basket": shape.size=Vector3(.19,.22,.19)
		elif entry.id=="baby_carrier": shape.size=Vector3(.27,.35,.18)
	collision.shape = shape
	if ATTACHED.has(entry.id) and not entry.anchor.has_meta("standalone_artifact"): shape.size=ATTACHED[entry.id][2]
	body.add_child(collision)
	if entry.id=="a_cai_hoe":
		var shaft:=CollisionShape3D.new()
		var shaft_shape:=BoxShape3D.new()
		shaft_shape.size=Vector3(.78,.09,.12)
		shaft.shape=shaft_shape
		shaft.position=Vector3(-.02,1.35,-.025)
		body.add_child(shaft)
	picker_bodies[key] = body


func register_court_guests(guests: Array[Node3D]) -> void:
	var nearby: Node=world.get_node("NearbyInteractions")
	for id in ["a_cai_hoe","a_cai_basket","baby_carrier","a_qiang_beam","a_qiang_knife"]:
		var entry: Dictionary=items[id].duplicate()
		entry.anchor=guests[0 if id.begins_with("a_cai") or id=="baby_carrier" else 1]
		entry.chapter=2
		court_aliases[id]=entry
		_make_picker(entry,id+"@court")
		var alias: Dictionary=entry.duplicate()
		alias.id=id+"@court"
		nearby.entries.append(alias)


func active_entry(id: String) -> Dictionary:
	if world.current_space==2 and court_aliases.has(id) and court_aliases[id].anchor.is_visible_in_tree(): return court_aliases[id]
	return items[id]


func picker_key(id: String) -> String:
	return id+"@court" if active_entry(id)!=items[id] else id


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D and node.mesh != null: result.append(node)
	for child in node.get_children(): result.append_array(_meshes(child))
	return result


func _bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for mesh in _meshes(node):
		var part: AABB = (node.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _build_window() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(.025, .04, .05, .78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(72, 66)
	panel.size = Vector2(1136, 592)
	panel.add_theme_stylebox_override("panel", UiSkin.texture_paper())
	overlay.add_child(panel)
	for area in [Rect2(38, 22, 924, 49), Rect2(38, 497, 682, 62)]:
		var backing := ColorRect.new()
		backing.position = area.position
		backing.size = area.size
		backing.color = Color(.94, .88, .73, .91)
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(backing)
	heading = _label(panel, Vector2(42, 25), Vector2(930, 40), 28, UiSkin.VERMILION)
	_button(panel, "收起 · Esc", Vector2(980, 30), Vector2(110, 35), close)
	preview_area = SubViewportContainer.new()
	preview_area.position = Vector2(40, 88)
	preview_area.size = Vector2(430, 410)
	preview_area.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(preview_area)
	preview_area.gui_input.connect(_turn_preview)
	preview = SubViewport.new()
	preview.size = Vector2i(430, 410)
	preview.own_world_3d = true
	preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
	preview_area.add_child(preview)
	preview_stage = Node3D.new()
	preview.add_child(preview_stage)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(.11, .15, .16)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(.8, .81, .75)
	settings.ambient_light_energy = .85
	environment.environment = settings
	preview_stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-28, -25, 0)
	light.light_energy = 1.4
	preview_stage.add_child(light)
	preview_camera = Camera3D.new()
	preview_camera.fov = 35
	preview_stage.add_child(preview_camera)
	description_scroll=ScrollContainer.new()
	description_scroll.position=Vector2(500,90)
	description_scroll.size=Vector2(575,128)
	description_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(description_scroll)
	description = _label(description_scroll, Vector2.ZERO, Vector2(557,120), 18, UiSkin.INK)
	description.custom_minimum_size=Vector2(557,120)
	description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reference_image = TextureRect.new()
	reference_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reference_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(reference_image)
	reference_image.position = Vector2(40, 88)
	reference_image.size = Vector2(430, 322)
	reference_image.visible = false
	reference_credit = RichTextLabel.new()
	reference_credit.position = Vector2(46,414)
	reference_credit.size = Vector2(422,42)
	reference_credit.bbcode_enabled = true
	reference_credit.scroll_active = false
	reference_credit.add_theme_font_override("normal_font",description.get_theme_font("font"))
	reference_credit.add_theme_font_size_override("normal_font_size",preload("res://scripts/interface_skin.gd").text_size(11))
	reference_credit.add_theme_color_override("default_color",UiSkin.INK)
	reference_credit.meta_clicked.connect(func(url): OS.shell_open(str(url)))
	panel.add_child(reference_credit)
	reference_credit.visible = false
	reference_button = _button(panel, "实物照片 · 切换查看", Vector2(46, 461), Vector2(286, 30), _toggle_reference)
	reference_button.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(16))
	reference_button.visible = false
	next_reference = _button(panel,"下一张",Vector2(340,461),Vector2(124,30),_next_reference)
	next_reference.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(14))
	next_reference.visible = false
	board = Playboard.new()
	board.position = Vector2(500, 232)
	board.size = Vector2(550, 260)
	board.completed.connect(_complete_game)
	panel.add_child(board)
	activity_story=Panel.new()
	activity_story.position=board.position
	activity_story.size=board.size
	activity_story.add_theme_stylebox_override("panel",UiSkin.paper())
	panel.add_child(activity_story)
	activity_story_heading=_label(activity_story,Vector2(14,10),Vector2(520,30),19,UiSkin.VERMILION)
	activity_story_heading.add_theme_font_override("font",UiSkin.heading_font())
	activity_portrait=TextureRect.new()
	activity_portrait.position=Vector2(14,48)
	activity_portrait.size=Vector2(92,133)
	activity_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	activity_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	activity_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	activity_story.add_child(activity_portrait)
	activity_story_body=_label(activity_story,Vector2(121,47),Vector2(410,147),15,UiSkin.INK)
	activity_story_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	activity_level=_label(activity_story,Vector2(14,225),Vector2(322,24),12,UiSkin.INK)
	start_activity_button=_button(activity_story,"开始小艺 · Enter",Vector2(350,222),Vector2(176,32),_start_activity)
	start_activity_button.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(15))
	collection_label = _label(panel, Vector2(46, 502), Vector2(480, 25), 15, UiSkin.VERMILION)
	achievement_status=_label(panel,Vector2(46,533),Vector2(500,23),13,UiSkin.INK)
	achievement_entry=_button(panel,"共生见闻 · 成就",Vector2(570,511),Vector2(164,38),func(): world.get_node("PartyUI")._open_achievements())
	achievement_entry.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(14))
	play_again = _button(panel, "继续任务", Vector2(760, 511), Vector2(132, 38), _again)
	listen_button = _button(panel, "听奏示范", Vector2(918, 511), Vector2(132, 38), func(): board.demonstrate())
	overlay.visible = false


func _label(parent: Control, at: Vector2, dimensions: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	var font := preload("res://scripts/interface_skin.gd").body_font()

	label.add_theme_font_override("font", font)
	if size>=24: label.add_theme_font_override("font",UiSkin.heading_font())
	label.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	UiSkin.button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _preview_source(entry: Dictionary) -> Node3D:
	if entry.anchor.has_meta("standalone_artifact"): return entry.anchor.get_node("Object")
	if entry.id=="a_cai_hoe": return entry.anchor.get_node("Character").hoe_detail
	if entry.id.begins_with("garden_item_"): return world.courtyard.landscape.objects[int(entry.id.get_slice("_", 2))]
	if entry.anchor.has_node("Character"): return entry.anchor.get_node("Character")
	return entry.anchor


func _strip(node: Node) -> void:
	node.set_script(null)
	for child in node.get_children():
		if child is CollisionObject3D or child is CanvasLayer:
			node.remove_child(child)
			child.free()
		else: _strip(child)


func open_item(id: String) -> void:
	id=id.get_slice("@",0)
	if not items.has(id) or world.get_node("PartyUI").screen != 2 or world.cooperation.inspected_id >= 0 or world.courtyard.record_open: return
	var entry: Dictionary = active_entry(id)
	if not world.get_node("NearbyInteractions")._available(entry): return
	active_id = id
	if marked_id==id: marked_id=""
	activity_profile=Activities.for_item(id)
	seen[id] = items[id].chapter
	var newly_collected: bool = world.achievements.record_item(id) if world.achievements!=null else false
	achievement_status.text=("新见闻已收入成就册" if newly_collected else "此物已收录，可在成就册重看")+" · 拖动模型可转看"
	heading.text = "行旅器物 · " + entry.title
	reference_image.visible = false
	preview_area.visible = true
	reference_button.visible = photo_catalog.items.has(id)
	reference_credit.visible = false
	next_reference.visible = false
	reference_index = 0
	reference_button.text = "实物照片 · 切换查看"
	preview_area.size.y = 340
	preview.size.y = 340
	if reference_button.visible: _load_reference()
	var text: String = entry.description
	text = text.replace("此处为参考白族扎染的美术表现。", "").replace("此为美术化织架。", "")
	if id == "garden_item_1": text = "石阿朵（白族）的錾子归在木架上。她承接家里的石作手艺，知道怎样护住碑角，也愿与认字、认路的同行互相请教。"
	elif id == "garden_item_2": text = "老箐（彝族）将马铃挂在檐下。它原随驮队走过山路，如今把往来的声响留在共庭；风过铃响，便想起一路相助的人。"
	elif id == "garden_item_3": text = "杨三娘（回族）把红线系在保护架上，给后来人留下醒目的记号。这位货郎走南北、通乡音，也把沿途的人情与手艺带到一处。"
	if text.is_empty(): text = "这件物品随同行者来到院中。手艺、乡音各有来处，护碑、修桥、点灯却由众人一同完成。"
	description.text = text
	description_scroll.scroll_vertical=0
	if is_instance_valid(preview_model): preview_model.free()
	preview_model = _isolate_preview(entry) if ISOLATED_PARTS.has(id) else _preview_source(entry).duplicate(0)
	_strip(preview_model)
	preview_model.position = Vector3.ZERO
	preview_model.rotation = Vector3(0,PI,0) if id=="baby_carrier" else Vector3.ZERO
	preview_model.visible = true
	preview_stage.add_child(preview_model)
	_prepare_practice_cloth()
	var bounds: AABB = _bounds(preview_model)
	var center: Vector3 = bounds.get_center()
	var radius: float = maxf(.22, maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)))
	preview_camera.position = center + Vector3(radius * .16, radius * .12, radius * 2.15)
	preview_camera.look_at(center)
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS if DisplayServer.get_name() != "headless" else SubViewport.UPDATE_DISABLED
	_show_activity_story()
	_update_collection()
	overlay.visible = true
	world.get_node("PartyUI").screen = 8
	world.get_node("PartyUI")._refresh()
	get_tree().paused = true
	world.sfx.play_entry(entry)


func _isolate_preview(entry: Dictionary) -> Node3D:
	if entry.anchor.has_meta("standalone_artifact"):
		var isolated: Node3D=_preview_source(entry).duplicate(0)
		var display_scale:=Transform3D(isolated.basis,Vector3.ZERO)
		for part: Node3D in isolated.get_children(): part.transform=display_scale*part.transform
		isolated.transform=Transform3D.IDENTITY
		return isolated
	var source: Node3D=entry.anchor.get_node("Character")
	var bone: String="beam" if entry.id=="a_qiang_beam" else ATTACHED[entry.id][0]
	var names: Array=[bone,"baby"] if entry.id=="baby_carrier" else [bone]
	return preload("res://scripts/skinned_prop_mesh.gd").extract(source,names)


func _toggle_reference() -> void:
	reference_image.visible = not reference_image.visible
	reference_image.size = Vector2(430, 322)
	preview_area.visible = not reference_image.visible
	reference_credit.visible = reference_image.visible
	next_reference.visible = reference_image.visible and photo_catalog.items[active_id].size()>1
	reference_button.text = "回到三维 · 拖动转看" if reference_image.visible else "实物照片 · 切换查看"
	preview.render_target_update_mode = SubViewport.UPDATE_DISABLED if reference_image.visible or DisplayServer.get_name() == "headless" else SubViewport.UPDATE_ALWAYS


func _load_reference() -> void:
	var photos: Array = photo_catalog.items[active_id]
	var entry: Dictionary = photo_catalog.photos[photos[reference_index]]
	var texture: Texture2D = load(entry.file)
	if entry.has("region"):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(entry.region[0],entry.region[1],entry.region[2],entry.region[3])
		texture = atlas
	reference_image.texture = texture
	var license_link: String = entry.get("license_url","")
	if license_link.is_empty(): license_link = entry.source
	reference_credit.text = "%s\n%s · %s · [url=%s]来源[/url] · [url=%s]授权[/url]" % [entry.title,entry.author,entry.license,entry.source,license_link]
	next_reference.text = "下一张 %d/%d" % [reference_index+1,photos.size()]
	reference_image.tooltip_text = "实物/器型参照；非角色道具原物。"+entry.title


func _next_reference() -> void:
	if active_id.is_empty(): return
	reference_index = (reference_index+1)%photo_catalog.items[active_id].size()
	_load_reference()


func _again() -> void:
	if active_id.is_empty(): return
	if completed_items.has(active_id):
		_show_activity_story()
	elif activity_story.visible:
		_start_activity()
	else:
		# Keep the unfinished board intact, including its current weaving / tea.
		board.visible=true
		board.running=true


func _sync_activity_button() -> void:
	play_again.text="重听故事" if completed_items.has(active_id) else "继续任务"


func _show_activity_story() -> void:
	board.begin_profile(activity_profile,world.sfx)
	practice_ink=0
	for dye in practice_dyes: dye.set_shader_parameter("print_progress",0.0)
	board.visible=false
	activity_story.visible=true
	activity_story_heading.text=activity_profile.speaker+" · 器物里的相遇"
	activity_story_body.text=activity_profile.story
	activity_level.text=activity_profile.title+" · "+activity_profile.level
	var index: int = world.story.SPEAKERS.find(activity_profile.speaker)
	var atlas := AtlasTexture.new()
	if index<4:
		atlas.atlas=world.story.SHEETS[index]
		atlas.region=world.story.BUSTS[index]
	else:
		atlas.atlas=preload("res://scripts/opening_card_draw.gd").CARD_TEXTURES[index]
		var dimensions: Vector2 = atlas.atlas.get_size()
		atlas.region=Rect2(dimensions*Vector2(.30,.08),dimensions*Vector2(.51,.57))
	activity_portrait.texture=atlas
	listen_button.visible=false
	_sync_activity_button()


func _start_activity() -> void:
	if active_id.is_empty() or not activity_story.visible: return
	activity_story.visible=false
	board.visible=true
	board.start()
	listen_button.visible=board.mode==2
	_sync_activity_button()


func _complete_game() -> void:
	games_done[items[active_id].chapter] = true
	completed_items[active_id]=items[active_id].chapter
	_sync_activity_button()
	_update_collection()


func _update_collection() -> void:
	var total: int = world.achievements.collected.size() if world.achievements!=null else seen.size()
	collection_label.text = "本次见闻 %d 件 · 收藏 %d/21 · 器物小艺 %d/21" % [seen.size(),total,completed_items.size()]


func close() -> void:
	if not overlay.visible: return
	overlay.visible = false
	preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
	board.playing_demo = false
	board.running=false
	active_id = ""
	get_tree().paused = false
	world.get_node("PartyUI").screen = 2
	world.get_node("PartyUI")._refresh()


func reset_from(chapter: int) -> void:
	close()
	marked_id=""
	for index in range(chapter, 3): games_done[index] = false
	for key in seen.keys():
		if seen[key] >= chapter: seen.erase(key)
	for key in completed_items.keys():
		if completed_items[key]>=chapter: completed_items.erase(key)


func _process(delta: float) -> void:
	if world == null: return
	if is_instance_valid(location_marker):
		location_marker.visible=not marked_id.is_empty() and not overlay.visible and not get_tree().paused and world.get_node("NearbyInteractions")._available(active_entry(marked_id))
		if location_marker.visible:
			var picker: Node3D=picker_bodies[picker_key(marked_id)]
			var target: Node3D=picker.get_child(0)
			location_marker.global_position=target.global_position+Vector3(0,.40,.10)
	if overlay.visible and board.mode in [0,4,5,7] and world.get_node("PartyUI").screen==8:
		practice_ink=move_toward(practice_ink,board.print_fraction(),delta*2.4)
		for dye in practice_dyes: dye.set_shader_parameter("print_progress",practice_ink)
	if not get_tree().paused and Input.is_action_just_pressed("restart_lesson"): reset_from(0)
	for id in items:
		var entry: Dictionary = items[id]
		var available: bool = world.get_node("NearbyInteractions")._available(entry) and _preview_source(entry).is_visible_in_tree()
		picker_bodies[id].collision_layer = 8 if available else 0
		if id=="a_cai_hoe" or ATTACHED.has(id): _follow_attached_prop(id,entry)
	for id in court_aliases:
		var entry: Dictionary=court_aliases[id]
		var key: String=id+"@court"
		picker_bodies[key].collision_layer=8 if world.get_node("NearbyInteractions")._available(entry) else 0
		if id=="a_cai_hoe" or ATTACHED.has(id): _follow_attached_prop(key,entry)


func _follow_attached_prop(key: String, entry: Dictionary) -> void:
	if entry.anchor.has_meta("standalone_artifact"): return
	var id: String=entry.id
	var model: Node3D=entry.anchor.get_node("Character")
	if id=="a_cai_hoe" and is_instance_valid(model.hoe_detail):
		picker_bodies[key].global_transform=model.hoe_detail.global_transform
		return
	var bone: String=ATTACHED[id][0]
	var center: Vector3=ATTACHED[id][1]
	var index: int=model.skeleton.find_bone(bone)
	var rest: Transform3D=model.skeleton.get_bone_global_rest(index)
	picker_bodies[key].global_transform=model.skeleton.global_transform*model.skeleton.get_bone_global_pose(index)*Transform3D(Basis.IDENTITY,rest.affine_inverse()*center)


func attached_at(screen_point: Vector2) -> String:
	var camera: Camera3D=world.get_viewport().get_camera_3d()
	var selected: String=""
	var nearest: float=1.0
	for key in picker_bodies:
		var id: String=key.get_slice("@",0)
		if id!="a_cai_hoe" and not ATTACHED.has(id): continue
		var body: Node3D=picker_bodies[key]
		if body.get_parent().has_meta("standalone_artifact"): continue
		if body.collision_layer==0: continue
		for collision: CollisionShape3D in body.get_children():
			if camera.is_position_behind(collision.global_position): continue
			var center: Vector2=camera.unproject_position(collision.global_position)
			var padding: Vector2=Vector2(8,8)
			var half: Vector3=collision.shape.size*.5
			for x in [-1,1]:
				for y in [-1,1]:
					for z in [-1,1]:
						var corner: Vector2=camera.unproject_position(collision.to_global(half*Vector3(x,y,z)))
						padding=padding.max((corner-center).abs())
			var difference: Vector2=(screen_point-center)/(padding+Vector2(3,3))
			var distance: float=difference.length()
			if distance<nearest: nearest=distance; selected=id
	return selected


func mark_location(id: String) -> void:
	if not items.has(id): return
	marked_id=id
	if not is_instance_valid(location_marker):
		location_marker=Label3D.new()
		world.add_child(location_marker)
		location_marker.font=UiSkin.heading_font()
		location_marker.font_size=UiSkin.text_size(23)
		location_marker.pixel_size=.006
		location_marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		location_marker.outline_size=7
		location_marker.modulate=Color(1,.85,.45)
	location_marker.text="▼ "+items[id].title


func _prepare_practice_cloth() -> void:
	practice_dyes.clear()
	practice_ink=0
	if int(activity_profile.mode) not in [0,4,5,7]: return
	for mesh in _meshes(preview_model):
		var material: Material = mesh.material_override
		if material is ShaderMaterial and material.shader.resource_path=="res://shaders/trade_textile.gdshader":
			var practice: ShaderMaterial = material.duplicate()
			practice.set_shader_parameter("print_progress",0.0)
			mesh.material_override=practice
			practice_dyes.append(practice)


func _turn_preview(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT and is_instance_valid(preview_model):
		preview_model.rotation.y += event.relative.x * .012


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible:
		if activity_story.visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER,KEY_SPACE]:
			_start_activity()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_5:
			board.choose(event.physical_keycode - KEY_1)
			get_viewport().set_input_as_handled()
		return
	if not world.party.started or get_tree().paused or world.get_node("PartyUI").screen != 2 or world.cooperation.inspected_id >= 0 or world.courtyard.record_open: return
	if event is InputEventKey and event.is_action_pressed("restart_lesson"): reset_from(0); return
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: return
	if world.get_node("PartyUI").blocks_world_click(event.position): return
	var attached_id: String=attached_at(event.position)
	if not attached_id.is_empty():
		open_item(attached_id)
		if overlay.visible: get_viewport().set_input_as_handled(); return
	var camera: Camera3D = world.get_viewport().get_camera_3d()
	var origin: Vector3 = camera.project_ray_origin(event.position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(event.position) * 100, 8)
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_meta("folk_id"):
		open_item(hit.collider.get_meta("folk_id"))
		if overlay.visible: get_viewport().set_input_as_handled()
