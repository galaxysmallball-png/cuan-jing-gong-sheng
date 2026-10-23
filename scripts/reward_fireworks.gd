extends Node3D

const COLORS: Array[Color]=[Color(1,.19,.13),Color(1,.70,.16),Color(.24,1,.56),Color(.17,.64,1),Color(.66,.27,1),Color(1,.26,.57),Color(1,.83,.43)]
const CAPACITY: int=12000
const SHOW_SECONDS: float=7.4
var world: Node3D
var particles: MultiMeshInstance3D
var halos: MultiMeshInstance3D
var bursts: Array[Dictionary]=[]
var used: int=0
var launched: int=0
var burst_sounds: int=0

func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="PlayerFireworks"
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	mm.mesh=QuadMesh.new()
	mm.instance_count=CAPACITY
	mm.visible_instance_count=0
	mm.custom_aabb=AABB(Vector3(-100,-30,-50),Vector3(220,120,120))
	particles=MultiMeshInstance3D.new()
	particles.multimesh=mm
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/firework_glow.gdshader")
	particles.material_override=material
	particles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	var halo_mm:=MultiMesh.new()
	halo_mm.transform_format=MultiMesh.TRANSFORM_3D
	halo_mm.use_colors=true
	halo_mm.mesh=QuadMesh.new()
	halo_mm.instance_count=10
	halo_mm.visible_instance_count=0
	halo_mm.custom_aabb=mm.custom_aabb
	halos=MultiMeshInstance3D.new()
	halos.multimesh=halo_mm
	var haze:=ShaderMaterial.new()
	haze.shader=preload("res://shaders/firework_atmosphere.gdshader")
	halos.material_override=haze
	halos.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halos)

func launch() -> void:
	var size: Vector2=get_viewport().get_visible_rect().size
	# Three acts: coloured peonies, a gold willow canopy, then five finale shells.
	var positions: Array[Vector2]=[Vector2(.22,.26),Vector2(.50,.19),Vector2(.78,.26),Vector2(.32,.22),Vector2(.68,.22),Vector2(.15,.29),Vector2(.33,.19),Vector2(.50,.25),Vector2(.67,.19),Vector2(.85,.29)]
	var delays: Array[float]=[0,.23,.46,1.45,1.76,3.0,3.21,3.42,3.63,3.84]
	for i in range(positions.size()):
		var center: Vector3=world.camera.project_position(positions[i]*size,13.5)
		bursts.append({"age":-delays[i],"center":center,"color":(launched+i*2)%COLORS.size(),"kind":1 if i in [3,4] else 0,"launch":false,"boom":false})
	launched+=1

func update(delta: float) -> void:
	used=0
	var halo_count: int=0
	for i in range(bursts.size()-1,-1,-1):
		var data: Dictionary=bursts[i]
		data.age+=delta
		var age: float=data.age
		if age<0: continue
		if not data.launch:
			data.launch=true
			world.sfx.play("firework_launch")
		if age>.70 and not data.boom:
			data.boom=true
			burst_sounds+=1
			world.sfx.play("firework_burst")
		if age>3.5:
			bursts.remove_at(i)
			continue
		var center: Vector3=data.center
		if age<.70:
			for tail in range(24):
				var t: float=maxf(0,age/.70-tail*.016)
				var p: Vector3=(center-Vector3(.36,4.4,0)).lerp(center,t*t*.30+t*.70)
				p.x+=sin(t*11)*.018
				_spark(p,.105-tail*.003,Color(1,.71,.28,1-tail*.037))
			continue
		var t: float=age-.70
		var willow: bool=data.kind==1
		var fade: float=pow(maxf(0,1-t/2.8),1.12)
		var color: Color=COLORS[data.color]
		var halo_size: float=(1.0-exp(-t*1.8))*6.6
		halos.multimesh.set_instance_transform(halo_count,Transform3D(Basis.from_scale(Vector3(halo_size,halo_size,1)),center-Vector3(0,t*t*.1,.1)))
		halos.multimesh.set_instance_color(halo_count,Color(color,fade*.24))
		halo_count+=1
		# Two spherical layers with long segmented trails.
		for ray in range(144):
			var angle: float=ray*2.399963+data.color*.24
			var z: float=1.0-2.0*(float(ray)+.5)/144.0
			var radius: float=sqrt(1-z*z)
			var direction:=Vector3(cos(angle)*radius,sin(angle)*radius,z*.22)
			var outer: bool=ray%3!=0
			var speed: float=(2.85 if outer else 1.55)*(1.0 if not willow else 1.15)
			var tint: Color=Color(1,.69,.22) if willow else color.lerp(COLORS[(data.color+2)%COLORS.size()],.60 if not outer else .0)
			for tail in range(9):
				var tt: float=maxf(0,t-tail*.048)
				var distance: float=(1.0-exp(-tt*1.85))*speed
				var p: Vector3=center+direction*distance-Vector3(0,tt*tt*(.38 if willow else .23),0)
				var prior: float=maxf(0,tt-.065)
				var previous: Vector3=center+direction*(1.0-exp(-prior*1.85))*speed-Vector3(0,prior*prior*(.38 if willow else .23),0)
				var glow: Color=tint.lerp(Color(1,.95,.73),maxf(0,1-t*2)*.72)
				glow.a=fade*(1-tail*.095)*(.76+.24*sin(ray*17+t*24))
				_streak(previous,p,(.080-tail*.006)*(1.0 if outer else .78),glow)
				if tail==0: _spark(p,.105,glow.lerp(Color(1,.94,.72,glow.a),.30))
		# Secondary palm bursts on the tips, followed by golden glitter rain.
		if t>.85:
			var st: float=t-.85
			for seed_index in range(12):
				var a: float=seed_index*TAU/12+data.color*.24
				var tip: Vector3=center+Vector3(cos(a),sin(a),0)*(1-exp(-.85*1.85))*2.6
				for ray in range(12):
					var aa: float=ray*TAU/12+seed_index
					var p: Vector3=tip+Vector3(cos(aa),sin(aa),0)*(1-exp(-st*2.2))*.54-Vector3(0,st*st*.42,0)
					var twinkle: float=pow(maxf(0,sin(st*29+ray*2.1+seed_index)),3)
					_spark(p,.065+twinkle*.035,Color(1,.79,.38,fade*(.25+twinkle*.75)))
		if t<.20:
			_spark(center,.65*(1-t/.20),Color(1,.88,.58,(1-t/.20)*.60))
	particles.multimesh.visible_instance_count=used
	halos.multimesh.visible_instance_count=halo_count

func _spark(at: Vector3,size_value: float,color: Color) -> void:
	if used>=CAPACITY: return
	particles.multimesh.set_instance_transform(used,Transform3D(Basis.from_scale(Vector3(size_value,size_value,1)),at))
	particles.multimesh.set_instance_color(used,color)
	used+=1

func _streak(from: Vector3,to: Vector3,width: float,color: Color) -> void:
	if used>=CAPACITY: return
	var d: Vector3=to-from
	var basis:=Basis(Vector3.BACK,atan2(d.y,d.x))*Basis.from_scale(Vector3(d.length()+width,width,1))
	particles.multimesh.set_instance_transform(used,Transform3D(basis,(from+to)*.5))
	particles.multimesh.set_instance_color(used,color)
	used+=1

func clear() -> void:
	bursts.clear()
	used=0
	particles.multimesh.visible_instance_count=0
	halos.multimesh.visible_instance_count=0
