extends CanvasLayer

const Content = preload("res://scripts/achievement_content.gd")
const UiSkin = preload("res://scripts/interface_skin.gd")
const Threads = preload("res://scripts/achievement_threads.gd")
const PAGE_SIZE: int = 4
var world: Node3D
var collected: Dictionary = {}
var unlocked: Dictionary = {}
var overlay: Control
var summary: Label
var section: Label
var footer: Label
var tabs: Dictionary = {}
var cards: Array[Button] = []
var card_images: Array[TextureRect] = []
var card_titles: Array[Label] = []
var card_meta: Array[Label] = []
var card_states: Array[Label] = []
var card_groups: Array[Label] = []
var card_marks: Array[Label] = []
var card_bars: Array[ProgressBar] = []
var previous: Button
var next: Button
var page_label: Label
var detail_title: Label
var detail_meta: Label
var detail_photo: TextureRect
var detail_credit: RichTextLabel
var detail_note: Label
var detail_locked: Label
var detail_required: RichTextLabel
var photo_next: Button
var locate_button: Button
var threads: Control
var selected_group: String = "全部"
var selected_id: String = ""
var selected_photo: int = 0
var page: int = 0
var visible_ids: Array[String] = []
var font: Font
var toast: Panel
var toast_text: Label
var toast_button: Button
var pending_toast: String = ""
var toast_left: float = 0


func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="AchievementBook"
	layer=16
	process_mode=Node.PROCESS_MODE_ALWAYS
	_build()
	reset_session()


func group_count(group: String) -> int:
	var count: int = 0
	for id in collected:
		if Content.ITEMS[id].group==group: count+=1
	return count


func group_total(group: String) -> int:
	var count: int = 0
	for id in Content.ITEMS:
		if Content.ITEMS[id].group==group: count+=1
	return count


func connected_groups() -> int:
	var count: int = 0
	for group in Content.GROUPS:
		if group!="共用器物" and group_count(group)>0: count+=1
	return count


func badge_progress(badge: Dictionary) -> Vector2i:
	if badge.has("minimum"): return Vector2i(mini(collected.size(),badge.minimum),badge.minimum)
	var done: int = 0
	for id in badge.items:
		if collected.has(id): done+=1
	var total: int = badge.items.size()
	if badge.has("groups"):
		done+=mini(connected_groups(),badge.groups)
		total+=int(badge.groups)
	return Vector2i(done,total)


func record_item(id: String) -> bool:
	if not Content.ITEMS.has(id) or collected.has(id): return false
	var now: String = Time.get_datetime_string_from_system()
	collected[id]=now
	var new_titles: Array[String] = []
	for badge in Content.BADGES:
		var progress: Vector2i = badge_progress(badge)
		if progress.x==progress.y and not unlocked.has(badge.id):
			unlocked[badge.id]=now
			new_titles.append(badge.title)
	pending_toast="新收录 · "+world.folk.items[id].title+"\n"+("成就解锁 · "+"、".join(new_titles) if not new_titles.is_empty() else "%s · 共生见闻 %d/21"%[Content.ITEMS[id].group,collected.size()])
	toast_left=5
	if not new_titles.is_empty(): world.sfx.play("success")
	_sync_collection_reward()
	return true


func reset_session() -> void:
	collected.clear()
	unlocked.clear()
	_sync_collection_reward()
	pending_toast=""
	toast_left=0
	selected_group="全部"
	selected_id=""
	selected_photo=0
	page=0
	if is_instance_valid(overlay):
		toast.visible=false
		_refresh()


func _sync_collection_reward() -> void:
	var all_complete: bool=not Content.BADGES.is_empty()
	for badge in Content.BADGES:
		if not unlocked.has(badge.id): all_complete=false
	world.courtyard.landscape.collection_reward.set_complete(all_complete)


