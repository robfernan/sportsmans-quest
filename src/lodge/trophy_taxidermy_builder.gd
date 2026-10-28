class_name TrophyTaxidermyBuilder
extends RefCounted

## Builds full 3D taxidermy mounts and shoulder pedestals for the Trophy Lodge.
## 100% Procedural geometry (0 KB textures, 0 KB external files).

static func build_taxidermy_mount(species: String, score: float, gender: String) -> Node3D:
	var mount := Node3D.new()
	mount.name = "Taxidermy_" + species.replace(" ", "_")
	
	match species:
		"Whitetail Deer":
			_build_deer_shoulder_mount(mount, score, gender == "Male")
		"Ghost Buck (Mythical)":
			_build_ghost_buck_mount(mount, score)
		"Red Fox":
			_build_fox_pedestal(mount)
		"Mallard":
			_build_duck_flight_mount(mount)
		"Werewolf":
			_build_werewolf_head_mount(mount)
		"Wendigo (Cryptid)":
			_build_wendigo_skull_mount(mount)
		_:
			_build_deer_shoulder_mount(mount, score, true)
			
	return mount

static func _build_deer_shoulder_mount(parent: Node3D, score: float, is_buck: bool) -> void:
	var sphere := SphereMesh.new(); sphere.radial_segments = 10; sphere.rings = 5
	var cap := CapsuleMesh.new(); cap.radius = 0.25; cap.height = 0.8; cap.radial_segments = 8; cap.rings = 3
	
	var mat_fur := StandardMaterial3D.new()
	mat_fur.albedo_color = Color(0.48, 0.33, 0.21)
	mat_fur.roughness = 0.85
	
	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.1, 0.08, 0.07)
	
	var mat_bone := StandardMaterial3D.new()
	mat_bone.albedo_color = Color(0.82, 0.76, 0.64)
	mat_bone.roughness = 0.6
	
	# Swelling Neck emerging from wall shield
	var neck := MeshInstance3D.new()
	neck.mesh = cap
	neck.scale = Vector3(0.5, 0.65, 0.5)
	neck.position = Vector3(0.25, 0, 0)
	neck.rotation = Vector3(0, 0, deg_to_rad(-65))
	neck.material_override = mat_fur
	parent.add_child(neck)
	
	# Head
	var head := MeshInstance3D.new()
	head.mesh = sphere
	head.scale = Vector3(0.26, 0.24, 0.35)
	head.position = Vector3(0.55, 0.15, 0)
	head.rotation.y = deg_to_rad(20) # Alert natural turn toward lodge floor
	head.material_override = mat_fur
	parent.add_child(head)
	
	# Snout & Nose
	var snout := MeshInstance3D.new()
	snout.mesh = sphere
	snout.scale = Vector3(0.13, 0.12, 0.25)
	snout.position = Vector3(0.72, 0.11, 0.06)
	snout.material_override = mat_fur
	parent.add_child(snout)
	
	var nose := MeshInstance3D.new()
	nose.mesh = sphere
	nose.scale = Vector3(0.06, 0.05, 0.06)
	nose.position = Vector3(0.85, 0.10, 0.11)
	nose.material_override = mat_dark
	parent.add_child(nose)
	
	# Ears
	for sx in [-1, 1]:
		var ear := MeshInstance3D.new()
		ear.mesh = sphere
		ear.scale = Vector3(0.05, 0.18, 0.08)
		ear.position = Vector3(0.48, 0.32, 0.12 * sx)
		ear.rotation = Vector3(0, 0, deg_to_rad(-25))
		ear.material_override = mat_fur
		parent.add_child(ear)
		
	# Antlers for Bucks
	if is_buck:
		var tine_mesh := CylinderMesh.new()
		tine_mesh.top_radius = 0.008; tine_mesh.bottom_radius = 0.024; tine_mesh.height = 0.45; tine_mesh.radial_segments = 5
		for sx in [-1, 1]:
			var antler := MeshInstance3D.new()
			antler.mesh = tine_mesh
			antler.scale = Vector3(1.0, 1.0 + (score / 200.0) * 0.4, 1.0)
			antler.position = Vector3(0.52, 0.42, 0.14 * sx)
			antler.rotation = Vector3(deg_to_rad(20 * sx), 0, deg_to_rad(-25))
			antler.material_override = mat_bone
			parent.add_child(antler)

static func _build_ghost_buck_mount(parent: Node3D, score: float) -> void:
	_build_deer_shoulder_mount(parent, score, true)
	# Apply ethereal translucent glowing overlay
	var mat_ghost := StandardMaterial3D.new()
	mat_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_ghost.albedo_color = Color(0.85, 0.95, 1.0, 0.7)
	mat_ghost.emission_enabled = true
	mat_ghost.emission = Color(0.3, 0.7, 1.0)
	mat_ghost.emission_energy_multiplier = 0.9
	
	for child in parent.get_children():
		if child is MeshInstance3D:
			child.material_override = mat_ghost

