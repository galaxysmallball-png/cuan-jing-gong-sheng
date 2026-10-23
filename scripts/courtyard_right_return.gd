extends "res://scripts/environment_art.gd"

# Scenery beyond the playable court, continuing the paving and all three risers
# past both the gameplay camera and the wider art inspection camera.
func setup(stone: Material, wood: Material) -> void:
	name="CourtyardRightReturn"
	rng.seed=202610204
	_box(self,Vector3(24.12,-.3,0),Vector3(7.76,.58,6.8),stone).name="ContinuousDeck"
	var paving: Array=[]
	var risers: Array=[]
	for row in range(7):
		for col in range(23,32):
			var x: float=.1+col*.89+(.22 if row%2==0 else 0)
			paving.append([Vector3(.83,.045,.71),Transform3D(Basis(Vector3.UP,rng.randf_range(-.025,.025)),Vector3(x,-.025+rng.randf_range(-.006,.006),-2.7+row*.78))])
	_boxes_merged(self,_flat(Color(.28,.31,.26)),paving).name="ContinuedPaving"
	for index in range(28,39):
		risers.append([Vector3(.70,.2,.26),Transform3D(Basis.IDENTITY,Vector3(.1+index*.74,.08,2.85))])
	for row in range(3):
		for col in range(26,36):
			risers.append([Vector3(.78,.20,.55),Transform3D(Basis.IDENTITY,Vector3(-.1+col*.81+row%2*.20,-.22-row*.22,3.38))])
	_boxes_merged(self,stone,risers).name="ContinuousStepCourses"
	# A garden return sits behind the walking lane, attached to the gallery end.
	var wall: Array=[]
	for row in range(3):
		for index in range(8):
			wall.append([Vector3(.77,.22,.38),Transform3D(Basis.IDENTITY,Vector3(20.1+index*.81+(row%2)*.18,.12+row*.24,-3.5))])
	_boxes_merged(self,stone,wall).name="GardenReturnMasonry"
	_box(self,Vector3(23.2,.77,-3.5),Vector3(6.9,.12,.50),stone)
	for x in [20.25,22.5,24.75,27.0]:
		_box(self,Vector3(x,.98,-3.5),Vector3(.25,.52,.25),stone)
		_box(self,Vector3(x,1.26,-3.5),Vector3(.34,.10,.34),stone)
	for y in [.91,1.15]:
		_rod(self,Vector3(20.25,y,-3.5),Vector3(27,y,-3.5),.025,wood)
	# Low, irregular planted rock beds tie the wall into the hillside. No collision.
	var rock_material: Material=preload("res://scripts/natural_outcrop.gd").stone(Color(.25,.29,.24),.29)
	for index in range(9):
		var at:=Vector3(20.55+index*.86,.1,-4.12)
		var outline:=PackedVector2Array([Vector2(-.65,-.2),Vector2(.65,-.2),Vector2(.76,.27),Vector2(.36,.55+rng.randf()*.35),Vector2(-.28,.72+rng.randf()*.3),Vector2(-.72,.3)])
		preload("res://scripts/natural_outcrop.gd").make(self,at,outline,.7,rock_material)
		for leaf in range(6):
			var a: Vector3=at+Vector3(rng.randf_range(-.25,.25),.35,.28)
			var b: Vector3=a+Vector3(rng.randf_range(-.5,.5),rng.randf_range(.25,.6),.08)
			preload("res://scripts/botanical_detail.gd").sprig(self,a,b,.09,Color(.26,.34,.19))
