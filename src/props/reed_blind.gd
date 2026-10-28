class_name ReedBlind
extends Node3D

## Deployable Shoreline Reed Blind (Sportsman's Quest)
## Deployed with 'B'. Reduces hunter's visual profile by 85% when inside.

func _ready() -> void:
	_build_blind_mesh()

func _build_blind_mesh() -> void:
	var mat_reeds := StandardMaterial3D.new()
	mat_reeds.albedo_color = Color(0.42, 0.38, 0.22) # Dried marsh grass/reeds
	mat_reeds.roughness = 0.95
	
	var box := BoxMesh.new()
	
	# Left wall, Back wall, Right wall (U-shape shelter open towards lake)
	var walls = [
		[Vector3(0.08, 1.35, 1.4), Vector3(-0.7, 0.67, 0)], # Left
		[Vector3(0.08, 1.35, 1.4), Vector3(0.7, 0.67, 0)],  # Right
		[Vector3(1.4, 1.35, 0.08), Vector3(0, 0.67, 0.7)],  # Back
	]
	
	for w in walls:
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.scale = w[0]
		mi.position = w[1]
		mi.material_override = mat_reeds
		add_child(mi)
