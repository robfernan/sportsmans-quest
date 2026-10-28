class_name LandmarkBuilder
extends RefCounted

## Builds rustic procedural landmarks for Whispering Pines Reserve (0 KB external models).
## 1. High Wooden Ladder Hunting Stand (elevated shooting platform)
## 2. Shoreline Kayak Pier / Boat Dock
## 3. Abandoned Trapper's Cabin landmark

static func build_hunting_stand() -> Node3D:
	var root := Node3D.new()
	root.name = "HuntingStand"
	
	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.30, 0.20, 0.12) # Rough weathered timber
	mat_wood.roughness = 0.9
	
	var mat_floor := StandardMaterial3D.new()
	mat_floor.albedo_color = Color(0.24, 0.16, 0.10)
	mat_floor.roughness = 0.8
	
	var box := BoxMesh.new()
	
	# 4 Heavy Support Stilts (elevated 4.2m)
	var stilt_coords = [
		Vector3(-1.1, 2.1, -1.1),
		Vector3(1.1, 2.1, -1.1),
		Vector3(-1.1, 2.1, 1.1),
		Vector3(1.1, 2.1, 1.1),
	]
	for c in stilt_coords:
		var stilt := MeshInstance3D.new()
		stilt.mesh = box
		stilt.scale = Vector3(0.22, 4.2, 0.22)
		stilt.position = c
		stilt.material_override = mat_wood
		root.add_child(stilt)
		
	# Shooting Platform Floor (2.6m x 2.6m at 4.2m height)
	var platform := MeshInstance3D.new()
	platform.mesh = box
	platform.scale = Vector3(2.6, 0.2, 2.6)
	platform.position = Vector3(0, 4.2, 0)
	platform.material_override = mat_floor
	root.add_child(platform)
	
	# Wooden Waist Railings / Blind screen
	var rails = [
		[Vector3(2.6, 0.8, 0.12), Vector3(0, 4.7, -1.24)], # Front shooting rest
		[Vector3(0.12, 0.8, 2.6), Vector3(-1.24, 4.7, 0)], # Left rail
		[Vector3(0.12, 0.8, 2.6), Vector3(1.24, 4.7, 0)],  # Right rail
		[Vector3(1.4, 0.8, 0.12), Vector3(-0.6, 4.7, 1.24)], # Back rail (leaves ladder gap)
	]
	for r in rails:
		var rail := MeshInstance3D.new()
		rail.mesh = box
		rail.scale = r[0]
		rail.position = r[1]
		rail.material_override = mat_wood
		root.add_child(rail)
		
	# Ladder rungs & climbing collision
	for i in 8:
		var rung := MeshInstance3D.new()
		rung.mesh = box
		rung.scale = Vector3(0.7, 0.08, 0.12)
		rung.position = Vector3(0.6, 0.5 + float(i) * 0.46, 1.25)
		rung.material_override = mat_wood
		root.add_child(rung)
		
	# Static collision for platform floor
	var static_body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.6, 0.2, 2.6)
	col_shape.shape = box_shape
	static_body.position = Vector3(0, 4.2, 0)
	static_body.add_child(col_shape)
	root.add_child(static_body)

	# Interactive Stand Ladder (Press E to climb up / down)
	var ladder_area := Area3D.new()
	ladder_area.name = "StandLadderArea"
	ladder_area.position = Vector3(0.6, 2.1, 1.25)
	ladder_area.set_meta("interaction_type", "hunting_stand")
	ladder_area.set_meta("stand_root", root)
	var l_col := CollisionShape3D.new()
	var l_box := BoxShape3D.new()
	l_box.size = Vector3(1.6, 4.4, 1.6)
	l_col.shape = l_box
	ladder_area.add_child(l_col)
	root.add_child(ladder_area)
	
	return root

static func build_boat_dock() -> Node3D:
	var root := Node3D.new()
	root.name = "BoatDock"
	
	var mat_dock := StandardMaterial3D.new()
	mat_dock.albedo_color = Color(0.26, 0.19, 0.13) # Weathered lake pier planks
	mat_dock.roughness = 0.85
	
	var box := BoxMesh.new()
	
	# Dock Planks (Length 8m x Width 2.4m projecting into the lake)
	var deck := MeshInstance3D.new()
	deck.mesh = box
	deck.scale = Vector3(2.4, 0.24, 8.0)
	deck.position = Vector3(0, 0.12, 0)
	deck.material_override = mat_dock
	root.add_child(deck)
	
	# Dock Pilings in water
	for z in [-3.5, 0.0, 3.5]:
		for x in [-1.1, 1.1]:
			var pile := MeshInstance3D.new()
			pile.mesh = box
			pile.scale = Vector3(0.22, 2.5, 0.22)
			pile.position = Vector3(x, -0.9, z)
			pile.material_override = mat_dock
			root.add_child(pile)
			
	# Mooring Cleats / Tie-off Posts
	for x in [-1.1, 1.1]:
		var post := MeshInstance3D.new()
		post.mesh = box
		post.scale = Vector3(0.18, 0.55, 0.18)
		post.position = Vector3(x, 0.5, 3.8)
		post.material_override = mat_dock
		root.add_child(post)
		
	# Pier collision
	var static_body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.4, 0.24, 8.0)
	col_shape.shape = box_shape
	static_body.position = Vector3(0, 0.12, 0)
	static_body.add_child(col_shape)
	root.add_child(static_body)
	
	return root

