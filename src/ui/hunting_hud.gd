class_name HuntingHUD
extends CanvasLayer

## Minimalist Diegetic In-Game Hunting HUD (Sportsman's Quest)
## Features Procedural Compass Strip, Diegetic Drop Crosshair, Ammo Counter,
## Scope Vignette Aperture, Contextual First-Time Tutorial, and Pause Overlay.

@onready var wind_label: Label = $Margin/TopRight/WindLabel
@onready var menu_btn: Button = $Margin/TopRight/MenuButton
@onready var fullscreen_btn: Button = $Margin/TopRight/FullscreenButton
@onready var stance_label: Label = $Margin/BottomLeft/StanceLabel
@onready var clue_label: Label = $Margin/BottomLeft/ClueLabel
@onready var range_label: Label = $Center/RangeLabel
@onready var notification_label: Label = $Center/NotificationLabel
@onready var crosshair: ColorRect = $Center/Crosshair

var hunter: HunterController
var wind_system: WindSystem
var world: Node

# Diegetic HUD Controls
var _compass_strip: Control
var _ammo_label: Label
var _drop_tick: ColorRect
var _ch_top: ColorRect
var _ch_bottom: ColorRect
var _ch_left: ColorRect
var _ch_right: ColorRect
var _scope_overlay: Control

# Tutorial state tracking
var _walk_time: float = 0.0
var _tutorial_step: int = 0
var _tutorial_timer: float = 0.0
var _tutorial_label: Label

var _note_time: float = 0.0
var _spook_cd: float = 0.0
var _downed_panel: Panel = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hunter = get_tree().root.find_child("Hunter", true, false) as HunterController
	wind_system = get_tree().root.find_child("WindSystem", true, false) as WindSystem
	world = get_tree().root.find_child("Main", true, false)
	
	if menu_btn:
		menu_btn.pressed.connect(toggle_pause)
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(_toggle_fullscreen)

	_build_procedural_hud()
	if wind_label:
		wind_label.add_theme_color_override("font_color", Color(0.85, 0.72, 0.45))
		wind_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.03, 0.85))
		wind_label.add_theme_constant_override("shadow_offset_x", 1)
		wind_label.add_theme_constant_override("shadow_offset_y", 1)
	if notification_label:
		notification_label.add_theme_font_size_override("font_size", 22)
		notification_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
		notification_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		notification_label.add_theme_constant_override("shadow_offset_x", 1)
		notification_label.add_theme_constant_override("shadow_offset_y", 1)
	_connect_feedback()

func _connect_feedback() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		if not gs.notify.is_connected(_on_game_notify):
			gs.notify.connect(_on_game_notify)
		if not gs.mission_completed.is_connected(_on_mission):
			gs.mission_completed.connect(_on_mission)
	var eb := get_node_or_null("/root/EventBus")
	if eb == null:
		return
	if eb.has_signal("shot_resolved") and not eb.shot_resolved.is_connected(_on_shot):
		eb.shot_resolved.connect(_on_shot)
	if eb.has_signal("player_downed") and not eb.player_downed.is_connected(show_downed):
		eb.player_downed.connect(show_downed)
	if eb.has_signal("animal_spooked") and not eb.animal_spooked.is_connected(_on_spook):
		eb.animal_spooked.connect(_on_spook)

func push_note(text: String) -> void:
	if notification_label == null:
		return
	notification_label.text = text
	notification_label.visible = true
	_note_time = 3.4

func _on_game_notify(text: String) -> void:
	push_note(text)

func _on_mission(title: String) -> void:
	push_note("MISSION COMPLETE: " + title)

func _on_shot(organ: String, distance_m: float, fatal: bool) -> void:
	if organ == "":
		push_note("MISS")
	elif fatal:
		push_note("KILL  %s   %.0f m" % [organ, distance_m])
	else:
		push_note("HIT  %s   %.0f m" % [organ, distance_m])

