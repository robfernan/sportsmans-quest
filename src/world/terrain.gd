class_name Terrain
extends StaticBody3D

## Procedural heightmap reserve ("Whispering Pines"). Builds render mesh, collision and minimap.

const SIZE := 600.0
const STEP := 3.0
const WATER_LEVEL := 0.0
const LAKE_CENTER := Vector2(-70.0, 60.0)
const LAKE_RADIUS := 85.0

var verts_per_side: int = int(SIZE / STEP) + 1
var heights := PackedFloat32Array()
var noise := FastNoiseLite.new()
var detail := FastNoiseLite.new()
var map_image: Image

func build(seed_value: int = 1337) -> void:
	noise.seed = seed_value
	noise.frequency = 0.004
	noise.fractal_octaves = 4
	detail.seed = seed_value + 7
	detail.frequency = 0.03
	_generate_heights()
	_build_mesh()
	_build_collision()
	_build_map_image()

func _raw_height(x: float, z: float) -> float:
	var h := noise.get_noise_2d(x, z) * 28.0 + 10.0
	h += detail.get_noise_2d(x, z) * 1.2
	# Ridge rising toward the north edge
	h += clamp((-z - 120.0) * 0.12, 0.0, 30.0)
	# Lake basin
	var d := Vector2(x, z).distance_to(LAKE_CENTER)
	var basin: float = 1.0 - smoothstep(LAKE_RADIUS * 0.4, LAKE_RADIUS, d)
	h = lerp(h, -4.0, basin)
	# Raise borders so player stays inside
	var edge: float = max(abs(x), abs(z)) - (SIZE * 0.5 - 30.0)
	if edge > 0.0:
		h += edge * 1.5
	return h

func _generate_heights() -> void:
	heights.resize(verts_per_side * verts_per_side)
	var half := SIZE * 0.5
	for zi in verts_per_side:
		for xi in verts_per_side:
			heights[zi * verts_per_side + xi] = _raw_height(xi * STEP - half, zi * STEP - half)

func height_at(x: float, z: float) -> float:
	var half := SIZE * 0.5
	var fx: float = clamp((x + half) / STEP, 0.0, verts_per_side - 1.001)
	var fz: float = clamp((z + half) / STEP, 0.0, verts_per_side - 1.001)
	var xi := int(fx)
	var zi := int(fz)
	var tx := fx - xi
	var tz := fz - zi
	var h00 := heights[zi * verts_per_side + xi]
	var h10 := heights[zi * verts_per_side + xi + 1]
	var h01 := heights[(zi + 1) * verts_per_side + xi]
	var h11 := heights[(zi + 1) * verts_per_side + xi + 1]
	return lerp(lerp(h00, h10, tx), lerp(h01, h11, tx), tz)

func normal_at(x: float, z: float) -> Vector3:
	var hl := height_at(x - 1.0, z)
	var hr := height_at(x + 1.0, z)
	var hd := height_at(x, z - 1.0)
	var hu := height_at(x, z + 1.0)
	return Vector3(hl - hr, 2.0, hd - hu).normalized()

func is_water(x: float, z: float) -> bool:
	return height_at(x, z) < WATER_LEVEL - 0.3

func _build_mesh() -> void:
	var n := verts_per_side
	var half := SIZE * 0.5
	var verts := PackedVector3Array(); verts.resize(n * n)
	var norms := PackedVector3Array(); norms.resize(n * n)
	var uvs := PackedVector2Array(); uvs.resize(n * n)
	for zi in n:
		for xi in n:
			var i := zi * n + xi
			var x := xi * STEP - half
			var z := zi * STEP - half
			verts[i] = Vector3(x, heights[i], z)
			var hl := heights[zi * n + max(xi - 1, 0)]
			var hr := heights[zi * n + min(xi + 1, n - 1)]
			var hd := heights[max(zi - 1, 0) * n + xi]
			var hu := heights[min(zi + 1, n - 1) * n + xi]
			norms[i] = Vector3(hl - hr, 2.0 * STEP, hd - hu).normalized()
			uvs[i] = Vector2(x, z)
	var idx := PackedInt32Array(); idx.resize((n - 1) * (n - 1) * 6)
	var k := 0
	for zi in n - 1:
		for xi in n - 1:
			var a := zi * n + xi
			var b := a + 1
			var c := a + n
			var d := c + 1
			idx[k] = a; idx[k + 1] = b; idx[k + 2] = c
			idx[k + 3] = b; idx[k + 4] = d; idx[k + 5] = c
			k += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = mesh
	mi.material_override = _make_material()
	add_child(mi)

func _load_tex(path: String, fallback: Color) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	img.fill(fallback)
	return ImageTexture.create_from_image(img)

func _make_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/world/terrain.gdshader")
	return mat

func _build_collision() -> void:
	var shape := HeightMapShape3D.new()
	shape.map_width = verts_per_side
	shape.map_depth = verts_per_side
	shape.map_data = heights
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.scale = Vector3(STEP, 1.0, STEP)
	add_child(cs)

func _build_map_image() -> void:
	var n := verts_per_side
	map_image = Image.create(n, n, false, Image.FORMAT_RGB8)
	for zi in n:
		for xi in n:
			var h := heights[zi * n + xi]
			var c: Color
			if h < WATER_LEVEL:
				c = Color(0.15, 0.3, 0.45).lerp(Color(0.08, 0.18, 0.3), clamp(-h / 4.0, 0.0, 1.0))
			else:
				c = Color(0.32, 0.42, 0.24).lerp(Color(0.55, 0.5, 0.42), clamp(h / 45.0, 0.0, 1.0))
				# Contour lines every 5 m
				if fmod(h, 5.0) < 0.35:
					c = c.darkened(0.25)
			map_image.set_pixel(xi, zi, c)
