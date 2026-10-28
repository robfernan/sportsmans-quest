class_name HunterController
extends CharacterBody3D

## First-Person Stalking Hunter Controller (Sportsman's Quest)
## Features: Ballistic Trajectories (Drop & Wind Drift), Scope Zeroing (100m, 200m, 300m),
## Roper Repeating Shotgun (4-round cylinder with Birdshot, Buckshot, Slug),
## Talcum Wind Powder, Duck Decoy Deployment, Reed Blinds, Dog Companion Commands,
## Topographic GPS Map, and Third-Person Trophy Photo Pose.

enum Stance { STAND, CROUCH, PRONE }
enum WeaponSlot { RIFLE, SHOTGUN, BINOCULARS, DEER_CALL, DUCK_CALL, WIND_PUFF }
enum ShotgunAmmo { BIRDSHOT, BUCKSHOT, SLUG }

@export_group("Movement Speeds")
@export var sprint_speed: float = 6.2
@export var walk_speed: float = 3.2
@export var crouch_speed: float = 1.6
@export var prone_speed: float = 0.8
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.0025

@export_group("Noise Radii (Meters)")
@export var sprint_noise_radius: float = 75.0
@export var walk_noise_radius: float = 28.0
@export var crouch_noise_radius: float = 9.0
@export var prone_noise_radius: float = 2.5

@export_group("Optics")
@export var default_fov: float = 75.0
@export var scope_fov: float = 22.0
@export var binocular_fov: float = 10.0

var current_stance: Stance = Stance.STAND
var current_slot: WeaponSlot = WeaponSlot.RIFLE
var current_shotgun_ammo: ShotgunAmmo = ShotgunAmmo.BUCKSHOT
var roper_ammo_loaded: int = 4
const ROPER_CAPACITY: int = 4

# Rifle Scope Zeroing: 100m, 200m, 300m
var zero_settings: Array[float] = [100.0, 200.0, 300.0]
var current_zero_idx: int = 0

var is_aiming_optics: bool = false
var is_in_kayak: bool = false
var active_kayak: KayakController = null
var current_clue: String = ""
var _recoil_kick: float = 0.0

var health: float = 100.0
const MAX_HEALTH: float = 100.0

# Third-person model node (shown during photo mode)
var third_person_mesh: Node3D = null
var is_photo_mode: bool = false

# Audio players
var _gun_audio: AudioStreamPlayer
var _call_audio: AudioStreamPlayer
var _click_audio: AudioStreamPlayer
var _footstep_audio: AudioStreamPlayer
var _fabric_audio: AudioStreamPlayer
var _breathing_audio: AudioStreamPlayer
var _step_timer: float = 0.0

# Camera & Movement Juice
var _head_target_y: float = 1.7
var _crouch_dip: float = 0.0
var _bob_phase: float = 0.0
var _shake_pos: Vector3 = Vector3.ZERO
var _shake_vel: Vector3 = Vector3.ZERO
var _shake_rot_y: float = 0.0
var _sprint_fov_factor: float = 0.0
var _breath_cycle_timer: float = 0.0
var _recent_sprint_timer: float = 0.0

# Pre-synthesized audio streams
var _rifle_sound: AudioStreamWAV
var _shotgun_sound: AudioStreamWAV
var _grunt_sound: AudioStreamWAV
var _quack_sound: AudioStreamWAV
var _click_sound: AudioStreamWAV
var _foot_turf_sound: AudioStreamWAV
var _foot_water_sound: AudioStreamWAV
var _foot_wood_sound: AudioStreamWAV

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var rangefinder_ray: RayCast3D = $Head/Camera3D/RangefinderRay
@onready var rifle_model: Node3D = $Head/Camera3D/HuntingRifle
@onready var roper_shotgun_model: Node3D = $Head/Camera3D/RoperShotgun

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	floor_snap_length = 0.4
	max_slides = 6
	floor_constant_speed = true
	up_direction = Vector3.UP
	_init_audio()
	_init_third_person_model()

func _init_third_person_model() -> void:
	third_person_mesh = HunterThirdPersonBuilder.build_hunter_mesh()
	third_person_mesh.visible = false
	add_child(third_person_mesh)

func set_third_person_visible(p_visible: bool) -> void:
	if third_person_mesh:
		third_person_mesh.visible = p_visible
	if rifle_model:
		rifle_model.visible = not p_visible and (current_slot == WeaponSlot.RIFLE)
	if roper_shotgun_model:
		roper_shotgun_model.visible = not p_visible and (current_slot == WeaponSlot.SHOTGUN)

