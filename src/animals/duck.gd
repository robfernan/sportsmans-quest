class_name Duck
extends Animal

## Mallard: swims on the lake, flushes when disturbed, circles, and lands back on water.
## Attracted by the duck call. Harvest with the 12GA shotgun (from shore or kayak).

enum DuckState { SWIM, WALK, FLY, FALLING }
var dstate: int = DuckState.SWIM
var wings: Array = []
var fly_center := Vector3.ZERO
var fly_angle := 0.0
var fly_height := 0.0
var fly_timer := 0.0
var vel_y := 0.0
var flap := 0.0
var _quack: AudioStreamPlayer3D
var _quack_timer := 0.0

func _setup_species() -> void:
	species = "Mallard"
	gender = "Male" if randf() < 0.55 else "Female"
	weight_kg = randf_range(0.9, 1.5)
	trophy_score = weight_kg * 12.0 + randf_range(0.0, 4.0)
	trophy_label = "Plumage Score"
	call_type = "duck_call"
	hit_zones = [
		{"name": "Heart", "pos": Vector3(0, 0.12, 0), "r": 0.25},
		{"name": "Brain", "pos": Vector3(0, 0.28, -0.2), "r": 0.15},
		{"name": "Flesh", "pos": Vector3(0, 0.15, 0), "r": 0.40}
	]

func setup(w: Node, pos: Vector3) -> void:
	super.setup(w, pos)
	_quack = AudioStreamPlayer3D.new()
	_quack.bus = AudioDirector.BUS_SFX
	_quack.stream = AudioSynth.quack()
	_quack.unit_size = 2.5
	_quack.max_distance = 35.0
	_quack.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(_quack)
	_quack_timer = randf_range(15.0, 45.0)
	global_position.y = Terrain.WATER_LEVEL

func _collision_shape() -> Shape3D:
	var s := SphereShape3D.new()
	s.radius = 0.4   # generous for shotgun gameplay
	return s

func _collision_offset() -> Vector3:
	return Vector3(0, 0.15, 0)

func _build_model() -> Node3D:
	var root := Node3D.new()
	var sphere := SphereMesh.new(); sphere.radial_segments = 10; sphere.rings = 5
	var body_c := Color(0.55, 0.5, 0.45) if gender == "Male" else Color(0.5, 0.38, 0.25)
	var head_c := Color(0.05, 0.45, 0.18) if gender == "Male" else Color(0.45, 0.33, 0.22) # Emerald green head
	var parts := [
		[body_c, Vector3(0, 0.18, 0), Vector3(0.38, 0.28, 0.62)],
		[Color(0.38, 0.22, 0.14) if gender == "Male" else body_c, Vector3(0, 0.22, -0.22), Vector3(0.32, 0.26, 0.28)],
		[head_c, Vector3(0, 0.48, -0.32), Vector3(0.18, 0.18, 0.22)],
		[Color(0.95, 0.78, 0.15), Vector3(0, 0.45, -0.48), Vector3(0.08, 0.05, 0.15)], # Yellow bill
		[Color(0.1, 0.1, 0.1), Vector3(0, 0.25, 0.35), Vector3(0.16, 0.1, 0.16)], # Tail
	]
	for p in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		var m := StandardMaterial3D.new(); m.albedo_color = p[0]; m.roughness = 0.7
		mi.material_override = m
		mi.position = p[1]
		mi.scale = p[2]
		root.add_child(mi)
	var wing_mesh := BoxMesh.new(); wing_mesh.size = Vector3(0.65, 0.03, 0.28)
	var wm := StandardMaterial3D.new(); wm.albedo_color = body_c.darkened(0.15)
	for sx in [-1, 1]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.18 * sx, 0.26, 0.0)
		root.add_child(pivot)
		var w := MeshInstance3D.new()
		w.mesh = wing_mesh
		w.material_override = wm
		w.position = Vector3(0.32 * sx, 0, 0)
		pivot.add_child(w)
		pivot.visible = false
		wings.append(pivot)
	return root

func _physics_process(delta: float) -> void:
	if world == null:
		return
	if state == State.DEAD and dstate != DuckState.FALLING:
		return
	# Ensure duck 3D model is always rendered for nearby and flying ducks
	model.visible = true
	match dstate:
		DuckState.SWIM: _swim(delta)
		DuckState.WALK: _walk_shoreline(delta)
		DuckState.FLY: _fly(delta)
		DuckState.FALLING: _fall(delta)
	_quack_timer -= delta
	if _quack_timer <= 0.0 and state != State.DEAD:
		_quack_timer = randf_range(18.0, 50.0)
		if world and world.hunter and global_position.distance_to(world.hunter.global_position) < 35.0:
			_quack.play()

func _swim(delta: float) -> void:
	global_position.y = Terrain.WATER_LEVEL + sin(Time.get_ticks_msec() * 0.002 + get_instance_id()) * 0.02
	state_timer -= delta
	if state_timer <= 0.0:
		state_timer = randf_range(6.0, 16.0)
		# 25% chance to waddle up to the grassy shore
		if randf() < 0.25:
			dstate = DuckState.WALK
			target = global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
			return
		var p := global_position + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
		if world.terrain.is_water(p.x, p.z):
			target = p
	var d := target - global_position
	d.y = 0
	if d.length() > 0.5:
		_face(target, delta * 2.0)
		global_position += -global_transform.basis.z * 0.5 * delta
	# Disturbance check
	var h = world.hunter
	var dist := global_position.distance_to(h.global_position)
	var flush_r: float = 18.0 + h.get_noise_radius() * 0.6
	if h.is_in_kayak:
		flush_r *= 0.6
	if dist < flush_r:
		_take_off(h.global_position)

