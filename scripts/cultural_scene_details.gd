extends "res://scripts/environment_art.gd"

var props: Array[Dictionary] = []
var route_surface: Node3D
var world: Node3D
var timber: Material
var bronze: Material
var fiber: Material
var indigo: Material
var dark: Material
var dispersed_items: Dictionary={}


func setup(owner_world: Node3D) -> void:
	world = owner_world
	name = "CraftAndTrailDetails"
	rng.seed = 181818
	timber = _surface(Color(.35, .20, .09), 2)
	bronze = _flat(Color(.65, .43, .16))
	fiber = _flat(Color(.59, .43, .22))
	indigo = _flat(Color(.07, .12, .19))
	dark = _flat(Color(.10, .095, .08))
	var dye: Node3D = _prop(0, "bai_tiedye", "蓝白扎染布架", Vector3(5.9, 0, -1.6), "蓝白花纹的扎染布在架上晾着。先扎花、再染色，拆线处留下浅色纹样。此处为参考白族扎染的美术表现。", "cloth")
	_rack(dye, 2.0, 2.1, 0)
	_basket(dye, Vector3(-.82, .3, .35), .32)
	var trade: Node3D = _prop(0, "yang_trade_goods", "货郎竹筐与小秤", Vector3(2.5, 0, -1.5), "杨三娘的针线筐、小秤和布卷。山路上的货担，既送货，也捎话；小秤用来称零货。", "wood")
	_basket(trade, Vector3(-.45, .36, 0), .43)
	_basket(trade, Vector3(.48, .30, .12), .34)
	for index in range(5): _roll(trade, Vector3(-.68 + index * .14, .82 + (index % 2) * .08, 0), index % 3)
	_balance(trade, Vector3(.38, .9, 0))
	var books: Node3D = _prop(0, "scholar_tools", "竹筒书卷与拓包", Vector3(10.15, 0, -1.5), "竹筒收着纸卷，布包裹着拓印用具。邓书年随身带纸笔，遇到不识之字，也须请教同行。", "paper")
	var scholar_art := preload("res://scripts/scholar_travel_tools.gd").new()
	books.add_child(scholar_art)
	scholar_art.build(books)
	var pack: Node3D = _prop(1, "caravan_pack", "马帮木驮架与披毡", Vector3(.95, 0, -1.3), "老箐歇脚时放下的木驮架、披毡与马铃。驮架分担货重，绳结捆紧，过溪前更须逐一察看。", "bell")
	_pack(pack)
	_route_wall()
	var batik: Node3D = _prop(1, "miao_batik", "阿彩的蓝白花布与竹筐", Vector3(8.85, 0, -1.55), "阿彩带来的花布与竹筐。蓝白旋纹参照她的服饰和背婴布；这些日用物随众人一道走上古道。", "cloth")
	_rack(batik, 1.45, 1.7, 1)
	_basket(batik, Vector3(.7, .24, .35), .28)
	var brocade: Node3D = _prop(2, "dai_brocade", "玉喃的织锦布架", Vector3(1.3, 0, -1.55), "玉喃带来的织锦布卷在此铺开。花纹里有几何图形和孔雀意象，讲述布商与往来行人的相遇。", "cloth")
	_rack(brocade, 1.65, 2.1, 2)
	_peacock(brocade, Vector3(0, 1.3, .045))
	for index in range(4): _roll(brocade, Vector3(-.48 + index * .3, .24, .4), index % 3)
	var tea: Node3D = _prop(2, "shared_tea", "围火茶席与黑陶罐", Vector3(14.2, 0, -1.3), "黑陶罐、茶碗与火塘留在同一张席上。普嫫温着茶，诸位护碑归来，在此交换一路见闻。", "water")
	_tea(tea)
	var loom: Node3D = _prop(2, "cloth_loom", "锦布织架与线团", Vector3(17.0, 0, -1.7), "经线、梭子和布卷都能在架上看见。各地布样随行旅往来，不同手艺也在交流中相识。此为美术化织架。", "cloth")
	_loom(loom)
	_disperse_court_items()
	# Place a gentle fill close to the new objects so their patterns survive night scenes.
	for x in [5.7, 27.0, 42.0, 55.5]:
		var fill := OmniLight3D.new()
		fill.position = Vector3(x, 2.8, 1)
		fill.light_color = Color(.89, .75, .54)
		fill.light_energy = .55
		fill.omni_range = 4.5
		add_child(fill)


