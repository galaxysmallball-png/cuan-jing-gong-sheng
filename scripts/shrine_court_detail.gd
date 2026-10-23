extends "res://scripts/environment_art.gd"


func setup(garden: Node3D) -> void:
	name="CraftedSteleAlcove"
	add_to_group("crafted_stele_alcove")
	var stone: Material=garden._stone(Color(.26,.29,.26),.05)
	var edge: Material=garden._stone(Color(.44,.43,.35),.02)
	var wood: Material=_surface(Color(.25,.14,.075),2)
	var warm_wood: Material=_surface(Color(.40,.26,.12),2)
	var bronze: Material=_flat(Color(.52,.39,.19))
	var boxes: Array=[]
	var trims: Array=[]
	var timber: Array=[]
	var lattice: Array=[]
	# Low broad stone courses make a fitted seat rather than an isolated cuboid.
	for entry in [[Vector3(2.38,.14,1.28),Vector3(10,.26,-2.35)],[Vector3(2.12,.10,1.12),Vector3(10,.37,-2.35)]]:
		boxes.append([entry[0],Transform3D(Basis.IDENTITY,entry[1])])
	for side in [-1,1]:
		var x: float=10+side*1.95
		# Recessed side panels, paired lattice and a shallow cornice behind the slab.
		for y in [.77,2.70]: timber.append([Vector3(1.03,.09,.12),Transform3D(Basis.IDENTITY,Vector3(x,y,-3.60))])
		for dx in [-.47,.47]: timber.append([Vector3(.09,2.01,.12),Transform3D(Basis.IDENTITY,Vector3(x+dx,1.73,-3.60))])
		for row in range(6):
			var cy: float=1.0+row*.27
			for col in range(3):
				var cx: float=x-.30+col*.30
				for sign_value in [-1,1]:
					lattice.append([Vector3(cx-.14,cy,-3.54),Vector3(cx+.14,cy+sign_value*.25,-3.54),.015])
		# Balustrade stops beside the shrine: the foreground walking lane stays clear.
		for z in [-2.9,-1.4]:
			boxes.append([Vector3(.23,.62,.25),Transform3D(Basis.IDENTITY,Vector3(x,.81,z))])
			trims.append([Vector3(.31,.10,.32),Transform3D(Basis.IDENTITY,Vector3(x,1.17,z))])
			_rock(self,Vector3(x,1.27,z),Vector3(.12,.12,.12),edge)
		for y in [.68,1.08]: boxes.append([Vector3(.15,.10,1.51),Transform3D(Basis.IDENTITY,Vector3(x,y,-2.15))])
		for z in [-2.65,-2.25,-1.85]: boxes.append([Vector3(.08,.34,.08),Transform3D(Basis.IDENTITY,Vector3(x,.86,z))])
		# Layered stone insets and a quiet geometric border, using no invented script.
		for y in [.48,.57]: trims.append([Vector3(.50,.025,.035),Transform3D(Basis.IDENTITY,Vector3(10+side*.69,y,-1.863))])
		for dx in [-.17,0,.17]:
			trims.append([Vector3(.025,.12,.03),Transform3D(Basis.IDENTITY,Vector3(10+side*.69+dx,.525,-1.86))])
	# Warm timber joinery complements the old thin protective surround.
	for side in [-1,1]:
		var x: float=10+side*.95
		timber.append([Vector3(.19,.21,.26),Transform3D(Basis.IDENTITY,Vector3(x,.69,-2.1))])
		timber.append([Vector3(.20,.12,.23),Transform3D(Basis.IDENTITY,Vector3(x,3.42,-2.1))])
		lattice.append([Vector3(x,3.05,-2.12),Vector3(x-side*.28,3.43,-2.12),.029])
	timber.append([Vector3(2.21,.14,.21),Transform3D(Basis.IDENTITY,Vector3(10,3.5,-2.12))])
	_boxes_merged(self,stone,boxes)
	_boxes_merged(self,edge,trims)
	_boxes_merged(self,wood,timber)
	_rods_merged(self,warm_wood,lattice)
	# Replace the visual impression of a bare ladder with a proper tied guard bay.
	var rails: Array=[]
	for x in [11.65,13.75]:
		_box(self,Vector3(x,.55,-2),Vector3(.31,.22,.38),stone)
		_rod(self,Vector3(x,.60,-2),Vector3(x,2.30,-2),.043,wood)
	for x in [11.95,12.30,12.65,13,13.35]:
		rails.append([Vector3(x,.79,-2.02),Vector3(x,1.23,-2.02),.019])
	_rods_merged(self,warm_wood,rails)
	_box(self,Vector3(12.70,2.31,-2),Vector3(2.30,.11,.22),warm_wood)
	# Small tool tray and turned feet finish the existing chisel bench.
	for x in [8.56,9.44]:
		_box(self,Vector3(x,.24,-1.3),Vector3(.19,.36,.32),wood)
		_box(self,Vector3(x,.10,-1.3),Vector3(.27,.08,.39),stone)
	_box(self,Vector3(9,.43,-1.3),Vector3(1.23,.07,.42),warm_wood)
	for x in [8.43,9.57]: _box(self,Vector3(x,.50,-1.3),Vector3(.035,.10,.43),bronze)
	# A pair of shallow offering dishes, not another line of hanging lanterns.
	for x in [8.30,11.70]:
		_box(self,Vector3(x,.57,-3.04),Vector3(.50,.09,.39),stone)
		var dish: MeshInstance3D=_rod(self,Vector3(x,.63,-3.04),Vector3(x,.70,-3.04),.17,bronze)
		dish.name="AlcoveDish"
