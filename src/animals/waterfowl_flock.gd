class_name WaterfowlFlock
extends Node3D

## Waterfowl Flocking & Decoy AI (Mallard / Canadian Geese)
## Inspired by Bult: Hunting Simulator & theHunter Classic waterfowl mechanics.

enum FlockState { CRUISING_HIGH, CIRCLING_DECOYS, COMMITTING_LANDING, WATER_SWIMMING, SPOOKED_CLIMBING }

@export var bird_count: int = 5
@export var flight_speed: float = 14.0       ## Fast cruising speed (~50 km/h)
@export var glide_landing_speed: float = 6.0
@export var flight_altitude: float = 35.0

var current_state: FlockState = FlockState.CRUISING_HIGH
var target_landing_spot: Vector3 = Vector3.ZERO
var wind_system: WindSystem

func _ready() -> void:
	wind_system = get_tree().root.find_child("WindSystem", true, false) as WindSystem

func _physics_process(delta: float) -> void:
	match current_state:
		FlockState.CRUISING_HIGH:
			_cruise_over_marsh(delta)
			_scan_for_decoys()
		FlockState.CIRCLING_DECOYS:
			_circle_pattern(delta)
		FlockState.COMMITTING_LANDING:
			_approach_landing_into_wind(delta)
		FlockState.SPOOKED_CLIMBING:
			_climb_and_escape(delta)

func _cruise_over_marsh(delta: float) -> void:
	# Fly in a sweeping patrol across the marsh
	var forward = -global_transform.basis.z
	global_position += forward * flight_speed * delta

func _scan_for_decoys() -> void:
	# Search for player decoys in the water within 150m
	var decoys = get_tree().get_nodes_in_group("waterfowl_decoys")
	for decoy in decoys:
		if decoy is Node3D:
			var dist = global_position.distance_to(decoy.global_position)
			if dist < 120.0:
				target_landing_spot = decoy.global_position
				current_state = FlockState.CIRCLING_DECOYS
				print("[Waterfowl] Flock spotted decoy spread! Cupping wings to circle.")
				break

func _circle_pattern(delta: float) -> void:
	# Orbit around the decoy spread to inspect before landing
	var to_target = target_landing_spot - global_position
	rotate_y(deg_to_rad(30.0) * delta)
	global_position += -global_transform.basis.z * (flight_speed * 0.8) * delta
	# Descend gradually
	global_position.y = move_toward(global_position.y, 15.0, delta * 3.0)
	
	if global_position.y <= 16.0:
		current_state = FlockState.COMMITTING_LANDING
		print("[Waterfowl] Flock committing! Pitching into the wind for water landing.")

func _approach_landing_into_wind(delta: float) -> void:
	# Birds ALWAYS land heading INTO the wind for aerodynamic lift
	var approach_dir = Vector3.FORWARD
	if wind_system:
		approach_dir = -wind_system.current_wind_direction # Into wind
	
	look_at(global_position + approach_dir, Vector3.UP)
	global_position += approach_dir * glide_landing_speed * delta
	global_position.y = move_toward(global_position.y, 0.2, delta * 2.5)

	if global_position.y <= 0.3:
		current_state = FlockState.WATER_SWIMMING
		print("[Waterfowl] Ducks touched down on water.")

func _climb_and_escape(delta: float) -> void:
	# Emergency spook climb when hunter shoots or moves too fast
	global_position.y += 10.0 * delta
	global_position += -global_transform.basis.z * (flight_speed * 1.3) * delta

func spook_flock() -> void:
	if current_state != FlockState.SPOOKED_CLIMBING:
		current_state = FlockState.SPOOKED_CLIMBING
		print("[Waterfowl] Gunshot/Movement startled flock! Rapidly climbing.")
