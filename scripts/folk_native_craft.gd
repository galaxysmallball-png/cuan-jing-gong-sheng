extends RefCounted

# Spatial and continuous craft encounters. These are short artistic abstractions,
# never a claim to teach the complete craft or assign shared tools exclusively.
const Art=preload("res://scripts/folk_activity_art.gd")
var b: Control
var phase: int=0
var marks: Array[bool]=[false,false,false]
var hold: bool=false
var pointer:=Vector2.ZERO
var drag: int=-1
var amount: float=0
var dye: float=0
var path_index: int=0
var path: Array[Vector2]=[]
var turns: Array[int]=[1,1,0,0,2,1,0,0,2]
var wet: Array[int]=[]
var rows: Array[int]=[]
var colour: int=0
var target_rows: Array[int]=[]
var tension: Array[float]=[.18,.86]
var rotation: int=1
var piece:=Vector2(115,130)
var heat: float=.18
var cups: Array[float]=[0,0,0]
var target_fills: Array[float]=[.55,.70,.55]
var served: Array[bool]=[false,false,false]
var ember: float=0
var spark_clock: float=0
var flame_time: float=0
var hint: String=""
const KNOTS: Array[Vector2]=[Vector2(90,125),Vector2(175,105),Vector2(265,140)]
const WAX: Array[Vector2]=[Vector2(85,125),Vector2(170,76),Vector2(255,125),Vector2(170,181),Vector2(85,125)]
const FURROWS: Dictionary={0:[3,1],1:[3,2],4:[0,1],5:[3,2],8:[0,1]}


func _init(board: Control) -> void:
	b=board
	target_rows.assign(b.profile.get("rows",[0,1,0,1,1,0]))
	if b.profile.id=="tea_jar": target_fills.assign([.75,.50,.65])
	if b.profile.id=="fire_basin": phase=1; ember=.42
	refresh_hint()


func refresh_hint() -> void:
	match b.mode:
		4: hint=["在素布三处扎结，留住未染的白。","按住染缸，将扎好的布浸入靛蓝。","点击三处线结拆线，看看留下的白花。"][mini(phase,2)]
		5: hint=["按住左侧起点，沿菱形轮廓描蜡。","按住染缸入染，蜡线保留原来的布色。","点击布面脱蜡，显出蓝白相间的纹样。"][mini(phase,2)]
		6: hint="点沟段改变方向，让水从左上流到右下。"
		7: hint="选右侧线色，依照样带来回拖梭织入。"
		8: hint="拖两侧系带至适中，再按住试背，稳住孩子。"
		9: hint="点转向，再将左侧木榫拖入右侧卯口。" if phase==0 else "榫口已对齐，按住木销压紧连接。"
		10: hint="按住茶壶温茶，指针到绿区后松开。" if phase==0 else "按住杯子注茶，到刻线附近松开，均分给同行。"
		11: hint=["从红线左端沿引线绕过木柱，交叉落下。","拖另一端穿过绳圈，注意先经过下方。","按住两端收紧，把共同的守望系牢。"][mini(phase,2)]
		12: hint=["亮点经过金色区时点火石，积下三次火星。","按住或松开扇风，让炭温留在绿区。","点击三盏油灯，把暖意分给后来的人。"][mini(phase,2)]
	b.message=hint


