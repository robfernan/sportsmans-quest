extends Node

## GameState autoload: persistent offline save data (trophies, missions, settings).

signal notify(text: String)
signal mission_completed(title: String)

const SAVE_PATH := "user://sportsmans_quest_save.json"

var trophies: Array = []
var settings := {"quality": 1, "mouse_sens": 1.0}   # quality: 0 low, 1 medium, 2 high
var missions: Array = [
	{"id": "first_deer", "title": "First Blood", "desc": "Harvest any Whitetail Deer.", "done": false},
	{"id": "long_shot", "title": "Long Range", "desc": "Harvest a deer from over 100 m.", "done": false},
	{"id": "clean_kill", "title": "Ethical Hunter", "desc": "Harvest a deer with a heart or lung shot.", "done": false},
	{"id": "fox", "title": "Predator Control", "desc": "Harvest a Red Fox.", "done": false},
	{"id": "duck", "title": "Marsh Master", "desc": "Harvest a Mallard with the shotgun.", "done": false},
	{"id": "buck150", "title": "Trophy Buck", "desc": "Harvest a buck scoring 150+ points.", "done": false},
	{"id": "kayak", "title": "Silent Waters", "desc": "Paddle the kayak across the lake.", "done": false},
]

func _ready() -> void:
	load_game()

func add_trophy(record: Dictionary) -> void:
	trophies.append(record)
	_check_missions(record)
	save_game()
	notify.emit("Trophy recorded: %s (%.1f pts)" % [record.get("species_name", "?"), record.get("trophy_score", 0.0)])

func complete_mission(id: String) -> void:
	for m in missions:
		if m.id == id and not m.done:
			m.done = true
			mission_completed.emit(m.title)
			notify.emit("MISSION COMPLETE: " + m.title)
			save_game()

func _check_missions(r: Dictionary) -> void:
	var sp: String = r.get("species_name", "")
	if sp == "Whitetail Deer":
		complete_mission("first_deer")
		if r.get("shot_distance_m", 0.0) >= 100.0:
			complete_mission("long_shot")
		var organ: String = r.get("organ_hit", "")
		if organ.contains("Heart") or organ.contains("Lung"):
			complete_mission("clean_kill")
		if r.get("gender", "") == "Male" and r.get("trophy_score", 0.0) >= 150.0:
			complete_mission("buck150")
	elif sp == "Red Fox":
		complete_mission("fox")
	elif sp == "Mallard":
		complete_mission("duck")

func save_game() -> void:
	var done_ids := []
	for m in missions:
		if m.done:
			done_ids.append(m.id)
	var data := {"trophies": trophies, "missions_done": done_ids, "settings": settings}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	trophies = data.get("trophies", [])
	var s = data.get("settings", {})
	for k in s:
		settings[k] = s[k]
	var done_ids: Array = data.get("missions_done", [])
	for m in missions:
		m.done = done_ids.has(m.id)
