class_name HuntingHUD
extends CanvasLayer

## Minimalist In-Game Hunting HUD (Sportsman's Quest)
## Displays Wind Indicator, Stance/Noise, Weapon/Ammo, Rangefinder, Zeroing, and Huntermate Clues.

@onready var wind_label: Label = $Margin/TopRight/WindLabel
@onready var stance_label: Label = $Margin/BottomLeft/StanceLabel
@onready var clue_label: Label = $Margin/BottomLeft/ClueLabel
@onready var range_label: Label = $Center/RangeLabel
@onready var notification_label: Label = $Center/NotificationLabel
@onready var crosshair: ColorRect = $Center/Crosshair

var hunter: HunterController
var wind_system: WindSystem
var world: Node

func _ready() -> void:
	hunter = get_tree().root.find_child("Hunter", true, false) as HunterController
	wind_system = get_tree().root.find_child("WindSystem", true, false) as WindSystem
	world = get_tree().root.find_child("Main", true, false)

func _process(_delta: float) -> void:
	if not hunter:
		hunter = get_tree().root.find_child("Hunter", true, false) as HunterController
		return

	# Update stance & noise display
	var stance_str = "STAND"
	if hunter.current_stance == HunterController.Stance.CROUCH:
		stance_str = "CROUCH"
	elif hunter.current_stance == HunterController.Stance.PRONE:
		stance_str = "PRONE"
	if hunter.is_in_kayak:
		stance_str = "KAYAK"

	var noise = hunter.get_noise_radius()
	var current_item = hunter.get_current_weapon_display_name() if hunter.has_method("get_current_weapon_display_name") else "Equipment"
	var hp_str = "❤️ HP: %.0f" % hunter.health if "health" in hunter else "❤️ HP: 100"
	
	stance_label.text = "%s | [%s] | %s | NOISE: %.0fm  [M: Map | F: Zero | G: Decoy | B: Blind | K: Dog]" % [
		hp_str, current_item, stance_str, noise
	]

	# Update Huntermate clue reading
	if clue_label:
		if hunter.current_clue != "":
			clue_label.visible = true
			clue_label.text = "🔍 " + hunter.current_clue + " (Press E when near to claim fallen game)"
		else:
			clue_label.visible = false

	# Update wind & clock display
	if wind_system:
		var dir = wind_system.current_wind_direction
		var speed = wind_system.current_wind_speed
		var clock_str = world.clock_string() if (world and world.has_method("clock_string")) else "08:00 AM"
		wind_label.text = "%s  |  WIND: %.1f m/s (%.1f, %.1f)  [P: Powder Puff]" % [clock_str, speed, dir.x, dir.z]

	# Rangefinder optics readout
	if hunter.is_aiming_optics:
		crosshair.visible = false
		range_label.visible = true
		if hunter.rangefinder_ray and hunter.rangefinder_ray.is_colliding():
			var dist = hunter.rangefinder_ray.get_collision_point().distance_to(hunter.global_position)
			range_label.text = "%.1f m" % dist
		else:
			range_label.text = "--- m"
	else:
		crosshair.visible = true
		range_label.visible = false

var _pause_panel: Panel = null

func toggle_pause() -> void:
	if _pause_panel == null:
		_create_pause_menu()
	_pause_panel.visible = not _pause_panel.visible
	if _pause_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _create_pause_menu() -> void:
	_pause_panel = Panel.new()
	_pause_panel.name = "PauseMenu"
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.04, 0.04, 0.06, 0.85)
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
	resume_btn.text = "RESUME HUNT"
	resume_btn.custom_minimum_size = Vector2(0, 44)
	resume_btn.pressed.connect(toggle_pause)
	vbox.add_child(resume_btn)
	
	var lodge_btn := Button.new()
	lodge_btn.text = "VISIT 3D TROPHY LODGE"
	lodge_btn.custom_minimum_size = Vector2(0, 44)
	lodge_btn.pressed.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/trophy_lodge.tscn")
	)
	vbox.add_child(lodge_btn)
	
	var menu_btn := Button.new()
	menu_btn.text = "RETURN TO MAIN MENU (ESC / F10)"
	menu_btn.custom_minimum_size = Vector2(0, 44)
	menu_btn.pressed.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(_pause_panel)
