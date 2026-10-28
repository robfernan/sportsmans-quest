class_name BigGameAI
extends CharacterBody3D

## Big Game Animal AI (Whitetail Deer / Elk)
## Realistic sensory perception (Scent, Sound, Sight) inspired by theHunter Classic.

enum AIState { IDLE_FEEDING, WARY_SNIFFING, ALERT_WARNING, FLEEING, WOUNDED_TRACKING, DEAD }

@export_group("Sensory Parameters")
@export var sight_range: float = 120.0       ## Maximum visual spotting distance
@export var sight_fov_degrees: float = 240.0 ## Wide prey vision cone (deer have almost 300 deg FOV)
@export var hearing_sensitivity: float = 1.0 ## Multiplier for audio detection
@export var scent_sensitivity: float = 1.0   ## Sensitivity to downwind human scent

@export_group("Locomotion")
@export var walk_speed: float = 2.0
@export var trot_speed: float = 4.5
@export var sprint_flee_speed: float = 11.0  ## ~40 km/h realistic whitetail sprint
@export var flee_duration: float = 25.0       ## Seconds to flee before slowing down to relocate

@export_group("Vitals & Trophy")
@export var species_name: String = "Whitetail Deer"
@export var max_health: float = 100.0
@export var trophy_score: float = 145.5       ## Boone & Crockett score estimate

var current_state: AIState = AIState.IDLE_FEEDING
var current_health: float = 100.0
var bleed_rate: float = 0.0                  ## Damage taken per second from organ wound
var flee_timer: float = 0.0
var alert_level: float = 0.0                 ## 0.0 to 1.0
var flee_direction: Vector3 = Vector3.ZERO
var last_organ_hit: String = "Heart"
var last_shot_distance: float = 35.0

# References
var wind_system: WindSystem
var hunter_node: Node3D

func _ready() -> void:
	current_health = max_health
	# Find wind system if available in scene tree
	wind_system = get_tree().root.find_child("WindSystem", true, false) as WindSystem

func _physics_process(delta: float) -> void:
	if current_state == AIState.DEAD:
		return
	
	_handle_health_and_bleeding(delta)
	if current_state == AIState.DEAD:
		return

	_evaluate_senses(delta)
	_execute_behavior_state(delta)

## Evaluates Scent, Hearing, and Vision to update threat/alert level
func _evaluate_senses(delta: float) -> void:
	if not hunter_node:
		# Auto-locate player if not assigned
		hunter_node = get_tree().root.find_child("Hunter", true, false)
		if not hunter_node:
			return

	var hunter_pos = hunter_node.global_position
	var to_hunter = hunter_pos - global_position
	var distance = to_hunter.length()

	# 1. SCENT EVALUATION (From WindSystem)
	var scent_exposure = 0.0
	if wind_system:
		scent_exposure = wind_system.calculate_scent_exposure(hunter_pos, global_position) * scent_sensitivity

	# 2. VISION EVALUATION
	var visual_exposure = 0.0
	if distance < sight_range:
		var forward = -global_transform.basis.z.normalized()
		var dir_to_hunter = to_hunter.normalized()
		var angle_to_hunter = rad_to_deg(forward.angle_to(dir_to_hunter))
		
		if angle_to_hunter < (sight_fov_degrees * 0.5):
			# Hunter is inside visual cone; line of sight raycast
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.2, 0), hunter_pos + Vector3(0, 1.2, 0))
			query.exclude = [self]
			var hit = space_state.intersect_ray(query)
			
			# If unoccluded, visibility scales by stance and movement
			if not hit or hit.collider == hunter_node:
				var hunter_speed = 0.0
				if hunter_node.has_method("get_current_speed"):
					hunter_speed = hunter_node.get_current_speed()
				var movement_visibility = clamp(hunter_speed / 4.0, 0.2, 1.0)
				visual_exposure = (1.0 - (distance / sight_range)) * movement_visibility

	# 3. SOUND EVALUATION
	var sound_exposure = 0.0
	if hunter_node.has_method("get_noise_radius"):
		var noise_radius = hunter_node.get_noise_radius() * hearing_sensitivity
		if distance < noise_radius:
			sound_exposure = 1.0 - (distance / noise_radius)

	# Aggregate threat
	var total_threat = (scent_exposure * 1.2) + (sound_exposure * 1.0) + (visual_exposure * 0.8)

	if total_threat > 0.8:
		_transition_to_flee(hunter_pos)
	elif total_threat > 0.4:
		alert_level = move_toward(alert_level, 0.7, delta * 0.8)
		if current_state == AIState.IDLE_FEEDING:
			current_state = AIState.WARY_SNIFFING
	elif total_threat > 0.15:
		alert_level = move_toward(alert_level, 0.3, delta * 0.4)
	else:
		alert_level = move_toward(alert_level, 0.0, delta * 0.2)
		if current_state == AIState.WARY_SNIFFING and alert_level <= 0.1:
			current_state = AIState.IDLE_FEEDING

