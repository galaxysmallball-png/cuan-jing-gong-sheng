from pathlib import Path
import re,shutil,json,hashlib
root=Path('数媒/cuan-game'); backup=root/'backups/before-craft-polish-2026-10-19'
backup.mkdir(parents=True,exist_ok=True)
for folder in ['scripts','scenes']:
    shutil.copytree(root/folder,backup/folder,dirs_exist_ok=True)
for name in ['project.godot','export_presets.cfg']: shutil.copy2(root/name,backup/name)
source=Path('C:/Users/26845/AppData/Local/Temp/codex-clipboard-b01d4363-6694-4865-b939-ec9767d72c87.png')
asset=root/'assets/interface/notice_bird_paper.png'; shutil.copy2(source,asset)
p=root/'assets/interface/SOURCE.json'; data=json.loads(p.read_text(encoding='utf-8-sig'))
data.append(dict(file=asset.name,source=str(source),sha256=hashlib.sha256(asset.read_bytes()).hexdigest(),use='成就与线索通知和相关弹窗按钮',altered=False))
p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
p=root/'scripts/interface_skin.gd'; s=p.read_text(encoding='utf-8')
s=s.replace('const CUAN_FONT', 'const NOTICE_PAPER = preload("res://assets/interface/notice_bird_paper.png")\nconst TEXT_SCALE: float = 1.16\nconst CUAN_FONT',1)
s+='''

static func text_size(base: int) -> int:
	return roundi(base*TEXT_SCALE)


static func notice_paper() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture=NOTICE_PAPER
	style.set_content_margin_all(0)
	return style


static func notice_button(control: Button) -> void:
	button(control)
	for state in ["normal","hover","pressed","focus"]:
		var style := notice_paper()
		style.modulate_color=Color(.88,.82,.70) if state=="pressed" else Color(1.06,1.03,.95) if state=="hover" else Color.WHITE
		control.add_theme_stylebox_override(state,style)
'''
p.write_text(s,encoding='utf-8')
for p in (root/'scripts').glob('*.gd'):
    s=p.read_text(encoding='utf-8')
    # Scale the layout metrics as well as the glyphs: native wrapping sees the larger font.
    s=re.sub(r'(\.add_theme_font_size_override\("[^"\n]+",\s*)([^\n]+)(\))',lambda m:m[1]+'preload("res://scripts/interface_skin.gd").text_size('+m[2]+')'+m[3],s)
    p.write_text(s,encoding='utf-8')
# World labels and default-theme text use the same increase.
for name in ['chapter_props.gd','party_character_visual.gd','opening_card_draw.gd']:
    p=root/'scripts'/name;s=p.read_text(encoding='utf-8')
    s=re.sub(r'(\.font_size = )(\d+)',r'\1preload("res://scripts/interface_skin.gd").text_size(\2)',s)
    p.write_text(s,encoding='utf-8')
p=root/'scripts/world_signs.gd';s=p.read_text(encoding='utf-8').replace('size.y * 0.73','size.y * 0.84').replace('size.x * 0.77','size.x * 0.89');p.write_text(s,encoding='utf-8')
p=root/'assets/interface/cuan_theme.tres';s=p.read_text(encoding='utf-8').replace('[resource]','[resource]\ndefault_font_size = 19');p.write_text(s,encoding='utf-8')
p=root/'scripts/story_dialogue.gd';s=p.read_text(encoding='utf-8').replace('-1, 17)', '-1, SkinStyle.text_size(17))').replace('-1, 20)', '-1, SkinStyle.text_size(20))')
s=s.replace('width = 325','width = 325').replace('height = 100','height = 110').replace('Vector2(65,612)','Vector2(65,602)').replace('words.size.y = 58','words.size.y = 68')
p.write_text(s,encoding='utf-8')
p=root/'scripts/folk_collection.gd';s=p.read_text(encoding='utf-8').replace('Vector2(550, 234)','Vector2(550, 260)').replace('Vector2(500, 246)','Vector2(500, 232)').replace('Vector2(575, 140)','Vector2(575, 128)').replace('Vector2(121,47),Vector2(410,130)','Vector2(121,47),Vector2(410,147)').replace('Vector2(14,193)','Vector2(14,225)').replace('Vector2(350,190)','Vector2(350,222)');p.write_text(s,encoding='utf-8')
# Preserve the requested parcel card paper; only the notification-related buttons change.
p=root/'scripts/field_satchel.gd';s=p.read_text(encoding='utf-8').replace('UiSkin.parcel_button(close_button)','UiSkin.notice_button(close_button)');p.write_text(s,encoding='utf-8')
p=root/'scripts/achievement_book.gd';s=p.read_text(encoding='utf-8').replace('UiSkin.button(button)','UiSkin.notice_button(button)')
s=s.replace('var toast_text: Label','var toast_text: Label\nvar toast_button: Button')
s=s.replace('Vector2(448,75)','Vector2(320,75)').replace('Vector2(384,68)','Vector2(640,90)').replace('toast.mouse_filter=Control.MOUSE_FILTER_IGNORE','toast.mouse_filter=Control.MOUSE_FILTER_PASS').replace('toast.add_theme_stylebox_override("panel",UiSkin.paper())','toast.add_theme_stylebox_override("panel",UiSkin.notice_paper())').replace('Vector2(16,9),Vector2(352,51)','Vector2(22,13),Vector2(444,64)')
s=s.replace('toast_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART','''toast_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	toast_button=_button(toast,Vector2(482,30),Vector2(136,32),"翻看成就 · C",func(): world.get_node("PartyUI")._open_achievements())
	toast_button.add_theme_font_size_override("font_size",UiSkin.text_size(14))''')
