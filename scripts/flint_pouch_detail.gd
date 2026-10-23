extends "res://scripts/environment_art.gd"

const ROWS: int=32
const SIDES: int=64

func _point(u: float,v: float) -> Vector3:
	var angle: float=u*TAU
	var width: float=.015+.102*pow(sin(v*PI*.95),.66)
	width*=1.0-.22*smoothstep(.72,1,v)
	var gathering: float=sin(angle*12+.3)*.009*smoothstep(.60,1,v)
	var folds: float=sin(angle*7+v*4.1)*.0025
	return Vector3(cos(angle)*(width+gathering+folds),.012+v*.30,sin(angle)*(width*.55+gathering*.55+folds))

func build() -> void:
	name="GatheredWovenFlintPouch"
	add_to_group("detailed_flint_pouch")
	var body:=SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(ROWS+1):
		for side in range(SIDES+1):
			var v: float=float(row)/ROWS
			var u: float=float(side)/SIDES
			body.set_uv(Vector2(u,v))
			body.add_vertex(_point(u,v))
	for row in range(ROWS):
		for side in range(SIDES):
			var a: int=row*(SIDES+1)+side
			for i in [a,a+1,a+SIDES+1,a+1,a+SIDES+2,a+SIDES+1]: body.add_index(i)
	body.generate_normals()
	var cloth:=MeshInstance3D.new()
	cloth.name="GatheredClothBody"
	cloth.mesh=body.commit()
	var fabric:=ShaderMaterial.new()
	fabric.shader=preload("res://shaders/pouch_woven.gdshader")
	cloth.material_override=fabric
	add_child(cloth)
	var dark: Material=_flat(Color(.075,.073,.045))
	var thread: Material=_flat(Color(.61,.45,.20))
	var flax: Material=_flat(Color(.42,.31,.16))
	var blue: Material=_flat(Color(.10,.27,.29))
	# An open mouth, rolled irregular hem, gathered pleats and sewn eyelets.
	var mouth:=MeshInstance3D.new()
	var cavity:=CylinderMesh.new()
	cavity.top_radius=.027
	cavity.bottom_radius=.031
	cavity.height=.009
	cavity.radial_segments=32
	mouth.mesh=cavity
	mouth.position=Vector3(0,.302,0)
	mouth.material_override=dark
	add_child(mouth)
	var sewing: Array=[]
	var cord: Array=[]
	for i in range(80):
		var a: Vector3=_point(float(i)/80,1)
		var b: Vector3=_point(float(i+1)/80,1)
		cord.append([a,b,.0034])
		var aa: Vector3=_point(float(i)/80,.915)+Vector3(0,0,.001)
		var bb: Vector3=_point(float(i+1)/80,.915)+Vector3(0,0,.001)
		cord.append([aa,bb,.0023])
	for side in [-1,1]:
		for i in range(23):
			var v: float=.08+i*.036
			var a: Vector3=_point(.085 if side>0 else .415,v)
			sewing.append([a,a+Vector3(-side*.006,.004,.0015),.0009])
			sewing.append([a+Vector3(-side*.006,.004,.0015),a+Vector3(0,.008,0),.0009])
		# Two braided drawstrings cross in a real knot before dropping to tassels.
		for strand in range(2):
			for i in range(36):
				var t: float=float(i)/36
				var tt: float=float(i+1)/36
				var a:=Vector3(side*(.025+t*.063)+sin(t*TAU*7+strand*PI)*.0013,.306-t*.111,.029+cos(t*TAU*7+strand*PI)*.0013)
				var b:=Vector3(side*(.025+tt*.063)+sin(tt*TAU*7+strand*PI)*.0013,.306-tt*.111,.029+cos(tt*TAU*7+strand*PI)*.0013)
				cord.append([a,b,.00125])
		for i in range(8): cord.append([Vector3(side*.088,.195,.03),Vector3(side*.088+(i-3.5)*.0012,.174-i%2*.003,.031),.0007])
		for i in range(28):
			var a: float=float(i)/28*TAU
			var b: float=float(i+1)/28*TAU
			cord.append([Vector3(side*(.026+sin(a)*.019),.324+cos(a)*.018,.018),Vector3(side*(.026+sin(b)*.019),.324+cos(b)*.018,.018),.0019])
	# Embroidered petals use two outlines with fine satin stitches and a small
	# turquoise centre, all raised above the woven front rather than a flat decal.
	for petal in range(6):
		var theta: float=petal*TAU/6
		for row in range(2):
			for i in range(36):
				var a: float=float(i)/36*TAU
				var b: float=float(i+1)/36*TAU
				var center:=Vector2(sin(theta),cos(theta))*.025
				var basis_a:=Vector2(sin(theta),cos(theta))
				var basis_b:=Vector2(cos(theta),-sin(theta))
				var aa: Vector2=center+basis_a*cos(a)*(.027-row*.003)+basis_b*sin(a)*(.014-row*.0015)
				var bb: Vector2=center+basis_a*cos(b)*(.027-row*.003)+basis_b*sin(b)*(.014-row*.0015)
				sewing.append([Vector3(aa.x,.169+aa.y,.066),Vector3(bb.x,.169+bb.y,.066),.00085])
		for i in range(9):
			var t: float=(i+.5)/9
			var p: Vector2=Vector2(sin(theta),cos(theta))*(.012+t*.035)
			var cross: Vector2=Vector2(cos(theta),-sin(theta))*sin(t*PI)*.009
			sewing.append([Vector3(p.x-cross.x,.169+p.y-cross.y,.066),Vector3(p.x+cross.x,.169+p.y+cross.y,.066),.00055])
	_rods_merged(self,thread,sewing).name="RaisedEmbroideryAndSeams"
	_rods_merged(self,flax,cord).name="BraidedDrawstringsAndRolledHem"
	var center:=MeshInstance3D.new()
	var bead:=SphereMesh.new()
	bead.radius=.006
	bead.height=.012
	bead.radial_segments=16
	bead.rings=8
	center.mesh=bead
	center.position=Vector3(0,.169,.069)
	center.scale.z=.5
	center.material_override=blue
	add_child(center)
	for i in range(2):
		var profile:=PackedVector2Array([Vector2(-.013,0),Vector2(.012,.001),Vector2(.010,.026),Vector2(.001,.036),Vector2(-.009,.023)])
		var flint: MeshInstance3D=preload("res://scripts/natural_outcrop.gd").make(self,Vector3(-.011+i*.019,.297,.005-i*.013),profile,.012,_flat(Color(.31,.33,.29)))
		flint.name="ChippedFlintInMouth"
		flint.rotation.z=(-.22 if i==0 else .31)
