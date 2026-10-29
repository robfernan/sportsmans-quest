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
var _bird_timer := 4.0
const _CRYPTID_HUSH_M := 80.0
var _ravens_node: Node3D = null
var _session_time_seconds: float = 6.0 * 3600.0 # Starts at 06:00 AM (or 10:30 PM if Night Hunt)
var _sun_light: DirectionalLight3D
var _env: Environment
var _time_update_timer: float = 0.0
var _wind_param_timer: float = 0.0

func _ready() -> void:
	print("[Sportsman's Quest] Initializing Whispering Pines Reserve...")
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.is_night_hunt:
		_session_time_seconds = 22.5 * 3600.0 # 10:30 PM Night Hunt
		print("[Sportsman's Quest] NIGHT HUNT MODE ACTIVATED. Cryptids roaming.")
	else:
		_session_time_seconds = 6.0 * 3600.0 # 06:00 AM Dawn Hunt
		
	_setup_environment()
	_build_terrain_and_nature()
	_spawn_player_and_vehicles()
	_populate_wildlife()
	_init_ambient_audio()
	_update_lighting_and_fog(0.0)
	print("[Sportsman's Quest] Reserve loaded and ready for hunt!")

func _setup_environment() -> void:
	# Add WindSystem & WeatherSystem
	wind = WindSystem.new()
	wind.name = "WindSystem"
	add_child(wind)

	var weather := WeatherSystem.new()
	weather.name = "WeatherSystem"
	add_child(weather)

	var gs = get_node_or_null("/root/GameState")
	var is_night = gs.is_night_hunt if gs else false

	# WorldEnvironment & Procedural Sky (Halloween Spooky Sky)
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	if is_night:
		sky_mat.sky_top_color = Color(0.02, 0.015, 0.05) # Deep midnight abyss
		sky_mat.sky_horizon_color = Color(0.38, 0.14, 0.32) # Eerie blood-violet glow
		sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.02)
		sky_mat.ground_horizon_color = Color(0.16, 0.08, 0.18)
		_env.fog_light_color = Color(0.24, 0.12, 0.26)
		_env.fog_density = 0.0075
	else:
		sky_mat.sky_top_color = Color(0.08, 0.10, 0.22) # Crisp autumn sky
		sky_mat.sky_horizon_color = Color(0.55, 0.28, 0.24) # Golden-amber twilight horizon
		sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.04)
		sky_mat.ground_horizon_color = Color(0.28, 0.16, 0.14)
		_env.fog_light_color = Color(0.35, 0.25, 0.28)
		_env.fog_density = 0.0048
	sky.sky_material = sky_mat
	_env.sky = sky
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true

	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

	# Directional Sun / Moon Light
	_sun_light = DirectionalLight3D.new()
	_sun_light.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(35.0)) * Basis(Vector3.RIGHT, deg_to_rad(-40.0)), Vector3(0, 50, 0))
	_sun_light.shadow_enabled = false
	if is_night:
		_sun_light.light_color = Color(0.85, 0.70, 0.95)
		_sun_light.light_energy = 0.55
	else:
		_sun_light.light_color = Color(1.0, 0.88, 0.75)
		_sun_light.light_energy = 1.05
	add_child(_sun_light)

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
	if not dog.retrieve_finished.is_connected(_on_dog_retrieved):
		dog.retrieve_finished.connect(_on_dog_retrieved)

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