func set_photo_pose(pose_idx: int) -> void:
	if third_person_mesh:
		var pose_enum = pose_idx as HunterThirdPersonBuilder.Pose
		HunterThirdPersonBuilder.apply_pose(third_person_mesh, pose_enum)

func set_photo_mode_active(p_active: bool) -> void:
	is_photo_mode = p_active
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		col.disabled = p_active
	velocity = Vector3.ZERO
	if not p_active:
		var world = get_parent()
		if world and world.terrain:
			var half := Terrain.SIZE * 0.48
			global_position.x = clamp(global_position.x, -half, half)
			global_position.z = clamp(global_position.z, -half, half)
			global_position.y = world.terrain.height_at(global_position.x, global_position.z) + 0.90
			velocity = Vector3.ZERO

func _init_audio() -> void:
	_gun_audio = AudioStreamPlayer.new()
	_call_audio = AudioStreamPlayer.new()
	_click_audio = AudioStreamPlayer.new()
	_footstep_audio = AudioStreamPlayer.new()
	_fabric_audio = AudioStreamPlayer.new()
	_breathing_audio = AudioStreamPlayer.new()
	_gun_audio.volume_db = -10.0
	_call_audio.volume_db = -8.0
	_click_audio.volume_db = -12.0
	_footstep_audio.volume_db = -18.0
	_fabric_audio.volume_db = -14.0
	_breathing_audio.volume_db = -20.0
	add_child(_gun_audio)
	add_child(_call_audio)
	add_child(_click_audio)
	add_child(_footstep_audio)
	add_child(_fabric_audio)
	add_child(_breathing_audio)

	_rifle_sound = AudioSynth.gunshot(true)
	_shotgun_sound = AudioSynth.gunshot(false)
	_grunt_sound = AudioSynth.grunt_call()
	_quack_sound = AudioSynth.quack()
	_click_sound = AudioSynth.click()
	_foot_turf_sound = AudioSynth.footstep_turf()
	_foot_water_sound = AudioSynth.footstep_water()
	_foot_wood_sound = AudioSynth.footstep_wood()

func _input(event: InputEvent) -> void:
	# If Harvest Card, Huntermate Map, or Pause Menu is visible, let UI process mouse/keys freely!
	var hs = get_tree().root.find_child("HarvestScreen", true, false)
	var hm = get_tree().root.find_child("HuntermateMap", true, false)
	var hud = get_tree().root.find_child("HuntingHUD", true, false)
	if (hs and hs.visible) or (hm and hm.visible) or (hud and hud.is_paused):
		return

	# Click window to recapture mouse if lost
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return

	# ESC key toggles Pause & Navigation Menu
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return

	# F10 or Backquote (`) quick shortcut: return immediately to Main Menu
	if event is InputEventKey and event.pressed and (event.keycode == KEY_F10 or event.keycode == KEY_QUOTELEFT):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		get_viewport().set_input_as_handled()
		return

	# Mouse look handling
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens = mouse_sensitivity * (0.35 if is_aiming_optics else 1.0)
		rotate_y(-event.relative.x * sens)
		head.rotate_x(-event.relative.y * sens)
		head.rotation.x = clamp(head.rotation.x, -deg_to_rad(85.0), deg_to_rad(85.0))
		get_viewport().set_input_as_handled()
		return

	if is_in_kayak:
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
			_exit_kayak()
		return

	# Toggle Optics / Binoculars (Right Click)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_aiming_optics = event.pressed
		get_viewport().set_input_as_handled()
		return

	# Primary Action / Fire (Left Click)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_use_current_item()
		get_viewport().set_input_as_handled()
		return

	# Key shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: equip_slot(WeaponSlot.RIFLE)
			KEY_2: equip_slot(WeaponSlot.SHOTGUN)
			KEY_3: equip_slot(WeaponSlot.BINOCULARS)
			KEY_4: equip_slot(WeaponSlot.DEER_CALL)
			KEY_5: equip_slot(WeaponSlot.DUCK_CALL)
			KEY_6, KEY_P: equip_slot(WeaponSlot.WIND_PUFF)
			KEY_R:
				if current_slot == WeaponSlot.SHOTGUN:
					_reload_roper_shotgun()
			KEY_T:
				if current_slot == WeaponSlot.SHOTGUN:
					_cycle_shotgun_ammo()
			KEY_F:
				_cycle_rifle_zero()
			KEY_M:
				_toggle_gps_map()
			KEY_G:
				_deploy_duck_decoy()
			KEY_B:
				_deploy_reed_blind()
			KEY_K:
				_command_dog_toggle()
			KEY_C:
				current_stance = Stance.STAND if current_stance == Stance.CROUCH else Stance.CROUCH
				_adjust_stance_height()
			KEY_Z:
				current_stance = Stance.STAND if current_stance == Stance.PRONE else Stance.PRONE
				_adjust_stance_height()
			KEY_E:
				_try_interact()
			KEY_SPACE:
				if is_on_floor() and current_stance == Stance.STAND:
					velocity.y = jump_velocity

