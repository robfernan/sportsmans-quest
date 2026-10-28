class_name MainMenu
extends Control

## Start Menu for "Sportsman's Quest"
## Features Reserve Selection, 3D Trophy Lodge, Cryptid Night Hunt Mode, and instant launch.

@onready var start_btn: Button = $CenterContainer/VBoxContainer/StartButton
@onready var lodge_btn: Button = $CenterContainer/VBoxContainer/LodgeButton
@onready var reserve_btn: Button = $CenterContainer/VBoxContainer/ReserveButton
@onready var settings_btn: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel

var _wind_audio: AudioStreamPlayer
var night_hunt_btn: Button

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	start_btn.text = "☀️ DAY HUNT EXPEDITION (DAWN)"
	start_btn.pressed.connect(_on_start_pressed)
	lodge_btn.pressed.connect(_on_lodge_pressed)
	reserve_btn.pressed.connect(_on_reserve_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	# Add Dedicated Cryptid Night Hunt Button
	night_hunt_btn = Button.new()
	night_hunt_btn.text = "🎃 NIGHT HUNT (CRYPTID HORROR MODE)"
	night_hunt_btn.custom_minimum_size = Vector2(0, 48)
	night_hunt_btn.add_theme_font_size_override("font_size", 16)
	night_hunt_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
	
	var vbox = $CenterContainer/VBoxContainer
	if vbox:
		# Insert after standard start button
		vbox.add_child(night_hunt_btn)
		vbox.move_child(night_hunt_btn, start_btn.get_index() + 1)
		
	night_hunt_btn.pressed.connect(_on_night_hunt_pressed)
	
	# Procedural ambient wind on main menu
	_wind_audio = AudioStreamPlayer.new()
	_wind_audio.stream = AudioSynth.wind_ambient(15.0, 0.4, false)
	_wind_audio.volume_db = -22.0
	add_child(_wind_audio)
	_wind_audio.play()

	start_btn.grab_focus()

func _on_start_pressed() -> void:
	print("[Sportsman's Quest] Launching Day Hunt Expedition...")
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.is_night_hunt = false
	start_btn.text = "ENTERING RESERVE..."
	start_btn.disabled = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_night_hunt_pressed() -> void:
	print("[Sportsman's Quest] Entering Night Hunt (Cryptids Activated)...")
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.is_night_hunt = true
	night_hunt_btn.text = "STALKING INTO THE DARKNESS..."
	night_hunt_btn.disabled = true
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
