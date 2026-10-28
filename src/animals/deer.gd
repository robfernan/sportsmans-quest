class_name Deer
extends Animal

## Whitetail Deer: procedurally modelled & animated (legs, grazing head, flagging tail, antlers).

var legs: Array = []
var neck: Node3D
var tail: Node3D
var phase := 0.0
var antler_points := 0

static func _mat(c: Color, rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _setup_species() -> void:
	species = "Whitetail Deer"
	gender = "Male" if randf() < 0.4 else "Female"
	walk_speed = 1.3
	run_speed = 12.0
	sight_range = 120.0
	hearing_mult = 1.0
	scent_range = 240.0
	call_type = "deer_call"
	if gender == "Male":
		weight_kg = randf_range(70.0, 125.0)
		antler_points = [4, 6, 8, 8, 8, 10, 10, 12].pick_random()
		trophy_score = 60.0 + antler_points * 9.0 + (weight_kg - 70.0) * 0.4 + randf_range(-8.0, 12.0)
		trophy_label = "Antler Score (B&C)"
	else:
		weight_kg = randf_range(45.0, 75.0)
		trophy_score = weight_kg * 0.9 + randf_range(0.0, 10.0)
		trophy_label = "Weight Score"
	var spine := []
	for i in 7:
		spine.append({"name": "Spine", "pos": Vector3(0, 1.3, -0.65 + i * 0.2), "r": 0.07, "lethal": 1})
	hit_zones = [
		{"name": "Heart", "pos": Vector3(0, 0.86, -0.52), "r": 0.11},
		{"name": "Lungs", "pos": Vector3(0, 1.03, -0.45), "r": 0.24},
		{"name": "Liver", "pos": Vector3(0, 0.96, -0.12), "r": 0.15},
		{"name": "Stomach", "pos": Vector3(0, 0.95, 0.25), "r": 0.28},
		{"name": "Brain", "pos": Vector3(0, 1.72, -0.92), "r": 0.075},
		{"name": "Spine", "pos": Vector3(0, 1.45, -0.75), "r": 0.06},
	] + spine

func _collision_shape() -> Shape3D:
	var b := BoxShape3D.new()
	b.size = Vector3(0.55, 1.35, 2.0)
	return b

func _collision_offset() -> Vector3:
	return Vector3(0, 1.15, -0.1)

func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi

func _build_model() -> Node3D:
	var root := Node3D.new()
	var coat := _mat(Color(0.47, 0.32, 0.2) if gender == "Male" else Color(0.55, 0.4, 0.27))
	var belly := _mat(Color(0.82, 0.76, 0.66))
	var dark := _mat(Color(0.1, 0.08, 0.07))
	var bone := _mat(Color(0.78, 0.72, 0.6), 0.6)
	var s := 1.0 if gender == "Female" else 1.1
	root.scale = Vector3(s, s, s) * (weight_kg / 85.0) ** 0.33
	var sphere := SphereMesh.new(); sphere.radial_segments = 12; sphere.rings = 6
	var cap := CapsuleMesh.new(); cap.radius = 0.5; cap.height = 2.0; cap.radial_segments = 10; cap.rings = 4
	# Body
	_part(root, sphere, coat, Vector3(0, 1.0, 0), Vector3.ZERO, Vector3(0.48, 0.62, 1.55))
	_part(root, sphere, belly, Vector3(0, 0.86, -0.05), Vector3.ZERO, Vector3(0.4, 0.38, 1.2))
	_part(root, sphere, coat, Vector3(0, 1.03, -0.5), Vector3.ZERO, Vector3(0.5, 0.66, 0.6))
	# Neck + head
	neck = Node3D.new()
	neck.position = Vector3(0, 1.15, -0.62)
	root.add_child(neck)
	_part(neck, cap, coat, Vector3(0, 0.25, -0.1), Vector3(deg_to_rad(-30), 0, 0), Vector3(0.24, 0.3, 0.24))
	var head := Node3D.new()
	head.position = Vector3(0, 0.55, -0.28)
	neck.add_child(head)
	_part(head, sphere, coat, Vector3(0, 0, 0), Vector3.ZERO, Vector3(0.22, 0.22, 0.3))
	_part(head, sphere, coat, Vector3(0, -0.04, -0.2), Vector3(deg_to_rad(10), 0, 0), Vector3(0.13, 0.13, 0.28))
	_part(head, sphere, dark, Vector3(0, -0.05, -0.34), Vector3.ZERO, Vector3(0.07, 0.06, 0.05))
	_part(head, sphere, dark, Vector3(0.09, 0.04, -0.08), Vector3.ZERO, Vector3(0.035, 0.035, 0.035))
	_part(head, sphere, dark, Vector3(-0.09, 0.04, -0.08), Vector3.ZERO, Vector3(0.035, 0.035, 0.035))
	for sx in [-1, 1]:
		_part(head, sphere, coat, Vector3(0.12 * sx, 0.14, 0.05), Vector3(0, 0, deg_to_rad(-40 * sx)), Vector3(0.05, 0.16, 0.03))
	if gender == "Male":
		_build_antlers(head, bone)
	# Legs
	var leg_mesh := CylinderMesh.new(); leg_mesh.top_radius = 0.05; leg_mesh.bottom_radius = 0.028; leg_mesh.height = 0.95; leg_mesh.radial_segments = 6
	for p in [Vector3(0.14, 0.95, -0.52), Vector3(-0.14, 0.95, -0.52), Vector3(0.14, 0.97, 0.5), Vector3(-0.14, 0.97, 0.5)]:
		var hip := Node3D.new()
		hip.position = p
		root.add_child(hip)
		_part(hip, leg_mesh, coat, Vector3(0, -0.47, 0))
		_part(hip, sphere, dark, Vector3(0, -0.93, -0.02), Vector3.ZERO, Vector3(0.06, 0.05, 0.08))
		if p.z > 0:
			_part(hip, sphere, coat, Vector3(0, -0.05, 0.02), Vector3.ZERO, Vector3(0.2, 0.32, 0.26))
		legs.append(hip)
	tail = Node3D.new()
	tail.position = Vector3(0, 1.15, 0.75)
	root.add_child(tail)
	_part(tail, sphere, coat, Vector3(0, -0.08, 0.04), Vector3.ZERO, Vector3(0.09, 0.18, 0.05))
	_part(tail, sphere, belly, Vector3(0, -0.08, 0.07), Vector3.ZERO, Vector3(0.08, 0.16, 0.03))
	return root

func _build_antlers(head: Node3D, mat: Material) -> void:
	var tine := CylinderMesh.new(); tine.top_radius = 0.008; tine.bottom_radius = 0.022; tine.height = 1.0; tine.radial_segments = 5
	var per_side: int = int(antler_points / 2.0)
	for sx in [-1, 1]:
		var base := Node3D.new()
		base.position = Vector3(0.07 * sx, 0.14, 0.0)
		base.rotation = Vector3(deg_to_rad(-25), 0, deg_to_rad(-35 * sx))
		head.add_child(base)
		# Main beam: three segments curving forward
		var seg_root := base
		for i in 3:
			_part(seg_root, tine, mat, Vector3(0, 0.12, 0), Vector3.ZERO, Vector3(1, 0.24, 1))
			var nxt := Node3D.new()
			nxt.position = Vector3(0, 0.23, 0)
			nxt.rotation = Vector3(deg_to_rad(-30), 0, deg_to_rad(25 * sx))
			seg_root.add_child(nxt)
			seg_root = nxt
		# Tines
		for t in per_side - 1:
			var tn := Node3D.new()
			tn.position = Vector3(0.05 * sx * t, 0.18 + t * 0.07, -0.04 * t)
			tn.rotation = Vector3(deg_to_rad(-10), 0, deg_to_rad(10 * sx))
			base.add_child(tn)
			_part(tn, tine, mat, Vector3(0, 0.08, 0), Vector3.ZERO, Vector3(0.8, 0.17, 0.8))

func _animate(delta: float) -> void:
	phase += delta * (speed * (2.6 if speed > 4.0 else 3.2) + 0.0)
	var amp: float = clamp(speed / 2.0, 0.0, 1.0) * (0.75 if speed > 4.0 else 0.4)
	var offsets := [0.0, PI, PI * 0.5, PI * 1.5] if speed <= 4.0 else [0.0, 0.3, PI, PI + 0.3]
	for i in legs.size():
		legs[i].rotation.x = sin(phase + offsets[i]) * amp
	var bob: float = abs(sin(phase)) * 0.08 * clamp(speed / run_speed, 0.0, 1.0)
	model.position.y = bob
	var neck_target := 0.0
	match state:
		State.GRAZE: neck_target = deg_to_rad(95)
		State.ALERT: neck_target = deg_to_rad(-12)
		State.FLEE, State.WOUNDED: neck_target = deg_to_rad(20)
	neck.rotation.x = lerp_angle(neck.rotation.x, neck_target, delta * 3.0)
	var tail_up := state == State.FLEE or state == State.ALERT
	tail.rotation.x = lerp_angle(tail.rotation.x, deg_to_rad(-110) if tail_up else 0.0, delta * 6.0)

func _on_death() -> void:
	model.position.y = 0.25
	model.rotation.z = deg_to_rad(80)
	for l in legs:
		l.rotation.x = randf_range(-0.4, 0.4)
	neck.rotation.x = deg_to_rad(40)