s=s.replace('toast.visible=can_show and toast_left>0','toast.visible=can_show and toast_left>0\n\ttoast.position.y=150 if ui._notice_seconds>0 else 75')
p.write_text(s,encoding='utf-8')
p=root/'scripts/party_ui.gd';s=p.read_text(encoding='utf-8').replace('var satchel_notice: Label','var satchel_notice: Label\nvar satchel_notice_frame: Panel\nvar satchel_notice_button: Button')
s=s.replace('satchel_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE','''satchel_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	satchel_notice_frame=Panel.new()
	satchel_notice_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	satchel_notice_frame.add_theme_stylebox_override("panel",UiStyle.notice_paper())
	add_child(satchel_notice_frame)''')
s=s.replace('Color(1.0,0.86,0.55)','UiStyle.VERMILION',1)
s=s.replace('Color(0,0,0,0.95)','Color.TRANSPARENT',1)
s=s.replace('add_child(satchel_notice)\n','''add_child(satchel_notice)
	satchel_notice_button=Button.new()
	satchel_notice_button.text="查看包裹 · B"
	satchel_notice_button.add_theme_font_size_override("font_size",UiStyle.text_size(14))
	UiStyle.notice_button(satchel_notice_button)
	satchel_notice_button.pressed.connect(_open_satchel)
	add_child(satchel_notice_button)
''',1)
s=s.replace('satchel_notice.position=Vector2(480,124) if inspecting else Vector2(900,66)','satchel_notice.position=Vector2(496,123) if inspecting else Vector2(720,85)')
s=s.replace('satchel_notice.size=Vector2(600,28) if inspecting else Vector2(350,42)','satchel_notice.size=Vector2(444,28) if inspecting else Vector2(360,38)')
s=s.replace('satchel_notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if inspecting else HORIZONTAL_ALIGNMENT_RIGHT','''satchel_notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	satchel_notice_frame.position=Vector2(480,112) if inspecting else Vector2(700,72)
	satchel_notice_frame.size=Vector2(680,50) if inspecting else Vector2(556,64)
	satchel_notice_button.position=Vector2(994,122) if inspecting else Vector2(1100,88)
	satchel_notice_button.size=Vector2(146,30)''')
# _refresh also sets visibility; mirror it before draw via the process path.
s=s.replace('\n\nfunc _open_satchel()', '\n\tsatchel_notice_frame.visible=satchel_notice.visible\n\tsatchel_notice_button.visible=satchel_notice.visible\n\n\nfunc _open_satchel()')
p.write_text(s,encoding='utf-8')
p=root/'scripts/scene_atmosphere.gd';s=p.read_text(encoding='utf-8')
s=s.replace('stream.add_vertex(Vector3((u-.5)*width,3.5-v*7,.035*sin(v*14)*v))','stream.add_vertex(Vector3(-.95*v*v+(u-.5)*width,3.5-v*7,.035*sin(v*14)*v))')
s=s.replace('waterfall.set_meta("top_width",.18)','''waterfall.set_meta("top_width",.18)
	waterfall.set_meta("left_drift",.95)
	waterfall.set_meta("source_gap",Vector3(17.2,4.7,-5.7))''')