func _build() -> void:
	font=preload("res://scripts/interface_skin.gd").body_font()

	overlay=Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color(.018,.03,.03,.95)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var paper := Panel.new()
	paper.position=Vector2(40,42)
	paper.size=Vector2(1200,636)
	paper.add_theme_stylebox_override("panel",UiSkin.texture_paper())
	paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(paper)
	var header_paper := ColorRect.new()
	header_paper.position=Vector2(68,62)
	header_paper.size=Vector2(1028,80)
	header_paper.color=Color(.96,.90,.76,.94)
	header_paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(header_paper)
	var title := _label(overlay,Vector2(70,62),Vector2(330,52),34,"共 生 见 闻",UiSkin.VERMILION)
	var title_font: Font = UiSkin.heading_font()
	title.add_theme_font_override("font",title_font)
	summary=_label(overlay,Vector2(608,76),Vector2(474,28),17,"",UiSkin.INK)
	summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	_button(overlay,Vector2(1102,68),Vector2(100,36),"收起 · Esc",func(): world.get_node("PartyUI")._close_achievements())
	_label(overlay,Vector2(72,116),Vector2(1125,27),13,"按剧中人物与使用情境归档；器物和手艺在往来中共享，不代表某个民族独有。",UiSkin.INK)
	section=_label(overlay,Vector2(234,149),Vector2(566,27),18,"",UiSkin.VERMILION)
	var groups: Array[String] = ["全部"]
	groups.append_array(Content.GROUPS)
	for index in range(groups.size()):
		var group: String = groups[index]
		tabs[group]=_button(overlay,Vector2(68,178+index*42),Vector2(144,35),group,func(): select_group(group))
		tabs[group].add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(14))
	tabs["交融成就"]=_button(overlay,Vector2(68,582),Vector2(144,44),"交融成就",func(): select_group("交融成就"))
	for index in range(PAGE_SIZE):
		var card := Button.new()
		card.position=Vector2(234+(index%2)*286,183+floori(index/2.0)*209)
		card.size=Vector2(272,198)
		UiSkin.button(card)
		card.add_theme_stylebox_override("normal",UiSkin.paper(Color(.62,.48,.29)))
		card.add_theme_stylebox_override("hover",UiSkin.paper(Color(.58,.23,.14)))
		card.pressed.connect(func(): _select_card(index))
		overlay.add_child(card)
		cards.append(card)
		card_groups.append(_label(card,Vector2(12,7),Vector2(188,22),12,"",Color(.39,.36,.25)))
		card_states.append(_label(card,Vector2(210,7),Vector2(52,22),11,"",UiSkin.VERMILION))
		var image := TextureRect.new()
		image.position=Vector2(12,32)
		image.size=Vector2(248,108)
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(image)
		card_images.append(image)
		card_marks.append(_label(card,Vector2(12,47),Vector2(248,80),30,"",Color(.43,.45,.37)))
		card_marks[index].horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		card_titles.append(_label(card,Vector2(12,145),Vector2(248,25),16,"",UiSkin.INK))
		card_titles[index].add_theme_font_override("font",UiSkin.heading_font())
		card_meta.append(_label(card,Vector2(12,174),Vector2(248,20),11,"",Color(.39,.36,.25)))
		var bar := ProgressBar.new()
		bar.position=Vector2(20,129)
		bar.size=Vector2(232,4)
		bar.max_value=1
		bar.show_percentage=false
		bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var fill := StyleBoxFlat.new()
		fill.bg_color=Color(.58,.31,.18)
		bar.add_theme_stylebox_override("fill",fill)
		var track := StyleBoxFlat.new()
		track.bg_color=Color(.82,.78,.65)
		bar.add_theme_stylebox_override("background",track)
		card.add_child(bar)
		bar.size=Vector2(232,4)
		card_bars.append(bar)
	previous=_button(overlay,Vector2(234,608),Vector2(88,30),"上一页",func(): turn_page(-1))
	next=_button(overlay,Vector2(706,608),Vector2(88,30),"下一页",func(): turn_page(1))
	for button in [previous,next]: button.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(14))
	page_label=_label(overlay,Vector2(338,610),Vector2(352,26),14,"",UiSkin.INK)
	page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var detail := Panel.new()
	detail.position=Vector2(824,155)
	detail.size=Vector2(384,483)
	detail.add_theme_stylebox_override("panel",UiSkin.paper())
	detail.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(detail)
	detail_title=_label(overlay,Vector2(844,174),Vector2(344,56),22,"",UiSkin.VERMILION)
	detail_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_meta=_label(overlay,Vector2(844,238),Vector2(344,38),13,"",UiSkin.INK)
	detail_meta.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_photo=TextureRect.new()
	detail_photo.position=Vector2(844,280)
	detail_photo.size=Vector2(344,143)
	detail_photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	detail_photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(detail_photo)
	detail_locked=_label(overlay,Vector2(844,315),Vector2(344,106),19,"",Color(.43,.45,.37))
	detail_locked.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	detail_locked.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_credit=_rich(Vector2(844,429),Vector2(344,78),11)
	detail_credit.meta_clicked.connect(func(url): OS.shell_open(str(url)))
	detail_note=_label(overlay,Vector2(844,520),Vector2(344,72),13,"",UiSkin.INK)
	detail_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_required=_rich(Vector2(844,278),Vector2(344,225),14)
	detail_required.meta_clicked.connect(_required_link)
	photo_next=_button(overlay,Vector2(844,598),Vector2(344,29),"下一张实物参照",_photo_or_locate)
	photo_next.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(13))
	locate_button=_button(overlay,Vector2(844,598),Vector2(164,29),"标记位置",_locate_selected)
	locate_button.add_theme_font_size_override("font_size",UiSkin.text_size(13))
	threads=Threads.new()
	threads.position=Vector2(832,271)
	threads.size=Vector2(368,229)
	threads.mouse_filter=Control.MOUSE_FILTER_IGNORE
	threads.font=UiSkin.heading_font()
	overlay.add_child(threads)
	footer=_label(overlay,Vector2(68,645),Vector2(1136,23),12,"",UiSkin.INK)
	toast=Panel.new()
	toast.position=Vector2(320,75)
	toast.size=Vector2(640,90)
	toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast.add_theme_stylebox_override("panel",UiSkin.notice_paper())
	add_child(toast)
	toast_text=_label(toast,Vector2(22,13),Vector2(444,64),16,"",UiSkin.VERMILION)
	toast_text.add_theme_font_override("font",UiSkin.heading_font())
	toast_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	toast_button=_button(toast,Vector2(482,30),Vector2(136,32),"翻看成就 · C",func(): world.get_node("PartyUI")._open_achievements())
	toast_button.add_theme_font_size_override("font_size",UiSkin.text_size(14))
	toast_button.visible=false
	toast_button.disabled=true
	overlay.visible=false
	toast.visible=false


