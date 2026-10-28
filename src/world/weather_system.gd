class_name WeatherSystem
extends Node3D

## Dynamic Hunting Weather & Atmosphere (Sportsman's Quest)
## Simulates Clear Dawn, Drifting River Valley Fog, and Autumn Rain Showers.
## Weather directly alters acoustic scent dampening, footstep noise, and visibility.

enum WeatherType { CLEAR_DAWN, VALLEY_FOG, RAIN_SHOWER }

@export var current_weather: WeatherType = WeatherType.CLEAR_DAWN

var _weather_timer: float = 180.0
var _rain_particles: GPUParticles3D
var _rain_sound: AudioStreamPlayer
var world: Node

func _ready() -> void:
	world = get_parent()
	_init_rain_system()

func _init_rain_system() -> void:
	_rain_particles = GPUParticles3D.new()
	_rain_particles.name = "RainParticles"
	_rain_particles.amount = 450
	_rain_particles.lifetime = 1.4
	_rain_particles.emitting = false
	
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(25.0, 1.0, 25.0)
	mat.direction = Vector3(0.1, -1.0, 0.05)
	mat.spread = 5.0
	mat.initial_velocity_min = 18.0
	mat.initial_velocity_max = 24.0
	_rain_particles.process_material = mat
	
	var drop := CylinderMesh.new()
	drop.top_radius = 0.005
	drop.bottom_radius = 0.005
	drop.height = 0.45
	drop.radial_segments = 4
	
	var drop_mat := StandardMaterial3D.new()
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.5)
	drop.material = drop_mat
	_rain_particles.draw_pass_1 = drop
	
	add_child(_rain_particles)

func _physics_process(delta: float) -> void:
	_weather_timer -= delta
	if _weather_timer <= 0.0:
		_weather_timer = randf_range(120.0, 300.0)
		_cycle_weather()

	# Keep rain particles centered above the hunter
	if current_weather == WeatherType.RAIN_SHOWER and world and world.hunter:
		_rain_particles.global_position = world.hunter.global_position + Vector3(0, 12.0, 0)

func _cycle_weather() -> void:
	var next_idx = (int(current_weather) + 1) % 3
	set_weather(next_idx as WeatherType)

func set_weather(weather: WeatherType) -> void:
	current_weather = weather
	var we: WorldEnvironment = world.find_child("WorldEnvironment", true, false) as WorldEnvironment
	
	match current_weather:
		WeatherType.CLEAR_DAWN:
			_rain_particles.emitting = false
			if we and we.environment:
				we.environment.fog_density = 0.0018
			print("[Weather] Skies cleared. Crisp morning visibility across Whispering Pines.")
		WeatherType.VALLEY_FOG:
			_rain_particles.emitting = false
			if we and we.environment:
				we.environment.fog_density = 0.012
			print("[Weather] Thick ground mist rolls across the marsh and lake basin.")
		WeatherType.RAIN_SHOWER:
			_rain_particles.emitting = true
			if we and we.environment:
				we.environment.fog_density = 0.006
			print("[Weather] Gentle autumn rain begins. Footstep noise dampened on wet ground.")

func get_acoustic_multiplier() -> float:
	return 0.65 if current_weather == WeatherType.RAIN_SHOWER else 1.0

func get_scent_multiplier() -> float:
	return 0.5 if current_weather == WeatherType.RAIN_SHOWER else 1.0