func _toggle_pause_menu() -> void:
	var hud = get_tree().root.find_child("HuntingHUD", true, false)
	if hud and hud.has_method("toggle_pause"):
		hud.toggle_pause()
	else:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_gps_map() -> void:
	var map = get_tree().root.find_child("HuntermateMap", true, false)
	if map and map.has_method("toggle_map"):
		map.toggle_map()

func _cycle_rifle_zero() -> void:
	current_zero_idx = (current_zero_idx + 1) % zero_settings.size()
	var z = zero_settings[current_zero_idx]
	_click_audio.stream = _click_sound
	_click_audio.play()
	print("[Optics] Rifle zero elevation adjusted to: %.0fm" % z)

func get_current_zero() -> float:
	return zero_settings[current_zero_idx]

func _reload_roper_shotgun() -> void:
	if roper_ammo_loaded >= ROPER_CAPACITY:
		print("[Roper Shotgun] Revolving cylinder is already full (4/4).")
		return
	roper_ammo_loaded = ROPER_CAPACITY
	_click_audio.stream = _click_sound
	_click_audio.play()
	print("[Roper Shotgun] Top latch opened. Loaded 4 rounds into cylinder (4/4).")

func _cycle_shotgun_ammo() -> void:
	current_shotgun_ammo = (int(current_shotgun_ammo) + 1) % 3 as ShotgunAmmo
	roper_ammo_loaded = ROPER_CAPACITY # Reloads with selected ammo type
	_click_audio.stream = _click_sound
	_click_audio.play()
	var ammo_names := ["Birdshot (#4)", "00 Buckshot", "Rifled Slug (1 oz)"]
	print("[Roper Shotgun] Revolving cylinder loaded: %s (4/4)" % ammo_names[current_shotgun_ammo])

func equip_slot(slot: WeaponSlot) -> void:
	current_slot = slot
	_click_audio.stream = _click_sound
	_click_audio.play()

	if rifle_model:
		rifle_model.visible = (slot == WeaponSlot.RIFLE)
	if roper_shotgun_model:
		roper_shotgun_model.visible = (slot == WeaponSlot.SHOTGUN)

func get_current_weapon_display_name() -> String:
	match current_slot:
		WeaponSlot.RIFLE:
			return ".308 Bolt Rifle (Zero: %.0fm)" % get_current_zero()
		WeaponSlot.SHOTGUN:
			var ammo_names := ["Birdshot", "00 Buck", "Slug"]
			return "Roper Shotgun [%s] (%d/%d)" % [ammo_names[current_shotgun_ammo], roper_ammo_loaded, ROPER_CAPACITY]
		WeaponSlot.BINOCULARS:
			return "8x42 Optical Rangefinder"
		WeaponSlot.DEER_CALL:
			return "Whitetail Grunt Tube"
		WeaponSlot.DUCK_CALL:
			return "Mallard Reed Call"
		WeaponSlot.WIND_PUFF:
			return "Talcum Wind Powder Puff"
	return "Equipment"

func _use_current_item() -> void:
	match current_slot:
		WeaponSlot.RIFLE:
			_fire_rifle()
		WeaponSlot.SHOTGUN:
			_fire_shotgun()
		WeaponSlot.BINOCULARS:
			pass
		WeaponSlot.DEER_CALL:
			_use_caller("deer_call", _grunt_sound)
		WeaponSlot.DUCK_CALL:
			_use_caller("duck_call", _quack_sound)
		WeaponSlot.WIND_PUFF:
			_puff_wind_powder()

func _puff_wind_powder() -> void:
	var wind_sys = get_tree().root.find_child("WindSystem", true, false) as WindSystem
	var wind_vec = wind_sys.get_current_wind_vector() if wind_sys else Vector3(2.5, 0, 1.2)
	
	var puff := WindPuff.new()
	get_parent().add_child(puff)
	puff.global_position = camera.global_position - camera.global_transform.basis.z * 0.8
	puff.puff_wind(wind_vec)
	print("[Wind Powder] Squeezed talcum bottle. White cloud drifting downwind.")

