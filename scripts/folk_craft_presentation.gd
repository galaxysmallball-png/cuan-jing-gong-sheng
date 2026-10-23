extends RefCounted

const A=preload("res://scripts/folk_activity_art.gd")
const TEAL=Color("426764")
const BLUE=Color("244c65")
const LINEN=Color("e8dcc0")
const CLAY=Color("925e40")


static func ellipse(b: Control, at: Vector2, radius: Vector2, fill: Color, rim: Color=Color.TRANSPARENT) -> void:
	b.draw_set_transform(at,0,radius)
	b.draw_circle(Vector2.ZERO,1,fill)
	if rim.a>0: b.draw_arc(Vector2.ZERO,1,0,TAU,64,rim,.035,true)
	b.draw_set_transform(Vector2.ZERO)


static func stroke(b: Control, points: Array, ink: Color, width: float) -> void:
	b.draw_polyline(PackedVector2Array(points),ink,width,true)


static func cord(b: Control, points: Array, ink: Color=A.RED, width: float=4) -> void:
	stroke(b,points,Color(ink*.55,ink.a),width+2)
	stroke(b,points,ink,width)
	for i in range(1,points.size()):
		var v: Vector2=points[i]-points[i-1]
		var steps: int=maxi(1,int(v.length()/7))
		for j in range(steps):
			var at: Vector2=points[i-1].lerp(points[i],j/float(steps))
			A.line(b,at-v.normalized().orthogonal()*1.6,at+v.normalized().orthogonal()*1.6,Color(1,.83,.57,.35))


static func surface(b: Control, rect: Rect2, textile: bool=false) -> void:
	A.panel(b,rect,Color("dcd0af") if textile else Color("d7c5a1"),Color(.61,.44,.26,.32),6)
	for i in range(35):
		var x: float=rect.position.x+4+i*(rect.size.x-8)/35
		var y: float=rect.position.y+5+fposmod(i*37.3,rect.size.y-10)
		A.line(b,Vector2(x,y),Vector2(minf(x+22,rect.end.x-3),y+.9),Color(.34,.25,.16,.06),1)
	if textile:
		for y in range(int(rect.position.y)+3,int(rect.end.y)-2,4): A.line(b,Vector2(rect.position.x+3,y),Vector2(rect.end.x-3,y),Color(1,.98,.84,.15))


static func button(b: Control, rect: Rect2, words: String, progress: float=0) -> void:
	A.panel(b,Rect2(rect.position+Vector2(1,3),rect.size),Color(.20,.25,.22,.14),Color.TRANSPARENT,12)
	A.panel(b,rect,TEAL,A.GOLD,12)
	A.panel(b,rect.grow(-5),Color.TRANSPARENT,Color(.81,.72,.48,.4),8)
	A.centered(b,rect.get_center()+Vector2(0,5),words,13,A.CREAM,true)
	if progress>0: A.line(b,rect.position+Vector2(10,rect.size.y-10),rect.position+Vector2(10+(rect.size.x-20)*minf(1,progress),rect.size.y-10),A.CREAM,3)


static func render(g: RefCounted) -> void:
	var b: Control=g.b
	A.panel(b,Rect2(Vector2.ZERO,b.size),Color("f1e4c7"),A.GOLD,10)
	A.text(b,Vector2(20,27),"试作 · "+str(b.profile.title),20,A.RED,true)
	A.line(b,Vector2(20,36),Vector2(530,36),Color(.57,.40,.24,.25))
	A.text(b,Vector2(20,55),g.hint,12)
	surface(b,Rect2(18,64,514,151),true)
	match b.mode:
		4,5: dye(g)
		6: furrows(g)
		7: weave(g)
		8: carrier(g)
		9: joinery(g)
		10: tea(g)
		11: knot(g)
		12: fire(g)
	var words: String=b.message
	A.text(b,Vector2(20,247),words,12,A.RED if b.won else A.INK)