func _label(parent: Node, at: Vector2, dimensions: Vector2, size: int, words: String, ink: Color) -> Label:
	var label := Label.new()
	label.position=at
	label.size=dimensions
	label.text=words
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",font)
	if size>=18: label.add_theme_font_override("font",UiSkin.heading_font())
	label.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(size))
	label.add_theme_color_override("font_color",ink)
	parent.add_child(label)
	return label


func _button(parent: Node, at: Vector2, dimensions: Vector2, words: String, callback: Callable) -> Button:
	var button := Button.new()
	button.position=at
	button.size=dimensions
	button.text=words
	button.add_theme_font_override("font",font)
	button.add_theme_font_size_override("font_size",preload("res://scripts/interface_skin.gd").text_size(16))
	UiSkin.notice_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _rich(at: Vector2, dimensions: Vector2, size: int) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.position=at
	text.size=dimensions
	text.bbcode_enabled=true
	text.scroll_active=false
	for type in ["normal_font","italics_font","mono_font"]: text.add_theme_font_override(type,font)
	text.add_theme_font_override("bold_font",UiSkin.heading_font())
	text.add_theme_font_override("bold_italics_font",UiSkin.heading_font())
	text.add_theme_font_size_override("normal_font_size",preload("res://scripts/interface_skin.gd").text_size(size))
	text.add_theme_color_override("default_color",UiSkin.INK)
	overlay.add_child(text)
	return text


func open_book() -> void:
	overlay.visible=true
	_refresh()


func select_group(group: String) -> void:
	selected_group=group
	selected_id=""
	page=0
	selected_photo=0
	_refresh()


func turn_page(direction: int) -> void:
	page=clampi(page+direction,0,maxi(0,ceili(visible_ids.size()/float(PAGE_SIZE))-1))
	_refresh()


