class_name Fox
extends Animal

## Red Fox: 100% Procedural Geometric Model (0 KB Textures, 0 KB External Files)
## Lightweight stalking predator with procedural leg trot and tail sway.

var legs: Array[MeshInstance3D] = []
var tail: MeshInstance3D
var walk_cycle: float = 0.0

func _setup_species() -> void:
	species = "Red Fox"
	gender = "Male" if randf() < 0.5 else "Female"
	walk_speed = 1.8
	run_speed = 13.5
	sight_range = 95.0
	hearing_mult = 1.3
	scent_range = 210.0
	flee_time = 14.0
	track_spacing = 2.4
	weight_kg = randf_range(4.5, 8.2)
	trophy_score = weight_kg * 2.0 + randf_range(0.0, 3.5)
	trophy_label = "Pelt Score"
	call_type = "predator"
	hit_zones = [
		{"name": "Heart", "pos": Vector3(0, 0.26, -0.15), "r": 0.12},
		{"name": "Lungs", "pos": Vector3(0, 0.31, -0.05), "r": 0.16},
		{"name": "Brain", "pos": Vector3(0, 0.42, -0.42), "r": 0.10},
		{"name": "Flesh", "pos": Vector3(0, 0.30, 0), "r": 0.28},
	]

func _collision_shape() -> Shape3D:
	var b := BoxShape3D.new()
	b.size = Vector3(0.35, 0.55, 1.0)
	return b

func _collision_offset() -> Vector3:
	return Vector3(0, 0.3, -0.1)

func _build_model() -> Node3D:
	var holder := Node3D.new()
	var mat_fur := StandardMaterial3D.new()
	mat_fur.albedo_color = Color(0.85, 0.38, 0.12) # Fox red/orange
	mat_fur.roughness = 0.85
	
	var mat_white := StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.92, 0.90, 0.85) # White bib and tail tip
	
	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.12, 0.10, 0.08) # Black stockings and ears
	
	var box := BoxMesh.new()
	
	# Torso
	var body := MeshInstance3D.new()
	body.mesh = box
	body.scale = Vector3(0.24, 0.26, 0.65)
	body.position = Vector3(0, 0.32, 0)
	body.material_override = mat_fur
	holder.add_child(body)
	
	# Chest / Bib (White)
	var bib := MeshInstance3D.new()
	bib.mesh = box
	bib.scale = Vector3(0.22, 0.24, 0.22)
	bib.position = Vector3(0, 0.34, -0.28)
	bib.material_override = mat_white
	holder.add_child(bib)

	# Head
	var head := MeshInstance3D.new()
	head.mesh = box
	head.scale = Vector3(0.18, 0.18, 0.24)
	head.position = Vector3(0, 0.44, -0.38)
	head.material_override = mat_fur
	holder.add_child(head)
	
	# Snout
	var snout := MeshInstance3D.new()
	snout.mesh = box
	snout.scale = Vector3(0.10, 0.09, 0.16)
	snout.position = Vector3(0, 0.41, -0.52)
	snout.material_override = mat_white
	holder.add_child(snout)
	
	# Bushy Tail
	tail = MeshInstance3D.new()
	tail.mesh = box
	tail.scale = Vector3(0.14, 0.14, 0.45)
	tail.position = Vector3(0, 0.38, 0.42)
	tail.rotation.x = deg_to_rad(25)
	tail.material_override = mat_fur
	holder.add_child(tail)
	
	# 4 Legs
	var leg_positions = [
		Vector3(-0.09, 0.16, -0.22), # Front Left
		Vector3(0.09, 0.16, -0.22),  # Front Right
		Vector3(-0.09, 0.16, 0.22),   # Back Left
		Vector3(0.09, 0.16, 0.22)    # Back Right
	]
	for p in leg_positions:
		var leg := MeshInstance3D.new()
		leg.mesh = box
		leg.scale = Vector3(0.07, 0.32, 0.08)
		leg.position = p
		leg.material_override = mat_dark
		holder.add_child(leg)
		legs.append(leg)
		
	return holder

func _animate(delta: float) -> void:
	if state == State.DEAD:
		return
	if speed > 0.2:
		walk_cycle += delta * (speed * 3.2)
		if legs.size() == 4:
			legs[0].rotation.x = sin(walk_cycle) * 0.45
			legs[1].rotation.x = -sin(walk_cycle) * 0.45
			legs[2].rotation.x = -sin(walk_cycle) * 0.45
			legs[3].rotation.x = sin(walk_cycle) * 0.45
		if tail:
			tail.rotation.y = sin(walk_cycle) * 0.35
	else:
		if legs.size() == 4:
			for l in legs:
				l.rotation.x = move_toward(l.rotation.x, 0.0, delta * 3.0)