static func dye(g: RefCounted) -> void:
	var b: Control=g.b
	A.cloth(b,Rect2(29,68,282,137),false,false)
	A.panel(b,Rect2(37,75,266,122),LINEN.lerp(BLUE,g.dye),Color("c3b690"),4)
	for y in range(80,194,4): A.line(b,Vector2(42,y),Vector2(299,y),Color(1,.97,.83,.09))
	for x in range(46,300,14): A.line(b,Vector2(x,202),Vector2(x+1,207),Color("b9a984"),1)
	if b.mode==4:
		for i in range(3):
			var at: Vector2=g.KNOTS[i]
			if g.phase==2 and g.marks[i] or b.won:
				for r in range(7): b.draw_arc(at,10+r*3,0,TAU,48,Color(.96,.94,.78,.18+r*.10),1.5,true)
				A.motif(b,at,i,A.CREAM)
			else:
				for r in range(15,0,-2): ellipse(b,at+Vector2(0,2),Vector2(r,r*.62),Color(.62+r*.012,.59+r*.011,.46+r*.013))
				cord(b,[at-Vector2(22,1),at-Vector2(5,0),at+Vector2(5,3),at+Vector2(23,-1)],Color("9f8153"),2)
				if g.marks[i] or g.phase>0:
					b.draw_arc(at-Vector2(5,1),7,-PI,PI*.7,24,A.GOLD,2,true)
					b.draw_arc(at+Vector2(6,-1),7,-PI*.3,PI,24,A.GOLD,2,true)
				else: b.draw_arc(at,25,0,TAU,40,Color(.41,.34,.22,.4),1,true)
	else:
		stroke(b,g.WAX,Color(.40,.36,.25,.24),1.5)
		if g.phase>0: stroke(b,g.WAX,A.CREAM,4)
		elif g.path.size()>1: cord(b,g.path,Color("f4e2a7"),3)
		if b.won:
			for x in [128,212]: A.motif(b,Vector2(x,127),1,Color(.93,.91,.76,.7))
		b.draw_circle(g.WAX[0],5,A.GOLD)
	# Wooden staves and an elliptical indigo surface make a real dye vat.
	A.panel(b,Rect2(375,93,129,94),Color("69503a"),Color("4e3d2c"),18)
	for x in range(386,500,13): A.line(b,Vector2(x,106),Vector2(x-3,182),Color("af8c59"),2)
	for y in [119,168]: A.line(b,Vector2(378,y),Vector2(502,y),Color("4d4538"),4)
	ellipse(b,Vector2(440,99),Vector2(66,23),Color("b08c58"),A.GOLD)
	ellipse(b,Vector2(440,99),Vector2(58,18),BLUE,Color("c0ad77"))
	for i in range(3): ellipse(b,Vector2(434+i*6,100+i*3),Vector2(28-i*5,7-i),Color.TRANSPARENT,Color(.65,.81,.79,.35))
	A.centered(b,Vector2(440,203),"按住入染" if g.phase==1 else "靛蓝染缸",12)
	if g.phase==1: A.line(b,Vector2(384,188),Vector2(384+112*g.amount,188),BLUE,3)