func _deploy_duck_decoy() -> void:
	var pos = global_position - global_transform.basis.z * 2.5
	var world = get_parent()
	if world and world.terrain and world.terrain.is_water(pos.x, pos.z):
		var decoy := DuckDecoy.new()
		world.add_child(decoy)
		decoy.global_position = Vector3(pos.x, Terrain.WATER_LEVEL, pos.z)
		print("[Hunting Gear] Floating mallard decoy placed on the lake basin.")
	else:
		print("[Hunting Gear] Can only deploy duck decoys onto water surfaces.")

func _deploy_reed_blind() -> void:
	var blind := ReedBlind.new()
	var world = get_parent()
	if world:
		world.add_child(blind)
		blind.global_position = global_position
		blind.rotation.y = rotation.y
		print("[Hunting Gear] Camouflaged reed blind set up along the shoreline.")

func _command_dog_toggle() -> void:
	var dog = get_tree().root.find_child("HuntingDog", true, false) as RetrieverDog
	if dog:
		if dog.current_command == RetrieverDog.DogCommand.HEEL_FOLLOW:
			dog.order_sit()
		else:
			dog.order_heel()

func _use_caller(call_type: String, sound: AudioStreamWAV) -> void:
	_call_audio.stream = sound
	_call_audio.play()
	print("[Call] Blew %s into the valley." % call_type)
	var world = get_parent()
	if world and world.has_method("broadcast_animal_call"):
		world.broadcast_animal_call(call_type, global_position)

func _fire_rifle() -> void:
	_recoil_kick = 0.16
	_gun_audio.stream = _rifle_sound
	_gun_audio.play()
	_trigger_gunshot_shake()
	
	var origin = camera.global_position
	var dir = -camera.global_transform.basis.z
	
	# Muzzle flash and shell casing ejection
	if rifle_model and rifle_model.visible:
		_spawn_muzzle_flash(rifle_model, Vector3(0, 0.05, -0.75))
		_eject_shell_casing(rifle_model.global_position + Vector3(0.08, 0.05, -0.15), camera.global_transform.basis)
		
	# Gunshot acoustic reflection reverb
	var dist_water = max(10.0, abs(origin.y - Terrain.WATER_LEVEL))
	var reverb_sound = AudioSynth.gunshot_reverb(dist_water, 120.0)
	var rev_player = AudioStreamPlayer.new()
	rev_player.stream = reverb_sound
	rev_player.volume_db = -14.0
	add_child(rev_player)
	rev_player.play()
	rev_player.finished.connect(rev_player.queue_free)
	
	# Broadcast to EventBus
	var eb = get_node_or_null("/root/EventBus")
	if eb and eb.has_signal("gunshot_fired"):
		eb.gunshot_fired.emit(global_position, dir, true)
		
	print("[Rifle] Shot fired! Echoing across the valley.")
	
	var world = get_parent()
	if world and world.has_method("broadcast_gunshot"):
		world.broadcast_gunshot(global_position)

	var space = get_world_3d().direct_space_state
	var wind_sys = get_tree().root.find_child("WindSystem", true, false) as WindSystem
	var wind_vec = wind_sys.get_current_wind_vector() if wind_sys else Vector3.ZERO
	
	# Simulate realistic physics trajectory with bullet drop and crosswind deflection
	var traj = Ballistics.simulate_shot(
		space,
		origin,
		dir,
		840.0, # .308 Win muzzle velocity (m/s)
		0.42,  # Ballistic coefficient
		wind_vec,
		get_current_zero(), # Zeroing compensation
		600.0,
		0.012,
		2 # Animals layer
	)
	
	# Bullet trail for shots > 30m
	var target_point = traj.hit_pos if traj.hit else (origin + dir * 250.0)
	_spawn_bullet_trail(origin + dir * 0.8, target_point)
	
	if traj.hit and traj.collider:
		if traj.collider.has_method("take_hit"):
			var organ = traj.collider.take_hit(origin, dir, ".308 Bolt-Action Rifle", false)
			print("[Target Hit] Struck in: %s (Flight Time: %.3fs, Dist: %.1fm)" % [
				organ, traj.flight_time, origin.distance_to(traj.hit_pos)
			])

