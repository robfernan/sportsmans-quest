class_name Animal
extends CharacterBody3D

## Shared wildlife brain for Sportsman's Quest.
## Senses (scent / hearing / sight), herd alerts, calling response, ballistic organ hits,
## bleeding, tracks and blood trails. Subclasses provide the species data + model.

enum State { GRAZE, WALK, ALERT, FLEE, WOUNDED, DEAD }

var species := "Animal"
var gender := "Male"
var walk_speed := 1.4
var run_speed := 10.0
var sight_range := 110.0
var hearing_mult := 1.0
var scent_range := 220.0
var flee_time := 18.0
var weight_kg := 50.0
var trophy_score := 0.0
var trophy_label := "Trophy Score"
var call_type := ""            # which caller attracts this species
var hit_zones: Array = []      # [{name, pos, r, lethal}] in local space (forward = -Z)
var track_spacing := 3.5

var world: Node                # Game root (has terrain, hunter, wind, tracks)
var herd: Array = []
var state: int = State.GRAZE
var state_timer := 0.0
var target := Vector3.ZERO
var flee_dir := Vector3.ZERO
var awareness := 0.0
var bleed_time := -1.0         # seconds until death from bleeding (-1 = not bleeding)
var hits: Array = []           # organ names hit
var best_organ := ""
var shot_distance := 0.0
var weapon_used := ""
var model: Node3D
var speed := 0.0
var sense_timer := 0.0
var _last_track_pos := Vector3.ZERO
var _last_blood_pos := Vector3.ZERO
var _snort_player: AudioStreamPlayer3D
var harvested := false
var spawn_grace_timer := 8.0   # 8-second spawn grace period to prevent immediate spooking
var fear_memory: float = 0.0
var rumor_threat_bonus: float = 0.0
var rumor_timer: float = 0.0

const ORGAN_RANK := {"Brain": 6, "Spine": 5, "Heart": 4, "Lungs": 3, "Liver": 2, "Stomach": 1, "Flesh": 0}

func setup(w: Node, pos: Vector3) -> void:
	world = w
	collision_layer = 2
	collision_mask = 0
	_setup_species()
	model = _build_model()
	add_child(model)
	var cs := CollisionShape3D.new()
	cs.shape = _collision_shape()
	cs.position = _collision_offset()
	add_child(cs)
	_snort_player = AudioStreamPlayer3D.new()
	_snort_player.stream = AudioSynth.snort()
	_snort_player.unit_size = 12.0
	add_child(_snort_player)
	global_position = pos
	rotation.y = randf() * TAU
	_last_track_pos = pos
	state_timer = randf_range(2.0, 8.0)
	
	# Restore persistent fear memory
	var gs = get_node_or_null("/root/GameState")
	if gs and "animal_fear" in gs and gs.animal_fear is Dictionary:
		fear_memory = float(gs.animal_fear.get(species, 0.0))
		
	# Connect to EventBus signals
	var eb = get_node_or_null("/root/EventBus")
	if eb and eb.has_signal("gunshot_fired"):
		eb.gunshot_fired.connect(_on_eventbus_gunshot)

func _on_eventbus_gunshot(pos: Vector3, _dir: Vector3, _is_heavy: bool) -> void:
	on_gunshot(pos)

# ---- overridables ---------------------------------------------------------
func _setup_species() -> void: pass
func _build_model() -> Node3D: return Node3D.new()
func _collision_shape() -> Shape3D:
	var b := BoxShape3D.new(); b.size = Vector3(0.6, 1.2, 1.8); return b
func _collision_offset() -> Vector3: return Vector3(0, 1.0, 0)
func _animate(_delta: float) -> void: pass

# ---- main loop ------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if state == State.DEAD or world == null:
		return
		
	# Fear memory decays at 0.01/s
	fear_memory = max(0.0, fear_memory - delta * 0.01)
	
	# Rumor propagation timer decay
	if rumor_timer > 0.0:
		rumor_timer -= delta
		if rumor_timer <= 0.0:
			rumor_threat_bonus = 0.0
			
	var hunter: Node3D = world.hunter
	var far := global_position.distance_to(hunter.global_position) > 300.0
	model.visible = not far
	sense_timer -= delta
	if sense_timer <= 0.0:
		sense_timer = 0.25 if not far else 1.0
		_sense(0.25 if not far else 1.0)
	_update_bleeding(delta)
	if state == State.DEAD:
		return
	_think(delta)
	if not far:
		_animate(delta)
	_leave_sign()

