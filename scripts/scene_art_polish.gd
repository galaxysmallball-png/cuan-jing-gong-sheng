extends "res://scripts/environment_art.gd"

# Pure visual assemblies. Gameplay colliders, inscription meshes and all 21
# click targets are owned by their original systems, never replaced here.
var world: Node3D
var batches: Array[MeshInstance3D] = []
var glows: Array[MeshInstance3D] = []
var source_parts: int = 0
var ash: Material
var timber: Material
var aged_gold: Material
var green: Material
var pale_green: Material
var roots: Array[Node3D] = []


func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="SceneArtPolish"
	rng.seed=2026101917
	ash=_surface(Color(.31,.34,.31),0)
	timber=_surface(Color(.235,.115,.062),2)
	aged_gold=_flat(Color(.47,.31,.13))
	green=_flat(Color(.14,.24,.135))
	pale_green=_flat(Color(.23,.30,.15))
	for material in [green,pale_green]: material.cull_mode=BaseMaterial3D.CULL_DISABLED
	for index in range(3):
		var stage:=Node3D.new()
		stage.name=["WeatheredSteleGallery","MoonlitCanyonBanks","CarvedSharedCourt"][index]
		stage.position.x=index*20
		add_child(stage)
		roots.append(stage)
	_court(roots[0])
	_canyon(roots[1])
	_shared(roots[2])
	_merge_details()


func _bracket(parent: Node3D, x: float, y: float, z: float, scale_factor: float=1.0) -> void:
	# Stacked bearing blocks and splayed arms visibly join column to eave.
	for tier in range(3):
		var width: float=(.30+tier*.23)*scale_factor
		_box(parent,Vector3(x,y+tier*.11*scale_factor,z),Vector3(width,.085*scale_factor,.31*scale_factor),timber)
		if tier<2:
			for side in [-1,1]:
				var end:=Vector3(x+side*width*.43,y+(tier+1)*.11*scale_factor,z+.035)
				_rod(parent,Vector3(x+side*width*.20,y+tier*.11*scale_factor,z),end,.033*scale_factor,timber)
	for side in [-1,1]:
		_box(parent,Vector3(x+side*.23*scale_factor,y+.18*scale_factor,z+.17*scale_factor),Vector3(.07,.07,.035)*scale_factor,aged_gold)


func _lattice(parent: Node3D, center: Vector3, width: float, height: float) -> void:
	var dark: Material=_flat(Color(.065,.095,.087))
	_box(parent,center-Vector3(0,0,.045),Vector3(width,height,.06),dark)
	for side in [-1,1]:
		_box(parent,center+Vector3(side*width*.5,0,.015),Vector3(.055,height+.10,.07),timber)
		_box(parent,center+Vector3(0,side*height*.5,.015),Vector3(width+.1,.06,.07),timber)
	var count: int=int(width/.22)
	for col in range(count+1):
		var x: float=-width*.5+float(col)*width/count
		_rod(parent,center+Vector3(x,-height*.5,.055),center+Vector3(x,height*.5,.055),.011,aged_gold)
	for row in range(1,4):
		var y: float=-height*.5+height*row/4.0
		_rod(parent,center+Vector3(-width*.5,y,.055),center+Vector3(width*.5,y,.055),.012,timber)
	for col in range(count):
		var x: float=-width*.5+(col+.5)*width/count
		var c: Vector3=center+Vector3(x,0,.075)
		var corners: Array[Vector3]=[c+Vector3(0,.17,0),c+Vector3(.09,0,0),c+Vector3(0,-.17,0),c-Vector3(.09,0,0)]
		for side in range(4): _rod(parent,corners[side],corners[(side+1)%4],.009,aged_gold)


func _blade(parent: Node3D, root_at: Vector3, tip: Vector3, width: float, mat: Material) -> void:
	var direction: Vector3=(tip-root_at).normalized()
	var across: Vector3=direction.cross(Vector3(0,0,1)).normalized()*width
	if across.length()<.001: across=Vector3(width,0,0)
	var center: Vector3=root_at.lerp(tip,.40)+Vector3(0,0,.025)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex: Vector3 in [root_at,center-across,tip,root_at,tip,center+across]:
		st.set_uv(Vector2(vertex.x,vertex.y))
		st.add_vertex(vertex)
	st.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.mesh=st.commit()
	mesh.material_override=mat
	parent.add_child(mesh)


func _fern(parent: Node3D, at: Vector3, height: float) -> void:
	for frond in range(5):
		var angle: float=frond*TAU/5
		var end: Vector3=at+Vector3(cos(angle)*height*.54,height*.65,sin(angle)*height*.28)
		_rod(parent,at,end,.006,green)
		for index in range(1,7):
			var t: float=index/7.0
			var p: Vector3=at.lerp(end,t)
			var span: float=sin(t*PI)*height*.19
			for side in [-1,1]:
				_blade(parent,p,p+Vector3(side*span,height*.09,.01),span*.22,green if index%2 else pale_green)