func tick(delta: float) -> void:
	if not b.running: return
	match b.mode:
		4,5:
			if phase==1 and hold and Rect2(360,74,165,125).has_point(pointer):
				amount=minf(1,amount+delta)
				dye=amount
				if amount>=1: phase=2; marks.fill(false); b.answered=2; hold=false; refresh_hint()
		8:
			if hold and Rect2(414,105,112,75).has_point(pointer):
				var safe: bool=absf(tension[0]-.55)<.10 and absf(tension[1]-.55)<.10
				amount=amount+delta if safe else 0
				if amount>=1.2: win("背布托稳了 · 同行轻声，孩子安睡")
		9:
			if phase==1 and hold and Rect2(415,93,112,92).has_point(pointer):
				amount+=delta
				if amount>=.8: win("榫卯咬合 · 木作与石作接起同一座桥")
		10:
			if phase==0 and hold and pointer.distance_to(Vector2(85,130))<62: heat=minf(1,heat+delta*.48)
			elif phase==1 and hold and drag>=0 and drag<3 and not served[drag]:
				cups[drag]=minf(1.04,cups[drag]+delta*.52)
				if cups[drag]>1: cups[drag]=0; drag=-1; hold=false; b.message="茶洒了，慢一点，留心杯沿与刻线。"
		11:
			if phase==2 and hold and Rect2(415,95,112,90).has_point(pointer):
				amount+=delta
				if amount>.7: win("红线收紧 · 后来的人也能认出守护的记号")
		12:
			spark_clock+=delta
			if phase==1:
				ember=clampf(ember+delta*(.26 if hold and pointer.x>370 else -.16),0,1)
				flame_time=flame_time+delta if ember>.40 and ember<.72 else maxf(0,flame_time-delta*.5)
				if flame_time>=1.8: phase=2; marks.fill(false); hold=false; refresh_hint()
	b.queue_redraw()


func input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer=event.position
		if hold: motion(pointer)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		pointer=event.position
		if event.pressed: hold=true; press(pointer)
		else: release(pointer); hold=false; drag=-1
	b.queue_redraw()


func press(at: Vector2) -> void:
	match b.mode:
		4:
			if phase in [0,2]:
				for i in range(3):
					if at.distance_to(KNOTS[i])<27 and not marks[i]:
						marks[i]=true; b.audio.play("cloth")
						if marks.count(true)==3:
							if phase==0: phase=1; b.answered=1; refresh_hint()
							else: win("拆线见花 · 扎染与蜡染各有留白的办法")
		5:
			if phase==0 and at.distance_to(WAX[0])<22: drag=0; path_index=1; path=[WAX[0]]
			elif phase==2 and Rect2(30,65,280,135).has_point(at): win("蜡去花显 · 阿彩与阿朵交换彼此的留纹经验")
		6:
			for cell in FURROWS:
				if at.distance_to(cell_point(cell))<25:
					turns[cell]=(turns[cell]+1)%4; b.audio.play("stone"); flow(); break
		7:
			for i in range(2):
				if at.distance_to(Vector2(420+i*60,91))<25: colour=i; b.audio.play("cloth")
			if rows.size()<target_rows.size() and at.distance_to(shuttle_start())<25: drag=0; path=[at]
		8:
			for i in range(2):
				if Rect2(50+i*230,170,155,35).has_point(at): drag=i; motion(at)
		9:
			if phase==0:
				if at.distance_to(Vector2(130,195))<31: rotation=(rotation+1)%4; b.audio.play("wood")
				elif at.distance_to(piece)<55: drag=0
		10:
			if phase==1:
				for i in range(3):
					if Rect2(190+i*110,89,85,111).has_point(at) and not served[i]: drag=i
		11:
			if phase<2 and at.distance_to(rope_path()[0])<24: drag=0; path_index=1; path=[at]
		12:
			if phase==0 and Rect2(42,85,280,100).has_point(at):
				var x: float=154+92*sin(spark_clock*2.7)
				if x>138 and x<178:
					amount+=1; b.audio.play("bell")
					if amount>=3: phase=1; ember=.45; amount=0; refresh_hint()
				else: b.message="火石还没碰上，等亮点走进金色区再击。"
			elif phase==2:
				for i in range(3):
					if at.distance_to(Vector2(135+i*140,133))<38:
						marks[i]=true; b.audio.play("fire")
						if marks.count(true)==3: win("火种分给三盏灯 · 来路不同，同享一庭暖意")


