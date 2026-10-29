extends Node

## Shared Web + Desktop audio gate for Sportsman's Quest.
## Master stays muted until the first click, key, touch, or pad button.
## Focus loss and a hidden browser tab mute Music and Ambience; SFX and UI stay up.
## Restoring focus or showing the page brings those two buses back.

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_AMBIENCE := &"Ambience"
const BUS_SFX := &"SFX"
const BUS_UI := &"UI"

const _VIS_POLL_SEC := 0.3

var unlocked := false

var _os_focused := true
var _page_visible := true
var _web_bridge: Object
var _gesture_callback: Variant
var _visibility_callback: Variant
var _vis_poll := 0.0
var _missing_buses: Dictionary = {}

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	AudioSynth.warm_oneshot_cache()
	var win := get_tree().root
	if win and not win.focus_entered.is_connected(_on_window_focus_in):
		win.focus_entered.connect(_on_window_focus_in)
		win.focus_exited.connect(_on_window_focus_out)
	if DisplayServer.get_name() == "headless":
		unlocked = true
		_apply_bed_mute()
		return
	_set_bus_mute(BUS_MASTER, true)
	_apply_bed_mute()
	_hook_web()

func _input(event: InputEvent) -> void:
	if unlocked or not _is_gesture(event):
		return
	_unlock()

func _process(delta: float) -> void:
	if _web_bridge == null:
		return
	_vis_poll += delta
	if _vis_poll < _VIS_POLL_SEC:
		return
	_vis_poll = 0.0
	var hidden = _web_bridge.eval("document.hidden", true)
	if hidden is bool:
		_set_page_visible(not hidden)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_set_os_focused(false)
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_set_os_focused(true)

func _on_window_focus_in() -> void:
	_set_os_focused(true)

func _on_window_focus_out() -> void:
	_set_os_focused(false)

func _on_web_gesture(_args: Array) -> void:
	_unlock()

func _on_web_visibility(args: Array) -> void:
	var visible := true
	if args.size() > 0:
		visible = bool(args[0])
	_set_page_visible(visible)

func _unlock() -> void:
	if unlocked:
		return
	unlocked = true
	_resume_web_audio()
	_set_bus_mute(BUS_MASTER, false)
	_apply_bed_mute()

func _set_os_focused(focused: bool) -> void:
	if _os_focused == focused:
		return
	_os_focused = focused
	if focused:
		_resume_web_audio()
	_apply_bed_mute()

func _set_page_visible(visible: bool) -> void:
	if _page_visible == visible:
		return
	_page_visible = visible
	if visible:
		_resume_web_audio()
	_apply_bed_mute()

func _apply_bed_mute() -> void:
	var mute_beds := (not unlocked) or (not _os_focused) or (not _page_visible)
	_set_bus_mute(BUS_MUSIC, mute_beds)
	_set_bus_mute(BUS_AMBIENCE, mute_beds)

func _set_bus_mute(bus_name: StringName, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		if not _missing_buses.has(bus_name):
			_missing_buses[bus_name] = true
			push_warning("AudioDirector: bus '%s' is missing from the default layout." % String(bus_name))
		return
	AudioServer.set_bus_mute(idx, muted)

func _is_gesture(event: InputEvent) -> bool:
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventJoypadButton:
		return event.is_pressed()
	if event is InputEventKey:
		return event.is_pressed() and not (event as InputEventKey).echo
	return false

func _hook_web() -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	_web_bridge = Engine.get_singleton("JavaScriptBridge")
	_gesture_callback = _web_bridge.create_callback(_on_web_gesture)
	_visibility_callback = _web_bridge.create_callback(_on_web_visibility)
	var window = _web_bridge.get_interface("window")
	window.__sqOnGesture = _gesture_callback
	window.__sqOnVisibility = _visibility_callback
	_web_bridge.eval(_WEB_HOOK, true)
	var hidden = _web_bridge.eval("document.hidden", true)
	if hidden is bool:
		_page_visible = not hidden
		_apply_bed_mute()

func _resume_web_audio() -> void:
	if _web_bridge == null:
		return
	_web_bridge.eval("if (window.__sqResumeAudio) window.__sqResumeAudio();", true)

const _WEB_HOOK := """
(function () {
  if (window.__sqAudioHooked) return;
  window.__sqAudioHooked = true;
  function resumeCtx() {
    var list = [];
    if (typeof GodotAudio !== 'undefined' && GodotAudio.ctx) list.push(GodotAudio.ctx);
    if (window.GodotAudio && window.GodotAudio.ctx) list.push(window.GodotAudio.ctx);
    for (var i = 0; i < list.length; i++) {
      var ctx = list[i];
      if (ctx && ctx.state !== 'running' && ctx.resume) ctx.resume();
    }
  }
  function onGesture() {
    resumeCtx();
    var cb = window.__sqOnGesture;
    if (typeof cb === 'function') cb();
    document.removeEventListener('pointerdown', onGesture, true);
    document.removeEventListener('keydown', onGesture, true);
    document.removeEventListener('touchstart', onGesture, true);
  }
  window.__sqResumeAudio = resumeCtx;
  document.addEventListener('pointerdown', onGesture, true);
  document.addEventListener('keydown', onGesture, true);
  document.addEventListener('touchstart', onGesture, true);
  document.addEventListener('visibilitychange', function () {
    var cb = window.__sqOnVisibility;
    if (typeof cb === 'function') cb(!document.hidden);
  });
})();
"""
