extends "res://scripts/environment_art.gd"

var world: Node3D
var lanterns: Array[Node3D] = []
var glows: Array[StandardMaterial3D] = []
var guests: Array[Node3D] = []
var lights: Array[OmniLight3D] = []
var sparks: MultiMeshInstance3D
var clock: float = 0
var grand: Node3D
var lantern_bays: Array[Node3D] = []


func setup(owner_world: Node3D) -> void:
	world = owner_world
	name = "FestivalCourt"
	var wood: Material = _surface(Color(.30, .14, .06), 2)
	var gold: Material = _flat(Color(.70, .48, .16))
	var rope: Material = _flat(Color(.45, .33, .16))
	# Separate short strings follow actual porch beams and gallery fascias.
	# The central inscription, roof valleys and cloth banners remain open.
	_eave_string("LeftGallery",Vector3(44.6,3.16,-2.12),Vector3(46.7,3.16,-2.12),3,0,gold,rope)
	_eave_string("ShrineLeft",Vector3(47.1,3.85,-1.56),Vector3(47.95,3.85,-1.56),2,1,gold,rope)
	_eave_string("ShrineRight",Vector3(52.05,3.85,-1.56),Vector3(52.9,3.85,-1.56),2,1,gold,rope)
	_eave_string("RightGalleryInner",Vector3(55.2,3.23,-1.82),Vector3(56.7,3.23,-1.82),3,0,gold,rope)
	_eave_string("RightGalleryOuter",Vector3(57.6,3.23,-1.82),Vector3(59.3,3.23,-1.82),3,2,gold,rope)
	for side in [0, 1]:
		var x: float = 43.5 if side == 0 else 56.6
		for part in range(3):
			var at := Vector3(x + (part - 1) * .54, 3.2 - (part % 2) * .16, -3.48)
			world.scene_details._cloth(self, at, Vector2(.48, 1.42), (part + side) % 3)
		_rod(self, Vector3(x - .9, 4.0, -3.48), Vector3(x + .9, 4.0, -3.48), .04, gold)
	# A canopy in interlacing warm and cool cloth colors joins the pavilion to both galleries.
	for index in range(7):
		var at := Vector3(46.4 + index * 1.18, 4.53 + sin(index * PI / 6) * .25, -3.10)
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = .17
		mesh.outer_radius = .205
		mesh.rings = 24
		mesh.ring_segments = 6
		ring.mesh = mesh
		ring.position = at
		ring.rotation.x = PI / 2
		ring.material_override = gold
		add_child(ring)
		for angle_id in range(6):
			var angle: float = TAU * angle_id / 6
			_rod(self, at, at + Vector3(cos(angle), sin(angle), 0) * .15, .012, gold)
	for index in range(40):
		var a: float = TAU * index / 40
		var b: float = TAU * (index + 1) / 40
		for radius in [1.25, 1.48]:
			_rod(self, Vector3(50 + cos(a) * radius, .025, 1.0 + sin(a) * radius * .48), Vector3(50 + cos(b) * radius, .025, 1.0 + sin(b) * radius * .48), .012, gold)
	for x in [41.0,44.2,55.9,59.0]: _flowers(Vector3(x,0,-.35),wood,gold)
	for x in [44.8, 50.2, 55.8]:
		var glow := OmniLight3D.new()
		glow.position = Vector3(x, 3.4, .5)
		glow.light_color = Color(1, .67, .32)
		glow.omni_range = 5.7
		glow.light_energy = .6
		add_child(glow)
		lights.append(glow)
	var people: Array[PackedScene] = [preload("res://scenes/villagers/a_cai_villager.tscn"), preload("res://scenes/villagers/a_qiang_villager.tscn")]
	for index in range(2):
		var guest: Node3D = people[index].instantiate()
		guest.position = Vector3(45.0 + index * 10.5, 0, .85)
		add_child(guest)
		guest.visible = false
		guests.append(guest)
		var note: Label3D = guest.get_node("NameLabel")
		note.text = ["阿彩（苗族）", "阿强（壮族）"][index]
		note.position = Vector3(0, 2.2, 0)
		note.font_size = preload("res://scripts/interface_skin.gd").text_size(26)
		note.pixel_size = .006
		note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		note.modulate = Color(.98, .80, .47)
	_build_sparks()
	grand = preload("res://scripts/grand_court.gd").new()
	add_child(grand)
	grand.setup(world)


func _eave_string(id: String, start: Vector3, end: Vector3, count: int, palette: int, gold: Material, rope: Material) -> void:
	var bay := Node3D.new()
	bay.name="EaveLanternBay"+id
	bay.set_meta("beam_start",start)
	bay.set_meta("beam_end",end)
	bay.set_meta("lantern_count",count)
	bay.add_to_group("eave_lantern_bays")
	add_child(bay)
	lantern_bays.append(bay)
	var previous: Vector3 = start
	for segment in range(1,13):
		var t: float = segment/12.0
		var at: Vector3 = start.lerp(end,t)-Vector3(0,sin(t*PI)*.07,0)
		_rod(bay,previous,at,.009,rope)
		previous=at
	for anchor in [start,end]:
		_rod(bay,anchor+Vector3(0,.09,-.04),anchor,.016,gold)
	for index in range(count):
		var t: float = (index+.5)/count
		var at: Vector3 = start.lerp(end,t)-Vector3(0,.34+sin(t*PI)*.07,0)
		_lantern(at,(palette+index)%3,gold,bay)


