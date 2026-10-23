extends RefCounted


static func binds(mesh: MeshInstance3D, skeleton: Skeleton3D, names: Array) -> Array[int]:
	var result: Array[int]=[]
	if mesh.skin==null: return result
	for i in range(mesh.skin.get_bind_count()):
		var index: int=mesh.skin.get_bind_bone(i)
		var bone_name: String=str(mesh.skin.get_bind_name(i))
		if bone_name.is_empty() and index>=0: bone_name=skeleton.get_bone_name(index)
		if bone_name in names: result.append(i)
	return result


static func belongs(arrays: Array, vertex: int, selected: Array[int]) -> bool:
	var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	var count: int=bones.size()/positions.size()
	var influence: float=0
	for i in range(count):
		if bones[vertex*count+i] in selected: influence+=weights[vertex*count+i]
	return influence>.5


static func extract(source: Node3D, names: Array) -> Node3D:
	var result:=Node3D.new()
	result.name="FocusedObjectPreview"
	for original: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var selected: Array[int]=binds(original,source.skeleton,names)
		if selected.is_empty(): continue
		var mesh:=ArrayMesh.new()
		for surface in range(original.mesh.get_surface_count()):
			var arrays: Array=original.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var chosen:=PackedInt32Array()
			for triangle in range(0,indices.size(),3):
				if belongs(arrays,indices[triangle],selected) and belongs(arrays,indices[triangle+1],selected) and belongs(arrays,indices[triangle+2],selected):
					for offset in range(3): chosen.append(indices[triangle+offset])
			if chosen.is_empty(): continue
			var st:=SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_material(original.get_active_material(surface))
			for index in chosen:
				if not normals.is_empty(): st.set_normal(normals[index])
				if not uv.is_empty(): st.set_uv(uv[index])
				st.add_vertex(positions[index])
			st.commit(mesh)
		if mesh.get_surface_count()==0: continue
		var part:=MeshInstance3D.new()
		part.mesh=mesh
		part.transform=source.global_transform.affine_inverse()*original.global_transform
		result.add_child(part)
	return result


static func omit(source: Node3D, names: Array) -> void:
	for instance: MeshInstance3D in source._model.find_children("*","MeshInstance3D",true,false):
		var selected: Array[int]=binds(instance,source.skeleton,names)
		if selected.is_empty(): continue
		var mesh:=ArrayMesh.new()
		for surface in range(instance.mesh.get_surface_count()):
			var arrays: Array=instance.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var kept:=PackedInt32Array()
			for triangle in range(0,indices.size(),3):
				if belongs(arrays,indices[triangle],selected): continue
				for offset in range(3): kept.append(indices[triangle+offset])
			if kept.is_empty(): continue
			arrays[Mesh.ARRAY_INDEX]=kept
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			mesh.surface_set_material(mesh.get_surface_count()-1,instance.get_active_material(surface))
		instance.mesh=mesh
