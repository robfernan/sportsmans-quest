class_name RetrieverDog
extends CharacterBody3D

## Hunting Companion Dog (Golden Retriever / Labrador)
## Inspired by Hunting Simulator 2. Supports Water Retrieval, Blood Tracking, and Heeling.

signal retrieve_finished(item: Node)

enum DogCommand { HEEL_FOLLOW, STAY_SIT, TRACK_BLOOD, WATER_FETCH }

@export var follow_distance: float = 3.2
@export var run_speed: float = 7.5
@export var swim_speed: float = 4.2

var current_command: DogCommand = DogCommand.HEEL_FOLLOW
var target_hunter: Node3D = null
var fetch_target_item: Node3D = null
var _carry: Node3D = null
var _returning: bool = false
var _sniffed: Array[Vector3] = []
var model_root: Node3D = null
var tail: Node3D = null
var legs: Array[MeshInstance3D] = []
var walk_cycle: float = 0.0

func _ready() -> void:
	target_hunter = get_tree().root.find_child("Hunter", true, false)
	
	# Instantiate visual 3D dog model
	model_root = DogModelBuilder.build_retriever_model()
	add_child(model_root)
	
	tail = model_root.find_child("Tail", true, false) as Node3D
	for i in 4:
		var leg = model_root.find_child("Leg_%d" % i, true, false) as MeshInstance3D
		if leg:
			legs.append(leg)

func _physics_process(delta: float) -> void:
	match current_command:
		DogCommand.HEEL_FOLLOW:
			_heel_hunter(delta)
		DogCommand.STAY_SIT:
			velocity = Vector3.ZERO
		DogCommand.WATER_FETCH:
			_swim_and_retrieve(delta)
		DogCommand.TRACK_BLOOD:
			_track_blood_trail(delta)

	if not is_on_floor() and global_position.y > 0.0:
		velocity.y -= 9.8 * delta
	move_and_slide()
	_float_while_retrieving()
	
	_animate_dog(delta)

func _animate_dog(delta: float) -> void:
	var horiz_vel := Vector2(velocity.x, velocity.z)
	var speed := horiz_vel.length()
	
	if speed > 0.2:
		walk_cycle += delta * (speed * 2.2)
		# Leg oscillation
		if legs.size() == 4:
			legs[0].rotation.x = sin(walk_cycle) * 0.45
			legs[1].rotation.x = -sin(walk_cycle) * 0.45
			legs[2].rotation.x = -sin(walk_cycle) * 0.45
			legs[3].rotation.x = sin(walk_cycle) * 0.45
		if tail:
			tail.rotation.y = sin(walk_cycle * 2.0) * 0.35
	else:
		# Idle tail wag
		if tail:
			tail.rotation.y = sin(Time.get_ticks_msec() * 0.005) * 0.2
		if legs.size() == 4:
			for leg in legs:
				leg.rotation.x = move_toward(leg.rotation.x, 0.0, delta * 3.0)

func _heel_hunter(delta: float) -> void:
	if not target_hunter:
		target_hunter = get_tree().root.find_child("Hunter", true, false)
		return
	
	var to_hunter = target_hunter.global_position - global_position
	var dist = to_hunter.length()

	if dist > follow_distance:
		var dir = to_hunter.normalized()
		velocity.x = dir.x * run_speed
		velocity.z = dir.z * run_speed
		look_at(Vector3(target_hunter.global_position.x, global_position.y, target_hunter.global_position.z), Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, delta * 12.0)
		velocity.z = move_toward(velocity.z, 0, delta * 12.0)

func order_fetch(item: Node3D) -> void:
	fetch_target_item = item
	_carry = null
	_returning = false
	current_command = DogCommand.WATER_FETCH
	print("[Retriever Dog] Commanded to fetch! Diving in to retrieve harvest.")

func order_track() -> void:
	_sniffed.clear()
	current_command = DogCommand.TRACK_BLOOD
	print("[Retriever Dog] Nose down. Working the blood trail.")

func order_sit() -> void:
	current_command = DogCommand.STAY_SIT
	velocity = Vector3.ZERO
	print("[Retriever Dog] Commanded to sit/stay.")

func order_heel() -> void:
	current_command = DogCommand.HEEL_FOLLOW
	print("[Retriever Dog] Commanded to heel and follow.")

func _swim_and_retrieve(_delta: float) -> void:
	if _returning:
		if not target_hunter or not is_instance_valid(target_hunter):
			target_hunter = get_tree().root.find_child("Hunter", true, false)
		if target_hunter == null:
			current_command = DogCommand.HEEL_FOLLOW
			return
		var to_hunter := target_hunter.global_position - global_position
		to_hunter.y = 0.0
		if to_hunter.length() > 2.4:
			var dir := to_hunter.normalized()
			velocity.x = dir.x * swim_speed
			velocity.z = dir.z * swim_speed
			look_at(global_position + dir, Vector3.UP)
		else:
			var carried := _carry
			_carry = null
			_returning = false
			fetch_target_item = null
			current_command = DogCommand.HEEL_FOLLOW
			print("[Retriever Dog] Retrieved waterfowl! Bringing back to hunter.")
			if carried and is_instance_valid(carried):
				retrieve_finished.emit(carried)
		return

	if not fetch_target_item or not is_instance_valid(fetch_target_item):
		current_command = DogCommand.HEEL_FOLLOW
		return

	var to_item := fetch_target_item.global_position - global_position
	to_item.y = 0.0
	var dist := to_item.length()

	if dist > 1.4:
		var dir := to_item.normalized()
		velocity.x = dir.x * swim_speed
		velocity.z = dir.z * swim_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		# Keep the carcass in the world. Reparenting a CharacterBody3D fights physics.
		if fetch_target_item is Animal:
			fetch_target_item.set_physics_process(false)
		_carry = fetch_target_item
		_returning = true
		print("[Retriever Dog] Has the bird. Swimming back.")

func _float_while_retrieving() -> void:
	if current_command != DogCommand.WATER_FETCH:
		return
	var world = get_parent()
	if world and world.terrain and world.terrain.is_water(global_position.x, global_position.z):
		global_position.y = Terrain.WATER_LEVEL + 0.2
		velocity.y = 0.0
	if _carry and is_instance_valid(_carry):
		_carry.global_position = global_position + Vector3(0, 0.35, -0.45)

func _track_blood_trail(_delta: float) -> void:
	var world = get_parent()
	if world == null or world.tracks == null or world.tracks.blood.is_empty():
		order_heel()
		return
	var found := false
	var best_pos := Vector3.ZERO
	var best_d := 70.0
	for b in world.tracks.blood:
		var p: Vector3 = b.pos
		var skip := false
		for sniffed in _sniffed:
			if p.distance_to(sniffed) < 1.2:
				skip = true
				break
		if skip:
			continue
		var d := global_position.distance_to(p)
		if d < best_d:
			best_d = d
			best_pos = p
			found = true
	if not found:
		print("[Retriever Dog] Lost the line.")
		order_heel()
		return
	if best_d < 1.3:
		_sniffed.append(best_pos)
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir := best_pos - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		return
	dir = dir.normalized()
	velocity.x = dir.x * run_speed * 0.85
	velocity.z = dir.z * run_speed * 0.85
	look_at(global_position + dir, Vector3.UP)
