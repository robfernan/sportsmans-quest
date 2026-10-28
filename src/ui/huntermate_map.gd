class_name HuntermateMap
extends CanvasLayer

## Handheld Topographic Reserve GPS & Huntermate (Sportsman's Quest)
## Toggle with 'M'. Shows lake contours, shoreline, player position/heading,
## companion dog icon, and discovered animal sign pins.

@onready var map_panel: Panel = $MapPanel
@onready var map_canvas: Control = $MapPanel/MapCanvas
@onready var close_btn: Button = $MapPanel/CloseButton
@onready var title_label: Label = $MapPanel/TitleLabel
@onready var coords_label: Label = $MapPanel/CoordsLabel

var hunter: HunterController = null
var dog: Node3D = null
var world: Node = null

# Map coordinates mapping: Reserve is 600m x 600m (-300 to +300)
const RESERVE_EXTENT = 300.0

func _ready() -> void:
	visible = false
	map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.pressed.connect(close_map)

func toggle_map() -> void:
	if visible:
		close_map()
	else:
		open_map()

func open_map() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not hunter:
		hunter = get_tree().root.find_child("Hunter", true, false) as HunterController
	if not dog:
		dog = get_tree().root.find_child("HuntingDog", true, false)
	if not world:
		world = get_tree().root.find_child("Main", true, false)
	map_canvas.queue_redraw()

func close_map() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	if not visible:
		return
	if hunter:
		var pos = hunter.global_position
		coords_label.text = "GPS: X: %+.1f m | Z: %+.1f m | ELEV: %.1f m" % [pos.x, pos.z, pos.y]
	map_canvas.queue_redraw()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_M or event.keycode == KEY_ESCAPE:
			close_map()
			get_viewport().set_input_as_handled()