func _ivy(parent: Node3D, start: Vector3, length: float) -> void:
	var previous: Vector3=start
	for step in range(13):
		var t: float=(step+1)/13.0
		var p: Vector3=start+Vector3(sin(t*5.0)*.10,-length*t,.035*sin(t*3.0))
		_rod(parent,previous,p,.006,timber)
		var side: int=1 if step%2 else -1
		_blade(parent,p,p+Vector3(side*.15,-.07,.025),.057,green if step%3 else pale_green)
		previous=p


func _glow(parent: Node3D, at: Vector3, size: Vector2, strength: float) -> void:
	var glow:=MeshInstance3D.new()
	var quad:=QuadMesh.new()
	quad.size=size
	glow.mesh=quad
	glow.position=at
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/lantern_aureole.gdshader")
	material.set_shader_parameter("strength",strength)
	material.set_shader_parameter("phase",glows.size()*1.7)
	glow.material_override=material
	glow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.set_meta("soft_light",true)
	glow.set_meta("peak_strength",strength)
	parent.add_child(glow)
	glows.append(glow)


func _court(parent: Node3D) -> void:
	# Eave joints stop at the three existing pillars, outside the inscription faces.
	for x in [10.6,13.55,16.5]: _bracket(parent,x,3.43,-2.69,.85)
	for x in [10.6,16.5]:
		for side in [-1,1]:
			_rod(parent,Vector3(x,2.96,-2.79),Vector3(x+side*.43,3.55,-2.79),.035,timber)
	# Bare plaster exposes irregular courses of old masonry around the moon gate.
	for row in range(4):
		for col in range(5):
			var x: float=.55+col*.52+(row%2)*.22
			var block: MeshInstance3D=_rock(parent,Vector3(x,.16+row*.23,-2.83),Vector3(.47,.21,.15),ash)
			block.rotation.z=rng.randf_range(-.035,.035)
	for x in [1.15,3.1,8.1]: _bracket(parent,x,3.30,-1.71,.70)
	for start in [Vector3(7.6,1.4,-2.76),Vector3(8.25,2.10,-2.73),Vector3(10.65,3.35,-2.61),Vector3(16.40,3.58,-2.60)]:
		_ivy(parent,start,rng.randf_range(.55,1.10))
	for at in [Vector3(7.9,.06,-2.2),Vector3(9.05,.04,2.2),Vector3(17.1,.05,-2.4)]: _fern(parent,at,.62)
	var tile: Material=_flat(Color(.15,.20,.21))
	for i in range(18):
		var piece: MeshInstance3D=_box(parent,Vector3(7.6+rng.randf_range(-.65,.65),.055,-2.2+rng.randf_range(-.25,.25)),Vector3(.15,.035,.21),tile)
		piece.rotation=Vector3(rng.randf_range(-.25,.25),rng.randf()*TAU,rng.randf_range(-.18,.18))
	# Pale mineral run-off and leaves collect on the edges, never under the targets.
	_leaf_litter(parent,2.6,18.1,2.32,74)
	for at in [Vector3(2.7,2.3,-1.0),Vector3(8.4,2.45,-1.35),Vector3(10.8,3.05,-1.57),Vector3(16.5,3.05,-1.57)]:
		_glow(parent,at,Vector2(1.25,1.65),.16)


func _canyon(parent: Node3D) -> void:
	var cliff: Material=_surface(Color(.18,.245,.27),0)
	# Actual ledges flank the river behind the bridge; the middle stays open to
	# mist and moonlight, and every new rock is below or behind the deck.
	for side in [-1,1]:
		var x: float=15+side*3.65
		for row in range(5):
			for col in range(3):
				_rock(parent,Vector3(x+side*col*.29,-.65-row*.56,-3.7+col*.14),Vector3(.85+row*.06,.62,.85),cliff)
		for i in range(3): _ivy(parent,Vector3(x+side*i*.24,-.05,-3.06),.70+i*.22)
		_fern(parent,Vector3(x+side*.44,.04,-2.6),.78)
	for at in [Vector3(4.2,.04,-2.4),Vector3(9.8,.03,2.35),Vector3(19.2,.03,-2.1)]: _fern(parent,at,.70)
	# Old stone revetment: short joints, broken cap and dark waterline footings.
	for x in [11.45,18.55]:
		for row in range(5):
			for col in range(3):
				_box(parent,Vector3(x+(col-1)*.28,-.22-row*.36,-1.7),Vector3(.26,.32,.36),ash)
		_rock(parent,Vector3(x,-.05,-1.7),Vector3(1.02,.21,.60),ash)
	_leaf_litter(parent,1.5,10.5,2.25,38)
	for at in [Vector3(10.8,1.86,-1.25),Vector3(18.7,1.86,-1.25)]:
		_glow(parent,at,Vector2(1.35,1.65),.15)
	var mist:=ShaderMaterial.new()
	mist.shader=preload("res://shaders/mist_ribbon.gdshader")
	mist.set_shader_parameter("strength",.17)
	var spray:=MeshInstance3D.new()
	var mesh:=QuadMesh.new()
	mesh.size=Vector2(5.9,.82)
	spray.mesh=mesh
	spray.position=Vector3(15,-2.72,1.8)
	spray.material_override=mist
	spray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spray.set_meta("soft_light",true)
	parent.add_child(spray)