func _lantern(at: Vector3, layer_id: int, gold: Material, bay: Node3D) -> void:
	var root := Node3D.new()
	root.position = at
	bay.add_child(root)
	lanterns.append(root)
	var shade := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = .13
	mesh.bottom_radius = .13
	mesh.height = .30 + layer_id * .018
	mesh.radial_segments = 8
	shade.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = [Color(.87, .58, .27), Color(.76, .31, .15), Color(.30, .49, .46)][layer_id]
	material.emission_enabled = true
	material.emission = Color(1, .50, .12)
	material.roughness = .9
	shade.material_override = material
	glows.append(material)
	root.add_child(shade)
	for y in [-.17, .17]: _box(root, Vector3(0, y, 0), Vector3(.30, .035, .29), gold)
	_rod(root, Vector3(0, .17, 0), Vector3(0, .30, 0), .009, gold)
	_rod(root, Vector3(0, -.17, 0), Vector3(0, -.37, 0), .008, gold)
	for side in [-1, 1]: _rod(root, Vector3(side * .105, -.14, .11), Vector3(side * .105, .14, .11), .009, gold)


func _flowers(at: Vector3, wood: Material, gold: Material) -> void:
	var props=preload("res://scripts/artisan_prop_detail.gd")
	props.lathe(self,at,PackedVector2Array([Vector2(.15,0),Vector2(.18,.03),Vector2(.23,.35),Vector2(.23,.38),Vector2(.20,.38),Vector2(.18,.08)]),wood,32)
	for y in [.09,.31]: props.ring(self,at+Vector3(0,y,0),.17+y*.15,.009,gold)
	for index in range(5):
		var center: Vector3 = at + Vector3((index - 2) * .10, .70 + sin(index * 1.3) * .18, 0)
		_rod(self, at + Vector3(0, .22, 0), center, .012, _flat(Color(.18, .31, .14)))
		for side in [-1,1]:
			var start: Vector3=at.lerp(center,.62)
			preload("res://scripts/botanical_detail.gd").sprig(self,start,start+Vector3(side*.17,.10,.02),.043,Color(.21,.33,.16))
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for petal in range(8):
			var angle: float=petal*TAU/8+index*.31
			var middle:=Vector3(cos(angle)*.074,sin(angle)*.074,.018)
			for segment in range(12):
				for corner in [-1,0,1]:
					var p:=middle+Vector3(0,0,.018)
					if corner!=0:
						var t: float=(segment+(1 if corner==1 else 0))*TAU/12
						p=middle+Vector3(cos(angle)*cos(t)*.070-sin(angle)*sin(t)*.038,sin(angle)*cos(t)*.070+cos(angle)*sin(t)*.038,.012*cos(t))
					st.add_vertex(p)
		st.generate_normals()
		var flower:=MeshInstance3D.new()
		flower.mesh=st.commit()
		flower.position=center
		var material: Material=_flat([Color(.76,.48,.23),Color(.68,.30,.23),Color(.83,.71,.43)][index%3])
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		flower.material_override=material
		flower.name="CuppedFlowerPetals"
		add_child(flower)
		var disk:=MeshInstance3D.new()
		var sphere:=SphereMesh.new()
		sphere.radius=.029
		sphere.height=.055
		sphere.radial_segments=10
		sphere.rings=4
		disk.mesh=sphere
		disk.scale.z=.45
		disk.position=center+Vector3(0,0,.046)
		disk.material_override=_flat(Color(.43,.29,.10))
		add_child(disk)


func _build_sparks() -> void:
	sparks = MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = 56
	var mesh := SphereMesh.new()
	mesh.radius = .017
	mesh.height = .034
	mesh.radial_segments = 5
	mesh.rings = 3
	multi.mesh = mesh
	sparks.multimesh = multi
	sparks.material_override = _flat(Color(.95, .68, .26), true, true)
	add_child(sparks)


func _process(delta: float) -> void:
	if world == null: return
	clock += delta
	var warmth: float = world.courtyard.lamp_count / 7.0
	var extra: float = world.folk.games_done.count(true) / 3.0 if world.folk != null else 0
	for index in range(lanterns.size()):
		lanterns[index].rotation.z = sin(clock * .8 + index * .6) * .045
		glows[index].emission_energy_multiplier = .12 + warmth * .70 + extra * .17
	for light in lights: light.light_energy = .35 + warmth * .55 + extra * .18
	for index in range(guests.size()):
		guests[index].visible = world.courtyard.personal_items_done()
		if guests[index].visible: guests[index].get_node("Character").animate_model(delta, 0, true, false, false)
	for index in range(sparks.multimesh.instance_count):
		var at := Vector3(41 + fposmod(index * 2.73 + sin(clock * .19 + index) * .4, 18), 1.7 + fposmod(index * .31 + clock * .07, 3.2), -1.4 - sin(index * 1.7) * .6)
		sparks.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, at))
	sparks.visible = warmth > .25 or extra > 0