func _fire_shotgun() -> void:
	if roper_ammo_loaded <= 0:
		_click_audio.stream = _click_sound
		_click_audio.play()
		print("[Roper Shotgun] *Click!* Cylinder empty (0/4). Press R to reload.")
		return

	roper_ammo_loaded -= 1
	_recoil_kick = 0.22
	_gun_audio.stream = _shotgun_sound
	_gun_audio.play()
	_trigger_gunshot_shake()
	
	var origin = camera.global_position
	var fwd = -camera.global_transform.basis.z
	
	# Muzzle flash and shell casing
	if roper_shotgun_model and roper_shotgun_model.visible:
		_spawn_muzzle_flash(roper_shotgun_model, Vector3(0, 0.06, -0.68))
		_eject_shell_casing(roper_shotgun_model.global_position + Vector3(0.10, 0.06, -0.12), camera.global_transform.basis)
		
	# Broadcast to EventBus
	var eb = get_node_or_null("/root/EventBus")
	if eb and eb.has_signal("gunshot_fired"):
		eb.gunshot_fired.emit(global_position, fwd, false)
		
	var world = get_parent()
	if world and world.has_method("broadcast_gunshot"):
		world.broadcast_gunshot(global_position)

	var space = get_world_3d().direct_space_state

	match current_shotgun_ammo:
		ShotgunAmmo.BIRDSHOT:
			print("[Roper Shotgun] Fired Birdshot! 24 pellets spreading.")
			for i in 24:
				var spread_angle = randf_range(0.0, deg_to_rad(4.2))
				var spread_rot = randf() * TAU
				var p_dir = fwd.rotated(camera.global_transform.basis.x, sin(spread_rot) * spread_angle)
				p_dir = p_dir.rotated(camera.global_transform.basis.y, cos(spread_rot) * spread_angle)
				var query = PhysicsRayQueryParameters3D.create(origin, origin + (p_dir * 80.0), 2)
				var hit = space.intersect_ray(query)
				if hit and hit.collider and hit.collider.has_method("take_hit"):
					hit.collider.take_hit(origin, p_dir, "Roper 12GA (Birdshot)", true)
					break

		ShotgunAmmo.BUCKSHOT:
			print("[Roper Shotgun] Fired 00 Buckshot! 9 heavy lead balls dispersing.")
			for i in 9:
				var spread_angle = randf_range(0.0, deg_to_rad(1.8))
				var spread_rot = randf() * TAU
				var p_dir = fwd.rotated(camera.global_transform.basis.x, sin(spread_rot) * spread_angle)
				p_dir = p_dir.rotated(camera.global_transform.basis.y, cos(spread_rot) * spread_angle)
				var query = PhysicsRayQueryParameters3D.create(origin, origin + (p_dir * 95.0), 2)
				var hit = space.intersect_ray(query)
				if hit and hit.collider and hit.collider.has_method("take_hit"):
					hit.collider.take_hit(origin, p_dir, "Roper 12GA (00 Buckshot)", false)
					break

		ShotgunAmmo.SLUG:
			print("[Roper Shotgun] Fired 1 oz Rifled Slug! Heavy solid impact.")
			var query = PhysicsRayQueryParameters3D.create(origin, origin + (fwd * 180.0), 2)
			var hit = space.intersect_ray(query)
			if hit and hit.collider and hit.collider.has_method("take_hit"):
				var organ = hit.collider.take_hit(origin, fwd, "Roper 12GA (Rifled Slug)", false)
				print("[Target Hit] Slug struck in: %s" % organ)
			var slug_target = hit.position if hit else (origin + fwd * 180.0)
			_spawn_bullet_trail(origin + fwd * 0.8, slug_target)

func _trigger_gunshot_shake() -> void:
	_shake_pos = Vector3(randf_range(-0.04, 0.04), 0.15, randf_range(0.04, 0.07))
	_shake_vel = Vector3(randf_range(-0.4, 0.4), -1.4, randf_range(-0.6, -0.3))
	_shake_rot_y = deg_to_rad(randf_range(-0.5, 0.5))

func _apply_camera_shake(delta: float) -> void:
	# Damped harmonic spring: k = 220.0, damping = 18.0
	var spring_force = -220.0 * _shake_pos
	var damping_force = -18.0 * _shake_vel
	_shake_vel += (spring_force + damping_force) * delta
	_shake_pos += _shake_vel * delta
	_shake_rot_y = move_toward(_shake_rot_y, 0.0, delta * 3.5)

