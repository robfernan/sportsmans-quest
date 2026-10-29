class_name HarvestScreen
extends CanvasLayer

## Harvest Confirmation, Trophy Inspection & Trophy Photo Mode (Inspired by theHunter Classic)
## Displays shot analysis, hit organ, trophy score, harvest weight, and Trophy Photo Pose.

signal harvest_accepted(record: Dictionary)

@onready var panel: Panel = $Panel
@onready var species_title: Label = $Panel/VBoxContainer/SpeciesTitle
@onready var trophy_score_label: Label = $Panel/VBoxContainer/TrophyScore
@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var shot_details_label: Label = $Panel/VBoxContainer/ShotDetailsLabel
@onready var photo_btn: Button = $Panel/VBoxContainer/HBoxContainer/PhotoButton
@onready var accept_btn: Button = $Panel/VBoxContainer/HBoxContainer/AcceptButton

@onready var photo_flash: ColorRect = $PhotoFlash
@onready var photo_hud: Panel = $PhotoHUD
@onready var snap_photo_btn: Button = $PhotoHUD/HBox/SnapButton
@onready var done_photo_btn: Button = $PhotoHUD/HBox/DoneButton
@onready var pose_btn: Button = $PhotoHUD/HBox/PoseButton
@onready var cam_angle_btn: Button = $PhotoHUD/HBox/CamAngleButton

var current_record: Dictionary = {}
var target_animal: Node3D = null
var is_in_photo_mode: bool = false
var original_camera_transform: Transform3D
var hunter: HunterController = null
var photo_camera: Camera3D = null

# Poses: 0: Ground Kneel, 1: Ground Lounge, 2: Victory Thumbs-up, 3: Gun On Shoulder, 4: Stand Hero
var pose_names: Array[String] = [
	"🤸 POSE: KNEEL ON GROUND",
	"🏖️ POSE: GROUND LOUNGE",
	"👍 POSE: VICTORY THUMBS-UP",
	"🎯 POSE: GUN ON SHOULDER",
	"🏆 POSE: HERO STAND"
]
var pose_enums: Array = [
	HunterThirdPersonBuilder.Pose.GROUND_KNEEL,
	HunterThirdPersonBuilder.Pose.GROUND_LOUNGE,
	HunterThirdPersonBuilder.Pose.VICTORY_THUMBS_UP,
	HunterThirdPersonBuilder.Pose.GUN_ON_SHOULDER,
	HunterThirdPersonBuilder.Pose.STAND_HERO
]
var current_pose_idx: int = 0
var current_cam_angle_idx: int = 0
var photo_counter: int = 1

func _ready() -> void:
	visible = false
	if photo_hud:
		photo_hud.visible = false
	if photo_flash:
		photo_flash.visible = false
		
	if accept_btn:
		accept_btn.pressed.connect(_on_accept_pressed)
	if photo_btn:
		photo_btn.pressed.connect(_on_pose_photo_pressed)
	if snap_photo_btn:
		snap_photo_btn.pressed.connect(_on_snap_photo)
	if done_photo_btn:
		done_photo_btn.pressed.connect(_on_exit_photo_mode)
	if pose_btn:
		pose_btn.pressed.connect(_on_cycle_pose)
	if cam_angle_btn:
		cam_angle_btn.pressed.connect(_on_cycle_cam_angle)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_in_photo_mode:
			_on_exit_photo_mode()
		else:
			_on_accept_pressed()
		get_viewport().set_input_as_handled()

func show_harvest(record: Dictionary, animal: Node3D = null) -> void:
	current_record = record
	target_animal = animal
	hunter = get_tree().root.find_child("Hunter", true, false) as HunterController
	
	species_title.text = record.get("species_name", "Wild Game").to_upper()
	trophy_score_label.text = "%s: %.1f PTS" % [record.get("trophy_name", "Trophy Score"), record.get("trophy_score", 0.0)]
	
	stats_label.text = "Weight: %.1f kg  |  Gender: %s  |  Harvest Time: %s" % [
		record.get("weight_kg", 0.0),
		record.get("gender", "Male"),
		record.get("harvest_time", "08:15 AM")
	]
	
	shot_details_label.text = "WEAPON: %s\nHIT ORGAN: %s\nSHOT DISTANCE: %.1f METERS\nETHICS RATING: %d%%" % [
		record.get("weapon_used", "Hunting Rifle"),
		record.get("organ_hit", "Heart"),
		record.get("shot_distance_m", 0.0),
		int(record.get("harvest_quality", 0))
	]

	# Build or update live 3D Ballistic X-Ray view
	var xray = panel.get_node_or_null("XrayViewer")
	if not xray:
		xray = XrayViewer.new()
		xray.name = "XrayViewer"
		panel.add_child(xray)
		xray.position = Vector2(480, 50)
	xray.build_xray(record.get("species_name", "Game"), record.get("organ_hit", "Heart"))

	panel.visible = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if photo_btn:
		photo_btn.grab_focus()

