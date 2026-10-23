extends RefCounted

static func pottery(tint: Color) -> ShaderMaterial:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://shaders/handmade_pottery.gdshader")
	mat.set_shader_parameter("tint",tint)
	return mat

static func lathe(parent: Node3D, at: Vector3, profile: PackedVector2Array, material: Material, segments: int=48) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size()-1):
		for segment in range(segments):
			for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				var index: int=row+corner.y
				var uv:=Vector2((segment+corner.x)/float(segments),index/float(profile.size()-1))
				var a: float=uv.x*TAU
				var shape: Vector2=profile[index]
				var tangent: Vector2=profile[mini(index+1,profile.size()-1)]-profile[maxi(index-1,0)]
				st.set_normal(Vector3(cos(a)*tangent.y,-tangent.x,sin(a)*tangent.y).normalized())
				st.set_uv(uv)
				st.add_vertex(Vector3(cos(a)*shape.x,shape.y,sin(a)*shape.x))
	var node:=MeshInstance3D.new()
	node.mesh=st.commit()
	node.material_override=material
	node.position=at
	parent.add_child(node)
	return node

static func ring(parent: Node3D, at: Vector3, radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var mesh:=TorusMesh.new()
	mesh.inner_radius=radius-thickness
	mesh.outer_radius=radius+thickness
	mesh.rings=40
	mesh.ring_segments=8
	node.mesh=mesh
	node.position=at
	node.material_override=material
	parent.add_child(node)
	return node

static func tea(parent: Node3D) -> void:
	var clay: Material=pottery(Color(.20,.19,.17))
	var glaze: Material=pottery(Color(.27,.31,.25))
	var tea_color:=StandardMaterial3D.new()
	tea_color.albedo_color=Color(.36,.22,.08)
	tea_color.roughness=.27
	lathe(parent,Vector3(-.42,.065,0),PackedVector2Array([Vector2(.0,0),Vector2(.17,0),Vector2(.21,.025),Vector2(.23,.07),Vector2(.27,.17),Vector2(.28,.35),Vector2(.25,.47),Vector2(.19,.55),Vector2(.17,.56),Vector2(.17,.60),Vector2(.14,.60),Vector2(.14,.53)]),clay).name="ThrownBlackTeaJar"
	var burnished: Material=pottery(Color(.25,.23,.20))
	for i in range(2): ring(parent,Vector3(-.42,.325+i*.03,0),.275+i*.0016,.002,burnished)
	ring(parent,Vector3(-.42,.665,0),.158,.015,clay)
	lathe(parent,Vector3(-.42,.674,0),PackedVector2Array([Vector2(.0,.024),Vector2(.055,.023),Vector2(.10,.012),Vector2(.15,0)]),clay)
	lathe(parent,Vector3(-.42,.697,0),PackedVector2Array([Vector2(.035,0),Vector2(.04,.035),Vector2(.025,.052),Vector2(0,.052)]),clay)
	for side in [-1,1]:
		var ear: MeshInstance3D=ring(parent,Vector3(-.42+side*.245,.47,0),.058,.014,clay)
		ear.rotation.x=PI/2
	for index in range(3):
		var at:=Vector3(.02+index*.28,.085,.25)
		lathe(parent,at,PackedVector2Array([Vector2(0,0),Vector2(.055,0),Vector2(.061,.016),Vector2(.064,.036),Vector2(.087,.07),Vector2(.108,.14),Vector2(.107,.15),Vector2(.093,.15),Vector2(.078,.09),Vector2(.047,.039),Vector2(0,.039)]),glaze).name="GlazedOpenTeaBowl"
		ring(parent,at+Vector3(0,.15,0),.101,.006,glaze)
		lathe(parent,at+Vector3(0,.082,0),PackedVector2Array([Vector2(0,0),Vector2(.073,0)]),tea_color)
	parent.add_to_group("artisan_tea_service")

static func bell(parent: Node3D, material: Material) -> void:
	lathe(parent,Vector3.ZERO,PackedVector2Array([Vector2(.18,-.12),Vector2(.185,-.105),Vector2(.17,-.08),Vector2(.135,-.02),Vector2(.115,.055),Vector2(.075,.105),Vector2(.018,.12),Vector2(0,.12),Vector2(0,.093),Vector2(.06,.078),Vector2(.09,.04),Vector2(.115,-.025),Vector2(.15,-.11),Vector2(.18,-.12)]),material).name="HollowHorseBell"
	ring(parent,Vector3(0,-.10,0),.175,.008,material)
	for height in [-.04,.015]: ring(parent,Vector3(0,height,0),.145-height*.4,.003,material)
	var eye: MeshInstance3D=ring(parent,Vector3(0,.15,0),.034,.009,material)
	eye.rotation.x=PI/2
	lathe(parent,Vector3(0,-.07,0),PackedVector2Array([Vector2(.021,-.05),Vector2(.031,-.038),Vector2(.018,-.015),Vector2(.009,0),Vector2(.009,.15)]),material,24)
	parent.add_to_group("hollow_horse_bell_detail")
