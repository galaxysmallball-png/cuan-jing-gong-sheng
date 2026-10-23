extends RefCounted


static func dress(panel: MeshInstance3D, id: int) -> void:
	var dimensions: Vector3 = panel.mesh.get_aabb().size
	var width: float = dimensions.x
	var height: float = dimensions.y
	var depth: float = dimensions.z
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/courtyard_stone.gdshader")
	material.set_shader_parameter("base_color", Color(.37, .35, .30))
	material.set_shader_parameter("moss_amount", .14)
	panel.material_override = material
	panel.mesh = _body(width, height if id == 0 else height * .78, depth)
	if id == 1:
		# The arched, pierced crown is a visual study of the supplied stone photo.
		var lower := MeshInstance3D.new()
		lower.mesh = panel.mesh
		lower.position.y = -height * .11
		lower.material_override = material
		panel.add_child(lower)
		panel.mesh = _crown(width, height, depth)
	panel.set_meta("historical_surface", true)


static func _body(width: float, height: float, depth: float) -> ArrayMesh:
	var x: float = width / 2
	var y: float = height / 2
	var c: float = width * .065
	var outline: Array[Vector2] = [Vector2(-x + c, -y), Vector2(x - c, -y), Vector2(x, -y + c), Vector2(x, y - c * .8), Vector2(x - c * .7, y), Vector2(-x + c * 1.2, y - c * .2), Vector2(-x, y - c * 1.4), Vector2(-x, -y + c)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bevel: float=minf(depth*.12,.035)
	for index in range(outline.size()):
		var p: Vector2 = outline[index]
		var q: Vector2 = outline[(index + 1) % outline.size()]
		var a := Vector3(p.x*.965, p.y*.985, depth / 2)
		var b := Vector3(q.x*.965, q.y*.985, depth / 2)
		var c3 := Vector3(q.x*.965, q.y*.985, -depth / 2)
		var d := Vector3(p.x*.965, p.y*.985, -depth / 2)
		var e := Vector3(p.x,p.y,depth/2-bevel)
		var f := Vector3(q.x,q.y,depth/2-bevel)
		var g := Vector3(q.x,q.y,-depth/2+bevel)
		var h := Vector3(p.x,p.y,-depth/2+bevel)
		for triangle in [[Vector3(0, 0, depth / 2), a, b], [Vector3(0, 0, -depth / 2), c3, d], [a,e,f],[a,f,b],[e,h,g],[e,g,f],[h,d,c3],[h,c3,g]]:
			_triangle(surface, triangle)
	surface.generate_normals()
	return surface.commit()


static func _crown(width: float, height: float, depth: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2(0, height * .35)
	var outer: Array[Vector2] = []
	var inner: Array[Vector2] = []
	for index in range(40):
		var angle: float = TAU * index / 40
		var direction := Vector2(cos(angle), sin(angle))
		var distance: float = 0
		for step in range(1, 101):
			var test: Vector2 = center + direction * (width * step / 100)
			if test.y < height * .27 or pow(test.x / (width * .5), 2) + pow((test.y - height * .27) / (height * .23), 2) > 1: break
			distance = width * step / 100
		outer.append(center + direction * distance)
		inner.append(center + direction * width * .075)
	for index in range(40):
		var next: int = (index + 1) % 40
		for side in [-1, 1]:
			var a := Vector3(outer[index].x, outer[index].y, side * depth / 2)
			var b := Vector3(outer[next].x, outer[next].y, side * depth / 2)
			var c := Vector3(inner[next].x, inner[next].y, side * depth / 2)
			var d := Vector3(inner[index].x, inner[index].y, side * depth / 2)
			_triangle(surface, [a, b, c] if side > 0 else [a, c, b])
			_triangle(surface, [a, c, d] if side > 0 else [a, d, c])
		for ring in [outer, inner]:
			var a := Vector3(ring[index].x, ring[index].y, depth / 2)
			var b := Vector3(ring[next].x, ring[next].y, depth / 2)
			var c := Vector3(b.x, b.y, -depth / 2)
			var d := Vector3(a.x, a.y, -depth / 2)
			_triangle(surface, [a, d, c])
			_triangle(surface, [a, c, b])
	surface.generate_normals()
	return surface.commit()


static func _triangle(surface: SurfaceTool, triangle: Array) -> void:
	# Outward faces use Godot's clockwise front winding. The former reverse
	# winding culled the near stone edges, making a carried slab look like paper.
	for index in [0,2,1]:
		var vertex: Vector3=triangle[index]
		surface.set_uv(Vector2(vertex.x, vertex.y))
		surface.add_vertex(vertex)