func _on_pose_photo_pressed() -> void:
	# theHunter Classic Trophy Photo Pose Mode:
	# Hide harvest card, show 3D hunter model, position dedicated photo camera viewing hunter + harvest
	panel.visible = false
	photo_hud.visible = true
	is_in_photo_mode = true
	current_pose_idx = 0
	current_cam_angle_idx = 0
	
	if pose_btn:
		pose_btn.text = pose_names[current_pose_idx]
	
	if hunter and is_instance_valid(hunter):
		hunter.set_photo_mode_active(true)
		hunter.set_third_person_visible(true)
		hunter.set_photo_pose(pose_enums[current_pose_idx])
		_position_hunter_for_photo()
		
		# Create or activate a world-space photo camera focused on the hunter & harvest
		if not photo_camera:
			photo_camera = Camera3D.new()
			photo_camera.name = "TrophyPhotoCamera"
			get_tree().root.add_child(photo_camera)
		
		_update_photo_camera_transform()

func _position_hunter_for_photo() -> void:
	if not hunter or not is_instance_valid(hunter):
		return
	if target_animal and is_instance_valid(target_animal):
		var a_pos = target_animal.global_position
		var world = get_tree().root.find_child("Main", true, false)
		
		var animal_ground_y = a_pos.y
		if world and world.terrain:
			animal_ground_y = world.terrain.height_at(a_pos.x, a_pos.z)
			var n: Vector3 = world.terrain.normal_at(a_pos.x, a_pos.z)
			var sp_name = current_record.get("species_name", "")
			var animal_lift = 0.20
			if "Duck" in sp_name or "Mallard" in sp_name:
				animal_lift = 0.08
			elif "Fox" in sp_name:
				animal_lift = 0.16
			elif "Deer" in sp_name or "Buck" in sp_name:
				animal_lift = 0.30
			target_animal.global_position.y = animal_ground_y + animal_lift
			a_pos = target_animal.global_position
			
			# Align animal along terrain slope
			var up := Vector3.UP
			var axis := up.cross(n)
			if axis.length() > 0.001:
				target_animal.basis = Basis(axis.normalized(), up.angle_to(n))
		
		# Position hunter comfortably beside the harvest looking at the camera
		var offset_dir = target_animal.global_transform.basis.x
		if offset_dir.length_squared() < 0.1:
			offset_dir = Vector3(1, 0, 0)
		offset_dir.y = 0.0
		offset_dir = offset_dir.normalized()
		
		var h_pos = a_pos + (offset_dir * 0.95)
		var y_offset = 0.85
		var cur_pose = pose_enums[current_pose_idx]
		if cur_pose == HunterThirdPersonBuilder.Pose.GROUND_LOUNGE:
			y_offset = 0.78 # Matches -0.76 anchor position so pelvis rests +0.02m on turf!
		elif cur_pose == HunterThirdPersonBuilder.Pose.GROUND_KNEEL:
			y_offset = 0.45 # Matches -0.42 anchor position so knee rests +0.03m on turf!
			
		if world and world.terrain:
			h_pos.y = world.terrain.height_at(h_pos.x, h_pos.z) + y_offset
		else:
			h_pos.y = a_pos.y + y_offset
			
		hunter.global_position = h_pos
		# Hunter faces front towards the photo camera with proud trophy composure
		var photo_face_dir := -target_animal.global_transform.basis.z
		if photo_face_dir.length_squared() < 0.1:
			photo_face_dir = Vector3(0, 0, 1)
		photo_face_dir.y = 0.0
		photo_face_dir = photo_face_dir.normalized()
		hunter.look_at(hunter.global_position + photo_face_dir, Vector3.UP)
		hunter.rotation.x = 0
		hunter.rotation.z = 0