static func build_trapper_cabin() -> Node3D:
	var root := Node3D.new()
	root.name = "TrapperCabin"
	
	var mat_log := StandardMaterial3D.new()
	mat_log.albedo_color = Color(0.22, 0.15, 0.10) # Dark aged cedar logs
	mat_log.roughness = 0.95
	
	var mat_roof := StandardMaterial3D.new()
	mat_roof.albedo_color = Color(0.35, 0.28, 0.22) # Weathered cedar shake roof
	mat_roof.roughness = 0.8
	
	var box := BoxMesh.new()
	
	# Cabin Walls (5.5m x 4.5m x 3.2m tall)
	var walls = [
		[Vector3(5.5, 3.0, 0.3), Vector3(0, 1.5, -2.1)], # Back wall
		[Vector3(1.8, 3.0, 0.3), Vector3(-1.8, 1.5, 2.1)], # Front left
		[Vector3(1.8, 3.0, 0.3), Vector3(1.8, 1.5, 2.1)],  # Front right (doorway in middle)
		[Vector3(0.3, 3.0, 4.5), Vector3(-2.6, 1.5, 0)], # Left wall
		[Vector3(0.3, 3.0, 4.5), Vector3(2.6, 1.5, 0)],  # Right wall
	]
	for w in walls:
		var wm := MeshInstance3D.new()
		wm.mesh = box
		wm.scale = w[0]
		wm.position = w[1]
		wm.material_override = mat_log
		root.add_child(wm)
		
		var col := StaticBody3D.new()
		var s := CollisionShape3D.new()
		var b := BoxShape3D.new(); b.size = w[0]
		s.shape = b
		col.position = w[1]
		col.add_child(s)
		root.add_child(col)
		
	# Overhanging Gable Roof
	for sx in [-1, 1]:
		var roof_panel := MeshInstance3D.new()
		roof_panel.mesh = box
		roof_panel.scale = Vector3(3.2, 0.15, 5.2)
		roof_panel.position = Vector3(1.4 * sx, 3.6, 0)
		roof_panel.rotation.z = deg_to_rad(-24 * sx)
		roof_panel.material_override = mat_roof
		root.add_child(roof_panel)
		
	# Rustic stone chimney
	var chimney := MeshInstance3D.new()
	chimney.mesh = box
	chimney.scale = Vector3(0.9, 4.5, 0.9)
	chimney.position = Vector3(2.6, 2.25, -1.0)
	var mat_stone := StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.28, 0.28, 0.30)
	chimney.material_override = mat_stone
	root.add_child(chimney)

	# Cabin Interior Floor & Shelter Area (Press E to rest / visit Trophy Lodge)
	var cabin_area := Area3D.new()
	cabin_area.name = "CabinDoorArea"
	cabin_area.position = Vector3(0, 1.2, 0)
	cabin_area.set_meta("interaction_type", "trapper_cabin")
	var c_col := CollisionShape3D.new()
	var c_box := BoxShape3D.new()
	c_box.size = Vector3(4.8, 2.8, 4.0)
	c_col.shape = c_box
	cabin_area.add_child(c_col)
	root.add_child(cabin_area)

	# Cabin Floor
	var floor_m := MeshInstance3D.new()
	floor_m.mesh = box
	floor_m.scale = Vector3(5.2, 0.15, 4.2)
	floor_m.position = Vector3(0, 0.08, 0)
	floor_m.material_override = mat_log
	root.add_child(floor_m)
	
	var floor_col := StaticBody3D.new()
	var fc_shape := CollisionShape3D.new()
	var fc_box := BoxShape3D.new()
	fc_box.size = Vector3(5.2, 0.15, 4.2)
	fc_shape.shape = fc_box
	floor_col.add_child(fc_shape)
	floor_col.position = Vector3(0, 0.08, 0)
	root.add_child(floor_col)

	# Warm cabin oil lantern inside
	var lantern_light := OmniLight3D.new()
	lantern_light.position = Vector3(0, 2.2, 0)
	lantern_light.light_color = Color(1.0, 0.72, 0.35)
	lantern_light.light_energy = 1.4
	lantern_light.omni_range = 7.0
	root.add_child(lantern_light)

	return root