static func furrows(g: RefCounted) -> void:
	var b: Control=g.b
	for row in range(3):
		A.panel(b,Rect2(139,61+row*48,198,45),Color("ae9b6e"),Color("817954"),5)
		for i in range(12): A.line(b,Vector2(146+i*16,96+row*48),Vector2(153+i*16,96+row*48),Color(.3,.35,.21,.25),2)
	for cell in range(9):
		var at: Vector2=g.cell_point(cell)
		if g.FURROWS.has(cell):
			for direction in g.FURROWS[cell]:
				var v: Vector2=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][(direction+g.turns[cell])%4]
				A.line(b,at,at+v*Vector2(29,22),Color("735b3d"),10)
				A.line(b,at+Vector2(1,2),at+v*Vector2(29,22)+Vector2(1,2),Color("c7ab74"),2)
				if cell in g.wet: A.line(b,at,at+v*Vector2(29,22),Color("80b6b6"),5)
		else:
			ellipse(b,at+Vector2(2,5),Vector2(20,11),Color(.2,.24,.18,.15))
			b.draw_colored_polygon(PackedVector2Array([at+Vector2(-17,8),at+Vector2(-15,-8),at+Vector2(-4,-15),at+Vector2(13,-10),at+Vector2(18,7),at+Vector2(7,12)]),Color("7e8878"))
	A.text(b,Vector2(36,84),"溪水 →",13,TEAL)
	for row in range(3):
		for col in range(4):
			var at:=Vector2(376+col*31,99+row*32)
			ellipse(b,at+Vector2(0,5),Vector2(12,3),Color("928c61"))
			A.line(b,at+Vector2(0,5),at-Vector2(0,16),Color("48734b"),2)
			for side in [-1,1]: A.line(b,at,at+Vector2(side*8,-10),Color("63804f"),3)
	A.text(b,Vector2(380,207),"顺坡入畦",12,TEAL)


static func weave(g: RefCounted) -> void:
	var b: Control=g.b
	A.panel(b,Rect2(34,62,321,142),Color("635342"),A.GOLD,5)
	for x in [42,346]:
		A.panel(b,Rect2(x-4,64,9,143),Color("99764e"),Color("715235"),2)
		A.line(b,Vector2(x-1,69),Vector2(x-1,200),Color(.95,.83,.58,.45))
	for y in [66,200]: A.line(b,Vector2(35,y),Vector2(355,y),Color("b18b54"),7)
	for col in range(20):
		var x: float=58+col*14
		A.line(b,Vector2(x,68),Vector2(x,196),Color("82795e"),3)
		A.line(b,Vector2(x-1,68),Vector2(x-1,196),LINEN,1)
	for row in range(g.rows.size()):
		var y: float=76+row*20
		var color: Color=A.RED if g.rows[row]==0 else BLUE
		for offset in [-3,0,3]: A.line(b,Vector2(50,y+offset),Vector2(338,y+offset),color.lightened(offset*.025),3)
		for col in range(20):
			if (col+row)%2==0: A.line(b,Vector2(58+col*14,y-6),Vector2(58+col*14,y+6),LINEN,2)
	for i in range(2):
		var at:=Vector2(420+i*60,91)
		ellipse(b,at+Vector2(2,18),Vector2(24,5),Color(.2,.22,.16,.15))
		ellipse(b,at,Vector2(23,20),A.RED if i==0 else BLUE)
		for row in range(7): b.draw_arc(at,4+row*2,0,TAU,32,Color(.97,.88,.65,.34),1,true)
		if g.colour==i: b.draw_arc(at,27,0,TAU,40,A.GOLD,2,true)
	A.text(b,Vector2(396,137),"样带",12)
	for row in range(g.target_rows.size()): b.draw_rect(Rect2(452,121+row*12,46,8),A.RED if g.target_rows[row]==0 else BLUE)
	if not b.won:
		var at: Vector2=g.pointer if g.drag==0 else g.shuttle_start()
		var outline:=PackedVector2Array([at+Vector2(-23,0),at+Vector2(-12,-8),at+Vector2(13,-8),at+Vector2(23,0),at+Vector2(12,8),at+Vector2(-13,8)])
		b.draw_colored_polygon(outline,Color("bc935b"))
		b.draw_polyline(outline,Color("765534"),1,true)
		A.line(b,at-Vector2(10,0),at+Vector2(10,0),LINEN,4)
	A.text(b,Vector2(39,228),"经纬交错 · %d / %d 行"%[g.rows.size(),g.target_rows.size()],12)


