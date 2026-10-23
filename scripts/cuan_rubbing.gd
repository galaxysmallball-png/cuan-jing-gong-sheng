extends Control

signal finished
const UiStyle=preload("res://scripts/interface_skin.gd")
const Art=preload("res://scripts/folk_activity_art.gd")
const PAPER:=Rect2(196,86,416,250)
const ORDER: Array[int]=[3,0,5,2,1,4]
const TURNS: Array[int]=[0,2,1,2,0,3]
var chapter: Node3D
var phase: int=0
var completed: bool=false
var offsets: Array[float]=[-36,32]
var fixed: Array[bool]=[false,false]
var ink: Array[int]=[0,0,0,0,0,0]
var cursors: Array[int]=[0,0]
var rhythm: Array[float]=[0,.9]
var cooldown: Array[float]=[0,0]
var peel: float=0
var single_side: int=0
var mouse_directions: Array[int]=[0,0]
var mouse_holds: Array[bool]=[false,false]
var message: String=""
var arrows: Array[Button]=[]
var work: Array[Button]=[]
var take: Button


func setup(owner_chapter: Node3D) -> void:
	chapter=owner_chapter
	size=Vector2(810,438)
	mouse_filter=Control.MOUSE_FILTER_STOP
	for slot in range(2):
		var x: float=16 if slot==0 else 634
		for direction in [-1,1]:
			var button:=_button(Vector2(x+(0 if direction<0 else 80),132),Vector2(74,36),"←" if direction<0 else "→")
			button.button_down.connect(func(): mouse_directions[slot]=direction)
			button.button_up.connect(func(): mouse_directions[slot]=0)
			arrows.append(button)
		var button:=_button(Vector2(x,230),Vector2(154,42),"")
		button.pressed.connect(func(): _use(slot))
		button.button_down.connect(func(): mouse_holds[slot]=true)
		button.button_up.connect(func(): mouse_holds[slot]=false)
		work.append(button)
	take=_button(Vector2(267,374),Vector2(278,40),"取下练习拓片 · 开始合读")
	take.pressed.connect(_take_print)
	reset_practice()


func _button(at: Vector2, dimensions: Vector2, words: String) -> Button:
	var button:=Button.new()
	button.position=at
	button.size=dimensions
	button.text=words
	button.focus_mode=Control.FOCUS_NONE
	UiStyle.button(button)
	button.add_theme_font_size_override("font_size",UiStyle.text_size(15))
	add_child(button)
	return button


func reset_practice() -> void:
	phase=0
	completed=false
	offsets.assign([-36.0,32.0])
	fixed.fill(false)
	ink.fill(0)
	cursors.fill(0)
	rhythm.assign([0.0,.9])
	cooldown.fill(0)
	single_side=0
	release_tools()
	message="上下边都与金线对齐，再分别压纸。"
	_sync_buttons()
	queue_redraw()


func release_tools() -> void:
	mouse_directions.fill(0)
	mouse_holds.fill(false)
	peel=0


func _active() -> bool:
	return is_visible_in_tree() and not get_tree().paused and chapter.get_node("../../../PartyUI").screen==2 and not completed


func _process(delta: float) -> void:
	if not _active(): return
	if phase==0:
		for slot in range(2):
			if fixed[slot]: continue
			var axis: float=float(mouse_directions[slot])
			if chapter.party.local_coop:
				axis+=Input.get_axis("move_left","move_right") if slot==0 else Input.get_axis("p2_move_left","p2_move_right")
			elif slot==single_side: axis+=Input.get_axis("move_left","move_right")
			offsets[slot]=clampf(offsets[slot]+axis*80*delta,-52,52)
	elif phase==1:
		for slot in range(2):
			rhythm[slot]+=delta*2.5
			cooldown[slot]=maxf(0,cooldown[slot]-delta)
	elif phase==2:
		var first: bool=mouse_holds[0] or Input.is_action_pressed("interact")
		var second: bool=mouse_holds[1] or Input.is_action_pressed("p2_interact")
		if first and (second or not chapter.party.local_coop):
			peel=minf(1,peel+delta/.95)
		else: peel=maxf(0,peel-delta*1.5)
		if peel>=1:
			phase=3
			release_tools()
			message="六片拓字已显。取下后，与同伴合读四人见闻。"
			chapter.get_node("../../..").sfx.play("paper")
			_sync_buttons()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _active() or not event is InputEventKey or not event.pressed or event.echo: return
	var key: int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
	if key in [KEY_E,KEY_P,KEY_KP_0]:
		if key==KEY_E: _use(0 if chapter.party.local_coop else single_side)
		elif chapter.party.local_coop: _use(1)
	elif phase==1 and key in [KEY_W,KEY_S,KEY_UP,KEY_DOWN]:
		var side: int=0 if key in [KEY_W,KEY_S] else 1
		if not chapter.party.local_coop: side=single_side
		cursors[side]=posmod(cursors[side]+(-1 if key in [KEY_W,KEY_UP] else 1),3)
	elif phase==1 and not chapter.party.local_coop and key in [KEY_A,KEY_D]:
		single_side=0 if key==KEY_A else 1
	elif phase==3 and key in [KEY_ENTER,KEY_KP_ENTER]: _take_print()
	else: return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not _active() or phase!=1: return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for index in range(6):
			if patch_rect(index).has_point(event.position):
				var slot: int=index%2
				cursors[slot]=index/2
				single_side=slot
				_use(slot)
				accept_event()
				return


