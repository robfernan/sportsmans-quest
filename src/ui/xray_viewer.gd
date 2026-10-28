class_name XrayViewer
extends SubViewportContainer

## Real-Time 3D Ballistic X-Ray Viewer (theHunter Classic Style)
## Renders a transparent holographic wireframe/glass animal model with organ hitboxes
## and a glowing red 3D trajectory line tracing entry wound, organ cavity, and exit wound.

var _subviewport: SubViewport
var _camera: Camera3D
var _pivot: Node3D
var _rot_speed: float = 0.45

func _init() -> void:
	custom_minimum_size = Vector2(280, 240)
	stretch = true
	
	_subviewport = SubViewport.new()
	_subviewport.size = Vector2i(280, 240)
	_subviewport.transparent_bg = true
	_subviewport.msaa_3d = Viewport.MSAA_DISABLED
	add_child(_subviewport)
	
	_pivot = Node3D.new()
	_subviewport.add_child(_pivot)
	
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 0.4, 2.2)
	_subviewport.add_child(_camera)
	
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-45), deg_to_rad(35), 0)
	light.light_energy = 1.4
	light.light_color = Color(0.85, 0.92, 1.0)
	_subviewport.add_child(light)

func build_xray(species_name: String, hit_organ: String) -> void:
	for c in _pivot.get_children():
		c.queue_free()
		
	var mat_glass := StandardMaterial3D.new()
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.albedo_color = Color(0.2, 0.4, 0.6, 0.28)
	mat_glass.metallic = 0.5
	mat_glass.roughness = 0.2
	
	var mat_vital := StandardMaterial3D.new()
	mat_vital.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_vital.albedo_color = Color(0.95, 0.25, 0.15, 0.85)
	mat_vital.emission_enabled = true
	mat_vital.emission = Color(0.95, 0.2, 0.1)
	mat_vital.emission_energy_multiplier = 1.2
	
	var mat_organ := StandardMaterial3D.new()
	mat_organ.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_organ.albedo_color = Color(0.35, 0.55, 0.75, 0.6)
	
	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 6
	
	var cylinder := CylinderMesh.new()
	cylinder.radial_segments = 8
	
	# Transparent Ghost Silhouette
	var body := MeshInstance3D.new()
	body.mesh = sphere
	body.material_override = mat_glass
	
	if species_name.contains("Mallard"):
		body.scale = Vector3(0.35, 0.28, 0.55)
		_pivot.add_child(body)
		
		# Vitals
		var heart := MeshInstance3D.new()
		heart.mesh = sphere
		heart.scale = Vector3(0.12, 0.12, 0.14)
		heart.position = Vector3(0, 0.05, 0)
		heart.material_override = mat_vital if hit_organ.contains("Heart") else mat_organ
		_pivot.add_child(heart)
		
		# Trajectory laser
		var traj := MeshInstance3D.new()
		traj.mesh = cylinder
		traj.scale = Vector3(0.015, 0.65, 0.015)
		traj.rotation.x = deg_to_rad(85)
		traj.position = Vector3(0, 0.05, 0)
		traj.material_override = mat_vital
		_pivot.add_child(traj)
	else:
		# Whitetail Deer silhouette
		body.scale = Vector3(0.55, 0.65, 1.2)
		body.position = Vector3(0, 0.2, 0)
		_pivot.add_child(body)
		
		# Spine
		var spine := MeshInstance3D.new()
		spine.mesh = cylinder
		spine.scale = Vector3(0.04, 0.95, 0.04)
		spine.rotation.x = deg_to_rad(90)
		spine.position = Vector3(0, 0.55, 0)
		spine.material_override = mat_vital if hit_organ.contains("Spine") else mat_organ
		_pivot.add_child(spine)
		
		# Heart & Lungs
		var heart := MeshInstance3D.new()
		heart.mesh = sphere
		heart.scale = Vector3(0.16, 0.18, 0.22)
		heart.position = Vector3(0, 0.18, -0.15)
		heart.material_override = mat_vital if hit_organ.contains("Heart") else mat_organ
		_pivot.add_child(heart)
		
		var lungs := MeshInstance3D.new()
		lungs.mesh = sphere
		lungs.scale = Vector3(0.24, 0.26, 0.35)
		lungs.position = Vector3(0, 0.32, -0.05)
		lungs.material_override = mat_vital if hit_organ.contains("Lung") else mat_organ
		_pivot.add_child(lungs)
		
		# Glowing Wound Channel
		var wound_channel := MeshInstance3D.new()
		wound_channel.mesh = cylinder
		wound_channel.scale = Vector3(0.02, 0.85, 0.02)
		wound_channel.rotation.z = deg_to_rad(80)
		wound_channel.position = Vector3(0, 0.22, -0.12)
		wound_channel.material_override = mat_vital
		_pivot.add_child(wound_channel)

func _process(delta: float) -> void:
	if _pivot:
		_pivot.rotation.y += delta * _rot_speed