s=s.replace('waterfall.name = "CliffWaterfall"','''waterfall.name = "CliffWaterfall"
	# Front-facing rock lips conceal the sheet's upper edge inside a real fissure.
	_rock(parent,Vector3(16.81,4.78,-5.60),Vector3(.59,.91,.54),cliff)
	_rock(parent,Vector3(17.59,4.86,-5.58),Vector3(.58,.96,.56),cliff)
	_rock(parent,Vector3(17.20,5.20,-5.59),Vector3(.76,.27,.52),cliff)''')
s=s.replace('Vector3(17.2,-1.95,-5.25)','Vector3(16.25,-1.95,-5.25)')
p.write_text(s,encoding='utf-8')
# The same courtyard stele travels from the bridge entry; it is never pre-populated.
p=root/'scripts/lantern_garden.gd';s=p.read_text(encoding='utf-8').replace('var tablet_placed: bool = false','''var tablet_placed: bool = false
var tablet_arriving: bool = false
var arrival_elapsed: float = 0
var arrival_from := Vector3.ZERO
const ARRIVAL_SECONDS: float = 3.2''')
s=s.replace('\t_tablet.visible = bridge.tablet_delivered','''	_tablet.visible = bridge.tablet_delivered
	if tablet_arriving and not tablet_placed and party.started and not party.movement_locked():
		arrival_elapsed=minf(ARRIVAL_SECONDS,arrival_elapsed+delta)
		var progress: float = smoothstep(0,1,arrival_elapsed/ARRIVAL_SECONDS)
		_tablet.position=arrival_from.lerp(Vector3(PLACEMENT_X,.70,-1.8),progress)
		if arrival_elapsed>=ARRIVAL_SECONDS:
			tablet_arriving=false
			landscape.say("石阿朵","从溪桥一路护来的碑，终于到碑座了。请与我合力扶正。",4)
		landscape.sync_state()''',1)
s=s.replace('if _place_together(delta): _raise_tablet()', 'if not tablet_arriving and bridge.tablet_delivered and _place_together(delta): _raise_tablet()')
s=s.replace('landscape.say("石阿朵", "到了。先扶正碑身——我来认墩脚，诸位在旁稳住。")','landscape.say("石阿朵", "碑从桥上送来了。先让它落到碑座，诸位在旁稳住。")')
s=s.replace('func _raise_tablet() -> void:', '''func receive_tablet(from_world: Vector3) -> void:
	if tablet_placed or tablet_arriving: return
	arrival_from=to_local(from_world)
	arrival_from.x=clampf(arrival_from.x,-1.2,1.0)
	arrival_from.y=.85
	arrival_from.z=-.25
	arrival_elapsed=0
	tablet_arriving=true
	_tablet.position=arrival_from
	_tablet.rotation.z=PI/2
	_tablet.visible=true
	landscape.sync_state()


func _raise_tablet() -> void:''')
s=s.replace('if not tablet_placed:\n\t\treturn "到院中碑座', 'if tablet_arriving: return "溪桥送来的碑正在入院，请随碑前往院中碑座。\\n到达后由石阿朵与同伴合力立碑。"\n\tif not tablet_placed:\n\t\treturn "到院中碑座')
s=s.replace('if not tablet_placed:\n\t\tif party.local_coop:', 'if tablet_arriving: return _task("随碑入院 · 等送到碑座后合力立碑")\n\tif not tablet_placed:\n\t\tif party.local_coop:')
s=s.replace('\ttablet_placed = false\n\tlamp_count', '\ttablet_placed = false\n\ttablet_arriving = false\n\tarrival_elapsed = 0\n\t_tablet.visible = bridge.tablet_delivered\n\tlamp_count')
s=s.replace('\tlandscape.reset_art()', '\tlandscape.reset_art()\n\tif bridge.tablet_delivered: receive_tablet(Vector3(40.1,.85,-.25))')
p.write_text(s,encoding='utf-8')
p=root/'scripts/chapter02_party.gd';s=p.read_text(encoding='utf-8').replace('root_world.courtyard._tablet.visible = true','root_world.courtyard.receive_tablet(_tablet.global_position)').replace('碑已送到院中。接下来，咱们一同将它扶正。','碑已过溪，沿这条路送到院中碑座，再一起扶正。');p.write_text(s,encoding='utf-8')
p=root/'scripts/garden_art.gd';s=p.read_text(encoding='utf-8').replace('placement_label.visible = not chapter.tablet_placed','placement_label.visible = chapter.bridge.tablet_delivered and not chapter.tablet_arriving and not chapter.tablet_placed').replace('placement_marker.visible = not chapter.tablet_placed','placement_marker.visible = placement_label.visible');p.write_text(s,encoding='utf-8')
print('CRAFT_POLISH_BASE_EDITED')