func _on_spook(_animal_id: int, animal_pos: Vector3, _alert_level: float) -> void:
	if _spook_cd > 0.0 or hunter == null:
		return
	if hunter.global_position.distance_to(animal_pos) > 70.0:
		return
	_spook_cd = 5.0
	push_note("SPOOKED — something heard or smelled you")

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	if _downed_panel != null and _downed_panel.visible:
		get_viewport().set_input_as_handled()
		return
	var hm := get_tree().root.find_child("HuntermateMap", true, false)
	if hm and hm.visible:
		return
	var hs := get_tree().root.find_child("HarvestScreen", true, false)
	if hs and hs.visible:
		return
	var pie := get_tree().root.find_child("PieMenu", true, false)
	if pie and bool(pie.get("is_open")):
		return
	toggle_pause()
	get_viewport().set_input_as_handled()

func _toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _build_procedural_hud() -> void:
	# Hide legacy square crosshair
	if crosshair:
		crosshair.visible = false

	# 1. Procedural 4-line crosshair with 8px gap
	var center_node = $Center
	if center_node:
		_ch_top = ColorRect.new(); _ch_top.size = Vector2(2, 10); _ch_top.position = Vector2(-1, -18); _ch_top.color = Color(1, 1, 1, 0.85); center_node.add_child(_ch_top)
		_ch_bottom = ColorRect.new(); _ch_bottom.size = Vector2(2, 10); _ch_bottom.position = Vector2(-1, 8); _ch_bottom.color = Color(1, 1, 1, 0.85); center_node.add_child(_ch_bottom)
		_ch_left = ColorRect.new(); _ch_left.size = Vector2(10, 2); _ch_left.position = Vector2(-18, -1); _ch_left.color = Color(1, 1, 1, 0.85); center_node.add_child(_ch_left)
		_ch_right = ColorRect.new(); _ch_right.size = Vector2(10, 2); _ch_right.position = Vector2(8, -1); _ch_right.color = Color(1, 1, 1, 0.85); center_node.add_child(_ch_right)
		
		# Bullet drop tick indicator below crosshair
		_drop_tick = ColorRect.new()
		_drop_tick.size = Vector2(6, 2)
		_drop_tick.position = Vector2(-3, 8)
		_drop_tick.color = Color(1, 0.4, 0.2, 0.9)
		center_node.add_child(_drop_tick)

	# 2. Procedural Compass Strip at Top Center
	_compass_strip = Control.new()
	_compass_strip.custom_minimum_size = Vector2(320, 28)
	_compass_strip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_compass_strip.position = Vector2(-160, 16)
	_compass_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass_strip.draw.connect(_draw_compass_strip)
	add_child(_compass_strip)

	# 3. Clean Ammo Counter at Bottom Right
	_ammo_label = Label.new()
	_ammo_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ammo_label.position = Vector2(-160, -55)
	_ammo_label.add_theme_font_size_override("font_size", 24)
	_ammo_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 0.95))
	_ammo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_ammo_label.add_theme_constant_override("shadow_offset_x", 1)
	_ammo_label.add_theme_constant_override("shadow_offset_y", 1)
	_ammo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ammo_label)

	# 4. Scope Vignette Overlay (Circular vignette when aiming)
	_scope_overlay = Control.new()
	_scope_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scope_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scope_overlay.visible = false
	_scope_overlay.draw.connect(_draw_scope_vignette)
	add_child(_scope_overlay)

	# 5. Tutorial Toast Label
	_tutorial_label = Label.new()
	_tutorial_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_tutorial_label.position = Vector2(-220, -110)
	_tutorial_label.custom_minimum_size = Vector2(440, 36)
	_tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_label.add_theme_font_size_override("font_size", 16)
	_tutorial_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_tutorial_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_tutorial_label.add_theme_constant_override("shadow_offset_x", 1)
	_tutorial_label.add_theme_constant_override("shadow_offset_y", 1)
	_tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_label.visible = false
	add_child(_tutorial_label)