func _sense(dt: float) -> void:
	if state == State.FLEE or state == State.WOUNDED:
		return
	if spawn_grace_timer > 0.0:
		spawn_grace_timer -= dt
		awareness = 0.0
		return
	var hunter = world.hunter
	var hpos: Vector3 = hunter.global_position
	var to_h := hpos - global_position
	var dist := to_h.length()
	if dist > 400.0:
		awareness = max(awareness - dt * 0.2, 0.0)
		return
		
	var gs = get_node_or_null("/root/GameState")
	var fog_d: float = gs.fog_density if (gs and "fog_density" in gs) else 0.0
	var eff_sight: float = sight_range * (1.0 - fog_d * 0.6)
	
	var scent: float = world.wind.calculate_scent_exposure(hpos, global_position, scent_range) * hunter.scent_multiplier()
	var raw_noise_r: float = hunter.get_noise_radius() * hearing_mult
	var noise_r: float = raw_noise_r / (1.0 + fog_d * dist * 0.02)
	var sound: float = clamp(1.0 - dist / noise_r, 0.0, 1.0) if noise_r > 0.1 else 0.0
	var vis := 0.0
	if dist < eff_sight:
		var fwd := -global_transform.basis.z
		var ang := rad_to_deg(fwd.angle_to(to_h.normalized()))
		if ang < 150.0:
			var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.3, 0), hpos + Vector3(0, hunter.eye_height() * 0.8, 0), 1)
			q.exclude = [get_rid(), hunter.get_rid()]
			var hit := get_world_3d().direct_space_state.intersect_ray(q)
			if hit.is_empty():
				vis = (1.0 - dist / eff_sight) * hunter.visibility_factor()
	var threat := (scent * 2.2 + sound * 1.6 + vis * 1.4) + rumor_threat_bonus
	if threat > 0.05:
		awareness += threat * dt
	else:
		awareness = max(awareness - dt * 0.08, 0.0)
		
	var wary_thresh: float = 0.35 * (1.0 - fear_memory * 0.15)
	if awareness > 1.0:
		_start_flee(hpos, true)
	elif awareness > wary_thresh and state != State.ALERT:
		state = State.ALERT
		state_timer = randf_range(4.0, 8.0)
		target = hpos
		if randf() < 0.5:
			_snort_player.play()

func _think(delta: float) -> void:
	state_timer -= delta
	match state:
		State.GRAZE:
			speed = move_toward(speed, 0.0, delta * 3.0)
			if state_timer <= 0.0:
				_pick_wander_target(45.0)
		State.WALK:
			speed = move_toward(speed, walk_speed, delta * 2.0)
			_move_toward_point(target, delta)
			if global_position.distance_to(target) < 2.0 or state_timer <= 0.0:
				state = State.GRAZE
				state_timer = randf_range(6.0, 20.0)
		State.ALERT:
			speed = move_toward(speed, 0.0, delta * 6.0)
			_face(target, delta * 3.0)
			if state_timer <= 0.0:
				awareness *= 0.5
				state = State.GRAZE
				state_timer = randf_range(3.0, 8.0)
		State.FLEE, State.WOUNDED:
			var max_speed := run_speed
			if state == State.WOUNDED and bleed_time > 0.0:
				max_speed = lerp(run_speed * 0.35, run_speed, clamp(bleed_time / 20.0, 0.0, 1.0))
			speed = move_toward(speed, max_speed, delta * 8.0)
			_steer_flee(delta)
			if state_timer <= 0.0:
				if state == State.WOUNDED and bleed_time > 0.0:
					state_timer = 6.0
				else:
					awareness = 0.4
					_pick_wander_target(60.0)