func _refresh() -> void:
	summary.text="器物 %d / 21   ·   七族 %d / 7   ·   成就 %d / %d"%[collected.size(),connected_groups(),unlocked.size(),Content.BADGES.size()]
	footer.text="本轮交互自动收录 · 再次启动 / T新旅程重新收集 · 回位置和重开本关保留 · C / Esc 收起"
	for group in tabs:
		var button: Button = tabs[group]
		var count: int = unlocked.size() if group=="交融成就" else collected.size() if group=="全部" else group_count(group)
		var total: int = Content.BADGES.size() if group=="交融成就" else Content.ITEMS.size() if group=="全部" else group_total(group)
		button.text=("● " if group==selected_group else "")+group+" %d/%d"%[count,total]
		button.add_theme_color_override("font_color",UiSkin.VERMILION if group==selected_group else UiSkin.INK)
	visible_ids.clear()
	if selected_group=="交融成就":
		for badge in Content.BADGES: visible_ids.append(badge.id)
	else:
		for id in Content.ITEMS:
			if selected_group=="全部" or Content.ITEMS[id].group==selected_group: visible_ids.append(id)
	page=clampi(page,0,maxi(0,ceili(visible_ids.size()/float(PAGE_SIZE))-1))
	section.text="跨民族相识，解锁共同的记忆" if selected_group=="交融成就" else selected_group+" · 沿途器物"
	for index in range(PAGE_SIZE):
		var offset: int = page*PAGE_SIZE+index
		cards[index].visible=offset<visible_ids.size()
		if not cards[index].visible: continue
		var id: String = visible_ids[offset]
		var badge_mode: bool = selected_group=="交融成就"
		var known: bool = unlocked.has(id) if badge_mode else collected.has(id)
		card_states[index].text="已解锁" if known and badge_mode else "已收录" if known else "待达成" if badge_mode else "待寻访"
		card_bars[index].visible=badge_mode
		card_images[index].visible=not badge_mode and known
		card_marks[index].visible=badge_mode or not known
		if badge_mode:
			var badge: Dictionary = _badge(id)
			var progress: Vector2i = badge_progress(badge)
			card_groups[index].text=badge.subtitle
			card_titles[index].text=badge.title
			card_meta[index].text="条件 %d/%d · 点击看共同见闻"%[progress.x,progress.y]
			card_marks[index].text="◆ 同 心 ◆" if known else "◇ 待 相 逢 ◇"
			card_marks[index].add_theme_color_override("font_color",UiSkin.VERMILION if known else Color(.49,.49,.41))
			card_bars[index].value=float(progress.x)/progress.y
		else:
			var entry: Dictionary = world.folk.items[id]
			card_groups[index].text=Content.ITEMS[id].group
			card_titles[index].text=entry.title
			card_meta[index].text=["第一关 · 雾廊碑院","第二关 · 断溪古道","第三关 · 灯火共庭"][entry.chapter]
			card_marks[index].text="待 访"
			card_marks[index].add_theme_color_override("font_color",Color(.49,.49,.41))
			card_images[index].texture=_photo_texture(id,0) if known else null
	previous.disabled=page==0
	next.disabled=(page+1)*PAGE_SIZE>=visible_ids.size()
	page_label.text="第 %d / %d 页  ·  点击卡片查看"%[page+1,maxi(1,ceili(visible_ids.size()/float(PAGE_SIZE)))]
	if selected_id.is_empty(): _show_threads()
	elif selected_group=="交融成就": _show_badge()
	else: _show_item()


func _select_card(index: int) -> void:
	var offset: int = page*PAGE_SIZE+index
	if offset>=visible_ids.size(): return
	selected_id=visible_ids[offset]
	selected_photo=0
	if selected_group=="交融成就": _show_badge()
	else: _show_item()


func _hide_detail() -> void:
	for control in [detail_photo,detail_credit,detail_locked,detail_required,photo_next,locate_button,threads]: control.visible=false
	# Detail prose follows the photo / condition list; the overview uses it too.
	detail_note.position=Vector2(844,514)
	detail_note.size=Vector2(344,77)


func _show_threads() -> void:
	_hide_detail()
	detail_title.text="各有来处，共织一卷"
	detail_meta.text="已连结 %d / 7 个民族\n从左侧寻访器物，或翻看交融成就。"%connected_groups()
	for index in range(7):
		threads.counts[index]=group_count(Content.GROUPS[index])
		threads.totals[index]=group_total(Content.GROUPS[index])
	threads.queue_redraw()
	threads.visible=true
	detail_note.text="认字、石作、行路、木工、织染与待客，在共同的路途相接。收得一物，也记住人与人如何相助。\n\n点击卡片，重看实物与相遇。"


func _photo_texture(id: String, index: int) -> Texture2D:
	var list: Array = world.folk.photo_catalog.items[id]
	var entry: Dictionary = world.folk.photo_catalog.photos[list[index%list.size()]]
	var texture: Texture2D = load(entry.file)
	if entry.has("region"):
		var atlas := AtlasTexture.new()
		atlas.atlas=texture
		atlas.region=Rect2(entry.region[0],entry.region[1],entry.region[2],entry.region[3])
		return atlas
	return texture


