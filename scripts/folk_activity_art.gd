extends RefCounted

const UiStyle = preload("res://scripts/interface_skin.gd")
const INK := Color("344941")
const GOLD := Color("b58a4b")
const CREAM := Color("f5e6be")
const RED := Color("954b36")
const INDIGO := Color("263f50")
const MOTIFS: Array[String] = ["菱形纹", "花叶纹", "回旋纹"]


static func panel(b: Control, rect: Rect2, fill: Color, edge: Color = GOLD, radius: int = 8) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	b.draw_style_box(style,rect)


static func text(b: Control, at: Vector2, words: String, base: int, color: Color = INK, heading: bool = false, width: float = -1) -> void:
	b.draw_string(UiStyle.heading_font() if heading else UiStyle.body_font(),at,words,HORIZONTAL_ALIGNMENT_LEFT,width,UiStyle.text_size(base),color)


static func centered(b: Control, at: Vector2, words: String, base: int, color: Color = INK, heading: bool = false) -> void:
	var font: Font = UiStyle.heading_font() if heading else UiStyle.body_font()
	var px: int = UiStyle.text_size(base)
	text(b,at-Vector2(font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x/2,0),words,base,color,heading)


static func line(b: Control, a: Vector2, z: Vector2, ink: Color, stroke: float = 1) -> void:
	b.draw_line(a,z,ink,stroke,true)


static func diamond(b: Control, center: Vector2, radius: float, ink: Color, stroke: float = 1.6) -> void:
	b.draw_polyline(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)]),ink,stroke,true)


static func motif(b: Control, center: Vector2, kind: int, ink: Color) -> void:
	if kind==0:
		for radius in [34,27,12]: diamond(b,center,radius,ink)
		for side in [-1,1]:
			for offset in [-1,1]:
				diamond(b,center+Vector2(side*27,offset*27),5,ink,1)
		b.draw_circle(center,3,ink)
	elif kind==1:
		for petal in range(8):
			var angle: float = TAU*petal/8
			var direction := Vector2(cos(angle),sin(angle))
			var cross := direction.orthogonal()*7
			b.draw_polyline(PackedVector2Array([center+direction*8,center+direction*23+cross,center+direction*37,center+direction*23-cross,center+direction*8]),ink,1.6,true)
		b.draw_arc(center,7,0,TAU,32,ink,1.6,true)
	else:
		var spiral := PackedVector2Array()
		for step in range(130):
			var angle: float = step/129.0*TAU*2.5
			spiral.append(center+Vector2(cos(angle),sin(angle))*(3+step/129.0*33))
		b.draw_polyline(spiral,ink,1.8,true)
		for side in [-1,1]: diamond(b,center+Vector2(side*35,-30),4,ink,1)


static func cloth(b: Control, rect: Rect2, red: bool, active: bool) -> void:
	var fill := Color("773e32") if red else INDIGO
	panel(b,rect,fill,CREAM if active else GOLD)
	var weave := Color(1,.94,.78,.045)
	for y in range(int(rect.position.y)+4,int(rect.end.y)-2,4): line(b,Vector2(rect.position.x+3,y),Vector2(rect.end.x-3,y),weave)
	for x in range(int(rect.position.x)+4,int(rect.end.x)-2,5): line(b,Vector2(x,rect.position.y+3),Vector2(x,rect.end.y-3),weave)
	var inset: Rect2 = rect.grow(-6)
	panel(b,inset,Color.TRANSPARENT,Color(.9,.77,.49,.5),3)
	for x in range(int(inset.position.x)+3,int(inset.end.x)-3,7):
		line(b,Vector2(x,inset.position.y+3),Vector2(x+3,inset.position.y+3),CREAM*.65)
		line(b,Vector2(x,inset.end.y-3),Vector2(x+3,inset.end.y-3),CREAM*.65)


static func cargo(b: Control, center: Vector2, weight: int, left: bool, hover: bool, number: int) -> void:
	var at: Vector2 = center+Vector2(0,-3 if hover else 0)
	panel(b,Rect2(at-Vector2(44,37),Vector2(88,80)),Color(.85,.79,.64,.25),Color(.64,.48,.27,.24))
	var fill := Color("a16445") if left else Color("687f7b")
	var bag := PackedVector2Array([at+Vector2(-31,-22),at+Vector2(-22,-31),at+Vector2(19,-31),at+Vector2(31,-21),at+Vector2(34,22),at+Vector2(25,29),at+Vector2(-28,29),at+Vector2(-35,20),at+Vector2(-31,-22)])
	b.draw_colored_polygon(bag,fill)
	b.draw_polyline(bag,CREAM if hover else Color("43534a"),1.2,true)
	for x in range(-25,28,7): line(b,at+Vector2(x,-20),at+Vector2(x,22),Color(1,.94,.8,.10))
	line(b,at+Vector2(-31,-15),at+Vector2(31,-15),CREAM,2)
	line(b,at+Vector2(0,-30),at+Vector2(0,25),Color(.9,.76,.49,.75),1.4)
	b.draw_arc(at+Vector2(-7,-19),7,-PI*.9,PI*.8,20,CREAM,1.4,true)
	b.draw_arc(at+Vector2(7,-19),7,-PI*.3,PI*1.4,20,CREAM,1.4,true)
	centered(b,at+Vector2(0,12),"%d 份"%weight,18,CREAM,true)
	centered(b,center+Vector2(0,48),("左筐" if left else "右筐")+" · "+str(number),11,RED if left else INK)