func _draw_compass_strip() -> void:
	if not hunter:
		return
	var yaw_deg = rad_to_deg(hunter.rotation.y)
	if hunter.head:
		yaw_deg += rad_to_deg(hunter.head.rotation.y)
	yaw_deg = fmod(yaw_deg + 360.0, 360.0)

	var w = _compass_strip.size.x
	var h = _compass_strip.size.y
	var mid_x = w * 0.5

	# Dark subtle backing
	_compass_strip.draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.08, 0.12, 0.45))
	_compass_strip.draw_line(Vector2(0, h - 2), Vector2(w, h - 2), Color(0.6, 0.7, 0.8, 0.35), 1.0)
	# Center pointer tick
	_compass_strip.draw_line(Vector2(mid_x, 0), Vector2(mid_x, 10), Color(1.0, 0.6, 0.2, 0.95), 2.0)

	var pixels_per_deg = w / 90.0 # 90 degree field of view on compass
	var card_dirs = {0: "N", 45: "NE", 90: "E", 135: "SE", 180: "S", 225: "SW", 270: "W", 315: "NW"}

	for angle_step in range(-50, 51, 10):
		var check_angle = int(fmod(yaw_deg + angle_step + 360.0, 360.0))
		var offset_x = mid_x + (angle_step * pixels_per_deg)
		if offset_x < 4 or offset_x > w - 4:
			continue

		if card_dirs.has(check_angle):
			var label_str = card_dirs[check_angle]
			_compass_strip.draw_string(ThemeDB.fallback_font, Vector2(offset_x - 5, 20), label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1, 0.9, 0.5) if label_str == "N" else Color(0.85, 0.88, 0.95))
			_compass_strip.draw_line(Vector2(offset_x, 4), Vector2(offset_x, 10), Color(0.9, 0.9, 1.0, 0.8), 1.5)
		else:
			_compass_strip.draw_line(Vector2(offset_x, 6), Vector2(offset_x, 11), Color(0.7, 0.7, 0.8, 0.4), 1.0)

func _draw_scope_vignette() -> void:
	var vp_size = _scope_overlay.get_viewport_rect().size
	var center = vp_size * 0.5
	var r = min(vp_size.x, vp_size.y) * 0.42

	# Draw outer blackout border
	_scope_overlay.draw_rect(Rect2(0, 0, vp_size.x, center.y - r), Color(0.02, 0.02, 0.04, 0.95))
	_scope_overlay.draw_rect(Rect2(0, center.y + r, vp_size.x, vp_size.y - (center.y + r)), Color(0.02, 0.02, 0.04, 0.95))
	_scope_overlay.draw_rect(Rect2(0, center.y - r, center.x - r, r * 2), Color(0.02, 0.02, 0.04, 0.95))
	_scope_overlay.draw_rect(Rect2(center.x + r, center.y - r, vp_size.x - (center.x + r), r * 2), Color(0.02, 0.02, 0.04, 0.95))
	_scope_overlay.draw_arc(center, r, 0, TAU, 64, Color(0.05, 0.05, 0.07, 0.98), 4.0)
	# Scope reticle center hair
	_scope_overlay.draw_line(center - Vector2(r * 0.85, 0), center + Vector2(r * 0.85, 0), Color(0.1, 0.1, 0.1, 0.7), 1.5)
	_scope_overlay.draw_line(center - Vector2(0, r * 0.85), center + Vector2(0, r * 0.85), Color(0.1, 0.1, 0.1, 0.7), 1.5)