func _on_dog_retrieved(item: Node) -> void:
	if hunter and is_instance_valid(item):
		hunter.claim_harvest(item)

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
	var gs = get_node_or_null("/root/GameState")
	var is_night = gs.is_night_hunt if gs else false

	# 1. Primary Whitetail Herd (Buck + 3 Does) Meadow near Spawn
	var h1: Array = []
	var deer_spawn := Vector3(25.0, 0, -45.0)
	deer_spawn.y = terrain.height_at(deer_spawn.x, deer_spawn.z)
	for i in 4:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = deer_spawn + Vector3(randf_range(-7, 7), 0, randf_range(-7, 7))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h1.append(d)
	for d in h1: d.herd = h1

	# 2. Secondary Whitetail Herd (North Ridge Meadow - 4 deer)
	var h2: Array = []
	var ridge_spawn := Vector3(-40.0, 0, -110.0)
	ridge_spawn.y = terrain.height_at(ridge_spawn.x, ridge_spawn.z)
	for i in 4:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = ridge_spawn + Vector3(randf_range(-9, 9), 0, randf_range(-9, 9))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h2.append(d)
	for d in h2: d.herd = h2

	# 3. Third Whitetail Herd (East Timber Glade - 4 deer)
	var h3: Array = []
	var east_spawn := Vector3(90.0, 0, -30.0)
	east_spawn.y = terrain.height_at(east_spawn.x, east_spawn.z)
	for i in 4:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = east_spawn + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h3.append(d)
	for d in h3: d.herd = h3

	# 4. Fourth Whitetail Herd (South Pines Basin - 4 deer)
	var h4: Array = []
	var south_spawn := Vector3(-20.0, 0, 85.0)
	south_spawn.y = terrain.height_at(south_spawn.x, south_spawn.z)
	for i in 4:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = south_spawn + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h4.append(d)
	for d in h4: d.herd = h4

	# 5. Fifth Whitetail Herd (West Shoreline Glade - 4 deer)
	var h5: Array = []
	var west_spawn := Vector3(-95.0, 0, -20.0)
	west_spawn.y = terrain.height_at(west_spawn.x, west_spawn.z)
	for i in 4:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = west_spawn + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h5.append(d)
	for d in h5: d.herd = h5

	# 6. Sixth Whitetail Herd (High Plateau Pines - 4 deer)
	var h6: Array = []
	var plateau_spawn := Vector3(45.0, 0, 95.0)
	plateau_spawn.y = terrain.height_at(plateau_spawn.x, plateau_spawn.z)
	for i in 4:
		var d := Deer.new()
		d.gender = "Male" if i == 0 else "Female"
		add_child(d)
		var p = plateau_spawn + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		p.y = terrain.height_at(p.x, p.z)
		d.setup(self, p)
		animals.append(d)
		h6.append(d)
	for d in h6: d.herd = h6

	# 7. Solitary Trophy Bucks (8 Majestic Bucks across ridges)
	var trophy_spots = [
		Vector3(-85.0, 0, -70.0),
		Vector3(110.0, 0, 45.0),
		Vector3(60.0, 0, -115.0),
		Vector3(-75.0, 0, 40.0),
		Vector3(15.0, 0, -130.0),
		Vector3(-110.0, 0, 80.0),
		Vector3(85.0, 0, -95.0),
		Vector3(-45.0, 0, -35.0)
	]
	for tsp in trophy_spots:
		var tb := Deer.new()
		tb.gender = "Male"
		add_child(tb)
		tsp.y = terrain.height_at(tsp.x, tsp.z)
		tb.setup(self, tsp)
		animals.append(tb)

	# 8. Vibrant Red Fox Population (14 foxes roaming all sectors)
	var fox_spawns = [
		Vector3(45.0, 0, 35.0),
		Vector3(-30.0, 0, 95.0),
		Vector3(75.0, 0, -85.0),
		Vector3(-60.0, 0, -40.0),
		Vector3(15.0, 0, 65.0),
		Vector3(-85.0, 0, 15.0),
		Vector3(25.0, 0, -15.0),
		Vector3(-15.0, 0, -60.0),
		Vector3(55.0, 0, -10.0),
		Vector3(-50.0, 0, 60.0),
		Vector3(100.0, 0, -50.0),
		Vector3(-105.0, 0, -80.0),
		Vector3(30.0, 0, 110.0),
		Vector3(-70.0, 0, 110.0)
	]
	for fsp in fox_spawns:
		var f := Fox.new()
		add_child(f)
		fsp.y = terrain.height_at(fsp.x, fsp.z)
		f.setup(self, fsp)
		animals.append(f)

	# 9. Mallard Population (14 ducks flocking across the lake)
	var lcenter := lake_center()
	for i in 14:
		var duck := Duck.new()
		add_child(duck)
		var dp := lcenter + Vector3(randf_range(-45, 45), 0, randf_range(-45, 45))
		duck.setup(self, dp)
		animals.append(duck)

	# 10. HALLOWEEN SPECIAL: 25 Glowing Jack-O'-Lanterns
	var pumpkin_spots = [
		Vector3(14.0, 0, -8.0),
		Vector3(16.5, 0, -12.0),
		Vector3(10.0, 0, -5.0),
		Vector3(3.0, 0, 8.0),
		Vector3(-8.0, 0, 12.0),
		Vector3(22.0, 0, -20.0),
		Vector3(40.0, 0, -35.0),
		Vector3(-25.0, 0, 30.0),
		Vector3(35.0, 0, -22.0),
		Vector3(68.0, 0, -12.0),
		Vector3(72.0, 0, -18.0),
		Vector3(33.0, 0, -27.0),
		Vector3(-18.0, 0, -87.0),
		Vector3(4.0, 0, 2.0),
		Vector3(-4.0, 0, 6.0),
		Vector3(50.0, 0, 20.0),
		Vector3(-40.0, 0, 70.0),
		Vector3(80.0, 0, -30.0),
		Vector3(-60.0, 0, -30.0),
		Vector3(20.0, 0, 50.0),
		Vector3(-15.0, 0, -100.0),
		Vector3(65.0, 0, 80.0),
		Vector3(-80.0, 0, 10.0),
		Vector3(12.0, 0, -2.0),
		Vector3(-2.0, 0, 15.0)
	]
	for sp in pumpkin_spots:
		var pkin := JackOLantern.new()
		add_child(pkin)
		sp.y = terrain.height_at(sp.x, sp.z) + 0.2
		pkin.global_position = sp
		pkin.rotation.y = randf() * TAU

	# 11. CRYPTID SPAWNING
	# Mythical Ghost Buck
	var ghost := GhostBuck.new()
	add_child(ghost)
	var gp := Vector3(32.0, 0, -65.0)
	gp.y = terrain.height_at(gp.x, gp.z)
	ghost.setup(self, gp)
	animals.append(ghost)

	# Apex Werewolf Predator
	var wolf := Werewolf.new()
	add_child(wolf)
	var wp := Vector3(-45.0, 0, 75.0)
	wp.y = terrain.height_at(wp.x, wp.z)
	wolf.setup(self, wp)
	animals.append(wolf)

	# Horrific Wendigo
	var wen := Wendigo.new()
	add_child(wen)
	var wnp := Vector3(65.0, 0, 85.0)
	wnp.y = terrain.height_at(wnp.x, wnp.z)
	wen.setup(self, wnp)
	animals.append(wen)

	# In Night Hunt mode: spawn a 2nd Ghost Buck & 2nd Werewolf for intense horror action
	if is_night:
		var ghost2 := GhostBuck.new()
		add_child(ghost2)
		var gp2 := Vector3(-70.0, 0, -95.0)
		gp2.y = terrain.height_at(gp2.x, gp2.z)
		ghost2.setup(self, gp2)
		animals.append(ghost2)
		
		var wolf2 := Werewolf.new()
		add_child(wolf2)
		var wp2 := Vector3(85.0, 0, 45.0)
		wp2.y = terrain.height_at(wp2.x, wp2.z)
		wolf2.setup(self, wp2)
		animals.append(wolf2)

	# 12. Halloween Ravens circling overhead in the sky (visual ambiance, zero sound)
	_spawn_sky_ravens()

