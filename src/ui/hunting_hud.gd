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
