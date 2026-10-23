extends "res://scripts/environment_art.gd"


func build() -> void:
	name="ForgedHoeDetail"
	add_to_group("forged_hoe_detail")
	var wood: Material=_surface(Color(.30,.19,.095),2)
	var iron: Material=_flat(Color(.19,.23,.23))
	var worn: Material=_flat(Color(.47,.49,.45))
	var rope: Material=_flat(Color(.52,.41,.25))
	_rod(self,Vector3(-.44,1.336,-.01),Vector3(.39,1.363,-.045),.014,wood)
	for i in range(5):
		_rod(self,Vector3(-.36+i*.032,1.34,-.012),Vector3(-.36+i*.032,1.34,-.012)+Vector3(.004,.017,.003),.017,rope)
	_rod(self,Vector3(.345,1.36,-.045),Vector3(.405,1.362,-.045),.026,iron)
	_rod(self,Vector3(.39,1.36,-.045),Vector3(.41,1.29,-.043),.020,iron)
	var vertices:=PackedVector3Array([Vector3(.38,1.31,-.06),Vector3(.43,1.31,-.06),Vector3(.48,1.14,-.015),Vector3(.33,1.14,-.015),Vector3(.38,1.31,-.045),Vector3(.43,1.31,-.045),Vector3(.48,1.14,-.002),Vector3(.33,1.14,-.002)])
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0,2,1],[0,3,2],[4,5,6],[4,6,7],[0,1,5],[0,5,4],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,0,4],[3,4,7]]:
		for index in face: st.add_vertex(vertices[index])
	st.generate_normals()
	var blade:=MeshInstance3D.new()
	blade.mesh=st.commit()
	blade.material_override=iron
	add_child(blade)
	_rod(self,Vector3(.33,1.14,-.008),Vector3(.48,1.14,-.008),.004,worn)
	_rod(self,Vector3(.405,1.29,-.059),Vector3(.405,1.18,-.024),.004,worn)
