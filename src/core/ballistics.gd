class_name Ballistics
extends RefCounted

## Realistic Exterior Ballistics for Sportsman's Quest.
## Simulates drag, gravity drop over distance, bullet travel time, crosswind deflection,
## and scope zeroing elevations.

class TrajectoryResult:
	var hit: bool = false
	var hit_pos: Vector3 = Vector3.ZERO
	var hit_normal: Vector3 = Vector3.ZERO
	var collider: Object = null
	var flight_time: float = 0.0
	var final_velocity: float = 0.0
	var drop_m: float = 0.0
	var wind_drift_m: float = 0.0

static func simulate_shot(
	space_state: PhysicsDirectSpaceState3D,
	muzzle_pos: Vector3,
	muzzle_forward: Vector3,
	muzzle_velocity: float,
	ballistic_coeff: float,
	wind_vector: Vector3,
	zero_range_m: float = 100.0,
	max_range_m: float = 500.0,
	step_dt: float = 0.015,
	collision_mask: int = 2 # Layers: 2 = Animals, or 1|2
) -> TrajectoryResult:
	var res := TrajectoryResult.new()
	
	# Scope elevation compensation for zero range:
	# angle ≈ 0.5 * asin(g * zero_range / v0^2)
	var g := 9.81
	var zero_comp_angle: float = 0.0
	if zero_range_m > 1.0 and muzzle_velocity > 50.0:
		var ratio = (g * zero_range_m) / (muzzle_velocity * muzzle_velocity)
		if ratio < 0.95:
			zero_comp_angle = 0.5 * asin(ratio)
	
	# Elevate initial launch angle slightly according to zero setting
	var up_vec := Vector3.UP
	var right_vec := muzzle_forward.cross(up_vec).normalized()
	var initial_dir := muzzle_forward.rotated(right_vec, -zero_comp_angle).normalized()
	
	var current_pos := muzzle_pos
	var current_vel := initial_dir * muzzle_velocity
	var total_time := 0.0
	var total_dist := 0.0
	
	# Wind resistance factor (simplified G1 drag function)
	var drag_factor = 0.0014 / max(ballistic_coeff, 0.05)

	while total_dist < max_range_m and total_time < 3.5:
		var speed = current_vel.length()
		
		# Drag force opposing motion
		var drag_accel = -current_vel.normalized() * (speed * speed * drag_factor)
		# Gravity
		var grav_accel = Vector3(0, -g, 0)
		# Wind drift (bullet exposed to relative wind)
		var rel_wind = wind_vector - current_vel
		var wind_accel = rel_wind.normalized() * (rel_wind.length() * 0.4 * drag_factor * 12.0)
		
		var net_accel = drag_accel + grav_accel + Vector3(wind_accel.x, 0, wind_accel.z)
		
		var next_vel = current_vel + net_accel * step_dt
		var next_pos = current_pos + ((current_vel + next_vel) * 0.5) * step_dt
		
		# Trace ray through physics space
		var query := PhysicsRayQueryParameters3D.create(current_pos, next_pos, collision_mask)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var ray_hit = space_state.intersect_ray(query)
		if ray_hit:
			res.hit = true
			res.hit_pos = ray_hit.position
			res.hit_normal = ray_hit.normal
			res.collider = ray_hit.collider
			res.flight_time = total_time + step_dt
			res.final_velocity = next_vel.length()
			res.drop_m = muzzle_pos.y - res.hit_pos.y
			return res
			
		current_pos = next_pos
		current_vel = next_vel
		total_time += step_dt
		total_dist = (current_pos - muzzle_pos).length()

	# If no hit, record final position
	res.hit = false
	res.hit_pos = current_pos
	res.flight_time = total_time
	res.final_velocity = current_vel.length()
	return res
