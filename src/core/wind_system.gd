class_name WindSystem
extends Node

## Global Wind and Scent Simulation (Inspired by theHunter Classic)
## Animals downwind of the player calculate scent exposure based on this system.

signal wind_changed(direction: Vector3, speed: float)

@export var base_wind_speed: float = 4.5  ## meters per second (approx 10 mph)
@export var wind_variation_strength: float = 1.5
@export var wind_shift_interval: float = 60.0 ## Seconds between natural wind shifts

var current_wind_direction: Vector3 = Vector3(1, 0, 0.5).normalized()
var current_wind_speed: float = 4.5
var _time_accumulator: float = 0.0

func _ready() -> void:
	_update_wind()

func _physics_process(delta: float) -> void:
	_time_accumulator += delta
	if _time_accumulator >= wind_shift_interval:
		_time_accumulator = 0.0
		_shift_wind()

func _shift_wind() -> void:
	# Gently rotate wind direction by +/- 15 to 30 degrees
	var angle_delta = randf_range(-PI / 6.0, PI / 6.0)
	current_wind_direction = current_wind_direction.rotated(Vector3.UP, angle_delta).normalized()
	current_wind_speed = clamp(base_wind_speed + randf_range(-wind_variation_strength, wind_variation_strength), 1.0, 12.0)
	wind_changed.emit(current_wind_direction, current_wind_speed)

func _update_wind() -> void:
	wind_changed.emit(current_wind_direction, current_wind_speed)

func get_current_wind_vector() -> Vector3:
	return current_wind_direction * current_wind_speed

## Calculates how much of the player's scent reaches a target position.
## Returns a factor from 0.0 (upwind/undetected) to 1.0 (directly downwind/strong scent).
func calculate_scent_exposure(hunter_pos: Vector3, animal_pos: Vector3, max_scent_range: float = 250.0) -> float:
	var to_animal = animal_pos - hunter_pos
	var distance = to_animal.length()
	
	if distance > max_scent_range or distance < 0.1:
		return 0.0
	
	var dir_to_animal = to_animal.normalized()
	# Dot product compares wind direction to vector toward the animal
	var alignment = current_wind_direction.dot(dir_to_animal)
	
	# If alignment <= 0, animal is upwind (cannot smell hunter)
	if alignment <= 0.0:
		return 0.0
	
	# Distance decay: scent drops off as distance increases
	var distance_factor = 1.0 - (distance / max_scent_range)
	
	# Scent cone intensity: strongest along the direct wind vector
	var scent_intensity = pow(alignment, 2.0) * distance_factor
	return clamp(scent_intensity, 0.0, 1.0)