static func carrier(g: RefCounted) -> void:
	var b: Control=g.b
	for side in [-1,1]: cord(b,[Vector2(242+side*25,111),Vector2(242+side*65,145),Vector2(242+side*75,186)],Color("8d7857"),7)
	A.cloth(b,Rect2(200,99,84,101),false,true)
	for row in range(3):
		for col in range(2):
			b.draw_arc(Vector2(220+col*40,131+row*23),8,0,TAU,24,LINEN,1.5,true)
	ellipse(b,Vector2(242,87),Vector2(21,24),Color("d2ab83"),Color("a88461"))
	ellipse(b,Vector2(242,70),Vector2(21,9),BLUE)
	for x in [234,250]: b.draw_arc(Vector2(x,85),4,.1,PI-.1,16,Color("6a4a38"),1.5,true)
	b.draw_arc(Vector2(242,94),4,.2,PI-.2,16,Color("a56c58"),1,true)
	for i in range(2):
		var at:=Vector2(60+i*230,188)
		cord(b,[at,at+Vector2(130,0)],Color("ad8b53"),6)
		A.line(b,at+Vector2(58,0),at+Vector2(84,0),TEAL,9)
		var knot_at: Vector2=at+Vector2(130*g.tension[i],0)
		b.draw_arc(knot_at-Vector2(4,2),6,0,TAU,28,A.RED,3,true)
		b.draw_arc(knot_at+Vector2(4,2),6,0,TAU,28,A.RED,3,true)
		A.text(b,at-Vector2(0,22),"左带" if i==0 else "右带",12)
	button(b,Rect2(414,105,112,75),"按住试背",g.amount/1.2)


static func joinery(g: RefCounted) -> void:
	var b: Control=g.b
	var at:=Vector2(275,88)
	var face:=PackedVector2Array([at,at+Vector2(115,0),at+Vector2(115,83),at+Vector2(0,83)])
	b.draw_colored_polygon(PackedVector2Array([at+Vector2(0,83),at+Vector2(115,83),at+Vector2(125,72),at+Vector2(125,-10),at+Vector2(115,0),at]),Color("6d4f32"))
	b.draw_colored_polygon(face,Color("aa8450"))
	for y in range(94,170,9): A.line(b,Vector2(280,y),Vector2(385,y+2),Color(.37,.24,.12,.18))
	b.draw_rect(Rect2(302,104,56,46),Color("644b32"))
	b.draw_rect(Rect2(307,110,46,35),Color("302f26"))
	var shape:=PackedVector2Array()
	for v in [Vector2(-53,-17),Vector2(5,-17),Vector2(5,-11),Vector2(31,-11),Vector2(31,11),Vector2(5,11),Vector2(5,17),Vector2(-53,17)]: shape.append(g.piece+v.rotated(g.rotation*PI/2))
	var shadow:=PackedVector2Array()
	for p in shape: shadow.append(p+Vector2(4,5))
	b.draw_colored_polygon(shadow,Color(.24,.19,.12,.25))
	b.draw_colored_polygon(shape,Color("c79c60"))
	b.draw_polyline(shape,Color("8b693d"),2,true)
	for offset in [-9,-3,4,10]:
		A.line(b,g.piece+Vector2(-48,offset).rotated(g.rotation*PI/2),g.piece+Vector2(0,offset+1).rotated(g.rotation*PI/2),Color(.49,.32,.15,.4),1)
	A.centered(b,Vector2(130,200),"↻ 转正榫口",14)
	if g.phase==1: button(b,Rect2(415,93,112,92),"按住木销",g.amount/.8)