func _process(delta: float) -> void:
	if _note_time > 0.0:
		_note_time -= delta
		if _note_time <= 0.0 and notification_label:
			notification_label.visible = false
	if _spook_cd > 0.0:
		_spook_cd -= delta

	if not hunter:
		hunter = get_tree().root.find_child("Hunter", true, false) as HunterController
		return

	if _compass_strip:
		_compass_strip.queue_redraw()

	# Stance & Noise
	var stance_str = "STAND"
	if hunter.current_stance == HunterController.Stance.CROUCH:
		stance_str = "CROUCH"
	elif hunter.current_stance == HunterController.Stance.PRONE:
		stance_str = "PRONE"
	if hunter.is_in_kayak:
		stance_str = "KAYAK"

	var noise = hunter.get_noise_radius()
	var noise_band := "QUIET"
	if noise >= 40.0:
		noise_band = "ALARM"
	elif noise >= 15.0:
		noise_band = "LOUD"
	elif noise >= 3.0:
		noise_band = "SOFT"
	var current_item = hunter.get_current_weapon_display_name() if hunter.has_method("get_current_weapon_display_name") else "Equipment"
	var hp_str = "HP %.0f" % hunter.health if "health" in hunter else "HP 100"
	
	stance_label.text = "%s  |  %s  |  %s  |  NOISE %s %.0fm" % [
		hp_str, current_item, stance_str, noise_band, noise
	]

	# Ammo Count (Bottom Right)
	if _ammo_label:
		if hunter.current_slot == HunterController.WeaponSlot.RIFLE:
			_ammo_label.text = "1 / 40 [.308]"
		elif hunter.current_slot == HunterController.WeaponSlot.SHOTGUN:
			_ammo_label.text = "%d / 4 [12GA]" % hunter.roper_ammo_loaded
		else:
			_ammo_label.text = ""

	# Huntermate Clue reading
	if clue_label:
		if hunter.current_clue != "":
			clue_label.visible = true
			clue_label.text = "🔍 " + hunter.current_clue + " (Press E when near to claim fallen game)"
		else:
			clue_label.visible = false

	# Wind & Clock display
	if wind_system:
		var speed = wind_system.current_wind_speed
		var card: String = wind_system.blowing_toward_cardinal() if wind_system.has_method("blowing_toward_cardinal") else "?"
		var clock_str = world.clock_string() if (world and world.has_method("clock_string")) else "08:00 AM"
		var smelling := 0
		if world and hunter and wind_system.has_method("count_animals_smelling") and "animals" in world:
			smelling = wind_system.count_animals_smelling(hunter.global_position, world.animals)
		var scent := "UPWIND" if smelling == 0 else "DOWNWIND x%d" % smelling
		wind_label.text = "%s  |  WIND %s %.1f m/s  |  SCENT %s" % [clock_str, card, speed, scent]

	# Optics & Crosshair drop indicator
	var aiming = hunter.is_aiming_optics
	if _scope_overlay:
		_scope_overlay.visible = aiming
		if aiming:
			_scope_overlay.queue_redraw()

	if _ch_top:
		_ch_top.visible = not aiming
		_ch_bottom.visible = not aiming
		_ch_left.visible = not aiming
		_ch_right.visible = not aiming
		_drop_tick.visible = not aiming

	if aiming:
		range_label.visible = true
		if hunter.rangefinder_ray and hunter.rangefinder_ray.is_colliding():
			var dist = hunter.rangefinder_ray.get_collision_point().distance_to(hunter.global_position)
			range_label.text = "%.1f m" % dist
		else:
			range_label.text = "--- m"
	else:
		range_label.visible = false
		# Calculate bullet drop offset for crosshair tick (max 12px)
		var measured_dist = 100.0
		if hunter.rangefinder_ray and hunter.rangefinder_ray.is_colliding():
			measured_dist = hunter.rangefinder_ray.get_collision_point().distance_to(hunter.global_position)
		var drop_pixels = clamp((measured_dist - hunter.get_current_zero()) * 0.08, 0.0, 12.0)
		if _drop_tick:
			_drop_tick.position.y = 8.0 + drop_pixels

	_update_tutorial(delta)

func _tutorial_done() -> bool:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or not (gs.seen_tutorial is Dictionary):
		return true
	return bool(gs.seen_tutorial.get("sprint", false)) and bool(gs.seen_tutorial.get("crouch", false)) and bool(gs.seen_tutorial.get("aim_vital", false))

func _update_tutorial(delta: float) -> void:
	if _tutorial_done():
		if _tutorial_label:
			_tutorial_label.visible = false
		return

	var spd = hunter.get_current_speed() if hunter else 0.0
	match _tutorial_step:
		0:
			if spd > 1.0:
				_walk_time += delta
				if _walk_time > 2.0:
					_show_tip("Hold SHIFT to sprint across long distances")
					if Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SHIFT):
						_advance_tip()
		1:
			if spd < 0.3:
				_show_tip("Press C to crouch — drastically reduces sound & silhouette")
				if hunter and hunter.current_stance == HunterController.Stance.CROUCH:
					_advance_tip()
		2:
			if hunter and hunter.is_aiming_optics:
				_show_tip("Aim for the vital chest zone (Heart / Lungs) for an ethical clean harvest")
				_tutorial_timer += delta
				if _tutorial_timer > 5.0:
					_advance_tip()