func pressure(slot: int) -> float:
	return .5+.5*sin(rhythm[slot])


func _use(slot: int) -> void:
	if not _active(): return
	var audio: Node=chapter.get_node("../../..").sfx
	if phase==0:
		if fixed[slot]: return
		if absf(offsets[slot])>5:
			message="纸边还未对齐，请向金线移动。"
			audio.play("wrong")
		else:
			offsets[slot]=0
			fixed[slot]=true
			audio.play("paper")
			if not chapter.party.local_coop: single_side=1
			if false not in fixed:
				phase=1
				single_side=0
				message="指针进入绿色区时轻扑；每格两次，重复按住不会连扑。"
	elif phase==1:
		var index: int=cursors[slot]*2+slot
		if ink[index]>=2:
			message="这格墨色已匀，换到尚未拓好的区域。"
			return
		if cooldown[slot]>0: return
		cooldown[slot]=.20
		if pressure(slot)<.27 or pressure(slot)>.73:
			message="扑子尚未稳住，等指针进入绿色区再轻扑。"
			audio.play("wrong")
		else:
			ink[index]+=1
			audio.last.clear()
			audio.play("cloth")
			message="此格 %d / 2 · 墨色均匀后，换到下一格。"%ink[index]
			if ink.count(2)==6:
				phase=2
				mouse_holds.fill(false)
				message="两人同时按住 E / P，托住两边，缓缓揭纸。" if chapter.party.local_coop else "按住 E，缓缓揭起练习拓片。"
	_sync_buttons()
	queue_redraw()


func _take_print() -> void:
	if not _active() or phase!=3: return
	completed=true
	release_tools()
	chapter.get_node("../../..").sfx.play("paper")
	finished.emit()


func _sync_buttons() -> void:
	for button in arrows: button.visible=phase==0
	for slot in range(work.size()):
		var key: String="E" if slot==0 or not chapter.party.local_coop else "P"
		work[slot].visible=phase<3
		work[slot].text=("压住上边" if slot==0 else "压住下边") if phase==0 else "轻扑 · "+key if phase==1 else "按住揭纸 · "+key
		work[slot].disabled=phase==0 and fixed[slot]
		if not chapter.party.local_coop and phase==2: work[slot].visible=slot==0
	take.visible=phase==3


func patch_rect(index: int) -> Rect2:
	return Rect2(214+(index%2)*198,101+(index/2)*75,181,65)