static func basket(b: Control, at: Vector2, fill: Color) -> void:
	var contour := PackedVector2Array([at+Vector2(-27,0),at+Vector2(27,0),at+Vector2(20,23),at+Vector2(-20,23),at+Vector2(-27,0)])
	b.draw_colored_polygon(contour,fill)
	b.draw_polyline(contour,GOLD,1.2,true)
	for x in range(-18,24,7): line(b,at+Vector2(x,2),at+Vector2(x*.75,21),Color("cfac6e"))
	for y in [6,12,18]: line(b,at+Vector2(-25+y*.25,y),at+Vector2(25-y*.25,y),Color("cfac6e"))


static func progress(b: Control) -> void:
	if b.mode==1: return
	for step in range(b.recipe.size()):
		var at := Vector2(24+step*17,220)
		b.draw_circle(at,3.5,RED if step<b.answered else Color("cabd9e"))
	text(b,Vector2(170,224),"已完成 %d / %d"%[b.answered,b.recipe.size()],12)


static func render(b: Control) -> void:
	panel(b,Rect2(Vector2.ZERO,b.size),Color("f0e4c5"),GOLD,9)
	line(b,Vector2(18,34),Vector2(b.size.x-18,34),Color(.62,.44,.24,.3))
	text(b,Vector2(18,27),"试作 · "+str(b.profile.title),20,RED,true)
	if b.mode==0:
		text(b,Vector2(18,57),"依次留纹："+b._sequence_text(),14)
		for index in range(3):
			var center: Vector2 = b.option_position(index)
			var active: bool = b.stamps[index] or b.lit==index or b.hovered==index
			cloth(b,Rect2(center-Vector2(76,57),Vector2(152,118)),b.profile.id=="dai_brocade",active)
			if b.stamp_reveals[index]>0:
				var printed := CREAM
				printed.a=b.stamp_reveals[index]
				motif(b,center-Vector2(0,5),index,printed)
			else:
				centered(b,center+Vector2(0,0),"素布",13,Color(.86,.83,.69,.65))
			centered(b,center+Vector2(0,48),"%d · %s"%[index+1,MOTIFS[index]],12,CREAM)
	elif b.mode==1:
		centered(b,Vector2(275,55),"驮架配重 · 两筐各 %d 份"%(b.total_weight()/2),14)
		for index in range(b.weights.size()): cargo(b,b.option_position(index),b.weights[index],b.packs[index],b.hovered==index,index+1)
		var amount: int = b._left_weight()
		var tilt: float = clampf((b.total_weight()/2.0-amount)*.6,-8,8)
		var left := Vector2(162,165-tilt)
		var right := Vector2(388,165+tilt)
		b.draw_colored_polygon(PackedVector2Array([Vector2(275,158),Vector2(259,208),Vector2(291,208)]),Color("735638"))
		panel(b,Rect2(248,207,54,6),Color("755535"),GOLD,2)
		line(b,left,right,GOLD,4)
		b.draw_circle(Vector2(275,165),4,CREAM)
		for end in [left,right]:
			line(b,end,end+Vector2(-24,23),GOLD)
			line(b,end,end+Vector2(24,23),GOLD)
			basket(b,end+Vector2(0,23),Color("796345"))
		centered(b,Vector2(76,203),"左 %d 份"%amount,16,RED if b.won else INK,true)
		centered(b,Vector2(474,203),"右 %d 份"%(b.total_weight()-amount),16,RED if b.won else INK,true)
	elif b.mode==3:
		text(b,Vector2(18,56),b._action_text(),12)
		for index in range(b.actions.size()):
			var center: Vector2 = b.option_position(index)
			cloth(b,Rect2(center-Vector2(44,39),Vector2(88,80)),false,index in b.history or b.hovered==index)
			var words: String = b.actions[index]
			if words.length()>4: words=words.substr(0,4)+"\n"+words.substr(4)
			b.draw_multiline_string(UiStyle.heading_font(),center+Vector2(-39,-10),words,HORIZONTAL_ALIGNMENT_CENTER,78,UiStyle.text_size(16),2,CREAM)
			centered(b,center+Vector2(0,31),"✓" if index in b.history else str(index+1),12,CREAM)
	else:
		text(b,Vector2(18,56),"先听乐句，再凭记忆回应；可点「再听一次」。",14)
		for index in range(3):
			var center: Vector2 = b.option_position(index)
			cloth(b,Rect2(center-Vector2(76,57),Vector2(152,118)),false,b.lit==index or b.hovered==index)
			if index==0:
				panel(b,Rect2(center-Vector2(30,16),Vector2(60,27)),Color("976a43"),GOLD,7)
				for cut in [-18,-6,6,18]: line(b,center+Vector2(cut,-11),center+Vector2(cut,5),Color("432c21"),2)
				line(b,center+Vector2(-17,-30),center+Vector2(18,11),CREAM,3)
			elif index==1:
				line(b,center+Vector2(0,-36),center+Vector2(0,-21),GOLD,2)
				b.draw_colored_polygon(PackedVector2Array([center+Vector2(-12,-24),center+Vector2(12,-24),center+Vector2(27,19),center+Vector2(-27,19)]),GOLD)
				line(b,center+Vector2(-30,20),center+Vector2(30,20),CREAM,3)
				b.draw_circle(center+Vector2(0,26),4,CREAM)
			else:
				for pipe in range(5):
					var top: float = -13-pipe*5
					panel(b,Rect2(center+Vector2(-25+pipe*11,top),Vector2(7,26-top)),Color("a7a67b"),GOLD,2)
				line(b,center+Vector2(-29,7),center+Vector2(28,7),CREAM,2)
			centered(b,center+Vector2(0,48),["1 · 木击","2 · 马铃","3 · 竹音"][index],12,CREAM)
	progress(b)
	var message: String = b.message
	if b.mode==1 and not b.won and b._left_weight()==0: message="点击货包换边 · 让木秤两边平衡"
	text(b,Vector2(18,247),message,12,RED if b.won else INK)