func _pick_wander_target(radius: float) -> void:
	for i in 8:
		var p := global_position + Vector3(randf_range(-radius, radius), 0, randf_range(-radius, radius))
		if _is_walkable(p):
			target = p
			state = State.WALK
			state_timer = 40.0
			return
	state = State.GRAZE
	state_timer = 5.0

func _is_walkable(p: Vector3) -> bool:
	var t: Terrain = world.terrain
	var lim := Terrain.SIZE * 0.5 - 40.0
	if abs(p.x) > lim or abs(p.z) > lim:
		return false
	if t.height_at(p.x, p.z) < 0.15:
		return false
	return t.normal_at(p.x, p.z).y > 0.7

func _move_toward_point(p: Vector3, delta: float) -> void:
	var dir := p - global_position
	dir.y = 0.0
	if dir.length() < 0.1:
		return
	dir = dir.normalized()
	_face(global_position + dir, delta * 2.5)
	_advance(-global_transform.basis.z, delta)

func _steer_flee(delta: float) -> void:
	# Turn away from obstacles (water, cliffs, borders) while fleeing
	var probe := global_position + flee_dir * 8.0
	var tries := 0
	while not _is_walkable(probe) and tries < 12:
		flee_dir = flee_dir.rotated(Vector3.UP, deg_to_rad(30.0))
		probe = global_position + flee_dir * 8.0
		tries += 1
	_face(global_position + flee_dir, delta * 4.0)
	_advance(-global_transform.basis.z, delta)

func _advance(dir: Vector3, delta: float) -> void:
	var np := global_position + dir * speed * delta
	if not _is_walkable(np) and state != State.FLEE and state != State.WOUNDED:
		state = State.GRAZE
		state_timer = 2.0
		return
	np.y = world.terrain.height_at(np.x, np.z)
	global_position = np

func _face(p: Vector3, weight: float) -> void:
	var d := p - global_position
	d.y = 0.0
	if d.length() < 0.05:
		return
	var target_yaw := atan2(-d.x, -d.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clamp(weight, 0.0, 1.0))

func receive_rumor(bonus: float, duration: float) -> void:
	rumor_threat_bonus = bonus
	rumor_timer = duration

func _start_flee(from_pos: Vector3, alert_herd: bool) -> void:
	if state == State.DEAD:
		return
	if state != State.WOUNDED:
		state = State.FLEE
	state_timer = flee_time * randf_range(0.8, 1.3)
	flee_dir = (global_position - from_pos)
	flee_dir.y = 0.0
	flee_dir = flee_dir.normalized().rotated(Vector3.UP, randf_range(-0.4, 0.4))
	awareness = 1.2
	
	# Increment fear memory and persist in GameState
	fear_memory = min(1.0, fear_memory + 0.2)
	var gs = get_node_or_null("/root/GameState")
	if gs and "animal_fear" in gs and gs.animal_fear is Dictionary:
		gs.animal_fear[species] = fear_memory
		
	var eb = get_node_or_null("/root/EventBus")
	if eb and eb.has_signal("animal_spooked"):
		eb.animal_spooked.emit(get_instance_id(), global_position, awareness)
		
	if randf() < 0.7:
		_snort_player.play()
	if alert_herd:
		for m in herd:
			if is_instance_valid(m) and m != self and m.state != State.DEAD:
				if global_position.distance_to(m.global_position) <= 80.0 and m.has_method("receive_rumor"):
					m.receive_rumor(0.15, 90.0)
				if m.state != State.FLEE:
					m.call_deferred("_start_flee", from_pos, false)

func on_gunshot(pos: Vector3) -> void:
	if state == State.DEAD:
		return
	var d := global_position.distance_to(pos)
	if d < 350.0:
		_start_flee(pos, false)
	elif d < 600.0 and state != State.FLEE:
		state = State.ALERT
		state_timer = 8.0
		target = pos

func hear_call(kind: String, pos: Vector3) -> void:
	if kind != call_type or state == State.DEAD or state == State.FLEE or state == State.WOUNDED:
		return
	var d := global_position.distance_to(pos)
	if d > 320.0 or awareness > 0.6:
		return
	var p := pos + Vector3(randf_range(-25, 25), 0, randf_range(-25, 25))
	if _is_walkable(p):
		target = p
		state = State.WALK
		state_timer = 60.0
		speed = walk_speed

