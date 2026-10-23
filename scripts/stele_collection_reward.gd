extends "res://scripts/environment_art.gd"

var complete: bool=false
var amount: float=0.0
var materials: Array[ShaderMaterial]=[]
var inlay: Node3D
var motes: MultiMeshInstance3D
var clock: float=0
var aura_material: ShaderMaterial
var glow_light: OmniLight3D
const PIGMENTS: Array[Color]=[Color(.71,.16,.12),Color(.88,.41,.12),Color(.87,.70,.24),Color(.19,.53,.30),Color(.16,.60,.64),Color(.20,.32,.69),Color(.52,.25,.59)]
const PIGMENT_TEXTURE: Texture2D=preload("res://assets/rewards/stele_mineral_pigment_20261021.png")

func setup(chapter: Node3D) -> void:
	name="CollectedColors"
	materials=[chapter._tablet.material_override,chapter.landscape.inscription.material_override]
	for material in materials: material.set_shader_parameter("collection_pigment_texture",PIGMENT_TEXTURE)
	_build_inlay(chapter._tablet)
	_apply()

func set_complete(value: bool) -> void:
	complete=value
	if not complete:
		amount=0
		_apply()

func _process(delta: float) -> void:
	if complete and amount<1:
		amount=move_toward(amount,1,delta/2.2)
		_apply()
	if complete and amount>.7:
		clock+=delta
		for i in range(18):
			var phase: float=fmod(clock*.12+i*.618,1.0)
			var side: float=-1 if i%2==0 else 1
			var scale_value: float=.008+.012*pow(sin(phase*PI),2)
			var speck_position:=Vector3(side*(.63+.075*sin(phase*TAU+i)), -1.1+phase*2.8,.35+.10*sin(i*1.7))
			motes.multimesh.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3.ONE*scale_value),speck_position))

func _apply() -> void:
	for material in materials:
		material.set_shader_parameter("collection_color_amount",smoothstep(0,1,amount))
	if is_instance_valid(inlay):
		inlay.visible=amount>.72
		inlay.scale=Vector3.ONE*(.985+.015*smoothstep(.72,1,amount))
		if aura_material!=null: aura_material.set_shader_parameter("strength",.60*smoothstep(.72,1,amount))
		if glow_light!=null: glow_light.light_energy=1.1*smoothstep(.72,1,amount)


func _build_inlay(tablet: MeshInstance3D) -> void:
	inlay=Node3D.new()
	inlay.name="SevenPigmentInlay"
	# Light veils and floating gold never carry the stone's weight.
	inlay.set_meta("nonstructural_effect",true)
	tablet.add_child(inlay)
	var halo:=MeshInstance3D.new()
	var veil:=QuadMesh.new()
	veil.size=Vector2(2.65,3.8)
	halo.mesh=veil
	halo.position=Vector3(0,.08,-.24)
	aura_material=ShaderMaterial.new()
	aura_material.shader=preload("res://shaders/reward_halo.gdshader")
	aura_material.set_shader_parameter("tint",Color(1,.74,.32))
	halo.material_override=aura_material
	halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inlay.add_child(halo)
	glow_light=OmniLight3D.new()
	glow_light.position=Vector3(0,.3,.85)
	glow_light.light_color=Color(1,.76,.39)
	glow_light.omni_range=3.8
	inlay.add_child(glow_light)
	var gold: Material=_flat(Color(.69,.47,.18))
	gold.metallic=.72
	gold.roughness=.42
	var strands: Array=[]
	for side in [-1,1]:
		for segment in range(16):
			var y: float=-1.035+segment*.133
			strands.append([Vector3(side*.503,y,.226),Vector3(side*.503,y+.118,.226),.0045])
		for sign_y in [-1,1]:
			var corner:=Vector3(side*.496,sign_y*1.095,.227)
			strands.append([corner,corner+Vector3(-side*.22,0,0),.006])
			strands.append([corner,corner+Vector3(0,-sign_y*.15,0),.006])
			# Small curled cloud tendrils sit above/below the inscription, leaving
			# the characters uncovered. Radius changes give the scrolls tapered ends.
			for segment in range(22):
				var t: float=float(segment)/22
				var tt: float=float(segment+1)/22
				var a:=Vector3(side*(.365+cos(t*TAU*1.1)*.054*(1-t)),sign_y*(1.06+sin(t*TAU*1.1)*.024*(1-t)),.228)
				var b:=Vector3(side*(.365+cos(tt*TAU*1.1)*.054*(1-tt)),sign_y*(1.06+sin(tt*TAU*1.1)*.024*(1-tt)),.228)
				strands.append([a,b,.0035*(1-t*.5)])
	# Fine lines continue around the real top and side thickness.
	for side in [-1,1]:
		strands.append([Vector3(side*.50,1.11,.223),Vector3(side*.50,1.11,-.22),.005])
	_rods_merged(inlay,gold,strands).name="WornGoldCloudInlay"
	for i in range(7):
		var gem:=MeshInstance3D.new()
		var bead:=SphereMesh.new()
		bead.radius=.027
		bead.height=.054
		bead.radial_segments=12
		bead.rings=6
		gem.mesh=bead
		gem.position=Vector3((i-3)*.12,1.24,.235)
		var pigment:=_flat(PIGMENTS[i])
		pigment.metallic=.30
		pigment.roughness=.37
		gem.material_override=pigment
		inlay.add_child(gem)
		var ring:=TorusMesh.new()
		ring.inner_radius=.027
		ring.outer_radius=.032
		ring.rings=16
		ring.ring_segments=5
		var setting:=MeshInstance3D.new()
		setting.mesh=ring
		setting.rotation.x=PI/2
		setting.position=gem.position
		setting.material_override=gold
		inlay.add_child(setting)
	var points:=MultiMesh.new()
	points.transform_format=MultiMesh.TRANSFORM_3D
	var quad:=QuadMesh.new()
	quad.size=Vector2(2,2)
	points.mesh=quad
	points.instance_count=18
	motes=MultiMeshInstance3D.new()
	motes.multimesh=points
	var glint:=ShaderMaterial.new()
	glint.shader=preload("res://shaders/collection_glint.gdshader")
	motes.material_override=glint
	motes.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inlay.add_child(motes)
