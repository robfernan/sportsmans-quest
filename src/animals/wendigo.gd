class_name Wendigo
extends Animal

## Cryptid Wendigo (Halloween Special Apex Beast)
## Tall gaunt 3-meter demonic entity with deer skull head, decaying ribs, elongated claws,
## roams in misty timber valleys, emits chilling screeches, and stalks the hunter relentlessly.

var arms: Array[MeshInstance3D] = []
var legs: Array[MeshInstance3D] = []
var anim_t: float = 0.0
var screech_timer: float = 8.0
var attack_cooldown: float = 0.0

func _setup_species() -> void:
	species = "Wendigo (Cryptid)"
	gender = "Unknown"
	walk_speed = 3.2
	run_speed = 15.2
	sight_range = 150.0
	hearing_mult = 2.0
	scent_range = 400.0
	flee_time = 4.0
	track_spacing = 3.8
	weight_kg = 195.0
	trophy_score = 280.0
	trophy_label = "Cryptid Skull Score"
	
	hit_zones = [
		{"name": "Heart", "pos": Vector3(0, 1.8, -0.15), "r": 0.20},
		{"name": "Spine", "pos": Vector3(0, 2.0, 0.1), "r": 0.16},
		{"name": "Brain", "pos": Vector3(0, 2.65, -0.3), "r": 0.18},
		{"name": "Flesh", "pos": Vector3(0, 1.5, 0), "r": 0.50},
	]

func _collision_shape() -> Shape3D:
	var b := BoxShape3D.new()
	b.size = Vector3(0.9, 2.9, 0.9)
	return b

func _collision_offset() -> Vector3:
	return Vector3(0, 1.45, 0)

func _build_model() -> Node3D:
	var root := Node3D.new()
	root.name = "WendigoModel"
	
	var mat_flesh := StandardMaterial3D.new()
	mat_flesh.albedo_color = Color(0.28, 0.30, 0.28) # Pale sickly ashen skin
	mat_flesh.roughness = 0.9
	
	var mat_bone := StandardMaterial3D.new()
	mat_bone.albedo_color = Color(0.88, 0.85, 0.74) # Aged bone white
	mat_bone.roughness = 0.7
	
	var mat_void := StandardMaterial3D.new()
	mat_void.albedo_color = Color(0.02, 0.02, 0.02) # Empty hollow eye sockets
	mat_void.emission_enabled = true
	mat_void.emission = Color(0.85, 0.1, 0.1) # Faint demonic red pinpricks
	mat_void.emission_energy_multiplier = 4.0

	var box := BoxMesh.new()
	var cyl := CylinderMesh.new()
	cyl.radial_segments = 6

	# 1. Gaunt 3-Meter Skeletal Torso & Exposed Spine
	var torso := MeshInstance3D.new()
	torso.mesh = box
	torso.scale = Vector3(0.52, 1.25, 0.35)
	torso.position = Vector3(0, 1.8, 0)
	torso.material_override = mat_flesh
	root.add_child(torso)
	
	# Exposed Ribcage
	for r in 4:
		var rib := MeshInstance3D.new()
		rib.mesh = box
		rib.scale = Vector3(0.58, 0.06, 0.38)
		rib.position = Vector3(0, 1.5 + (r * 0.18), 0.02)
		rib.material_override = mat_bone
		root.add_child(rib)

	# 2. Bleached Stag Skull Head
	var head := MeshInstance3D.new()
	head.mesh = box
	head.scale = Vector3(0.28, 0.38, 0.55)
	head.position = Vector3(0, 2.65, -0.25)
	head.rotation.x = deg_to_rad(15)
	head.material_override = mat_bone
	root.add_child(head)
	
	# Glowing Void Sockets
	for sx in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.mesh = box
		eye.scale = Vector3(0.04, 0.06, 0.04)
		eye.position = Vector3(0.10 * sx, 2.7, -0.45)
		eye.material_override = mat_void
		root.add_child(eye)

	# Corrupted Antlers
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.04
	cyl.height = 1.1
	for sx in [-1, 1]:
		var horn := MeshInstance3D.new()
		horn.mesh = cyl
		horn.position = Vector3(0.18 * sx, 3.1, -0.15)
		horn.rotation = Vector3(deg_to_rad(-25), 0, deg_to_rad(-40 * sx))
		horn.material_override = mat_bone
		root.add_child(horn)

	# 3. Elongated Spindly Clawed Arms
	for sx in [-1, 1]:
		var arm := MeshInstance3D.new()
		arm.name = "Arm_%d" % (1 if sx == 1 else 0)
		arm.mesh = box
		arm.scale = Vector3(0.12, 1.45, 0.14)
		arm.position = Vector3(0.38 * sx, 1.7, -0.1)
		arm.rotation.x = deg_to_rad(-15)
		arm.material_override = mat_flesh
		root.add_child(arm)
		arms.append(arm)

	# 4. Long Skeletal Legs
	for sx in [-1, 1]:
		var leg := MeshInstance3D.new()
		leg.name = "Leg_%d" % (1 if sx == 1 else 0)
		leg.mesh = box
		leg.scale = Vector3(0.15, 1.4, 0.16)
		leg.position = Vector3(0.18 * sx, 0.7, 0.05)
		leg.material_override = mat_flesh
		root.add_child(leg)
		legs.append(leg)

	return root

func _think(delta: float) -> void:
	if state == State.DEAD or world == null:
		return
		
	var hunter = world.hunter
	var d_to_hunter = global_position.distance_to(hunter.global_position)
	attack_cooldown -= delta
	screech_timer -= delta

	if screech_timer <= 0.0:
		screech_timer = randf_range(12.0, 25.0)
		if _snort_player:
			_snort_player.stream = AudioSynth.wendigo_screech()
			_snort_player.max_distance = 300.0
			_snort_player.unit_size = 20.0
			_snort_player.play()
		print("[HORROR] A blood-curdling screech echoes from the timber ridge...")

	if hunter.get("is_downed"):
		super._think(delta)
		return

	# Stalk in, then rush. Charging from 110 m removed the tell.
	const stalk_range := 80.0
	const rush_range := 18.0
	if d_to_hunter < stalk_range and state != State.WOUNDED:
		_face(hunter.global_position, delta * 4.0)
		if d_to_hunter < rush_range:
			state = State.FLEE
			flee_dir = (hunter.global_position - global_position).normalized()
			speed = run_speed
			_advance(-global_transform.basis.z, delta)
			if d_to_hunter < 3.2 and attack_cooldown <= 0.0:
				attack_cooldown = 1.6
				if hunter.has_method("take_damage"):
					hunter.take_damage(35.0)
				print("[LETHAL!] The Wendigo tore into the hunter with elongated bone claws!")
		else:
			state = State.ALERT
			speed = walk_speed
			_advance(-global_transform.basis.z, delta)
	else:
		super._think(delta)

func _animate(delta: float) -> void:
	if state == State.DEAD:
		return
	if speed > 0.5:
		anim_t += delta * (speed * 1.6)
		if arms.size() == 2:
			arms[0].rotation.x = sin(anim_t) * 0.8 - 0.2
			arms[1].rotation.x = -sin(anim_t) * 0.8 - 0.2
		if legs.size() == 2:
			legs[0].rotation.x = -sin(anim_t) * 0.7
			legs[1].rotation.x = sin(anim_t) * 0.7