func _on_cycle_pose() -> void:
	current_pose_idx = (current_pose_idx + 1) % pose_names.size()
	if pose_btn:
		pose_btn.text = pose_names[current_pose_idx]
	if hunter and is_instance_valid(hunter):
		hunter.set_photo_pose(pose_enums[current_pose_idx])
		_position_hunter_for_photo()
	_update_photo_camera_transform()
	print("[Sportsman's Quest] Hunter struck pose: %s" % pose_names[current_pose_idx])

func _on_cycle_cam_angle() -> void:
	current_cam_angle_idx = (current_cam_angle_idx + 1) % 4
	_update_photo_camera_transform()
	print("[Sportsman's Quest] Switched photo camera angle: %d" % current_cam_angle_idx)

func _update_photo_camera_transform() -> void:
	if not photo_camera or not hunter or not is_instance_valid(hunter):
		return
	var center_pos = hunter.global_position + Vector3(0, 0.45, 0)
	if target_animal and is_instance_valid(target_animal):
		center_pos = (hunter.global_position + target_animal.global_position) * 0.5 + Vector3(0, 0.35, 0)

	var fwd = -hunter.global_transform.basis.z
	var right = hunter.global_transform.basis.x
	
	var cam_pos = Vector3.ZERO
	match current_cam_angle_idx:
		0:
			# Low Ground Front Angle
			cam_pos = center_pos + (fwd * 2.0) + (right * 0.4) + Vector3(0, 0.35, 0)
		1:
			# Eye-Level Side Angle
			cam_pos = center_pos + (right * 2.2) + Vector3(0, 0.55, 0)
		2:
			# High 3/4 Elevated Overview
			cam_pos = center_pos + (fwd * 1.8) - (right * 1.2) + Vector3(0, 1.2, 0)
		3:
			# Low Macro Angle
			cam_pos = center_pos + (fwd * 1.5) + Vector3(0, 0.25, 0)
	
	# Clamp camera above terrain surface to completely prevent underground clipping
	var world = get_tree().root.find_child("Main", true, false)
	if world and world.terrain:
		var ground_y = world.terrain.height_at(cam_pos.x, cam_pos.z)
		cam_pos.y = max(cam_pos.y, ground_y + 0.45)
	
	photo_camera.global_position = cam_pos
	photo_camera.look_at(center_pos, Vector3.UP)
	photo_camera.current = true

func _on_snap_photo() -> void:
	# Camera flash effect and shutter feedback
	photo_flash.visible = true
	var tween = create_tween()
	tween.tween_property(photo_flash, "modulate:a", 0.0, 0.5).from(1.0)
	tween.tween_callback(func(): photo_flash.visible = false)
	
	var pose_name_clean = pose_names[current_pose_idx].replace("🤸 ", "").replace("🏖️ ", "").replace("👍 ", "").replace("🎯 ", "").replace("🏆 ", "")
	current_record["trophy_photo"] = "Photo #%d: %s (%s)" % [photo_counter, current_record.get("species_name", "Game"), pose_name_clean]
	photo_counter += 1
	
	# Update persistent record in GameState
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.save_game()
		
	print("[Sportsman's Quest] *Click-Flash!* Trophy photo saved to logbook and Trophy Lodge: %s" % current_record["trophy_photo"])

func _on_exit_photo_mode() -> void:
	if hunter and is_instance_valid(hunter):
		hunter.set_third_person_visible(false)
		hunter.set_photo_mode_active(false)
		var world = get_tree().root.find_child("Main", true, false)
		if world and world.terrain:
			hunter.global_position.y = world.terrain.height_at(hunter.global_position.x, hunter.global_position.z) + 0.90
		if hunter.camera:
			hunter.camera.current = true
			
	if photo_camera and is_instance_valid(photo_camera):
		photo_camera.current = false
		photo_camera.queue_free()
		photo_camera = null
		
	photo_hud.visible = false
	panel.visible = true
	is_in_photo_mode = false

func _on_accept_pressed() -> void:
	if is_in_photo_mode:
		_on_exit_photo_mode()
		
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	harvest_accepted.emit(current_record)
	
	if target_animal and is_instance_valid(target_animal):
		target_animal.queue_free()
		target_animal = null
	
	print("[Sportsman's Quest] Harvest claimed and added to your offline 3D Trophy Lodge!")
