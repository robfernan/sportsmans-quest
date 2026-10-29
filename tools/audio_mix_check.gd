extends SceneTree

## Headless check for the shared bus layout and one-shot pools.
## Run: godot --headless --path . --script res://tools/audio_mix_check.gd

func _initialize() -> void:
	var fails: Array[String] = []
	var names: PackedStringArray = []
	for i in AudioServer.bus_count:
		names.append("%s:%.1f" % [AudioServer.get_bus_name(i), AudioServer.get_bus_volume_db(i)])
	print("BUSES ", " ".join(names))

	if AudioServer.bus_count != 5:
		fails.append("bus count %s" % AudioServer.bus_count)

	var expect := {
		&"Master": 0.0,
		&"Music": -12.0,
		&"Ambience": -16.0,
		&"SFX": -6.0,
		&"UI": -10.0,
	}
	for bus_name in expect:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			fails.append("missing %s" % bus_name)
			continue
		var vol := AudioServer.get_bus_volume_db(idx)
		if absf(vol - float(expect[bus_name])) > 0.01:
			fails.append("%s vol %s" % [bus_name, vol])
		if bus_name != &"Master" and String(AudioServer.get_bus_send(idx)) != "Master":
			fails.append("%s send %s" % [bus_name, AudioServer.get_bus_send(idx)])

	var master := AudioServer.get_bus_index(&"Master")
	if master < 0 or AudioServer.get_bus_effect_count(master) < 1:
		fails.append("no master effect")
	else:
		var fx: AudioEffect = AudioServer.get_bus_effect(master, 0)
		print("FX ", fx)
		if fx == null or not is_instance_of(fx, AudioEffectHardLimiter):
			fails.append("fx type %s" % fx)
		elif absf(fx.ceiling_db - (-1.0)) > 0.01:
			fails.append("ceiling %s" % fx.ceiling_db)

	var t0 := Time.get_ticks_msec()
	AudioSynth.warm_oneshot_cache()
	print("WARM_MS ", Time.get_ticks_msec() - t0)

	var ids := {}
	for i in 24:
		ids[AudioSynth.take_footstep(2).get_instance_id()] = true
	print("FOOT_UNIQUE ", ids.size())
	if ids.size() != 4:
		fails.append("foot unique %s" % ids.size())
	for i in 8:
		if not ids.has(AudioSynth.take_footstep(2).get_instance_id()):
			fails.append("new foot after warm")
			break

	var fab := {}
	for i in 12:
		fab[AudioSynth.take_fabric().get_instance_id()] = true
	print("FABRIC_UNIQUE ", fab.size())
	if fab.size() != 3:
		fails.append("fabric %s" % fab.size())

	var tails := {}
	for i in 8:
		tails[AudioSynth.take_gunshot_reverb(12.0, 120.0).get_instance_id()] = true
		tails[AudioSynth.take_gunshot_reverb(200.0, 120.0).get_instance_id()] = true
	print("REVERB_UNIQUE ", tails.size())
	if tails.size() != 4:
		fails.append("reverb unique %s" % tails.size())

	var screech := {}
	for i in 24:
		screech[AudioSynth.take_wendigo_screech().get_instance_id()] = true
	print("SCREECH_UNIQUE ", screech.size())
	if screech.size() != 2:
		fails.append("screech %s" % screech.size())

	var leaves := {}
	for i in 16:
		leaves[AudioSynth.take_footstep(0).get_instance_id()] = true
	print("LEAVES_UNIQUE ", leaves.size())
	if leaves.size() != 4:
		fails.append("leaves %s" % leaves.size())

	AudioSynth.warm_oneshot_cache()
	if not ids.has(AudioSynth.take_footstep(2).get_instance_id()):
		fails.append("rewarm rebuilt turf")

	_expect_pool(fails, "bird", 4, func() -> AudioStreamWAV: return AudioSynth.take_bird_chirp())
	_expect_pool(fails, "paddle", 3, func() -> AudioStreamWAV: return AudioSynth.take_paddle())
	_expect_pool(fails, "thud", 3, func() -> AudioStreamWAV: return AudioSynth.take_hit_thud())
	_expect_pool(fails, "hoof", 3, func() -> AudioStreamWAV: return AudioSynth.take_flee_hooves())
	_expect_pool(fails, "crash", 3, func() -> AudioStreamWAV: return AudioSynth.take_flee_crash())
	_expect_pool(fails, "ghost", 1, func() -> AudioStreamWAV: return AudioSynth.take_ghost_chime())
	_expect_pool(fails, "sting", 1, func() -> AudioStreamWAV: return AudioSynth.take_trophy_sting())
	_expect_pool(fails, "breath", 1, func() -> AudioStreamWAV: return AudioSynth.take_hunter_breathing(false))
	var room_a := AudioSynth.take_room_tone().get_instance_id()
	var room_b := AudioSynth.take_room_tone().get_instance_id()
	var fire_a := AudioSynth.take_fire_crackle().get_instance_id()
	var fire_b := AudioSynth.take_fire_crackle().get_instance_id()
	if room_a != room_b:
		fails.append("room tone rebuilt")
	if fire_a != fire_b:
		fails.append("fire crackle rebuilt")

	_fails = fails
	process_frame.connect(_finish_after_autoload_ready, CONNECT_ONE_SHOT)