func _show_item() -> void:
	_hide_detail()
	var entry: Dictionary = world.folk.items[selected_id]
	var known: bool = collected.has(selected_id)
	locate_button.visible=world.party.started
	locate_button.tooltip_text=preload("res://scripts/folk_locations.gd").text(selected_id,world)
	photo_next.position=Vector2(1018,598)
	photo_next.size=Vector2(170,29)
	detail_title.text=entry.title
	detail_meta.text=Content.ITEMS[selected_id].group+" · "+["雾廊碑院","断溪古道","灯火共庭"][entry.chapter]+("\n已收录 · "+str(collected[selected_id]).get_slice("T",0) if known else "\n尚未收入成就册")
	detail_note.text=Content.ITEMS[selected_id].note
	if not known:
		detail_locked.position.y=300
		detail_locked.size=Vector2(344,207)
		detail_locked.text=preload("res://scripts/folk_locations.gd").text(selected_id,world)+"\n\n附近物件可用 1P：G / 2P：句号轮选，F / 斜杠察看。"
		detail_locked.add_theme_font_size_override("font_size",UiSkin.text_size(16))
		photo_next.visible=false
		detail_locked.visible=true
		return
	var list: Array = world.folk.photo_catalog.items[selected_id]
	selected_photo=selected_photo%list.size()
	var photo: Dictionary = world.folk.photo_catalog.photos[list[selected_photo]]
	detail_photo.texture=_photo_texture(selected_id,selected_photo)
	detail_photo.visible=true
	var license_link: String = photo.get("license_url","")
	if license_link.is_empty(): license_link=photo.source
	detail_credit.text="%s\n%s · %s · [url=%s]来源[/url] · [url=%s]授权[/url]"%[photo.title,photo.author,photo.license,photo.source,license_link]
	detail_credit.visible=true
	photo_next.visible=list.size()>1
	photo_next.text="下一张 %d/%d"%[selected_photo+1,list.size()]


func _photo_or_locate() -> void:
	selected_photo+=1
	_show_item()


func _locate_selected() -> void:
	var id: String=selected_id
	world.get_node("PartyUI")._close_achievements()
	if world.folk.overlay.visible: world.folk.close()
	world.folk.mark_location(id)


func _badge(id: String) -> Dictionary:
	for badge in Content.BADGES:
		if badge.id==id: return badge
	return {}


func _show_badge() -> void:
	_hide_detail()
	var badge: Dictionary = _badge(selected_id)
	var progress: Vector2i = badge_progress(badge)
	detail_title.text=badge.title
	detail_meta.text=("已解锁 · " if unlocked.has(selected_id) else "待达成 · ")+"条件 %d/%d\n"%[progress.x,progress.y]+badge.subtitle
	detail_note.text=badge.note
	var lines: Array[String] = []
	if badge.has("minimum"): lines.append("已收录 %d / %d 类特色物件。"%[mini(collected.size(),badge.minimum),badge.minimum])
	for id in badge.items:
		lines.append(("✓ " if collected.has(id) else "○ ")+"[url=item:%s]%s[/url] · %s"%[id,world.folk.items[id].title,Content.ITEMS[id].group])
	if badge.has("groups"):
		lines.append("\n民族相识 %d/%d："%[mini(connected_groups(),badge.groups),badge.groups])
		var groups: Array[String] = []
		for index in range(7):
			var group: String = Content.GROUPS[index]
			groups.append(("✓" if group_count(group)>0 else "○")+group)
		lines.append("  ".join(groups))
	lines.append("\n点击器物名，可看收录状态与所在场景。" if not badge.items.is_empty() else "\n按民族分类寻访器物；重开本关保留本轮，再次启程重新收集。")
	detail_required.text="\n".join(lines)
	detail_required.visible=true


func _required_link(value: Variant) -> void:
	var link: String = str(value)
	if not link.begins_with("item:"): return
	var id: String = link.trim_prefix("item:")
	if not Content.ITEMS.has(id): return
	select_group(Content.ITEMS[id].group)
	selected_id=id
	page=floori(float(visible_ids.find(id))/PAGE_SIZE)
	_refresh()


func _process(delta: float) -> void:
	if world==null or toast==null: return
	var ui: CanvasLayer = world.get_node("PartyUI")
	var can_show: bool = ui.screen==ui.Screen.GAME and not get_tree().paused and world.cooperation.inspected_id<0 and not world.courtyard.record_open and not world.courtyard.tablet_raising and not world.courtyard.tablet_arriving
	toast.visible=can_show and toast_left>0
	if toast.visible:
		toast_text.text=pending_toast
		var top: float=ui.satchel_notice_frame.get_rect().end.y+8 if ui.satchel_notice_frame.visible else 72.0
		UiSkin.layout_notice(toast,toast_text,Vector2(1256,top))
		toast_left=maxf(0,toast_left-delta)