func _transition_to_flee(threat_source_pos: Vector3) -> void:
	current_state = AIState.FLEEING
	flee_timer = flee_duration
	# Run directly away from the threat source
	flee_direction = (global_position - threat_source_pos).normalized()
	flee_direction.y = 0.0
	flee_direction = flee_direction.normalized()

func _execute_behavior_state(delta: float) -> void:
	match current_state:
		AIState.IDLE_FEEDING:
			velocity = velocity.move_toward(Vector3.ZERO, delta * 5.0)
		AIState.WARY_SNIFFING:
			# Stand still with head up, alert
			velocity = velocity.move_toward(Vector3.ZERO, delta * 8.0)
		AIState.FLEEING:
			flee_timer -= delta
			velocity = flee_direction * sprint_flee_speed
			# Orient toward fleeing direction
			if flee_direction != Vector3.ZERO:
				var look_target = global_position + flee_direction
				look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)
			if flee_timer <= 0.0:
				current_state = AIState.IDLE_FEEDING # Returns to cautious feeding far away
		AIState.WOUNDED_TRACKING:
			# Slowed trot/stumble while bleeding out
			velocity = flee_direction * trot_speed * 0.6

	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()

## Handles bullet impact, anatomical organ penetration, and bleed rate
func apply_ballistic_hit(damage: float, organ_hit_name: String, hit_position: Vector3) -> void:
	last_organ_hit = organ_hit_name
	if hunter_node:
		last_shot_distance = global_position.distance_to(hunter_node.global_position)
	print("[Animal Hit] %s struck in: %s for %.1f damage" % [species_name, organ_hit_name, damage])
	current_health -= damage

	# Configure bleed rate based on struck organ (Inspired by Way of the Hunter)
	match organ_hit_name:
		"Brain", "UpperSpine":
			current_health = 0.0 # Instant collapse
		"Heart":
			bleed_rate = 25.0 # Dies within 4 seconds
		"Lungs":
			bleed_rate = 12.0 # Dies within ~8 seconds
		"Liver":
			bleed_rate = 4.0  # Prolonged tracking
		"Flesh":
			bleed_rate = 0.5  # Superficial wound

	if current_health <= 0.0:
		_die()
	else:
		_transition_to_flee(hit_position)
		if bleed_rate > 0.0:
			current_state = AIState.WOUNDED_TRACKING

func _handle_health_and_bleeding(delta: float) -> void:
	if bleed_rate > 0.0 and current_health > 0.0:
		current_health -= bleed_rate * delta
		if current_health <= 0.0:
			_die()

func _die() -> void:
	current_state = AIState.DEAD
	velocity = Vector3.ZERO
	# Collapse to the ground
	rotation.z = deg_to_rad(90.0)
	print("[Harvest Ready] %s has expired. Approach and press E to inspect trophy." % species_name)

func get_harvest_record() -> Dictionary:
	var organ_enum = HunterConstants.OrganType.HEART
	match last_organ_hit:
		"Brain": organ_enum = HunterConstants.OrganType.BRAIN
		"UpperSpine": organ_enum = HunterConstants.OrganType.UPPER_SPINE
		"Heart": organ_enum = HunterConstants.OrganType.HEART
		"Lungs": organ_enum = HunterConstants.OrganType.LUNGS
		"Liver": organ_enum = HunterConstants.OrganType.LIVER
		"Flesh": organ_enum = HunterConstants.OrganType.FLESH

	return HunterConstants.generate_harvest_record(
		HunterConstants.SpeciesType.WHITETAIL_DEER,
		organ_enum,
		last_shot_distance,
		".308 Bolt-Action Rifle"
	)
