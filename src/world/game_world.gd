class_name GameWorld
extends Node3D

## Master Game World for Sportsman's Quest ("Whispering Pines Reserve")
## Builds procedural terrain, chunked vegetation, animated water, wildlife populations,
## tracking decals, and manages global wildlife sensory broadcasts.

@export var reserve_seed: int = 1337

var terrain: Terrain
var vegetation: Vegetation
var wind: WindSystem
var tracks: TrackManager
var hunter: HunterController
var kayak: KayakController
var dog: RetrieverDog

var animals: Array = []
var _ambient_wind_player: AudioStreamPlayer
var _bird_player: AudioStreamPlayer
var _bird_timer: float = 4.0
var _session_time_seconds: float = 7.5 * 3600.0 # Starts at 07:30 AM (morning hunt)

func _ready() -> void:
	print("[Sportsman's Quest] Initializing Whispering Pines Reserve...")
	_setup_environment()
	_build_terrain_and_nature()
	_spawn_player_and_vehicles()
	_populate_wildlife()
	_init_ambient_audio()
	print("[Sportsman's Quest] Reserve loaded and ready for hunt!")

func _setup_environment() -> void:
	# Add WindSystem & WeatherSystem
	wind = WindSystem.new()
	wind.name = "WindSystem"
	add_child(wind)

	var weather := WeatherSystem.new()
	weather.name = "WeatherSystem"
	add_child(weather)

	# WorldEnvironment & Halloween Twilight Night Lighting
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.04, 0.05, 0.12) # Midnight purple-black
	sky_mat.sky_horizon_color = Color(0.24, 0.12, 0.28) # Blood twilight horizon
	sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.04)
	sky_mat.ground_horizon_color = Color(0.18, 0.10, 0.20)
	sky.sky_material = sky_mat
	env.sky = sky
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.22, 0.14, 0.28)
	env.fog_density = 0.0055 # Atmospheric autumn mist

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Eerie Harvest Blood Moon Light
	var moon := DirectionalLight3D.new()
	moon.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(35.0)) * Basis(Vector3.RIGHT, deg_to_rad(-40.0)), Vector3(0, 50, 0))
	moon.shadow_enabled = false # Disabled real-time directional shadow mapping for silky smooth 60fps WebGL
	moon.light_color = Color(0.85, 0.65, 0.95) # Pale lunar lavender
	moon.light_energy = 0.9
	add_child(moon)

func _build_terrain_and_nature() -> void:
	# 1. Heightmap Terrain
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build(reserve_seed)

	# 2. Water Plane over Lake Basin
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(Terrain.SIZE, Terrain.SIZE)
	var water_mat := ShaderMaterial.new()
	water_mat.shader = load("res://src/world/water.gdshader")
	var water_inst := MeshInstance3D.new()
	water_inst.mesh = water_mesh
	water_inst.material_override = water_mat
	water_inst.position.y = Terrain.WATER_LEVEL
	add_child(water_inst)

	# 3. Track & Spoor Manager
	tracks = TrackManager.new()
	tracks.name = "TrackManager"
	add_child(tracks)
	tracks.setup(terrain)

	# 4. MultiMesh Chunked Vegetation
	vegetation = Vegetation.new()
	vegetation.name = "Vegetation"
	add_child(vegetation)
	var spawn_pos := Vector3(15.0, terrain.height_at(15.0, -10.0), -10.0)
	vegetation.build(terrain, 1, spawn_pos)

	# 5. Reserve Architectural Landmarks (Hunting Stands, Pier, Trapper Cabin)
	_build_reserve_landmarks()

func _build_reserve_landmarks() -> void:
	# Shoreline Pier / Boat Dock at lake edge
	var dock := LandmarkBuilder.build_boat_dock()
	dock.position = Vector3(2.0, Terrain.WATER_LEVEL, 4.0)
	dock.rotation.y = deg_to_rad(-45.0)
	add_child(dock)

	# Elevated Wooden Hunting Stand overlooking the meadow
	var stand1 := LandmarkBuilder.build_hunting_stand()
	var s1_pos := Vector3(35.0, 0, -25.0)
	s1_pos.y = terrain.height_at(s1_pos.x, s1_pos.z)
	stand1.position = s1_pos
	stand1.rotation.y = deg_to_rad(130.0)
	add_child(stand1)

	# Secondary Hunting Stand on North Ridge
	var stand2 := LandmarkBuilder.build_hunting_stand()
	var s2_pos := Vector3(-20.0, 0, -85.0)
	s2_pos.y = terrain.height_at(s2_pos.x, s2_pos.z)
	stand2.position = s2_pos
	stand2.rotation.y = deg_to_rad(30.0)
	add_child(stand2)

	# Historic Trapper's Cabin landmark on East Ridge
	var cabin := LandmarkBuilder.build_trapper_cabin()
	var c_pos := Vector3(70.0, 0, -15.0)
	c_pos.y = terrain.height_at(c_pos.x, c_pos.z)
	cabin.position = c_pos
	cabin.rotation.y = deg_to_rad(-65.0)
	add_child(cabin)

