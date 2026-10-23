extends "res://scripts/environment_art.gd"

const UiSkin=preload("res://scripts/interface_skin.gd")
const TITLES: Array[String]=["邓书年的拓片","石阿朵的錾子","老箐的马铃","杨三娘的红线"]
const CHAPTERS: Array[int]=[0,0,1,1]
const POSITIONS: Array[Vector3]=[Vector3(9.2,0,-.55),Vector3(17.4,0,-.55),Vector3(23.0,0,-.55),Vector3(28.8,0,-.55)]
const PLACES: Array[String]=["第一关 · 残廊拓印桌旁","第一关 · 大碑右侧古道口","第二关 · 进山行囊旁","第二关 · 花布架前的石路"]
const USES: Array[String]=["拓片上墙，留下所识之字。","錾子入架，存好护石工具。","马铃挂檐，传递同行声息。","红线系架，标记护碑归处。"]
const STORIES: Array[String]=[
	"邓书年落下的练习拓片。收好纸上的字，带到共庭留给后来人。",
	"石阿朵歇手时放下的錾子。一路护石，入院后再安放到工具架上。",
	"老箐行囊旁遗落的马铃。山路上用来传递同行的声息，入院后挂到檐下。",
	"杨三娘整理货担留下的红线。收好带入院中，用它标记石碑保护架。"
]
var world: Node3D
var collected: Array[bool]=[false,false,false,false]
var pickups: Array[Node3D]=[]
var labels: Array[Label3D]=[]


func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="JourneyKeepsakes"
	var nearby: Node=world.get_node("NearbyInteractions")
	for index in range(4):
		var pickup:=Node3D.new()
		pickup.name="DroppedKeepsake%d"%index
		pickup.position=POSITIONS[index]
		add_child(pickup)
		pickups.append(pickup)
		_box(pickup,Vector3(0,.055,0),Vector3(.68,.075,.48),_surface(Color(.31,.27,.18),0))
		var model: Node3D=world.courtyard.landscape.objects[index].duplicate()
		model.name="RecognizableKeepsake"
		pickup.add_child(model)
		model.visible=true
		model.position=Vector3(0,[.47,.22,.27,.40][index],0)
		model.scale=Vector3.ONE*[.54,.88,.82,.78][index]
		if index==0:
			model.rotation.x=-PI/2
			model.position.y=.14
		if index==2: model.rotation.z=PI/2
		var ring:=MeshInstance3D.new()
		var torus:=TorusMesh.new()
		torus.inner_radius=.34
		torus.outer_radius=.355
		torus.rings=24
		torus.ring_segments=4
		ring.mesh=torus
		ring.position=Vector3(0,.105,0)
		ring.scale.z=.72
		ring.material_override=_flat(Color(.69,.48,.20),true)
		pickup.add_child(ring)
		var glow:=preload("res://scripts/pickup_glow.gd").new()
		pickup.add_child(glow)
		glow.setup(index)
		var label:=Label3D.new()
		label.text=TITLES[index]+" · 本人拾取"
		label.position=Vector3(0,1.03,0)
		label.font=UiSkin.heading_font()
		label.font_size=UiSkin.text_size(20)
		label.pixel_size=.0065
		label.modulate=Color(1,.85,.53)
		label.outline_size=5
		label.visible=false
		pickup.add_child(label)
		labels.append(label)
		nearby._add("keepsake_%d"%index,TITLES[index],pickup,Vector3(0,1.0,0),CHAPTERS[index],"keepsake",index,STORIES[index])
		world.click_interactions.register(nearby.entries[-1],Vector3(.80,.95,.75),Vector3(0,.48,0))


func _allowed() -> bool:
	return world.party.started and not get_tree().paused and not world.party.movement_locked() and world.get_node("PartyUI").screen==2


func in_reach(index: int, body: CharacterBody3D) -> bool:
	return body.is_on_floor() and world.party.planar_speed(body)<.15 and Vector2(body.global_position.x-POSITIONS[index].x,body.global_position.z-POSITIONS[index].z).length()<=1.15


func _physics_process(_delta: float) -> void:
	if world==null or not _allowed(): return
	for body in world.party.human_players():
		if not Input.is_action_just_pressed(body.action("interact")): continue
		var nearest: int=-1
		var distance: float=INF
		for index in range(4):
			if collected[index] or not in_reach(index,body): continue
			var d: float=body.global_position.distance_squared_to(POSITIONS[index])
			if d<distance: nearest=index; distance=d
		if nearest>=0: collect(nearest,body)


func collect(index: int, body: CharacterBody3D) -> bool:
	if index<0 or index>=4 or collected[index] or not _allowed(): return false
	if CHAPTERS[index]==1 and not world.cooperation.gate_open: return false
	if not in_reach(index,body): return false
	if body.character_id!=index:
		_owner_reminder(index)
		return false
	collected[index]=true
	pickups[index].visible=false
	world.sfx.play("paper" if index==0 else "cloth" if index==3 else "button")
	var ui: CanvasLayer=world.get_node("PartyUI")
	ui.notify_keepsake(TITLES[index])
	world.story.speak(world.party.NAMES[body.character_id],"我的%s在这里。先收进包裹，到了共庭再归位。"%["拓片","錾子","马铃","红线"][index],4,true)
	return true


func click_collect(index: int) -> bool:
	if index<0 or index>=4 or collected[index] or not _allowed(): return false
	var humans: Array=world.party.human_players()
	for body in humans:
		if body.character_id==index and in_reach(index,body): return collect(index,body)
	for body in humans:
		if in_reach(index,body):
			_owner_reminder(index)
			return false
	world.story.speak("同行提醒","先走近这件物品，落地站稳，再拾取。",3,true)
	return false


func _owner_reminder(index: int) -> void:
	var owner: int=world.party.owner_of(index)
	var key: String="Tab" if owner==0 else "右Shift"
	var who: String=world.party.NAMES[index].get_slice("（",0)
	world.story.speak("物归其主","这是"+who+"的随身物件。请由"+str(owner+1)+"P按"+key+"切换到本人，走近拾取。",4,true)


func reset_from(chapter: int) -> void:
	if chapter>1: return
	world.get_node("PartyUI")._notice_seconds=0
	world.get_node("PartyUI")._notice_keepsake=false
	for index in range(4):
		if CHAPTERS[index]<chapter: continue
		collected[index]=false
		pickups[index].visible=true


func seed_previous(chapter: int) -> void:
	# Explicit chapter-preview entries supply only the skipped earlier chapters.
	for index in range(4):
		if CHAPTERS[index]>=chapter: continue
		collected[index]=true
		pickups[index].visible=false


func missing_names() -> String:
	var missing: Array[String]=[]
	for index in range(4):
		if not collected[index]: missing.append(TITLES[index])
	return "、".join(missing)


func entry_text(index: int) -> String:
	if world.courtyard.items_done[index]: return "已在共庭归位，点亮同行灯。\n"+USES[index]
	if collected[index]: return "已收进包裹 · 第三关归位。\n"+USES[index]
	var who: String=world.party.NAMES[index].get_slice("（",0)
	return "由"+who+"本人走近站稳。\n按自己的操作键，或点击物件拾取。"
