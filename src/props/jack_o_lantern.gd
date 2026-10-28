class_name JackOLantern
extends Node3D

## Spooky Glowing Jack-O'-Lantern (Halloween Special)
## Procedural carved pumpkin with flickering inner candle light.

func _ready() -> void:
	_build_pumpkin()

func _build_pumpkin() -> void:
	var mat_pumpkin := StandardMaterial3D.new()
	mat_pumpkin.albedo_color = Color(0.92, 0.45, 0.08) # Vivid pumpkin orange
	mat_pumpkin.roughness = 0.75
	
	var mat_stem := StandardMaterial3D.new()
	mat_stem.albedo_color = Color(0.24, 0.32, 0.12)
	
	var mat_glow := StandardMaterial3D.new()
	mat_glow.albedo_color = Color(1.0, 0.85, 0.2)
	mat_glow.emission_enabled = true
	mat_glow.emission = Color(1.0, 0.75, 0.1)
	mat_glow.emission_energy_multiplier = 2.5
	
	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 6
	
	var box := BoxMesh.new()
	
	# Ribbed pumpkin body (3 squashed intersecting spheres)
	for rot in [0.0, deg_to_rad(30), deg_to_rad(-30)]:
		var rib := MeshInstance3D.new()
		rib.mesh = sphere
		rib.scale = Vector3(0.55, 0.45, 0.52)
		rib.rotation.y = rot
		rib.material_override = mat_pumpkin
		add_child(rib)

	# Stem
	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.06
	cyl.height = 0.18
	stem.mesh = cyl
	stem.position = Vector3(0, 0.28, 0)
	stem.rotation.z = deg_to_rad(12)
	stem.material_override = mat_stem
	add_child(stem)

	# Carved Glowing Eyes (Triangles)
	for sx in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.mesh = box
		eye.scale = Vector3(0.08, 0.08, 0.04)
		eye.position = Vector3(0.14 * sx, 0.08, -0.26)
		eye.rotation.z = deg_to_rad(45 * sx)
		eye.material_override = mat_glow
		add_child(eye)
		
	# Carved Grinning Tooth Mouth
	var mouth := MeshInstance3D.new()
	mouth.mesh = box
	mouth.scale = Vector3(0.28, 0.06, 0.04)
	mouth.position = Vector3(0, -0.08, -0.26)
	mouth.material_override = mat_glow
	add_child(mouth)

	# Flickering candle point light (Shadows disabled for 60fps web performance)
	var candle := OmniLight3D.new()
	candle.name = "CandleLight"
	candle.position = Vector3(0, 0.02, -0.15)
	candle.light_color = Color(1.0, 0.65, 0.15)
	candle.light_energy = 1.6
	candle.omni_range = 5.0
	candle.shadow_enabled = false
	add_child(candle)

func _process(_delta: float) -> void:
	var l = get_node_or_null("CandleLight") as OmniLight3D
	if l:
		# Random candle flicker
		l.light_energy = 1.6 + sin(Time.get_ticks_msec() * 0.015) * 0.3 + (randf() * 0.15)