func _draw() -> void:
	if chapter==null: return
	# The shared floral sheet remains visible through the work area.
	Art.panel(self,Rect2(Vector2.ZERO,size),Color(.96,.91,.79,.38),Color(.61,.44,.26,.25),6)
	Art.text(self,Vector2(18,31),["① 覆纸对齐 · 各压一边","② 轻扑匀墨 · 各拓一列","③ 共揭拓片 · 两边同起","④ 拓字显影 · 留待合读"][phase],23,Art.RED,true)
	Art.text(self,Vector2(18,62),"练习刻板上的节选字形，将成为下一步的六张拓字卡。",14)
	Art.panel(self,PAPER.grow(9),Color("634933"),Art.GOLD)
	var sheet:=PackedVector2Array([PAPER.position+Vector2(offsets[0],0),Vector2(PAPER.end.x+offsets[0],PAPER.position.y),PAPER.end+Vector2(offsets[1],0),Vector2(PAPER.position.x+offsets[1],PAPER.end.y)])
	draw_colored_polygon(sheet,Color("f1e4c1"))
	if phase==0:
		for slot in range(2):
			var y: float=PAPER.position.y+slot*PAPER.size.y
			Art.line(self,Vector2(PAPER.position.x-14,y),Vector2(PAPER.end.x+14,y),Art.GOLD,2)
			Art.line(self,Vector2(PAPER.position.x,y-12),Vector2(PAPER.position.x,y+12),Art.RED,2)
			Art.line(self,Vector2(PAPER.position.x+offsets[slot],y-10),Vector2(PAPER.position.x+offsets[slot],y+10),Color("427e75"),5)
			var x: float=16 if slot==0 else 634
			Art.text(self,Vector2(x,107),("上边 · 1P" if slot==0 else "下边 · 2P") if chapter.party.local_coop else ("先压上边" if slot==0 else "再压下边"),18,Art.RED,true)
			Art.text(self,Vector2(x,204),("A / D 调整" if slot==0 else "← / → 调整") if chapter.party.local_coop else "A / D 调整",14)
			Art.text(self,Vector2(x,300),"已压稳" if fixed[slot] else ("E 压纸" if slot==0 or not chapter.party.local_coop else "P 压纸"),16)
		Art.centered(self,Vector2(404,209),"先让纸边贴合定位线",20,Color("796747"))
	else:
		for index in range(6):
			var rect: Rect2=patch_rect(index)
			var darkness: float=float(ink[index])/2.0
			var peel_light: float=peel if phase==2 else 1.0 if phase==3 else 0.0
			Art.panel(self,rect,Color("e7d8af").lerp(Color("252e2c"),darkness),Color("baa77d"),3)
			var slot: int=index%2
			if phase==1 and cursors[slot]==index/2: draw_rect(rect.grow(2),Color("b04e3a") if slot==0 else Color("548ca1"),false,2)
			if ink[index]>0:
				var id: int=ORDER[index]
				draw_set_transform(rect.get_center(),TURNS[id]*PI/2)
				Art.centered(self,Vector2(0,18),chapter.GLYPHS[id],39,Color(1,.96,.83,.35+darkness*.65))
				draw_set_transform(Vector2.ZERO)
			if peel_light>0 and rect.position.y<PAPER.position.y+PAPER.size.y*peel_light:
				Art.line(self,rect.position+Vector2(6,5),Vector2(rect.end.x-6,rect.position.y+5),Color("d9bc78"),2)
		if phase==1:
			for slot in range(2):
				var x: float=16 if slot==0 else 634
				Art.text(self,Vector2(x,107),("左列 · 1P" if slot==0 else "右列 · 2P") if chapter.party.local_coop else ("左列" if slot==0 else "右列"),18,Art.RED,true)
				Art.text(self,Vector2(x,139),("W / S 选格" if slot==0 else "↑ / ↓ 选格") if chapter.party.local_coop else "A / D 换列",12)
				if not chapter.party.local_coop: Art.text(self,Vector2(x,160),"W / S 选格 · E 轻扑",11)
				Art.panel(self,Rect2(x,180,154,15),Color("6c6954"),Art.GOLD,3)
				Art.panel(self,Rect2(x+154*.27,181,154*.46,13),Color("598e70"),Color("598e70"),2)
				var indicator: float=x+pressure(slot)*154
				Art.line(self,Vector2(indicator,176),Vector2(indicator,199),Art.CREAM,3)
				Art.text(self,Vector2(x,300),"绿色区内轻扑",14)
		elif phase==2:
			Art.panel(self,Rect2(196,86,416,250*peel),Color(1,.91,.71,.18),Color.TRANSPARENT,0)
			var curl_y: float=PAPER.end.y-peel*PAPER.size.y
			var curl:=PackedVector2Array([Vector2(196,curl_y),Vector2(612,curl_y),Vector2(603,curl_y-15),Vector2(205,curl_y-15)])
			draw_colored_polygon(curl,Color("ead7a4"))
			Art.line(self,Vector2(198,curl_y+2),Vector2(610,curl_y+2),Color(0,0,0,.24),3)
			Art.centered(self,Vector2(404,365),"共同揭纸 %d%%"%int(peel*100),16,Art.RED,true)
	Art.centered(self,Vector2(404,360 if phase<2 else 397 if phase==2 else 362),message,12)
	Art.text(self,Vector2(18,432),"传拓玩法简化 · 练习刻板 / 现代小爨字库节选 · 取拓后仍需四人辨字合读",11)