# ---- ballistics -----------------------------------------------------------
func take_hit(origin: Vector3, dir: Vector3, weapon: String, is_pellet: bool) -> String:
	if state == State.DEAD:
		return "Dead"
	var inv := global_transform.affine_inverse()
	var lo := inv * origin
	var ld := (inv.basis * dir).normalized()
	var organ := "Flesh"
	for z in hit_zones:
		if _ray_sphere(lo, ld, z.pos, z.r) and ORGAN_RANK[z.name] > ORGAN_RANK[organ]:
			organ = z.name
	if is_pellet and weight_kg > 20.0 and organ != "Brain":
		organ = "Flesh"
	hits.append(organ)
	if best_organ == "" or ORGAN_RANK[organ] > ORGAN_RANK[best_organ]:
		best_organ = organ
	shot_distance = global_position.distance_to(world.hunter.global_position)
	weapon_used = weapon
	_apply_wound(organ)
	_spawn_blood_fx(global_position + Vector3(0, 0.6, 0), -dir, organ)
	if state != State.DEAD:
		state = State.WOUNDED
		_start_flee(origin, true)
	return organ

func _spawn_blood_fx(pos: Vector3, normal: Vector3, organ: String) -> void:
	if not world:
		return
	var col := Color(0.85, 0.05, 0.05)
	var vel_mult := 1.0
	var grav_mult := 1.0
	var up_bias := 0.0
	
	match organ:
		"Brain", "Spine":
			col = Color(1.0, 0.2, 0.2) # Bright red
			vel_mult = 1.6
			grav_mult = 0.8
		"Heart":
			col = Color(0.55, 0.0, 0.0) # Dark crimson
			vel_mult = 1.1
			grav_mult = 1.4
		"Lungs":
			col = Color(1.0, 0.7, 0.75) # Frothy pink
			vel_mult = 1.0
			up_bias = 0.4
		"Liver":
			col = Color(0.36, 0.1, 0.1) # Deep maroon
			vel_mult = 0.7
			grav_mult = 1.6
			
	var count := randi_range(8, 15)
	for i in count:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = randf_range(0.02, 0.045)
		sm.height = sm.radius * 2.0
		s.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.4
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s.material_override = mat
		world.add_child(s)
		s.global_position = pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		
		var out_dir = (normal + Vector3(randf_range(-0.6, 0.6), randf_range(-0.2, 0.6) + up_bias, randf_range(-0.6, 0.6))).normalized()
		var p_vel = out_dir * randf_range(2.0, 5.0) * vel_mult
		
		var tween := s.create_tween()
		tween.tween_property(s, "scale", Vector3.ZERO, 1.2)
		tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 1.2)
		var end_pos = s.global_position + p_vel * 0.4 + Vector3(0, -0.6 * grav_mult, 0)
		tween.parallel().tween_property(s, "global_position", end_pos, 1.2)
		tween.tween_callback(s.queue_free)
		
	# Ground-aligned Blood Decal
	if world.terrain:
		var p_ground := pos
		p_ground.y = world.terrain.height_at(pos.x, pos.z) + 0.03
		var gn: Vector3 = world.terrain.normal_at(pos.x, pos.z)
		
		var decal := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.5, 0.5)
		pm.orientation = PlaneMesh.FACE_Y
		decal.mesh = pm
		
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var center := Vector2(32, 32)
		for px in 64:
			for py in 64:
				var dist_c := center.distance_to(Vector2(px, py))
				var angle := atan2(py - 32, px - 32)
				var blob_rad := 14.0 + sin(angle * 5.0) * 6.0 + cos(angle * 7.0) * 4.0
				if dist_c < blob_rad:
					var a: float = clamp((1.0 - (dist_c / blob_rad)) * 1.5, 0.0, randf_range(0.7, 0.9))
					img.set_pixel(px, py, Color(col.r, col.g, col.b, a))
				elif randf() < 0.02 and dist_c < 28.0:
					img.set_pixel(px, py, Color(col.r, col.g, col.b, randf_range(0.5, 0.8)))
					
		var tex := ImageTexture.create_from_image(img)
		var dmat := StandardMaterial3D.new()
		dmat.albedo_texture = tex
		dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		decal.material_override = dmat
		
		world.add_child(decal)
		decal.global_position = p_ground
		var up := Vector3.UP
		var axis := up.cross(gn)
		if axis.length() > 0.001:
			decal.basis = Basis(axis.normalized(), up.angle_to(gn)) * decal.basis
			
		var dtween := decal.create_tween()
		dtween.tween_property(dmat, "albedo_color:a", 0.0, 300.0)
		dtween.tween_callback(decal.queue_free)