func _spawn_player_and_vehicles() -> void:
	# Spawn Hunter on the shoreline overlooking the lake
	var spawn_x := 15.0
	var spawn_z := -10.0
	var spawn_y := terrain.height_at(spawn_x, spawn_z) + 1.2

	var hunter_scene: PackedScene = load("res://src/player/hunter.tscn")
	hunter = hunter_scene.instantiate() as HunterController
	hunter.name = "Hunter"
	hunter.position = Vector3(spawn_x, spawn_y, spawn_z)
	add_child(hunter)

	# Spawn Kayak at water edge
	kayak = KayakController.new()
	kayak.name = "Kayak"
	kayak.mass = 45.0
	kayak.water_surface_y = Terrain.WATER_LEVEL
	kayak.position = Vector3(-5.0, 0.2, 5.0)
	add_child(kayak)

	var kcol := CollisionShape3D.new()
	var kbox := BoxShape3D.new(); kbox.size = Vector3(1.0, 0.5, 3.5)
	kcol.shape = kbox
	kayak.add_child(kcol)

	var kmesh := MeshInstance3D.new()
	var kb := BoxMesh.new(); kb.size = Vector3(0.9, 0.4, 3.4)
	var kmat := StandardMaterial3D.new(); kmat.albedo_color = Color(0.18, 0.45, 0.28)
	kmesh.mesh = kb; kmesh.material_override = kmat
	kayak.add_child(kmesh)

	# Spawn Dog Companion
	dog = RetrieverDog.new()
	dog.name = "HuntingDog"
	dog.position = Vector3(spawn_x + 2.0, spawn_y, spawn_z + 1.5)
	add_child(dog)

	var dcol := CollisionShape3D.new()
	var dbox := BoxShape3D.new(); dbox.size = Vector3(0.4, 0.6, 0.9)
	dcol.shape = dbox
	dog.add_child(dcol)

	# Add HUD, Pie Menu, Harvest Screen, and Huntermate GPS Map
	var hud_scene: PackedScene = load("res://src/ui/hunting_hud.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		add_child(hud)

	var pie_scene: PackedScene = load("res://src/ui/pie_menu.tscn")
	if pie_scene:
		var pie = pie_scene.instantiate()
		add_child(pie)
		pie.item_selected.connect(_on_pie_item_selected)

	var harvest_scene: PackedScene = load("res://src/ui/harvest_screen.tscn")
	if harvest_scene:
		var hs = harvest_scene.instantiate()
		add_child(hs)

	var map_scene: PackedScene = load("res://src/ui/huntermate_map.tscn")
	if map_scene:
		var hm = map_scene.instantiate()
		add_child(hm)

func _on_pie_item_selected(item_id: String) -> void:
	if not hunter:
		return
	match item_id:
		"rifle": hunter.equip_slot(HunterController.WeaponSlot.RIFLE)
		"shotgun": hunter.equip_slot(HunterController.WeaponSlot.SHOTGUN)
		"binoculars": hunter.equip_slot(HunterController.WeaponSlot.BINOCULARS)
		"deer_call": hunter.equip_slot(HunterController.WeaponSlot.DEER_CALL)
		"duck_call": hunter.equip_slot(HunterController.WeaponSlot.DUCK_CALL)

func _populate_wildlife() -> void:
	# 1. Primary Whitetail Herd (Buck + 2 Does) Meadow near Spawn
	var h1: Array = []
	var deer_spawn := Vector3(25.0, 0, -45.0)
	deer_spawn.y = terrain.height_at(deer_spawn.x, deer_spawn.z)
	for i in 3:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = deer_spawn + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h1.append(d)
	for d in h1: d.herd = h1

	# 2. Secondary Whitetail Herd (North Ridge Meadow)
	var h2: Array = []
	var ridge_spawn := Vector3(-40.0, 0, -110.0)
	ridge_spawn.y = terrain.height_at(ridge_spawn.x, ridge_spawn.z)
	for i in 3:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = ridge_spawn + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h2.append(d)
	for d in h2: d.herd = h2

	# 3. Third Whitetail Herd (East Timber Glade)
	var h3: Array = []
	var east_spawn := Vector3(90.0, 0, -30.0)
	east_spawn.y = terrain.height_at(east_spawn.x, east_spawn.z)
	for i in 3:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = east_spawn + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h3.append(d)
	for d in h3: d.herd = h3

	# 4. Solitary Trophy Bucks (Deep Ridge & South Pines)
	var trophy_spots = [
		Vector3(-85.0, 0, -70.0),
		Vector3(110.0, 0, 45.0)
	]
	for tsp in trophy_spots:
		var tb := Deer.new()
		tb.gender = "Male"
		add_child(tb)
		tsp.y = terrain.height_at(tsp.x, tsp.z)
		tb.setup(self, tsp)
		animals.append(tb)

	# 5. Vivid Red Fox Population (4 foxes hunting across forest borders)
	var fox_spawns = [
		Vector3(45.0, 0, 35.0),
		Vector3(-30.0, 0, 95.0),
		Vector3(75.0, 0, -85.0),
		Vector3(-60.0, 0, -40.0)
	]
	for fsp in fox_spawns:
		var f := Fox.new()
		add_child(f)
		fsp.y = terrain.height_at(fsp.x, fsp.z)
		f.setup(self, fsp)
		animals.append(f)

	# 6. Mallards flocking in the lake basin and walking on shore
	var lcenter := lake_center()
	for i in 8:
		var duck := Duck.new()
		add_child(duck)
		var dp := lcenter + Vector3(randf_range(-35, 35), 0, randf_range(-35, 35))
		duck.setup(self, dp)
		animals.append(duck)

	# 7. HALLOWEEN SPECIAL: Spawn Jack-O'-Lanterns along shoreline and spawn area
	var pumpkin_spots = [
		Vector3(14.0, 0, -8.0),
		Vector3(16.5, 0, -12.0),
		Vector3(10.0, 0, -5.0),
		Vector3(3.0, 0, 8.0),
		Vector3(-8.0, 0, 12.0),
		Vector3(22.0, 0, -20.0),
		Vector3(40.0, 0, -35.0),
		Vector3(-25.0, 0, 30.0)
	]
	for sp in pumpkin_spots:
		var pkin := JackOLantern.new()
		add_child(pkin)
		sp.y = terrain.height_at(sp.x, sp.z) + 0.2
		pkin.global_position = sp
		pkin.rotation.y = randf() * TAU

	# 8. HALLOWEEN LEGEND: Spawn the Mythical Ghost Buck across the ridge
	var ghost := GhostBuck.new()
	add_child(ghost)
	var gp := Vector3(32.0, 0, -65.0)
	gp.y = terrain.height_at(gp.x, gp.z)
	ghost.setup(self, gp)
	animals.append(ghost)

	# 9. APEX PREDATOR: Spawn Werewolf stalking the pine timber edge
	var wolf := Werewolf.new()
	add_child(wolf)
	var wp := Vector3(-45.0, 0, 75.0)
	wp.y = terrain.height_at(wp.x, wp.z)
	wolf.setup(self, wp)
	animals.append(wolf)

	# 10. CRYPTID HORROR: Spawn the Wendigo lurking deep in the foggy valley
	var wen := Wendigo.new()
	add_child(wen)
	var wnp := Vector3(65.0, 0, 85.0)
	wnp.y = terrain.height_at(wnp.x, wnp.z)
	wen.setup(self, wnp)
	animals.append(wen)

func _init_ambient_audio() -> void:
	_ambient_wind_player = AudioStreamPlayer.new()
	_ambient_wind_player.stream = AudioSynth.wind_loop()
	_ambient_wind_player.volume_db = -18.0
	add_child(_ambient_wind_player)
	_ambient_wind_player.play()

	_bird_player = AudioStreamPlayer.new()
	_bird_player.volume_db = -24.0
	add_child(_bird_player)

func _physics_process(delta: float) -> void:
	_session_time_seconds += delta * 4.0 # 4x in-game time progression
	_bird_timer -= delta
	if _bird_timer <= 0.0:
		# Balanced ambient chirping: Every 25 to 55 seconds (natural immersion, not constant spam)
		_bird_timer = randf_range(25.0, 55.0)
		_bird_player.stream = AudioSynth.bird_chirp()
		_bird_player.play()

func lake_center() -> Vector3:
	return Vector3(Terrain.LAKE_CENTER.x, Terrain.WATER_LEVEL, Terrain.LAKE_CENTER.y)

func clock_string() -> String:
	var total_min: int = int(_session_time_seconds / 60.0)
	var hrs: int = int(total_min / 60.0) % 24
	var mins: int = total_min % 60
	var ampm := "AM" if hrs < 12 else "PM"
	var disp_hr := hrs if (hrs > 0 and hrs <= 12) else (hrs - 12 if hrs > 12 else 12)
	return "%02d:%02d %s" % [disp_hr, mins, ampm]

func broadcast_gunshot(pos: Vector3) -> void:
	for a in animals:
		if is_instance_valid(a) and a.has_method("on_gunshot"):
			a.on_gunshot(pos)

func broadcast_animal_call(kind: String, pos: Vector3) -> void:
	for a in animals:
		if is_instance_valid(a) and a.has_method("hear_call"):
			a.hear_call(kind, pos)
