class_name GhostBuck
extends Animal

## Mythical Ghost Buck (Sportsman's Quest Halloween Special Event)
## Spectral translucent white stag with glowing crimson eyes, massive 14-point rack,
## leaves glowing phantom tracks, and grants the legendary "Phantom of Whispering Pines" trophy.

var legs: Array = []
var tail: Node3D
var neck: Node3D
var head_bone: Node3D
var anim_t := 0.0
var _phantom_light: OmniLight3D
var _chime_player: AudioStreamPlayer3D
var _chime_played := false
const _CHIME_RANGE_M := 80.0

func _setup_species() -> void:
	species = "Ghost Buck (Mythical)"
	gender = "Male"
	walk_speed = 2.2
	run_speed = 14.5
	sight_range = 140.0
	hearing_mult = 1.6
	scent_range = 300.0
	flee_time = 24.0
	weight_kg = 125.0
	trophy_score = 215.5 # Legendary Boone & Crockett
	trophy_label = "Spectral Trophy Score"
	call_type = "deer_call"
	
	hit_zones = [
		{"name": "Heart", "pos": Vector3(0, 0.72, -0.35), "r": 0.24},
		{"name": "Lungs", "pos": Vector3(0, 0.85, -0.15), "r": 0.32},
		{"name": "Spine", "pos": Vector3(0, 1.15, 0.1), "r": 0.14},
		{"name": "Brain", "pos": Vector3(0, 1.45, -0.95), "r": 0.12},
	]

func _build_model() -> Node3D:
	var root := Node3D.new()
	root.name = "GhostBuckModel"
	
	# Spectral Translucent Ghost Material
	var mat_ghost := StandardMaterial3D.new()
	mat_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_ghost.albedo_color = Color(0.88, 0.94, 1.0, 0.55) # Ethereal blue-white
	mat_ghost.emission_enabled = true
	mat_ghost.emission = Color(0.35, 0.65, 0.95)
	mat_ghost.emission_energy_multiplier = 0.8
	mat_ghost.roughness = 0.3
	
	# Blood Red Glowing Eyes
	var mat_eye := StandardMaterial3D.new()
	mat_eye.albedo_color = Color(1.0, 0.1, 0.1)
	mat_eye.emission_enabled = true
	mat_eye.emission = Color(1.0, 0.15, 0.05)
	mat_eye.emission_energy_multiplier = 4.0

	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 6
	
	var box := BoxMesh.new()
	
	# Body
	var body := MeshInstance3D.new()
	body.mesh = sphere
	body.scale = Vector3(0.58, 0.72, 1.35)
	body.position = Vector3(0, 0.88, 0)
	body.material_override = mat_ghost
	root.add_child(body)

	# Neck & Head
	neck = Node3D.new()
	neck.position = Vector3(0, 0.95, -0.55)
	root.add_child(neck)

	head_bone = Node3D.new()
	head_bone.position = Vector3(0, 0.45, -0.35)
	neck.add_child(head_bone)

	var head_m := MeshInstance3D.new()
	head_m.mesh = sphere
	head_m.scale = Vector3(0.24, 0.28, 0.45)
	head_m.material_override = mat_ghost
	head_bone.add_child(head_m)

	# Glowing Red Eyes
	for sx in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.mesh = box
		eye.scale = Vector3(0.04, 0.04, 0.06)
		eye.position = Vector3(0.12 * sx, 0.08, -0.16)
		eye.material_override = mat_eye
		head_bone.add_child(eye)

	# Massive 14-Point Antler Rack
	var antler_mat := StandardMaterial3D.new()
	antler_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	antler_mat.albedo_color = Color(0.95, 0.98, 1.0, 0.7)
	antler_mat.emission_enabled = true
	antler_mat.emission = Color(0.5, 0.8, 1.0)
	antler_mat.emission_energy_multiplier = 1.2

	var cyl := CylinderMesh.new()
	cyl.radial_segments = 5
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.035
	cyl.height = 0.85

	for sx in [-1, 1]:
		var beam := MeshInstance3D.new()
		beam.mesh = cyl
		beam.position = Vector3(0.18 * sx, 0.35, -0.05)
		beam.rotation = Vector3(deg_to_rad(-25), 0, deg_to_rad(-35 * sx))
		beam.material_override = antler_mat
		head_bone.add_child(beam)
		
		# Tines
		for t in 3:
			var tine := MeshInstance3D.new()
			tine.mesh = cyl
			tine.scale = Vector3(0.5, 0.45, 0.5)
			tine.position = Vector3(0.24 * sx + (t * 0.08 * sx), 0.45 + (t * 0.12), -0.08 + (t * 0.06))
			tine.rotation = Vector3(deg_to_rad(20), 0, deg_to_rad(15 * sx))
			tine.material_override = antler_mat
			head_bone.add_child(tine)

	# 4 Ghost Legs
	var leg_coords = [
		Vector3(-0.16, 0.42, -0.42),
		Vector3(0.16, 0.42, -0.42),
		Vector3(-0.16, 0.42, 0.42),
		Vector3(0.16, 0.42, 0.42),
	]
	for p in leg_coords:
		var leg := MeshInstance3D.new()
		leg.mesh = box
		leg.scale = Vector3(0.11, 0.85, 0.13)
		leg.position = p
		leg.material_override = mat_ghost
		root.add_child(leg)
		legs.append(leg)

	# Spectral Ambient Glow
	_phantom_light = OmniLight3D.new()
	_phantom_light.position = Vector3(0, 0.9, 0)
	_phantom_light.light_color = Color(0.4, 0.75, 1.0)
	_phantom_light.light_energy = 2.2
	_phantom_light.omni_range = 9.0
	root.add_child(_phantom_light)

	return root

func _animate(delta: float) -> void:
	_maybe_chime()
	if state == State.DEAD:
		return
	if speed > 0.2:
		anim_t += delta * (speed * 2.8)
		if legs.size() == 4:
			legs[0].rotation.x = sin(anim_t) * 0.5
			legs[1].rotation.x = -sin(anim_t) * 0.5
			legs[2].rotation.x = -sin(anim_t) * 0.5
			legs[3].rotation.x = sin(anim_t) * 0.5
	else:
		if legs.size() == 4:
			for l in legs:
				l.rotation.x = move_toward(l.rotation.x, 0.0, delta * 3.0)

func _maybe_chime() -> void:
	if _chime_played or world == null or world.hunter == null:
		return
	if global_position.distance_to(world.hunter.global_position) > _CHIME_RANGE_M:
		return
	_chime_played = true
	if _chime_player == null:
		_chime_player = AudioStreamPlayer3D.new()
		_chime_player.bus = AudioDirector.BUS_SFX
		_chime_player.stream = AudioSynth.take_ghost_chime()
		_chime_player.unit_size = 16.0
		_chime_player.max_distance = 110.0
		_chime_player.volume_db = -6.0
		add_child(_chime_player)
	_chime_player.pitch_scale = AudioSynth.vary_pitch(0.98, 1.03)
	_chime_player.play()
