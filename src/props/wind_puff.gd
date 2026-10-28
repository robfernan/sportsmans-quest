class_name WindPuff
extends GPUParticles3D

## Visual Talcum Wind Powder Indicator (Sportsman's Quest)
## Releases a white talcum powder cloud that drifts with local wind direction & velocity.

func _init() -> void:
	amount = 32
	lifetime = 3.0
	one_shot = true
	explosiveness = 0.85
	randomness = 0.4
	
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.08
	mat.direction = Vector3(0, 0.4, -0.6)
	mat.spread = 25.0
	mat.initial_velocity_min = 1.2
	mat.initial_velocity_max = 2.4
	mat.gravity = Vector3(0, -0.15, 0)
	mat.scale_min = 0.08
	mat.scale_max = 0.28
	
	# Color fade out
	var grad := Gradient.new()
	grad.set_color(0, Color(0.96, 0.96, 0.98, 0.85))
	grad.set_color(1, Color(0.96, 0.96, 0.98, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	mat.color_ramp = grad_tex
	
	process_material = mat
	
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 8
	sphere.rings = 4
	
	var pass_mat := StandardMaterial3D.new()
	pass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pass_mat.vertex_color_use_as_albedo = true
	pass_mat.albedo_color = Color(1, 1, 1, 0.7)
	sphere.material = pass_mat
	
	draw_pass_1 = sphere

func puff_wind(wind_vec: Vector3) -> void:
	var mat = process_material as ParticleProcessMaterial
	if mat:
		# Blend initial puff with ambient wind drift
		mat.gravity = Vector3(wind_vec.x * 0.85, -0.12, wind_vec.z * 0.85)
	restart()
	emitting = true
	
	# Auto remove after particles finish
	get_tree().create_timer(lifetime + 0.5).timeout.connect(queue_free)
