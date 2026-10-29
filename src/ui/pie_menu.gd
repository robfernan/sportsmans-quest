class_name PieMenu
extends CanvasLayer

## Iconic Quick-Select Radial / Pie Menu (Inspired by theHunter Classic's gui_pie_menu.py)
## Hold 'Q' or 'TAB' to open the radial wheel, select gear, and release to equip.

signal item_selected(item_id: String)

@export var radius: float = 140.0
@export var slice_count: int = 5

var items = [
	{"id": "rifle", "name": "Hunting Rifle (.308)"},
	{"id": "shotgun", "name": "12GA Shotgun"},
	{"id": "binoculars", "name": "Rangefinder Optics"},
	{"id": "deer_call", "name": "Grunt Tube Caller"},
	{"id": "duck_call", "name": "Waterfowl Call"}
]

var active_hovered_index: int = -1
var is_open: bool = false

@onready var wheel_center: Control = $Center
@onready var selection_label: Label = $Center/SelectionLabel

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	var hunter := get_tree().root.find_child("Hunter", true, false)
	if hunter and bool(hunter.get("is_downed")):
		return
	# Hold Q or TAB to open radial menu
	if event is InputEventKey:
		if event.keycode == KEY_Q or event.keycode == KEY_TAB:
			if event.pressed and not is_open:
				_open_menu()
			elif not event.pressed and is_open:
				_close_and_select()

	if is_open and event is InputEventMouseMotion:
		_calculate_hovered_slice(event.position)

func _open_menu() -> void:
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	selection_label.text = "SELECT EQUIPMENT"

func _close_and_select() -> void:
	is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if active_hovered_index >= 0 and active_hovered_index < items.size():
		var selected = items[active_hovered_index]
		item_selected.emit(selected["id"])
		print("[Equipment Wheel] Equipped: %s" % selected["name"])

func _calculate_hovered_slice(mouse_pos: Vector2) -> void:
	var screen_center = get_viewport().get_visible_rect().size * 0.5
	var diff = mouse_pos - screen_center
	
	if diff.length() < 30.0:
		active_hovered_index = -1
		selection_label.text = "SELECT EQUIPMENT"
		return

	# Calculate angle around circle
	var angle = atan2(diff.y, diff.x) # -PI to PI
	if angle < 0:
		angle += TAU

	var slice_angle = TAU / items.size()
	active_hovered_index = int(floor(angle / slice_angle)) % items.size()
	selection_label.text = items[active_hovered_index]["name"]