static func cup(b: Control, at: Vector2, fill: float, target: float, served: bool) -> void:
	ellipse(b,at+Vector2(2,63),Vector2(40,9),Color(.24,.25,.19,.13))
	ellipse(b,at+Vector2(0,58),Vector2(24,6),Color("6b7769"))
	var outline:=PackedVector2Array([at+Vector2(-37,-25),at+Vector2(-32,29),at+Vector2(-25,49),at+Vector2(0,58),at+Vector2(25,49),at+Vector2(32,29),at+Vector2(37,-25)])
	b.draw_colored_polygon(outline,Color("9fae94"))
	for i in range(12):
		var x: float=-27+i*4.5
		A.line(b,at+Vector2(x,-21),at+Vector2(x*.70,45),Color(1,.97,.80,.025+sin(i/11.0*PI)*.035),3)
	if fill>0:
		var y: float=47-clampf(fill,0,1)*65
		var w: float=26+clampf(fill,0,1)*8
		b.draw_colored_polygon(PackedVector2Array([at+Vector2(-w,y),at+Vector2(w,y),at+Vector2(24,51),at+Vector2(0,56),at+Vector2(-24,51)]),Color("a67c3f"))
		ellipse(b,at+Vector2(0,y),Vector2(w,5),Color("c29a52"),Color("e3bd75"))
	var y: float=47-target*65
	A.line(b,at+Vector2(-30,y),at+Vector2(-18,y),A.RED,2)
	A.line(b,at+Vector2(18,y),at+Vector2(30,y),A.RED,2)
	ellipse(b,at-Vector2(0,25),Vector2(37,9),Color("d0d6b6"),Color("77856e"))
	ellipse(b,at-Vector2(0,25),Vector2(31,5),Color("646e59"))
	A.centered(b,at+Vector2(0,80),"已分好" if served else "按住斟茶",12,TEAL if served else A.INK)


static func tea(g: RefCounted) -> void:
	var b: Control=g.b
	# A dark clay kettle with belly, foot, fitted lid, curved spout and loop handle.
	var at:=Vector2(83,132)
	ellipse(b,at+Vector2(2,45),Vector2(53,9),Color(.20,.22,.18,.14))
	b.draw_arc(at+Vector2(-22,-8),32,PI*.48,PI*1.52,40,Color("4b463a"),8,true)
	b.draw_arc(at+Vector2(-22,-8),32,PI*.48,PI*1.52,40,Color("938064"),2,true)
	b.draw_colored_polygon(PackedVector2Array([at+Vector2(27,-8),at+Vector2(49,-21),at+Vector2(59,-42),at+Vector2(65,-41),at+Vector2(61,-13),at+Vector2(38,15)]),Color("68604b"))
	ellipse(b,at+Vector2(0,36),Vector2(28,6),Color("494334"))
	ellipse(b,at,Vector2(42,37),Color("615b47"),Color("8b7957"))
	for i in range(14): b.draw_arc(at-Vector2(5,5),18+i,PI*1.05,PI*1.78,40,Color(1,.89,.66,.015),2,true)
	ellipse(b,at-Vector2(0,32),Vector2(31,8),Color("8b7a58"),A.GOLD)
	ellipse(b,at-Vector2(0,39),Vector2(8,5),Color("b49761"))
	for row in [-8,0,8]: A.line(b,at+Vector2(-15,row),at+Vector2(15,row),Color(.80,.70,.45,.18))
	if g.phase==0:
		A.panel(b,Rect2(185,115,303,24),Color("c3b48e"),A.GOLD,12)
		A.line(b,Vector2(185+303*.55,127),Vector2(185+303*.86,127),TEAL,15)
		b.draw_circle(Vector2(185+303*g.heat,127),8,CLAY)
		A.centered(b,Vector2(335,177),"按住温茶 · 到绿区松开",14)
	else:
		for i in range(3): cup(b,Vector2(232+i*110,126),g.cups[i],g.target_fills[i],g.served[i])
		if g.hold and g.drag>=0:
			var end:=Vector2(232+g.drag*110,105)
			stroke(b,[at+Vector2(63,-40),at+Vector2(110,-43),end+Vector2(-22,-20),end],Color(.68,.55,.30,.25),6)
			stroke(b,[at+Vector2(63,-40),at+Vector2(110,-43),end+Vector2(-22,-20),end],Color("d8b46b"),2.5)
	for i in range(3): b.draw_arc(at+Vector2(-12+i*14,-54-i*4),7,-PI*.9,PI*.3,24,Color(.88,.85,.72,.35),1,true)