func _disperse_court_items() -> void:
	var source: Node3D=world.courtyard.get_node("Residents/ResidentA/Character")
	var extractor=preload("res://scripts/skinned_prop_mesh.gd")
	# Each object keeps its collection identity, reference photo and small craft,
	# but receives a separate visible setting instead of a tiny overlap on a person.
	for spec in [
		["fire_basin","firepan","三足铜火盆",Vector3(46.1,0,-.55),.48,.12],
		["tea_jar","teapot","黑陶茶罐",Vector3(53.5,0,-.40),.52,.64],
		["flint_pouch","pouch","火石小布袋",Vector3(57.65,0,.20),.38,.64],
	]:
		var anchor:=Node3D.new()
		anchor.name=spec[0]
		anchor.position=spec[3]
		anchor.set_meta("standalone_artifact",true)
		add_child(anchor)
		var object: Node3D
		if spec[0]=="flint_pouch":
			object=preload("res://scripts/flint_pouch_detail.gd").new()
			anchor.add_child(object)
			object.build()
		else:
			object=extractor.extract(source,[spec[1]])
			anchor.add_child(object)
		object.name="Object"
		var bounds:=AABB()
		var first: bool=true
		for part: MeshInstance3D in object.get_children():
			var local: AABB=part.transform*part.mesh.get_aabb()
			bounds=local if first else bounds.merge(local)
			first=false
		var shift:=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
		for part: Node3D in object.get_children(): part.position-=shift
		object.scale=Vector3.ONE*float(spec[4])/maxf(.01,bounds.size.y)
		object.position.y=spec[5]
		if spec[0]=="fire_basin":
			_rock(anchor,Vector3(0,.06,0),Vector3(.91,.12,.68),preload("res://scripts/natural_outcrop.gd").stone(Color(.33,.34,.28),.1))
			var glow:=OmniLight3D.new()
			glow.position=Vector3(0,.55,.15)
			glow.light_color=Color(1,.45,.16)
			glow.light_energy=.60
			glow.omni_range=2.2
			anchor.add_child(glow)
		else:
			_box(anchor,Vector3(0,.58,0),Vector3(.74,.10,.55),timber)
			for x in [-.27,.27]:
				for z in [-.17,.17]: _rod(anchor,Vector3(x,.03,z),Vector3(x,.54,z),.033,timber)
			for z in [-.17,.17]: _rod(anchor,Vector3(-.27,.20,z),Vector3(.27,.20,z),.018,timber)
		dispersed_items[spec[0]]=anchor
	# Omit only the three carried props from the runtime mesh; the original GLB
	# and the person's body/clothes remain intact on disk.
	extractor.omit(source,["teapot","firepan","pouch"])


func _prop(chapter: int, id: String, title: String, local_at: Vector3, description: String, sound: String) -> Node3D:
	var root := Node3D.new()
	root.name = id
	root.position = local_at + Vector3(chapter * 20, 0, 0)
	add_child(root)
	props.append({"id": id, "title": title, "anchor": root, "offset": Vector3(0, 2.3, .2), "chapter": chapter, "description": description, "sound": sound})
	return root


func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * .88
	mesh.height = height
	mesh.radial_segments = 16
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node