func _spawn_muzzle_flash(parent_node: Node3D, offset: Vector3) -> void:
	var flash := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.005
	cone.bottom_radius = 0.045
	cone.height = 0.10
	cone.radial_segments = 6
	flash.mesh = cone
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(1.0, 0.96, 0.88)
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.96, 0.88)
	fmat.emission_energy_multiplier = 5.0
	flash.material_override = fmat
	parent_node.add_child(flash)
	flash.position = offset
	flash.rotation = Vector3(deg_to_rad(-90), randf() * TAU, 0)
	
	var tree = get_tree()
	if tree:
		await tree.process_frame
		await tree.process_frame
	if is_instance_valid(flash):
		flash.queue_free()

func _eject_shell_casing(pos: Vector3, weapon_basis: Basis) -> void:
	var world = get_parent()
	if not world:
		return
	var casing := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.008, 0.003, 0.003) # 8x3x3mm
	casing.mesh = bm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.85, 0.72, 0.28) # Polished brass
	cmat.metallic = 0.85
	cmat.roughness = 0.3
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	casing.material_override = cmat
	world.add_child(casing)
	casing.global_position = pos
	
	var up = weapon_basis.y
	var right = weapon_basis.x
	var vel = (up * randf_range(1.6, 2.3)) + (right * randf_range(1.8, 2.7))
	
	var tween = casing.create_tween()
	var end_pos = pos + vel * 0.45 + Vector3(0, -0.3, 0)
	tween.tween_property(casing, "global_position", end_pos, 0.45)
	tween.parallel().tween_property(casing, "rotation", Vector3(randf() * 12.0, randf() * 12.0, randf() * 12.0), 0.45)
	tween.tween_property(cmat, "albedo_color:a", 0.0, 1.5).set_delay(0.5)
	tween.tween_callback(casing.queue_free)

func _spawn_bullet_trail(from_pos: Vector3, to_pos: Vector3) -> void:
	if from_pos.distance_to(to_pos) < 30.0:
		return
	var world = get_parent()
	if not world:
		return
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(Color(1.0, 1.0, 0.8, 0.9))
	im.surface_add_vertex(from_pos)
	im.surface_set_color(Color(1.0, 1.0, 0.8, 0.0))
	im.surface_add_vertex(to_pos)
	im.surface_end()
	
	var trail := MeshInstance3D.new()
	trail.mesh = im
	var tmat := StandardMaterial3D.new()
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tmat.vertex_color_use_as_albedo = true
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail.material_override = tmat
	world.add_child(trail)
	
	var tween = trail.create_tween()
	tween.tween_property(tmat, "albedo_color:a", 0.0, 0.08)
	tween.tween_callback(trail.queue_free)