static func _build_fox_pedestal(parent: Node3D) -> void:
	var box := BoxMesh.new()
	var sphere := SphereMesh.new(); sphere.radial_segments = 8; sphere.rings = 4
	
	var mat_red := StandardMaterial3D.new(); mat_red.albedo_color = Color(0.85, 0.38, 0.12)
	var mat_white := StandardMaterial3D.new(); mat_white.albedo_color = Color(0.95, 0.92, 0.88)
	var mat_dark := StandardMaterial3D.new(); mat_dark.albedo_color = Color(0.12, 0.10, 0.08)
	
	var body := MeshInstance3D.new()
	body.mesh = sphere
	body.scale = Vector3(0.24, 0.22, 0.45)
	body.position = Vector3(0.35, 0.0, 0.0)
	body.material_override = mat_red
	parent.add_child(body)
	
	var head := MeshInstance3D.new()
	head.mesh = box
	head.scale = Vector3(0.16, 0.16, 0.22)
	head.position = Vector3(0.55, 0.12, 0.0)
	head.material_override = mat_red
	parent.add_child(head)
	
	var tail := MeshInstance3D.new()
	tail.mesh = box
	tail.scale = Vector3(0.10, 0.12, 0.42)
	tail.position = Vector3(0.15, -0.15, 0.12)
	tail.rotation.x = deg_to_rad(40)
	tail.material_override = mat_white
	parent.add_child(tail)

static func _build_duck_flight_mount(parent: Node3D) -> void:
	var sphere := SphereMesh.new(); sphere.radial_segments = 8; sphere.rings = 4
	var box := BoxMesh.new()
	
	var mat_d := StandardMaterial3D.new(); mat_d.albedo_color = Color(0.52, 0.48, 0.40)
	var mat_head := StandardMaterial3D.new(); mat_head.albedo_color = Color(0.06, 0.40, 0.18)
	var mat_wing := StandardMaterial3D.new(); mat_wing.albedo_color = Color(0.38, 0.32, 0.26)
	
	var body := MeshInstance3D.new()
	body.mesh = sphere
	body.scale = Vector3(0.20, 0.16, 0.36)
	body.position = Vector3(0.35, 0, 0)
	body.material_override = mat_d
	parent.add_child(body)
	
	var head := MeshInstance3D.new()
	head.mesh = sphere
	head.scale = Vector3(0.11, 0.11, 0.14)
	head.position = Vector3(0.52, 0.12, 0)
	head.material_override = mat_head
	parent.add_child(head)
	
	# Outstretched Cupped Wings
	for sx in [-1, 1]:
		var wing := MeshInstance3D.new()
		wing.mesh = box
		wing.scale = Vector3(0.42, 0.02, 0.18)
		wing.position = Vector3(0.35, 0.12, 0.28 * sx)
		wing.rotation.x = deg_to_rad(30 * sx)
		wing.material_override = mat_wing
		parent.add_child(wing)

static func _build_werewolf_head_mount(parent: Node3D) -> void:
	var box := BoxMesh.new()
	var mat_wolf := StandardMaterial3D.new(); mat_wolf.albedo_color = Color(0.16, 0.14, 0.13)
	var mat_eye := StandardMaterial3D.new()
	mat_eye.albedo_color = Color(1.0, 0.85, 0.15)
	mat_eye.emission_enabled = true
	mat_eye.emission = Color(1.0, 0.75, 0.05)
	mat_eye.emission_energy_multiplier = 1.2
	
	var head := MeshInstance3D.new()
	head.mesh = box
	head.scale = Vector3(0.34, 0.38, 0.42)
	head.position = Vector3(0.45, 0.05, 0)
	head.material_override = mat_wolf
	parent.add_child(head)
	
	var snout := MeshInstance3D.new()
	snout.mesh = box
	snout.scale = Vector3(0.24, 0.22, 0.35)
	snout.position = Vector3(0.68, 0.0, 0)
	snout.material_override = mat_wolf
	parent.add_child(snout)
	
	# Glowing Yellow Predator Eyes
	for sx in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.mesh = box
		eye.scale = Vector3(0.04, 0.06, 0.06)
		eye.position = Vector3(0.56, 0.16, 0.14 * sx)
		eye.material_override = mat_eye
		parent.add_child(eye)

static func _build_wendigo_skull_mount(parent: Node3D) -> void:
	var box := BoxMesh.new()
	var cylinder := CylinderMesh.new(); cylinder.top_radius = 0.01; cylinder.bottom_radius = 0.03; cylinder.height = 0.8
	
	var mat_skull := StandardMaterial3D.new(); mat_skull.albedo_color = Color(0.85, 0.82, 0.75); mat_skull.roughness = 0.9
	var mat_red := StandardMaterial3D.new(); mat_red.albedo_color = Color(1.0, 0.05, 0.05); mat_red.emission_enabled = true; mat_red.emission = Color(1.0, 0.0, 0.0); mat_red.emission_energy_multiplier = 1.5
	
	var skull := MeshInstance3D.new()
	skull.mesh = box
	skull.scale = Vector3(0.30, 0.35, 0.45)
	skull.position = Vector3(0.48, 0.05, 0)
	skull.material_override = mat_skull
	parent.add_child(skull)
	
	# Massive Demonic Antlers
	for sx in [-1, 1]:
		var horn := MeshInstance3D.new()
		horn.mesh = cylinder
		horn.position = Vector3(0.42, 0.45, 0.25 * sx)
		horn.rotation = Vector3(deg_to_rad(35 * sx), 0, deg_to_rad(-25))
		horn.material_override = mat_skull
		parent.add_child(horn)
		
	# Red Hollow Void Sockets
	for sx in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.mesh = box
		eye.scale = Vector3(0.05, 0.07, 0.07)
		eye.position = Vector3(0.60, 0.12, 0.12 * sx)
		eye.material_override = mat_red
		parent.add_child(eye)