func _spawn_sky_ravens() -> void:
	_ravens_node = Node3D.new()
	_ravens_node.name = "SkyRavens"
	add_child(_ravens_node)
	_ravens_node.position = Vector3(15.0, 48.0, -10.0)
	
	var mat_raven := StandardMaterial3D.new()
	mat_raven.albedo_color = Color(0.08, 0.08, 0.09)
	mat_raven.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_raven.roughness = 0.9
	
	var bm := BoxMesh.new()
	for i in 6:
		var r_pivot := Node3D.new()
		r_pivot.name = "RavenPivot_%d" % i
		_ravens_node.add_child(r_pivot)
		r_pivot.rotation.y = float(i) * TAU / 6.0
		
		var raven := MeshInstance3D.new()
		raven.mesh = bm
		raven.scale = Vector3(1.1, 0.04, 0.42)
		raven.position = Vector3(randf_range(30.0, 55.0), randf_range(-3.0, 4.0), 0)
		raven.material_override = mat_raven
		r_pivot.add_child(raven)

func _init_ambient_audio() -> void:
	_ambient_wind_player = AudioStreamPlayer.new()
	_ambient_wind_player.bus = AudioDirector.BUS_AMBIENCE
	_ambient_wind_player.stream = AudioSynth.wind_loop()
	_ambient_wind_player.volume_db = -18.0
	add_child(_ambient_wind_player)
	_ambient_wind_player.play()

	_bird_player = AudioStreamPlayer.new()
	_bird_player.bus = AudioDirector.BUS_AMBIENCE
	_bird_player.volume_db = -24.0
	add_child(_bird_player)

