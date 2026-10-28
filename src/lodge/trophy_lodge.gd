class_name TrophyLodge
extends Node3D

## Walkable 3D Trophy Lodge & Taxidermy Cabin (Sportsman's Quest)
## Features rustic pine log walls, stone hearth fireplace, wall mounts for whitetail deer antlers,
## waterfowl waterfowl pedastals, trophy ledger, and photo inspection camera.

@onready var exit_button: Button = $UI/ExitButton
@onready var lodge_info_label: Label = $UI/InfoLabel

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_cabin_geometry()
	_populate_harvested_trophies()
	
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _build_cabin_geometry() -> void:
	# Materials
	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.32, 0.20, 0.12)
	mat_wood.roughness = 0.8
	
	var mat_floor := StandardMaterial3D.new()
	mat_floor.albedo_color = Color(0.24, 0.16, 0.10)
	mat_floor.roughness = 0.6
	
	var mat_stone := StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.35, 0.35, 0.38)
	mat_stone.roughness = 0.9
	
	var box := BoxMesh.new()
	
	# Floor (16m x 12m)
	var floor_m := MeshInstance3D.new()
	floor_m.mesh = box
	floor_m.scale = Vector3(16.0, 0.2, 12.0)
	floor_m.position = Vector3(0, -0.1, 0)
	floor_m.material_override = mat_floor
	add_child(floor_m)
	
	var floor_col := StaticBody3D.new()
	var f_shape := CollisionShape3D.new()
	var f_box := BoxShape3D.new(); f_box.size = Vector3(16.0, 0.2, 12.0)
	f_shape.shape = f_box
	floor_col.add_child(f_shape)
	floor_col.position.y = -0.1
	add_child(floor_col)

	# Ceiling / Roof
	var ceil_m := MeshInstance3D.new()
	ceil_m.mesh = box
	ceil_m.scale = Vector3(16.0, 0.2, 12.0)
	ceil_m.position = Vector3(0, 4.2, 0)
	ceil_m.material_override = mat_wood
	add_child(ceil_m)

	# Walls (North, South, East, West)
	var walls = [
		[Vector3(16.0, 4.2, 0.3), Vector3(0, 2.1, -6.0)], # North (Fireplace wall)
		[Vector3(16.0, 4.2, 0.3), Vector3(0, 2.1, 6.0)],  # South
		[Vector3(0.3, 4.2, 12.0), Vector3(-8.0, 2.1, 0)], # West
		[Vector3(0.3, 4.2, 12.0), Vector3(8.0, 2.1, 0)],  # East
	]
	for w in walls:
		var wm := MeshInstance3D.new()
		wm.mesh = box
		wm.scale = w[0]
		wm.position = w[1]
		wm.material_override = mat_wood
		add_child(wm)
		
		var col := StaticBody3D.new()
		var s := CollisionShape3D.new()
		var b := BoxShape3D.new(); b.size = w[0]
		s.shape = b
		col.position = w[1]
		col.add_child(s)
		add_child(col)

	# Stone Fireplace (North Wall)
	var hearth := MeshInstance3D.new()
	hearth.mesh = box
	hearth.scale = Vector3(3.2, 3.6, 0.8)
	hearth.position = Vector3(0, 1.8, -5.6)
	hearth.material_override = mat_stone
	add_child(hearth)
	
	# Fireplace Light
	var fire_light := OmniLight3D.new()
	fire_light.position = Vector3(0, 1.0, -5.0)
	fire_light.light_color = Color(1.0, 0.65, 0.3)
	fire_light.light_energy = 2.4
	fire_light.omni_range = 10.0
	add_child(fire_light)
	
	# Warm Cabin Chandelier
	var chandelier := OmniLight3D.new()
	chandelier.position = Vector3(0, 3.5, 0)
	chandelier.light_color = Color(1.0, 0.88, 0.65)
	chandelier.light_energy = 1.8
	chandelier.omni_range = 14.0
	add_child(chandelier)

func _populate_harvested_trophies() -> void:
	var gs = get_node_or_null("/root/GameState")
	var trophies = gs.trophies if gs else []
	
	lodge_info_label.text = "OFFLINE TROPHY LODGE • CLAIMED HARVESTS: %d" % trophies.size()
	
	# Spawn wall mounts along the East and West walls
	var mount_x_positions = [-7.6, 7.6]
	var mount_z_positions = [-4.0, -2.0, 0.0, 2.0, 4.0]
	var slot_index = 0
	
	var box := BoxMesh.new()
	var mat_plaque := StandardMaterial3D.new()
	mat_plaque.albedo_color = Color(0.18, 0.10, 0.05)
	
	for record in trophies:
		if slot_index >= 10:
			break
		var wall_x = mount_x_positions[slot_index % 2]
		var wall_z = mount_z_positions[(slot_index / 2) % 5]
		slot_index += 1
		
		# Wooden Wall Shield Plaque
		var plaque := MeshInstance3D.new()
		plaque.mesh = box
		plaque.scale = Vector3(0.1, 0.7, 0.55)
		plaque.position = Vector3(wall_x, 2.2, wall_z)
		plaque.material_override = mat_plaque
		add_child(plaque)
		
		# Full 3D Taxidermy Mount mounted on the wall plaque
		var species_name: String = record.get("species_name", "Whitetail Deer")
		var score: float = float(record.get("trophy_score", 0.0))
		var gender: String = record.get("gender", "Male")
		
		var mount_3d = TrophyTaxidermyBuilder.build_taxidermy_mount(species_name, score, gender)
		mount_3d.position = Vector3(wall_x + (0.05 if wall_x < 0 else -0.05), 2.2, wall_z)
		mount_3d.rotation.y = deg_to_rad(90 if wall_x < 0 else -90)
		add_child(mount_3d)
		
		# Plaque 3D label
		var lbl := Label3D.new()
		var photo_note = record.get("trophy_photo", "No Photo")
		lbl.text = "🏆 %s\n%.1f PTS | %.1f kg\n📷 %s" % [
			species_name,
			score,
			record.get("weight_kg", 0.0),
			photo_note
		]
		lbl.font_size = 13
		lbl.position = Vector3(wall_x + (0.12 if wall_x < 0 else -0.12), 1.7, wall_z)
		lbl.rotation.y = deg_to_rad(90 if wall_x < 0 else -90)
		add_child(lbl)
		
		# Add miniature 3D trophy pedestal or framed photograph canvas on the wall
		var frame := MeshInstance3D.new()
		frame.mesh = box
		frame.scale = Vector3(0.04, 0.45, 0.6)
		frame.position = Vector3(wall_x + (0.05 if wall_x < 0 else -0.05), 1.15, wall_z)
		var mat_frame := StandardMaterial3D.new()
		mat_frame.albedo_color = Color(0.92, 0.90, 0.85) # Photo paper
		frame.material_override = mat_frame
		add_child(frame)
		
		var photo_lbl := Label3D.new()
		photo_lbl.text = "📸 FIELD PHOTO\n%s\n[Hunter & %s]" % [
			photo_note,
			species_name
		]
		photo_lbl.font_size = 11
		photo_lbl.modulate = Color(0.15, 0.12, 0.1)
		photo_lbl.position = Vector3(wall_x + (0.08 if wall_x < 0 else -0.08), 1.15, wall_z)
		photo_lbl.rotation.y = deg_to_rad(90 if wall_x < 0 else -90)
		add_child(photo_lbl)