func _walk_shoreline(delta: float) -> void:
	# Waddling on the grass/mud above the waterline
	var ground = world.terrain.height_at(global_position.x, global_position.z)
	global_position.y = max(ground, Terrain.WATER_LEVEL)
	
	state_timer -= delta
	if state_timer <= 0.0:
		state_timer = randf_range(8.0, 18.0)
		# Decide whether to head back to water or peck grass
		if randf() < 0.5:
			dstate = DuckState.SWIM
			target = world.lake_center() + Vector3(randf_range(-25, 25), 0, randf_range(-25, 25))
		else:
			target = global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
			
	var d := target - global_position
	d.y = 0
	if d.length() > 0.5:
		_face(target, delta * 3.0)
		global_position += -global_transform.basis.z * 0.8 * delta
		# Cute waddle roll animation
		model.rotation.z = sin(Time.get_ticks_msec() * 0.01) * 0.12
	else:
		model.rotation.z = 0.0
		
	# Check for hunter disturbance on grass
	var h = world.hunter
	if global_position.distance_to(h.global_position) < (22.0 + h.get_noise_radius() * 0.7):
		_take_off(h.global_position)

func _take_off(_from: Vector3) -> void:
	if state == State.DEAD:
		return
	dstate = DuckState.FLY
	state = State.FLEE
	fly_center = world.lake_center()
	fly_angle = atan2(global_position.z - fly_center.z, global_position.x - fly_center.x)
	fly_height = randf_range(22.0, 38.0)
	fly_timer = randf_range(20.0, 40.0)
	for w in wings:
		w.visible = true
	model.rotation.z = 0.0
	_quack.play()

func _fly(delta: float) -> void:
	fly_timer -= delta
	fly_angle += delta * 0.18
	var radius := 75.0
	
	# Keep flight path strictly above highest ground beneath bird
	var ground_y: float = max(world.terrain.height_at(global_position.x, global_position.z), Terrain.WATER_LEVEL)
	var tgt_y: float = max(ground_y + 16.0, fly_height)
	
	if fly_timer <= 0.0:
		# Landing phase: only descend toward water level or landing spot
		tgt_y = Terrain.WATER_LEVEL
		
	var goal := fly_center + Vector3(cos(fly_angle) * radius, 0, sin(fly_angle) * radius)
	goal.y = global_position.y
	var dir := (goal - global_position)
	dir.y = 0
	_face(global_position + dir, delta * 2.0)
	global_position += -global_transform.basis.z * 13.0 * delta
	
	# Smoothly adjust altitude, NEVER clipping into ground
	global_position.y = move_toward(global_position.y, tgt_y, delta * (7.0 if fly_timer > 0.0 else 3.5))
	if global_position.y < ground_y + 0.3 and fly_timer > 0.0:
		global_position.y = ground_y + 0.3
		
	flap += delta * 18.0
	for i in wings.size():
		wings[i].rotation.z = sin(flap) * 0.9 * (1 if i == 0 else -1)
		
	# Touchdown check
	if fly_timer <= 0.0:
		if world.terrain.is_water(global_position.x, global_position.z) and global_position.y <= Terrain.WATER_LEVEL + 0.15:
			dstate = DuckState.SWIM
			state = State.GRAZE
			for w in wings:
				w.visible = false
		elif global_position.y <= ground_y + 0.15:
			dstate = DuckState.WALK
			state = State.GRAZE
			for w in wings:
				w.visible = false

func hear_call(kind: String, pos: Vector3) -> void:
	if kind != "duck_call" or state == State.DEAD:
		return
	if dstate == DuckState.FLY:
		fly_center = pos
		fly_timer = min(fly_timer, 12.0)
	elif world.terrain.is_water(pos.x, pos.z) or global_position.distance_to(pos) < 120.0:
		target = pos + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))

func on_gunshot(pos: Vector3) -> void:
	if dstate == DuckState.SWIM and global_position.distance_to(pos) < 250.0:
		_take_off(pos)

func _die() -> void:
	state = State.DEAD
	bleed_time = -1.0
	for w in wings:
		w.visible = false
	model.rotation.z = deg_to_rad(120)
	if global_position.y > Terrain.WATER_LEVEL + 0.2:
		dstate = DuckState.FALLING
		vel_y = 0.0

func _fall(delta: float) -> void:
	vel_y -= 9.8 * delta
	global_position.y += vel_y * delta
	var ground: float = max(world.terrain.height_at(global_position.x, global_position.z), Terrain.WATER_LEVEL)
	if global_position.y <= ground:
		global_position.y = ground
		dstate = DuckState.SWIM
		print("[Waterfowl Down] Mallard struck down! Floating on surface ready for dog retrieval or claim.")

func _sense(_dt: float) -> void:
	pass