func motion(at: Vector2) -> void:
	match b.mode:
		5:
			if phase==0 and drag==0:
				if _trace(at,WAX): phase=1; b.answered=1; drag=-1; refresh_hint()
		7:
			if drag==0:
				var a: Vector2=shuttle_start()
				if absf(at.y-a.y)>19: drag=-1; b.message="梭子偏出了经线，回到这一行再穿。"; return
				path.append(at)
				if absf(at.x-a.x)>260:
					if colour==target_rows[rows.size()]:
						rows.append(colour); b.answered=rows.size(); b.audio.play("cloth")
						if rows.size()==target_rows.size(): win("经纬成纹 · 把各人的线色织进同一幅锦")
					else: b.message="这一行线色与样带不同，换好颜色再引梭。"
					drag=-1
		8:
			if drag>=0: tension[drag]=clampf((at.x-(60+drag*230))/130,0,1); amount=0
		9:
			if phase==0 and drag==0: piece=at.clamp(Vector2(55,70),Vector2(390,180))
		11:
			if phase<2 and drag==0 and _trace(at,rope_path()):
				phase+=1; drag=-1; path.clear(); b.answered=phase; b.audio.play("rope"); refresh_hint()


func _trace(at: Vector2, guide: Array[Vector2]) -> bool:
	if path_index>=guide.size(): return true
	var last: Vector2=guide[path_index-1]
	var next: Vector2=guide[path_index]
	var foot: Vector2=Geometry2D.get_closest_point_to_segment(at,last,next)
	if at.distance_to(foot)>23:
		drag=-1; path.clear(); path_index=0; b.message="手偏离了引线，从起点再慢慢走一遍。"; return false
	path.append(at)
	if at.distance_to(next)<21: path_index+=1
	return path_index>=guide.size()


func release(_at: Vector2) -> void:
	if b.mode==9 and drag==0 and phase==0:
		if piece.distance_to(Vector2(330,127))<35 and rotation==0:
			phase=1; piece=Vector2(330,127); b.answered=1; refresh_hint(); b.audio.play("wood")
		else: piece=Vector2(115,130); b.message="榫肩还没对齐，转正长边，再让木榫入卯。"
	elif b.mode==10:
		if phase==0 and heat>.55 and heat<.86: phase=1; b.answered=1; refresh_hint()
		elif phase==0 and heat>=.86: heat=.18; b.message="茶温过高，重新慢慢温茶，到绿区就松开。"
		elif phase==1 and drag>=0:
			if absf(cups[drag]-target_fills[drag])<.075:
				served[drag]=true; b.answered=served.count(true); b.audio.play("water")
				if served.count(true)==3: win("三杯茶分好 · 给每一位同行留一个位置")
			else: cups[drag]=0; b.message="还没到杯上刻线，再斟一次；满而不溢。"


func cell_point(cell: int) -> Vector2:
	return Vector2(170+(cell%3)*64,80+(cell/3)*48)


func flow() -> void:
	wet.clear()
	var cell: int=0
	var incoming: int=3
	for step in range(10):
		if not FURROWS.has(cell) or cell in wet: break
		var ports: Array[int]=[]
		for direction in FURROWS[cell]: ports.append((direction+turns[cell])%4)
		if incoming not in ports: break
		wet.append(cell)
		var out: int=ports[1] if ports[0]==incoming else ports[0]
		if cell==8 and out==1: win("沟通水到 · 日常劳作的经验也帮上了护碑的路"); return
		var col: int=cell%3
		if (out==1 and col==2) or (out==3 and col==0): break
		cell += [-3,1,3,-1][out]
		if cell<0 or cell>8: break
		incoming=(out+2)%4
	b.message="水已流过 %d 段，看看断在了哪一个转弯。"%wet.size()


func shuttle_start() -> Vector2:
	return Vector2(50 if rows.size()%2==0 else 338,76+rows.size()*20)


func rope_path() -> Array[Vector2]:
	var result: Array[Vector2]=[]
	if phase==0: result.assign([Vector2(75,100),Vector2(180,80),Vector2(300,155)])
	else: result.assign([Vector2(75,175),Vector2(190,180),Vector2(310,105)])
	return result


func win(words: String) -> void:
	drag=-1
	hold=false
	b.answered=b.recipe.size()
	b._win(words)


func draw() -> void:
	preload("res://scripts/folk_craft_presentation.gd").render(self)
