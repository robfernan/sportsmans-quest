extends Node

## GameState autoload: persistent offline save data (trophies, missions, settings).
## Supports forward migration, tutorial flags, fear memory, and global environmental states.

signal notify(text: String)
signal mission_completed(title: String)

const SAVE_PATH := "user://sportsmans_quest_save.json"
const CURRENT_SAVE_VERSION := 1

var trophies: Array = []
var settings := {"quality": 1, "mouse_sens": 1.0, "night_hunt": false}
var seen_tutorial := {
	"sprint": false,
	"crouch": false,
	"aim_vital": false
}
var animal_fear: Dictionary = {} # Persistent fear memory keyed by species
var fog_density: float = 0.0055 # Dynamic atmospheric fog level (0.0 to 1.0)
var is_night_hunt: bool = false # Cryptid Night Mode toggle

var missions: Array = [
	{"id": "first_deer", "title": "First Blood", "desc": "Harvest any Whitetail Deer.", "done": false},
	{"id": "long_shot", "title": "Long Range", "desc": "Harvest a deer from over 100 m.", "done": false},
	{"id": "clean_kill", "title": "Ethical Hunter", "desc": "Harvest a deer with a heart or lung shot.", "done": false},
	{"id": "fox", "title": "Predator Control", "desc": "Harvest a Red Fox.", "done": false},
	{"id": "duck", "title": "Marsh Master", "desc": "Harvest a Mallard with the shotgun.", "done": false},
	{"id": "buck150", "title": "Trophy Buck", "desc": "Harvest a buck scoring 150+ points.", "done": false},
	{"id": "ghost_hunt", "title": "Ghost Hunt", "desc": "Harvest the Mythical Ghost Buck under moonlight.", "done": false},
	{"id": "cryptid_survivor", "title": "Cryptid Survivor", "desc": "Harvest a Werewolf or Wendigo in Night Hunt.", "done": false},
	{"id": "kayak", "title": "Silent Waters", "desc": "Paddle the kayak across the lake.", "done": false},
]

func _ready() -> void:
	load_game()

func add_trophy(record: Dictionary) -> void:
	trophies.append(record)
	_check_missions(record)
	save_game()
	notify.emit("Trophy recorded: %s (%.1f pts)" % [record.get("species_name", "?"), record.get("trophy_score", 0.0)])
	
	var eb = get_node_or_null("/root/EventBus")
	if eb:
		eb.animal_harvested.emit(
			record.get("species_name", "Game"),
			record.get("organ_hit", "Vital"),
			record.get("shot_distance_m", 0.0),
			record
		)

func complete_mission(id: String) -> void:
	for m in missions:
		if m.id == id and not m.done:
			m.done = true
			mission_completed.emit(m.title)
			notify.emit("MISSION COMPLETE: " + m.title)
			save_game()

func _check_missions(r: Dictionary) -> void:
	var sp: String = r.get("species_name", "")
	var organ: String = r.get("organ_hit", "")
	var dist: float = r.get("shot_distance_m", 0.0)
	
	if sp == "Whitetail Deer":
		complete_mission("first_deer")
		if dist >= 100.0:
			complete_mission("long_shot")
		if organ.contains("Heart") or organ.contains("Lung"):
			complete_mission("clean_kill")
		if r.get("gender", "") == "Male" and r.get("trophy_score", 0.0) >= 150.0:
			complete_mission("buck150")
	elif sp == "Red Fox":
		complete_mission("fox")
	elif sp == "Mallard":
		complete_mission("duck")
	elif sp.contains("Ghost Buck"):
		complete_mission("ghost_hunt")
	elif sp.contains("Werewolf") or sp.contains("Wendigo"):
		complete_mission("cryptid_survivor")

func save_game() -> void:
	var done_ids := []
	for m in missions:
		if m.done:
			done_ids.append(m.id)
	settings["night_hunt"] = is_night_hunt
	var data := {
		"version": CURRENT_SAVE_VERSION,
		"trophies": trophies,
		"missions_done": done_ids,
		"settings": settings,
		"seen_tutorial": seen_tutorial,
		"animal_fear": animal_fear
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("[Sportsman's Quest] Save failed: could not open file for writing at " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("[Sportsman's Quest] Load failed: could not open file for reading at " + SAVE_PATH)
		return
	var raw_text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(raw_text)
	if typeof(data) != TYPE_DICTIONARY:
		return
		
	var v: int = int(data.get("version", 0))
	if v < CURRENT_SAVE_VERSION:
		data = _migrate_save(data, v)
		
	trophies = data.get("trophies", [])
	var s = data.get("settings", {})
	for k in s:
		settings[k] = s[k]
	is_night_hunt = settings.get("night_hunt", false)
	
	var tut = data.get("seen_tutorial", {})
	# Older builds saved `true` here and then crashed on the next load.
	if typeof(tut) == TYPE_BOOL:
		if tut:
			seen_tutorial["sprint"] = true
			seen_tutorial["crouch"] = true
			seen_tutorial["aim_vital"] = true
	elif typeof(tut) == TYPE_DICTIONARY:
		for k in tut:
			if seen_tutorial.has(k):
				seen_tutorial[k] = bool(tut[k])
		
	animal_fear = data.get("animal_fear", {})
	
	var done_ids: Array = data.get("missions_done", [])
	for m in missions:
		m.done = done_ids.has(m.id)

func _migrate_save(old_data: Dictionary, from_version: int) -> Dictionary:
	# Version migration placeholder for future expansions
	print("[Sportsman's Quest] Migrating save data from version %d to %d" % [from_version, CURRENT_SAVE_VERSION])
	old_data["version"] = CURRENT_SAVE_VERSION
	return old_data
