extends Node3D

const UiSkin=preload("res://scripts/interface_skin.gd")
const COLORS: Array[Color]=[Color(1,.35,.26),Color(1,.75,.29),Color(.39,1,.63),Color(.30,.77,1),Color(.69,.46,1),Color(1,.40,.71)]
const TRAIL_CAPACITY: int=128
var world: Node3D
var fireworks: Node3D
var button: Button
var canvas: CanvasLayer
var flowers: MultiMeshInstance3D
var footprints: Array[Dictionary]=[]
var last_positions: Dictionary={}
var distances: Dictionary={}
var step_counts: Dictionary={}
var cooldown: float=0
var flower_count: int=0
var foot_lights: Array[OmniLight3D]=[]

func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="CelebrationRewards"
	process_mode=Node.PROCESS_MODE_ALWAYS
	fireworks=preload("res://scripts/reward_fireworks.gd").new()
	add_child(fireworks)
	fireworks.setup(world)
	canvas=CanvasLayer.new()
	canvas.layer=12
	add_child(canvas)
	button=Button.new()
	button.name="LaunchFireworks"
	button.text="放烟花"
	button.size=Vector2(146,48)
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_override("font",UiSkin.heading_font())
	button.add_theme_font_size_override("font_size",UiSkin.text_size(20))
	UiSkin.button(button,true)
	button.add_theme_stylebox_override("disabled",UiSkin.texture_paper(false,Color(.92,.88,.79)))
	button.add_theme_color_override("font_disabled_color",Color(.43,.28,.15))
	canvas.add_child(button)
	button.pressed.connect(launch_fireworks)
	button.visible=false
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	mm.mesh=QuadMesh.new()
	mm.instance_count=TRAIL_CAPACITY
	mm.visible_instance_count=0
	mm.custom_aabb=AABB(Vector3(-5,-10,-10),Vector3(85,25,25))
	flowers=MultiMeshInstance3D.new()
	flowers.name="RainbowFootFlowers"
	flowers.multimesh=mm
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/footflower_glow.gdshader")
	flowers.material_override=material
	flowers.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flowers)
	for i in range(4):
		var light:=OmniLight3D.new()
		light.omni_range=1.20
		light.light_energy=.70
		light.visible=false
		add_child(light)
		foot_lights.append(light)

func _gameplay() -> bool:
	var ui: CanvasLayer=world.get_node("PartyUI")
	return world.party.started and ui.screen==ui.Screen.GAME and not get_tree().paused and not world.courtyard.record_open and not world.party.movement_locked()

func _all_achievements() -> bool:
	return world.courtyard.landscape.collection_reward.complete

func launch_fireworks() -> void:
	if not _gameplay() or not _all_achievements() or cooldown>0: return
	fireworks.launch()
	cooldown=fireworks.SHOW_SECONDS

func _process(delta: float) -> void:
	if world==null: return
	var gameplay: bool=_gameplay()
	var mobile_dual: bool=world.mobile_controls!=null and world.party.local_coop
	button.position=get_viewport().get_visible_rect().size-Vector2(170,52 if mobile_dual else 76)
	button.visible=gameplay and _all_achievements() and not world.story.frame.visible
	button.disabled=cooldown>0
	button.text="烟花绽放" if cooldown>0 else "放烟花"
	fireworks.visible=gameplay
	flowers.visible=gameplay
	for light in foot_lights: light.visible=false
	if not gameplay:
		last_positions.clear()
		return
	cooldown=maxf(0,cooldown-delta)
	fireworks.update(delta)
	var cleared: bool=world.ending_reached and world.courtyard.court_lit
	if not cleared:
		footprints.clear()
		last_positions.clear()
		flowers.multimesh.visible_instance_count=0
		return
	for i in range(footprints.size()-1,-1,-1):
		footprints[i].age+=delta
		if footprints[i].age>2.1: footprints.remove_at(i)
	var actor_index: int=-1
	for actor in world.party.human_players():
		actor_index+=1
		var id: int=actor.character_id
		var current: Vector3=actor.global_position
		var previous: Vector3=last_positions.get(id,current)
		last_positions[id]=current
		var d: float=Vector2(current.x-previous.x,current.z-previous.z).length()
		if d>1.0: distances[id]=0; continue
		if not actor.is_on_floor() or world.party.planar_speed(actor)<.25: continue
		var light: OmniLight3D=foot_lights[actor_index]
		light.visible=true
		light.global_position=current-Vector3(0,.51,0)
		light.light_color=COLORS[(id+int(step_counts.get(id,0)))%COLORS.size()]
		distances[id]=float(distances.get(id,0)) + d
		if distances[id]<.44: continue
		distances[id]=0
		var step: int=int(step_counts.get(id,0))+1
		step_counts[id]=step
		var direction:=Vector2(current.x-previous.x,current.z-previous.z).normalized()
		var side:=Vector2(-direction.y,direction.x)*(.085 if step%2 else -.085)
		var at:=Vector3(current.x+side.x,current.y-.7+.018,current.z+side.y)
		var query:=PhysicsRayQueryParameters3D.create(Vector3(at.x,current.y-.25,at.z),Vector3(at.x,current.y-1.4,at.z),1)
		var ground: Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
		if not ground.is_empty(): at.y=ground.position.y+.018
		footprints.append({"age":0.0,"at":at,"color":(id+step)%COLORS.size(),"angle":atan2(direction.y,direction.x)+step*.17})
		flower_count+=1
		if footprints.size()>TRAIL_CAPACITY: footprints.pop_front()
	for i in range(footprints.size()):
		var f: Dictionary=footprints[i]
		var t: float=f.age/2.1
		var s: float=lerpf(.50,.73,smoothstep(0,.38,t))
		# Quad local XY lies on world XZ; rotate the motif around the ground normal.
		var basis:=Basis(Vector3.UP,f.angle)*Basis(Vector3.RIGHT,-PI*.5)*Basis.from_scale(Vector3(s,s,1))
		flowers.multimesh.set_instance_transform(i,Transform3D(basis,f.at))
		var hue: Color=COLORS[f.color]
		hue.a=pow(1-t,1.45)
		flowers.multimesh.set_instance_color(i,hue)
	flowers.multimesh.visible_instance_count=footprints.size()

func reset() -> void:
	if world!=null and world.sfx!=null: world.sfx.stop_fireworks()
	cooldown=0
	footprints.clear()
	last_positions.clear()
	distances.clear()
	step_counts.clear()
	if fireworks!=null: fireworks.clear()
	if flowers!=null: flowers.multimesh.visible_instance_count=0
	if button!=null: button.visible=false
	for light in foot_lights: light.visible=false
