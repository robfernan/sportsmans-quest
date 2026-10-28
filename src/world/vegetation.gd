class_name Vegetation
extends Node3D

## 100% Procedural Chunked MultiMesh Vegetation (Sportsman's Quest)
## Generates procedural conifers, shrubs, reed clusters, rocks, and grasses
## with ZERO external textures or models (< 1 MB game package).

const CHUNK = 64.0

var terrain: Terrain
var chunks := {}
var tree_body: StaticBody3D
var rng := RandomNumberGenerator.new()

var _rock_mesh: Mesh
var _shrub_mesh: Mesh
var _grass_mesh: Mesh
var _stump_mesh: Mesh

var layers: Array = [
	{"kind": "tree", "proc": 0, "count": 450, "scale": Vector2(0.8, 1.3), "min_h": 1.0, "slope": 0.45, "range": 450.0, "col": 0.35},
	{"kind": "tree", "proc": 1, "count": 300, "scale": Vector2(0.8, 1.2), "min_h": 1.0, "slope": 0.45, "range": 450.0, "col": 0.35},
	{"kind": "tree", "proc": 2, "count": 350, "scale": Vector2(0.7, 1.4), "min_h": 0.8, "slope": 0.5, "range": 160.0, "col": 0.0},
	{"kind": "stump", "count": 80, "scale": Vector2(0.8, 1.3), "min_h": 0.5, "slope": 0.5, "range": 140.0, "col": 0.3},
	{"kind": "rock", "count": 160, "scale": Vector2(0.8, 2.0), "min_h": -1.0, "slope": 0.8, "range": 220.0, "col": 0.0},
	{"kind": "shrub", "count": 500, "scale": Vector2(0.7, 1.3), "min_h": 0.3, "slope": 0.6, "range": 120.0, "col": 0.0},
	{"kind": "grass", "count": 1500, "scale": Vector2(0.9, 1.6), "min_h": 0.2, "slope": 0.5, "range": 60.0, "col": 0.0},
]

func _init_procedural_meshes() -> void:
	if _rock_mesh:
		return
		
	# 1. Procedural Rock (Sphere with low subdivision + stone material)
	var rock := SphereMesh.new()
	rock.radial_segments = 5
	rock.rings = 3
	rock.radius = 0.6
	rock.height = 0.7
	var mat_rock := StandardMaterial3D.new()
	mat_rock.albedo_color = Color(0.38, 0.38, 0.36)
	mat_rock.roughness = 0.95
	rock.material = mat_rock
	_rock_mesh = rock

	# 2. Procedural Shrub
	var shrub := SphereMesh.new()
	shrub.radial_segments = 6
	shrub.rings = 4
	shrub.radius = 0.55
	shrub.height = 0.8
	var mat_shrub := StandardMaterial3D.new()
	mat_shrub.albedo_color = Color(0.18, 0.28, 0.14)
	mat_shrub.roughness = 0.9
	shrub.material = mat_shrub
	_shrub_mesh = shrub

	# 3. Procedural Tree Stump
	var stump := CylinderMesh.new()
	stump.radial_segments = 6
	stump.top_radius = 0.35
	stump.bottom_radius = 0.42
	stump.height = 0.6
	var mat_stump := StandardMaterial3D.new()
	mat_stump.albedo_color = Color(0.26, 0.18, 0.12)
	mat_stump.roughness = 0.9
	stump.material = mat_stump
	_stump_mesh = stump

	# 4. Procedural Grass Tuft (Cross-quad mesh)
	var grass := QuadMesh.new()
	grass.size = Vector2(0.7, 0.6)
	var mat_grass := StandardMaterial3D.new()
	mat_grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_grass.albedo_color = Color(0.28, 0.42, 0.16)
	mat_grass.roughness = 0.9
	grass.material = mat_grass
	_grass_mesh = grass

func build(t: Terrain, quality: int, keep_clear: Vector3) -> void:
	terrain = t
	rng.seed = 4242
	_init_procedural_meshes()
	
	tree_body = StaticBody3D.new()
	tree_body.name = "TreeColliders"
	add_child(tree_body)
	
	var density: float = [0.35, 0.7, 1.0][clamp(quality, 0, 2)]
	for layer in layers:
		if layer.kind == "tree":
			for v in 3:
				var l: Dictionary = layer.duplicate()
				l["parts"] = [{"mesh": TreeBuilder.build(layer.proc, layer.proc * 100 + v), "xf": Transform3D.IDENTITY}]
				_scatter(l, int(layer.count * density / 3.0), keep_clear)
		elif layer.kind == "rock":
			layer["parts"] = [{"mesh": _rock_mesh, "xf": Transform3D.IDENTITY}]
			_scatter(layer, int(layer.count * density), keep_clear)
		elif layer.kind == "shrub":
			layer["parts"] = [{"mesh": _shrub_mesh, "xf": Transform3D.IDENTITY}]
			_scatter(layer, int(layer.count * density), keep_clear)
		elif layer.kind == "stump":
			layer["parts"] = [{"mesh": _stump_mesh, "xf": Transform3D.IDENTITY}]
			_scatter(layer, int(layer.count * density), keep_clear)
		elif layer.kind == "grass":
			layer["parts"] = [{"mesh": _grass_mesh, "xf": Transform3D.IDENTITY}]
			_scatter(layer, int(layer.count * density), keep_clear)

func _scatter(layer: Dictionary, total: int, keep_clear: Vector3) -> void:
	var parts: Array = layer.get("parts", [])
	if parts.is_empty():
		return
	var half := Terrain.SIZE * 0.48
	var max_range: float = layer.range
	var max_range_sq := max_range * max_range
	var chunks := {}

	for i in total:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		if Vector2(x - keep_clear.x, z - keep_clear.z).length_squared() > max_range_sq:
			continue
		var h := terrain.height_at(x, z)
		if h < layer.min_h:
			continue
		var n := terrain.normal_at(x, z)
		if 1.0 - n.y > layer.slope:
			continue
		if layer.col > 0.0 and Vector2(x, z).distance_to(Vector2(keep_clear.x, keep_clear.z)) < 14.0:
			continue
		if layer.col > 0.0 and terrain.noise.get_noise_2d(x * 2.5, z * 2.5) < -0.15:
			continue
		var s := rng.randf_range(layer.scale.x, layer.scale.y)
		var t_basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
		var xf := Transform3D(t_basis, Vector3(x, h - 0.05, z))
		var key := Vector2i(int(floor(x / CHUNK)), int(floor(z / CHUNK)))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(xf)
		if layer.col > 0.0:
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = layer.col * s * 0.8
			cyl.height = 10.0 * s
			cs.shape = cyl
			cs.position = Vector3(x, h + cyl.height * 0.5, z)
			tree_body.add_child(cs)

	for key in chunks:
		var xfs: Array = chunks[key]
		for part in parts:
			var mmi := MultiMeshInstance3D.new()
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = part.mesh
			mm.instance_count = xfs.size()
			for idx in xfs.size():
				mm.set_instance_transform(idx, xfs[idx] * part.xf)
			mmi.multimesh = mm
			add_child(mmi)
