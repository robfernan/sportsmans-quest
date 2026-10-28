class_name TreeBuilder
extends RefCounted

## Generates lightweight procedural conifers (~400 tris) textured with CC0 Poly Haven bark/twig maps.

static var _bark_mat: Material
static var _leaf_mat: Material

static func _materials() -> void:
	if _bark_mat:
		return
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.24, 0.16, 0.10) # Procedural conifer bark
	bark.roughness = 0.95
	_bark_mat = bark
	
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.16, 0.28, 0.18) # Conifer green dusted with frost
	leaf.roughness = 0.9
	_leaf_mat = leaf

## kind: 0 = tall fir, 1 = wide spruce, 2 = sapling
static func build(kind: int, seed_value: int) -> ArrayMesh:
	_materials()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base_heights: Array[float] = [16.0, 12.0, 3.5]
	var base_widths: Array[float] = [3.2, 4.2, 1.3]
	var layer_counts: Array[int] = [9, 8, 5]
	var start_ratios: Array[float] = [0.22, 0.12, 0.1]

	var height: float = base_heights[kind] * rng.randf_range(0.85, 1.15)
	var width: float = base_widths[kind] * rng.randf_range(0.85, 1.15)
	var layers: int = layer_counts[kind]
	var mesh := ArrayMesh.new()
	# Trunk
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 7
	var r0 := height * 0.022
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var b0 := Vector3(cos(a0) * r0, 0, sin(a0) * r0)
		var b1 := Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		var t0 := Vector3(cos(a0) * r0 * 0.2, height * 0.9, sin(a0) * r0 * 0.2)
		var t1 := Vector3(cos(a1) * r0 * 0.2, height * 0.9, sin(a1) * r0 * 0.2)
		var u0 := float(i) / sides
		var u1 := float(i + 1) / sides
		for v in [[b0, Vector2(u0, 1)], [t0, Vector2(u0, 0)], [b1, Vector2(u1, 1)], [b1, Vector2(u1, 1)], [t0, Vector2(u0, 0)], [t1, Vector2(u1, 0)]]:
			st.set_uv(v[1])
			st.set_normal(Vector3(v[0].x, 0, v[0].z).normalized())
			st.add_vertex(v[0] - Vector3(0, 0.3, 0))
	st.set_material(_bark_mat)
	st.commit(mesh)
	# Foliage skirts (drooping cones with jagged edges)
	var fs := SurfaceTool.new()
	fs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 9
	var start_h: float = height * start_ratios[kind]
	for l in layers:
		var t := float(l) / layers
		var y_top: float = lerp(start_h, height, t) + (height / float(layers)) * 1.2
		var y_rim: float = lerp(start_h, height, t) - height * 0.02
		var rad: float = width * (1.0 - t * 0.9) * rng.randf_range(0.9, 1.1)
		var rot := rng.randf() * TAU
		var top := Vector3(0, y_top, 0)
		for s in segs:
			var a0 := rot + TAU * s / segs
			var a1 := rot + TAU * (s + 1) / segs
			var am := (a0 + a1) * 0.5
			var j0 := rad * rng.randf_range(0.8, 1.05)
			var j1 := rad * rng.randf_range(0.8, 1.05)
			var p0 := Vector3(cos(a0) * j0, y_rim + rng.randf_range(-0.3, 0.2), sin(a0) * j0)
			var p1 := Vector3(cos(a1) * j1, y_rim + rng.randf_range(-0.3, 0.2), sin(a1) * j1)
			var pm := Vector3(cos(am) * rad * 1.15, y_rim - 0.5, sin(am) * rad * 1.15)
			var n := Vector3(cos(am), 0.8, sin(am)).normalized()
			for v in [[top, Vector2(0.5, 0)], [p0, Vector2(0, 1)], [pm, Vector2(0.5, 1)], [top, Vector2(0.5, 0)], [pm, Vector2(0.5, 1)], [p1, Vector2(1, 1)]]:
				fs.set_uv(v[1])
				fs.set_normal(n)
				fs.set_color(Color(1, 1, 1, v[0].y / height))
				fs.add_vertex(v[0])
	fs.set_material(_leaf_mat)
	fs.commit(mesh)
	return mesh