func _physics_process(delta: float) -> void:
	_session_time_seconds += delta * 4.0 # 4x in-game time progression
	
	_time_update_timer += delta
	if _time_update_timer >= 1.0:
		_time_update_timer = 0.0
		_update_lighting_and_fog(delta)
		
	_wind_param_timer += delta
	if _wind_param_timer >= 0.5:
		_wind_param_timer = 0.0
		_update_wind_ambient()

	if _ravens_node:
		_ravens_node.rotation.y += delta * 0.12
	_tick_birds(delta)

func _update_lighting_and_fog(_delta: float) -> void:
	if not _sun_light or not _env:
		return
	var hr: float = fmod(_session_time_seconds / 3600.0, 24.0)
	var gs = get_node_or_null("/root/GameState")
	var is_night = gs.is_night_hunt if gs else false
	
	var light_col := Color.WHITE
	var light_energy := 1.0
	var fog_d := 0.0055
	
	if hr >= 5.0 and hr < 8.0:
		# Dawn: Warm golden morning
		var t = (hr - 5.0) / 3.0
		light_col = Color(1.0, 0.67, 0.27).lerp(Color(1.0, 0.95, 0.85), t)
		light_energy = lerp(0.75, 1.1, t)
		fog_d = lerp(0.0075, 0.0045, t)
	elif hr >= 8.0 and hr < 17.0:
		# Noon / Afternoon: Crisp clear light
		light_col = Color(1.0, 0.98, 0.95)
		light_energy = 1.15
		fog_d = 0.0040
	elif hr >= 17.0 and hr < 20.5:
		# Dusk: Blood twilight
		var t = (hr - 17.0) / 3.5
		light_col = Color(1.0, 0.95, 0.85).lerp(Color(0.40, 0.53, 0.80), t)
		light_energy = lerp(1.1, 0.55, t)
		fog_d = lerp(0.0040, 0.0068, t)
	else:
		# Night: Midnight / Moonlight
		light_col = Color(0.67, 0.73, 0.87) if not is_night else Color(0.85, 0.55, 0.75)
		light_energy = 0.35 if not is_night else 0.45
		fog_d = 0.0060 if not is_night else 0.0080

	_sun_light.light_color = light_col
	_sun_light.light_energy = light_energy
	_env.fog_density = fog_d
	if gs:
		gs.fog_density = clamp(fog_d * 120.0, 0.0, 1.0)
		
	var eb = get_node_or_null("/root/EventBus")
	if eb and eb.has_signal("time_changed"):
		eb.time_changed.emit(hr)

func _update_wind_ambient() -> void:
	if not _ambient_wind_player or not hunter:
		return
	var alt = hunter.global_position.y
	var hr: float = fmod(_session_time_seconds / 3600.0, 24.0)
	var is_night = (hr < 5.0 or hr > 20.0)
	_ambient_wind_player.volume_db = lerp(-22.0, -14.0, clamp(alt / 45.0, 0.0, 1.0))
	if is_night:
		_ambient_wind_player.volume_db -= 2.0
	if hunter.is_aiming_optics:
		_ambient_wind_player.volume_db -= 3.0

func _tick_birds(delta: float) -> void:
	if _bird_player == null:
		return
	if _cryptid_nearby() or not _birds_in_daylight():
		if _bird_player.playing:
			_bird_player.stop()
		_bird_timer = maxf(_bird_timer, 1.5)
		return
	_bird_timer -= delta
	if _bird_timer > 0.0:
		return
	var hr: float = fmod(_session_time_seconds / 3600.0, 24.0)
	_bird_timer = randf_range(4.0, 9.0) if hr < 8.0 else randf_range(7.0, 16.0)
	_bird_player.stream = AudioSynth.take_bird_chirp()
	_bird_player.pitch_scale = AudioSynth.vary_pitch(0.92, 1.08)
	_bird_player.play()

func _birds_in_daylight() -> bool:
	var hr: float = fmod(_session_time_seconds / 3600.0, 24.0)
	return hr >= 5.0 and hr < 17.0

func _cryptid_nearby() -> bool:
	if hunter == null:
		return false
	var origin := hunter.global_position
	for a in animals:
		if not is_instance_valid(a):
			continue
		if not (a is Werewolf or a is Wendigo):
			continue
		if a.state == Animal.State.DEAD:
			continue
		if origin.distance_to(a.global_position) <= _CRYPTID_HUSH_M:
			return true
	return false

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