func _physics_process(delta: float) -> void:
	if is_photo_mode:
		velocity = Vector3.ZERO
		return

	if _recoil_kick > 0.0:
		_recoil_kick = move_toward(_recoil_kick, 0.0, delta * 2.2)
		if roper_shotgun_model and roper_shotgun_model.visible:
			roper_shotgun_model.rotation.x = -_recoil_kick * 1.6
			roper_shotgun_model.position.z = -0.38 + _recoil_kick * 0.35
		if rifle_model and rifle_model.visible:
			rifle_model.rotation.x = -_recoil_kick * 1.2
			rifle_model.position.z = -0.42 + _recoil_kick * 0.28

	_apply_camera_shake(delta)

	if is_in_kayak:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward") or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward") or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	if Input.is_action_pressed("move_left") or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var is_sprinting = (Input.is_action_pressed("sprint") or Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SHIFT)) and current_stance == Stance.STAND and not is_aiming_optics

	if is_sprinting and input_dir != Vector2.ZERO:
		_sprint_fov_factor = move_toward(_sprint_fov_factor, 1.0, delta / 0.3)
		_recent_sprint_timer = min(4.0, _recent_sprint_timer + delta * 2.0)
	else:
		_sprint_fov_factor = move_toward(_sprint_fov_factor, 0.0, delta / 0.5)
		_recent_sprint_timer = max(0.0, _recent_sprint_timer - delta * 0.5)

	# (Breathing audio disabled as requested)
	_breath_cycle_timer = 0.0

	var target_fov = default_fov
	if is_aiming_optics:
		if current_slot == WeaponSlot.BINOCULARS:
			target_fov = binocular_fov
		elif current_slot == WeaponSlot.RIFLE:
			target_fov = scope_fov
		elif current_slot == WeaponSlot.SHOTGUN:
			target_fov = 55.0
	else:
		# Smoothstep FOV sprint kick from 75° -> 78°
		var fov_kick = smoothstep(0.0, 1.0, _sprint_fov_factor) * 3.0
		target_fov += fov_kick

	camera.fov = lerp(camera.fov, target_fov, delta * 10.0)

	var current_speed = walk_speed
	match current_stance:
		Stance.STAND:
			current_speed = sprint_speed if is_sprinting else walk_speed
		Stance.CROUCH:
			current_speed = crouch_speed
		Stance.PRONE:
			current_speed = prone_speed

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Cap extreme physics impulses from depenetration or geometry
	if velocity.length() > 30.0:
		velocity = velocity.normalized() * 10.0

	move_and_slide()

	# Absolute Ground Clamping: Hunter CAN NEVER fall through slopes or terrain!
	var world = get_parent()
	if world and world.terrain:
		var half := Terrain.SIZE * 0.48
		global_position.x = clamp(global_position.x, -half, half)
		global_position.z = clamp(global_position.z, -half, half)
		var floor_y: float = world.terrain.height_at(global_position.x, global_position.z)
		var min_h: float = 0.90
		if current_stance == Stance.CROUCH:
			min_h = 0.58
		elif current_stance == Stance.PRONE:
			min_h = 0.28
		if global_position.y < floor_y + min_h:
			global_position.y = floor_y + min_h
			velocity.y = max(0.0, velocity.y)

	# Head stance ease and Head-bob
	head.position.y = lerp(head.position.y, _head_target_y, delta * 14.0)
	var move_spd = get_current_speed()
	if is_on_floor() and move_spd > 0.4 and not is_in_kayak:
		var spd_ratio = clamp((move_spd - walk_speed) / max(0.1, sprint_speed - walk_speed), 0.0, 1.0)
		var bob_hz = lerp(1.2, 2.4, spd_ratio) * TAU
		var bob_amp = lerp(0.03, 0.06, spd_ratio)
		_bob_phase += delta * bob_hz
		var bob_y = sin(_bob_phase) * bob_amp
		camera.position.y = bob_y - _crouch_dip + _shake_pos.y
	else:
		camera.position.y = move_toward(camera.position.y, -_crouch_dip + _shake_pos.y, delta * 3.0)

	camera.position.x = _shake_pos.x
	camera.position.z = _shake_pos.z
	camera.rotation.y = _shake_rot_y

	_handle_footstep_audio(delta, move_spd)
	_update_huntermate_tracking()

func _handle_footstep_audio(delta: float, speed: float) -> void:
	if not is_on_floor() or speed < 0.4 or is_in_kayak:
		return
	_step_timer -= delta * (speed * 1.5)
	if _step_timer <= 0.0:
		_step_timer = 1.0
		var stance_mult := 1.0
		match current_stance:
			Stance.PRONE: stance_mult = 0.3
			Stance.CROUCH: stance_mult = 0.6
			Stance.STAND: stance_mult = 1.4 if speed > walk_speed + 0.5 else 1.0
			
		var surf_type = 2 # TURF (default)
		if global_position.y <= Terrain.WATER_LEVEL + 0.3:
			surf_type = 3 # WATER
		elif global_position.y > 4.0:
			surf_type = 4 # WOOD
		elif randf() < 0.2:
			surf_type = 0 # DRY_LEAVES
			
		_footstep_audio.stream = AudioSynth.footstep_surface(surf_type, stance_mult)
		_footstep_audio.play()
		
		var eb = get_node_or_null("/root/EventBus")
		if eb and eb.has_signal("player_stepped"):
			eb.player_stepped.emit(surf_type, current_stance, global_position)

func _update_huntermate_tracking() -> void:
	current_clue = ""
	var world = get_parent()
	if not world or not world.tracks:
		return
	var tracks_node = world.tracks.get_node_or_null("Tracks")
	if not tracks_node:
		return
	var closest_dist: float = 4.2
	var best_text: String = ""
	for child in tracks_node.get_children():
		if child is Node3D:
			var d = global_position.distance_to(child.global_position)
			if d < closest_dist:
				closest_dist = d
				best_text = child.get_meta("clue_text") if child.has_meta("clue_text") else ""
	current_clue = best_text

func get_noise_radius() -> float:
	if is_in_kayak:
		return 3.5
	var speed = get_current_speed()
	if speed < 0.2:
		return 0.5
	match current_stance:
		Stance.STAND:
			return sprint_noise_radius if speed > walk_speed + 0.5 else walk_noise_radius
		Stance.CROUCH:
			return crouch_noise_radius
		Stance.PRONE:
			return prone_noise_radius
	return walk_noise_radius

func scent_emission_rate() -> float:
	if current_stance == Stance.PRONE:
		return 0.4
	if current_stance == Stance.CROUCH:
		return 0.7
	return 1.0

