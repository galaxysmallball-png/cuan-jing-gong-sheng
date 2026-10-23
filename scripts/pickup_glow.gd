extends Node3D

var clock: float=0
var flecks: MultiMeshInstance3D
var ring: MeshInstance3D

func setup(index: int) -> void:
	name="KeepsakeGuidingLight"
	var hues: Array[Color]=[Color(.54,.81,1),Color(.52,.95,.76),Color(1,.77,.30),Color(1,.45,.39)]
	var hue: Color=hues[index]
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/reward_halo.gdshader")
	material.set_shader_parameter("tint",hue)
	material.set_shader_parameter("strength",.50)
	var disc:=MeshInstance3D.new()
	var quad:=QuadMesh.new()
	quad.size=Vector2(1.35,1.35)
	disc.mesh=quad
	disc.rotation.x=-PI/2
	disc.position.y=.115
	disc.material_override=material
	disc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	var mist:=MeshInstance3D.new()
	var beam:=QuadMesh.new()
	beam.size=Vector2(.53,1.13)
	mist.mesh=beam
	mist.position=Vector3(0,.42,-.08)
	var soft: ShaderMaterial=material.duplicate()
	soft.set_shader_parameter("strength",.18)
	mist.material_override=soft
	mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mist)
	var light:=OmniLight3D.new()
	light.position=Vector3(0,.32,.18)
	light.light_color=hue
	light.light_energy=.55
	light.omni_range=1.5
	add_child(light)
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	var star:=QuadMesh.new()
	star.size=Vector2(.055,.055)
	mm.mesh=star
	mm.instance_count=8
	flecks=MultiMeshInstance3D.new()
	flecks.multimesh=mm
	var glitter:=ShaderMaterial.new()
	glitter.shader=preload("res://shaders/collection_glint.gdshader")
	flecks.material_override=glitter
	flecks.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flecks)
	clock=index*.51

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	clock+=delta
	for i in range(8):
		var t: float=fposmod(clock*.35+i*.618,1)
		var p:=Vector3(sin(i*2.3+clock*.5)*.28,.12+t*.73,.12+cos(i*1.9)*.18)
		var s: float=sin(t*PI)
		flecks.multimesh.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3.ONE*s),p))