func _shared(parent: Node3D) -> void:
	# Small woodwork belongs to a specific structural bay; no full-width festoon.
	for x in [4.4,15.6]: _bracket(parent,x,5.64,-5.65,1.05)
	for x in [7.1,12.9]: _bracket(parent,x,3.51,-1.50,.82)
	for x in [4.6,15.2,19.3]: _bracket(parent,x,2.87,-2.15,.70)
	for center in [Vector3(5.35,4.75,-6.02),Vector3(14.65,4.75,-6.02)]:
		_lattice(parent,center,1.75,1.55)
	# The high hall gains a narrow timber frieze and restrained geometric inlay.
	for interval in [Vector2(4.55,7.55),Vector2(12.45,15.45)]:
		_box(parent,Vector3((interval.x+interval.y)*.5,5.68,-5.69),Vector3(interval.y-interval.x,.10,.18),timber)
		for i in range(9):
			var x: float=lerpf(interval.x,interval.y,(i+.5)/9.0)
			for side in [-1,1]:
				_rod(parent,Vector3(x-side*.09,5.57,-5.56),Vector3(x,5.48,-5.56),.014,aged_gold)
	# Recessed side doors and plinth courses create depth behind existing props.
	for x in [3.4,16.5]:
		_lattice(parent,Vector3(x,1.92,-3.82),1.10,1.45)
		for side in [-1,1]:
			_box(parent,Vector3(x+side*.63,1.22,-3.75),Vector3(.10,2.44,.18),timber)
		_box(parent,Vector3(x,.18,-3.64),Vector3(1.46,.15,.48),ash)
	for at in [Vector3(.55,.04,2.55),Vector3(13.7,.04,2.58),Vector3(19.5,.04,-2.65)]: _fern(parent,at,.52)
	for i in range(32):
		var x: float=.3+i*.62
		_box(parent,Vector3(x,-.10,3.24),Vector3(.49,.045,.035),ash)
	_leaf_litter(parent,.7,19.7,2.68,44)
	for at in [Vector3(5.25,3.15,-1.63),Vector3(7.32,3.56,-.83),Vector3(12.68,3.56,-.83),Vector3(15.45,3.22,-1.53),Vector3(18.7,3.22,-1.53),Vector3(10,1.3,-1.72)]:
		_glow(parent,at,Vector2(1.35,1.72),.19)


func _leaf_litter(parent: Node3D, xmin: float, xmax: float, z: float, count: int) -> void:
	var leaf: Material=_flat(Color(.30,.22,.105))
	for index in range(count):
		var x: float=rng.randf_range(xmin,xmax)
		var start:=Vector3(x,.038,z+rng.randf_range(-.16,.16))
		var length: float=rng.randf_range(.045,.13)
		var node: MeshInstance3D=_rock(parent,start,Vector3(length,.014,length*.44),leaf)
		node.rotation.y=rng.randf()*TAU


func _merge_details() -> void:
	var groups: Dictionary={}
	for node: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		if node.get_meta("soft_light",false): continue
		var material: Material=node.material_override
		if not groups.has(material): groups[material]=[]
		groups[material].append(node)
	for material: Material in groups:
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var parts: int=groups[material].size()
		for node: MeshInstance3D in groups[material]:
			st.append_from(node.mesh,0,global_transform.affine_inverse()*node.global_transform)
			node.get_parent().remove_child(node)
			node.free()
		var merged:=MeshInstance3D.new()
		merged.mesh=st.commit()
		merged.material_override=material
		merged.name="MergedSceneDetail%d"%batches.size()
		merged.set_meta("merged_parts",parts)
		add_child(merged)
		batches.append(merged)
		source_parts+=parts


func _process(_delta: float) -> void:
	if world==null: return
	var warmth: float=world.courtyard.lamp_count/7.0
	for index in range(6,glows.size()):
		var material: ShaderMaterial=glows[index].material_override
		material.set_shader_parameter("strength",float(glows[index].get_meta("peak_strength"))*(.62+.38*warmth))