func scent_multiplier() -> float:
	return scent_emission_rate()

func visibility_factor() -> float:
	var factor = 1.0
	if current_stance == Stance.CROUCH:
		factor = 0.5
	elif current_stance == Stance.PRONE:
		factor = 0.2
	var speed_ratio = clamp(velocity.length() / walk_speed, 0.2, 1.5)
	return factor * speed_ratio

func eye_height() -> float:
	return head.position.y

func get_current_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()

func _adjust_stance_height() -> void:
	var target_y = 1.7
	if current_stance == Stance.CROUCH:
		target_y = 1.0
	elif current_stance == Stance.PRONE:
		target_y = 0.35
	_head_target_y = target_y
	
	if _fabric_audio:
		_fabric_audio.stream = AudioSynth.fabric_shift()
		_fabric_audio.play()
		
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_crouch_dip", 0.08, 0.06)
	tween.tween_property(self, "_crouch_dip", 0.0, 0.09)

func _try_interact() -> void:
	var space = get_world_3d().direct_space_state
	# Cast interactive ray 7.0m in front of hunter
	var origin = head.global_position
	var dir = -head.global_transform.basis.z
	var query = PhysicsRayQueryParameters3D.create(origin, origin + (dir * 7.0))
	query.collide_with_areas = true
	var result = space.intersect_ray(query)
	
	# Check for interactive areas (Hunting Stand Ladder or Trapper Cabin)
	if result and result.collider is Area3D:
		var area = result.collider as Area3D
		if area.has_meta("interaction_type"):
			var itype = area.get_meta("interaction_type")
			if itype == "hunting_stand":
				var stand = area.get_meta("stand_root") as Node3D
				if stand:
					if global_position.y < stand.global_position.y + 2.0:
						global_position = stand.global_position + Vector3(0, 4.8, 0)
						print("[Hunting Stand] Climbed ladder up to elevated shooting platform!")
					else:
						global_position = stand.global_position + Vector3(0.6, 0.4, 2.0)
						print("[Hunting Stand] Climbed down ladder to ground.")
					return
			elif itype == "trapper_cabin":
				print("[Trapper Cabin] Resting by the hearth fireplace. Traveling to Trophy Lodge...")
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().change_scene_to_file("res://scenes/trophy_lodge.tscn")
				return
	
	# Also check nearby animals within 4.0m radius (for harvesting fallen game in tall grass)
	var world = get_parent()
	if world and world.animals:
		for a in world.animals:
			if is_instance_valid(a) and a.state == Animal.State.DEAD and not a.harvested:
				if global_position.distance_to(a.global_position) < 4.5:
					a.harvested = true
					var harvest_screen = get_tree().root.find_child("HarvestScreen", true, false)
					if harvest_screen:
						var record = a.get_harvest_record()
						harvest_screen.show_harvest(record, a)
						var gs = get_node_or_null("/root/GameState")
						if gs:
							gs.add_trophy(record)
					return

	if result:
		if result.collider is KayakController:
			_enter_kayak(result.collider)
		elif result.collider.has_method("get_harvest_record"):
			var animal = result.collider
			if animal.state == Animal.State.DEAD and not animal.harvested:
				animal.harvested = true
				var harvest_screen = get_tree().root.find_child("HarvestScreen", true, false)
				if harvest_screen:
					var record = animal.get_harvest_record()
					harvest_screen.show_harvest(record, animal)
					var gs = get_node_or_null("/root/GameState")
					if gs:
						gs.add_trophy(record)

func take_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	_recoil_kick = 0.35
	_click_audio.stream = _click_sound
	_click_audio.play()
	# Camera shake on impact
	camera.rotation.z = deg_to_rad(randf_range(-12.0, 12.0))
	print("[HUNTER INJURED] Took %.0f damage from predator attack! HP: %.0f/%.0f" % [amount, health, MAX_HEALTH])
	if health <= 0.0:
		print("[DEATH] The hunter succumbed to the predator of the night!")

func _enter_kayak(kayak: KayakController) -> void:
	is_in_kayak = true
	active_kayak = kayak
	kayak.set_physics_process(true)
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.complete_mission("kayak")
	print("[Vehicle] Boarded hunting kayak. Use W/S/A/D to paddle. Press E to exit.")

func _exit_kayak() -> void:
	if not active_kayak:
		return
	is_in_kayak = false
	global_position += active_kayak.global_transform.basis.x * 2.0
	active_kayak = null
	print("[Vehicle] Exited kayak.")
