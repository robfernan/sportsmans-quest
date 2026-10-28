class_name MainMenu
extends Control

## Start Menu for "Sportsman's Quest"
## Features Reserve Selection, 3D Trophy Lodge, Hardware Specs, and instant Expedition launch.

@onready var start_btn: Button = $CenterContainer/VBoxContainer/StartButton
@onready var lodge_btn: Button = $CenterContainer/VBoxContainer/LodgeButton
@onready var reserve_btn: Button = $CenterContainer/VBoxContainer/ReserveButton
@onready var settings_btn: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	start_btn.pressed.connect(_on_start_pressed)
	lodge_btn.pressed.connect(_on_lodge_pressed)
	reserve_btn.pressed.connect(_on_reserve_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	start_btn.grab_focus()

func _on_start_pressed() -> void:
	print("[Sportsman's Quest] Launching hunt expedition...")
	start_btn.text = "ENTERING WHISPERING PINES..."
	start_btn.disabled = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_lodge_pressed() -> void:
	print("[Sportsman's Quest] Visiting 3D Trophy Lodge...")
	get_tree().change_scene_to_file("res://scenes/trophy_lodge.tscn")

func _on_reserve_pressed() -> void:
	subtitle_label.text = "RESERVES: Whispering Pines & Bayou (Active) | Timber Ridge (Soon)"

func _on_settings_pressed() -> void:
	subtitle_label.text = "HARDWARE TARGET: Intel HD/Iris Xe (60fps) up to RX 7900 XTX (4K 144fps)"

func _on_quit_pressed() -> void:
	get_tree().quit()