static func knot(g: RefCounted) -> void:
	var b: Control=g.b
	A.panel(b,Rect2(190,67,43,137),Color("8c6844"),Color("6d4e32"),4)
	for i in range(6): A.line(b,Vector2(197+i*5,72),Vector2(194+i*5,199),Color(.31,.22,.12,.17))
	for y in [74,193]:
		A.line(b,Vector2(191,y),Vector2(233,y),Color("a98952"),5)
		b.draw_circle(Vector2(198,y),2,Color("514937"))
	if g.phase<2:
		stroke(b,g.rope_path(),Color(.59,.31,.23,.24),3)
		ellipse(b,g.rope_path()[0],Vector2(10,7),A.RED)
		if g.path.size()>1: cord(b,g.path)
	if g.phase>0: cord(b,[Vector2(75,100),Vector2(180,80),Vector2(300,155)])
	if g.phase>1:
		cord(b,[Vector2(75,175),Vector2(190,180),Vector2(310,105)])
		button(b,Rect2(415,95,112,90),"按住收紧",g.amount/.7)
		if b.won:
			b.draw_arc(Vector2(212,130),18,0,TAU,40,A.RED,5,true)
			for side in [-1,1]: cord(b,[Vector2(212+side*8,143),Vector2(212+side*15,180),Vector2(212+side*12,201)],A.RED,3)


static func fire(g: RefCounted) -> void:
	var b: Control=g.b
	if g.phase==0:
		for i in range(2):
			var at:=Vector2(112+i*120,130)
			b.draw_colored_polygon(PackedVector2Array([at+Vector2(-28,20),at+Vector2(-36,-6),at+Vector2(-8,-23),at+Vector2(25,-12),at+Vector2(33,15),at+Vector2(6,27)]),Color("727b6b") if i==0 else Color("9b8a67"))
		A.line(b,Vector2(60,187),Vector2(300,187),Color("9b8661"),3)
		A.line(b,Vector2(138,187),Vector2(178,187),A.GOLD,8)
		b.draw_circle(Vector2(154+92*sin(g.spark_clock*2.7),187),5,Color("fff0a9"))
		A.text(b,Vector2(362,142),"火星 %d / 3"%int(g.amount),14)
	elif g.phase==1:
		ellipse(b,Vector2(200,144),Vector2(96,28),Color("71543b"),A.GOLD)
		ellipse(b,Vector2(200,134),Vector2(92,22),Color("493f32"))
		for i in range(18):
			var x: float=140+fposmod(i*31.7,120)
			var y: float=125+sin(i*4.6)*12
			ellipse(b,Vector2(x,y),Vector2(9,6),Color("a85a2d").lerp(Color("e9a74b"),g.ember))
		A.line(b,Vector2(80,193),Vector2(320,193),Color("9b8661"),7)
		A.line(b,Vector2(176,193),Vector2(253,193),TEAL,10)
		b.draw_circle(Vector2(80+g.ember*240,193),7,CLAY)
		button(b,Rect2(385,88,130,105),"按住扇风",g.flame_time/1.8)
	else:
		for i in range(3):
			var at:=Vector2(135+i*140,145)
			ellipse(b,at+Vector2(0,28),Vector2(40,6),Color(.22,.24,.17,.15))
			ellipse(b,at,Vector2(34,19),Color("8d693d"),A.GOLD)
			ellipse(b,at-Vector2(0,7),Vector2(33,10),Color("4e4936"))
			A.line(b,at,at-Vector2(0,20),Color("c1b284"),3)
			if g.marks[i]:
				ellipse(b,at-Vector2(0,27),Vector2(8,16),Color("e7a243"))
				ellipse(b,at-Vector2(0,24),Vector2(4,9),Color("ffdea1"))
			A.centered(b,at+Vector2(0,52),"已传火" if g.marks[i] else "点灯",12)