func _show_tip(text: String) -> void:
	if _tutorial_label:
		_tutorial_label.text = "💡 " + text
		_tutorial_label.visible = true

func _advance_tip() -> void:
	var flags := ["sprint", "crouch", "aim_vital"]
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.seen_tutorial is Dictionary and _tutorial_step >= 0 and _tutorial_step < flags.size():
		gs.seen_tutorial[flags[_tutorial_step]] = true
	_tutorial_step += 1
	_tutorial_timer = 0.0
	_walk_time = 0.0
	if _tutorial_step >= 3:
		if _tutorial_label:
			_tutorial_label.visible = false
		if gs and _tutorial_done():
			gs.save_game()

var _pause_panel: Panel = null
var is_paused: bool:
	get:
		return _pause_panel != null and _pause_panel.visible

func toggle_pause() -> void:
	if _downed_panel != null and _downed_panel.visible:
		return
	if _pause_panel == null:
		_create_pause_menu()
	_pause_panel.visible = not _pause_panel.visible
	var pausing: bool = _pause_panel.visible
	get_tree().paused = pausing
	if pausing:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var resume := _pause_panel.find_child("ResumeButton", true, false)
		if resume is Control:
			resume.grab_focus()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _create_pause_menu() -> void:
	_pause_panel = Panel.new()
	_pause_panel.name = "PauseMenu"
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.04, 0.04, 0.06, 0.88)
	_pause_panel.add_theme_stylebox_override("panel", bg_style)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(360, 280)
	vbox.add_theme_constant_override("separation", 16)
	_pause_panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "PAUSED • EXPEDITION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.72, 0.35))
	vbox.add_child(title)
	
	var resume_btn := Button.new()
	resume_btn.name = "ResumeButton"
	resume_btn.text = "RESUME HUNT"
	resume_btn.custom_minimum_size = Vector2(0, 44)
	resume_btn.pressed.connect(toggle_pause)
	vbox.add_child(resume_btn)
	
	var lodge_btn := Button.new()
	lodge_btn.text = "VISIT 3D TROPHY LODGE"
	lodge_btn.custom_minimum_size = Vector2(0, 44)
	lodge_btn.pressed.connect(func():
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var gs := get_node_or_null("/root/GameState")
		if gs:
			gs.save_game()
		get_tree().change_scene_to_file("res://scenes/trophy_lodge.tscn")
	)
	vbox.add_child(lodge_btn)
	
	var ret_btn := Button.new()
	ret_btn.text = "RETURN TO MAIN MENU"
	ret_btn.custom_minimum_size = Vector2(0, 44)
	ret_btn.pressed.connect(func():
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var gs := get_node_or_null("/root/GameState")
		if gs:
			gs.save_game()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(ret_btn)
	
	add_child(_pause_panel)

func show_downed() -> void:
	if _downed_panel != null:
		return
	if _pause_panel:
		_pause_panel.visible = false
	_downed_panel = Panel.new()
	_downed_panel.name = "DownedPanel"
	_downed_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.02, 0.02, 0.9)
	_downed_panel.add_theme_stylebox_override("panel", bg)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(420, 160)
	vbox.add_theme_constant_override("separation", 14)
	_downed_panel.add_child(vbox)
	var title := Label.new()
	title.text = "YOU ARE DOWN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.35, 0.2))
	vbox.add_child(title)
	var body := Label.new()
	body.text = "The reserve got to you. Trophies already saved stay in the lodge."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(400, 40)
	vbox.add_child(body)
	var camp := Button.new()
	camp.text = "RETURN TO CAMP"
	camp.custom_minimum_size = Vector2(0, 46)
	camp.pressed.connect(func():
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var gs := get_node_or_null("/root/GameState")
		if gs:
			gs.save_game()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(camp)
	add_child(_downed_panel)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camp.grab_focus()