var _fails: Array[String] = []

func _finish_after_autoload_ready() -> void:
	var fails := _fails
	var director := get_root().get_node_or_null("AudioDirector")
	print("DISPLAY ", DisplayServer.get_name(), " DIRECTOR ", director, " unlocked ", director.unlocked if director else "missing")
	if director == null:
		fails.append("autoload missing")
	elif DisplayServer.get_name() == "headless" and not director.unlocked:
		fails.append("headless should start unlocked")
	else:
		_check_focus_gate(director, fails)
	if fails.is_empty():
		print("AUDIO_CHECK_OK")
		quit(0)
	else:
		print("AUDIO_CHECK_FAIL")
		for item in fails:
			print(" - ", item)
		quit(1)

func _expect_pool(fails: Array[String], label: String, expect: int, builder: Callable) -> void:
	var seen := {}
	for i in maxi(expect * 12, 24):
		seen[builder.call().get_instance_id()] = true
	print(label.to_upper(), "_UNIQUE ", seen.size())
	if seen.size() != expect:
		fails.append("%s unique %s" % [label, seen.size()])

func _check_focus_gate(director: Node, fails: Array[String]) -> void:
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_E
	if not director._is_gesture(key):
		fails.append("key press should unlock")
	key.echo = true
	if director._is_gesture(key):
		fails.append("key echo should not unlock")
	var motion := InputEventMouseMotion.new()
	if director._is_gesture(motion):
		fails.append("mouse motion should not unlock")

	director.unlocked = false
	director._set_bus_mute(AudioDirector.BUS_MASTER, true)
	director._apply_bed_mute()
	if not AudioServer.is_bus_mute(AudioServer.get_bus_index(AudioDirector.BUS_MASTER)):
		fails.append("master should stay muted before the gesture")
	director._set_os_focused(false)
	_expect_beds(true, fails, "focus-out")
	director._set_os_focused(true)
	director._set_page_visible(false)
	_expect_beds(true, fails, "page-hidden")
	director._unlock()
	if AudioServer.is_bus_mute(AudioServer.get_bus_index(AudioDirector.BUS_MASTER)):
		fails.append("unlock should unmute master")
	_expect_beds(true, fails, "hidden-after-unlock")
	director._set_page_visible(true)
	_expect_beds(false, fails, "focus-in")
	director._set_os_focused(false)
	_expect_beds(true, fails, "focus-out-after-unlock")
	director._set_os_focused(true)
	_expect_beds(false, fails, "restored")

func _expect_beds(muted: bool, fails: Array[String], label: String) -> void:
	var music := AudioServer.get_bus_index(AudioDirector.BUS_MUSIC)
	var ambience := AudioServer.get_bus_index(AudioDirector.BUS_AMBIENCE)
	var sfx := AudioServer.get_bus_index(AudioDirector.BUS_SFX)
	var ui := AudioServer.get_bus_index(AudioDirector.BUS_UI)
	if AudioServer.is_bus_mute(music) != muted:
		fails.append("%s music" % label)
	if AudioServer.is_bus_mute(ambience) != muted:
		fails.append("%s ambience" % label)
	if AudioServer.is_bus_mute(sfx):
		fails.append("%s sfx muted" % label)
	if AudioServer.is_bus_mute(ui):
		fails.append("%s ui muted" % label)
