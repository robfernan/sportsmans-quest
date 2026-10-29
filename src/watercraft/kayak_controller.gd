class_name KayakController
extends RigidBody3D

## Lightweight, open-source 3D Kayak physics and paddling controller.
## Designed for Godot 4 (Compatibility / Mobile / Forward+ renderers).
## Supports shallow water navigation, alternating paddle strokes, and stealth noise emission.

# --- Kayak Configuration ---
@export_group("Paddling Dynamics")
@export var paddle_force: float = 350.0        ## Forward thrust per stroke
@export var paddle_torque: float = 65.0        ## Turning moment generated per single-sided stroke
@export var rudder_torque: float = 40.0        ## Turning torque when turning paddle as a rudder
@export var stroke_cooldown: float = 0.85      ## Minimum seconds between alternating strokes
@export var water_drag_linear: float = 1.2     ## Resistance slowing forward glide
@export var water_drag_angular: float = 2.5    ## Resistance preventing excessive spinning

@export_group("Water Simulation")
@export var water_surface_y: float = 0.0       ## World Y height of the water plane
@export var buoyancy_stiffness: float = 450.0  ## Upward spring force when submerged
@export var water_damping: float = 12.0        ## Dampens vertical bobbing/rocking

@export_group("Hunting Stealth Mechanics")
@export var paddle_splash_noise_radius: float = 12.0 ## Radius in meters where animals hear a paddle stroke
@export var passive_glide_noise_radius: float = 2.0  ## Minimal hull water displacement noise

# --- Runtime Variables ---
var _last_stroke_time: float = -10.0
var _last_stroke_side: int = 0 # -1 = Left, 1 = Right, 0 = Initial
var _current_stealth_noise: float = 0.0
var _paddle_audio: AudioStreamPlayer3D

func _ready() -> void:
	# Configure RigidBody properties for stable watercraft dynamics
	linear_damp = water_drag_linear
	angular_damp = water_drag_angular
	can_sleep = false
	_paddle_audio = AudioStreamPlayer3D.new()
	_paddle_audio.bus = AudioDirector.BUS_SFX
	_paddle_audio.unit_size = 5.0
	_paddle_audio.max_distance = 36.0
	_paddle_audio.volume_db = -8.0
	add_child(_paddle_audio)

func _physics_process(delta: float) -> void:
	_apply_buoyancy(delta)
	_handle_input(delta)
	_decay_noise(delta)

## Simulates twin-point water buoyancy (bow and stern) to keep the kayak level
func _apply_buoyancy(_delta: float) -> void:
	var submerged_depth = water_surface_y - global_position.y
	if submerged_depth > 0.0:
		# Upward buoyant force proportional to submersion depth
		var upward_force = Vector3.UP * (submerged_depth * buoyancy_stiffness)
		# Counteract vertical velocity to prevent endless bouncing
		upward_force.y -= linear_velocity.y * water_damping
		apply_central_force(upward_force)

## Reads paddling inputs and generates alternating stroke forces
func _handle_input(_delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var can_stroke = (current_time - _last_stroke_time) >= stroke_cooldown

	var forward_pressed = Input.is_action_just_pressed("paddle_forward") or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var reverse_pressed = Input.is_action_just_pressed("paddle_reverse") or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)

	# Input: Forward Paddle
	if forward_pressed and can_stroke:
		var stroke_side = -1 if _last_stroke_side != -1 else 1
		_execute_paddle_stroke(stroke_side, 1.0)
		_last_stroke_side = stroke_side
		_last_stroke_time = current_time

	# Input: Rudder / Steering
	var steer_input = 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		steer_input += 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		steer_input -= 1.0
	if steer_input == 0.0:
		steer_input = Input.get_axis("steer_right", "steer_left")

	if abs(steer_input) > 0.05:
		apply_torque(Vector3.UP * (steer_input * rudder_torque))
		_emit_stealth_noise(passive_glide_noise_radius * 1.5)

	# Input: Reverse Back-Paddle
	if reverse_pressed and can_stroke:
		_execute_paddle_stroke(0, -0.6)
		_last_stroke_time = current_time

## Applies forward impulse and asymmetric torque for a realistic paddle stroke
func _execute_paddle_stroke(side: int, power_multiplier: float) -> void:
	var forward_dir = -global_transform.basis.z.normalized()
	
	# Forward propulsion
	apply_central_force(forward_dir * (paddle_force * power_multiplier))
	
	# Turning moment (left paddle turns boat right, right paddle turns boat left)
	if side != 0:
		var torque_dir = -side # -1 (Left stroke) -> positive yaw (turns right)
		apply_torque(Vector3.UP * (torque_dir * paddle_torque * power_multiplier))

	# Broadcast noise to sensory system for surrounding waterfowl/deer
	_emit_stealth_noise(paddle_splash_noise_radius)
	_play_paddle(power_multiplier)

func _play_paddle(power_multiplier: float) -> void:
	if _paddle_audio == null:
		return
	var hunter = get_tree().root.find_child("Hunter", true, false)
	if hunter == null or not hunter.is_in_kayak or hunter.active_kayak != self:
		return
	_paddle_audio.stream = AudioSynth.take_paddle()
	_paddle_audio.pitch_scale = AudioSynth.vary_pitch(0.92, 1.08)
	_paddle_audio.volume_db = -8.0 + linear_to_db(maxf(absf(power_multiplier), 0.4))
	_paddle_audio.play()

func _emit_stealth_noise(radius: float) -> void:
	_current_stealth_noise = max(_current_stealth_noise, radius)
	# This function hooks directly into the Animal Sensory Manager
	# e.g., SensoryManager.register_noise(global_position, _current_stealth_noise)

func _decay_noise(delta: float) -> void:
	_current_stealth_noise = move_toward(_current_stealth_noise, 0.0, delta * 20.0)

## Returns current noise radius so the AI sensory manager can query it
func get_noise_radius() -> float:
	var speed = linear_velocity.length()
	var passive_hull_noise = speed * 0.8
	return max(_current_stealth_noise, passive_hull_noise)
