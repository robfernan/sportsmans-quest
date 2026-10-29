class_name Werewolf
extends Animal

## Apex Werewolf Predator (Halloween Special)
## Terrifying bipedal/quadrupedal beast with razor claws, piercing yellow eyes,
## hunts by human scent plume, leaps to attack the hunter, and takes heavy rifle/buckshot to stop.

var legs: Array[MeshInstance3D] = []
var arms: Array[MeshInstance3D] = []
var anim_cycle: float = 0.0
var attack_cooldown: float = 0.0
var howl_timer: float = 6.0
var _howl_player: AudioStreamPlayer3D

func _setup_species() -> void:
	species = "Werewolf"
	gender = "Male"
	walk_speed = 3.5
	run_speed = 13.8
	sight_range = 130.0
	hearing_mult = 1.8
	scent_range = 350.0
	flee_time = 5.0
	track_spacing = 3.2
	weight_kg = 165.0
	trophy_score = 240.0
	trophy_label = "Werewolf Pelt Score"
	
	hit_zones = [
		{"name": "Heart", "pos": Vector3(0, 1.1, -0.15), "r": 0.22},
		{"name": "Lungs", "pos": Vector3(0, 1.25, 0.0), "r": 0.28},
		{"name": "Brain", "pos": Vector3(0, 1.65, -0.35), "r": 0.16},
		{"name": "Flesh", "pos": Vector3(0, 1.0, 0), "r": 0.45},
	]

func _collision_shape() -> Shape3D:
	var b := BoxShape3D.new()
	b.size = Vector3(0.8, 1.9, 0.9)
	return b

func _collision_offset() -> Vector3:
	return Vector3(0, 1.0, 0)

func _build_model() -> Node3D:
	var root := Node3D.new()
	root.name = "WerewolfModel"
	
	var mat_fur := StandardMaterial3D.new()
	mat_fur.albedo_color = Color(0.18, 0.15, 0.14) # Midnight black/grey fur
	mat_fur.roughness = 0.9
	
	var mat_eyes := StandardMaterial3D.new()
	mat_eyes.albedo_color = Color(1.0, 0.85, 0.1) # Glowing feral amber/yellow
	mat_eyes.emission_enabled = true
	mat_eyes.emission = Color(1.0, 0.75, 0.05)
	mat_eyes.emission_energy_multiplier = 3.5

	var mat_claws := StandardMaterial3D.new()
	mat_claws.albedo_color = Color(0.85, 0.82, 0.78)
	
	var box := BoxMesh.new()
	
	# Massive muscular hunched torso
	var torso := MeshInstance3D.new()
	torso.mesh = box
	torso.scale = Vector3(0.68, 0.85, 0.48)
	torso.position = Vector3(0, 1.2, 0)
	torso.rotation.x = deg_to_rad(20) # Menacing forward hunch
	torso.material_override = mat_fur
	root.add_child(torso)
	
	# Wolf Snout & Head
	var head := MeshInstance3D.new()
	head.mesh = box
	head.scale = Vector3(0.32, 0.35, 0.42)
	head.position = Vector3(0, 1.68, -0.32)
	head.material_override = mat_fur
	root.add_child(head)
	
	var snout := MeshInstance3D.new()
	snout.mesh = box
	snout.scale = Vector3(0.18, 0.16, 0.35)
	snout.position = Vector3(0, 1.58, -0.62)
	snout.material_override = mat_fur
	root.add_child(snout)
	
	# Glowing Yellow Eyes
	for sx in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.mesh = box
		eye.scale = Vector3(0.05, 0.04, 0.04)
		eye.position = Vector3(0.11 * sx, 1.72, -0.48)
		eye.material_override = mat_eyes
		root.add_child(eye)
		
	# Pointed Wolf Ears
	for sx in [-1, 1]:
		var ear := MeshInstance3D.new()
		ear.mesh = box
		ear.scale = Vector3(0.06, 0.18, 0.08)
		ear.position = Vector3(0.14 * sx, 1.9, -0.22)
		ear.rotation.z = deg_to_rad(-18 * sx)
		ear.material_override = mat_fur
		root.add_child(ear)

	# Powerful Clawed Arms
	for sx in [-1, 1]:
		var arm := MeshInstance3D.new()
		arm.name = "Arm_%d" % (1 if sx == 1 else 0)
		arm.mesh = box
		arm.scale = Vector3(0.18, 0.95, 0.22)
		arm.position = Vector3(0.45 * sx, 1.15, -0.15)
		arm.rotation.x = deg_to_rad(-25)
		arm.material_override = mat_fur
		root.add_child(arm)
		arms.append(arm)

	# Digigrade Legs
	for sx in [-1, 1]:
		var leg := MeshInstance3D.new()
		leg.name = "Leg_%d" % (1 if sx == 1 else 0)
		leg.mesh = box
		leg.scale = Vector3(0.22, 0.95, 0.24)
		leg.position = Vector3(0.22 * sx, 0.5, 0.1)
		leg.material_override = mat_fur
		root.add_child(leg)
		legs.append(leg)

	return root

func _think(delta: float) -> void:
	if state == State.DEAD or world == null:
		return
		
	var hunter = world.hunter
	var d_to_hunter = global_position.distance_to(hunter.global_position)
	attack_cooldown -= delta
	howl_timer -= delta

	if howl_timer <= 0.0:
		howl_timer = randf_range(14.0, 28.0)
		if _howl_player == null:
			_howl_player = AudioStreamPlayer3D.new()
			_howl_player.bus = AudioDirector.BUS_SFX
			_howl_player.stream = AudioSynth.wolf_howl()
			_howl_player.max_distance = 250.0
			_howl_player.unit_size = 15.0
			add_child(_howl_player)
		_howl_player.play()
		print("[HOWL] A bloodcurdling wolf howl resonates through the hollow...")

	if hunter.get("is_downed"):
		super._think(delta)
		return

	# Close at a walk, then commit. A 95 m sprint left no time to stalk.
	const stalk_range := 70.0
	const rush_range := 16.0
	if d_to_hunter < stalk_range and state != State.WOUNDED:
		_face(hunter.global_position, delta * 4.0)
		if d_to_hunter < rush_range:
			state = State.FLEE
			flee_dir = (hunter.global_position - global_position).normalized()
			speed = run_speed
			_advance(-global_transform.basis.z, delta)
			if d_to_hunter < 2.5 and attack_cooldown <= 0.0:
				attack_cooldown = 1.4
				if hunter.has_method("take_damage"):
					hunter.take_damage(25.0)
				print("[DANGER!] Werewolf slashed the hunter with savage claws!")
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
		anim_cycle += delta * (speed * 1.8)
		if arms.size() == 2:
			arms[0].rotation.x = sin(anim_cycle) * 0.7 - 0.3
			arms[1].rotation.x = -sin(anim_cycle) * 0.7 - 0.3
		if legs.size() == 2:
			legs[0].rotation.x = -sin(anim_cycle) * 0.6
			legs[1].rotation.x = sin(anim_cycle) * 0.6