func _ring(parent: Node3D, at: Vector3, radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 24
	mesh.ring_segments = 5
	node.mesh = mesh
	node.position = at
	node.material_override = material
	parent.add_child(node)
	return node


func _cloth(parent: Node3D, at: Vector3, size: Vector2, motif: int) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.orientation = PlaneMesh.FACE_Z
	mesh.subdivide_width = 18
	mesh.subdivide_depth = 12
	node.mesh = mesh
	node.position = at
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/trade_textile.gdshader")
	material.set_shader_parameter("motif", motif)
	node.material_override = material
	parent.add_child(node)
	for index in range(12):
		var x: float = at.x - size.x * .47 + index * size.x * .086
		_rod(parent, Vector3(x, at.y - size.y * .50, at.z), Vector3(x, at.y - size.y * .50 - .10, at.z), .008, fiber)
	return node


func _rack(parent: Node3D, width: float, height: float, motif: int) -> void:
	for side in [-1, 1]:
		_rod(parent, Vector3(side * width * .55, 0, 0), Vector3(side * width * .55, height, 0), .045, timber)
		_rod(parent, Vector3(side * width * .55, .03, -.26), Vector3(side * width * .55, .03, .35), .05, timber)
	_rod(parent, Vector3(-width * .65, height, 0), Vector3(width * .65, height, 0), .048, timber)
	_cloth(parent, Vector3(0, height * .65, .015), Vector2(width, height * .68), motif)


func _basket(parent: Node3D, at: Vector3, radius: float) -> void:
	_cylinder(parent, at, radius, radius * 1.45, _flat(Color(.28, .19, .10)))
	for row in range(7): _ring(parent, at + Vector3(0, -.7 * radius + row * radius * .23, 0), radius * (.88 + row * .016), .014, fiber)
	for index in range(16):
		var angle: float = TAU * index / 16
		var radial := Vector3(cos(angle), 0, sin(angle))
		_rod(parent, at + radial * radius * .85 - Vector3(0, radius * .7, 0), at + radial * radius + Vector3(0, radius * .7, 0), .012, fiber)
	var handle: MeshInstance3D = _ring(parent, at + Vector3(0, radius * .75, 0), radius * .72, .019, fiber)
	handle.rotation.x = PI / 2


func _roll(parent: Node3D, at: Vector3, motif: int) -> void:
	var material: Material = _flat(Color(.81, .75, .56)) if motif < 0 else _flat([Color(.12, .23, .34), Color(.55, .19, .11), Color(.69, .46, .18)][motif])
	var roll: MeshInstance3D = _cylinder(parent, at, .115, .59, material)
	roll.rotation.x = PI / 2
	for radius in [.035, .068, .10]:
		var seam: MeshInstance3D = _ring(parent, at + Vector3(0, 0, .30), radius, .007, fiber)
		seam.rotation.x = PI / 2


func _balance(parent: Node3D, at: Vector3) -> void:
	_rod(parent, at, at + Vector3(0, .65, 0), .022, timber)
	_rod(parent, at + Vector3(-.4, .48, 0), at + Vector3(.4, .48, 0), .02, timber)
	for side in [-1, 1]:
		var center: Vector3 = at + Vector3(side * .34, .1, 0)
		_cylinder(parent, center, .15, .025, bronze)
		for z in [-.10, .10]: _rod(parent, center + Vector3(0, 0, z), at + Vector3(side * .34, .48, 0), .005, fiber)


func _pack(parent: Node3D) -> void:
	for x in [-.44, .44]:
		_rod(parent, Vector3(x, 0, .15), Vector3(x, 1.7, -.12), .055, timber)
	for y in [.25, .75, 1.35]: _rod(parent, Vector3(-.5, y, 0), Vector3(.5, y, 0), .06, timber)
	_box(parent, Vector3(0, .8, .2), Vector3(.82, .9, .45), dark)
	_cloth(parent, Vector3(0, 1, .44), Vector2(.95, 1.08), 3)
	for x in [-.3, .3]: _rod(parent, Vector3(x, .25, .49), Vector3(x, 1.45, .49), .023, fiber)
	for x in [-.55, .55]:
		var bell: MeshInstance3D = _cylinder(parent, Vector3(x, 1.05, .4), .11, .20, bronze)
		bell.rotation.z = .15 * signf(x)
		_ring(parent, Vector3(x, 1.18, .4), .06, .012, bronze).rotation.x = PI / 2


func _peacock(parent: Node3D, at: Vector3) -> void:
	var gold: Material = _flat(Color(.88, .61, .22), true)
	for index in range(7):
		var angle: float = -.95 + index * .317
		var end: Vector3 = at + Vector3(sin(angle) * .50, cos(angle) * .45, .008)
		_rod(parent, at - Vector3(0, .2, 0), end, .012, gold)
		var eye: MeshInstance3D = _ring(parent, end, .06, .015, gold)
		eye.rotation.x = PI / 2
	_rod(parent, at - Vector3(0, .20, 0), at + Vector3(.035, .18, .025), .04, gold)
	_rod(parent, at + Vector3(.035, .18, .025), at + Vector3(.15, .22, .025), .035, gold)


func _tea(parent: Node3D) -> void:
	var mat: MeshInstance3D = _box(parent, Vector3(0, .04, 0), Vector3(1.8, .04, .85), fiber)
	mat.rotation.y = .06
	preload("res://scripts/artisan_prop_detail.gd").tea(parent)
	for x in [-.25, .1, .42]: _rock(parent, Vector3(x, .12, -.36), Vector3(.3, .19, .18), dark)
	for index in range(4): _rod(parent, Vector3(-.1, .16, -.27), Vector3(.23, .16, -.5 + index * .06), .04, timber)
	_cylinder(parent, Vector3(.08, .21, -.36), .14, .03, _flat(Color(.86, .23, .04), true, true))


func _loom(parent: Node3D) -> void:
	for x in [-.63, .63]: _rod(parent, Vector3(x, 0, .25), Vector3(x, 1.8, -.25), .05, timber)
	for y in [.48, 1.7]: _rod(parent, Vector3(-.7, y, 0), Vector3(.7, y, 0), .065, timber)
	for index in range(20):
		var x: float = -.5 + index * .052
		_rod(parent, Vector3(x, .48, .05), Vector3(x, 1.7, .05), .006, fiber)
	_cloth(parent, Vector3(0, .82, .07), Vector2(1.0, .65), 2)
	var shuttle: MeshInstance3D = _box(parent, Vector3(.18, 1.32, .14), Vector3(.47, .06, .075), timber)
	shuttle.rotation.z = .17
	_basket(parent, Vector3(-.83, .22, .25), .24)


func _route_wall() -> void:
	# This fictional route marker is an actual, visible groove study, not a historical inscription.
	route_surface = Node3D.new()
	route_surface.name = "ReadableRouteWall"
	route_surface.position = Vector3(27, 0, -2.65)
	add_child(route_surface)
	var rock_art=preload("res://scripts/natural_outcrop.gd")
	var slab: Material=rock_art.stone(Color(.43,.45,.38),.18)
	var face: MeshInstance3D=preload("res://scripts/route_outcrop.gd").build(route_surface)
	face.name="WeatheredRouteOutcrop"
	var engraving:=ShaderMaterial.new()
	engraving.shader=preload("res://shaders/route_groove.gdshader")
	face.material_override=engraving
	face.set_meta("recessed_route",true)
	for index in range(9):
		var chip: MeshInstance3D=_rock(route_surface,Vector3(-1.40+index*.34,.08+(index%3)*.025,.15+sin(index*2.1)*.12),Vector3(.29+index%3*.08,.16+index%2*.09,.31),slab)
		chip.rotation.y=index*.57
	for side in [-1,1]:
		var outline:=PackedVector2Array([Vector2(-.45,.02),Vector2(.37,.04),Vector2(.48,.40),Vector2(.29,.91),Vector2(-.12,1.03),Vector2(-.42,.68)])
		rock_art.make(route_surface,Vector3(side*1.24,0,-.18),outline,.72,slab).name="FracturedShoulder"
	var groove: Material = _flat(Color(.065, .085, .07))
	# Paired worn ruts and patched paving tie the carving to the walked ancient route.
	for x in range(23, 31):
		for z in [.55, -.55]: _box(self, Vector3(x, .012, z), Vector3(.62, .008, .055), groove)
