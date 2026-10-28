class_name DogModelBuilder
extends RefCounted

## Builds a 3D Golden Retriever / Hunting Dog model with movable head, tail, and legs.

static func build_retriever_model() -> Node3D:
	var root := Node3D.new()
	root.name = "RetrieverDogVisual"
	
	var mat_fur := StandardMaterial3D.new()
	mat_fur.albedo_color = Color(0.76, 0.52, 0.28) # Warm golden-amber retriever coat
	mat_fur.roughness = 0.8
	
	var mat_chest := StandardMaterial3D.new()
	mat_chest.albedo_color = Color(0.85, 0.68, 0.44) # Lighter cream chest & bib
	mat_chest.roughness = 0.85
	
	var mat_collar := StandardMaterial3D.new()
	mat_collar.albedo_color = Color(0.85, 0.22, 0.15) # Red leather field collar with brass tag
	mat_collar.roughness = 0.6
	
	var mat_tag := StandardMaterial3D.new()
	mat_tag.albedo_color = Color(0.95, 0.82, 0.25) # Brass tag
	mat_tag.metallic = 0.8
	
	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.10, 0.08, 0.06) # Nose, dark eyes, foot pads
	mat_dark.roughness = 0.5
	
	var box := BoxMesh.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 4
	
	# 1. Torso / Ribcage
	var torso := MeshInstance3D.new()
	torso.mesh = box
	torso.scale = Vector3(0.38, 0.44, 0.72)
	torso.position = Vector3(0, 0.48, 0)
	torso.material_override = mat_fur
	root.add_child(torso)
	
	# 2. Chest / Shoulders & Cream Bib
	var chest := MeshInstance3D.new()
	chest.mesh = box
	chest.scale = Vector3(0.36, 0.42, 0.32)
	chest.position = Vector3(0, 0.52, -0.32)
	chest.material_override = mat_chest
	root.add_child(chest)
	
	# Red Leather Hunting Collar
	var collar := MeshInstance3D.new()
	collar.mesh = box
	collar.scale = Vector3(0.30, 0.10, 0.24)
	collar.position = Vector3(0, 0.64, -0.42)
	collar.material_override = mat_collar
	root.add_child(collar)
	
	var tag := MeshInstance3D.new()
	tag.mesh = box
	tag.scale = Vector3(0.06, 0.07, 0.03)
	tag.position = Vector3(0, 0.59, -0.55)
	tag.material_override = mat_tag
	root.add_child(tag)
	
	# 3. Head & Snout (Child of Neck for rotation)
	var neck := Node3D.new()
	neck.name = "Neck"
	neck.position = Vector3(0, 0.62, -0.42)
	root.add_child(neck)
	
	var head := MeshInstance3D.new()
	head.name = "HeadMesh"
	head.mesh = box
	head.scale = Vector3(0.24, 0.24, 0.3)
	head.position = Vector3(0, 0.14, -0.12)
	head.material_override = mat_fur
	neck.add_child(head)
	
	# Muzzle
	var snout := MeshInstance3D.new()
	snout.name = "Muzzle"
	snout.mesh = box
	snout.scale = Vector3(0.16, 0.14, 0.22)
	snout.position = Vector3(0, 0.08, -0.32)
	snout.material_override = mat_fur
	neck.add_child(snout)
	
	# Nose tip
	var nose := MeshInstance3D.new()
	nose.mesh = sphere
	nose.scale = Vector3(0.06, 0.05, 0.06)
	nose.position = Vector3(0, 0.12, -0.44)
	nose.material_override = mat_dark
	neck.add_child(nose)
	
	# Floppy Ears
	for sx in [-1, 1]:
		var ear := MeshInstance3D.new()
		ear.mesh = box
		ear.scale = Vector3(0.06, 0.22, 0.12)
		ear.position = Vector3(0.14 * sx, 0.12, -0.1)
		ear.rotation.z = deg_to_rad(15 * sx)
		ear.material_override = mat_fur
		neck.add_child(ear)
		
	# 4. Tail
	var tail := MeshInstance3D.new()
	tail.name = "Tail"
	tail.mesh = box
	tail.scale = Vector3(0.08, 0.08, 0.42)
	tail.position = Vector3(0, 0.58, 0.48)
	tail.rotation.x = deg_to_rad(35)
	tail.material_override = mat_fur
	root.add_child(tail)
	
	# 5. Four Legs
	var leg_coords := [
		Vector3(-0.14, 0.24, -0.28), # Front Left
		Vector3(0.14, 0.24, -0.28),  # Front Right
		Vector3(-0.14, 0.24, 0.28),  # Back Left
		Vector3(0.14, 0.24, 0.28)   # Back Right
	]
	for i in leg_coords.size():
		var leg := MeshInstance3D.new()
		leg.name = "Leg_%d" % i
		leg.mesh = box
		leg.scale = Vector3(0.11, 0.48, 0.13)
		leg.position = leg_coords[i]
		leg.material_override = mat_fur
		root.add_child(leg)

	return root
