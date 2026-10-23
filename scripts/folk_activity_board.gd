extends Control

signal completed
const UiSkin = preload("res://scripts/interface_skin.gd")
const INK := Color(.20,.24,.23)
const GOLD := Color(.72,.48,.20)
const RED := Color(.61,.24,.16)
var profile: Dictionary = {}
var mode: int = 0
var audio: Node
var stamps: Array[bool] = [false,false,false]
var stamp_reveals: Array[float] = [0,0,0]
var packs: Array[bool] = []
var weights: Array[int] = []
var recipe: Array[int] = []
var actions: Array[String] = []
var history: Array[int] = []
var answered: int = 0
var running: bool = false
var won: bool = false
var playing_demo: bool = false
var demo_index: int = 0
var clock: float = 0
var lit: int = -1
var flash: float = 0
var message: String = ""
var font: Font
var hovered: int = -1
var native: RefCounted
const Art = preload("res://scripts/folk_activity_art.gd")
const VISUAL_VERSION: int = 2


func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/interface_skin.gd").body_font()



func begin_profile(activity: Dictionary, sound: Node) -> void:
	profile=activity.duplicate(true)
	mode=int(profile.mode)
	audio=sound
	weights.assign(profile.get("weights",[1,2,3,4,6]))
	recipe.assign(profile.get("recipe",[0,1,2]))
	actions.assign(profile.get("actions",[]))
	packs.resize(weights.size())
	running=false
	_reset()
	message="先听听这件器物的故事，再开始小艺。"
	queue_redraw()


func _reset() -> void:
	stamps.fill(false)
	stamp_reveals.fill(0)
	packs.fill(false)
	history.clear()
	answered=0
	won=false
	playing_demo=false
	lit=-1
	flash=0
	native=preload("res://scripts/folk_native_craft.gd").new(self) if mode>=4 else null


func start() -> void:
	_reset()
	running=true
	if native!=null:
		native.refresh_hint()
		queue_redraw()
		return
	message="按上方次序点纹样；点错可重来。" if mode==0 else "点货包换边，让两筐同重。" if mode==1 else "按故事里的顺序点物件，完成准备。"
	if mode==2: demonstrate()
	queue_redraw()


func _sequence_text() -> String:
	var parts: Array[String] = []
	for index in recipe: parts.append(str(index+1))
	return " → ".join(parts)


func _action_text() -> String:
	var parts: Array[String] = []
	for index in recipe: parts.append(actions[index])
	return " → ".join(parts)


func total_weight() -> int:
	var total: int = 0
	for weight in weights: total+=weight
	return total


func _left_weight() -> int:
	var total: int = 0
	for index in range(weights.size()):
		if packs[index]: total+=weights[index]
	return total


func demonstrate() -> void:
	if mode!=2 or not running: return
	playing_demo=true
	lit=-1
	flash=0
	demo_index=0
	clock=.05
	answered=0
	history.clear()
	won=false
	message="先听 %d 声，再按相同次序回应。"%recipe.size()
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	var interface: Node = audio.get_parent().get_node_or_null("PartyUI")
	if interface!=null and interface.screen!=8:
		if native!=null: native.hold=false; native.drag=-1
		return
	if native!=null:
		native.tick(delta)
		return
	if mode==0:
		for index in range(3):
			var next: float = move_toward(stamp_reveals[index],1.0 if stamps[index] else 0.0,delta*3.6)
			if next!=stamp_reveals[index]: stamp_reveals[index]=next; queue_redraw()
	if not running: return
	if flash>0:
		flash-=delta
		if flash<=0: lit=-1; queue_redraw()
	if not playing_demo: return
	clock-=delta
	if clock<=0:
		if demo_index>=recipe.size():
			playing_demo=false
			message="轮到你回应。可点乐器或按 1 / 2 / 3。"
		else:
			_note(recipe[demo_index])
			demo_index+=1
			clock=.48
		queue_redraw()


func _note(index: int) -> void:
	lit=-1 if playing_demo else index
	flash=0 if playing_demo else .3
	audio.last.clear()
	audio.play(["wood","bell","folk_reed"][index])


func choose(index: int) -> void:
	if native!=null: return
	if not running or won or playing_demo or index<0: return
	if mode==1:
		if index>=weights.size(): return
		packs[index]=not packs[index]
		audio.play("cloth")
		var amount: int = _left_weight()
		message="左 %d 份 · 右 %d 份 · 目标各 %d 份"%[amount,total_weight()-amount,total_weight()/2]
		if amount*2==total_weight(): _win("两边同重 · 这份货物也配稳了")
	else:
		var choices: int = actions.size() if mode==3 else 3
		if index>=choices: return
		if mode==2: _note(index)
		else:
			lit=index
			flash=.35
			audio.last.clear()
			audio.play("paper" if mode==0 else "wood")
		if index==recipe[answered]:
			history.append(index)
			answered+=1
			if mode==0: stamps[index]=true
			message="%s %d / %d"%["留纹" if mode==0 else "合奏回应" if mode==2 else "器物准备",answered,recipe.size()]
			if answered==recipe.size(): _win("%s已成 · 记住这件器物与同行的人"%profile.title)
		else:
			answered=0
			history.clear()
			stamps.fill(false)
			message="还没接上，点「再听一次」后重新回应。" if mode==2 else "次序还没接上，从头再试；可看上方提示。"
			audio.play("wrong")
	queue_redraw()


func _win(text: String) -> void:
	won=true
	running=false
	message=text
	audio.play("success")
	completed.emit()


func option_position(index: int) -> Vector2:
	if mode==1: return Vector2(65+index*105,96)
	if mode==3: return Vector2(65+index*105,135)
	return Vector2(100+index*175,130)


func _gui_input(event: InputEvent) -> void:
	if native!=null:
		if running: native.input(event)
		accept_event()
		return
	if event is InputEventMouseMotion:
		hovered=-1
		for index in range(weights.size() if mode==1 else actions.size() if mode==3 else 3):
			if _option_rect(index).has_point(event.position): hovered=index; break
		tooltip_text=("点击移到另一筐" if mode==1 else "点击留下纹样" if mode==0 else "点击回应") if hovered>=0 else ""
		mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if hovered>=0 else Control.CURSOR_ARROW
		queue_redraw()
	if not running: return
	var at := Vector2(-100,-100)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed: at=event.position
	else: return
	if mode in [1,3]:
		for index in range(weights.size() if mode==1 else actions.size()):
			if _option_rect(index).has_point(at): choose(index); break
	else:
		for index in range(3):
			if _option_rect(index).has_point(at): choose(index); break
	accept_event()


func _text(at: Vector2, words: String, size: int = 15, color: Color = INK, heading: bool = false) -> void:
	draw_string(UiSkin.heading_font() if heading else font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)


func _option_rect(index: int) -> Rect2:
	var half := Vector2(44,42) if mode in [1,3] else Vector2(76,60)
	return Rect2(option_position(index)-half,half*2)


func _draw() -> void:
	if font==null or profile.is_empty(): return
	if native!=null:
		native.draw()
		return
	Art.render(self)


func print_fraction() -> float:
	if native==null: return float(answered)/maxi(1,recipe.size())
	if mode==4: return float(native.marks.count(true))/3 if native.phase==2 else 0
	if mode==5: return 1.0 if won else 0.0
	if mode==7: return float(native.rows.size())/maxi(1,native.target_rows.size())
	return 0