func _ray_sphere(o: Vector3, d: Vector3, c: Vector3, r: float) -> bool:
	var oc := o - c
	var b := oc.dot(d)
	var cc := oc.dot(oc) - r * r
	return b * b - cc >= 0.0 and (-b + sqrt(max(b * b - cc, 0.0))) > 0.0

func _apply_wound(organ: String) -> void:
	var t := -1.0
	match organ:
		"Brain", "Spine": _die(); return
		"Heart": t = randf_range(3.0, 7.0)
		"Lungs": t = randf_range(9.0, 16.0)
		"Liver": t = randf_range(40.0, 70.0)
		"Stomach": t = randf_range(120.0, 200.0)
		"Flesh":
			if weight_kg < 20.0 or hits.count("Flesh") >= 3:
				t = randf_range(2.0, 6.0) if weight_kg < 20.0 else randf_range(60.0, 90.0)
	if t > 0.0:
		bleed_time = t if bleed_time < 0.0 else min(bleed_time, t)

func _update_bleeding(delta: float) -> void:
	if bleed_time > 0.0:
		bleed_time -= delta
		if bleed_time <= 0.0:
			_die()

func _die() -> void:
	state = State.DEAD
	speed = 0.0
	bleed_time = -1.0
	model.visible = true
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		col.disabled = true
	collision_layer = 0
	collision_mask = 0
	_on_death()

func _on_death() -> void:
	if world and world.terrain:
		var n: Vector3 = world.terrain.normal_at(global_position.x, global_position.z)
		global_position.y = world.terrain.height_at(global_position.x, global_position.z) + 0.15
		var up := Vector3.UP
		var axis := up.cross(n)
		if axis.length() > 0.001:
			basis = Basis(axis.normalized(), up.angle_to(n)) * basis
	model.rotation.z = deg_to_rad(85.0)
	model.position.y = 0.2

func _leave_sign() -> void:
	if world.tracks == null:
		return
	if global_position.distance_to(_last_track_pos) > track_spacing:
		var gait := "Running" if speed > walk_speed * 2.0 else "Walking"
		world.tracks.add_track(global_position, rotation.y, species, gait, self)
		_last_track_pos = global_position
	if bleed_time > 0.0 and global_position.distance_to(_last_blood_pos) > 1.6:
		world.tracks.add_blood(global_position, best_organ)
		_last_blood_pos = global_position

# ---- harvest --------------------------------------------------------------
func get_harvest_record() -> Dictionary:
	var desc := {"Brain": "Brain (instant)", "Spine": "Spine (instant)", "Heart": "Heart", "Lungs": "Lungs", "Liver": "Liver", "Stomach": "Stomach (poor shot)", "Flesh": "Flesh (non-vital)"}
	var ethic := {"Brain": 1.0, "Spine": 0.9, "Heart": 1.0, "Lungs": 0.95, "Liver": 0.7, "Stomach": 0.4, "Flesh": 0.3}
	var quality: float = ethic.get(best_organ, 0.5)
	return {
		"species_name": species,
		"gender": gender,
		"weight_kg": snapped(weight_kg, 0.1),
		"trophy_name": trophy_label,
		"trophy_score": snapped(trophy_score, 0.1),
		"organ_hit": desc.get(best_organ, best_organ),
		"shots": hits.size(),
		"harvest_quality": int(quality * 100.0),
		"shot_distance_m": snapped(shot_distance, 0.1),
		"weapon_used": weapon_used,
		"harvest_time": world.clock_string() if world.has_method("clock_string") else "",
		"date": Time.get_date_string_from_system(),
	}
